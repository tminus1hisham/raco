import 'dart:async';
import 'dart:ui' as ui;

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'cars/cars_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedVehicleType = 0;
  int selectedVehicleIndex = 0;
  bool showBottomSheet = false;
  bool isLoadingLocation = false;

  GoogleMapController? mapController;
  LatLng? userLocation;
  double currentZoom = 14.0;
  Set<Marker> markers = {};
  late final Widget mapWidget;
  MapType _currentMapType = MapType.normal;

  final Utils _utils = Utils();
  final DeviceController _controller = Get.put(DeviceController());
  Map<String, BitmapDescriptor> customIcons = {};

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
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

      // 🔁 Keep following tracked car
      if (_trackedCarPlate != null) {
        final trackedDevice = devices.firstWhereOrNull(
          (d) => d.numberPlate == _trackedCarPlate,
        );

        if (trackedDevice != null && mapController != null) {
          final lat = double.tryParse(trackedDevice.latitude) ?? -1.2842;
          final lng = double.tryParse(trackedDevice.longitude) ?? 36.8163;
          mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        }
      }
    } catch (e) {
      setState(() => _isRefreshing = false);
    } finally {
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

      if (!_hasFitAllCars && devices.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitAllCarsOnMap(devices);
          _hasFitAllCars = true;
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() {
        _isDataReady = true;
      });
    }
  }

  Future<BitmapDescriptor> _resizeAndLoadIcon(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _showNextVehicle() {
    final devices = _filteredDevices;
    if (devices.isEmpty) return;

    setState(() {
      selectedVehicleIndex =
          (selectedVehicleIndex + 1) % devices.length; // move to next
    });

    _focusOnVehicle(selectedVehicleIndex);
  }

  void _showPreviousVehicle() {
    final devices = _filteredDevices;
    if (devices.isEmpty) return;

    setState(() {
      selectedVehicleIndex =
          (selectedVehicleIndex - 1 + devices.length) % devices.length;
    });

    _focusOnVehicle(selectedVehicleIndex);
  }

  void _focusOnVehicle(int index) {
    final devices = _filteredDevices;
    if (index < 0 || index >= devices.length || mapController == null) return;

    final device = devices[index];
    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;

    mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0),
    );

    _showVehicleInfoWindow(device);
  }

  void _showVehicleInfoWindow(Device device) {
    if (mapController != null) {
      mapController!.showMarkerInfoWindow(MarkerId(device.numberPlate));
    }
  }

  void _fitAllCarsOnMap(List<Device> devices) {
    if (mapController == null || devices.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var device in devices) {
      final lat = double.tryParse(device.latitude);
      final lng = double.tryParse(device.longitude);

      if (lat == null || lng == null) continue;

      if (minLat == null) {
        minLat = maxLat = lat;
        minLng = maxLng = lng;
      } else {
        if (lat < minLat) minLat = lat;
        if (lat > maxLat!) maxLat = lat;
        if (lng < minLng!) minLng = lng;
        if (lng > maxLng!) maxLng = lng;
      }
    }

    if (minLat == null || minLng == null || maxLat == null || maxLng == null) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate camera to show all markers with some padding
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location services')),
        );
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Location permission denied')));
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  void _moveToUserLocation() async {
    if (userLocation == null) await _getUserLocation();

    if (userLocation != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation!, 15.0),
      );
    }
  }

  void _zoomIn() async {
    if (mapController != null) {
      currentZoom += 1;
      mapController!.animateCamera(CameraUpdate.zoomTo(currentZoom));
    }
  }

  void _zoomOut() async {
    if (mapController != null) {
      currentZoom -= 1;
      mapController!.animateCamera(CameraUpdate.zoomTo(currentZoom));
    }
  }

  void _selectVehicle(int index) {
    setState(() {
      selectedVehicleIndex = index;
      showBottomSheet = true;
    });

    final devices = _controller.devicesModel.value?.devices ?? [];

    if (devices.isNotEmpty && index < devices.length) {
      final device = devices[index];
      final position = LatLng(
        double.tryParse(device.latitude) ?? -1.2842,
        double.tryParse(device.longitude) ?? 36.8163,
      );
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15.0));

      _showVehicleBottomSheet(device);
    }
  }

  Size getMarkerSize(bool isOnline, int ignitionStatus) {
    if (isOnline && ignitionStatus == 1) {
      return const Size(55, 55); // online and moving
    } else if (!isOnline) {
      return const Size(40, 40); // offline
    } else {
      return const Size(47, 47); // online but idle/stopped
    }
  }

  String getMarkerImage(bool isOnline, int ignitionStatus) {
    if (isOnline && ignitionStatus == 1) {
      return "assets/green_car.png";
    } else if (isOnline && ignitionStatus == 0) {
      return "assets/blue_car.png";
    } else {
      return "assets/red_car.png";
    }
  }

  void _showVehicleBottomSheet(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVehicleBottomSheet(device),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: AppBar(
            backgroundColor: kBgGrey,
            elevation: 0,
            toolbarHeight: 40,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Container(
                decoration: BoxDecoration(
                  color: kBgGrey,
                  boxShadow: [
                    BoxShadow(
                      color: kBlack.withValues(alpha: 0.05),
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.all(4),
                  labelColor: kWhite,
                  unselectedLabelColor: kGrey,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 6),
                          Text("Map"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt_outlined, size: 18),
                          SizedBox(width: 6),
                          Text("List"),
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
            // Tab 1: Map view
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

                    final devices =
                        _controller.devicesModel.value?.devices ?? [];

                    return Stack(
                      children: [
                        _buildFullScreenMap(_filteredDevices),
                        Positioned(
                          top: 10,
                          left: 20,
                          right: 20,
                          child: IgnorePointer(
                            ignoring: false,
                            child: _buildSearchBar(),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 70,
                          child: _buildMapControls(),
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

            // Tab 2: CarsScreen
            CarsScreen(),
          ],
        ),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else if (_currentMapType == MapType.terrain) {
        _currentMapType = MapType.hybrid;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }

  Widget _buildFullScreenMap(List<dynamic> devices) {
    final firstDevice = devices.isNotEmpty ? devices[0] as Device : null;
    final initialPosition = firstDevice != null
        ? LatLng(
            double.tryParse(firstDevice.latitude) ?? -1.2842,
            double.tryParse(firstDevice.longitude) ?? 36.8163,
          )
        : LatLng(-1.2842, 36.8163);

    // build markers
    final Set<Marker> deviceMarkers = devices.asMap().entries.map((entry) {
      int index = entry.key;
      Device device = entry.value as Device;

      final latitude = double.tryParse(device.latitude) ?? -1.2842;
      final longitude = double.tryParse(device.longitude) ?? 36.8163;

      // final imageKey = getMarkerImage(
      //   device.isDeviceOnline,
      //   device.ignitionStatus,
      // );

      // final imageKey = device.isDeviceOnline
      //     ? (device.ignitionStatus == 1 ? 'green' : 'blue')
      //     : 'red';

      final imageKey = device.isDeviceOnline ? 'green' : 'red';

      final markerIcon =
          customIcons[imageKey] ?? BitmapDescriptor.defaultMarker;

      return Marker(
        markerId: MarkerId(device.numberPlate),
        position: LatLng(latitude, longitude),
        rotation: double.tryParse(device.course) ?? 0.0,
        icon: markerIcon,
        onTap: () => _selectVehicle(index),
        infoWindow: InfoWindow(
          title: device.numberPlate,
          snippet: 'Speed: ${device.speed} km/h',
        ),
      );
    }).toSet();

    return GoogleMap(
      mapType: _currentMapType,
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: currentZoom,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      scrollGesturesEnabled: true,
      // zoomGesturesEnabled: true,
      // zoomControlsEnabled: false,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      markers: deviceMarkers.union(markers),

      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        if (devices.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitAllCarsOnMap(devices.cast<Device>());
          });
        }
      },
    );
  }

  void _focusOnSearchedCar(Device device) {
    if (mapController == null) return;

    final lat = double.tryParse(device.latitude) ?? -1.2842;
    final lng = double.tryParse(device.longitude) ?? 36.8163;

    mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
    );

    // Start tracking this car
    setState(() {
      _trackedCarPlate = device.numberPlate;
    });
  }

  // void _focusOnSearchedCar(Device device) {
  //   if (mapController == null) return;
  //
  //   final lat = double.tryParse(device.latitude) ?? -1.2842;
  //   final lng = double.tryParse(device.longitude) ?? 36.8163;
  //   mapController!.animateCamera(
  //     CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
  //   );
  // }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border.all(color: kLightGrey, width: 1),
        boxShadow: [kShadowSM],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: kSpaceXL),
            child: const Icon(Icons.search, color: kGrey, size: 24),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search by number plate",
                hintStyle: TextStyle(color: kGrey, fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
              onChanged: (query) {
                final allDevices =
                    _controller.devicesModel.value?.devices ?? [];
                setState(() {
                  _filteredDevices = allDevices
                      .where(
                        (device) => device.numberPlate.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .toList();
                });

                // Automatically focus on car if an exact match is found
                if (_filteredDevices.length == 1) {
                  _focusOnSearchedCar(_filteredDevices.first);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: kGrey),
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

  // Widget _buildSearchBar() {
  //   return Container(
  //     height: 50,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(5),
  //       border: Border.all(color: Colors.grey.shade400, width: 1),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.1),
  //           blurRadius: 10,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.only(left: 20),
  //           child: Icon(Icons.search, color: Colors.grey[600], size: 24),
  //         ),
  //         Expanded(
  //           child: TextField(
  //             decoration: InputDecoration(
  //               hintText: "Search",
  //               hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
  //               border: InputBorder.none,
  //               contentPadding: EdgeInsets.symmetric(
  //                 horizontal: 16,
  //                 vertical: 15,
  //               ),
  //             ),
  //           ),
  //         ),
  //         Container(
  //           color: kGrey.withOpacity(0.1),
  //           margin: EdgeInsets.only(right: 5),
  //           padding: EdgeInsets.all(8),
  //           child: Padding(
  //             padding: EdgeInsets.only(left: 25),
  //             child: Icon(Icons.tune, color: Colors.grey[600], size: 20),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMapControls() {
    return Column(
      children: [
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: kGrey),
            onPressed: _zoomIn,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: kGrey),
            onPressed: _zoomOut,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(Icons.layers, color: kGrey),
            onPressed: _toggleMapType,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: isLoadingLocation
              ? Padding(
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
                  ),
                  onPressed: _moveToUserLocation,
                ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: kGrey,
            ),
            onPressed: _showPreviousVehicle,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_outlined,
              color: kGrey,
            ),
            onPressed: _showNextVehicle,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: IconButton(
            icon: Icon(Icons.center_focus_strong, color: kGrey),
            onPressed: () => _fitAllCarsOnMap(_filteredDevices),
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusSM),
            boxShadow: [kShadowSM],
          ),
          child: _isRefreshing
              ? Padding(
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _countdown <= 3 ? kRed : kBlue,
                    ),
                  ),
                  onPressed: () {
                    _countdown = 10; // Reset counter
                    _refreshData(); // Immediate refresh
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVehicleBottomSheet(Device device) {
    bool isVehicleActive = device.ignitionStatus == 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.43,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kRadiusLG),
          topRight: Radius.circular(kRadiusLG),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kLightGrey,
              borderRadius: BorderRadius.circular(kRadiusSM),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectedCarScreen(
                          devices: device,
                          carModel: "${device.type} ${device.make}",
                          licensePlate: device.numberPlate,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(kRadiusMD),
                      border: Border.all(
                        color: kBlue.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [kShadowSM],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(Icons.more_vert, color: kBlue, size: 20),
                          SizedBox(width: 5),
                          Text(
                            "More Details",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.close,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            device.numberPlate,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: kBlack,
                            ),
                          ),
                          const SizedBox(height: kSpaceXS),
                          Text(
                            "${device.type} ${device.make}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: kGrey,
                            ),
                          ),
                        ],
                      ),

                      StatefulBuilder(
                        builder: (context, setModalState) {
                          return Row(
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'ENGINE',
                                    style: TextStyle(
                                      color: isVehicleActive
                                          ? kSuccessGreen
                                          : kGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isVehicleActive ? "ON" : "OFF",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isVehicleActive
                                          ? kSuccessGreen
                                          : kGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: kSpaceSM),
                              Switch(
                                value: isVehicleActive,
                                onChanged: (bool value) {},
                                activeColor: kSuccessGreen,
                                activeTrackColor: kSuccessGreen.withValues(alpha: 0.3),
                                inactiveThumbColor: kGrey,
                                inactiveTrackColor: kGrey.withValues(alpha: 0.3),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: kSpaceMD),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Driver Behaviour: Safe",
                        style: const TextStyle(
                          fontSize: 16,
                          color: kGrey,
                        ),
                      ),
                      Text(
                        "Time: ${_utils.formatTime(device.updatedAt)} ",
                        style: const TextStyle(
                          fontSize: 16,
                          color: kGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: kSpaceMD),

                  Row(
                    children: [
                      Text(
                        "Speed: ${device.speed} Km/h",
                        style: const TextStyle(fontSize: 16, color: kGrey),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: kSpaceXL),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'Playback',
                          icon: Icons.route,
                          color: kBlue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaybackScreen(
                                  numberPlate: device.numberPlate,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          title: 'Violations',
                          icon: Icons.warning_amber,
                          color: kRed,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViolationsScreen(
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kSpaceLG),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(kRadiusMD),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [kShadowSM],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpaceSM),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: kSpaceSM),
              Text(
                title,
                style: const TextStyle(fontSize: 15, color: kBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
