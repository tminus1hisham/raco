import 'package:atom/models/location_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeoFenceController extends GetxController {
  var latitude = ''.obs;
  var fullName = ''.obs;
  var longitude = ''.obs;
  var radius = 0.obs;
  var numberPlate = ''.obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  Future<bool> addGeoFence(BuildContext context) async {
    isLoading.value = true;

    try {
      final locationModel = LocationModel(
        latitude: latitude.value.trim(),
        longitude: longitude.value.trim(),
        radius: radius.value,
        name: fullName.value.trim(),
        numberPlate: numberPlate.value.trim(),
      );

      final result = await _apiService.addGeoFence(locationModel);

      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('adding geofence failed: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
