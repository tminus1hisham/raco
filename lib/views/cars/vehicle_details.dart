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
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
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
                  SizedBox(height: 10),
                  _buildSectionHeader("Vehicle Details"),
                  _buildVehicleCard(
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          title: 'Make',
                          subtitle: widget.device.make,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Registration Number',
                          subtitle: widget.device.numberPlate,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Make',
                          subtitle: widget.device.make,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSectionHeader("Ownership & Contact"),
                  _buildVehicleCard(
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          title: 'Owner ID',
                          subtitle: widget.device.ownerId,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Phone',
                          subtitle: widget.device.phone,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Email',
                          subtitle: widget.device.email,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Business Reg',
                          subtitle: widget.device.businessReg,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSectionHeader("Certificate & Compliance"),
                  _buildVehicleCard(
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          title: 'Certificate Number',
                          subtitle: widget.device.certNo,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Certificate URL',
                          subtitle: widget.device.certificateUrl,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Certificate Status',
                          subtitle: widget.device.certificateActiveStatus
                              ? "Active"
                              : "Inactive",
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Certificate Expiry',
                          subtitle: _utils.formatDate(
                            widget.device.certificateExpirey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSectionHeader("Installation & Device"),
                  _buildVehicleCard(
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          title: 'Technician Name',
                          subtitle: widget.device.technicianName,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Device Type',
                          subtitle: widget.device.deviceType,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Device Status',
                          subtitle: widget.device.isDeviceOnline
                              ? "Online"
                              : "Offline",
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSectionHeader("Agent & Details"),
                  _buildVehicleCard(
                    child: Column(
                      children: [
                        _buildVehicleItem(
                          title: 'Agent',
                          subtitle: widget.device.agent,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Agent ID',
                          subtitle: widget.device.agentID,
                        ),
                        _buildDivider(),
                        _buildVehicleItem(
                          title: 'Agent Phone',
                          subtitle: widget.device.agentPhone,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
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
        child: child,
      ),
    );
  }

  Widget _buildVehicleItem({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 👈 aligns text to top
        children: [
          // Title text
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(width: 10), // space between title and subtitle
          // Subtitle text (wrapping allowed)
          Expanded(
            child: Text(
              subtitle,
              textAlign: TextAlign.right, // aligns long text neatly
              softWrap: true, // 👈 allows wrapping to next line
              overflow: TextOverflow.visible, // shows full text
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey.shade100);
  }
}
