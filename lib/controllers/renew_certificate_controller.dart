import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RenewCertificateController extends GetxController {
  var isLoading = false.obs;
  final ApiService _apiService = ApiService();

  Future<bool> renewCertificate(
    BuildContext context,
    List<String> plateNumbers,
  ) async {
    isLoading.value = true;
    try {
      final result = await _apiService.renewCertificate(plateNumbers);
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
