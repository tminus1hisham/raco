import 'package:atom/views/auth/forgot_password_screen.dart';
import 'package:atom/views/auth/login_screen.dart';
import 'package:atom/views/auth/onboarding_screen.dart';
import 'package:atom/views/auth/register_screen.dart';
import 'package:atom/views/auth/reset_password_screen.dart';
import 'package:atom/views/auth/verification_screen.dart';
import 'package:atom/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgotPassword';
  static const String resetPasswordScreen = '/resetPasswordScreen';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(),
        );
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
        return MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen(),
        );
      case resetPasswordScreen:
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(),
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => Dashboard(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
