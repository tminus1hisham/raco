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
    if (diff.inDays > 0) return "${diff.inDays}d ${diff.inHours % 24}h ";
    if (diff.inHours > 0) return "${diff.inHours}h ${diff.inMinutes % 60}m";
    if (diff.inMinutes > 0) return " ${diff.inMinutes}m";
    return "Just now";
  }

  double _speedValue() {
    return double.tryParse(
          device.speed.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
  }

  String _getStatusText() {
    final speedVal = _speedValue();

    if (!device.isDeviceOnline) {
      DateTime? updated = DateTime.tryParse(device.updatedAt);
      return _formatDuration(updated);
    }

    return "${speedVal.toStringAsFixed(0)}km/h";
  }

  Color _getStatusColor() {
    final speedVal = _speedValue();
    if (speedVal > 80) return kRed;
    if (!device.isDeviceOnline) return kBlue;
    return kSuccessGreen;
  }

  String _vehicleAsset() {
    final speedVal = _speedValue();
    if (speedVal > 80) return 'assets/red_car.png';
    if (!device.isDeviceOnline || !device.certificateActiveStatus) {
      return 'assets/grey_car.png';
    }
    return 'assets/green_car.png';
  }

  bool _isBikeLike() {
    final typeLower = device.type.toLowerCase();
    final deviceTypeLower = device.deviceType.toLowerCase();
    final nameLower = device.name.toLowerCase();
    return typeLower.contains('bike') ||
        typeLower.contains('motorcycle') ||
        typeLower.contains('motorbike') ||
        deviceTypeLower.contains('bike') ||
        deviceTypeLower.contains('motorcycle') ||
        nameLower.contains('bike');
  }

  Widget _getDeviceIcon(BuildContext context) {
    final speedVal = _speedValue();
    final isOverspeeding = speedVal > 80;
    final color = isOverspeeding
        ? kRed
        : (!device.isDeviceOnline ? context.col.textSecondary : kSuccessGreen);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.col.inputFill,
        borderRadius: BorderRadius.circular(kRadiusSM),
      ),
      alignment: Alignment.center,
      child: _isBikeLike()
          ? Icon(Icons.pedal_bike_rounded, color: color, size: 24)
          : Image.asset(
              _vehicleAsset(),
              height: 36,
              width: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.directions_car_rounded,
                color: color,
                size: 24,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (device.numberPlate.isNotEmpty)
        ? device.numberPlate
        : device.name;
    final statusColor = _getStatusColor();

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 18, 6),
            child: Row(
              children: [
                _getDeviceIcon(context),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.col.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_vert_rounded,
                  color: context.col.textSecondary.withValues(alpha: 0.65),
                  size: 18,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: context.col.divider,
            indent: 76,
            endIndent: 22,
          ),
        ],
      ),
    );
  }
}
