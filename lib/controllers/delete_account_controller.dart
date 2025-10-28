import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/delete_account_model.dart';

class DeleteAccountController extends GetxController {
  var fullname = ''.obs;
  var phoneNumber = ''.obs;
  var reason = ''.obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  Future<bool> requestDeleteAccount(BuildContext context) async {
    isLoading.value = true;

    try {
      final deleteAccountModel = DeleteAccountModel(
        fullname: fullname.value.trim(),
        phoneNumber: phoneNumber.value.trim(),
        reason: reason.value,
      );

      final result = await _apiService.requestDeleteAccount(deleteAccountModel);

      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('account deletion failed: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
