import 'package:atom/models/playback_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class FetchGeofenceController extends GetxController {
  var isLoading = false.obs;
  var reports = <DeviceRecord>[].obs;
  var reportUrl = RxnString();

  Future<void> fetchReports(String numberPlate, String reportType) async {
    try {
      isLoading(true);

      var fetchedReports = await ApiService.fetchReports(
        numberPlate,
        reportType,
      );

      reports.assignAll(fetchedReports["devices"]);

      reportUrl.value = fetchedReports["reportUrl"];
    } finally {
      isLoading(false);
    }
  }
}
