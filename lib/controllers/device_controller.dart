import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DeviceController extends GetxController {
  var isLoading = true.obs;
  var devicesModel = Rxn<DevicesModel>();

  @override
  void onInit() {
    super.onInit();
    fetchDevices();
  }

  Future<void> fetchDevices({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading(true);
      }
      var fetchedModel = await ApiService.fetchDevices();
      devicesModel.value = fetchedModel;
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (!silent) {
        isLoading(false);
      }
    }
  }
}
