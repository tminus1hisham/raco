import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      status: "moving",
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
      status: "parking",
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
      status: "parking",
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
      status: "tampered",
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
    return Scaffold(
      body: Stack(
        children: [
          _buildFullScreenMap(),
          Positioned(top: 60, left: 20, right: 20, child: _buildSearchBar()),
          Positioned(right: 20, top: 140, child: _buildMapControls()),
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
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
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

              Color markerColor = Colors.green;
              if (vehicle.status == "parking") {
                markerColor = Colors.orange;
              }
              if (vehicle.status == "moving") {
                markerColor = Colors.green;
              }
              if (vehicle.status == "tampered") {
                markerColor = Colors.red;
              }

              return Marker(
                point: vehicle.position,
                width: 42,
                height: 42,
                child: GestureDetector(
                  onTap: () => _selectVehicle(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(8),
            child: Icon(Icons.tune, color: Colors.grey[600], size: 20),
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
          width: 50,
          height: 50,
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
          width: 50,
          height: 50,
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
      ],
    );
  }

  Widget _buildVehicleBottomSheet(Vehicle vehicle) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.plate,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            vehicle.model,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.status == "moving"
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          vehicle.status == "moving" ? "Moving" : "Parking",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Driver Behaviour
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
                      Spacer(),

                      _buildBatteryIndicator(vehicle.batteryLevel),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Engine status
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

                  SizedBox(height: 15),

                  // Speed info
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

                  SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.info_outline,
                          label: "Details",
                          color: Colors.blue[100]!,
                          textColor: Colors.blue[700]!,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.wifi,
                          label: "Command",
                          color: Colors.green[100]!,
                          textColor: Colors.green[700]!,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.bar_chart,
                          label: "Reports",
                          color: Colors.orange[100]!,
                          textColor: Colors.orange[700]!,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.more_horiz,
                          label: "More",
                          color: Colors.purple[100]!,
                          textColor: Colors.purple[700]!,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 24),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator(double level) {
    return Row(
      children: [
        // Battery bars
        Row(
          children: List.generate(5, (index) {
            bool isActive = index < (level * 5).round();
            return Container(
              width: 6,
              height: 20,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? (level > 0.5 ? Colors.green : Colors.orange)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
        SizedBox(width: 4),
        Icon(Icons.local_gas_station, size: 16, color: Colors.grey[600]),
      ],
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
