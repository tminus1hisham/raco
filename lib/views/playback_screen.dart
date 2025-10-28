import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/playback_controller.dart';
import 'package:atom/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  final PlaybackController controller = Get.put(PlaybackController());

  Timer? _playbackTimer;
  bool _isAnimatingCamera = false;
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  final Utils _utils = Utils();
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  // CACHE MARKERS AND POLYLINES
  BitmapDescriptor? _carMarkerIcon;
  Set<Polyline> _cachedPolylines = {};
  Map<double, BitmapDescriptor> _bearingMarkerCache = {};
  Completer<void> _mapReadyCompleter = Completer<void>();
  bool _isMapReady = false;
  Set<Marker> _conditionalMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadCarMarker();

    // Start without any selected dates
    _startDate = null;
    _endDate = null;
  }

  Future<void> _fetchHistoryData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _cachedPolylines = {};
      _conditionalMarkers = {};
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
      await _generateConditionalMarkers(controller.history.toList());
      _stopPlayback();
    }
  }

  Future<BitmapDescriptor> _createConditionMarker({
    required Color color,
    required String label,
  }) async {
    const double size = 80;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw colored circle
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    // Add white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2.5,
      borderPaint,
    );

    // Draw label text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
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
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
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

      // Fetch only when both dates are selected
      if (_startDate != null && _endDate != null) {
        _fetchHistoryData();
      }
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
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

      // Fetch only when both dates are selected
      if (_startDate != null && _endDate != null) {
        _fetchHistoryData();
      }
    }
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 80,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null
                      ? kBlue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selectedDate != null ? kBlue : Colors.grey[600],
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
                            color: Colors.grey[600],
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
                                ? Colors.black87
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateConditionalMarkers(List history) async {
    _conditionalMarkers.clear();

    for (int i = 0; i < history.length; i++) {
      final record = history[i];
      final speed = double.tryParse(record.spd.toString()) ?? 0.0;
      final lat = double.tryParse(record.lt.toString());
      final lng = double.tryParse(record.lg.toString());

      if (lat == null || lng == null) continue;

      // Example conditions
      if (speed > 80) {
        // Speeding
        final icon = await _createConditionMarker(
          color: Colors.red,
          label: 'S',
        );
        _conditionalMarkers.add(
          Marker(
            markerId: MarkerId('speeding_$i'),
            position: LatLng(lat, lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      } else if (speed == 0) {
        // Parked
        final icon = await _createConditionMarker(
          color: Colors.orange,
          label: 'P',
        );
        _conditionalMarkers.add(
          Marker(
            markerId: MarkerId('parked_$i'),
            position: LatLng(lat, lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    if (mounted) setState(() {});
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

  Future<BitmapDescriptor> _createRotatedMarker(
    String assetPath,
    double rotation,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);

    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 80,
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

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _getCachedMarker(double bearing) async {
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

  Set<Polyline> _buildGooglePolylines(List history) {
    if (_cachedPolylines.isNotEmpty &&
        history.length == _cachedPolylines.length + 1) {
      return _cachedPolylines;
    }

    final polylines = <Polyline>{};
    final points = <LatLng>[];

    for (int i = 0; i < history.length; i++) {
      points.add(
        LatLng(double.parse(history[i].lt), double.parse(history[i].lg)),
      );
    }

    if (points.length > 1) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: points,
          width: 6,
          color: Colors.blue,
          geodesic: true,
        ),
      );
    }

    _cachedPolylines = polylines;
    return polylines;
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

    double bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  double _getCurrentBearing(List history, int currentIndex) {
    final currentRecord = history[currentIndex];
    final course = double.tryParse(currentRecord.course.toString());

    if (course != null && course >= 0 && course <= 360) {
      return course;
    }

    if (currentIndex > 0 && currentIndex < history.length - 1) {
      final prevPoint = LatLng(
        double.parse(history[currentIndex - 1].lt),
        double.parse(history[currentIndex - 1].lg),
      );
      final nextPoint = LatLng(
        double.parse(history[currentIndex + 1].lt),
        double.parse(history[currentIndex + 1].lg),
      );
      return _calculateBearing(prevPoint, nextPoint);
    } else if (currentIndex > 0) {
      final prevPoint = LatLng(
        double.parse(history[currentIndex - 1].lt),
        double.parse(history[currentIndex - 1].lg),
      );
      final currentPoint = LatLng(
        double.parse(currentRecord.lt),
        double.parse(currentRecord.lg),
      );
      return _calculateBearing(prevPoint, currentPoint);
    } else if (currentIndex < history.length - 1) {
      final currentPoint = LatLng(
        double.parse(currentRecord.lt),
        double.parse(currentRecord.lg),
      );
      final nextPoint = LatLng(
        double.parse(history[currentIndex + 1].lt),
        double.parse(history[currentIndex + 1].lg),
      );
      return _calculateBearing(currentPoint, nextPoint);
    }

    return 0.0;
  }

  int _getIgnitionStatus(dynamic record) {
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;
  }

  void _startPlayback(List history) {
    if (_isPlaying || history.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _currentIndex = 0;
    });

    _playbackTimer?.cancel();

    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (200 ~/ _playbackSpeed)),
      (timer) async {
        if (!_isPlaying || _currentIndex >= history.length - 1) {
          timer.cancel();
          setState(() => _isPlaying = false);
          return;
        }

        if (_isAnimatingCamera) return;

        _currentIndex++;

        final current = history[_currentIndex];
        final nextPoint = LatLng(
          double.parse(current.lt),
          double.parse(current.lg),
        );

        _isAnimatingCamera = true;
        try {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLng(nextPoint),
          );
        } catch (e) {
          debugPrint("Camera animation error: $e");
        } finally {
          _isAnimatingCamera = false;
        }

        setState(() {});
      },
    );
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resumePlayback(List history) {
    if (_isPlaying || history.isEmpty) return;
    setState(() => _isPlaying = true);

    _playbackTimer?.cancel();

    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (200 ~/ _playbackSpeed)),
      (timer) async {
        if (!_isPlaying || _currentIndex >= history.length - 1) {
          timer.cancel();
          setState(() => _isPlaying = false);
          return;
        }

        if (_isAnimatingCamera) return;

        _currentIndex++;

        final current = history[_currentIndex];
        final nextPoint = LatLng(
          double.parse(current.lt),
          double.parse(current.lg),
        );

        _isAnimatingCamera = true;
        try {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLng(nextPoint),
          );
        } catch (e) {
          debugPrint("Camera animation error: $e");
        } finally {
          _isAnimatingCamera = false;
        }

        setState(() {});
      },
    );
  }

  void _updatePlaybackSpeed(double newSpeed) {
    setState(() => _playbackSpeed = newSpeed);

    if (_isPlaying) {
      _playbackTimer?.cancel();
      _playbackTimer = null;
      // Immediately trigger next frame at new speed
      _playbackTick(controller.history.toList());
    }
  }

  void _playbackTick(List history) async {
    final newIndex = _currentIndex + 1;
    final current = history[newIndex];
    final newPosition = LatLng(
      double.parse(current.lt),
      double.parse(current.lg),
    );

    if (newIndex % 2 == 0) {
      final bearing = _getCurrentBearing(history, newIndex);
      _getCachedMarker(bearing).then((marker) {
        if (mounted) {
          setState(() {
            _carMarkerIcon = marker;
          });
        }
      });
    }

    setState(() {
      _currentIndex = newIndex;
    });

    if (_mapController != null && _isMapReady) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Playback",
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kBlue,
        iconTheme: IconThemeData(color: kWhite),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            color: Colors.white,
            child: Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: kBlue,
                size: 50,
              ),
            ),
          );
        }

        final history = controller.history.toList();

        if (history.isEmpty && _startDate != null && _endDate != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 20),
                Text(
                  "No playback data available",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 10),
                Text(
                  "Select a date range to view vehicle history",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildDatePickerButton(
                        label: 'Start Date',
                        selectedDate: _startDate,
                        onTap: () => _pickStartDate(context),
                        icon: Icons.calendar_today,
                      ),
                      SizedBox(width: 12),
                      _buildDatePickerButton(
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

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 20),
                Text(
                  "Select date range to view playback",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildDatePickerButton(
                        label: 'Start Date',
                        selectedDate: _startDate,
                        onTap: () => _pickStartDate(context),
                        icon: Icons.calendar_today,
                      ),
                      SizedBox(width: 12),
                      _buildDatePickerButton(
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
        final currentPoint = LatLng(
          double.parse(currentRecord.lt),
          double.parse(currentRecord.lg),
        );
        final ignitionStatus = _getIgnitionStatus(currentRecord);

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _isMapReady = true;
                _mapReadyCompleter.complete();
              },
              initialCameraPosition: CameraPosition(
                target: currentPoint,
                zoom: 15.0,
              ),
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              polylines: _buildGooglePolylines(history),
              markers: _carMarkerIcon != null
                  ? {
                      Marker(
                        markerId: MarkerId('vehicle'),
                        position: currentPoint,
                        icon: _carMarkerIcon!,
                        anchor: Offset(0.5, 0.5),
                        flat: true,
                        rotation:
                            _getCurrentBearing(history, _currentIndex) - 90,
                      ),
                      ..._conditionalMarkers,
                    }
                  : {},
              onTap: (LatLng position) {},
            ),

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentRecord.rg,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ignitionStatus == 1
                                  ? Colors.green[100]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ignitionStatus == 1 ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: ignitionStatus == 1
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
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

            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Range Pickers
                      Row(
                        children: [
                          _buildDatePickerButton(
                            label: 'Start Date',
                            selectedDate: _startDate,
                            onTap: () => _pickStartDate(context),
                            icon: Icons.calendar_today,
                          ),
                          SizedBox(width: 12),
                          _buildDatePickerButton(
                            label: 'End Date',
                            selectedDate: _endDate,
                            onTap: () => _pickEndDate(context),
                            icon: Icons.event,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Speed Control Slider
                      Row(
                        children: [
                          Icon(
                            Icons.slow_motion_video,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: kBlue,
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: kBlue,
                                overlayColor: kBlue.withOpacity(0.2),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _playbackSpeed,
                                min: 1.0,
                                max: 10.0,
                                divisions: 18,
                                label: '${_playbackSpeed.toStringAsFixed(1)}x',
                                onChanged: (value) =>
                                    _updatePlaybackSpeed(value),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.fast_forward,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_playbackSpeed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Playback Controls
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
                            color: Colors.red[400]!,
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.1,
                              ), // light background
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              "Clear Dates",
                              style: TextStyle(
                                color: Colors.redAccent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
        child: Container(
          width: isLarge ? 60 : 50,
          height: isLarge ? 60 : 50,
          child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
        ),
      ),
    );
  }
}
