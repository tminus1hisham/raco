import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/fetch_geofence_controller.dart';
import 'package:atom/controllers/geo_fence_controller.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/map/map_style_switcher.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class GeofencingScreen extends StatefulWidget {
  final String numberPlate;

  GeofencingScreen({required this.numberPlate, required Device device});

  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolygonAnnotationManager? _polygonAnnotationManager;
  String? _mapStyleUri;
  Point? selectedPoint;
  final GeoFenceController _geoFenceController = GeoFenceController();
  final FetchGeofenceController _fetchGeofenceController =
      FetchGeofenceController();

  final TextEditingController zoneNameController = TextEditingController();

  List<PointAnnotationOptions> markers = [];
  List<PolygonAnnotationOptions> circles = [];
  GeofenceModel? selectedGeofence;
  bool isAddingGeofence = false;
  bool isSaveEnabled = false;
  Uint8List? _centerPinIcon;

  // Radius in kilometres (0.1 – 50 km)
  double radiusKm = 0.5;
  static const double _radiusMin = 0.1;
  static const double _radiusMax = 50.0;

  @override
  void initState() {
    super.initState();
    _buildCenterPinIcon().then((bytes) => setState(() => _centerPinIcon = bytes));
    _loadExistingGeofences();
  }

  Future<Uint8List> _buildCenterPinIcon() async {
    const double w = 48, h = 64;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final fillPaint = ui.Paint()
      ..color = const Color(0xFFFF6B00)
      ..style = ui.PaintingStyle.fill;
    final strokePaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final innerPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    // Pin head (circle)
    const cx = w / 2;
    const cy = w / 2;
    const r = w / 2 - 2;
    canvas.drawCircle(const ui.Offset(cx, cy), r, fillPaint);
    canvas.drawCircle(const ui.Offset(cx, cy), r, strokePaint);

    // Pin tail (triangle pointing down)
    final tail = ui.Path()
      ..moveTo(cx - 10, cy + r - 4)
      ..lineTo(cx, h - 2)
      ..lineTo(cx + 10, cy + r - 4)
      ..close();
    canvas.drawPath(tail, fillPaint);
    canvas.drawPath(tail, strokePaint);

    // Inner dot
    canvas.drawCircle(const ui.Offset(cx, cy), 8, innerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadExistingGeofences() async {
    await _fetchGeofenceController.fetchGeofence(widget.numberPlate);
    setState(() {
      _updateMapMarkers();
    });
  }

  // ── Annotation manager lifecycle ──────────────────────────────────────────
  // Called on EVERY style load (initial creation + style switches).
  // loadStyleURI destroys all native managers immediately, so references must
  // be nulled before a style change and recreated here once the style is ready.

  Future<void> _setupAnnotationManagers() async {
    _pointAnnotationManager = null;
    _polygonAnnotationManager = null;
    if (mapboxMap == null || !mounted) return;

    final polygonManager =
        await mapboxMap!.annotations.createPolygonAnnotationManager();
    if (!mounted) return;
    _polygonAnnotationManager = polygonManager;

    final pointManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    if (!mounted) return;
    _pointAnnotationManager = pointManager;

    await _refreshMapAnnotations();
  }

  // Builds a geodesic circle polygon (an actual radius in metres on the map,
  // which scales correctly with zoom — unlike CircleAnnotation whose radius is
  // measured in screen pixels).
  Polygon _circlePolygon(Position center, double radiusMeters, {int steps = 64}) {
    const earthRadius = 6378137.0; // metres
    final lat = center.lat * math.pi / 180.0;
    final lng = center.lng * math.pi / 180.0;
    final d = radiusMeters / earthRadius;

    final ring = <Position>[];
    for (int i = 0; i <= steps; i++) {
      final bearing = 2 * math.pi * i / steps;
      final lat2 = math.asin(
        math.sin(lat) * math.cos(d) +
            math.cos(lat) * math.sin(d) * math.cos(bearing),
      );
      final lng2 = lng +
          math.atan2(
            math.sin(bearing) * math.sin(d) * math.cos(lat),
            math.cos(d) - math.sin(lat) * math.sin(lat2),
          );
      ring.add(Position(lng2 * 180.0 / math.pi, lat2 * 180.0 / math.pi));
    }
    return Polygon(coordinates: [ring]);
  }

  // Smoothly zooms the camera so the whole radius circle stays visible, keeping
  // the center pinned. Called as the slider changes so growing the radius
  // visibly expands the coverage area (the map eases out) instead of the circle
  // flooding the viewport at a fixed zoom.
  bool _fittingCamera = false;
  Future<void> _fitCameraToRadius(Position center, double radiusMeters) async {
    final map = mapboxMap;
    if (map == null || _fittingCamera) return;
    _fittingCamera = true;
    try {
      await _fitCameraToRadiusInner(map, center, radiusMeters);
    } finally {
      _fittingCamera = false;
    }
  }

  Future<void> _fitCameraToRadiusInner(
    MapboxMap map,
    Position center,
    double radiusMeters,
  ) async {
    // Bounding box of the circle, derived from its ring extremes.
    final ring = _circlePolygon(center, radiusMeters).coordinates.first;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in ring) {
      final lat = p.lat.toDouble();
      final lng = p.lng.toDouble();
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = CoordinateBounds(
      southwest: Point(coordinates: Position(minLng, minLat)),
      northeast: Point(coordinates: Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    final camera = await map.cameraForCoordinateBounds(
      bounds,
      MbxEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
      null,
      null,
      null,
      null,
    );
    if (!mounted) return;

    // Pin the camera on the geofence center and ease there smoothly.
    camera.center = Point(coordinates: center);
    await map.easeTo(camera, MapAnimationOptions(duration: 250));
  }

  // ── Map markers ───────────────────────────────────────────────────────────

  void _updateMapMarkers() {
    markers.clear();
    circles.clear();

    if (selectedGeofence != null) {
      final point = Point(
        coordinates: Position(
          double.parse(selectedGeofence!.longitude),
          double.parse(selectedGeofence!.latitude),
        ),
      );
      markers.add(
        PointAnnotationOptions(
          geometry: point,
          iconSize: 1.5,
          iconImage: "assets/blue_car.png",
          textField: selectedGeofence!.name,
          textSize: 12.0,
        ),
      );
      circles.add(
        PolygonAnnotationOptions(
          // radius is stored in metres
          geometry: _circlePolygon(
            point.coordinates,
            selectedGeofence!.radius.toDouble(),
          ),
          fillColor: kBlue.toARGB32(),
          fillOpacity: 0.6,
          fillOutlineColor: kBlue.toARGB32(),
        ),
      );
    }

    if (isAddingGeofence && selectedPoint != null) {
      markers.add(
        PointAnnotationOptions(
          geometry: selectedPoint!,
          iconSize: 1.0,
          image: _centerPinIcon,
          textField: zoneNameController.text.trim().isNotEmpty
              ? zoneNameController.text.trim()
              : "New Zone",
          textSize: 12.0,
          textOffset: [0.0, 2.5],
        ),
      );
      circles.add(
        PolygonAnnotationOptions(
          geometry: _circlePolygon(selectedPoint!.coordinates, radiusKm * 1000),
          fillColor: kBlue.toARGB32(),
          fillOpacity: 0.08,
          fillOutlineColor: kBlue.toARGB32(),
        ),
      );
    }

    setState(() {});
    _refreshMapAnnotations();
  }

  Future<void> _refreshMapAnnotations() async {
    if (_pointAnnotationManager != null) {
      await _pointAnnotationManager!.deleteAll();
      if (markers.isNotEmpty) {
        await _pointAnnotationManager!.createMulti(markers);
      }
    }
    if (_polygonAnnotationManager != null) {
      await _polygonAnnotationManager!.deleteAll();
      if (circles.isNotEmpty) {
        await _polygonAnnotationManager!.createMulti(circles);
      }
    }
  }

  // ── Interactions ──────────────────────────────────────────────────────────

  void _onMapTap(Point point) {
    if (!isAddingGeofence) return;
    setState(() {
      selectedPoint = point;
      selectedGeofence = null;
    });
    _checkSaveButtonState();
    _updateMapMarkers();
  }

  void _onGeofenceSelected(GeofenceModel? geofence) {
    setState(() {
      selectedGeofence = geofence;
      selectedPoint = null;
    });

    if (geofence != null) {
      final point = Point(
        coordinates: Position(
          double.parse(geofence.longitude),
          double.parse(geofence.latitude),
        ),
      );
      mapboxMap?.flyTo(CameraOptions(center: point, zoom: 14.0), null);
    }

    _updateMapMarkers();
  }

  void _checkSaveButtonState() {
    final hasZoneName = zoneNameController.text.trim().isNotEmpty;
    final hasPin = selectedPoint != null;
    setState(() {
      isSaveEnabled = hasZoneName && hasPin;
    });
  }

  // ── Save geofence ─────────────────────────────────────────────────────────

  Future<void> _addGeofenceZone() async {
    if (selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (zoneNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a zone name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _geoFenceController.numberPlate.value = widget.numberPlate;
    _geoFenceController.fullName.value = zoneNameController.text.trim();
    _geoFenceController.latitude.value = selectedPoint!.coordinates.lat
        .toString();
    _geoFenceController.longitude.value = selectedPoint!.coordinates.lng
        .toString();
    // Store in metres (radius is in km on UI)
    _geoFenceController.radius.value = (radiusKm * 1000).round();

    final success = await _geoFenceController.addGeoFence(context);

    CustomAlertDialog(
      context: context,
      title: success ? "Success" : "Error",
      message: success
          ? "Geofence added successfully"
          : "Failed to add geofence",
      icon: success
          ? "assets/animations/Success.json"
          : "assets/animations/Failed.json",
      buttonColor: success ? kSuccessGreen : kRed,
    );

    if (success) {
      setState(() {
        selectedPoint = null;
        zoneNameController.clear();
        radiusKm = 0.5;
        isAddingGeofence = false;
      });
      await _loadExistingGeofences();
    }
  }

  // ── Delete geofence ───────────────────────────────────────────────────────

  void _confirmDeleteGeofence() {
    if (selectedGeofence == null) return;
    showDialog(
      context: context,
      builder: (_) => ActionDialog(
        title: 'Delete Geofence',
        message: 'Delete "${selectedGeofence!.name}"? This cannot be undone.',
        confirmText: 'Delete',
        onConfirm: _deleteGeofence,
      ),
    );
  }

  Future<void> _deleteGeofence() async {
    if (selectedGeofence == null) return;
    final id = selectedGeofence!.id;
    final success = await _geoFenceController.deleteGeofence(id);

    CustomAlertDialog(
      context: context,
      title: success ? "Deleted" : "Error",
      message: success
          ? "Geofence deleted successfully"
          : "Failed to delete geofence",
      icon: success
          ? "assets/animations/Success.json"
          : "assets/animations/Failed.json",
      buttonColor: success ? kSuccessGreen : kRed,
    );

    if (success) {
      setState(() {
        selectedGeofence = null;
        markers.clear();
        circles.clear();
      });
      await _loadExistingGeofences();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: col.bg,
          appBar: AppBar(
            title: const Text(
              'Geofencing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: Column(
            children: [
              if (!isAddingGeofence) _buildViewPanel(col),
              if (isAddingGeofence) _buildAddPanel(col),
              Expanded(child: _buildMap(isDark)),
              _buildBottomPanel(col),
            ],
          ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  // ── View panel (existing geofences dropdown + status) ─────────────────────

  Widget _buildViewPanel(AppColors col) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: col.surface,
              borderRadius: BorderRadius.circular(kRadiusMD),
              boxShadow: [kShadowSM],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GeofenceModel>(
                isExpanded: true,
                dropdownColor: col.surface,
                hint: Text(
                  'Select existing geofence to view',
                  style: TextStyle(color: col.textSecondary),
                ),
                value: selectedGeofence,
                icon: Icon(Icons.arrow_drop_down, color: col.textSecondary),
                items: _fetchGeofenceController.geofences.map((
                  GeofenceModel geofence,
                ) {
                  return DropdownMenuItem<GeofenceModel>(
                    value: geofence,
                    child: Text(
                      '${geofence.name} (${(geofence.radius / 1000).toStringAsFixed(1)} km)',
                      style: TextStyle(color: col.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: _onGeofenceSelected,
              ),
            ),
          ),

          // Status chip — only shown when a geofence is selected
          if (selectedGeofence != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusChip(isInside: selectedGeofence!.isInsideGeofence),
                const Spacer(),
                Text(
                  'Radius: ${(selectedGeofence!.radius / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: col.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Add panel (zone name + radius slider) ──────────────────────────────────

  Widget _buildAddPanel(AppColors col) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone name
          TextField(
            controller: zoneNameController,
            decoration: InputDecoration(
              hintText: 'Zone name (e.g. Depot A)',
              prefixIcon: const Icon(Icons.label_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSM),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (_) {
              _checkSaveButtonState();
              if (selectedPoint != null) _updateMapMarkers();
            },
          ),

          const SizedBox(height: 12),

          // Radius slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: col.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(kRadiusPill),
                ),
                child: Text(
                  '${radiusKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kBlue,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kBlue,
              thumbColor: kBlue,
              inactiveTrackColor: col.border,
              overlayColor: kBlue.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              min: _radiusMin,
              max: _radiusMax,
              divisions: 499, // 100 m steps
              value: radiusKm,
              onChanged: (value) {
                setState(() => radiusKm = value);
                _updateMapMarkers();
                if (selectedPoint != null) {
                  _fitCameraToRadius(selectedPoint!.coordinates, value * 1000);
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_radiusMin.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 11, color: col.textSecondary),
              ),
              Text(
                '${_radiusMax.toStringAsFixed(0)} km',
                style: TextStyle(fontSize: 11, color: col.textSecondary),
              ),
            ],
          ),

          // Tap-to-place hint
          if (selectedPoint == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Tap on the map to place the center pin',
                    style: TextStyle(
                      fontSize: 12,
                      color: col.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap(bool isDark) {
    final styleUri =
        _mapStyleUri ??
        (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS);
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusLG),
            boxShadow: [kShadowMD],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusLG),
            child: MapWidget(
              styleUri: styleUri,
              cameraOptions: CameraOptions(
                center:
                    selectedPoint ??
                    Point(
                      coordinates: Position(
                        36.816382318562034,
                        -1.2842328448615796,
                      ),
                    ),
                zoom: 13.0,
              ),
              onMapCreated: (MapboxMap map) {
                mapboxMap = map;
                // Managers are created in onStyleLoadedListener so they are
                // recreated on every style change, not just the first load.
                setState(() {});
              },
              onStyleLoadedListener: (_) => _setupAnnotationManagers(),
              onTapListener: (context) => _onMapTap(context.point),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 32,
          child: MapStyleSwitcherButton(
            mapboxMap: mapboxMap,
            currentStyleUri: styleUri,
            onStyleChanged: (uri) {
              // Null managers immediately — they are invalidated the moment
              // loadStyleURI is called on the native side. They will be
              // recreated by _setupAnnotationManagers via onStyleLoadedListener.
              _pointAnnotationManager = null;
              _polygonAnnotationManager = null;
              setState(() => _mapStyleUri = uri);
            },
          ),
        ),
      ],
    );
  }

  // ── Bottom panel ──────────────────────────────────────────────────────────

  Widget _buildBottomPanel(AppColors col) {
    return Container(
      padding: const EdgeInsets.all(kSpaceLG),
      decoration: BoxDecoration(color: col.surface, boxShadow: [kShadowMD]),
      child: Row(
        children: [
          // Cancel / Add Geofence button
          Expanded(
            child: CustomButton(
              callBackFunction: () {
                setState(() {
                  if (isAddingGeofence) {
                    isAddingGeofence = false;
                    selectedPoint = null;
                    zoneNameController.clear();
                    radiusKm = 0.5;
                    _updateMapMarkers();
                  } else {
                    isAddingGeofence = true;
                    selectedGeofence = null;
                    markers.clear();
                    circles.clear();
                  }
                });
              },
              label: isAddingGeofence ? "Cancel" : "Add Geofence",
              backgroundColor: isAddingGeofence ? kRed : kBlue,
              txtColor: kWhite,
            ),
          ),

          // Save button (add mode)
          if (isAddingGeofence) ...[
            const SizedBox(width: kSpaceSM),
            Expanded(
              child: CustomButton(
                callBackFunction: isSaveEnabled ? _addGeofenceZone : () {},
                label: "Save",
                backgroundColor: isSaveEnabled ? kBlue : col.border,
                txtColor: kWhite,
              ),
            ),
          ],

          // Delete button (view mode, geofence selected)
          if (!isAddingGeofence && selectedGeofence != null) ...[
            const SizedBox(width: kSpaceSM),
            Expanded(
              child: CustomButton(
                callBackFunction: _confirmDeleteGeofence,
                label: "Delete",
                backgroundColor: kRed,
                txtColor: kWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Loading overlay ───────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (_geoFenceController.isLoading.value) {
        return Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: kBlue,
              size: 50,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

// ── Status chip widget ─────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isInside;
  const _StatusChip({required this.isInside});

  @override
  Widget build(BuildContext context) {
    final color = isInside ? kSuccessGreen : kRed;
    final icon = isInside ? Icons.check_circle_outline : Icons.highlight_off;
    final label = isInside ? 'INSIDE' : 'OUTSIDE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
