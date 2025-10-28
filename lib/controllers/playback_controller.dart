import 'package:atom/models/playback_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class PlaybackController extends GetxController {
  var isLoading = false.obs;
  var history = <DeviceRecord>[].obs;

  Future<void> fetchHistory(
    String numberPlate,
    String startDate,
    String endDate,
  ) async {
    try {
      isLoading(true);
      var fetchedHistory = await ApiService.fetchDeviceHistory(
        numberPlate,
        startDate,
        endDate,
      );
      history.assignAll(fetchedHistory);
    } finally {
      isLoading(false);
    }
  }
}
