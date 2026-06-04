import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/dashboard_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/in_app_update_service.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/utils/signal_tier.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/geofencing_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, ByteData, SystemUiOverlayStyle, Brightness;
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Size, LocationSettings;
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'cars/cars_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedVehicleIndex = 0;
  bool isLoadingLocation = false;

  MapboxMap? mapboxMap;
  Point? userLocation;
  double currentZoom = 14.0;
  String _currentMapStyle = MapboxStyles.MAPBOX_STREETS;

  // Annotation management
  PointAnnotationManager? _annotationManager;
  final Map<String, PointAnnotation> _vehicleAnnotations = {};
  final Map<String, PointAnnotation> _plateAnnotations = {};
  static final Map<String, Uint8List> _plateCalloutCache = {};
  String? _selectedVehiclePlate;
  Offset? _bannerScreenPos;

  CircleAnnotationManager? _circleAnnotationManager;
  CircleAnnotation? _breathingCircle;
  late AnimationController _breathingController;

  final Utils _utils = Utils();
  final DeviceController _controller = Get.put(DeviceController());
  Map<String, Uint8List> customIcons = {};

  // Decoded PNG bytes are expensive to produce; cache them for the lifetime of
  // the app so revisiting this screen skips the decode entirely.
  static final Map<String, Uint8List> _iconCache = {};

  final TextEditingController _searchController = TextEditingController();
  List<Device> _filteredDevices = [];

  bool _isDataReady = false;
  bool _hasFitAllCars = false;
  String? _trackedCarPlate;
  bool _isLoggedIn = false;
  bool _showSearchOverlay = false;
  String _userName = 'Demo';
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _breathingController.addListener(_updateBreathingCircle);

    _checkLoginState();
    _initializeData();
    InAppUpdateService.checkForUpdate();
  }

  Future<void> _checkLoginState() async {
    final token = await StorageService.getData('access_token');
    final name = await StorageService.getData('userName');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.toString().isNotEmpty;
        _userName = (name != null && name.toString().isNotEmpty) ? name.toString() : 'Demo';
      });
    }
  }

  void _applyFilters() {
    final all = _controller.devicesModel.value?.devices ?? [];
    var filtered = _selectedGroup == null
        ? List<Device>.from(all)
        : all.where((d) => d.group == _selectedGroup).toList();
    final q = _searchController.text;
    if (q.isNotEmpty) {
      filtered = filtered
          .where(
            (d) => d.numberPlate.toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    }
    setState(() => _filteredDevices = filtered);
  }

  // Called by _CountdownRefreshButton. Returns a Future so the button can
  // show its own spinner while the fetch is in flight — no parent setState
  // needed for the loading indicator.
  Future<void> _refreshData() async {
    try {
      await _controller.fetchDevices(silent: true);
      if (!mounted) return;
      _applyFilters();
      await _updateVehicleAnnotations(_filteredDevices);

      if (_trackedCarPlate != null) {
        final tracked = _filteredDevices
            .where((d) => d.numberPlate == _trackedCarPlate)
            .firstOrNull;
        if (tracked != null && mapboxMap != null) {
          final lat = double.tryParse(tracked.latitude) ?? -1.2842;
          final lng = double.tryParse(tracked.longitude) ?? 36.8163;
          mapboxMap!.flyTo(
            CameraOptions(center: Point(coordinates: Position(lng, lat))),
            null,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _initializeData() async {
    try {
      await _loadCustomIcons();
      await _controller.fetchDevices();
      if (!mounted) return;
      setState(() => _isDataReady = true);
      _applyFilters();
      _getUserLocation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateVehicleAnnotations(_filteredDevices);
        if (!_hasFitAllCars && _filteredDevices.isNotEmpty) {
          _fitAllCarsOnMap(_filteredDevices);
          _hasFitAllCars = true;
        }
      });
    } catch (e) {
      print('Error initializing data: $e');
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isDataReady = true);
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

  // ─── Map layer setup ─────────────────────────────────────────────────────
  Future<void> _setupMapLayers() async {
    _vehicleAnnotations.clear();
    _plateAnnotations.clear();
    _breathingCircle = null;
    _circleAnnotationManager = null;
    _annotationManager = null;
    if (mapboxMap == null || !mounted) return;

    final circleManager =
        await mapboxMap!.annotations.createCircleAnnotationManager();
    if (!mounted) return;
    setState(() => _circleAnnotationManager = circleManager);

    final pointManager =
        await mapboxMap!.annotations.createPointAnnotationManager();
    if (!mounted) return;
    _annotationManager = pointManager;
    _updateVehicleAnnotations(_filteredDevices);
  }

  // ─── Icon & annotation helpers ───────────────────────────────────────────

  bool _deviceHasViolation(Device device) {
    final speedVal = double.tryParse(device.speed) ?? 0;
    final isSpeeding = speedVal > 80;
    final isSignalCut = device.signalStrength == 0;
    final isPowerCut = device.vehicleBatteryVoltage;
    return isSpeeding || isSignalCut || isPowerCut;
  }

  Uint8List? _getImageForDevice(Device device) {
    if (!device.isDeviceOnline) return customIcons['grey'];
    if (_deviceHasViolation(device)) return customIcons['red'];
    final speedVal = double.tryParse(device.speed) ?? 0;
    if (speedVal > 0) return customIcons['green'];
    return customIcons['blue'];
  }

  Future<void> _updateVehicleAnnotations(List<Device> devices) async {
    if (_annotationManager == null) return;

    final newPlates = devices.map((d) => d.numberPlate).toSet();
    final toRemove = _vehicleAnnotations.keys
        .where((p) => !newPlates.contains(p))
        .toList();
    for (final plate in toRemove) {
      final ann = _vehicleAnnotations.remove(plate);
      if (ann != null) await _annotationManager!.delete(ann);
      final plateAnn = _plateAnnotations.remove(plate);
      if (plateAnn != null) await _annotationManager!.delete(plateAnn);
    }

    for (final device in devices) {
      final lat = double.tryParse(device.latitude) ?? -1.2842;
      final lng = double.tryParse(device.longitude) ?? 36.8163;
      final rotation = double.tryParse(device.course) ?? 0.0;
      final iconBytes = _getImageForDevice(device);
      const iconSize = 0.9;
      final point = Point(coordinates: Position(lng, lat));

      if (_vehicleAnnotations.containsKey(device.numberPlate)) {
        final ann = _vehicleAnnotations[device.numberPlate]!;
        ann.geometry = point;
        ann.iconRotate = rotation;
        ann.image = iconBytes;
        ann.iconSize = iconSize;
        await _annotationManager!.update(ann);
      } else {
        final ann = await _annotationManager!.create(
          PointAnnotationOptions(
            geometry: point,
            image: iconBytes,
            iconSize: iconSize,
            iconRotate: rotation,
          ),
        );
        _vehicleAnnotations[device.numberPlate] = ann;
      }

      // Number-plate callout (white rounded box with downward arrow).
      final calloutBytes = await _getPlateCallout(device.numberPlate);
      if (_plateAnnotations.containsKey(device.numberPlate)) {
        final pAnn = _plateAnnotations[device.numberPlate]!;
        pAnn.geometry = point;
        await _annotationManager!.update(pAnn);
      } else {
        final pAnn = await _annotationManager!.create(
          PointAnnotationOptions(
            geometry: point,
            image: calloutBytes,
            iconSize: 1 / 3 * 2.1, // image rendered at 3x; displayed larger for legibility
            iconAnchor: IconAnchor.BOTTOM,
            iconOffset: [0.0, -38.0],
            symbolSortKey: 100.0,
          ),
        );
        _plateAnnotations[device.numberPlate] = pAnn;
      }
    }
  }

  Future<Uint8List> _getPlateCallout(String text) async {
    final cached = _plateCalloutCache[text];
    if (cached != null) return cached;
    final bytes = await _buildPlateCallout(text);
    _plateCalloutCache[text] = bytes;
    return bytes;
  }

  Future<Uint8List> _buildPlateCallout(String text) async {
    const double scale = 3.0;
    const double fontSize = 13.0;
    const double padH = 10.0;
    const double padV = 5.0;
    const double radius = 7.0;
    const double arrowW = 12.0;
    const double arrowH = 6.0;
    const double shadowPad = 4.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF1B8F3A),
          fontSize: fontSize * scale,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double rectW = textPainter.width + padH * 2 * scale;
    final double rectH = textPainter.height + padV * 2 * scale;
    final double imgW = rectW + shadowPad * 2 * scale;
    final double imgH = rectH + arrowH * scale + shadowPad * 2 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double rectLeft = shadowPad * scale;
    final double rectTop = shadowPad * scale;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectLeft, rectTop, rectW, rectH),
      Radius.circular(radius * scale),
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawRRect(rrect.shift(const Offset(0, 1)), shadowPaint);

    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(rrect, bgPaint);

    // Downward-pointing arrow
    final double cx = rectLeft + rectW / 2;
    final double arrowTop = rectTop + rectH - 0.5; // tiny overlap to avoid seam
    final arrowPath = Path()
      ..moveTo(cx - arrowW * scale / 2, arrowTop)
      ..lineTo(cx + arrowW * scale / 2, arrowTop)
      ..lineTo(cx, arrowTop + arrowH * scale)
      ..close();
    canvas.drawPath(arrowPath, bgPaint);

    // Text
    textPainter.paint(
      canvas,
      Offset(rectLeft + padH * scale, rectTop + padV * scale),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(imgW.ceil(), imgH.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  int _lastFrameRenderTime = 0;
  Future<void> _updateBreathingCircle() async {
    if (_circleAnnotationManager == null ||
        _selectedVehiclePlate == null ||
        _filteredDevices.isEmpty)
      return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameRenderTime < 41) return;
    _lastFrameRenderTime = now;

    final device = _filteredDevices.firstWhereOrNull(
      (d) => d.numberPlate == _selectedVehiclePlate,
    );
    if (device == null) return;

    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;
    final progress = _breathingController.value;

    final currentRadius = 10.0 + (progress * 30.0);
    final currentOpacity = (0.6 * (1.0 - progress)).clamp(0.0, 1.0);

    try {
      if (_breathingCircle == null) {
        _breathingCircle = await _circleAnnotationManager!.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            circleColor: 0xFF287ec3,
            circleRadius: currentRadius,
            circleOpacity: currentOpacity,
            circleStrokeWidth: 1.5,
            circleStrokeColor: 0xFF287ec3,
            circleStrokeOpacity: currentOpacity,
          ),
        );
      } else {
        _breathingCircle!.geometry = Point(coordinates: Position(lng, lat));
        _breathingCircle!.circleRadius = currentRadius;
        _breathingCircle!.circleOpacity = currentOpacity;
        _breathingCircle!.circleStrokeOpacity = currentOpacity;
        await _circleAnnotationManager!.update(_breathingCircle!);
      }
    } catch (_) {
      _breathingCircle = null;
      _circleAnnotationManager = null;
    }
  }

  void _onMapTapped(Point tappedPoint) {
    final tapLat = tappedPoint.coordinates.lat.toDouble();
    final tapLng = tappedPoint.coordinates.lng.toDouble();

    Device? nearest;
    double minDist = double.infinity;

    for (final device in _filteredDevices) {
      final devLat = double.tryParse(device.latitude) ?? 0;
      final devLng = double.tryParse(device.longitude) ?? 0;
      final dist =
          (devLat - tapLat) * (devLat - tapLat) +
          (devLng - tapLng) * (devLng - tapLng);
      if (dist < minDist) {
        minDist = dist;
        nearest = device;
      }
    }

    if (nearest != null && minDist < 0.0005) {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().isNavVisible.value = false;
      }
      setState(() => _selectedVehiclePlate = nearest!.numberPlate);
      _updateVehicleAnnotations(_filteredDevices);
      _focusOnDevice(nearest);
      _updateBannerPosition();
    }
  }

  void _focusOnDevice(Device device) {
    if (mapboxMap == null) return;
    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;
    mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.0),
      null,
    );
  }

  Future<void> _updateBannerPosition() async {
    if (mapboxMap == null || _selectedVehiclePlate == null) {
      if (mounted && _bannerScreenPos != null) {
        setState(() => _bannerScreenPos = null);
      }
      return;
    }
    final device = _filteredDevices.firstWhereOrNull(
      (d) => d.numberPlate == _selectedVehiclePlate,
    );
    if (device == null) return;
    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;
    try {
      final sc = await mapboxMap!.pixelForCoordinate(
        Point(coordinates: Position(lng, lat)),
      );
      if (mounted) setState(() => _bannerScreenPos = Offset(sc.x, sc.y));
    } catch (_) {}
  }

  // ─── Vehicle navigation ───────────────────────────────────────────────────

  void _showNextVehicle() {
    if (_filteredDevices.isEmpty) return;
    setState(
      () => selectedVehicleIndex =
          (selectedVehicleIndex + 1) % _filteredDevices.length,
    );
    _focusOnVehicle(selectedVehicleIndex);
  }

  void _showPreviousVehicle() {
    if (_filteredDevices.isEmpty) return;
    setState(
      () => selectedVehicleIndex =
          (selectedVehicleIndex - 1 + _filteredDevices.length) %
          _filteredDevices.length,
    );
    _focusOnVehicle(selectedVehicleIndex);
  }

  void _focusOnVehicle(int index) {
    if (index < 0 || index >= _filteredDevices.length || mapboxMap == null)
      return;
    final device = _filteredDevices[index];
    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;
    mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.0),
      null,
    );
  }

  void _fitAllCarsOnMap(List<Device> devices) {
    if (mapboxMap == null || devices.isEmpty) return;
    final points = devices
        .where(
          (d) =>
              double.tryParse(d.latitude) != null &&
              double.tryParse(d.longitude) != null,
        )
        .map(
          (d) => Point(
            coordinates: Position(
              double.parse(d.longitude),
              double.parse(d.latitude),
            ),
          ),
        )
        .toList();
    if (points.isEmpty) return;
    double sumLat = 0, sumLng = 0;
    for (final p in points) {
      sumLat += p.coordinates.lat.toDouble();
      sumLng += p.coordinates.lng.toDouble();
    }
    mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(sumLng / points.length, sumLat / points.length),
        ),
        zoom: 10.0,
      ),
      null,
    );
  }

  Future<void> _loadCustomIcons() async {
    if (_iconCache.isNotEmpty) {
      customIcons = Map.of(_iconCache);
      return;
    }
    customIcons['green'] = await _resizeAndLoadIcon(
      'assets/green_car.png',
      70,
    );
    customIcons['blue'] = await _resizeAndLoadIcon('assets/blue_car.png', 70);
    customIcons['red'] = await _resizeAndLoadIcon('assets/red_car.png', 90);
    customIcons['grey'] = await _resizeAndLoadIcon('assets/grey_car.png', 180);
    _iconCache.addAll(customIcons);
  }

  Future<void> _getUserLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        setState(() => isLoadingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        setState(() => isLoadingLocation = false);
        return;
      }
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        userLocation = Point(
          coordinates: Position(currentPos.longitude, currentPos.latitude),
        );
        isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      if (!mounted) return;
      setState(() => isLoadingLocation = false);
    }
  }

  void _moveToUserLocation() async {
    if (userLocation == null) await _getUserLocation();
    if (userLocation != null && mapboxMap != null) {
      mapboxMap!.flyTo(CameraOptions(center: userLocation, zoom: 15.0), null);
    }
  }

  void _zoomIn() {
    if (mapboxMap != null) {
      currentZoom += 1;
      mapboxMap!.flyTo(CameraOptions(zoom: currentZoom), null);
    }
  }

  void _zoomOut() {
    if (mapboxMap != null) {
      currentZoom -= 1;
      mapboxMap!.flyTo(CameraOptions(zoom: currentZoom), null);
    }
  }

  void _applyMapStyle(String style) {
    Navigator.pop(context);
    _vehicleAnnotations.clear();
    _plateAnnotations.clear();
    _breathingCircle = null;
    _circleAnnotationManager = null;
    _annotationManager = null;
    setState(() => _currentMapStyle = style);
    mapboxMap?.loadStyleURI(style);
  }

  void _showMapStyleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildMapStyleSheet(),
    );
  }

  Widget _buildMapStyleSheet() {
    final styleOptions = [
      {
        'label': 'Standard',
        'icon': Icons.map_outlined,
        'style': MapboxStyles.MAPBOX_STREETS,
        'color': kBlue,
      },
      {
        'label': 'Satellite',
        'icon': Icons.satellite_alt_rounded,
        'style': MapboxStyles.SATELLITE,
        'color': const Color(0xFF2C7A4B),
      },
      {
        'label': 'Terrain',
        'icon': Icons.terrain_rounded,
        'style': MapboxStyles.OUTDOORS,
        'color': const Color(0xFF8B5E3C),
      },
      {
        'label': 'Hybrid',
        'icon': Icons.layers_rounded,
        'style': MapboxStyles.SATELLITE_STREETS,
        'color': const Color(0xFF4A7A5C),
      },
      {
        'label': 'Dark Mode',
        'icon': Icons.dark_mode_rounded,
        'style': MapboxStyles.DARK,
        'color': const Color(0xFF2D2D3A),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kRadiusLG),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(kRadiusSM),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.layers_rounded, color: kBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Map Style',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.col.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.col.divider),
          ...styleOptions.map((opt) {
            final isActive = _currentMapStyle == opt['style'] as String;
            final color = opt['color'] as Color;
            return ListTile(
              tileColor: context.col.surface,
              onTap: () => _applyMapStyle(opt['style'] as String),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(kRadiusMD),
                ),
                child: Icon(opt['icon'] as IconData, color: color, size: 20),
              ),
              title: Text(
                opt['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? kBlue : context.col.textPrimary,
                ),
              ),
              trailing: isActive
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: kBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: kWhite, size: 14),
                    )
                  : null,
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _showFleetSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildFleetSelectorSheet(),
    );
  }

  Widget _buildFleetSelectorSheet() {
    final allDevices = _controller.devicesModel.value?.devices ?? [];
    final groups = allDevices
        .map((d) => d.group)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kRadiusLG),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(kRadiusSM),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: kBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Fleet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.col.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.col.divider),
          // "All" option
          ListTile(
            tileColor: context.col.surface,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedGroup = null);
              _applyFilters();
              _updateVehicleAnnotations(_filteredDevices);
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadiusMD),
              ),
              child: const Icon(Icons.select_all_rounded, color: kBlue, size: 20),
            ),
            title: Text(
              'All Fleets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _selectedGroup == null ? FontWeight.w700 : FontWeight.w500,
                color: _selectedGroup == null ? kBlue : context.col.textPrimary,
              ),
            ),
            trailing: _selectedGroup == null
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: kWhite, size: 14),
                  )
                : null,
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No fleets available',
                style: TextStyle(
                  fontSize: 14,
                  color: context.col.textSecondary,
                ),
              ),
            )
          else
            ...groups.map((group) {
              final isActive = _selectedGroup == group;
              final count = allDevices.where((d) => d.group == group).length;
              return ListTile(
                tileColor: context.col.surface,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedGroup = group);
                  _applyFilters();
                  _updateVehicleAnnotations(_filteredDevices);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(kRadiusMD),
                  ),
                  child: const Icon(Icons.directions_car_outlined, color: kBlue, size: 20),
                ),
                title: Text(
                  group,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w300 : FontWeight.w300,
                    color: isActive ? kBlue : context.col.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '$count vehicle${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.col.textSecondary,
                  ),
                ),
                trailing: isActive
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: kBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: kWhite, size: 14),
                      )
                    : null,
              );
            }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _focusOnSearchedCar(Device device) {
    if (mapboxMap == null) return;
    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;
    mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 16.0),
      null,
    );
    setState(() => _trackedCarPlate = device.numberPlate);
  }

  @override
  void dispose() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().isNavVisible.value = true;
    }
    _searchController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: context.col.surface,
        appBar: _buildAppBar(),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CarsScreen(showSearch: _showSearchOverlay),
            _buildMapTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = context.isDark;
    final gradientColors = isDark
        ? [
            kBlue.withValues(alpha: 0.32),
            kBlue.withValues(alpha: 0.10),
            context.col.surface,
          ]
        : [
            const Color(0xFFB8C8E8),
            const Color(0xFFD6DEEF),
            context.col.surface,
          ];
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarBrightness: Brightness.light,
                statusBarIconBrightness: Brightness.dark,
              ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.7, 1.0],
              colors: gradientColors,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
          child: Obx(() {
            final model = _controller.devicesModel.value;
            final total = model?.totalDevices ?? 0;
            final online = model?.onlineDevices ?? 0;
            final groups = (model?.devices
                        .map((d) => d.group)
                        .where((g) => g.isNotEmpty)
                        .toSet()
                        .toList() ??
                    [])
              ..sort();
            return Row(
              children: [
                Expanded(child: _buildFleetSelector(model, total, online, groups)),
                const SizedBox(width: kSpaceSM),
                _buildSearchIconBtn(),
              ],
            );
          }),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kSpaceLG, kSpaceMD, kSpaceLG, 0),
            child: _buildSegmentedTabs(),
          ),
        ),
      ),
    );
  }

  Widget _buildFleetSelector(
    DevicesModel? model,
    int total,
    int online,
    List<String> groups,
  ) {
    final offline = (total - online).clamp(0, total);
    final scopeLabel = _selectedGroup ?? 'All Fleets';
    return PopupMenuButton<String?>(
      onSelected: (group) {
        setState(() => _selectedGroup = group);
        _applyFilters();
        _updateVehicleAnnotations(_filteredDevices);
      },
      offset: const Offset(0, 52),
      color: context.col.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMD),
      ),
      elevation: 6,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: kSpaceMD, vertical: 6),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(kRadiusPill),
          border: Border.all(
            color: context.col.border.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [kShadowSM],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBlue, kBlue.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: kSpaceSM),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scopeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.col.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _statDot(color: kSuccessGreen),
                      const SizedBox(width: 3),
                      Text(
                        '$online online',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.col.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statDot(color: kLightGrey),
                      const SizedBox(width: 3),
                      Text(
                        '$offline offline',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.col.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(kRadiusSM),
              ),
              child: Row(
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_drop_down, color: kBlue, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: _selectedGroup == null
                    ? const Icon(Icons.check, size: 16, color: kBlue)
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                'All [$total/$online]',
                style: GoogleFonts.poppins(
                  color: context.col.textPrimary,
                  fontWeight: _selectedGroup == null
                      ? FontWeight.w500
                      : FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        ...groups.map((g) {
          final gDevices =
              model?.devices.where((d) => d.group == g).toList() ?? [];
          final gTotal = gDevices.length;
          final gOnline = gDevices.where((d) => d.isDeviceOnline).length;
          return PopupMenuItem<String?>(
            value: g,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: _selectedGroup == g
                      ? const Icon(Icons.check, size: 16, color: kBlue)
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  '$g [$gTotal/$gOnline]',
                  style: GoogleFonts.poppins(
                    color: context.col.textPrimary,
                    fontWeight: _selectedGroup == g
                        ? FontWeight.w500
                        : FontWeight.w300,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statDot({required Color color}) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  List<Widget> _buildSignalTierIndicator(
    int strength, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final tier = SignalTier.from(strength);
    return [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: tier.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        tier.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: tier.color,
        ),
      ),
    ];
  }

  Widget _buildSearchIconBtn() {
    final active = _showSearchOverlay;
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusPill),
      onTap: () =>
          setState(() => _showSearchOverlay = !_showSearchOverlay),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? kBlue : context.col.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? kBlue
                : context.col.border.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [kShadowSM],
        ),
        child: Icon(
          Icons.search_rounded,
          color: active ? kWhite : context.col.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return SizedBox(
      height: 52,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 44),
        dividerColor: Colors.transparent,
        indicator: _BrowserTabIndicator(color: context.col.surface),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: kBlue,
        unselectedLabelColor: context.col.textPrimary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [  
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_list_bulleted_rounded, size: 16),
                SizedBox(width: 8),
                Text('List'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 6),
                Text('Map'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Map tab ──────────────────────────────────────────────────────────────

  Widget _buildMapTab() {
    final selectedDevice = _selectedVehiclePlate != null
        ? _filteredDevices.firstWhereOrNull(
            (d) => d.numberPlate == _selectedVehiclePlate,
          )
        : null;

    return Column(
      children: [
        if (!_isLoggedIn) _buildLoginBanner(),
        Expanded(
          child: Stack(
            children: [
              _buildMap(),
              if (_isDataReady) ...[
                if (_showSearchOverlay)
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),
                Positioned(
                  right: 12,
                  top: _showSearchOverlay ? 70 : 10,
                  child: _buildRightControls(),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildBottomMapControls(),
                ),
                if (selectedDevice != null && _bannerScreenPos != null)
                  _buildVehicleMapBanner(selectedDevice, _bannerScreenPos!),
              ],
              if (!_isDataReady)
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (selectedDevice != null) _buildVehicleInfoCard(selectedDevice),
        if (selectedDevice != null) _buildVehicleNavBar(selectedDevice),
      ],
    );
  }

  // ─── Login banner ─────────────────────────────────────────────────────────

  Widget _buildLoginBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF2D2D2D),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Manage Vehicles after login',
              style: const TextStyle(color: kWhite, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusSM),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                color: kWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Map widget ───────────────────────────────────────────────────────────

  Widget _buildMap() {
    final initialPosition = _filteredDevices.isNotEmpty
        ? Point(
            coordinates: Position(
              double.tryParse(_filteredDevices[0].longitude) ?? 36.8163,
              double.tryParse(_filteredDevices[0].latitude) ?? -1.2842,
            ),
          )
        : Point(coordinates: Position(36.8163, -1.2842));

    return MapWidget(
      styleUri: _currentMapStyle,
      cameraOptions: CameraOptions(center: initialPosition, zoom: currentZoom),
      onMapCreated: (MapboxMap map) {
        _vehicleAnnotations.clear();
        _plateAnnotations.clear();
        _breathingCircle = null;
        _circleAnnotationManager = null;
        _annotationManager = null;
        mapboxMap = map;
      },
      onStyleLoadedListener: (_) => _setupMapLayers(),
      onTapListener: (MapContentGestureContext context) {
        _onMapTapped(context.point);
      },
      onCameraChangeListener: (data) {
        currentZoom = data.cameraState.zoom;
        _updateBannerPosition();
      },
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(color: context.col.border, width: 1),
        boxShadow: [kShadowSM],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: kSpaceXL),
            child: Icon(
              Icons.search,
              color: context.col.textSecondary,
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.col.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search by number plate',
                hintStyle: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
              ),
              onChanged: (query) {
                _applyFilters();
                if (_filteredDevices.length == 1) {
                  _focusOnSearchedCar(_filteredDevices.first);
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, color: context.col.textSecondary, size: 20),
            onPressed: () {
              _searchController.clear();
              FocusScope.of(context).unfocus();
              setState(() {
                _trackedCarPlate = null;
                _showSearchOverlay = false;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  // ─── Right-side map controls (layers / users / A) ─────────────────────────

  Widget _buildRightControls() {
    return Column(
      children: [
        _mapControlBtn(Icons.layers_outlined, _showMapStyleSelector),
        const SizedBox(height: 8),
        _mapControlBtn(
          Icons.people_outline,
          _showFleetSelector,
          activeColor: _selectedGroup != null ? kBlue : kGrey,
        ),
        const SizedBox(height: 8),
        _mapControlBtnLabel('A', () => _fitAllCarsOnMap(_filteredDevices)),
      ],
    );
  }

  // ─── Bottom map controls (refresh+GPS | arrows | zoom) ────────────────────

  Widget _buildBottomMapControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: countdown + GPS
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mapControlContainer(
                child: _CountdownRefreshButton(
                  onRefresh: _refreshData,
                  intervalSeconds: 20,
                ),
              ),
              const SizedBox(height: 8),
              _mapControlBtn(
                isLoadingLocation ? null : Icons.my_location,
                _moveToUserLocation,
                isLoading: isLoadingLocation,
                activeColor: userLocation != null ? kBlue : kGrey,
              ),
            ],
          ),
          // Center: prev / next arrows (joined pill)
          Expanded(
            child: Center(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: context.col.surface,
                  borderRadius: BorderRadius.circular(kRadiusPill),
                  boxShadow: [kShadowSM],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.chevron_left,
                          color: context.col.textSecondary,
                          size: 22,
                        ),
                        onPressed: _showPreviousVehicle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: context.col.border.withValues(alpha: 0.5),
                    ),
                    SizedBox(
                      width: 48,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.chevron_right,
                          color: context.col.textSecondary,
                          size: 22,
                        ),
                        onPressed: _showNextVehicle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right: zoom (joined vertical pill)
          Container(
            width: 44,
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(kRadiusMD),
              boxShadow: [kShadowSM],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.add,
                      color: context.col.textSecondary,
                      size: 20,
                    ),
                    onPressed: _zoomIn,
                  ),
                ),
                Container(
                  width: 22,
                  height: 1,
                  color: context.col.border.withValues(alpha: 0.5),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.remove,
                      color: context.col.textSecondary,
                      size: 20,
                    ),
                    onPressed: _zoomOut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlBtn(
    IconData? icon,
    VoidCallback? onTap, {
    bool isLoading = false,
    Color? activeColor,
  }) =>
      _mapControlContainer(
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: kBlue),
              )
            : IconButton(
                icon: Icon(
                  icon,
                  color: activeColor ?? context.col.textSecondary,
                  size: 20,
                ),
                onPressed: onTap,
              ),
      );

  Widget _mapControlBtnLabel(String label, VoidCallback onTap) =>
      _mapControlContainer(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusSM),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.col.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _mapControlContainer({required Widget child}) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: context.col.surface,
      borderRadius: BorderRadius.circular(kRadiusSM),
      boxShadow: [kShadowSM],
    ),
    child: child,
  );

  // ─── Floating vehicle banner (above marker) ──────────────────────────────

  Widget _buildVehicleMapBanner(Device device, Offset screenPos) {
    const bannerWidth = 200.0;
    const cardHeight = 108.0;
    const arrowSize = 8.0;

    final screenWidth = MediaQuery.of(context).size.width;

    // Center banner horizontally on the marker, keep it within screen bounds
    final double left =
        (screenPos.dx - bannerWidth / 2).clamp(8.0, screenWidth - bannerWidth - 8.0);
    // Place banner above the marker icon (~30 px gap)
    final double top = screenPos.dy - cardHeight - arrowSize - 30;

    final bool isOnline = device.isDeviceOnline;
    final double speedVal = double.tryParse(device.speed) ?? 0;
    final bool isMoving =
        isOnline && (device.ignitionStatus == 1 || speedVal > 0);
    final String statusLabel =
        !isOnline ? 'Offline' : (isMoving ? 'Moving' : 'Idle');
    final Color statusColor =
        !isOnline ? kRed : (isMoving ? kSuccessGreen : kBlue);

    return Positioned(
      left: left,
      top: top.clamp(8.0, double.infinity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              width: bannerWidth,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.col.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: plate + close
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.numberPlate,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.col.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (Get.isRegistered<DashboardController>()) {
                            Get.find<DashboardController>().isNavVisible.value = true;
                          }
                          setState(() {
                            _selectedVehiclePlate = null;
                            _bannerScreenPos = null;
                            _breathingCircle = null;
                          });
                          _updateVehicleAnnotations(_filteredDevices);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: context.col.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Status + signal tier
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      ..._buildSignalTierIndicator(device.signalStrength, fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Speed
                  Row(
                    children: [
                      Icon(Icons.speed, size: 13, color: kBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${device.speed} km/h',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.col.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: kBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          device.location.trim().isEmpty
                              ? 'Location unavailable'
                              : device.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.col.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Down-pointing arrow
          CustomPaint(
            painter: _DownArrowPainter(color: context.col.surface),
            size: const Size(14, arrowSize),
          ),
        ],
      ),
    );
  }

  // ─── Vehicle info card (inline) ───────────────────────────────────────────

  Widget _buildVehicleInfoCard(Device device) {
    final bool isOnline = device.isDeviceOnline;
    final double speedVal = double.tryParse(device.speed) ?? 0;
    final bool isMoving =
        isOnline && (device.ignitionStatus == 1 || speedVal > 0);
    final String statusLabel =
        !isOnline ? 'Offline' : (isMoving ? 'Moving' : 'Idle');
    final Color statusColor =
        !isOnline ? kRed : (isMoving ? kSuccessGreen : kBlue);
    final Color speedColor = isMoving ? kSuccessGreen : context.col.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row: plate + signal + close
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                device.numberPlate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.col.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Signal tier
              Row(
                children: _buildSignalTierIndicator(
                  device.signalStrength,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              // Close button
              GestureDetector(
                onTap: () {
                  if (Get.isRegistered<DashboardController>()) {
                    Get.find<DashboardController>().isNavVisible.value = true;
                  }
                  setState(() {
                    _selectedVehiclePlate = null;
                    _bannerScreenPos = null;
                    _breathingCircle = null;
                  });
                  _updateVehicleAnnotations(_filteredDevices);
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: context.col.border.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: context.col.textSecondary, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status + speed row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.speed_rounded, size: 15, color: context.col.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Speed: ${device.speed} km/h',
                style: TextStyle(
                  fontSize: 13,
                  color: speedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Group row
          if (device.group.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.business_rounded, color: kBlue, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      device.group,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.col.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Timestamp row
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: context.col.textSecondary, size: 15),
              const SizedBox(width: 6),
              Text(
                _utils.formatTime(device.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: context.col.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Vehicle bottom navigation bar ────────────────────────────────────────

  Widget _buildVehicleNavBar(Device device) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        border: Border(
          top: BorderSide(color: context.col.border.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navBarItem(
                Icons.directions_car_rounded,
                'Details',
                'Vehicle info',
                kBlue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectedCarScreen(
                      devices: device,
                      carModel: '${device.type} ${device.make}'.trim(),
                      licensePlate: device.numberPlate,
                    ),
                  ),
                ),
              ),
              _navBarItem(
                Icons.history_rounded,
                'Playback',
                'History & trips',
                kSuccessGreen,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaybackScreen(numberPlate: device.numberPlate),
                  ),
                ),
              ),
              _navBarItem(
                Icons.gps_fixed_rounded,
                'Tracking',
                'Live tracking',
                const Color(0xFFF39C12),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleLocationScreen(
                      latitude: double.tryParse(device.latitude) ?? -1.2842,
                      longitude: double.tryParse(device.longitude) ?? 36.8163,
                      deviceId: device.deviceId,
                      numberPlate: device.numberPlate,
                    ),
                  ),
                ),
              ),
              _navBarItem(
                Icons.terminal_rounded,
                'Command',
                'Send commands',
                kBlue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Commands(device: device),
                  ),
                ),
              ),
              _navBarItem(
                Icons.fence_rounded,
                'Fence',
                'Geo-fencing',
                kSuccessGreen,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeofencingScreen(numberPlate: device.numberPlate, device: device),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBarItem(
    IconData icon,
    String label,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.col.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: context.col.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Down-arrow painter (banner pointer) ──────────────────────────────────────

class _DownArrowPainter extends CustomPainter {
  final Color color;
  const _DownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DownArrowPainter old) => old.color != color;
}

// ── Countdown refresh button ──────────────────────────────────────────────────

class _CountdownRefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final int intervalSeconds;

  const _CountdownRefreshButton({
    required this.onRefresh,
    this.intervalSeconds = 20,
  });

  @override
  State<_CountdownRefreshButton> createState() =>
      _CountdownRefreshButtonState();
}

class _CountdownRefreshButtonState extends State<_CountdownRefreshButton> {
  late int _countdown;
  bool _isRefreshing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.intervalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _countdown = widget.intervalSeconds);
        _triggerRefresh();
      }
    });
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRefreshing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(strokeWidth: 2, color: kBlue),
      );
    }
    return IconButton(
      icon: Text(
        '$_countdown',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _countdown <= 3 ? kRed : kBlue,
        ),
      ),
      onPressed: () {
        setState(() => _countdown = widget.intervalSeconds);
        _triggerRefresh();
      },
    );
  }
}

// Browser-style tab indicator: rounded top, flat bottom with bottom corners
// that flare outward so the active tab visually "merges" into the content below.
class _BrowserTabIndicator extends Decoration {
  const _BrowserTabIndicator({required this.color});

  final Color color;
  static const double topRadius = 18;
  static const double bottomFlare = 16;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _BrowserTabPainter(this);
}

class _BrowserTabPainter extends BoxPainter {
  _BrowserTabPainter(this.decoration);
  final _BrowserTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    final rect = offset & size;
    const r = _BrowserTabIndicator.topRadius;
    const f = _BrowserTabIndicator.bottomFlare;
    final bodyLeft = rect.left + f;
    final bodyRight = rect.right - f;

    final path = Path()
      ..moveTo(bodyLeft + r, rect.top)
      ..lineTo(bodyRight - r, rect.top)
      ..quadraticBezierTo(bodyRight, rect.top, bodyRight, rect.top + r)
      ..lineTo(bodyRight, rect.bottom - f)
      ..quadraticBezierTo(bodyRight, rect.bottom, rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..quadraticBezierTo(bodyLeft, rect.bottom, bodyLeft, rect.bottom - f)
      ..lineTo(bodyLeft, rect.top + r)
      ..quadraticBezierTo(bodyLeft, rect.top, bodyLeft + r, rect.top)
      ..close();

    canvas.drawShadow(path, const Color(0xFF000000).withValues(alpha: 0.10),
        3, false);
    canvas.drawPath(path, Paint()..color = decoration.color..isAntiAlias = true);
  }
}
