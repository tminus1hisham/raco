import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final bool isRead;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final visual = _resolveVisual(notification);
    final vehicleCode = _extractVehicleCode(notification);
    final secondaryMeta = _extractSecondaryMeta(notification, visual.kind);
    final cardColor = context.isDark ? col.surface : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: isRead ? 0 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconBlock(visual: visual),
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.12,
                                      color: context.isDark
                                          ? col.textPrimary
                                          : const Color(0xFF15285D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: context.isDark
                                        ? col.textSecondary
                                        : const Color(0xFF51678E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _MetaPill(
                                  label: vehicleCode ?? _sourceFallback(),
                                  backgroundColor: context.isDark
                                      ? visual.softColor.withValues(alpha: 0.18)
                                      : const Color(0xFFE5E9FF),
                                  textColor: context.isDark
                                      ? col.textPrimary
                                      : const Color(0xFF5C6BAA),
                                ),
                                Text(
                                  secondaryMeta,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _detailAccentColor(visual.kind),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: context.isDark
                                    ? col.textSecondary
                                    : const Color(0xFF334A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1661C5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sourceFallback() {
    final source = notification.createdByName.trim();
    if (source.isEmpty) return 'Fleet Ops';

    final words = source.split(RegExp(r'\s+'));
    final compact = words.take(2).join(' ');
    if (compact.length <= 14) return compact;
    return '${compact.substring(0, 14)}...';
  }

  _NotificationVisual _resolveVisual(NotificationModel notification) {
    final haystack = '${notification.title} ${notification.message}'
        .toLowerCase();

    if (haystack.contains('speed') || haystack.contains('overspeed')) {
      return _NotificationVisual(
        kind: _NotificationKind.speed,
        icon: Icons.speed_rounded,
        color: const Color(0xFFC92D2D),
        softColor: const Color(0xFFFFECEC),
      );
    }
    if (haystack.contains('geofence') ||
        haystack.contains('fence') ||
        haystack.contains('zone') ||
        haystack.contains('location')) {
      return _NotificationVisual(
        kind: _NotificationKind.geofence,
        icon: Icons.location_on_rounded,
        color: const Color(0xFF1560C1),
        softColor: const Color(0xFFEAF3FF),
      );
    }
    if (haystack.contains('battery') ||
        haystack.contains('power') ||
        haystack.contains('charging')) {
      return _NotificationVisual(
        kind: _NotificationKind.battery,
        icon: Icons.battery_alert_rounded,
        color: const Color(0xFF0C8D39),
        softColor: const Color(0xFFEAF8EE),
      );
    }
    if (haystack.contains('system') ||
        haystack.contains('maintenance') ||
        haystack.contains('diagnostic') ||
        haystack.contains('check')) {
      return _NotificationVisual(
        kind: _NotificationKind.system,
        icon: Icons.build_rounded,
        color: const Color(0xFF0F6AA8),
        softColor: const Color(0xFFEAF4FB),
      );
    }

    return _NotificationVisual(
      kind: _NotificationKind.alert,
      icon: Icons.notifications_active_rounded,
      color: kBlue,
      softColor: const Color(0xFFEAF3FF),
    );
  }

  String? _extractVehicleCode(NotificationModel notification) {
    final haystack = '${notification.title} ${notification.message}'.toUpperCase();
    final match = RegExp(r'\b[A-Z]{1,4}[-\s]?\d{2,5}\b').firstMatch(haystack);
    if (match == null) return null;
    return match.group(0)?.replaceAll(' ', '-');
  }

  String _extractSecondaryMeta(
    NotificationModel notification,
    _NotificationKind kind,
  ) {
    final haystack = '${notification.title} ${notification.message}';
    final speedMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(km\/h|kmh|kph)',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (speedMatch != null) {
      return '${speedMatch.group(1)} Km/h';
    }

    final batteryMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*%',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (batteryMatch != null) {
      return '${batteryMatch.group(1)}% Remaining';
    }

    if (kind == _NotificationKind.geofence) {
      return _extractLocation(notification.message) ?? 'Zone update';
    }
    if (kind == _NotificationKind.system) {
      return 'Scheduled';
    }
    if (kind == _NotificationKind.speed) {
      return 'Overspeed';
    }
    if (kind == _NotificationKind.battery) {
      return 'Battery status';
    }
    return 'Fleet alert';
  }

  String? _extractLocation(String message) {
    final match = RegExp(
      r'(?:at|in|to)\s+([A-Za-z0-9]+(?:\s+[A-Za-z0-9]+){0,3})',
      caseSensitive: false,
    ).firstMatch(message);

    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'[.,]$'), '');
  }

  Color _detailAccentColor(_NotificationKind kind) {
    switch (kind) {
      case _NotificationKind.speed:
        return const Color(0xFFC92D2D);
      case _NotificationKind.geofence:
      case _NotificationKind.system:
      case _NotificationKind.alert:
        return const Color(0xFF135FBF);
      case _NotificationKind.battery:
        return const Color(0xFFD62828);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final local = timestamp.toLocal();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) return 'NOW';
    if (difference.inMinutes < 60) return '${difference.inMinutes}M AGO';
    if (difference.inHours < 24) return '${difference.inHours}H AGO';
    if (difference.inDays < 7) return '${difference.inDays}D AGO';
    return DateFormat('MMM d').format(local).toUpperCase();
  }
}

enum _NotificationKind { speed, geofence, battery, system, alert }

class _NotificationVisual {
  final _NotificationKind kind;
  final IconData icon;
  final Color color;
  final Color softColor;

  const _NotificationVisual({
    required this.kind,
    required this.icon,
    required this.color,
    required this.softColor,
  });
}

class _IconBlock extends StatelessWidget {
  final _NotificationVisual visual;

  const _IconBlock({required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: visual.softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: visual.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(visual.icon, color: kWhite, size: 14),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _MetaPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
