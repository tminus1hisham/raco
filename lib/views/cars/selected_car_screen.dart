import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/views/cars/car_report.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/views/cars/vehicle_details.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class SelectedCarScreen extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final int batteryLevel;

  const SelectedCarScreen({
    super.key,
    required this.carModel,
    required this.licensePlate,
    required this.batteryLevel,
  });

  @override
  State<SelectedCarScreen> createState() => _SelectedCarScreenState();
}

class _SelectedCarScreenState extends State<SelectedCarScreen> {
  bool isVehicleActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            customHeader(
              label: widget.carModel,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      builder: (context) => DriverBehaviour(),
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
                                      builder: (context) => PlaybackScreen(),
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
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.driver_behaviour,
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
                                title: 'Details',
                                subtitle:
                                    "View a detailed infomation of the vehicle.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VehicleDetails(
                                        vehiclePlate: "KDG001A",
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildCommandItem(
                                title: 'Commands',
                                subtitle: "View all the commands of a vehicle.",
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
                                title: 'Command History',
                                subtitle: "View all the commands actioned.",
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.commandHistory,
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildCommandItem(
                                title: 'Geo Fence',
                                subtitle:
                                    "Set a radius where your car to operate.",
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.geofencingScreen,
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildCommandItem(
                                title: 'View Live Location',
                                subtitle: "See your the vehicle live location.",
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildCommandItem(
                                title: 'Reports',
                                subtitle: "See all the reports.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CarReports(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildCommandItem(
                                title: 'Certificate',
                                subtitle: "Expiry: 22/12/2025.",
                                onTap: () {},
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
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
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
