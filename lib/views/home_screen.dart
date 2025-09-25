import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  final List<Vehicle> vehicles = [
    Vehicle(
      name: "BMW X6",
      plate: "KDF001A",
      model: "Isuzu NQR",
      status: "online",
      batteryLevel: 0.85,
      position: LatLng(-1.2842328448615796, 36.816382318562034),
      image: "bmw_x6.png",
      driverBehaviour: "Safe",
      engineStatus: "Active",
      engineRunTime: "4hr 22Mins",
      todayDistance: "22KM",
      averageSpeed: "60 KM/Hr",
      topSpeed: "92KM/Hr",
    ),
    Vehicle(
      name: "BMW X4",
      plate: "KDC002A",
      model: "Isuzu NQR",
      status: "offline",
      batteryLevel: 0.6,
      position: LatLng(-1.3175902227858143, 36.786056310270034),
      image: "bmw_z4.png",
      driverBehaviour: "Safe",
      engineStatus: "Idle",
      engineRunTime: "2hr 15Mins",
      todayDistance: "15KM",
      averageSpeed: "45 KM/Hr",
      topSpeed: "78KM/Hr",
    ),
    Vehicle(
      name: "BMW M3",
      plate: "KDB001A",
      model: "Isuzu NQR",
      status: "tampered",
      batteryLevel: 0.9,
      position: LatLng(-1.2799336124445042, 36.77765642862558),
      image: "bmw_m3.png",
      driverBehaviour: "Safe",
      engineStatus: "Stopped",
      engineRunTime: "0hr 0Mins",
      todayDistance: "8KM",
      averageSpeed: "35 KM/Hr",
      topSpeed: "65KM/Hr",
    ),
    Vehicle(
      name: "Toyota",
      plate: "KDB001A",
      model: "Vitz",
      status: "online",
      batteryLevel: 0.9,
      position: LatLng(-1.3799336124445042, 36.87765642862558),
      image: "bmw_m3.png",
      driverBehaviour: "Risky",
      engineStatus: "Moving",
      engineRunTime: "0hr 0Mins",
      todayDistance: "8KM",
      averageSpeed: "35 KM/Hr",
      topSpeed: "65KM/Hr",
    ),
  ];

  void _selectVehicle(int index) {
    setState(() {
      selectedVehicleIndex = index;
      showBottomSheet = true;
    });

    mapController.move(vehicles[index].position, 15.0);
    _showVehicleBottomSheet(vehicles[index]);
  }

  Size getMarkerSize(String status) {
    switch (status) {
      case "online":
        return const Size(55, 55);
      case "offline":
        return const Size(40, 40);
      default:
        return const Size(47, 47);
    }
  }

  void _showVehicleBottomSheet(Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVehicleBottomSheet(vehicle),
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
            Stack(
              children: [
                _buildFullScreenMap(),
                Positioned(
                  top: 10, // Reduced from 20
                  left: 20,
                  right: 20,
                  child: _buildSearchBar(),
                ),
                Positioned(
                  right: 20,
                  top: 70, // Reduced from 90
                  child: _buildMapControls(),
                ),
              ],
            ),
            // Tab 2: CarsScreen
            CarsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return Positioned.fill(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: vehicles[selectedVehicleIndex].position,
          initialZoom: 13.0,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            // urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.atom',
          ),
          MarkerLayer(
            markers: vehicles.asMap().entries.map((entry) {
              int index = entry.key;
              Vehicle vehicle = entry.value;

              String imagePath;
              switch (vehicle.status.toLowerCase()) {
                case "online":
                  imagePath = "assets/green_car.png";
                  break;
                case "offline":
                  imagePath = "assets/blue_car.png";
                  break;
                case "tampered":
                  imagePath = "assets/red_car.png";
                  break;
                default:
                  imagePath = "assets/green_car.png";
              }

              final size = getMarkerSize(vehicle.status);

              return Marker(
                point: vehicle.position,
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

  Widget _buildVehicleBottomSheet(Vehicle vehicle) {
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
                          carModel: 'BMW X6',
                          licensePlate: 'AG 5758 SS',
                          batteryLevel: 4,
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
                            vehicle.plate,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            vehicle.model,
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

                                  print(
                                    'Vehicle ${vehicle.plate} is now ${value ? "ON" : "OFF"}',
                                  );
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
                      Text(
                        vehicle.driverBehaviour,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
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
                        "${vehicle.engineStatus} (${vehicle.engineRunTime})",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Today: ${vehicle.todayDistance}",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "Average Speed: ${vehicle.averageSpeed}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Spacer(),
                      Text(
                        "Top Speed: ${vehicle.topSpeed}",
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
                                builder: (context) => PlaybackScreen(),
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
                            Navigator.pushNamed(
                              context,
                              AppRoutes.driver_behaviour,
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

class Vehicle {
  final String name;
  final String plate;
  final String model;
  final String status;
  final double batteryLevel;
  final LatLng position;
  final String image;
  final String driverBehaviour;
  final String engineStatus;
  final String engineRunTime;
  final String todayDistance;
  final String averageSpeed;
  final String topSpeed;

  Vehicle({
    required this.name,
    required this.plate,
    required this.model,
    required this.status,
    required this.batteryLevel,
    required this.position,
    required this.image,
    required this.driverBehaviour,
    required this.engineStatus,
    required this.engineRunTime,
    required this.todayDistance,
    required this.averageSpeed,
    required this.topSpeed,
  });
}
