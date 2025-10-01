import 'package:atom/models/playback_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class ViolationsController extends GetxController {
  var isLoading = false.obs;
  var violations = <DeviceRecord>[].obs;
  var reportUrl = RxnString();

  Future<void> fetchViolations(
    String numberPlate,
    String startDate,
    String endDate,
    String violationType,
  ) async {
    try {
      isLoading(true);
      var result = await ApiService.fetchViolations(
        numberPlate,
        startDate,
        endDate,
        violationType,
      );

      violations.assignAll(result["devices"]);
      reportUrl.value = result["reportUrl"];
    } finally {
      isLoading(false);
    }
  }
}
