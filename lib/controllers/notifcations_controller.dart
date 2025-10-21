import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

import '../models/notifications_model.dart';

class NotificationsController extends GetxController {
  var isLoading = false.obs;
  var notifications = <NotificationModel>[].obs;

  /// Fetch all notifications from the API
  Future<void> fetchNotifications() async {
    try {
      isLoading(true);
      var fetchedNotifications = await ApiService.fetchNotifications();
      if (fetchedNotifications != null) {
        notifications.assignAll(
          NotificationModel.fromJsonList(fetchedNotifications),
        );
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading(false);
    }
  }
}
