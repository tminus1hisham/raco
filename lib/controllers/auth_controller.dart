import 'package:atom/models/login_model.dart';
import 'package:atom/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  var phoneNumberOrEmail = ''.obs;
  var email = ''.obs;
  var fullname = ''.obs;
  var phoneNumber = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;

  final AuthService _authService = AuthService();

  void register(BuildContext context) async {
    isLoading.value = true;

    try {
      final registerModel = RegisterModel(
        fullname: fullname.value,
        email: email.value,
        phoneNumber: phoneNumber.value,
        password: password.value,
      );

      final result = await _authService.register(registerModel);

      if (result != null) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      print("failed to register");
    } finally {
      isLoading.value = false;
    }
  }

  void login(BuildContext context) async {
    isLoading.value = true;

    try {
      final loginModel = LoginModel(
        phoneNumberOrEmail: phoneNumberOrEmail.value.trim(),
        password: password.value.trim(),
      );

      final result = await _authService.login(loginModel);

      if (result != null) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      Get.snackbar(
        "Login Failed",
        "Please check your phone/email and password",
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout(BuildContext context) async {
    final success = await _authService.logoutUser();
    if (success) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
