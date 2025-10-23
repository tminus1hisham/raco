import 'package:atom/models/geofence_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class FetchGeofenceController extends GetxController {
  var isLoading = false.obs;
  var geofences = <GeofenceModel>[].obs;

  Future<void> fetchGeofence(String numberPlate) async {
    try {
      isLoading(true);

      final fetchedGeofences = await ApiService.fetchGeoFence(numberPlate);
      geofences.assignAll(fetchedGeofences);
    } catch (e) {
      print("Error fetching geofences: $e");
    } finally {
      isLoading(false);
    }
  }
}
