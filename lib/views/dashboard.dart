import 'package:atom/config/constants.dart';
import 'package:atom/views/cars_screen.dart';
import 'package:atom/views/history_screen.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

import 'home_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late MotionTabBarController _motionTabBarController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(
      initialIndex: 0,
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _motionTabBarController.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [HomeScreen(), CarsScreen(), HistoryScreen(), SettingsScreen()];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabBarController,
        initialSelectedTab: "Home",
        useSafeArea: true,
        labels: const ["Home", "Car", "Reports", "Settings"],
        icons: const [
          Icons.home,
          Icons.directions_car_rounded,
          Icons.history,
          Icons.settings,
        ],

        // Styling
        tabSize: 50,
        tabBarHeight: 55,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: Colors.grey,
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: kBlue,
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,

        onTabItemSelected: _onTabTapped,
      ),
    );
  }
}
