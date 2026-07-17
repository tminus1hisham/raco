import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MarkasreadController extends GetxController {
  var isLoading = false.obs;
  final ApiService _apiService = ApiService();

  Future<bool> markAsRead(
    BuildContext context,
    List<int> notifications,
  ) async {
    isLoading.value = true;
    try {
      final result = await _apiService.markAllNotificationsAsRead(
        notifications,
      );
      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
