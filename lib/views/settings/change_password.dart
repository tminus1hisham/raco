import 'package:atom/config/constants.dart';
import 'package:atom/controllers/change_password_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  String phoneNumber = '';
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final ChangePasswordController changePasswordController = Get.put(
    ChangePasswordController(),
  );
  final GlobalKey<FormState> _changePasswordKey = GlobalKey<FormState>();

  void _fetchPhoneNumber() async {
    phoneNumber = await StorageService.getData('phone');
  }

  @override
  void initState() {
    super.initState();
    _fetchPhoneNumber();
  }

  void _changePassword() async {
    if (!_changePasswordKey.currentState!.validate()) {
      return;
    }

    changePasswordController.phoneNumber.value = phoneNumber;
    changePasswordController.currentPassword.value = currentPasswordController
        .text
        .trim();
    changePasswordController.newPassword.value = newPasswordController.text
        .trim();

    bool success = await changePasswordController.changePassword(context);

    if (success) {
      await CustomAlertDialog(
        context: context,
        title: "Success",
        message: "Your have successfully updated your password.",
        icon: "assets/animations/Success.json",
        buttonColor: kSuccessGreen,
      );
    } else {
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message:
            "Failed to update your password, please check your current password.",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(
        () => Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  customHeader(
                    label: "Change Password",
                    icon: Icons.security,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _changePasswordKey,
                        child: _buildPasswordForm(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (changePasswordController.isLoading.value)
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
              return null;
            },
          ),

          SizedBox(height: 8),

          /// Confirm Password
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

          /// Submit
          CustomButton(
            callBackFunction: _changePassword,
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
            borderColor: kLightGrey,
            txtColor: kBlack,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
