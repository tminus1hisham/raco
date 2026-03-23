import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/technician_device_controller.dart';
import 'package:atom/views/cars/car_list_screen.dart';
import 'package:atom/widgets/cards/car_info_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final TechnicianDeviceController _controller = Get.put(
    TechnicianDeviceController(),
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = _controller.devicesModel.value?.devices ?? [];

      final col = context.col;
      return Scaffold(
        backgroundColor: col.bg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              customHeader(label: "Devices", icon: Icons.receipt_long),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: col.bg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBlack.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              title: 'Online',
                              icon: Icons.online_prediction,
                              color: kSuccessGreen,
                              count:
                                  _controller.devicesModel.value?.onlineDevices
                                      .toString() ??
                                  '0',
                              onPressed: () {
                                final onlineDevices = devices
                                    .where((d) => d.isDeviceOnline)
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CarListScreen(
                                      isTechnician: true,
                                      label: "Online",
                                      devices: onlineDevices,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatsCard(
                              title: 'Offline',
                              icon: Icons.wifi_off,
                              color: kRed,
                              count:
                                  _controller.devicesModel.value?.offlineDevices
                                      .toString() ??
                                  '0',
                              onPressed: () {
                                final offlineDevices = devices
                                    .where((d) => !d.isDeviceOnline)
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CarListScreen(
                                      label: "Offline",
                                      devices: offlineDevices,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return CarInfoCard(
                      expiryDate: device.certificateExpirey,
                      isAdmin: false,
                      carModel: "${device.type} ${device.make}",
                      licensePlate: device.numberPlate,
                      status: device.isDeviceOnline ? "Online" : "Offline",
                      statusColor: device.isDeviceOnline ? kSuccessGreen : kRed,
                      statusBackgroundColor: device.isDeviceOnline
                          ? kSuccessGreen.withValues(alpha: 0.1)
                          : kRed.withValues(alpha: 0.1),
                      currentSpeed: "${device.speed} km/h",
                      topSpeed: "",
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => SelectedCarScreen(
                        //       devices: device.toDevice(),
                        //       carModel: device.make,
                        //       licensePlate: device.numberPlate,
                        //     ),
                        //   ),
                        // );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final col = context.col;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          boxShadow: [kShadowSM],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kRadiusSM),
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
                      color: col.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: col.textSecondary,
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
