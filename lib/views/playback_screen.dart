import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:http/http.dart' as http;
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

const _kMapboxToken =
    'pk.eyJ1Ijoic2h1bGVkcml2ZSIsImEiOiJjbWx0azl0c2gwMTBrM2NzaDVmMnV4a2Q2In0.4nKQxxM4e2DcmF110KhyyA';

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
  // Drives the info-panel rebuild without calling setState on the full tree.
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);
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

  // When true the map bearing rotates to match the vehicle heading.
  bool _headingUp = false;

  // When true the map switches to Standard style with 82° pitch (3D immersive).
  bool _isImmersiveMode = false;
  // Stores the style and zoom active before entering immersive for restoration.
  String? _preImmersiveStyleUri;
  double _preImmersiveZoom = 15.0;

  // Tracks whether the vehicle marker has been made visible (play pressed at
  // least once). Used to restore opacity correctly after a style switch.
  bool _markerVisible = false;

  // Map style
  String? _mapStyleUri;

  // Map readiness
  final Completer<void> _mapReadyCompleter = Completer<void>();
  bool _isMapReady = false;

  // Annotation layer management
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _vehicleAnnotation;
  PolylineAnnotationManager? _polylineAnnotationManager;

  // Cached marker bitmaps — computed once, reused across style switches.
  Uint8List? _startMarkerImg;
  Uint8List? _stopMarkerImg;

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
    _markerVisible = false;
    _currentIndexNotifier.value = 0;

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

  /// Calls the Mapbox Map Matching API to snap [history] GPS points onto the
  /// actual road network. Chunks the history into batches of 50 (API max is
  /// 100; 50 keeps URLs short and avoids rate-limit bursts). Falls back to the
  /// raw GPS position for any chunk whose API call fails.
  Future<List<Position>> _fetchMatchedRoute(List<DeviceRecord> history) async {
    const int chunkSize = 50;
    final valid = history.where((r) => r.hasValidCoords).toList();
    if (valid.isEmpty) return [];

    final matched = <Position>[];

    for (int i = 0; i < valid.length; i += chunkSize) {
      final chunk = valid.sublist(
        i,
        (i + chunkSize).clamp(0, valid.length),
      );
      // Map Matching requires at least 2 points.
      if (chunk.length < 2) {
        matched.addAll(chunk.map((r) => Position(r.lngD, r.latD)));
        continue;
      }

      final coords = chunk.map((r) => '${r.lngD},${r.latD}').join(';');
      final uri = Uri.parse(
        'https://api.mapbox.com/matching/v5/mapbox/driving/$coords'
        '?geometries=geojson&tidy=true&access_token=$_kMapboxToken',
      );

      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final matchings = body['matchings'] as List?;
          if (matchings != null && matchings.isNotEmpty) {
            final rawCoords =
                matchings[0]['geometry']['coordinates'] as List;
            matched.addAll(
              rawCoords.map<Position>((c) => Position(
                (c[0] as num).toDouble(),
                (c[1] as num).toDouble(),
              )),
            );
            continue;
          }
        }
      } catch (_) {}

      // Fallback: use raw GPS coords for this chunk.
      matched.addAll(chunk.map((r) => Position(r.lngD, r.latD)));
    }

    return matched;
  }

  Future<void> _drawRoute(List<DeviceRecord> history) async {
    if (_mapboxMap == null || history.isEmpty) return;

    // Fetch road-snapped coordinates from the Map Matching API.
    // Falls back to straight GPS lines for any chunk that fails.
    final lineCoords = await _fetchMatchedRoute(history);
    if (lineCoords.isEmpty) return;

    _polylineAnnotationManager ??= await _mapboxMap!.annotations
        .createPolylineAnnotationManager();

    try {
      _polylineAnnotationManager?.deleteAll();
    } catch (_) {}

    await _polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: lineCoords),
        lineColor: 0xFF2563EB,
        lineWidth: 4.5,
        lineOpacity: 0.85,
      ),
    );
  }

  Future<void> _generateConditionalMarkers(List<DeviceRecord> history) async {
    if (_mapboxMap == null || history.isEmpty) return;

    await _drawRoute(history);

    try {
      _annotationManager?.deleteAll();
    } catch (_) {}
    _vehicleAnnotation = null;

    // Reuse existing manager; only create once per map instance.
    _annotationManager ??= await _mapboxMap!.annotations
        .createPointAnnotationManager();
    await _annotationManager!.setIconRotationAlignment(
      IconRotationAlignment.MAP,
    );
    await _annotationManager!.setIconPitchAlignment(IconPitchAlignment.MAP);

    // Cache start/stop bitmaps — canvas rendering is expensive, do it once.
    _startMarkerImg ??= await _createStartMarker();
    _stopMarkerImg ??= await _createStopMarker();
    _carMarkerIcon ??= await _createRotatedMarker('assets/blue_car.png', 0);

    final startRec = history.first;
    await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(startRec.lngD, startRec.latD),
        ),
        image: _startMarkerImg!,
        iconSize: 0.5,
      ),
    );

    final stopRec = history.last;
    await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(stopRec.lngD, stopRec.latD),
        ),
        image: _stopMarkerImg!,
        iconSize: 0.5,
      ),
    );

    final bearing = _getCurrentBearing(history, 0);
    _currentBearing = bearing;
    _lastPosition = Position(startRec.lngD, startRec.latD);
    _vehicleAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(startRec.lngD, startRec.latD),
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

  /// Exponential zoom-to-iconSize, anchored so zoom 15 → 0.7 (smaller icon).
  /// Doubles every 3 zoom levels in; halves every 3 levels out.
  /// zoom 9 → 0.18 | zoom 12 → 0.35 | zoom 15 → 0.7 | zoom 18 → 1.4 (capped)
  double _iconSizeForZoom(double zoom) =>
      (0.7 * math.pow(2.0, (zoom - 15.0) / 3.0)).clamp(0.15, 1.4);

  Future<void> _updateVehicleIconSize() async {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    _vehicleAnnotation!.iconSize = _iconSizeForZoom(_currentZoom);
    await _annotationManager!.update(_vehicleAnnotation!);
  }

  Future<void> _switchMapStyle(String styleUri) async {
    setState(() => _mapStyleUri = styleUri);
    if (_mapboxMap == null) return;
    // Null annotation refs BEFORE the style load completes.
    // The animation listener checks these refs at the top of every tick; if
    // they are null it early-returns — preventing it from updating stale
    // annotation handles on the incoming style and leaving ghost markers.
    _polylineAnnotationManager = null;
    _annotationManager = null;
    _vehicleAnnotation = null;
    await _mapboxMap!.loadStyleURI(styleUri);
    final history = controller.history.toList();
    if (history.isEmpty) return;
    await _generateConditionalMarkers(history);
    // _generateConditionalMarkers always places the vehicle at index 0 with
    // iconOpacity 0.0. Restore the correct position and make it visible if
    // playback was started before the style switch.
    if (_markerVisible && _vehicleAnnotation != null && _annotationManager != null) {
      final idx = _currentIndex.clamp(0, history.length - 1);
      final rec = history[idx];
      if (rec.hasValidCoords) {
        _vehicleAnnotation!.geometry = Point(
          coordinates: Position(rec.lngD, rec.latD),
        );
        _vehicleAnnotation!.iconRotate = _currentBearing;
        _vehicleAnnotation!.iconOpacity = 1.0;
        await _annotationManager!.update(_vehicleAnnotation!);
      }
    }
  }

  Future<void> _toggleImmersiveMode({required bool isDark}) async {
    if (_isImmersiveMode) {
      // ── Exit immersive ────────────────────────────────────────────────────
      setState(() => _isImmersiveMode = false);
      final restoreStyle = _preImmersiveStyleUri ??
          (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS);
      final restoreZoom = _preImmersiveZoom;
      _preImmersiveStyleUri = null;
      await _switchMapStyle(restoreStyle);
      await _mapboxMap?.flyTo(
        CameraOptions(pitch: 0.0, bearing: 0.0, zoom: restoreZoom),
        MapAnimationOptions(duration: 1200, startDelay: 0),
      );
    } else {
      // ── Enter immersive ───────────────────────────────────────────────────
      _preImmersiveStyleUri = _mapStyleUri ??
          (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS);
      _preImmersiveZoom = _currentZoom;
      setState(() => _isImmersiveMode = true);
      await _switchMapStyle(MapboxStyles.STANDARD);
      final history = controller.history;
      if (history.isNotEmpty) {
        final rec = history[_currentIndex.clamp(0, history.length - 1)];
        if (rec.hasValidCoords) {
          await _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(rec.lngD, rec.latD)),
              // 82° pitch + zoom 18 places the camera at near-building eye-level,
              // looking almost horizontally along the road — matching the
              // "elevated building" perspective of Google's immersive view.
              pitch: 82.0,
              zoom: 18.0,
              bearing: _currentBearing,
            ),
            MapAnimationOptions(duration: 2500, startDelay: 0),
          );
        }
      }
    }
  }

  void _updateVehicleMarker(int index, List<DeviceRecord> history) {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    if (index < 0 || index >= history.length) return;

    final rec = history[index];
    if (!rec.hasValidCoords) {
      if (_isPlaying) Future.microtask(() => _playNextSegment(history));
      return;
    }

    final targetBearing = _getLookaheadBearing(history, index);
    final newPosition = Position(rec.lngD, rec.latD);

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
        if (now - lastFrameTime < 16) return; // ~60 FPS
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

        // Camera tracks the interpolated vehicle position every frame.
        // setCamera (instantaneous) is used instead of easeTo — calling
        // easeTo 60×/second stacks overlapping animations and causes lag.
        // In immersive mode: lock pitch to 82° and zoom to 18 every frame so
        // user pinch-zoom or SDK corrections cannot flatten the view mid-playback.
        try {
          _mapboxMap?.setCamera(
            CameraOptions(
              center: Point(coordinates: Position(currentLng, currentLat)),
              bearing: (_headingUp || _isImmersiveMode)
                  ? interpolatedBearing
                  : null,
              pitch: _isImmersiveMode ? 82.0 : null,
              zoom: _isImmersiveMode ? 18.0 : null,
            ),
          );
        } catch (_) {}
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
      if (!r.hasValidCoords) continue;
      if (r.latD < minLat) minLat = r.latD;
      if (r.latD > maxLat) maxLat = r.latD;
      if (r.lngD < minLng) minLng = r.lngD;
      if (r.lngD > maxLng) maxLng = r.lngD;
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
              history.first.lngD,
              history.first.latD,
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
        LatLng(history[currentIndex - 1].latD, history[currentIndex - 1].lngD),
        LatLng(history[currentIndex + 1].latD, history[currentIndex + 1].lngD),
      );
    } else if (currentIndex > 0) {
      return _calculateBearing(
        LatLng(history[currentIndex - 1].latD, history[currentIndex - 1].lngD),
        LatLng(currentRecord.latD, currentRecord.lngD),
      );
    } else if (currentIndex < history.length - 1) {
      return _calculateBearing(
        LatLng(currentRecord.latD, currentRecord.lngD),
        LatLng(history[currentIndex + 1].latD, history[currentIndex + 1].lngD),
      );
    }
    return 0.0;
  }

  /// Bearing from [history[index]] toward the first point ≥5 m ahead within
  /// 3 steps. Smooths jerky heading at tight GPS bends where a single noisy
  /// point would otherwise cause an abrupt rotation. Falls back to
  /// [_getCurrentBearing] when no lookahead point qualifies.
  double _getLookaheadBearing(List<DeviceRecord> history, int index) {
    const int lookahead = 3;
    const double minDistMetres = 5.0;
    final origin = history[index];
    final limit = (index + lookahead).clamp(0, history.length - 1);
    for (int i = index + 1; i <= limit; i++) {
      final c = history[i];
      if (!c.hasValidCoords) continue;
      final dist = _haversineDistance(
        origin.latD, origin.lngD, c.latD, c.lngD,
      );
      if (dist >= minDistMetres) {
        return _calculateBearing(
          LatLng(origin.latD, origin.lngD),
          LatLng(c.latD, c.lngD),
        );
      }
    }
    return _getCurrentBearing(history, index);
  }

  int _getIgnitionStatus(DeviceRecord record) {
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;
  }

  // ─── PLAYBACK CONTROLS ───────────────────────────────────────────────────

  void _startPlayback(List<DeviceRecord> history) {
    if (_isPlaying || history.isEmpty) return;
    _markerVisible = true;
    if (_vehicleAnnotation != null && _annotationManager != null) {
      _vehicleAnnotation!.iconOpacity = 1.0;
      _annotationManager!.update(_vehicleAnnotation!);
    }
    setState(() {
      _isPlaying = true;
      _currentIndex = 0;
    });
    _currentIndexNotifier.value = 0;
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
    _currentIndexNotifier.value = 0;
    final history = controller.history.toList();
    if (history.isNotEmpty) {
      _updateVehicleMarker(0, history);
    }
  }

  void _updatePlaybackSpeed(double newSpeed) {
    setState(() => _playbackSpeed = newSpeed);
  }

  void _seekTo(int index, List<DeviceRecord> history) {
    if (history.isEmpty) return;
    final clamped = index.clamp(0, history.length - 1);
    _pausePlayback();
    _markerAnimController?.stop();
    _lastPosition = null;
    setState(() => _currentIndex = clamped);
    _currentIndexNotifier.value = clamped;
    _updateVehicleMarker(clamped, history);
  }

  void _playNextSegment(List<DeviceRecord> history) {
    if (!_isPlaying || _currentIndex >= history.length - 1) {
      setState(() => _isPlaying = false);
      return;
    }

    _currentIndex++;
    _currentIndexNotifier.value = _currentIndex;

    final current = history[_currentIndex];
    if (!current.hasValidCoords) {
      _updateVehicleMarker(_currentIndex, history);
      return;
    }

    _updateVehicleMarker(_currentIndex, history);
    // Camera is now driven per-frame inside _updateVehicleMarker's animation
    // listener via setCamera — no separate easeTo call needed here.
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

  Widget _buildDateChip({
    required AppColors col,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    final hasDate = selectedDate != null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasDate
                ? kBlue.withValues(alpha: 0.08)
                : col.border.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kRadiusMD),
            border: Border.all(
              color: hasDate ? kBlue.withValues(alpha: 0.45) : col.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 14,
                color: hasDate ? kBlue : col.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: col.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hasDate
                          ? _dateFormat.format(selectedDate)
                          : 'Pick date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasDate ? col.textPrimary : col.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _markerAnimController?.dispose();
    _currentIndexNotifier.dispose();
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
      // MapWidget lives outside Obx so it is never unmounted during loading or
      // re-fetches. Unmounting destroys the GL surface and forces full re-init.
      body: Stack(
        children: [
          MapWidget(
            styleUri:
                _mapStyleUri ??
                (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
            // Static initial position — real camera is set by _fitCameraToBounds.
            // Constant value means MapWidget never sees a prop change on rebuilds.
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(0, 0)),
              zoom: 2.0,
            ),
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
              setState(() {});
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

          // ── Map style switcher — always visible once map exists ──
          Positioned(
            right: 16,
            top: 140,
            child: MapStyleSwitcherButton(
              mapboxMap: _mapboxMap,
              currentStyleUri:
                  _mapStyleUri ??
                  (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
              onStyleChanged: (uri) {
                // Manually switching styles exits immersive mode so the
                // pitch/bearing state stays consistent.
                if (_isImmersiveMode) {
                  setState(() {
                    _isImmersiveMode = false;
                    _preImmersiveStyleUri = null;
                  });
                  _mapboxMap?.setCamera(
                    CameraOptions(pitch: 0.0, bearing: 0.0),
                  );
                }
                _switchMapStyle(uri);
              },
            ),
          ),

          // ── Heading-up toggle ──────────────────────────────────────────────
          Positioned(
            right: 16,
            top: 196, // style button top(140) + height(44) + gap(12)
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: InkWell(
                onTap: () {
                  setState(() => _headingUp = !_headingUp);
                  if (!_headingUp) {
                    // Snap back to north-up when toggled off.
                    _mapboxMap?.setCamera(CameraOptions(bearing: 0.0));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _headingUp
                        ? kBlue.withValues(alpha: 0.15)
                        : col.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _headingUp ? kBlue : Colors.transparent,
                      width: _headingUp ? 1.5 : 0,
                    ),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: _headingUp ? kBlue : col.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // ── Immersive 3D mode toggle ───────────────────────────────────────
          // Positioned(
          //   right: 16,
          //   top: 252, // heading button top(196) + height(44) + gap(12)
          //   child: Material(
          //     elevation: 4,
          //     borderRadius: BorderRadius.circular(12),
          //     shadowColor: Colors.black.withValues(alpha: 0.2),
          //     child: InkWell(
          //       onTap: () => _toggleImmersiveMode(isDark: isDark),
          //       borderRadius: BorderRadius.circular(12),
          //       child: Container(
          //         width: 44,
          //         height: 44,
          //         decoration: BoxDecoration(
          //           color: _isImmersiveMode
          //               ? kBlue.withValues(alpha: 0.15)
          //               : col.surface,
          //           borderRadius: BorderRadius.circular(12),
          //           border: Border.all(
          //             color: _isImmersiveMode ? kBlue : Colors.transparent,
          //             width: _isImmersiveMode ? 1.5 : 0,
          //           ),
          //         ),
          //         child: Icon(
          //           _isImmersiveMode
          //               ? Icons.map_rounded
          //               : Icons.threed_rotation,
          //           color: _isImmersiveMode ? kBlue : col.textPrimary,
          //           size: 22,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // ── Reactive overlay: loading / empty-state / active UI ──
          Obx(() {
            // Loading overlay — semi-transparent so the map stays visible.
            if (controller.isLoading.value) {
              return Container(
                color: col.surface.withValues(alpha: 0.85),
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: kBlue,
                    size: 50,
                  ),
                ),
              );
            }

            final history = controller.history;

            if (history.isEmpty) {
              return Container(
                color: col.bg,
                child: Center(
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
                            _buildDateChip(
                              col: col,
                              label: 'Start Date',
                              selectedDate: _startDate,
                              onTap: () => _pickStartDate(context),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: col.textSecondary,
                              ),
                            ),
                            _buildDateChip(
                              col: col,
                              label: 'End Date',
                              selectedDate: _endDate,
                              onTap: () => _pickEndDate(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final historyList = history.toList();

            return Stack(
              children: [
                // ── Info panel — rebuilt only when index changes ──
                Positioned(
                  top: 16,
                  left: 16,
                  right: 80,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (_, idx, __) {
                      final rec = historyList[idx];
                      final ignition = _getIgnitionStatus(rec);
                      final speed =
                          double.tryParse(rec.spd.toString()) ?? 0.0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: col.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(kRadiusLG),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.numberPlate,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        size: 13,
                                        color: col.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${speed.toStringAsFixed(0)} km/h',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: speed > 0
                                              ? kBlue
                                              : col.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: col.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _utils.formatTime(
                                            rec.createdAt.toString(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: col.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: ignition == 1
                                    ? kSuccessGreen.withValues(alpha: 0.12)
                                    : col.border.withValues(alpha: 0.25),
                                borderRadius:
                                    BorderRadius.circular(kRadiusPill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: ignition == 1
                                          ? kSuccessGreen
                                          : col.textSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ignition == 1 ? 'Moving' : 'Idle',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ignition == 1
                                          ? kSuccessGreen
                                          : col.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

            // ── Bottom controls panel ──────────────────────────
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(kRadiusLG),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date row
                    Row(
                      children: [
                        _buildDateChip(
                          col: col,
                          label: 'Start Date',
                          selectedDate: _startDate,
                          onTap: () => _pickStartDate(context),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: col.textSecondary,
                          ),
                        ),
                        _buildDateChip(
                          col: col,
                          label: 'End Date',
                          selectedDate: _endDate,
                          onTap: () => _pickEndDate(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress scrubber
                    ValueListenableBuilder<int>(
                      valueListenable: _currentIndexNotifier,
                      builder: (_, idx, __) {
                        final total = historyList.length;
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: kBlue,
                            inactiveTrackColor:
                                col.border.withValues(alpha: 0.5),
                            thumbColor: kBlue,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayColor: kBlue.withValues(alpha: 0.15),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: idx.toDouble(),
                            min: 0,
                            max: (total - 1).toDouble().clamp(1, double.infinity),
                            onChanged: (val) =>
                                _seekTo(val.round(), historyList),
                          ),
                        );
                      },
                    ),
                    // Transport controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Slower
                        _PlaybackIconButton(
                          icon: Icons.remove_rounded,
                          onPressed: () => _updatePlaybackSpeed(
                            (_playbackSpeed - 1).clamp(0.5, 5.0),
                          ),
                          col: col,
                        ),
                        // Restart
                        _PlaybackIconButton(
                          icon: Icons.skip_previous_rounded,
                          onPressed: () => _seekTo(0, historyList),
                          col: col,
                        ),
                        // Play / Pause — large centre button
                        GestureDetector(
                          onTap: () => _isPlaying
                              ? _pausePlayback()
                              : (_currentIndex == 0
                                    ? _startPlayback(historyList)
                                    : _resumePlayback(historyList)),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: kBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kBlue.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: kWhite,
                              size: 30,
                            ),
                          ),
                        ),
                        // Stop / reset
                        _PlaybackIconButton(
                          icon: Icons.stop_rounded,
                          onPressed: _stopPlayback,
                          col: col,
                          color: kRed,
                        ),
                        // Faster
                        _PlaybackIconButton(
                          icon: Icons.add_rounded,
                          onPressed: () => _updatePlaybackSpeed(
                            (_playbackSpeed + 1).clamp(0.5, 5.0),
                          ),
                          col: col,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Speed badge + clear
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: kBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                          ),
                          child: Text(
                            '${_playbackSpeed.toStringAsFixed(1)}× speed',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kBlue,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: kRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                          ),
                          onPressed: () => setState(() {
                            _startDate = null;
                            _endDate = null;
                          }),
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 15,
                            color: kRed,
                          ),
                          label: const Text(
                            'Clear Dates',
                            style: TextStyle(
                              color: kRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _PlaybackIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final AppColors col;
  final Color? color;

  const _PlaybackIconButton({
    required this.icon,
    required this.onPressed,
    required this.col,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? col.textPrimary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
