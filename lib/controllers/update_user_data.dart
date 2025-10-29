import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class UpdateUserDataController extends GetxController {
  var isLoading = false.obs;
  var reportUrl = RxnString();

  Future<void> updateProfile(
    String userId,
    String email,
    String fullName,
  ) async {
    try {
      isLoading(true);
      await ApiService.updateProfile(userId, email, fullName);
    } finally {
      isLoading(false);
    }
  }
}
