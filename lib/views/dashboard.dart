import 'package:atom/config/constants.dart';
import 'package:atom/views/notification_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:atom/views/technician/create_device.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  String role = "Admin";

  // String role = "Technician";
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      role == 'Admin' ? HomeScreen() : TechnicianScreen(),
      NotificationScreen(),
      SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kWhite,
        type: BottomNavigationBarType.fixed,
        iconSize: 25,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: <BottomNavigationBarItem>[
          role == "Admin"
              ? BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home')
              : BottomNavigationBarItem(
                  icon: Icon(Icons.directions_car),
                  label: 'Add Device',
                ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.directions_car_rounded),
          //   label: 'Vehicles',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
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
