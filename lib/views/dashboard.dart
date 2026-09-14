import 'dart:io';

import 'package:atom/controllers/dashboard_controller.dart';

import 'package:atom/controllers/notifcations_controller.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/auth_service.dart';
import 'package:atom/services/push_notification_service.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/notification_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:atom/views/technician/devices_screen.dart';
import 'package:atom/views/technician/technician_home_screen.dart';
import 'package:atom/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  String? role;
  late final DashboardController _dashboardController = Get.put(
    DashboardController(),
  );
  late NotificationsController _notificationsController;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PushNotificationService.instance.dashboardReady();
    });
    if (!Get.isRegistered<NotificationsController>()) {
      _notificationsController = Get.put(NotificationsController());
    } else {
      _notificationsController = Get.find<NotificationsController>();
    }
    _fetchRole();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushNotificationService.instance.syncToken();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushNotificationService.instance.dashboardClosed();
    super.dispose();
  }

  Future<void> _fetchRole() async {
    final fetchedRole = await StorageService.getData('userRole');

    if (fetchedRole == 'Technician' && Platform.isIOS) {
      await AuthService().logoutUser();
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Not Available'),
            content: const Text(
              'This feature is not available for Apple devices.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    setState(() {
      role = fetchedRole;
      _screens = [
        role == 'Technician' ? TechnicianHomeScreen() : HomeScreen(),
        role == 'Technician' ? DevicesScreen() : NotificationScreen(),
        SettingsScreen(),
      ];
    });
  }

  void _onItemTapped(int index) {
    _dashboardController.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: _dashboardController.selectedIndex.value,
          children: _screens,
        ),
        bottomNavigationBar: _dashboardController.isNavVisible.value
            ? _buildBottomNav()
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBottomNav() {
    final bool isTechnician = role == 'Technician';

    // Nested Obx so an unread-count change repaints only the bar, not the
    // IndexedStack that the outer Obx wraps.
    return Obx(() {
      final unreadCount = isTechnician
          ? 0
          : _notificationsController.notifications
                .where((n) => n.isRead == false)
                .length;

      return FloatingNavBar(
        selectedIndex: _dashboardController.selectedIndex.value,
        onTap: _onItemTapped,
        items: [
          NavBarItemData(
            icon: isTechnician
                ? Icons.directions_car_outlined
                : Icons.home_outlined,
            activeIcon: isTechnician
                ? Icons.directions_car_rounded
                : Icons.home_rounded,
            label: isTechnician ? 'Create Device' : 'Home',
          ),
          NavBarItemData(
            icon: isTechnician
                ? Icons.drive_eta_outlined
                : Icons.notifications_outlined,
            activeIcon: isTechnician
                ? Icons.drive_eta_rounded
                : Icons.notifications_rounded,
            label: isTechnician ? 'Devices' : 'Alerts',
            badgeCount: unreadCount,
          ),
          const NavBarItemData(
            icon: Icons.person_2_outlined,
            activeIcon: Icons.person_2,
            label: 'Profile',
          ),
        ],
      );
    });
  }
}
