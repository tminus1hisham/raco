import 'package:atom/models/forgot_password_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class ForgotPasswordService extends GetxController {
  var phoneNumber = ''.obs;
  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  Future<bool> forgotPassword(BuildContext context) async {
    isLoading.value = true;
    try {
      final forgotPasswordModel = ForgotPasswordModel(
        phoneNumber: phoneNumber.value.trim(),
      );

      final result = await _authService.forgotPassword(forgotPasswordModel);
      return result != null;
    } catch (e) {
      debugPrint("Failed to send OTP: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
