import 'package:atom/views/splash_screen.dart';
import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/theme_controller.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/services/location_service.dart';
import 'package:atom/services/mqtt_client.dart';
import 'package:atom/views/auth/onboarding_screen.dart';
import 'package:atom/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<dynamic>> _combinedFuture;

  Future<bool> _checkIfLoggedIn() async {
    bool? isLoggedIn = await StorageService.getData('isLoggedin');
    return isLoggedIn == true;
  }

  @override
  void initState() {
    super.initState();
    LocationService().requestLocationPermission();
    final mqttConnect = MqttService().initializeMqtt();
    _combinedFuture = Future.wait([
      _checkIfLoggedIn(),
      mqttConnect,
      StorageService.getThemeMode(), // load persisted theme before first render
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _combinedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: kBlue,
                  size: 50,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text("Error: ${snapshot.error}")),
            ),
          );
        }

        final bool isAuthenticated = snapshot.data![0] as bool;
        final String? savedThemeStr = snapshot.data![2] as String?;
        final ThemeMode initialThemeMode = ThemeController.modeFromString(
          savedThemeStr,
        );

        // Register ThemeController with the loaded mode so the settings
        // screen shows the correct selection immediately (no flash).
        if (!Get.isRegistered<ThemeController>()) {
          Get.put(ThemeController(initialMode: initialThemeMode));
        }

        final nextScreen = isAuthenticated ? const Dashboard() : Onboarding();

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: initialThemeMode,
          onGenerateRoute: AppRoutes.generateRoute,
          home: RadarSplashScreen(
            nextScreen: nextScreen,
            themeMode: initialThemeMode,
          ),
        );
      },
    );
  }
}
