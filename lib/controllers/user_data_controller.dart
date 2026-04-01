import 'package:atom/models/user_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class UserResourceController extends GetxController {
  var user = Rxn<UserModel>();
  var isLoading = false.obs;

  final ApiService _userService = ApiService();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchUserProfile());
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    try {
      final data = await _userService.fetchUserData();

      if (data != null) {
        user.value = UserModel.fromJson(data);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch user data",
        margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
