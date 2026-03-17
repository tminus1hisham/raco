import 'package:atom/config/constants.dart';
import 'package:atom/models/notifications_model.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final bool isRead;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    required this.isRead,
  }) : super(key: key);

  _NotificationMeta _resolveMeta(String title) {
    final t = title.toLowerCase();
    if (t.contains('speed') || t.contains('overspeed')) {
      return _NotificationMeta(Icons.speed_rounded, const Color(0xFFF97316));
    }
    if (t.contains('geofence') || t.contains('fence')) {
      return _NotificationMeta(Icons.my_location_rounded, kBlue);
    }
    if (t.contains('engine') || t.contains('ignition')) {
      return _NotificationMeta(
          Icons.power_settings_new_rounded, const Color(0xFF10B981));
    }
    if (t.contains('alert') ||
        t.contains('warning') ||
        t.contains('violation')) {
      return _NotificationMeta(
          Icons.warning_amber_rounded, const Color(0xFFEF4444));
    }
    return _NotificationMeta(Icons.notifications_rounded, kBlue);
  }

  @override
  Widget build(BuildContext context) {
    final meta = _resolveMeta(notification.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? kWhite : kBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(kRadiusMD),
        border: Border(
          left: BorderSide(
            color: isRead ? Colors.transparent : meta.color,
            width: 3,
          ),
        ),
        boxShadow: [kShadowSM],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMD),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: isRead ? 0.08 : 0.14),
                    borderRadius: BorderRadius.circular(kRadiusSM),
                  ),
                  child: Icon(
                    meta.icon,
                    color: meta.color.withValues(alpha: isRead ? 0.6 : 1.0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: kBlack,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isRead ? kLightGrey : kGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? kGrey : kBlack.withValues(alpha: 0.65),
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isRead) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(kRadiusPill),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: meta.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final local = timestamp.toLocal();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _NotificationMeta {
  final IconData icon;
  final Color color;
  const _NotificationMeta(this.icon, this.color);
}
