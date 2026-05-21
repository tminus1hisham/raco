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
import 'package:flutter/scheduler.dart' show Ticker;
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

  // Continuous motion loop. A single Ticker drives the marker at frame rate
  // along the entire matched route. Replaces the previous per-segment
  // AnimationController approach — segment-restart caused micro-stalls and
  // re-snapped the bearing curve at every vertex.
  Ticker? _movementTicker;
  // Distance travelled along the route, in metres. Position is derived from
  // this value by binary-searching [_cumDist].
  double _progressMeters = 0.0;
  int _lastTickMs = 0;
  // Throttles the per-frame ValueNotifier updates so the info panel /
  // scrubber rebuild ~12 fps instead of 60 fps.
  int _lastIndexEmitMs = 0;
  // Cumulative distance to each route vertex (length == _routeCoords.length).
  // _cumDist[i] is the distance from coords[0] to coords[i] in metres.
  List<double> _cumDist = const [];
  // Bearing of each route segment (length == _routeCoords.length - 1).
  List<double> _segmentBearings = const [];
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

  // Road-snapped polyline coordinates from the Map Matching API. The vehicle
  // animates along THESE (not raw GPS) so it stays exactly on the drawn route.
  List<Position> _routeCoords = [];
  // For each entry in [_routeCoords], the index of the nearest raw history
  // record. Powers the info panel + scrubber so on-screen telemetry still
  // reflects real GPS timestamps/speeds even though the marker walks a
  // snapped path.
  List<int> _routeToHistoryIdx = [];

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
    });
    _movementTicker?.stop();
    _progressMeters = 0.0;
    _markerVisible = false;
    _currentIndexNotifier.value = 0;
    _routeCoords = [];
    _routeToHistoryIdx = [];
    _cumDist = const [];
    _segmentBearings = const [];

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

    // Fetch road-snapped coordinates once, then reuse across style switches.
    // _fetchHistoryData clears the cache when the date range changes.
    if (_routeCoords.isEmpty) {
      final lineCoords = await _fetchMatchedRoute(history);
      if (lineCoords.isEmpty) return;
      _routeCoords = lineCoords;
      _routeToHistoryIdx = _mapRouteToHistory(lineCoords, history);
      _computeRouteMetrics();
    }

    _polylineAnnotationManager ??= await _mapboxMap!.annotations
        .createPolylineAnnotationManager();

    try {
      _polylineAnnotationManager?.deleteAll();
    } catch (_) {}

    await _polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: _routeCoords),
        lineColor: 0xFF2563EB,
        lineWidth: 4.5,
        lineOpacity: 0.85,
      ),
    );
  }

  /// Pre-computes cumulative arc-length and segment bearings for
  /// [_routeCoords]. Called once per route fetch; the motion loop and the
  /// lookahead bearing rely on these arrays being in sync with the geometry.
  void _computeRouteMetrics() {
    if (_routeCoords.length < 2) {
      _cumDist = _routeCoords.isEmpty ? const [] : [0.0];
      _segmentBearings = const [];
      return;
    }
    final n = _routeCoords.length;
    final cum = List<double>.filled(n, 0.0);
    final bearings = List<double>.filled(n - 1, 0.0);
    double sum = 0.0;
    for (int i = 0; i < n - 1; i++) {
      final a = _routeCoords[i];
      final b = _routeCoords[i + 1];
      final aLat = a.lat.toDouble(), aLng = a.lng.toDouble();
      final bLat = b.lat.toDouble(), bLng = b.lng.toDouble();
      sum += _haversineDistance(aLat, aLng, bLat, bLng);
      cum[i + 1] = sum;
      bearings[i] = _calculateBearing(LatLng(aLat, aLng), LatLng(bLat, bLng));
    }
    _cumDist = cum;
    _segmentBearings = bearings;
  }

  /// Builds a length-N list mapping each matched route coord to the nearest
  /// raw [history] index. Walks monotonically forward with a hint to stay
  /// O(n+m) on long trips; never lets the hint regress so the resolved raw
  /// index stays in temporal order even if the matched geometry briefly
  /// loops back near a previously-visited road.
  List<int> _mapRouteToHistory(
    List<Position> route,
    List<DeviceRecord> history,
  ) {
    if (route.isEmpty || history.isEmpty) return [];
    final result = List<int>.filled(route.length, 0);
    int hint = 0;
    for (int i = 0; i < route.length; i++) {
      final pLat = route[i].lat.toDouble();
      final pLng = route[i].lng.toDouble();
      int bestIdx = hint;
      double bestDist = double.infinity;
      final end = math.min(history.length, hint + 200);
      for (int j = hint; j < end; j++) {
        final r = history[j];
        if (!r.hasValidCoords) continue;
        final d = _haversineDistance(pLat, pLng, r.latD, r.lngD);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = j;
        }
      }
      if (bestIdx > hint) hint = bestIdx;
      result[i] = bestIdx;
    }
    return result;
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

    // Place the vehicle on the matched route's first vertex (not raw GPS)
    // so it sits exactly on the drawn polyline from frame 0.
    final initialPos = _routeCoords.isNotEmpty
        ? _routeCoords.first
        : Position(startRec.lngD, startRec.latD);
    final bearing = (_routeCoords.isNotEmpty && _cumDist.length >= 2)
        ? _lookaheadBearing(0.0)
        : _getCurrentBearing(history, 0);
    _currentBearing = bearing;
    _progressMeters = 0.0;
    _vehicleAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: initialPos),
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
    // _generateConditionalMarkers always places the vehicle at route index 0
    // with iconOpacity 0.0. Restore the correct position on the matched
    // route (not raw GPS) and make it visible if playback was started before
    // the style switch.
    if (_markerVisible &&
        _vehicleAnnotation != null &&
        _annotationManager != null &&
        _routeCoords.isNotEmpty) {
      final idx = _currentIndex.clamp(0, _routeCoords.length - 1);
      _vehicleAnnotation!.geometry = Point(coordinates: _routeCoords[idx]);
      _vehicleAnnotation!.iconRotate = _currentBearing;
      _vehicleAnnotation!.iconOpacity = 1.0;
      await _annotationManager!.update(_vehicleAnnotation!);
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
      if (_routeCoords.isNotEmpty) {
        final pos = _routeCoords[_currentIndex.clamp(0, _routeCoords.length - 1)];
        await _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: pos),
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

  // ─── CONTINUOUS-MOTION ENGINE ────────────────────────────────────────────
  //
  // The vehicle's position is a single scalar: [_progressMeters] along the
  // route. A Ticker advances that scalar by speed × dt every frame, and
  // [_renderAtProgress] turns it back into (lng, lat, bearing).
  //
  // This replaces the previous segment-by-segment AnimationController model
  // which restarted a new curve at every vertex of the matched route, causing
  // micro-stalls between segments and re-snapping the bearing baseline each
  // time. With one continuous loop, motion has no boundaries — the bearing
  // chases a lookahead point smoothly through corners, exactly like a driver
  // looking ahead instead of at the bumper.

  void _ensureTicker() {
    _movementTicker ??= createTicker(_onTick);
  }

  void _onTick(Duration _) {
    if (!_isPlaying) return;
    if (_routeCoords.length < 2 || _cumDist.length < 2) return;
    final totalDist = _cumDist.last;
    if (totalDist <= 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // First tick after start/resume has no baseline — assume one 60 fps frame
    // so we don't jump forward by however long the app was paused.
    final dtMs = _lastTickMs == 0 ? 16 : (now - _lastTickMs).clamp(1, 100);
    _lastTickMs = now;
    final dtSec = dtMs / 1000.0;

    // Base playback rate: 100 m/s at _playbackSpeed = 1.0. Default 0.5×
    // → 50 m/s (~180 km/h), matching the old `dist * 10ms` pacing.
    final curveScale = _speedScaleForCurve(_progressMeters);
    final speedMps = 100.0 * _playbackSpeed * curveScale;

    _progressMeters += speedMps * dtSec;

    if (_progressMeters >= totalDist) {
      _progressMeters = totalDist;
      _renderAtProgress(_progressMeters);
      _onPlaybackComplete();
      return;
    }

    _renderAtProgress(_progressMeters);
  }

  /// Renders the marker + camera at a given distance along the route.
  /// Safe to call from outside the ticker (used by scrub/stop/seek).
  void _renderAtProgress(double prog) {
    if (_vehicleAnnotation == null || _annotationManager == null) return;
    if (_routeCoords.length < 2 || _cumDist.length < 2) return;

    final seg = _findSegment(prog);
    final segStart = _cumDist[seg];
    final segLen = _cumDist[seg + 1] - segStart;
    final t = segLen > 0 ? ((prog - segStart) / segLen).clamp(0.0, 1.0) : 0.0;

    final a = _routeCoords[seg];
    final b = _routeCoords[seg + 1];
    final aLng = a.lng.toDouble(), aLat = a.lat.toDouble();
    final bLng = b.lng.toDouble(), bLat = b.lat.toDouble();
    final lng = aLng + (bLng - aLng) * t;
    final lat = aLat + (bLat - aLat) * t;

    // Smooth bearing toward a lookahead point ~12 m ahead. Per-frame lerp at
    // 0.18 gives a ~110 ms time constant: anticipates corners (because the
    // lookahead enters the curve before we do), then straightens gradually
    // as the lookahead exits — exactly how a human driver steers.
    final targetBearing = _lookaheadBearing(prog);
    final diff = ((targetBearing - _currentBearing + 180) % 360) - 180;
    _currentBearing = (_currentBearing + diff * 0.18 + 360) % 360;

    _vehicleAnnotation!.geometry = Point(coordinates: Position(lng, lat));
    _vehicleAnnotation!.iconRotate = _currentBearing;
    _annotationManager!.update(_vehicleAnnotation!);

    // Per-frame instantaneous camera. setCamera is intentional — easeTo at
    // 60 fps stacks overlapping animations and visibly lags. In immersive
    // mode pitch/zoom are pinned each frame so pinch corrections cannot
    // flatten the view mid-playback.
    try {
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          bearing:
              (_headingUp || _isImmersiveMode) ? _currentBearing : null,
          pitch: _isImmersiveMode ? 82.0 : null,
          zoom: _isImmersiveMode ? 18.0 : null,
        ),
      );
    } catch (_) {}

    // Throttle scrubber / info-panel updates to ~12 fps. UI doesn't need
    // 60 fps and full ValueListenable rebuilds at frame rate cost frames.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (seg != _currentIndex && nowMs - _lastIndexEmitMs > 80) {
      _lastIndexEmitMs = nowMs;
      _currentIndex = seg;
      _currentIndexNotifier.value = seg;
    }
  }

  void _onPlaybackComplete() {
    _movementTicker?.stop();
    if (mounted) setState(() => _isPlaying = false);
  }

  /// Binary-searches for the segment that contains [prog]: the largest i with
  /// _cumDist[i] ≤ prog. Returns a value in [0, _cumDist.length - 2].
  int _findSegment(double prog) {
    if (_cumDist.length < 2) return 0;
    if (prog <= 0) return 0;
    if (prog >= _cumDist.last) return _cumDist.length - 2;
    int lo = 0, hi = _cumDist.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_cumDist[mid] <= prog) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  (double lat, double lng) _positionAtProgress(double prog) {
    final seg = _findSegment(prog);
    final segStart = _cumDist[seg];
    final segLen = _cumDist[seg + 1] - segStart;
    final t = segLen > 0 ? ((prog - segStart) / segLen).clamp(0.0, 1.0) : 0.0;
    final a = _routeCoords[seg];
    final b = _routeCoords[seg + 1];
    return (
      a.lat.toDouble() + (b.lat.toDouble() - a.lat.toDouble()) * t,
      a.lng.toDouble() + (b.lng.toDouble() - a.lng.toDouble()) * t,
    );
  }

  /// Bearing from the current position toward a point [_kLookAheadMeters]
  /// ahead along the route. Clamps to the end so we don't try to look past
  /// the route's tail.
  double _lookaheadBearing(double prog) {
    if (_routeCoords.length < 2 || _cumDist.length < 2) return _currentBearing;
    const double lookAheadMeters = 12.0;
    final totalDist = _cumDist.last;
    final lookProg = math.min(prog + lookAheadMeters, totalDist);

    // If we're at the end and can't see further forward, fall back to the
    // last segment's heading so the marker doesn't spin to north.
    if (lookProg - prog < 0.5) {
      return _segmentBearings.isNotEmpty
          ? _segmentBearings.last
          : _currentBearing;
    }

    final cur = _positionAtProgress(prog);
    final look = _positionAtProgress(lookProg);
    return _calculateBearing(
      LatLng(cur.$1, cur.$2),
      LatLng(look.$1, look.$2),
    );
  }

  /// Drops playback speed through tight corners. Looks ~25 m ahead for the
  /// sharpest segment-to-segment bend; ≥60° turn slows to 55%, ≤10° turn
  /// keeps full speed, with a linear ramp between. Real vehicles brake
  /// before corners and accelerate out — this is the most legible part of
  /// "realistic" motion at playback scales.
  double _speedScaleForCurve(double prog) {
    if (_segmentBearings.length < 2) return 1.0;
    const double lookAheadMeters = 25.0;
    final totalDist = _cumDist.last;
    final startSeg = _findSegment(prog);
    final endSeg = _findSegment(math.min(prog + lookAheadMeters, totalDist));
    double maxAbsTurn = 0.0;
    for (int i = startSeg; i < endSeg && i + 1 < _segmentBearings.length; i++) {
      final d = ((_segmentBearings[i + 1] - _segmentBearings[i] + 180) % 360) - 180;
      final absD = d.abs();
      if (absD > maxAbsTurn) maxAbsTurn = absD;
    }
    if (maxAbsTurn <= 10) return 1.0;
    if (maxAbsTurn >= 60) return 0.55;
    return (1.0 - (maxAbsTurn - 10) / 100).clamp(0.55, 1.0);
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

  int _getIgnitionStatus(DeviceRecord record) {
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;
  }

  // ─── PLAYBACK CONTROLS ───────────────────────────────────────────────────

  void _startPlayback() {
    if (_isPlaying || _routeCoords.length < 2 || _cumDist.length < 2) return;
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
    _progressMeters = 0.0;
    _lastTickMs = 0;
    // Snap bearing to the road heading at the start so the icon doesn't
    // enter mid-turn from a stale value.
    _currentBearing = _lookaheadBearing(0.0);
    _renderAtProgress(0.0);
    _ensureTicker();
    if (!(_movementTicker!.isActive)) _movementTicker!.start();
  }

  void _pausePlayback() {
    setState(() => _isPlaying = false);
    _movementTicker?.stop();
  }

  void _resumePlayback() {
    if (_isPlaying || _routeCoords.length < 2 || _cumDist.length < 2) return;
    if (_progressMeters >= _cumDist.last) return; // already at end
    setState(() => _isPlaying = true);
    _lastTickMs = 0;
    _ensureTicker();
    if (!(_movementTicker!.isActive)) _movementTicker!.start();
  }

  void _stopPlayback() {
    _movementTicker?.stop();
    _progressMeters = 0.0;
    _lastTickMs = 0;
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
    });
    _currentIndexNotifier.value = 0;
    if (_routeCoords.length >= 2 && _cumDist.length >= 2) {
      _currentBearing = _lookaheadBearing(0.0);
      _renderAtProgress(0.0);
    }
  }

  void _updatePlaybackSpeed(double newSpeed) {
    setState(() => _playbackSpeed = newSpeed);
  }

  void _seekTo(int index) {
    if (_routeCoords.length < 2 || _cumDist.length < 2) return;
    final clamped = index.clamp(0, _routeCoords.length - 1);
    _movementTicker?.stop();
    setState(() {
      _isPlaying = false;
      _currentIndex = clamped;
    });
    _currentIndexNotifier.value = clamped;
    _progressMeters = _cumDist[clamped];
    _lastTickMs = 0;
    // Snap bearing fully on big jumps so the marker doesn't slowly rotate
    // toward the new road heading after the scrub.
    _currentBearing = _lookaheadBearing(_progressMeters);
    _renderAtProgress(_progressMeters);
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
    _movementTicker?.dispose();
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
                  // Apply the rotation now so the toggle works whether or
                  // not playback is running. (The ticker only fires while
                  // playing; without this, paused users would see no
                  // visible effect until they hit Play.)
                  _mapboxMap?.setCamera(
                    CameraOptions(bearing: _headingUp ? _currentBearing : 0.0),
                  );
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
                      // `idx` walks the matched route; resolve back to the
                      // nearest raw record so telemetry (speed/time/ignition)
                      // reflects real GPS, not the snapped vertex.
                      final histIdx = (idx < _routeToHistoryIdx.length)
                          ? _routeToHistoryIdx[idx]
                              .clamp(0, historyList.length - 1)
                          : (historyList.length - 1).clamp(0, historyList.length - 1);
                      final rec = historyList[histIdx];
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
                        // Scrubber walks the matched route (what the user
                        // sees) — not raw GPS, which would put the thumb out
                        // of sync with the vehicle.
                        final total = _routeCoords.length;
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
                            onChanged: (val) => _seekTo(val.round()),
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
                          onPressed: () => _seekTo(0),
                          col: col,
                        ),
                        // Play / Pause — large centre button
                        GestureDetector(
                          onTap: () => _isPlaying
                              ? _pausePlayback()
                              : (_currentIndex == 0
                                    ? _startPlayback()
                                    : _resumePlayback()),
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
