import 'package:atom/views/auth/forgot_password_screen.dart';
import 'package:atom/views/auth/login_screen.dart';
import 'package:atom/views/auth/onboarding_screen.dart';
import 'package:atom/views/auth/register_screen.dart';
import 'package:atom/views/cars/car_report.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/views/cars/geofencing_screen.dart';
import 'package:atom/views/dashboard.dart';
import 'package:atom/views/notification_screen.dart';
import 'package:atom/views/settings/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../views/cars/command_history.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgotPassword';
  static const String dashboard = '/dashboard';
  static const String geofencingScreen = 'geofencingScreen';
  static const String notifications = 'notifications';
  static const String account = 'account';
  static const String car_report = 'car_report';
  static const String driver_behaviour = 'driver_behaviour';
  static const String commands = 'commands';
  static const String commandHistory = 'commandHistory';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => WillPopScope(
            onWillPop: () async {
              SystemNavigator.pop();
              return false;
            },
            child: Onboarding(),
          ),
        );
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => Dashboard());
      case geofencingScreen:
        return MaterialPageRoute(builder: (_) => GeofencingScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => NotificationScreen());
      case account:
        return MaterialPageRoute(builder: (_) => AccountScreen());
      case car_report:
        return MaterialPageRoute(builder: (_) => CarReports());
      case driver_behaviour:
        return MaterialPageRoute(builder: (_) => DriverBehaviour());
      case commands:
        return MaterialPageRoute(builder: (_) => Commands());
      case commandHistory:
        return MaterialPageRoute(builder: (_) => CommandHistory());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
