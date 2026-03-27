import 'dart:async';
import 'dart:math' as math;
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

import '../widgets/map/map_style_switcher.dart';
import '../widgets/modal/custom_alert.dart';

class PlaybackScreen extends StatefulWidget {
  final String numberPlate;

  const PlaybackScreen({super.key, required this.numberPlate});

  @override
  PlaybackScreenState createState() => PlaybackScreenState();
}

class PlaybackScreenState extends State<PlaybackScreen>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  final PlaybackController controller = Get.put(PlaybackController());

  Timer? _playbackTimer;
  AnimationController? _markerAnimController;
  Animation<double>? _markerAnimation;
  Position? _lastPosition;
  double _startLng = 0,
      _startLat = 0,
      _endLng = 0,
      _endLat = 0,
      _startBearing = 0,
      _endBearing = 0;
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 0.5;

  final Utils _utils = Utils();
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  // Marker
  Uint8List? _carMarkerIcon;
  double _currentBearing = 0.0;
  double _currentZoom = 15.0;

  // Map style
  String? _mapStyleUri;

  // Map readiness
  final Completer<void> _mapReadyCompleter = Completer<void>();
  bool _isMapReady = false;

  // Annotation layer management
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _vehicleAnnotation;
  PolylineAnnotationManager? _polylineAnnotationManager;

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

    final lineCoords = history
        .where(
          (r) => double.tryParse(r.lg) != null && double.tryParse(r.lt) != null,
        )
        .map((r) => Position(double.parse(r.lg), double.parse(r.lt)))
        .toList();

    if (lineCoords.isEmpty) return;

    _polylineAnnotationManager ??= await _mapboxMap!.annotations
        .createPolylineAnnotationManager();

    try {
      _polylineAnnotationManager?.deleteAll();
    } catch (_) {}

    final List<PolylineAnnotationOptions> segments = [];
    final int segmentCount = lineCoords.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final double progress = i / segmentCount;
      // Fade opacity from tail (older history) to head (latest history)
      final opacity = 0.15 + (progress * 0.85);

      segments.add(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [lineCoords[i], lineCoords[i + 1]]),
          lineColor: 0xFF2563EB, // kBlue roughly
          lineWidth: 4.5,
          lineOpacity: opacity,
        ),
      );
    }

    if (segments.isNotEmpty) {
      await _polylineAnnotationManager!.createMulti(segments);
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
    await _annotationManager!.setIconRotationAlignment(
      IconRotationAlignment.MAP,
    );
    await _annotationManager!.setIconPitchAlignment(IconPitchAlignment.MAP);

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
    _currentBearing = bearing;
    _lastPosition = Position(
      double.parse(startRec.lg),
      double.parse(startRec.lt),
    );
    _carMarkerIcon ??= await _createRotatedMarker('assets/blue_car.png', 0);
    _vehicleAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            double.parse(startRec.lg),
            double.parse(startRec.lt),
          ),
        ),
        image: _carMarkerIcon!,
        iconSize: _iconSizeForZoom(_currentZoom),
        iconRotate: bearing,
        iconOpacity: 0.0,
      ),
    );

    await _fitCameraToBounds(history);

    if (mounted) setState(() {});
  }

  /// Exponential zoom-to-iconSize, anchored so zoom 15 → 1.5 (original size).
  /// Doubles every 3 zoom levels in; halves every 3 levels out.
  /// zoom 9 → 0.38 | zoom 12 → 0.75 | zoom 15 → 1.5 | zoom 18 → 3.0 (capped)
  double _iconSizeForZoom(double zoom) =>
      (1.5 * math.pow(2.0, (zoom - 15.0) / 3.0)).clamp(0.3, 2.5);

  Future<void> _updateVehicleIconSize() async {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    _vehicleAnnotation!.iconSize = _iconSizeForZoom(_currentZoom);
    await _annotationManager!.update(_vehicleAnnotation!);
  }

  Future<void> _switchMapStyle(String styleUri) async {
    setState(() => _mapStyleUri = styleUri);
    if (_mapboxMap == null) return;
    await _mapboxMap!.loadStyleURI(styleUri);
    if (controller.history.isNotEmpty) {
      await _generateConditionalMarkers(controller.history.toList());
    }
  }

  void _updateVehicleMarker(int index, List<DeviceRecord> history) {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    if (index < 0 || index >= history.length) return;

    final rec = history[index];
    final lat = double.tryParse(rec.lt);
    final lng = double.tryParse(rec.lg);
    if (lat == null || lng == null) {
      if (_isPlaying) Future.microtask(() => _playNextSegment(history));
      return;
    }

    final targetBearing = _getCurrentBearing(history, index);
    final newPosition = Position(lng, lat);

    // Smooth shortest-path angular interpolation so the icon rotates
    // gradually at corners rather than snapping to the new heading.
    final diff = ((targetBearing - _currentBearing + 180) % 360) - 180;
    final newBearing = (_currentBearing + diff * 0.4 + 360) % 360;

    if (_lastPosition == null) {
      _lastPosition = newPosition;
      _currentBearing = newBearing;
      _vehicleAnnotation!.geometry = Point(coordinates: newPosition);
      _vehicleAnnotation!.iconRotate = _currentBearing;
      _annotationManager!.update(_vehicleAnnotation!);
      if (_isPlaying) Future.microtask(() => _playNextSegment(history));
      return;
    }

    final startPosition = _lastPosition!;
    final startBearing = _currentBearing;

    _lastPosition = newPosition;
    _currentBearing = newBearing;

    final double dist = _haversineDistance(
      startPosition.lat.toDouble(),
      startPosition.lng.toDouble(),
      newPosition.lat.toDouble(),
      newPosition.lng.toDouble(),
    );
    // Dynamic duration based on physical distance (10 ms per meter at 1.0x speed)
    final int targetDurationMs = (dist * 10 ~/ _playbackSpeed).toInt();
    final int durationMs = targetDurationMs.clamp(50, 3000);

    if (_markerAnimController == null) {
      _markerAnimController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durationMs),
      );
      _markerAnimation = CurvedAnimation(
        parent: _markerAnimController!,
        curve: Curves.linear,
      );
      int lastFrameTime = 0;
      _markerAnimation!.addListener(() {
        if (_vehicleAnnotation == null || _annotationManager == null) return;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastFrameTime < 32)
          return; // Throttle to ~30 FPS to stabilize Mapbox renderer
        lastFrameTime = now;

        final t = _markerAnimation!.value;

        final currentLng = _startLng + (_endLng - _startLng) * t;
        final currentLat = _startLat + (_endLat - _startLat) * t;

        final bearingDiff = ((_endBearing - _startBearing + 180) % 360) - 180;
        final interpolatedBearing =
            (_startBearing + bearingDiff * t + 360) % 360;

        _vehicleAnnotation!.geometry = Point(
          coordinates: Position(currentLng, currentLat),
        );
        _vehicleAnnotation!.iconRotate = interpolatedBearing;
        _annotationManager!.update(_vehicleAnnotation!);
      });
      _markerAnimation!.addStatusListener((status) {
        if (status == AnimationStatus.completed && _isPlaying) {
          _playNextSegment(controller.history.toList());
        }
      });
    }

    _markerAnimController!.duration = Duration(milliseconds: durationMs);
    _startLng = startPosition.lng.toDouble();
    _startLat = startPosition.lat.toDouble();
    _endLng = newPosition.lng.toDouble();
    _endLat = newPosition.lat.toDouble();
    _startBearing = startBearing;
    _endBearing = newBearing;

    _markerAnimController!.forward(from: 0.0);
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
    // Load a single north-facing bitmap; rotation is applied via iconRotate.
    _carMarkerIcon = await _createRotatedMarker('assets/blue_car.png', 0);
    setState(() {});
  }

  Future<Uint8List> _createRotatedMarker(
    String assetPath,
    double rotation,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 120,
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
    canvas.rotate(rotation * math.pi / 180);
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

  // ─── BEARING / IGNITION HELPERS ──────────────────────────────────────────

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371e3; // metres
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

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
    if (_vehicleAnnotation != null && _annotationManager != null) {
      _vehicleAnnotation!.iconOpacity = 1.0;
      _annotationManager!.update(_vehicleAnnotation!);
    }
    setState(() {
      _isPlaying = true;
      _currentIndex = 0;
    });
    _playbackTimer?.cancel();
    _playNextSegment(history);
  }

  void _pausePlayback() {
    setState(() => _isPlaying = false);
    _markerAnimController?.stop();
  }

  void _resumePlayback(List<DeviceRecord> history) {
    if (_isPlaying || history.isEmpty) return;
    setState(() => _isPlaying = true);
    if (_markerAnimController != null && !_markerAnimController!.isAnimating) {
      _markerAnimController!.forward();
    } else {
      _playNextSegment(history);
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _markerAnimController?.stop();
    _lastPosition = null;
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
  }

  void _playNextSegment(List<DeviceRecord> history) {
    if (!_isPlaying || _currentIndex >= history.length - 1) {
      setState(() => _isPlaying = false);
      return;
    }

    _currentIndex++;

    final current = history[_currentIndex];
    final lat = double.tryParse(current.lt);
    final lng = double.tryParse(current.lg);
    if (lat == null || lng == null) {
      _updateVehicleMarker(_currentIndex, history);
      return;
    }

    _updateVehicleMarker(_currentIndex, history);

    final int cameraDurationMs = (200 ~/ _playbackSpeed).clamp(50, 2000);
    try {
      _mapboxMap?.easeTo(
        CameraOptions(center: Point(coordinates: Position(lng, lat))),
        MapAnimationOptions(duration: cameraDurationMs),
      );
    } catch (e) {
      debugPrint("Camera animation error: $e");
    }

    setState(() {});
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
    _markerAnimController?.dispose();
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
              styleUri:
                  _mapStyleUri ??
                  (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
              cameraOptions: CameraOptions(center: currentPoint, zoom: 15.0),
              onCameraChangeListener: (CameraChangedEventData data) async {
                final newZoom = data.cameraState.zoom;
                if ((newZoom - _currentZoom).abs() >= 0.3) {
                  _currentZoom = newZoom;
                  await _updateVehicleIconSize();
                }
              },
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

            // ── Map style switcher ─────────────────────────────
            Positioned(
              right: 16,
              top: 140,
              child: MapStyleSwitcherButton(
                mapboxMap: _mapboxMap,
                currentStyleUri:
                    _mapStyleUri ??
                    (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
                onStyleChanged: (uri) async {
                  setState(() => _mapStyleUri = uri);
                  if (controller.history.isNotEmpty) {
                    await _generateConditionalMarkers(
                      controller.history.toList(),
                    );
                  }
                },
              ),
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

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: kWhite, size: 24),
        ),
      ),
    );
  }
}
