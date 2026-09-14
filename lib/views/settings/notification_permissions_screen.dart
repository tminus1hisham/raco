import 'package:atom/config/profile_palette.dart';
import 'package:atom/models/notification_permission.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/services/push_notification_service.dart';
import 'package:atom/widgets/profile/profile_widgets.dart';
import 'package:flutter/material.dart';

class NotificationPermissionsScreen extends StatefulWidget {
  const NotificationPermissionsScreen({
    super.key,
    this.apiService,
    this.enablePush,
  });

  final ApiService? apiService;
  final Future<void> Function()? enablePush;

  @override
  State<NotificationPermissionsScreen> createState() =>
      _NotificationPermissionsScreenState();
}

class _NotificationPermissionsScreenState
    extends State<NotificationPermissionsScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  Map<NotificationPermission, bool>? _permissions;
  final Set<NotificationPermission> _saving = {};
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final permissions = await _api.fetchNotificationPermissions();
      if (mounted) setState(() => _permissions = permissions);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(NotificationPermission permission, bool enabled) async {
    if (_saving.contains(permission)) return;
    final previous = _permissions![permission]!;
    setState(() {
      _permissions![permission] = enabled;
      _saving.add(permission);
    });
    try {
      if (enabled) {
        await (widget.enablePush ??
            PushNotificationService.instance.enableNotifications)();
      }
      await _api.updateNotificationPermission(permission, enabled);
    } catch (error) {
      if (!mounted) return;
      setState(() => _permissions![permission] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is PushNotificationException
                ? error.message
                : 'Could not save ${permission.title.toLowerCase()} alerts. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving.remove(permission));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.headline,
        title: const Text('Notification Permissions'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: palette.accent))
          : _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load your notification settings.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 48,
                  color: palette.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your alerts, your choice',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: palette.headline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the vehicle alerts you want to receive. Changes save automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.supporting),
                ),
                const SizedBox(height: 28),
                const ProfileSectionLabel('Vehicle alerts'),
                const SizedBox(height: 12),
                ProfileGroupCard(
                  children: [
                    for (final permission in NotificationPermission.values)
                      SwitchListTile.adaptive(
                        key: ValueKey(permission),
                        activeTrackColor: palette.accent,
                        title: Text(
                          permission.title,
                          style: TextStyle(color: palette.headline),
                        ),
                        subtitle: Text(
                          _saving.contains(permission)
                              ? 'Saving…'
                              : permission.description,
                          style: TextStyle(color: palette.supporting),
                        ),
                        value: _permissions![permission]!,
                        onChanged: _saving.isNotEmpty
                            ? null
                            : (value) => _update(permission, value),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
