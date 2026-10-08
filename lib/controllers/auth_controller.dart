import 'package:atom/models/login_model.dart';
import 'package:atom/services/push_notification_service.dart';
import 'package:atom/models/register_model.dart';
import 'package:flutter/foundation.dart';
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
  var adminPhoneNumber = ''.obs;

  /// Last login failure, ready to show to the user. Empty when there is none.
  var loginError = ''.obs;

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
        adminPhoneNumber: adminPhoneNumber.value,
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
    loginError.value = '';

    try {
      final firebaseToken =
          await PushNotificationService.instance.tokenForLogin() ?? '';
      if (kDebugMode) {
        final tokenLogValue = firebaseToken.isEmpty ? '<empty>' : firebaseToken;
        debugPrint('[Auth/login] FCM token: $tokenLogValue');
      }

      if (firebaseToken.isEmpty) {
        loginError.value =
            'Could not connect to push notifications. Please check your connection and try again.';
        debugPrint('[Auth/login] blocked because firebaseToken is empty');
        return false;
      }

      final loginModel = LoginModel(
        phoneNumber: phoneNumber.value.trim(),
        password: password.value.trim(),
        firebaseToken: firebaseToken,
        deviceModel: deviceModel.value.trim(),
        userAgent: userAgent.value.trim(),
        location: location.value.trim(),
        ipAddress: ipAddress.value.trim(),
      );

      // Empty fields are a common cause of a 400 that looks like a wrong
      // password, so name them before the request goes out.
      final missing = <String>[
        if (loginModel.phoneNumber.isEmpty) 'phoneNumber',
        if (loginModel.password.isEmpty) 'password',
        if (loginModel.firebaseToken.isEmpty) 'firebaseToken',
        if (loginModel.deviceModel.isEmpty) 'deviceModel',
        if (loginModel.ipAddress.isEmpty) 'ipAddress',
      ];
      if (missing.isNotEmpty) {
        debugPrint(
          '[Auth/login] empty fields being sent: ${missing.join(', ')}',
        );
      }

      final result = await _authService.login(loginModel);

      if (result != null) {
        Get.offAllNamed(AppRoutes.dashboard);
        return true;
      }

      loginError.value = 'Login failed, please try again.';
      debugPrint('[Auth/login] service returned null without throwing');
      return false;
    } on AuthException catch (e) {
      loginError.value = e.message;
      debugPrint('[Auth/login] FAILED $e');
      return false;
    } catch (e, stack) {
      loginError.value = 'Something went wrong. Please try again.';
      debugPrint('[Auth/login] FAILED with ${e.runtimeType}: $e');
      debugPrint('[Auth/login] stack: $stack');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(int id) async {
    isLoading.value = true;

    try {
      final result = await _authService.deleteUser(id);

      return result;
    } catch (e) {
      debugPrint('Delete user failed: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout(BuildContext context) async {
    final success = await _authService.logoutUser();
    if (success) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.snackbar(
        'Could not sign out',
        'Please check your connection and try again.',
      );
    }
  }
}
