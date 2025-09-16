import 'package:atom/models/reset_password_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class ResetPasswordService extends GetxController {
  var phoneNumber = ''.obs;
  var newPassword = ''.obs;
  var resetToken = ''.obs;
  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  Future<bool> resetPassword(BuildContext context) async {
    isLoading.value = true;
    try {
      final resetPasswordModel = ResetPasswordModel(
        phoneNumber: phoneNumber.value.trim(),
        newPassword: newPassword.value.trim(),
        resetToken: resetToken.value.trim(),
      );

      final result = await _authService.resetPassword(resetPasswordModel);
      return result != null;
    } catch (e) {
      debugPrint("Failed to send OTP: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
