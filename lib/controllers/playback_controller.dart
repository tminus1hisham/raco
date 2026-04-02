import 'package:atom/models/playback_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/utils/gps_data_cleaner.dart';
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
      final fetched = await ApiService.fetchDeviceHistory(
        numberPlate,
        startDate,
        endDate,
      );

      // Remove GPS noise and impossible jumps before rendering.
      List<dynamic> processed = GpsDataCleaner.cleanGpsData(fetched);

      // Reduce point count for large datasets — Douglas-Peucker at ~8m tolerance.
      // Keeps curves accurate while eliminating redundant collinear points.
      if (processed.length > 400) {
        processed = GpsDataCleaner.simplifyPath(processed, 0.00008);
      }

      history.assignAll(processed.cast<DeviceRecord>());
    } finally {
      isLoading(false);
    }
  }
}
