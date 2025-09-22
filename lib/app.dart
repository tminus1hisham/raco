import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/views/auth/onboarding_screen.dart';
import 'package:atom/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isAuthenticated;

  Future<bool> _checkIfLoggedIn() async {
    bool? isLoggedIn = await StorageService.getData('isLoggedin');
    return isLoggedIn == true;
  }

  @override
  void initState() {
    super.initState();
    _isAuthenticated = _checkIfLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticated,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator(color: kBlue)),
            ),
          );
        }

        final nextScreen = snapshot.data! ? Dashboard() : Onboarding();

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRoutes.generateRoute,
          home: AnimatedSplashScreen(
            splash: Center(
              child: Image.asset(
                "assets/eagle_logo.png",
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            nextScreen: nextScreen,
            splashTransition: SplashTransition.fadeTransition,
            duration: 2000,
            backgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}
