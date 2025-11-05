import 'package:atom/config/constants.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/notification_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:atom/views/technician/create_device.dart';
import 'package:atom/views/technician/devices_screen.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  String? role;

  // String role = "Technician";

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final fetchedRole = await StorageService.getData('userRole');
    setState(() {
      role = fetchedRole;
      _screens = [
        role == 'SuperAdmin' ? HomeScreen() : TechnicianScreen(),
        role == 'SuperAdmin' ? NotificationScreen() : DevicesScreen(),
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
          role == "SuperAdmin"
              ? const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                )
              : const BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car),
                  label: 'Create Device',
                ),
          role == "SuperAdmin"
              ? const BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
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
