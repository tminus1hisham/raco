import 'package:atom/config/constants.dart';
import 'package:atom/views/widgets/car_info_card.dart';
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
      body: Column(
        children: [
          CarInfoCard(
            carModel: 'Tesla',
            licensePlate: "KDB001A",
            batteryLevel: 4,
            stats: [
              StatCardData(
                icon: Icons.location_on,
                value: '25.3 km',
                label: 'Distance',
              ),
              StatCardData(
                icon: Icons.speed,
                value: '85 km/h',
                label: 'Average Speed',
              ),
              StatCardData(
                icon: Icons.battery_charging_full,
                value: '78%',
                label: 'Battery',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
