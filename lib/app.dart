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
            useMaterial3: true,
            scaffoldBackgroundColor: kBgGrey,
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: kWhite,
              secondary: kSuccessGreen,
              error: kRed,
              surface: kWhite,
              onSurface: kBlack,
              outline: kLightGrey,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: kBlack),
              headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kBlack),
              titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kBlack),
              titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kBlack),
              bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: kBlack),
              bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kGrey),
              bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: kGrey),
              labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kWhite),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: kBgGrey,
              foregroundColor: kBlack,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: kWhite,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: kWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMD),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: kGrey,
                side: const BorderSide(color: kLightGrey),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMD),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kInputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: const BorderSide(color: kBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintStyle: TextStyle(color: kGrey),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: kWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: kWhite,
              selectedItemColor: kBlue,
              unselectedItemColor: kGrey,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              elevation: 8,
            ),
            dividerTheme: const DividerThemeData(
              color: kDivider,
              thickness: 1,
              space: 0,
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
            backgroundColor: kWhite,
          ),
        );
      },
    );
  }
}
