import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'cars/cars_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedVehicleType = 0;
  int selectedVehicleIndex = 0;
  final MapController mapController = MapController();
  bool showBottomSheet = false;

  final DeviceController _controller = Get.put(DeviceController());

  @override
  void initState() {
    super.initState();
    _controller.fetchDevices();
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
      mapController.move(position, 15.0);
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

  String getMarkerImage(bool isOnline, int ignitionStatus, int signalStrength) {
    if (isOnline && ignitionStatus == 1 && signalStrength > 0) {
      return "assets/green_car.png"; // online and moving
    } else if (isOnline && ignitionStatus == 0 && signalStrength > 0) {
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
          children: [
            // Tab 1: Map view
            Obx(() {
              if (_controller.isLoading.value) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  ),
                );
              }

              final devices = _controller.devicesModel.value?.devices ?? [];

              return Stack(
                children: [
                  _buildFullScreenMap(devices),
                  Positioned(
                    top: 10,
                    left: 20,
                    right: 20,
                    child: _buildSearchBar(),
                  ),
                  Positioned(right: 20, top: 70, child: _buildMapControls()),
                ],
              );
            }),

            // Tab 2: CarsScreen
            CarsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMap(List<dynamic> devices) {
    final firstDevice = devices.isNotEmpty ? devices[0] as Device : null;
    final initialPosition = firstDevice != null
        ? LatLng(
            double.tryParse(firstDevice.latitude) ?? -1.2842,
            double.tryParse(firstDevice.longitude) ?? 36.8163,
          )
        : LatLng(-1.2842, 36.8163);

    return Positioned.fill(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: initialPosition,
          initialZoom: 13.0,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.atom',
          ),
          MarkerLayer(
            markers: devices.asMap().entries.map((entry) {
              int index = entry.key;
              Device device = entry.value as Device;

              final latitude = double.tryParse(device.latitude) ?? -1.2842;
              final longitude = double.tryParse(device.longitude) ?? 36.8163;
              final position = LatLng(latitude, longitude);

              final imagePath = getMarkerImage(
                device.isDeviceOnline,
                device.ignitionStatus,
                device.signalStrength,
              );
              final size = getMarkerSize(
                device.isDeviceOnline,
                device.ignitionStatus,
              );

              return Marker(
                point: position,
                width: size.width,
                height: size.height,
                child: GestureDetector(
                  onTap: () => _selectVehicle(index),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
            ),
          ),
          Container(
            color: kGrey.withOpacity(0.1),
            margin: EdgeInsets.only(right: 5),
            padding: EdgeInsets.all(8),
            child: Padding(
              padding: EdgeInsets.only(left: 25),
              child: Icon(Icons.tune, color: Colors.grey[600], size: 20),
            ),
          ),
        ],
      ),
    );
  }

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
            onPressed: () {
              // Zoom in functionality
            },
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: Colors.grey[700]),
            onPressed: () {
              // Zoom out functionality
            },
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.map, color: Colors.grey[700]),
            onPressed: () {
              // Zoom out functionality
            },
          ),
        ),
        SizedBox(height: 10),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.my_location, color: Colors.grey[700]),
            onPressed: () {
              // Zoom out functionality
            },
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
                      // Text(
                      //   vehicle.driverBehaviour,
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.green,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Engine: ",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      // Text(
                      //   "${device.engineStatus} (${vehicle.engineRunTime})",
                      //   style: TextStyle(
                      //     fontSize: 16,
                      //     color: Colors.black87,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                      Text(
                        "${device.ignitionStatus == 1 ? "ON" : "OFF"}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      // Text(
                      //   "Today: ${vehicle.todayDistance}",
                      //   style: TextStyle(fontSize: 16, color: Colors.black87),
                      // ),
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
                          title: 'Violations ( 10 )',
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
