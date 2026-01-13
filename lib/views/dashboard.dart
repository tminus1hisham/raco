import 'package:atom/config/constants.dart';
import 'package:atom/controllers/notifcations_controller.dart';
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
  late NotificationsController _notificationsController =
      Get.find<NotificationsController>();

  // String role = "Technician";

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
    // Wait until role is loaded
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kWhite,
        type: BottomNavigationBarType.fixed,
        iconSize: 25,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: <BottomNavigationBarItem>[
          role != "Technician"
              ? const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                )
              : const BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car),
                  label: 'Create Device',
                ),
          role != "Technician"
              ? BottomNavigationBarItem(
                  icon: Obx(() {
                    // count unread notifications
                    final unreadCount = _notificationsController.notifications
                        .where((n) => n.isRead == false)
                        .length;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications),

                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9
                                      ? '9+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  label: 'Notifications',
                )
              : const BottomNavigationBarItem(
                  icon: Icon(Icons.drive_eta),
                  label: 'Devices',
                ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
