import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

                // Title
                Text(
                  'Reset Your Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'The password must be different than before',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 80),

                // New password input
                InputField(
                  hintText: 'New password',
                  prefixIcon: Icons.lock_outline,
                  password: true,
                  controller: _newPasswordController,
                  isRequired: true,
                ),

                // Confirm password input
                InputField(
                  hintText: 'Confirm password',
                  prefixIcon: Icons.lock_outline,
                  password: true,
                  controller: _confirmPasswordController,
                  isRequired: true,
                ),

                const SizedBox(height: 30),

                // Continue button
                CustomButton(
                  callBackFunction: () {
                    _handleContinue();
                  },
                  label: 'Continue',
                  backgroundColor: kBlue,
                  txtColor: Colors.white,
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
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    // Handle password reset logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Password reset successfully!')));

    // Navigate back to login
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// Custom painter for the forgot password illustration
class ForgotPasswordIllustration extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw a simple email illustration
    final center = Offset(size.width / 2, size.height / 2);

    // Email envelope
    paint.color = Colors.blue.shade300;
    final emailRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 120, height: 80),
      Radius.circular(8),
    );
    canvas.drawRRect(emailRect, paint);

    // Email flap
    paint.color = kBlue;
    final flap = Path()
      ..moveTo(center.dx - 60, center.dy - 40)
      ..lineTo(center.dx, center.dy - 10)
      ..lineTo(center.dx + 60, center.dy - 40)
      ..close();
    canvas.drawPath(flap, paint);

    // Question mark
    paint.color = Colors.orange;
    canvas.drawCircle(Offset(center.dx + 40, center.dy - 60), 15, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx + 35, center.dy - 70));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
