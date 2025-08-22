import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' show Lottie;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedVehicleType = 0;
  int selectedVehicleIndex = 0;
  final MapController mapController = MapController();

  final List<Vehicle> vehicles = [
    Vehicle(
      name: "BMW X6",
      plate: "KDM004A",
      status: VehicleStatus.moving,
      batteryLevel: 0.85,
      position: LatLng(-1.2842328448615796, 36.816382318562034),
      image: "bmw_x6.png",
    ),
    Vehicle(
      name: "BMW X4",
      plate: "KDC002A",
      status: VehicleStatus.parking,
      batteryLevel: 0.6,
      position: LatLng(-1.3175902227858143, 36.786056310270034),
      image: "bmw_z4.png",
    ),
    Vehicle(
      name: "BMW M3",
      plate: "KDB001A",
      status: VehicleStatus.parking,
      batteryLevel: 0.9,
      position: LatLng(-1.2799336124445042, 36.77765642862558),
      image: "bmw_m3.png",
    ),
  ];

  void _selectVehicle(int index) {
    setState(() {
      selectedVehicleIndex = index;
    });

    mapController.move(vehicles[index].position, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildFullScreenMap(),

          Column(
            children: [
              // SizedBox(height: 10),
              _buildHeaderBanner(),
              Spacer(), // This pushes the vehicle list to the bottom
              _buildVehicleList(),
              SizedBox(height: 20),
            ],
          ),
        ],
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
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.atom',
          ),
          MarkerLayer(
            markers: vehicles.asMap().entries.map((entry) {
              int index = entry.key;
              Vehicle vehicle = entry.value;
              bool isSelected = index == selectedVehicleIndex;

              return Marker(
                point: vehicle.position,
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                child: GestureDetector(
                  onTap: () => _selectVehicle(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : kBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? kWhite : Colors.white,
                        width: isSelected ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: isSelected ? 12 : 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: isSelected ? 24 : 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue, kBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        // borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Text(
                  'Good Morning,',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kWhite,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: kWhite,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      height: 40,
                      width: 40,
                      child: Lottie.asset(
                        'assets/animations/hand.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_outlined, size: 28, color: kWhite),
              ),
              SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          final bool isSelected = index == selectedVehicleIndex;

          return GestureDetector(
            onTap: () => _selectVehicle(index),
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Made slightly transparent
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? kBlue : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? kBlue.withOpacity(0.3)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: isSelected ? 15 : 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vehicle.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? kBlue : Colors.black87,
                          ),
                        ),
                        Text(
                          vehicle.plate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vehicle.status == VehicleStatus.moving
                                    ? kBlue
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    vehicle.status == VehicleStatus.moving
                                        ? Icons.info
                                        : Icons.local_parking,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    vehicle.status == VehicleStatus.moving
                                        ? 'Moving'
                                        : 'Parking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        _buildBatteryIndicator(vehicle.batteryLevel),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? kBlue.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: isSelected ? kBlue : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatteryIndicator(double level) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: level,
            child: Container(
              decoration: BoxDecoration(
                color: level > 0.5 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

}

class Vehicle {
  final String name;
  final String plate;
  final VehicleStatus status;
  final double batteryLevel;
  final LatLng position;
  final String image;

  Vehicle({
    required this.name,
    required this.plate,
    required this.status,
    required this.batteryLevel,
    required this.position,
    required this.image,
  });
}

enum VehicleStatus { moving, parking }