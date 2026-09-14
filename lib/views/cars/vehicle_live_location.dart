import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/fetch_geofence_controller.dart';
import 'package:atom/services/geofence_monitor_service.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/widgets/map/map_style_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class VehicleLocationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String deviceId;
  final String serialNumber;
  final String numberPlate;

  const VehicleLocationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    required this.serialNumber,
    required this.numberPlate,
  });

  @override
  State<VehicleLocationScreen> createState() => _VehicleLocationScreenState();
}

class _VehicleLocationScreenState extends State<VehicleLocationScreen>
    with SingleTickerProviderStateMixin {
  MapboxMap? mapboxMap;
  String? _mapStyleUri;
  Timer? _refreshTimer;
  bool _refreshing = false;
  String _trackingStatus = 'Loading';
  bool _online = false;

  double _bearing = 0.0;
  String speed = '0';
  String numberPlate = '';
  final double _currentZoom = 15.0;
  Uint8List? carIcon;

  // Cached icons per status
  static Uint8List? _cachedGreenIcon;
  static Uint8List? _cachedBlueIcon;
  static Uint8List? _cachedRedIcon;

  // In-flight icon load, so the annotation setup can await it instead of
  // racing against it.
  Future<void>? _iconLoadFuture;

  PointAnnotationManager? _annotationManager;
  PointAnnotation? _vehicleAnnotation;

  late AnimationController _moveController;
  void Function()? _moveListener;
  double _animLat = 0;
  double _animLng = 0;

  // ── Geofence monitoring ────────────────────────────────────────────────
  final _geofenceMonitor = GeofenceMonitorService();
  final _fetchGeofenceController = FetchGeofenceController();

  @override
  void initState() {
    super.initState();
    numberPlate = widget.numberPlate;
    _animLat = widget.latitude;
    _animLng = widget.longitude;
    _moveController = AnimationController(vsync: this);
    _initGeofenceMonitor();
    _refreshLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocation(),
    );
    _iconLoadFuture = _loadCarIcon();
  }

  Future<void> _initGeofenceMonitor() async {
    await _fetchGeofenceController.fetchGeofence(widget.numberPlate);
    if (!mounted) return;
    _geofenceMonitor.initializeStates(
      _fetchGeofenceController.geofences,
      widget.latitude,
      widget.longitude,
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _refreshTimer?.cancel();
    _geofenceMonitor.reset();
    super.dispose();
  }

  // API location refresh

  Future<void> _refreshLocation() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final device = await ApiService.fetchTrackingDevice(widget.serialNumber);
      if (!mounted) return;
      final lat = double.tryParse(device.latitude);
      final lng = double.tryParse(device.longitude);
      final validPosition =
          lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat.abs() <= 90 &&
          lng.abs() <= 180 &&
          (lat != 0 || lng != 0);
      setState(() {
        _online = device.isDeviceOnline;
        _trackingStatus = !validPosition
            ? 'No GPS'
            : _online
            ? 'Live'
            : 'Offline';
        speed = device.speed.isEmpty ? '0' : device.speed;
        if (device.numberPlate.isNotEmpty) numberPlate = device.numberPlate;
        final course = double.tryParse(device.course);
        _bearing = course != null && course.isFinite ? course % 360 : 0;
      });
      if (!validPosition) return;
      if (_vehicleAnnotation != null &&
          _cachedGreenIcon != null &&
          _cachedBlueIcon != null &&
          _cachedRedIcon != null) {
        _vehicleAnnotation!.image = _iconForSpeed(double.tryParse(speed) ?? 0);
        _vehicleAnnotation!.iconRotate = _bearing;
        _vehicleAnnotation!.textField = numberPlate.toUpperCase();
      }
      _geofenceMonitor.updateLocation(
        _fetchGeofenceController.geofences,
        lat,
        lng,
        numberPlate,
      );
      _animateMarkerTo(lat, lng);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _online = false;
        _trackingStatus = 'Retrying';
      });
      debugPrint('Live location refresh failed: $error');
    } finally {
      _refreshing = false;
    }
  }

  void _animateMarkerTo(double newLat, double newLng) {
    final fromLat = _animLat;
    final fromLng = _animLng;

    if (_moveListener != null) {
      _moveController.removeListener(_moveListener!);
    }

    _moveController.stop();
    _moveController.duration = const Duration(milliseconds: 800);

    _moveListener = () {
      if (!mounted) return;
      final t = Curves.easeInOut.transform(_moveController.value);
      _animLat = fromLat + (newLat - fromLat) * t;
      _animLng = fromLng + (newLng - fromLng) * t;

      final pt = Point(coordinates: Position(_animLng, _animLat));

      if (_vehicleAnnotation != null && _annotationManager != null) {
        _vehicleAnnotation!.geometry = pt;
        _annotationManager!.update(_vehicleAnnotation!);
      }

      mapboxMap?.setCamera(CameraOptions(center: pt, zoom: _currentZoom));
    };

    _moveController.addListener(_moveListener!);
    _moveController.forward(from: 0.0).then((_) {
      _animLat = newLat;
      _animLng = newLng;
    });
  }

  // ─── Annotation setup ─────────────────────────────────────────────────────
  // Called from both onMapCreated (initial) and onStyleLoadedListener (style
  // changes). loadStyleURI destroys native managers without re-firing
  // onMapCreated, so we must recreate them on every style load.

  Future<void> _setupAnnotations() async {
    _annotationManager = null;
    _vehicleAnnotation = null;
    if (mapboxMap == null || !mounted) return;

    // Make sure the icons are loaded before creating the annotation. Otherwise
    // on the very first open the marker is created with a null image and stays
    // invisible until the page is reopened (when the static cache is warm).
    await (_iconLoadFuture ??= _loadCarIcon());
    if (!mounted) return;

    final manager = await mapboxMap!.annotations.createPointAnnotationManager();
    if (!mounted) return;
    _annotationManager = manager;
    final speedVal = double.tryParse(speed) ?? 0;
    final icon = _iconForSpeed(speedVal);
    final ann = await manager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_animLng, _animLat)),
        image: icon,
        iconSize: 0.8,
        iconRotate: _bearing,
        textField: numberPlate.toUpperCase(),
        textSize: 11.0,
        textOffset: [0.0, 2.2],
      ),
    );
    if (mounted) _vehicleAnnotation = ann;
  }

  // ─── Icon loading ─────────────────────────────────────────────────────────

  Uint8List _iconForSpeed(double speedVal) {
    if (speedVal > 80) return _cachedRedIcon!;
    if (speedVal > 0) return _cachedGreenIcon!;
    return _cachedBlueIcon!;
  }

  Future<void> _loadCarIcon() async {
    _cachedGreenIcon ??= await _resizeAndLoadIcon('assets/green_car.png', 70);
    _cachedBlueIcon ??= await _resizeAndLoadIcon('assets/blue_car.png', 90);
    _cachedRedIcon ??= await _resizeAndLoadIcon('assets/red_car.png', 90);
    if (!mounted) return;
    final speedVal = double.tryParse(speed) ?? 0;
    carIcon = _iconForSpeed(speedVal);
    // If the annotation already exists (map loaded before icon), update it.
    if (_vehicleAnnotation != null && _annotationManager != null) {
      _vehicleAnnotation!.image = carIcon;
      await _annotationManager!.update(_vehicleAnnotation!);
    }
  }

  Future<Uint8List> _resizeAndLoadIcon(String assetPath, int width) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return bytes!.buffer.asUint8List();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────
          Positioned.fill(
            child: MapWidget(
              styleUri:
                  _mapStyleUri ??
                  (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(_animLng, _animLat)),
                zoom: _currentZoom,
              ),
              onMapCreated: (MapboxMap map) {
                _annotationManager = null;
                _vehicleAnnotation = null;
                mapboxMap = map;
                setState(() {});
              },
              onStyleLoadedListener: (_) => _setupAnnotations(),
            ),
          ),

          // ── Header ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: _buildHeader(col),
          ),

          // ── Map style switcher ─────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 16,
            child: MapStyleSwitcherButton(
              mapboxMap: mapboxMap,
              currentStyleUri:
                  _mapStyleUri ??
                  (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS),
              onStyleChanged: (uri) => setState(() => _mapStyleUri = uri),
            ),
          ),

          // ── Speed / status card ────────────────────────────
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildInfoCard(col),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 60,
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(kRadiusSM),
                boxShadow: [kShadowMD],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: col.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(kRadiusSM),
                boxShadow: [kShadowMD],
              ),
              child: Row(
                children: [
                  const Icon(Icons.drive_eta_rounded, color: kBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    numberPlate.isNotEmpty
                        ? numberPlate.toUpperCase()
                        : 'Live Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: col.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _online ? kSuccessGreen : col.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _trackingStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: _online ? kSuccessGreen : col.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppColors col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusLG),
        boxShadow: [kShadowLG],
      ),
      child: Row(
        children: [
          // Speed dial
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: kBlue.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speed,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBlue,
                  ),
                ),
                Text(
                  'km/h',
                  style: TextStyle(fontSize: 9, color: col.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Direction + device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      color: kBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _bearingToDirection(_bearing),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_bearing.toStringAsFixed(0)}°',
                      style: TextStyle(fontSize: 12, color: col.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Device: ${widget.deviceId}',
                  style: TextStyle(fontSize: 12, color: col.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // GPS indicator
          Column(
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                color: _online ? kSuccessGreen : col.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 2),
              const Text(
                'GPS',
                style: TextStyle(
                  fontSize: 10,
                  color: kSuccessGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bearingToDirection(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }
}
