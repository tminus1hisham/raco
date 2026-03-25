import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class Commands extends StatefulWidget {
  final Device device;
  const Commands({super.key, required this.device});

  @override
  State<Commands> createState() => _CommandsState();
}

class _CommandsState extends State<Commands> {
  bool _engineToggling = false;

  Future<void> _toggleEngine(bool turnOn) async {
    if (_engineToggling) return;
    setState(() => _engineToggling = true);
    try {
      final success = await ApiService.sendEngineCommand(
        widget.device.numberPlate,
        turnOn,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Engine ${turnOn ? 'started' : 'stopped'} successfully'
                  : 'Failed to ${turnOn ? 'start' : 'stop'} engine. Try again.',
            ),
            backgroundColor: success ? kSuccessGreen : kRed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _engineToggling = false);
    }
  }

  void _showSosInfo(AppColors col) {
    final phone = widget.device.phone.isNotEmpty ? widget.device.phone : 'Not set';
    showModalBottomSheet(
      context: context,
      backgroundColor: col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOS Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: col.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Emergency contact linked to ${widget.device.numberPlate}:',
              style: TextStyle(fontSize: 13, color: col.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone, color: kRed, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: col.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetMileageDialog(AppColors col) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: col.surface,
        title: Text(
          'Set Mileage',
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: col.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter mileage (km)',
            hintStyle: TextStyle(color: col.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: col.border),
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: kBlue),
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: col.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mileage set to ${controller.text} km for ${widget.device.numberPlate}',
                  ),
                  backgroundColor: kBlue,
                ),
              );
            },
            child: const Text('Set', style: TextStyle(color: kBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isEngineOn = widget.device.ignitionStatus == 1;
    final engineColor = isEngineOn ? kRed : kSuccessGreen;

    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: widget.device.numberPlate,
              icon: Icons.directions_car,
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _buildSectionHeader(col: col, title: 'Commands', icon: Icons.tune_rounded, color: kBlue),
                  _buildCard(
                    col: col,
                    children: [
                      _buildCommandItem(
                        col: col,
                        icon: Icons.my_location_rounded,
                        iconColor: Colors.orange,
                        title: 'Check Location',
                        subtitle: "View the vehicle's current GPS position.",
                        onTap: () {
                          final lat = double.tryParse(widget.device.latitude) ?? 0.0;
                          final lng = double.tryParse(widget.device.longitude) ?? 0.0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleLocationScreen(
                                latitude: lat,
                                longitude: lng,
                                deviceId: widget.device.deviceId,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(col),
                      _buildCommandItem(
                        col: col,
                        icon: Icons.power_settings_new_rounded,
                        iconColor: engineColor,
                        title: isEngineOn ? 'Stop Engine' : 'Start Engine',
                        subtitle: isEngineOn
                            ? "Remotely shut down the vehicle's engine."
                            : "Remotely start the vehicle's engine.",
                        trailing: _engineToggling
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: engineColor),
                              )
                            : null,
                        onTap: () => _toggleEngine(!isEngineOn),
                      ),
                      _buildDivider(col),
                      _buildCommandItem(
                        col: col,
                        icon: Icons.sos_rounded,
                        iconColor: kRed,
                        title: 'SOS Number',
                        subtitle: "View the emergency contact for this vehicle.",
                        onTap: () => _showSosInfo(col),
                      ),
                      _buildDivider(col),
                      _buildCommandItem(
                        col: col,
                        icon: Icons.speed_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Set Mileage',
                        subtitle: "Input or adjust the vehicle odometer reading.",
                        onTap: () => _showSetMileageDialog(col),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required AppColors col,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required AppColors col, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildCommandItem({
    required AppColors col,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: col.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: col.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? Icon(
              Icons.chevron_right_rounded,
              color: iconColor.withValues(alpha: 0.45),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors col) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 74),
      color: col.divider,
    );
  }
}
