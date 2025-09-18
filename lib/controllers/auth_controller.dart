import 'package:atom/models/login_model.dart';
import 'package:atom/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/routes.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  var emailAddress = ''.obs;
  var fullName = ''.obs;
  var phoneNumber = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  var userFirebaseToken = ''.obs;
  var deviceModel = ''.obs;
  var userAgent = ''.obs;
  var location = ''.obs;
  var ipAddress = ''.obs;
  var userRole = ''.obs;

  final AuthService _authService = AuthService();

  Future<bool> register(BuildContext context) async {
    isLoading.value = true;

    try {
      final registerModel = RegisterModel(
        fullName: fullName.value,
        emailAddress: emailAddress.value,
        phoneNumber: phoneNumber.value,
        password: password.value,
        userFirebaseToken: userFirebaseToken.value,
        userRole: userRole.value,
      );

      final result = await _authService.register(registerModel);

      if (result != null) {
        Get.offAllNamed(AppRoutes.dashboard);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("failed to register: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login(BuildContext context) async {
    isLoading.value = true;

    try {
      final loginModel = LoginModel(
        phoneNumber: phoneNumber.value.trim(),
        password: password.value.trim(),
        firebaseToken: userFirebaseToken.value.trim(),
        deviceModel: deviceModel.value.trim(),
        userAgent: userAgent.value.trim(),
        location: location.value.trim(),
        ipAddress: ipAddress.value.trim(),
      );

      final result = await _authService.login(loginModel);

      if (result != null) {
        Get.offAllNamed(AppRoutes.dashboard);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
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
