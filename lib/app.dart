import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.generateRoute,
      home: AnimatedSplashScreen(
        splash: Center(
          child: Image.asset(
            "assets/eagle_logo.png",
            width: 500,
            fit: BoxFit.contain,
          ),
        ),
        nextScreen: const _NextScreen(),
        splashTransition: SplashTransition.fadeTransition,
        duration: 2000,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _NextScreen extends StatefulWidget {
  const _NextScreen({super.key});

  @override
  State<_NextScreen> createState() => _NextScreenState();
}

class _NextScreenState extends State<_NextScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingAnimationWidget.fourRotatingDots(color: kBlue, size: 50),
      ),
    );
  }
}
