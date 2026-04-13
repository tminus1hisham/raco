import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:flutter/material.dart';

class CompactCarListItem extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const CompactCarListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  String _formatDuration(DateTime? lastUpdate) {
    if (lastUpdate == null) return "Offline";
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inDays > 0) return "${diff.inDays}d${diff.inHours % 24}h";
    if (diff.inHours > 0) return "${diff.inHours}h${diff.inMinutes % 60}m";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Just now";
  }

  String _getStatusText() {
    double speedVal = double.tryParse(device.speed.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    if (!device.isDeviceOnline) {
      DateTime? updated = DateTime.tryParse(device.updatedAt);
      return _formatDuration(updated);
    } else if (speedVal > 0) {
      return "${speedVal.toStringAsFixed(0)}km/h";
    } else {
      DateTime? updated = DateTime.tryParse(device.updatedAt);
      String dur = updated != null ? _formatDuration(updated) : "";
      return "Idle - $dur";
    }
  }

  Color _getStatusColor() {
    if (!device.isDeviceOnline) return kBlue; // Offline uses blue in the design
    double speedVal = double.tryParse(device.speed.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (speedVal > 0) return kSuccessGreen; 
    return const Color(0xFFF5B041); // Yellow/amber for idle
  }

  Widget _getDeviceIcon(BuildContext context) {
    final typeLower = device.type.toLowerCase();
    final deviceTypeLower = device.deviceType.toLowerCase();
    
    IconData icon = Icons.directions_car;
    Color iconColor = const Color(0xFFF5B041); // default yellow car
    
    if (typeLower.contains('person') || deviceTypeLower.contains('person') || device.name.toLowerCase().contains('person')) {
      icon = Icons.person;
      iconColor = const Color(0xFF82E0AA);
    } else if (typeLower.contains('asset') || deviceTypeLower.contains('asset') || typeLower.contains('battery')) {
      icon = Icons.battery_full;
      iconColor = const Color(0xFF58D68D);
    } else {
      // Color based on status to roughly mimic screenshot
      if (!device.isDeviceOnline) {
        iconColor = kBlue.withOpacity(0.8);
      } else if (_getStatusColor() == kSuccessGreen) {
        iconColor = kSuccessGreen;
      }
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (device.numberPlate.isNotEmpty) ? device.numberPlate : device.name;
    final statusColor = _getStatusColor();
    
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Row(
              children: [
                _getDeviceIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.col.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.col.border.withOpacity(0.5), indent: 72, endIndent: 20),
        ],
      ),
    );
  }
}
