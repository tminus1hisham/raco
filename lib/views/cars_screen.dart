import 'package:atom/config/constants.dart';
import 'package:atom/views/selected_car_screen.dart';
import 'package:atom/widgets/car_info_card.dart';
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
            customHeader(label: "My Cars", icon: Icons.directions_car),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
