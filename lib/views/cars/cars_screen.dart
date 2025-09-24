import 'package:atom/config/constants.dart';
import 'package:atom/views/cars/car_list_screen.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/cards/car_info_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(
              label: "Vehicles",
              icon: Icons.directions_car,
              onPressed: () {
                Navigator.pop(context);
              },
              showBackButton: true,
            ),

            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: kBgGrey,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            title: 'Online',
                            icon: Icons.online_prediction,
                            color: kSuccessGreen,
                            count: '40',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CarListScreen(label: "Online"),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildStatsCard(
                            title: 'Offline',
                            icon: Icons.wifi_off,
                            color: kRed,
                            count: '2',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CarListScreen(label: "Offline"),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  CarInfoCard(
                    carModel: 'BMW X6',
                    licensePlate: 'KDF 001A',
                    status: 'Moving',
                    statusColor: Colors.green,
                    statusBackgroundColor: Color(0xFFE8F5E8),
                    currentSpeed: '65 km/h',
                    topSpeed: '78 km/h',
                    onPressed: () {
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
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  CarInfoCard(
                    carModel: 'Isuzu NQR',
                    licensePlate: 'KDF 001A',
                    status: 'Overspeed',
                    statusColor: kRed,
                    statusBackgroundColor: kRed.withOpacity(0.1),
                    currentSpeed: '80 km/h',
                    topSpeed: '90 km/h',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectedCarScreen(
                            carModel: 'Isuzu NQR',
                            licensePlate: 'AG 5758 SS',
                            batteryLevel: 4,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Column(
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
