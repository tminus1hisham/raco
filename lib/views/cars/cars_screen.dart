import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
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
  final RenewCertificateController _renewCertificateController = Get.put(
    RenewCertificateController(),
  );

  @override
  void initState() {
    super.initState();
    // Defer to avoid triggering Obx rebuilds during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = _controller.devicesModel.value?.devices ?? [];

      return Stack(
        children: [
          Scaffold(
            backgroundColor: context.col.bg,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.col.bg,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                    child: RefreshIndicator(
                      onRefresh: () => _controller.fetchDevices(),
                      color: kBlue,
                      child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return CarInfoCard(
                          expiryDate: device.certificateExpirey,
                          isAdmin: true,
                          carModel: "${device.type} ${device.make}",
                          licensePlate: device.numberPlate,
                          status: device.isDeviceOnline ? "Online" : "Offline",
                          statusColor: device.isDeviceOnline
                              ? kSuccessGreen
                              : kRed,
                          statusBackgroundColor: device.isDeviceOnline
                              ? const Color(0xFFE8F5E8)
                              : kRed.withValues(alpha: 0.1),
                          currentSpeed: "${device.speed} km/h",
                          topSpeed: "",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectedCarScreen(
                                  devices: device,
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
                  ),
                ],
              ),
            ),
          ),
          if (_controller.isLoading.value ||
              _renewCertificateController.isLoading.value) ...[
            Container(
              color: kBlack.withValues(alpha: 0.3),
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
          color: context.col.surface,
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
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.col.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.col.textSecondary,
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
