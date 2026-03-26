import 'dart:io';

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/notifcations_controller.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/auth_service.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/notification_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:atom/views/technician/devices_screen.dart';
import 'package:atom/views/technician/technician_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String? role;
  late NotificationsController _notificationsController;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<NotificationsController>()) {
      _notificationsController = Get.put(NotificationsController());
    } else {
      _notificationsController = Get.find<NotificationsController>();
    }
    _fetchRole();
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: role == 'Technician'
                    ? Icons.directions_car_outlined
                    : Icons.home_outlined,
                activeIcon: role == 'Technician'
                    ? Icons.directions_car_rounded
                    : Icons.home_rounded,
                label: role == 'Technician' ? 'Create Device' : 'Home',
              ),
              _buildNotificationsNavItem(),
              _buildNavItem(
                index: 2,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBlue.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? kBlue : context.col.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kBlue : context.col.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsNavItem() {
    final bool isSelected = _selectedIndex == 1;
    final IconData icon = role == 'Technician'
        ? Icons.drive_eta_outlined
        : Icons.notifications_outlined;
    final IconData activeIcon = role == 'Technician'
        ? Icons.drive_eta_rounded
        : Icons.notifications_rounded;
    final String label = role == 'Technician' ? 'Devices' : 'Alerts';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBlue.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            role != 'Technician'
                ? Obx(() {
                    final unreadCount = _notificationsController.notifications
                        .where((n) => n.isRead == false)
                        .length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? activeIcon : icon,
                          color: isSelected ? kBlue : context.col.textSecondary,
                          size: 24,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: kRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9
                                      ? '9+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: kWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  })
                : Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? kBlue : context.col.textSecondary,
                    size: 24,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kBlue : context.col.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
