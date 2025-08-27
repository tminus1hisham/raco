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
                    carModel: 'BMW X3',
                    licensePlate: "KDB002A",
                    batteryLevel: 6,
                    stats: [
                      StatCardData(icon: Icons.location_on, value: '20 km'),
                      StatCardData(icon: Icons.speed, value: '100 km/h'),
                    ],
                  ),
                  CarInfoCard(
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
                    carModel: 'Tesla',
                    licensePlate: "KDB001A",
                    batteryLevel: 2,
                    stats: [
                      StatCardData(icon: Icons.location_on, value: '25.3 km'),
                      StatCardData(icon: Icons.speed, value: '85 km/h'),
                    ],
                  ),
                  CarInfoCard(
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
                    carModel: 'Tesla',
                    licensePlate: "KDB001A",
                    batteryLevel: 4,
                    stats: [
                      StatCardData(icon: Icons.location_on, value: '25.3 km'),
                      StatCardData(icon: Icons.speed, value: '85 km/h'),
                    ],
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
