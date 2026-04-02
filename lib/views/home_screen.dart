import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/dashboard_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
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

  Uint8List? _getImageForDevice(Device device) {
    if (!device.isDeviceOnline) return customIcons['red'];
    if (device.ignitionStatus == 1) return customIcons['green'];
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
    }

    for (final device in devices) {
      final lat = double.tryParse(device.latitude) ?? -1.2842;
      final lng = double.tryParse(device.longitude) ?? 36.8163;
      final rotation = double.tryParse(device.course) ?? 0.0;
      final iconBytes = _getImageForDevice(device);
      final isSelected = _selectedVehiclePlate == device.numberPlate;
      final iconSize = isSelected ? 2.0 : 1.2;

      if (_vehicleAnnotations.containsKey(device.numberPlate)) {
        final ann = _vehicleAnnotations[device.numberPlate]!;
        ann.geometry = Point(coordinates: Position(lng, lat));
        ann.iconRotate = rotation;
        ann.image = iconBytes;
        ann.iconSize = iconSize;
        await _annotationManager!.update(ann);
      } else {
        final ann = await _annotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            image: iconBytes,
            iconSize: iconSize,
            iconRotate: rotation,
            textField: device.numberPlate,
            textSize: 10.0,
            textColor: 0xFFFFFFFF,
            textHaloColor: 0xFF000000,
            textHaloWidth: 1.0,
            textOffset: [0.0, 2.0],
          ),
        );
        _vehicleAnnotations[device.numberPlate] = ann;
      }
    }
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
      140,
    );
    customIcons['blue'] = await _resizeAndLoadIcon('assets/blue_car.png', 70);
    customIcons['red'] = await _resizeAndLoadIcon('assets/red_car.png', 90);
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
        appBar: _buildAppBar(),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CarsScreen(),
            _buildMapTab(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        toolbarHeight: 40,
        title: Obx(() {
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
          final label = _selectedGroup == null
              ? '$_userName[$total/$online]'
              : '$_userName · $_selectedGroup';
          return PopupMenuButton<String?>(
            onSelected: (group) {
              setState(() => _selectedGroup = group);
              _applyFilters();
              _updateVehicleAnnotations(_filteredDevices);
            },
            offset: const Offset(0, 40),
            color: context.col.surface,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.col.textPrimary,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: context.col.textPrimary,
                  size: 20,
                ),
              ],
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
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontWeight: _selectedGroup == null
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: _selectedGroup == g
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.col.textPrimary, size: 22),
            onPressed: () =>
                setState(() => _showSearchOverlay = !_showSearchOverlay),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            decoration: BoxDecoration(
              color: context.col.bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusSM),
                color: kBlue,
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: kWhite,
              unselectedLabelColor: context.col.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu, size: 18),
                      SizedBox(width: 6),
                      Text('List'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Map'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        _breathingCircle = null;
        _circleAnnotationManager = null;
        _annotationManager = null;
        mapboxMap = map;
      },
      onStyleLoadedListener: (_) => _setupMapLayers(),
      onTapListener: (MapContentGestureContext context) {
        _onMapTapped(context.point);
      },
      onCameraChangeListener: (_) => _updateBannerPosition(),
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
        _mapControlBtn(Icons.people_outline, () {}),
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
          // Center: prev / next arrows
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _mapControlBtn(Icons.chevron_left, _showPreviousVehicle),
                const SizedBox(width: 8),
                _mapControlBtn(Icons.chevron_right, _showNextVehicle),
              ],
            ),
          ),
          // Right: zoom
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mapControlBtn(Icons.add, _zoomIn),
              const SizedBox(height: 8),
              _mapControlBtn(Icons.remove, _zoomOut),
            ],
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
    final bool isMoving = device.ignitionStatus == 1 && isOnline;
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
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: context.col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Status + signal strength
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
                      Icon(
                        Icons.signal_cellular_alt,
                        size: 13,
                        color: context.col.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${device.signalStrength}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.col.textSecondary,
                        ),
                      ),
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
    final bool isMoving = device.ignitionStatus == 1 && isOnline;
    final Color speedColor = isMoving ? kSuccessGreen : context.col.textSecondary;

    return Container(
      color: context.col.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header: name + speed + signal + close
          Row(
            children: [
              Text(
                device.numberPlate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.col.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Speed:${device.speed}km/h',
                style: TextStyle(
                  fontSize: 13,
                  color: speedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kSuccessGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${device.signalStrength}',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.battery_5_bar,
                color: context.col.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
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
                child: Icon(
                  Icons.close,
                  color: context.col.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Location row
          Row(
            children: [
              Icon(Icons.location_on, color: kBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.location.trim().isEmpty
                      ? 'Location unavailable'
                      : device.location,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.col.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Timestamp row
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: context.col.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _utils.formatTime(device.updatedAt),
                style: TextStyle(
                  fontSize: 13,
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
        boxShadow: [kShadowMD],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navBarItem(Icons.directions_car, 'Details', kBlue, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectedCarScreen(
                    devices: device,
                    carModel: '${device.type} ${device.make}'.trim(),
                    licensePlate: device.numberPlate,
                  ),
                ),
              );
            }),
            _navBarItem(Icons.route_rounded, 'Playback', kSuccessGreen, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlaybackScreen(numberPlate: device.numberPlate),
                ),
              );
            }),
            _navBarItem(Icons.gps_fixed, 'Tracking', const Color(0xFFF39C12), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleLocationScreen(
                    latitude: double.tryParse(device.latitude) ?? -1.2842,
                    longitude: double.tryParse(device.longitude) ?? 36.8163,
                    deviceId: device.deviceId,
                    numberPlate: device.numberPlate,
                  ),
                ),
              );
            }),
            _navBarItem(Icons.terminal, 'Command', kBlue, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Commands(device: device),
                ),
              );
            }),
            _navBarItem(Icons.grid_on_rounded, 'Fence', kSuccessGreen, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Geofence coming soon')),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navBarItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kWhite, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.col.textPrimary,
                fontWeight: FontWeight.w500,
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
