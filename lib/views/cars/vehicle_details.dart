import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class VehicleDetails extends StatefulWidget {
  final String vehiclePlate;
  final Device device;

  VehicleDetails({required this.vehiclePlate, required this.device});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  final _utils = Utils();

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            customHeader(
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
              label: widget.vehiclePlate,
              icon: Icons.directions_car,
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  _buildSectionHeader("Vehicle Details", col),
                  _buildVehicleCard(
                    col: col,
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          col: col,
                          title: 'Make',
                          subtitle: widget.device.make,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Registration Number',
                          subtitle: widget.device.numberPlate,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Make',
                          subtitle: widget.device.make,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionHeader("Ownership & Contact", col),
                  _buildVehicleCard(
                    col: col,
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          col: col,
                          title: 'Owner ID',
                          subtitle: widget.device.ownerId,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Phone',
                          subtitle: widget.device.phone,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Email',
                          subtitle: widget.device.email,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Business Reg',
                          subtitle: widget.device.businessReg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionHeader("Certificate & Compliance", col),
                  _buildVehicleCard(
                    col: col,
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          col: col,
                          title: 'Certificate Number',
                          subtitle: widget.device.certNo,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Certificate URL',
                          subtitle: widget.device.certificateUrl,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Certificate Status',
                          subtitle: widget.device.certificateActiveStatus
                              ? "Active"
                              : "Inactive",
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Certificate Expiry',
                          subtitle: _utils.formatDate(
                            widget.device.certificateExpirey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionHeader("Installation & Device", col),
                  _buildVehicleCard(
                    col: col,
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          col: col,
                          title: 'Technician Name',
                          subtitle: widget.device.technicianName,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Device Type',
                          subtitle: widget.device.deviceType,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Device Status',
                          subtitle: widget.device.isDeviceOnline
                              ? "Online"
                              : "Offline",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSectionHeader("Agent & Details", col),
                  _buildVehicleCard(
                    col: col,
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          col: col,
                          title: 'Agent',
                          subtitle: widget.device.agent,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Agent ID',
                          subtitle: widget.device.agentID,
                        ),
                        _buildDivider(col),
                        _buildVehicleItem(
                          col: col,
                          title: 'Agent Phone',
                          subtitle: widget.device.agentPhone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
      {required AppColors col, required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: child,
      ),
    );
  }

  Widget _buildVehicleItem(
      {required AppColors col,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: col.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtitle,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 14,
                color: col.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildDivider(AppColors col) {
    return Container(height: 1, color: col.divider);
  }
}
