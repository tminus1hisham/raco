import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/views/cars/car_list_screen.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/cards/car_info_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  final DeviceController _controller = Get.put(DeviceController());

  @override
  void initState() {
    super.initState();
    _controller.fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = _controller.devicesModel.value?.devices ?? [];

      return Stack(
        children: [
          Scaffold(
            backgroundColor: kBgGrey,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: kBgGrey,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                                      _controller
                                          .devicesModel
                                          .value
                                          ?.onlineDevices
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
                                      _controller
                                          .devicesModel
                                          .value
                                          ?.offlineDevices
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
          ),
          if (_controller.isLoading.value) ...[
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: kBlue,
                  size: 50,
                ),
              ),
            ),
          ],
        ],
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Column(
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
