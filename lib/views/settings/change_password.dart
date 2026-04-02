import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/change_password_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/primary_gradient_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:atom/widgets/glass_container.dart';

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
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: Obx(
        () => Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  customHeader(
                    label: "Change Password",
                    icon: Icons.security,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _changePasswordKey,
                        child: _buildPasswordForm(col),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (changePasswordController.isLoading.value)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildPasswordForm(AppColors col) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Lottie.asset(
              'assets/animations/password.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

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

          const SizedBox(height: 8),

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

          const SizedBox(height: 8),

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

          const SizedBox(height: 32),

          PrimaryGradientButton(
            onPressed: _changePassword,
            text: "Update Password",
          ),
          const SizedBox(height: 10),

          CustomBorderButton(
            callBackFunction: () {
              Navigator.pop(context);
            },
            label: "Back",
            borderColor: col.border,
            txtColor: col.textPrimary,
          ),
        ],
      ),
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
