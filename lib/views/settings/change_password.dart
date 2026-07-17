import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/change_password_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/buttons/primary_gradient_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
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
    if (!mounted) return;

    if (success) {
      await CustomAlertDialog(
        context: context,
        title: "Success",
        message: 'Your password has been updated successfully.',
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
                  const SizedBox(height: 8),
                  customHeader(
                    label: "Change Password",
                    icon: Icons.security,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
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
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusLG),
        border: Border.all(color: col.divider),
        boxShadow: context.isDark ? null : [kShadowSM],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kBlue.withValues(
                      alpha: context.isDark ? 0.20 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(kRadiusMD),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: kBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure your account',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Choose a new password that is unique to this account.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: col.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'CURRENT PASSWORD',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: col.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
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

            const SizedBox(height: 12),

            Text(
              'NEW PASSWORD',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: col.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
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
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 6),

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

            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: col.textSecondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Use at least 8 characters with a mix of letters, numbers, and symbols.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: col.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            PrimaryGradientButton(
              onPressed: _changePassword,
              text: 'Update Password',
              icon: Icons.lock_reset_rounded,
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
