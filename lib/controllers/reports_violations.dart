import 'package:atom/models/report_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  var isLoading = false.obs;
  var reports = <ReportModel>[].obs;
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
