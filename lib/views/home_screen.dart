import 'dart:convert';
import 'dart:ui' as ui;

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/mqtt_client.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mqtt_client/mqtt_client.dart';

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

  final DeviceController _controller = Get.put(DeviceController());
  final MqttService _mqttService = MqttService();
  Map<String, BitmapDescriptor> customIcons = {};

  final TextEditingController _searchController = TextEditingController();
  List<Device> _filteredDevices = [];

  bool _isDataReady = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCustomIcons();

    await _controller.fetchDevices();

    // Update filtered devices
    final devices = _controller.devicesModel.value?.devices ?? [];
    setState(() {
      _filteredDevices = devices;
    });

    setState(() {
      _isDataReady = true;
    });

    // Subscribe to MQTT and get user location
    _subscribeToVehicleTopics();
    _getUserLocation();
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
          (selectedVehicleIndex - 1 + devices.length) %
          devices.length; // move to prev
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

  Future<void> _loadCustomIcons() async {
    customIcons['green'] = await _resizeAndLoadIcon(
      'assets/green_car.png',
      180,
    );
    customIcons['blue'] = await _resizeAndLoadIcon('assets/blue_car.png', 100);
    customIcons['red'] = await _resizeAndLoadIcon('assets/red_car.png', 100);
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

  void _subscribeToVehicleTopics() {
    if (!_mqttService.isConnected) {
      print("MQTT not connected yet");
      return;
    }

    print("SUBSCRIBBING!!!");

    // Example topics
    _mqttService.subscribeToTopic("KDS123B");
    // _mqttService.subscribeToTopic("vehicles/CAR456/location");

    _mqttService.client.updates!.listen((messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      final topic = messages[0].topic;
      print("📩 $topic => $payload");

      // Parse topic (vehicles/<carId>/location)
      final parts = topic.split('/');
      if (parts.length >= 3 && parts[0] == 'vehicles') {
        final carId = parts[1];
        _handleCarLocation(carId, payload);
      }
    });
  }

  void _handleCarLocation(String carId, String message) {
    print(" Car $carId sent -> $message");

    try {
      final data = jsonDecode(message);
      print(data);
      // print("Parsed: lat=${data['lat']}, lng=${data['lng']}, speed=${data['speed']}");
      // here you can update your map markers with setState
    } catch (e) {
      print("Raw message: $message");
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
      return "assets/green_car.png"; // online and moving
    } else if (isOnline && ignitionStatus == 0) {
      return "assets/blue_car.png"; // offline
    } else {
      return "assets/red_car.png"; // online but stopped/idle
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
                  color: Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: kBlue,
                    boxShadow: [
                      BoxShadow(
                        color: kBlue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.all(4),
                  labelColor: kWhite,
                  unselectedLabelColor: Colors.grey[600],
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
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Icon(Icons.search, color: Colors.grey[600], size: 24),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by number plate",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
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
            icon: Icon(Icons.clear, color: Colors.grey[600]),
            onPressed: () {
              _searchController.clear();
              FocusScope.of(context).unfocus();

              setState(() {
                _filteredDevices =
                    _controller.devicesModel.value?.devices ?? [];
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
  //           color: Colors.black.withOpacity(0.1),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Colors.grey[700]),
            onPressed: _zoomIn,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: Colors.grey[700]),
            onPressed: _zoomOut,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.layers, color: Colors.grey[700]),
            onPressed: _toggleMapType,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
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
                    color: userLocation != null ? kBlue : Colors.grey[700],
                  ),
                  onPressed: _moveToUserLocation,
                ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.grey[700],
            ),
            onPressed: _showPreviousVehicle,
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_outlined,
              color: Colors.grey[700],
            ),
            onPressed: _showNextVehicle,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleBottomSheet(Device device) {
    bool isVehicleActive = true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.43,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
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
                          carModel: device.make,
                          licensePlate: device.numberPlate,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kBlue.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                  child: Icon(
                    Icons.close,
                    color: Colors.black.withOpacity(0.5),
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
                      Row(
                        children: [
                          Text(
                            device.numberPlate,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            device.make,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
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
                                          ? Colors.green
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isVehicleActive ? "ON" : "OFF",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isVehicleActive
                                          ? Colors.green
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 10),
                              Switch(
                                value: isVehicleActive,
                                onChanged: (bool value) {
                                  setModalState(() {
                                    isVehicleActive = value;
                                  });
                                },
                                activeColor: Colors.green,
                                activeTrackColor: Colors.green.withOpacity(0.3),
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.grey.withOpacity(
                                  0.3,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Driver Behaviour: ",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Engine: ",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Text(
                        "${device.ignitionStatus == 1 ? "ON" : "OFF"}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Average Speed: ",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Spacer(),
                      Text(
                        "Top Speed: ${device.speed}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
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
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
