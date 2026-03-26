import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/violations_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
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

  final Utils _utils = Utils();
  final DeviceController _controller = Get.put(DeviceController());
  Map<String, Uint8List> customIcons = {};

  final TextEditingController _searchController = TextEditingController();
  List<Device> _filteredDevices = [];

  bool _isDataReady = false;
  Timer? _pollingTimer;
  int _countdown = 10;
  bool _isRefreshing = false;
  bool _hasFitAllCars = false;
  String? _trackedCarPlate;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _refreshData();
          _countdown = 20;
        }
      });
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await _controller.fetchDevices(silent: true);
      final devices = _controller.devicesModel.value?.devices ?? [];
      setState(() {
        _filteredDevices = devices;
        _isRefreshing = false;
      });

      await _updateVehicleAnnotations(devices);

      if (_trackedCarPlate != null) {
        final tracked = devices
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
    } catch (e) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _initializeData() async {
    try {
      await _loadCustomIcons();
      await _controller.fetchDevices();
      final devices = _controller.devicesModel.value?.devices ?? [];
      setState(() {
        _filteredDevices = devices;
        _isDataReady = true;
      });
      _getUserLocation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateVehicleAnnotations(devices);
        if (!_hasFitAllCars && devices.isNotEmpty) {
          _fitAllCarsOnMap(devices);
          _hasFitAllCars = true;
        }
      });
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() => _isDataReady = true);
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

  // ─── Icon & annotation helpers ───────────────────────────────────────────

  /// Returns the pre-loaded Uint8List icon for a device based on its status.
  /// green = moving online, blue = idle online, red = offline.
  Uint8List? _getImageForDevice(Device device) {
    if (!device.isDeviceOnline) return customIcons['red'];
    if (device.ignitionStatus == 1) return customIcons['green'];
    return customIcons['blue'];
  }

  Future<void> _updateVehicleAnnotations(List<Device> devices) async {
    if (_annotationManager == null) return;

    // Remove stale annotations
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
            textOffset: [0.0, 2.0],
          ),
        );
        _vehicleAnnotations[device.numberPlate] = ann;
      }
    }
  }

  /// Hit-test the tapped map point against known vehicle positions.
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

    // ~0.0005° ≈ 55 m – reasonable tap target radius at zoom 14-16
    if (nearest != null && minDist < 0.0005) {
      setState(() => _selectedVehiclePlate = nearest!.numberPlate);
      _updateVehicleAnnotations(_filteredDevices);
      _showVehicleBottomSheet(nearest);
    }
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
    customIcons['green'] = await _resizeAndLoadIcon(
      'assets/green_car.png',
      140,
    );
    customIcons['blue'] = await _resizeAndLoadIcon('assets/blue_car.png', 70);
    customIcons['red'] = await _resizeAndLoadIcon('assets/red_car.png', 90);
    setState(() {});
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
      setState(() {
        userLocation = Point(
          coordinates: Position(currentPos.longitude, currentPos.latitude),
        );
        isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
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
    setState(() => _currentMapStyle = style);
    mapboxMap?.loadStyleURI(style).then((_) {
      _vehicleAnnotations.clear();
      _annotationManager = null;
      mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
        _annotationManager = manager;
        _updateVehicleAnnotations(_filteredDevices);
      });
    });
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

  void _showVehicleBottomSheet(Device device) {
    setState(() => _selectedVehiclePlate = device.numberPlate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVehicleBottomSheet(device),
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
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: context.col.bg,
            elevation: 0,
            toolbarHeight: 40,
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
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 6),
                          Text('Map'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt_outlined, size: 18),
                          SizedBox(width: 6),
                          Text('List'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _isDataReady
                ? Obx(() {
                    if (_controller.isLoading.value) {
                      return Center(
                        child: LoadingAnimationWidget.fourRotatingDots(
                          color: kBlue,
                          size: 50,
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        _buildMap(),
                        // Search bar
                        Positioned(
                          top: 10,
                          left: 16,
                          right: 68,
                          child: _buildSearchBar(),
                        ),
                        // Map controls (right side)
                        Positioned(
                          right: 12,
                          top: 10,
                          child: _buildMapControls(),
                        ),
                        // Status bar (bottom)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: _buildStatusBar(),
                        ),
                      ],
                    );
                  })
                : Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  ),
            CarsScreen(),
          ],
        ),
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
        mapboxMap = map;
        // Clear any stale references from a previous map instance
        _vehicleAnnotations.clear();
        map.annotations.createPointAnnotationManager().then((manager) {
          _annotationManager = manager;
          _updateVehicleAnnotations(_filteredDevices);
        });
      },
      onTapListener: (MapContentGestureContext context) {
        _onMapTapped(context.point);
      },
    );
  }

  // ─── Status bar ───────────────────────────────────────────────────────────

  Widget _buildStatusBar() {
    final model = _controller.devicesModel.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: context.col.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(kRadiusPill),
        boxShadow: [kShadowMD],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatChip(
            'Total',
            '${model?.totalDevices ?? _filteredDevices.length}',
            kBlue,
          ),
          _buildStatDivider(),
          _buildStatChip(
            'Online',
            '${model?.onlineDevices ?? 0}',
            kSuccessGreen,
          ),
          _buildStatDivider(),
          _buildStatChip(
            'Moving',
            '${model?.inMotion ?? 0}',
            const Color(0xFFF39C12),
          ),
          _buildStatDivider(),
          _buildStatChip('Offline', '${model?.offlineDevices ?? 0}', kRed),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.col.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatDivider() =>
      Container(height: 28, width: 1, color: context.col.border);

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
                final all = _controller.devicesModel.value?.devices ?? [];
                setState(() {
                  _filteredDevices = all
                      .where(
                        (d) => d.numberPlate.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .toList();
                });
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
                _filteredDevices =
                    _controller.devicesModel.value?.devices ?? [];
                _trackedCarPlate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── Map controls ─────────────────────────────────────────────────────────

  Widget _buildMapControls() {
    return Column(
      children: [
        _iconBtn(Icons.add, _zoomIn),
        const SizedBox(height: 8),
        _iconBtn(Icons.remove, _zoomOut),
        const SizedBox(height: 8),
        _iconBtn(Icons.layers_outlined, _showMapStyleSelector),
        const SizedBox(height: 8),
        // My location
        _controlContainer(
          child: isLoadingLocation
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kBlue,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: userLocation != null ? kBlue : kGrey,
                    size: 20,
                  ),
                  onPressed: _moveToUserLocation,
                ),
        ),
        const SizedBox(height: 8),
        _iconBtn(Icons.keyboard_arrow_up_rounded, _showPreviousVehicle),
        const SizedBox(height: 8),
        _iconBtn(Icons.keyboard_arrow_down_outlined, _showNextVehicle),
        const SizedBox(height: 8),
        _iconBtn(
          Icons.center_focus_strong,
          () => _fitAllCarsOnMap(_filteredDevices),
        ),
        const SizedBox(height: 8),
        // Countdown / refresh
        _controlContainer(
          child: _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kBlue,
                  ),
                )
              : IconButton(
                  icon: Text(
                    '$_countdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _countdown <= 3 ? kRed : kBlue,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _countdown = 10);
                    _refreshData();
                  },
                ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => _controlContainer(
    child: IconButton(
      icon: Icon(icon, color: context.col.textSecondary, size: 20),
      onPressed: onTap,
    ),
  );

  Widget _controlContainer({required Widget child}) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: context.col.surface,
      borderRadius: BorderRadius.circular(kRadiusSM),
      boxShadow: [kShadowSM],
    ),
    child: child,
  );

  // ─── Vehicle bottom sheet ─────────────────────────────────────────────────

  Widget _buildVehicleBottomSheet(Device device) {
    final bool isOnline = device.isDeviceOnline;
    final bool isMoving = device.ignitionStatus == 1 && isOnline;
    final Color statusColor = isMoving
        ? kSuccessGreen
        : isOnline
        ? kBlue
        : kRed;
    final String statusLabel = isMoving
        ? 'Moving'
        : isOnline
        ? 'Idle'
        : 'Offline';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kRadiusLG),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle icon ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(kRadiusMD),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child:
                          customIcons[isMoving
                                  ? 'green'
                                  : isOnline
                                  ? 'blue'
                                  : 'red'] !=
                              null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                kRadiusMD - 2,
                              ),
                              child: Image.memory(
                                customIcons[isMoving
                                    ? 'green'
                                    : isOnline
                                    ? 'blue'
                                    : 'red']!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Icon(
                              Icons.directions_car,
                              color: statusColor,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.numberPlate,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: context.col.textPrimary,
                            ),
                          ),
                          Text(
                            '${device.type} ${device.make}'.trim().isEmpty
                                ? 'Vehicle'
                                : '${device.type} ${device.make}'.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.col.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge + close
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: kGrey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
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
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Stats row ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: context.col.bg,
                    borderRadius: BorderRadius.circular(kRadiusMD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoTile(
                        Icons.speed_rounded,
                        '${device.speed} km/h',
                        'Speed',
                      ),
                      _vDivider(),
                      _infoTile(
                        Icons.access_time_rounded,
                        _utils.formatTime(device.updatedAt),
                        'Updated',
                      ),
                      _vDivider(),
                      _infoTile(
                        Icons.signal_cellular_alt,
                        '${device.signalStrength}%',
                        'Signal',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Action buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.location_on_rounded,
                        label: 'Live Track',
                        color: kSuccessGreen,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleLocationScreen(
                                latitude:
                                    double.tryParse(device.latitude) ?? -1.2842,
                                longitude:
                                    double.tryParse(device.longitude) ??
                                    36.8163,
                                deviceId: device.deviceId,
                                numberPlate: device.numberPlate,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.route_rounded,
                        label: 'Playback',
                        color: kBlue,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaybackScreen(
                                numberPlate: device.numberPlate,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.info_outline_rounded,
                        label: 'Details',
                        color: kGrey,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SelectedCarScreen(
                                devices: device,
                                carModel: '${device.type} ${device.make}',
                                licensePlate: device.numberPlate,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.warning_amber_rounded,
                        label: 'Violations',
                        color: kRed,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViolationsScreen(
                                numberPlate: device.numberPlate,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: kBlue, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.col.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.col.textSecondary),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: context.col.divider);

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(kRadiusMD),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
