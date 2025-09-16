import 'package:atom/config/constants.dart';
import 'package:atom/controllers/forgot_password_controller.dart';
import 'package:atom/views/auth/verification_screen.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final ForgotPasswordService forgotPasswordService = Get.put(
    ForgotPasswordService(),
  );

  void _handleContinue() async {
    if (_phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Phone number is required")));
      return;
    }

    forgotPasswordService.phoneNumber.value = _phoneNumberController.text;

    final success = await forgotPasswordService.forgotPassword(context);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VerificationCodeScreen(phoneNumber: _phoneNumberController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send OTP, try again.")));
    }
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Hero(
                        tag: "logo",
                        child: Image.asset(
                          'assets/eagle_logo.png',
                          height: 180,
                          width: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to reset password',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Lottie.asset(
                      'assets/animations/chat.json',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    InputField(
                      hintText: 'Phone number',
                      prefixIcon: Icons.phone,
                      controller: _phoneNumberController,
                      isRequired: true,
                    ),
                    const SizedBox(height: 40),
                    CustomButton(
                      callBackFunction: _handleContinue,
                      label: 'Continue',
                      backgroundColor: kBlue,
                      txtColor: kWhite,
                    ),
                    const SizedBox(height: 10),
                    CustomBorderButton(
                      callBackFunction: () => Navigator.pop(context),
                      label: "Cancel",
                      borderColor: Colors.grey.shade400,
                      txtColor: kBlack,
                    ),
                  ],
                ),
              ),
            ),

            if (forgotPasswordService.isLoading.value)
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
}
