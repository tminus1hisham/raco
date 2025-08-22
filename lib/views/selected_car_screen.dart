import 'package:atom/config/constants.dart';
import 'package:atom/views/widgets/car_info_card.dart';
import 'package:atom/views/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class SelectedCarScreen extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final int batteryLevel;
  final List<StatCardData> stats;

  const SelectedCarScreen({
    super.key,
    required this.carModel,
    required this.licensePlate,
    required this.batteryLevel,
    required this.stats,
  });

  @override
  State<SelectedCarScreen> createState() => _SelectedCarScreenState();
}

class _SelectedCarScreenState extends State<SelectedCarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            customHeader(label: widget.carModel, icon: Icons.drive_eta_rounded),
            Expanded(
              child: ListView(
                children: [
                  SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                title: 'Lock',
                                icon: Icons.lock_outline,
                                color: Colors.red,
                                onPressed: () {
                                  // Handle lock action
                                  _showActionDialog('Lock Vehicle');
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                title: 'Unlock',
                                icon: Icons.lock_open_outlined,
                                color: Colors.green,
                                onPressed: () {
                                  // Handle unlock action
                                  _showActionDialog('Unlock Vehicle');
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                title: 'Start Engine',
                                icon: Icons.power_settings_new,
                                color: kBlue,
                                onPressed: () {
                                  // Handle start engine action
                                  _showActionDialog('Start Engine');
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Vehicle Management',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildFeatureTile(
                              title: 'Details',
                              subtitle: 'View car information',
                              icon: Icons.info_outline,
                              color: kBlue,
                              onTap: () {
                                // Navigate to car details
                              },
                            ),
                            _buildFeatureTile(
                              title: 'Commands',
                              subtitle: 'Control your vehicle',
                              icon: Icons.settings_remote,
                              color: Colors.orange,
                              onTap: () {
                                // Navigate to commands
                              },
                            ),
                            _buildFeatureTile(
                              title: 'Geo Fence',
                              subtitle: 'Set location boundaries',
                              icon: Icons.location_on_outlined,
                              color: Colors.green,
                              onTap: () {
                                // Navigate to geo fence
                              },
                            ),
                            _buildFeatureTile(
                              title: 'Command History',
                              subtitle: 'View past commands',
                              icon: Icons.history,
                              color: Colors.purple,
                              onTap: () {
                                // Navigate to command history
                              },
                            ),
                            _buildFeatureTile(
                              title: 'Diagnostics',
                              subtitle: 'System health check',
                              icon: Icons.health_and_safety_outlined,
                              color: Colors.red,
                              onTap: () {
                                // Navigate to diagnostics
                              },
                            ),
                            _buildFeatureTile(
                              title: 'Analytics',
                              subtitle: 'Usage statistics',
                              icon: Icons.analytics_outlined,
                              color: Colors.teal,
                              onTap: () {
                                // Navigate to analytics
                              },
                            ),
                          ],
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

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showActionDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Action',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to $action?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Perform the action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$action command sent successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
