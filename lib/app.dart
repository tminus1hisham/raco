import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/services/location_service.dart';
import 'package:atom/services/mqtt_client.dart';
import 'package:atom/views/auth/onboarding_screen.dart';
import 'package:atom/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isAuthenticated;
  Future<void>? _mqttConnect;
  late Future<List<dynamic>> _combinedFuture;

  Future<bool> _checkIfLoggedIn() async {
    bool? isLoggedIn = await StorageService.getData('isLoggedin');
    return isLoggedIn == true;
  }

  @override
  void initState() {
    super.initState();
    LocationService().requestLocationPermission();
    _mqttConnect = MqttService().initializeMqtt();
    _isAuthenticated = _checkIfLoggedIn();
    _combinedFuture = Future.wait([_isAuthenticated, _mqttConnect!]);
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

        final nextScreen = isAuthenticated ? Dashboard() : Onboarding();

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                // statusBarColor: kBlue,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
            ),
          ),
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
