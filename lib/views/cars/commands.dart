import 'package:atom/config/app_theme.dart';
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
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
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
            _buildSectionHeader("Commands", col),
            _buildSettingsCard(
              col: col,
              child: Column(
                children: [
                  _buildCommandItem(
                    col: col,
                    title: 'Check location',
                    subtitle: "View the current's vehicle GPS position.",
                    onTap: () {},
                  ),
                  _buildDivider(col),
                  _buildCommandItem(
                    col: col,
                    title: 'Stop Engine',
                    subtitle: "remotely shut down the vehicle's engine",
                    onTap: () {},
                  ),
                  _buildDivider(col),
                  _buildCommandItem(
                    col: col,
                    title: 'SOS number',
                    subtitle: "remotely shut down the vehicle's engine",
                    onTap: () {},
                  ),
                  _buildDivider(col),
                  _buildCommandItem(
                    col: col,
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

  Widget _buildSectionHeader(String title, AppColors col) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: col.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
      {required AppColors col,
      required Widget child,
      VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
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
    required AppColors col,
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
                      color: textColor ?? col.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: col.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: col.border, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors col) {
    return Container(height: 1, color: col.divider);
  }
}
