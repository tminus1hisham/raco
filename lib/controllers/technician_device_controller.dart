import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class TechnicianDeviceController extends GetxController {
  var isLoading = true.obs;
  var devicesModel = Rxn<DevicesModel>();

  @override
  void onInit() {
    super.onInit();
    fetchTechnicianDevices();
  }

  Future<void> fetchTechnicianDevices({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading(true);
      }
      var fetchedModel = await ApiService.fetchTechnicianDevices();
      devicesModel.value = fetchedModel;
    } finally {
      if (!silent) {
        isLoading(false);
      }
    }
  }
}
