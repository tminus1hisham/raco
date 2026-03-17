import 'package:atom/models/user_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class UserResourceController extends GetxController {
  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final data = await ApiService.fetchUsers();
      users.assignAll(data);
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createUser(RegisterModel request) async {
    try {
      isLoading.value = true;
      var response = await ApiService.addUser(request);

      if (response) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch users");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
