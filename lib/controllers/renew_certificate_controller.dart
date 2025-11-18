import 'package:atom/models/plans_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RenewCertificateController extends GetxController {
  var isLoading = false.obs;
  var plans = <PlanModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<bool> renewCertificate(
    BuildContext context,
    String numberPlate,
    String phoneNumber,
    int amount,
  ) async {
    isLoading.value = true;

    try {
      final result = await ApiService.makePayment(
        numberPlate,
        phoneNumber,
        amount,
      );

      return result != null;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;

      final fetchedPlans = await ApiService.fetchPlans();
      plans.assignAll(fetchedPlans);
    } catch (e) {
      print("Error fetching plans: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
