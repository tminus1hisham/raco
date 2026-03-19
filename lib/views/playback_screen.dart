import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/playback_controller.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../widgets/modal/custom_alert.dart';

class PlaybackScreen extends StatefulWidget {
  final String numberPlate;

  PlaybackScreen({required this.numberPlate});

  @override
  _PlaybackScreenState createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  MapboxMap? _mapboxMap;
  final PlaybackController controller = Get.put(PlaybackController());

  Timer? _playbackTimer;
  bool _isAnimatingCamera = false;
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 0.5;

  final Utils _utils = Utils();
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  // Marker caches
  Uint8List? _carMarkerIcon;
  Map<double, Uint8List> _bearingMarkerCache = {};

  // Map readiness
  final Completer<void> _mapReadyCompleter = Completer<void>();
  bool _isMapReady = false;

  // Annotation layer management
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _vehicleAnnotation;
  static const String _routeSourceId = 'route-source';
  static const String _routeLayerId = 'route-layer';

  @override
  void initState() {
    super.initState();
    _loadCarMarker();
    _startDate = null;
    _endDate = null;
  }

  // ─── DATA FETCHING ────────────────────────────────────────────────────────

  Future<void> _fetchHistoryData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _currentIndex = 0;
      _isPlaying = false;
      _playbackTimer?.cancel();
    });

    final String startFormatted = _startDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    final String endFormatted = _endDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    await controller.fetchHistory(
      widget.numberPlate,
      startFormatted,
      endFormatted,
    );

    if (controller.history.isNotEmpty) {
      if (_isMapReady) {
        await _generateConditionalMarkers(controller.history.toList());
      } else {
        await _mapReadyCompleter.future;
        await _generateConditionalMarkers(controller.history.toList());
      }
      _stopPlayback();
    }
  }

  // ─── MAP RENDERING ────────────────────────────────────────────────────────

  Future<void> _drawRoute(List<DeviceRecord> history) async {
    if (_mapboxMap == null || history.isEmpty) return;

    final coords = history
        .where(
          (r) => double.tryParse(r.lg) != null && double.tryParse(r.lt) != null,
        )
        .map((r) => [double.parse(r.lg), double.parse(r.lt)])
        .toList();

    if (coords.isEmpty) return;

    final geoJson = jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coords},
          "properties": {},
        },
      ],
    });

    final sourceExists = await _mapboxMap!.style.styleSourceExists(
      _routeSourceId,
    );

    if (sourceExists) {
      await _mapboxMap!.style.setStyleSourceProperty(
        _routeSourceId,
        "data",
        geoJson,
      );
    } else {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: _routeSourceId, data: geoJson),
      );

      await _mapboxMap!.style.addLayer(
        LineLayer(id: _routeLayerId, sourceId: _routeSourceId),
      );

      await _mapboxMap!.style.setStyleLayerProperty(
        _routeLayerId,
        "line-color",
        "#2563EB",
      );
      await _mapboxMap!.style.setStyleLayerProperty(
        _routeLayerId,
        "line-width",
        3.5,
      );
      await _mapboxMap!.style.setStyleLayerProperty(
        _routeLayerId,
        "line-opacity",
        0.85,
      );
      await _mapboxMap!.style.setStyleLayerProperty(
        _routeLayerId,
        "line-cap",
        "round",
      );
      await _mapboxMap!.style.setStyleLayerProperty(
        _routeLayerId,
        "line-join",
        "round",
      );
    }
  }

  Future<void> _generateConditionalMarkers(List<DeviceRecord> history) async {
    if (_mapboxMap == null || history.isEmpty) return;

    await _drawRoute(history);

    try {
      _annotationManager?.deleteAll();
    } catch (_) {}
    _vehicleAnnotation = null;
    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();

    final startRec = history.first;
    final startImg = await _createStartMarker();
    await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            double.parse(startRec.lg),
            double.parse(startRec.lt),
          ),
        ),
        image: startImg,
        iconSize: 0.5,
      ),
    );

    final stopRec = history.last;
    final stopImg = await _createStopMarker();
    await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            double.parse(stopRec.lg),
            double.parse(stopRec.lt),
          ),
        ),
        image: stopImg,
        iconSize: 0.5,
      ),
    );

    final bearing = _getCurrentBearing(history, 0);
    final carImg = await _getCachedMarker(bearing);
    _vehicleAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            double.parse(startRec.lg),
            double.parse(startRec.lt),
          ),
        ),
        image: carImg,
        iconSize: 0.5,
      ),
    );

    await _fitCameraToBounds(history);

    if (mounted) setState(() {});
  }

  Future<void> _updateVehicleMarker(
    int index,
    List<DeviceRecord> history,
  ) async {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    if (index < 0 || index >= history.length) return;

    final rec = history[index];
    final lat = double.tryParse(rec.lt);
    final lng = double.tryParse(rec.lg);
    if (lat == null || lng == null) return;

    final bearing = _getCurrentBearing(history, index);
    final img = await _getCachedMarker(bearing);

    _vehicleAnnotation!.geometry = Point(coordinates: Position(lng, lat));
    _vehicleAnnotation!.image = img;
    await _annotationManager!.update(_vehicleAnnotation!);
  }

  Future<void> _fitCameraToBounds(List<DeviceRecord> history) async {
    if (_mapboxMap == null || history.isEmpty) return;

    double minLat = double.maxFinite, maxLat = -double.maxFinite;
    double minLng = double.maxFinite, maxLng = -double.maxFinite;

    for (final r in history) {
      final lat = double.tryParse(r.lt) ?? 0;
      final lng = double.tryParse(r.lg) ?? 0;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    if (minLat == maxLat && minLng == maxLng) {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(minLng, minLat)),
          zoom: 15.0,
        ),
        null,
      );
      return;
    }

    final bounds = CoordinateBounds(
      southwest: Point(coordinates: Position(minLng, minLat)),
      northeast: Point(coordinates: Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    try {
      final camera = await _mapboxMap!.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(top: 120.0, left: 40.0, bottom: 320.0, right: 40.0),
        null,
        null,
        null,
        null,
      );
      await _mapboxMap!.setCamera(camera);
    } catch (e) {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              double.parse(history.first.lg),
              double.parse(history.first.lt),
            ),
          ),
          zoom: 14.0,
        ),
        null,
      );
    }
  }

  // ─── MARKER CREATION ─────────────────────────────────────────────────────
  // Note: canvas-drawn markers use kWhite/kSuccessGreen/kRed intentionally —
  // these render to PNG bitmaps and are not Flutter UI widgets.

  Future<Uint8List> _createStartMarker() async {
    const double size = 100;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = kSuccessGreen,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = kWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'START',
        style: TextStyle(
          color: kWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createStopMarker() async {
    const double size = 100;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = kRed,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = kWhite
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'STOP',
        style: TextStyle(
          color: kWhite,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<void> _loadCarMarker() async {
    _carMarkerIcon = await _createRotatedMarker('assets/blue_car.png', 0);
    await _precacheCommonBearings();
    setState(() {});
  }

  Future<void> _precacheCommonBearings() async {
    final bearings = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    for (final bearing in bearings) {
      _bearingMarkerCache[bearing] = await _createRotatedMarker(
        'assets/blue_car.png',
        bearing,
      );
    }
  }

  Future<Uint8List> _createRotatedMarker(
    String assetPath,
    double rotation,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 70,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final originalImage = fi.image;

    final padding = (originalImage.width * 0.4).round();
    final canvasSize = originalImage.width + padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset.zero,
        Offset(canvasSize.toDouble(), canvasSize.toDouble()),
      ),
    );

    canvas.translate(canvasSize / 2, canvasSize / 2);
    canvas.rotate((rotation + 180) * math.pi / 180);
    canvas.drawImage(
      originalImage,
      Offset(-originalImage.width / 2, -originalImage.height / 2),
      Paint(),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize, canvasSize);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<Uint8List> _getCachedMarker(double bearing) async {
    final roundedBearing = (bearing / 45).round() * 45.0;
    if (_bearingMarkerCache.containsKey(roundedBearing)) {
      return _bearingMarkerCache[roundedBearing]!;
    }
    final marker = await _createRotatedMarker(
      'assets/blue_car.png',
      roundedBearing,
    );
    _bearingMarkerCache[roundedBearing] = marker;
    return marker;
  }

  // ─── BEARING / IGNITION HELPERS ──────────────────────────────────────────

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _getCurrentBearing(List<DeviceRecord> history, int currentIndex) {
    final currentRecord = history[currentIndex];
    final course = double.tryParse(currentRecord.course.toString());
    if (course != null && course >= 0 && course <= 360) return course;

    if (currentIndex > 0 && currentIndex < history.length - 1) {
      return _calculateBearing(
        LatLng(
          double.parse(history[currentIndex - 1].lt),
          double.parse(history[currentIndex - 1].lg),
        ),
        LatLng(
          double.parse(history[currentIndex + 1].lt),
          double.parse(history[currentIndex + 1].lg),
        ),
      );
    } else if (currentIndex > 0) {
      return _calculateBearing(
        LatLng(
          double.parse(history[currentIndex - 1].lt),
          double.parse(history[currentIndex - 1].lg),
        ),
        LatLng(double.parse(currentRecord.lt), double.parse(currentRecord.lg)),
      );
    } else if (currentIndex < history.length - 1) {
      return _calculateBearing(
        LatLng(double.parse(currentRecord.lt), double.parse(currentRecord.lg)),
        LatLng(
          double.parse(history[currentIndex + 1].lt),
          double.parse(history[currentIndex + 1].lg),
        ),
      );
    }
    return 0.0;
  }

  int _getIgnitionStatus(DeviceRecord record) {
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;
  }

  // ─── PLAYBACK CONTROLS ───────────────────────────────────────────────────

  void _startPlayback(List<DeviceRecord> history) {
    if (_isPlaying || history.isEmpty) return;
    setState(() {
      _isPlaying = true;
      _currentIndex = 0;
    });
    _playbackTimer?.cancel();
    _playbackTimer = _buildPlaybackTimer(history);
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resumePlayback(List<DeviceRecord> history) {
    if (_isPlaying || history.isEmpty) return;
    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();
    _playbackTimer = _buildPlaybackTimer(history);
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
    });
    final history = controller.history.toList();
    if (history.isNotEmpty) {
      _updateVehicleMarker(0, history);
    }
  }

  void _updatePlaybackSpeed(double newSpeed) {
    setState(() => _playbackSpeed = newSpeed);
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = _buildPlaybackTimer(controller.history.toList());
    }
  }

  Timer _buildPlaybackTimer(List<DeviceRecord> history) {
    return Timer.periodic(Duration(milliseconds: (100 ~/ _playbackSpeed)), (
      timer,
    ) async {
      if (!_isPlaying || _currentIndex >= history.length - 1) {
        timer.cancel();
        setState(() => _isPlaying = false);
        return;
      }

      if (_isAnimatingCamera) return;

      _currentIndex++;

      final current = history[_currentIndex];
      final lat = double.tryParse(current.lt);
      final lng = double.tryParse(current.lg);
      if (lat == null || lng == null) {
        setState(() {});
        return;
      }

      await _updateVehicleMarker(_currentIndex, history);

      _isAnimatingCamera = true;
      try {
        await _mapboxMap?.flyTo(
          CameraOptions(center: Point(coordinates: Position(lng, lat))),
          null,
        );
      } catch (e) {
        debugPrint("Camera animation error: $e");
      } finally {
        _isAnimatingCamera = false;
      }

      setState(() {});
    });
  }

  // ─── DATE PICKERS ────────────────────────────────────────────────────────

  Future<void> _pickStartDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: kBlue,
                  onPrimary: kWhite,
                  surface: col.surface,
                  onSurface: col.textPrimary,
                )
              : ColorScheme.light(
                  primary: kBlue,
                  onPrimary: kWhite,
                  surface: kWhite,
                  onSurface: Colors.black,
                ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => ActionDialog(
            title: "Invalid Date",
            message: "Start date cannot be after the end date.",
            confirmText: "Ok",
            cancelText: "Cancel",
            onConfirm: () async {},
          ),
        );
        return;
      }
      setState(() => _startDate = picked);
      if (_startDate != null && _endDate != null) _fetchHistoryData();
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: kBlue,
                  onPrimary: kWhite,
                  surface: col.surface,
                  onSurface: col.textPrimary,
                )
              : ColorScheme.light(
                  primary: kBlue,
                  onPrimary: kWhite,
                  surface: kWhite,
                  onSurface: Colors.black,
                ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => ActionDialog(
            title: "Invalid Date",
            message: "End date cannot be before the start date.",
            confirmText: "Ok",
            cancelText: "Cancel",
            onConfirm: () async {},
          ),
        );
        return;
      }
      setState(() => _endDate = picked);
      if (_startDate != null && _endDate != null) _fetchHistoryData();
    }
  }

  // ─── WIDGETS ─────────────────────────────────────────────────────────────

  Widget _buildDatePickerButton({
    required AppColors col,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: SizedBox(
        height: 80,
        child: Material(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(kRadiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusMD),
                border: Border.all(
                  color: selectedDate != null
                      ? kBlue.withValues(alpha: 0.3)
                      : col.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selectedDate != null ? kBlue : col.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: col.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedDate != null
                              ? _dateFormat.format(selectedDate)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedDate != null
                                ? col.textPrimary
                                : col.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: col.border, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Playback",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            color: col.surface,
            child: Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: kBlue,
                size: 50,
              ),
            ),
          );
        }

        final history = controller.history.toList();

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 60, color: col.border),
                const SizedBox(height: 20),
                Text(
                  _startDate != null && _endDate != null
                      ? "No playback data available"
                      : "Select date range to view playback",
                  style: TextStyle(fontSize: 18, color: col.textSecondary),
                ),
                const SizedBox(height: 10),
                if (_startDate != null && _endDate != null)
                  Text(
                    "No GPS records found for this range",
                    style: TextStyle(fontSize: 14, color: col.textSecondary),
                  ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildDatePickerButton(
                        col: col,
                        label: 'Start Date',
                        selectedDate: _startDate,
                        onTap: () => _pickStartDate(context),
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(width: 12),
                      _buildDatePickerButton(
                        col: col,
                        label: 'End Date',
                        selectedDate: _endDate,
                        onTap: () => _pickEndDate(context),
                        icon: Icons.event,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final currentRecord = history[_currentIndex];
        final currentPoint = Point(
          coordinates: Position(
            double.parse(currentRecord.lg),
            double.parse(currentRecord.lt),
          ),
        );
        final ignitionStatus = _getIgnitionStatus(currentRecord);

        return Stack(
          children: [
            MapWidget(
              styleUri: isDark
                  ? MapboxStyles.DARK
                  : MapboxStyles.MAPBOX_STREETS,
              cameraOptions: CameraOptions(center: currentPoint, zoom: 15.0),
              onMapCreated: (MapboxMap map) async {
                _mapboxMap = map;
                _isMapReady = true;
                if (!_mapReadyCompleter.isCompleted) {
                  _mapReadyCompleter.complete();
                }
                if (controller.history.isNotEmpty) {
                  await _generateConditionalMarkers(
                    controller.history.toList(),
                  );
                }
              },
            ),

            // ── Info panel ─────────────────────────────────────
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(kRadiusMD),
                child: Container(
                  padding: const EdgeInsets.all(kSpaceLG),
                  decoration: BoxDecoration(
                    color: col.surface,
                    borderRadius: BorderRadius.circular(kRadiusMD),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentRecord.rg,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ignitionStatus == 1
                                  ? kSuccessGreen.withValues(alpha: 0.15)
                                  : col.border.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                            child: Text(
                              ignitionStatus == 1 ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: ignitionStatus == 1
                                    ? kSuccessGreen
                                    : col.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.speed,
                              label: "Speed",
                              value: "${currentRecord.spd} km/h",
                            ),
                          ),
                          _InfoItem(
                            icon: Icons.access_alarms_sharp,
                            label: "Time",
                            value: _utils.formatTime(
                              currentRecord.createdAt.toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom controls panel ──────────────────────────
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(kRadiusLG),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: kSpaceLG,
                    horizontal: kSpaceXL,
                  ),
                  decoration: BoxDecoration(
                    color: col.surface,
                    borderRadius: BorderRadius.circular(kRadiusLG),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildDatePickerButton(
                            col: col,
                            label: 'Start Date',
                            selectedDate: _startDate,
                            onTap: () => _pickStartDate(context),
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(width: 12),
                          _buildDatePickerButton(
                            col: col,
                            label: 'End Date',
                            selectedDate: _endDate,
                            onTap: () => _pickEndDate(context),
                            icon: Icons.event,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kRadiusSM),
                        ),
                        child: Text(
                          '${_playbackSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kBlue,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.fast_rewind_sharp,
                              color: kBlue,
                              size: 30,
                            ),
                            onPressed: () {
                              _updatePlaybackSpeed(
                                (_playbackSpeed - 1).clamp(0.5, 5.0),
                              );
                            },
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: kBlue,
                                inactiveTrackColor: col.border,
                                thumbColor: kBlue,
                                overlayColor: kBlue.withValues(alpha: 0.2),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _playbackSpeed,
                                min: 0.1,
                                max: 5.0,
                                divisions: 9,
                                label: '${_playbackSpeed.toStringAsFixed(1)}x',
                                onChanged: _updatePlaybackSpeed,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.fast_forward,
                              color: kBlue,
                              size: 30,
                            ),
                            onPressed: () {
                              _updatePlaybackSpeed(
                                (_playbackSpeed + 1).clamp(0.5, 5.0),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                            onPressed: () => _isPlaying
                                ? _pausePlayback()
                                : (_currentIndex == 0
                                      ? _startPlayback(history)
                                      : _resumePlayback(history)),
                            color: kBlue,
                          ),
                          _ControlButton(
                            icon: Icons.stop,
                            onPressed: _stopPlayback,
                            color: kRed,
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: kRed.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(kRadiusMD),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            icon: const Icon(Icons.clear, color: kRed),
                            label: const Text(
                              "Clear Dates",
                              style: TextStyle(
                                color: kRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: col.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: col.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(isLarge ? 30 : 25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isLarge ? 30 : 25),
        child: SizedBox(
          width: isLarge ? 60 : 50,
          height: isLarge ? 60 : 50,
          child: Icon(icon, color: kWhite, size: isLarge ? 32 : 24),
        ),
      ),
    );
  }
}
