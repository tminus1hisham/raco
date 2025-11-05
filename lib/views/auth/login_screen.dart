import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/settings/privacy_policy.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String userIp = '';
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _auth = LocalAuthentication();

  final utils = Utils();
  bool isAvailable = false;

  final AuthController authController = Get.put(AuthController());
  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();

  void checkBiometrics() async {
    bool canCheck = await _auth.canCheckBiometrics;
    bool isSupported = await _auth.isDeviceSupported();
    List<BiometricType> availableBiometrics = await _auth
        .getAvailableBiometrics();

    setState(() {
      isAvailable = canCheck && isSupported && availableBiometrics.isNotEmpty;
    });
  }

  void fetchIp() async {
    final ip = await utils.getLocalIpAddress();
    if (ip != null) {
      setState(() {
        userIp = ip;
      });
    }
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) {
      return;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();

    String brand = "Unknown";
    String model = "Unknown";

    try {
      if (Platform.isAndroid) {
        // Android device
        final androidInfo = await deviceInfoPlugin.androidInfo;
        brand = androidInfo.brand ?? "Android";
        model = androidInfo.model ?? "Unknown Android Device";
      } else if (Platform.isIOS) {
        // iPhone or iPad
        final iosInfo = await deviceInfoPlugin.iosInfo;
        brand = "Apple";
        model = iosInfo.utsname.machine ?? "iPhone";
      }
    } catch (e) {
      print("Error getting device info: $e");
    }

    authController.phoneNumber.value = utils.normalizePhoneNumber(
      _phoneNumberController.text,
    );
    authController.password.value = _passwordController.text;
    authController.deviceModel.value = brand;
    authController.userAgent.value = model;
    authController.ipAddress.value = userIp;
    authController.location.value = 'Nairobi';

    bool success = await authController.login(context);

    if (!success) {
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to login, please check your credentials",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }
  }

  // Future<void> _login() async {
  //   if (!_loginKey.currentState!.validate()) {
  //     return;
  //   }
  //
  //   String? brand;
  //   String? model;
  //
  //   final deviceInfoPlugin = DeviceInfoPlugin();
  //
  //   try {
  //     final androidInfo = await deviceInfoPlugin.androidInfo;
  //     brand = androidInfo.brand ?? "Unknown";
  //     model = androidInfo.model ?? "Unknown";
  //   } catch (e) {
  //     brand = "Iphone";
  //     model = "Iphone";
  //   }
  //
  //   final androidInfo = await deviceInfoPlugin.androidInfo;
  //
  //   authController.phoneNumber.value = utils.normalizePhoneNumber(
  //     _phoneNumberController.text,
  //   );
  //   authController.password.value = _passwordController.text;
  //   authController.deviceModel.value = brand;
  //   authController.userAgent.value = model;
  //   authController.ipAddress.value = userIp;
  //   authController.location.value = 'Nairobi';
  //
  //   bool success = await authController.login(context);
  //
  //   if (!success) {
  //     await CustomAlertDialog(
  //       context: context,
  //       title: "Error",
  //       message: "Failed to login, please check your credentials",
  //       icon: "assets/animations/Failed.json",
  //       buttonColor: kRed,
  //     );
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchIp();
    checkBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Logo
                      Center(
                        child: Hero(
                          tag: "logo",
                          child: Image(
                            image: AssetImage('assets/eagle_logo.png'),
                            height: 180,
                            width: 180,
                          ),
                        ),
                      ),

                      Text(
                        'Welcome to Eagles Eye',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign up or login below to be able to\ntrack your vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      _buildLoginForm(),
                    ],
                  ),
                ),
              ),
            ),
            if (authController.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: kBlue,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputField(
            hintText: 'Phone number',
            prefixIcon: Icons.phone,
            controller: _phoneNumberController,
            isRequired: true,
            integerOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "This filed is required";
              }
              return null;
            },
          ),

          InputField(
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            password: true,
            controller: _passwordController,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "This field is required";
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Forgot password
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.forgotPassword);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: kBlue, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  callBackFunction: _login,
                  label: "Login",
                  backgroundColor: kBlue,
                  txtColor: kWhite,
                ),
              ),
              // if (isAvailable) ...[
              //   SizedBox(width: 10),
              //   Icon(Icons.fingerprint_outlined, color: kBlue, size: 40),
              // ],
            ],
          ),

          SizedBox(height: 20),
          // Terms text
          Text.rich(
            TextSpan(
              text: 'By signing up, you agree to our ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              children: [
                TextSpan(
                  text: 'Terms of service',
                  style: TextStyle(
                    color: kBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: kBlue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: navigate to Terms of Service screen
                    },
                ),
                const TextSpan(text: '\nand '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: kBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: kBlue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicy(),
                        ),
                      );
                    },
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
