import 'package:atom/config/constants.dart';
import 'package:atom/views/auth/verification_screen.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo
                Center(
                  child: Hero(
                    tag: "logo",
                    child: Image(
                      image: AssetImage('assets/eagle_logo.png'),
                      height: 80,
                      width: 100,
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
                  'Enter your email account to reset password',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                Container(
                  height: 250,
                  width: double.infinity,
                  child: Lottie.asset(
                    'assets/animations/Email.json',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 60),

                // Email input
                InputField(
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  isRequired: true,
                ),

                const SizedBox(height: 40),

                CustomButton(
                  callBackFunction: () {
                    _handleContinue();
                  },
                  label: 'Continue',
                  backgroundColor: kBlue,
                  txtColor: kWhite,
                ),

                const SizedBox(height: 10),

                CustomBorderButton(
                  callBackFunction: () {
                    Navigator.pop(context);
                  },
                  label: "Cancel",
                  borderColor: Colors.grey.shade400,
                  txtColor: kBlack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VerificationCodeScreen(email: _emailController.text),
      ),
    );
    // if (_emailController.text.isNotEmpty) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => VerificationCodeScreen(
    //         email: _emailController.text,
    //       ),
    //     ),
    //   );
    // }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
