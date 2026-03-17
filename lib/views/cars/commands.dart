import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class Commands extends StatefulWidget {
  const Commands({super.key});

  @override
  State<Commands> createState() => _CommandsState();
}

class _CommandsState extends State<Commands> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            customHeader(
              label: "KDA 001A",
              icon: Icons.directions_car,
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10),
            _buildSectionHeader("Commands"),
            _buildSettingsCard(
              child: Column(
                children: [
                  _buildCommandItem(
                    title: 'Check location',
                    subtitle: "View the current's vehicle GPS position.",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildCommandItem(
                    title: 'Stop Engine',
                    subtitle: "remotely shut down the vehicle's engine",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildCommandItem(
                    title: 'SOS number',
                    subtitle: "remotely shut down the vehicle's engine",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildCommandItem(
                    title: 'Set Milage',
                    subtitle: "Input or adjust the vehicle reading",
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMD),
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      color: textColor ?? kBlack,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: kGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kLightGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: kDivider);
  }
}
