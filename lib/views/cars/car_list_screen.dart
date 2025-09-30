import 'package:atom/config/constants.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/cards/car_info_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class CarListScreen extends StatefulWidget {
  final String label;
  final List devices;

  const CarListScreen({super.key, required this.label, required this.devices});

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  @override
  Widget build(BuildContext context) {
    final devices = widget.devices;

    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: widget.label,
              icon: Icons.directions_car,
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, color: kGrey, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "No devices found",
                            style: TextStyle(color: kGrey, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];

                        return CarInfoCard(
                          carModel: device.make,
                          licensePlate: device.numberPlate,
                          status: device.isDeviceOnline ? "Online" : "Offline",
                          statusColor: device.isDeviceOnline
                              ? kSuccessGreen
                              : kRed,
                          statusBackgroundColor: device.isDeviceOnline
                              ? const Color(0xFFE8F5E8)
                              : kRed.withOpacity(0.1),
                          currentSpeed: "${device.speed} km/h",
                          topSpeed: "",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectedCarScreen(
                                  carModel: device.make,
                                  licensePlate: device.numberPlate,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
