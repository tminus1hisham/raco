import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// import 'path/to/your/input_field.dart'; // Import your InputField widget

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(label: "Change Password", icon: Icons.security),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _buildPasswordForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            child: Lottie.asset(
              'assets/animations/password.json',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24),
          InputField(
            hintText: 'Current Password',
            password: true,
            controller: currentPasswordController,
            prefixIcon: Icons.lock_outline,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Current password is required';
              }
              return null;
            },
          ),

          SizedBox(height: 8),

          InputField(
            hintText: 'New Password',
            password: true,
            controller: newPasswordController,
            prefixIcon: Icons.lock_outline,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'New password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          SizedBox(height: 8),

          InputField(
            hintText: 'Confirm New Password',
            password: true,
            controller: confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          SizedBox(height: 32),

          CustomButton(
            callBackFunction: () {},
            label: "Update Password",
            backgroundColor: kBlue,
            txtColor: kWhite,
          ),
          SizedBox(height: 10),

          CustomBorderButton(
            callBackFunction: () {
              Navigator.pop(context);
            },
            label: "Back",
            borderColor: kGrey,
            txtColor: kBlack,
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    // Handle password change logic here
    print('Current: ${currentPasswordController.text}');
    print('New: ${newPasswordController.text}');
    print('Confirm: ${confirmPasswordController.text}');

    // Add your password change logic here
    // After successful change, you can show a success message or navigate back
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
