import 'package:atom/models/profile_picture_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateProfileController extends GetxController {
  var image = ''.obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  Future<bool> changePassword(BuildContext context) async {
    isLoading.value = true;
    try {
      final updateProfileModel = ProfilePictureModel(image: image.value.trim());

      final result = await _apiService.updateProfilePicture(updateProfileModel);
      return result != null;
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile picture");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
