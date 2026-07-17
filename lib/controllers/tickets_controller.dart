import 'package:atom/models/ticket_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:get/get.dart';

class TicketsController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var tickets = <TicketModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    try {
      isLoading(true);
      final fetched = await ApiService.fetchTickets();
      tickets.assignAll(fetched);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load tickets');
    } finally {
      isLoading(false);
    }
  }

  /// Creates a ticket. Returns true on success. Anyone can create one.
  Future<bool> createTicket(CreateTicketModel request) async {
    try {
      isSubmitting(true);
      final success = await ApiService.createTicket(request);
      if (success) await fetchTickets();
      return success;
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  /// Resolves a ticket (admins & technicians). Returns true on success.
  Future<bool> resolveTicket(int id, String status, String remarks) async {
    try {
      isSubmitting(true);
      final success = await ApiService.closeTicket(id, status, remarks);
      if (success) await fetchTickets();
      return success;
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSubmitting(false);
    }
  }
}
