import 'package:atom/models/change_password_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class ChangePasswordController extends GetxController {
  var phoneNumber = ''.obs;
  var currentPassword = ''.obs;
  var newPassword = ''.obs;
  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  Future<bool> changePassword(BuildContext context) async {
    isLoading.value = true;
    try {
      final changePasswordModel = ChangePasswordModel(
        phoneNumber: phoneNumber.value.trim(),
        newPassword: currentPassword.value.trim(),
        currentPassword: currentPassword.value.trim(),
      );

      final result = await _authService.changePassword(changePasswordModel);
      return result != null;
    } catch (e) {
      print(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
