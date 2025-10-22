import 'package:atom/config/constants.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/views/cars/geofencing_screen.dart';
import 'package:atom/views/cars/vehicle_details.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/reports_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectedCarScreen extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final Device devices;

  const SelectedCarScreen({
    super.key,
    required this.carModel,
    required this.licensePlate,
    required this.devices,
  });

  @override
  State<SelectedCarScreen> createState() => _SelectedCarScreenState();
}

class _SelectedCarScreenState extends State<SelectedCarScreen> {
  bool isVehicleActive = true;
  final _utils = Utils();

  final RenewCertificateController _controller = Get.put(
    RenewCertificateController(),
  );

  bool _isCertificateExpired(String expiryDate) {
    try {
      final parsedDate = DateTime.parse(expiryDate);
      final now = DateTime.now();

      return parsedDate.isBefore(now) || parsedDate.isAtSameMomentAs(now);
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: kBgGrey,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  customHeader(
                    label: widget.licensePlate,
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kGrey,
                                    ),
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Row(
                                        children: [
                                          Text(
                                            isVehicleActive
                                                ? "ENGINE ON"
                                                : " ENGINE OFF",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: isVehicleActive
                                                  ? Colors.green
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Switch(
                                            value: isVehicleActive,
                                            onChanged: (bool value) {
                                              setModalState(() {
                                                isVehicleActive = value;
                                              });
                                            },
                                            activeColor: Colors.green,
                                            activeTrackColor: Colors.green
                                                .withOpacity(0.3),
                                            inactiveThumbColor: Colors.grey,
                                            inactiveTrackColor: Colors.grey
                                                .withOpacity(0.3),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'Vehicle Safety',
                                      icon: Icons.safety_check_outlined,
                                      color: Colors.green,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DriverBehaviour(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'Location History',
                                      icon: Icons.route,
                                      color: kBlue,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PlaybackScreen(
                                                  numberPlate: widget
                                                      .devices
                                                      .numberPlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'violations',
                                      icon: Icons.warning_amber,
                                      color: kRed,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ViolationsScreen(
                                                  numberPlate: widget
                                                      .devices
                                                      .numberPlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Vehicle Management',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kGrey,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSettingsCard(
                                child: Column(
                                  children: [
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Details',
                                      subtitle:
                                          "View a detailed infomation of the vehicle.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VehicleDetails(
                                                  vehiclePlate: "KDG001A",
                                                  device: widget.devices,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Commands',
                                      subtitle:
                                          "View all the commands of a vehicle.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Commands(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Command History',
                                      subtitle:
                                          "View all the commands actioned.",
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.commandHistory,
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Geo Fence',
                                      subtitle:
                                          "Set a radius where your car to operate.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GeofencingScreen(
                                                  numberPlate:
                                                      widget.licensePlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'View Live Location',
                                      subtitle:
                                          "See your the vehicle live location.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VehicleLocationScreen(
                                                  latitude:
                                                      double.tryParse(
                                                        widget.devices.latitude,
                                                      ) ??
                                                      0.0,
                                                  longitude:
                                                      double.tryParse(
                                                        widget
                                                            .devices
                                                            .longitude,
                                                      ) ??
                                                      0.0,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Reports',
                                      subtitle: "See all the reports.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReportsScreen(
                                              numberPlate: widget.licensePlate,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: _isCertificateExpired(
                                        widget.devices.certificateExpirey,
                                      ),
                                      title: 'Certificate',
                                      subtitle:
                                          'Expiry: ${_utils.formatDate(widget.devices.certificateExpirey)}',
                                      onTap: () {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (context) => ActionDialog(
                                            title: "Renew Certificate",
                                            message:
                                                "Are you sure you want to renew certificate?",
                                            confirmText: "Renew",
                                            cancelText: "Cancel",
                                            onConfirm: () async {
                                              final success = await _controller
                                                  .renewCertificate(
                                                    Get.context!,
                                                    [widget.licensePlate],
                                                  );

                                              if (success) {
                                                CustomAlertDialog(
                                                  context: Get.context!,
                                                  title: "Success",
                                                  message:
                                                      "You have renewed your certificate.",
                                                  icon:
                                                      "assets/animations/Success.json",
                                                  buttonColor: kSuccessGreen,
                                                );
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.isLoading.value)
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
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCommandItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showBanner,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (showBanner) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      "Expired",
                      style: TextStyle(
                        color: kRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 5),
                ],

                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey.shade100);
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
