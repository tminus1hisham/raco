import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/tickets_controller.dart';
import 'package:atom/models/ticket_model.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/services/upload_image_service.dart';
import 'package:atom/views/camera_screen.dart';
import 'package:atom/widgets/buttons/primary_gradient_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/glass_container.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Available ticket categories shown when raising a ticket.
const List<String> kTicketTypes = <String>[
  'Maintenance',
  'Installation',
  'Repair',
  'Billing',
  'Feature Request',
  'Other',
];

/// Statuses an admin / technician can move a ticket to.
const List<String> kResolveStatuses = <String>[
  'In Progress',
  'Resolved',
  'Closed',
  'Rejected',
];

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketsController controller = Get.isRegistered<TicketsController>()
      ? Get.find<TicketsController>()
      : Get.put(TicketsController());

  bool _canResolve = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = (await StorageService.getData('userRole'))
            ?.toString()
            .toLowerCase() ??
        '';
    if (!mounted) return;
    setState(() {
      // Anyone can create; only admins & technicians can resolve tickets.
      _canResolve = role.contains('admin') || role.contains('technician');
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('resolved') || s.contains('closed')) return kSuccessGreen;
    if (s.contains('progress')) return kBlue;
    if (s.contains('reject')) return kRed;
    // Open / Pending / new tickets.
    return const Color(0xFFEE9B00);
  }

  String _statusLabel(String status) =>
      status.trim().isEmpty ? 'Open' : status.trim();

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year}  $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketSheet,
        backgroundColor: kBlue,
        icon: const Icon(Icons.add, color: kWhite),
        label: const Text(
          'New Ticket',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            customHeader(
              label: 'Support Tickets',
              icon: Icons.confirmation_number_outlined,
              subtitle: _canResolve
                  ? 'Review and resolve maintenance tickets'
                  : 'Raise and track your maintenance tickets',
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.tickets.isEmpty) {
                  return Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  );
                }

                if (controller.tickets.isEmpty) {
                  return _buildEmptyState(col);
                }

                return RefreshIndicator(
                  color: kBlue,
                  onRefresh: controller.fetchTickets,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: controller.tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTicketCard(col, controller.tickets[index]);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors col) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.confirmation_number_outlined,
          size: 72,
          color: col.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No tickets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Tap "New Ticket" to raise a maintenance request',
            style: TextStyle(fontSize: 13, color: col.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(AppColors col, TicketModel ticket) {
    final statusColor = _statusColor(ticket.status);
    final statusLabel = _statusLabel(ticket.status);

    return GlassContainer(
      borderRadius: BorderRadius.circular(kRadiusLG),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusLG),
          onTap: () => _showTicketDetailSheet(ticket),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.build_outlined,
                          color: kBlue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ticket.ticketType.isEmpty
                            ? 'Ticket #${ticket.id}'
                            : ticket.ticketType,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: col.textPrimary,
                        ),
                      ),
                    ),
                    _statusBadge(statusLabel, statusColor),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: col.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: col.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.createdByName.isEmpty
                            ? 'Unknown'
                            : ticket.createdByName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: col.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: col.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ─── Create ticket ──────────────────────────────────────────────────────

  void _showCreateTicketSheet() {
    final commentController = TextEditingController();
    final selectedType = kTicketTypes.first.obs;
    final attachmentUrl = ''.obs;
    final isUploading = false.obs;
    final uploader = ImageUploaderService();

    Future<void> pickAttachment(ImageSource source) async {
      try {
        XFile? image;
        if (source == ImageSource.camera) {
          final captured = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraCaptureScreen(
                preferredCamera: CameraLensDirection.back,
              ),
            ),
          );
          if (captured is XFile) image = captured;
        } else {
          image = await ImagePicker().pickImage(source: ImageSource.gallery);
        }
        if (image == null) return;

        isUploading(true);
        final url = await uploader.uploadPicture(image);
        if (url != null && url.isNotEmpty) {
          attachmentUrl(url);
        } else {
          Get.snackbar('Upload failed', 'Could not attach the image');
        }
      } catch (_) {
        Get.snackbar('Upload failed', 'Could not attach the image');
      } finally {
        isUploading(false);
      }
    }

    void chooseAttachmentSource() {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_outlined, color: kBlue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickAttachment(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: kBlue),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  pickAttachment(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final col = sheetContext.col;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: GlassContainer(
            isSheet: true,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: col.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_task,
                                color: kBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Raise a Ticket',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: col.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                            color: col.textSecondary,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Ticket Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: col.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: col.inputFill,
                            borderRadius: BorderRadius.circular(kRadiusMD),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedType.value,
                              isExpanded: true,
                              dropdownColor: col.surface,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: col.textSecondary),
                              style: TextStyle(
                                  color: col.textPrimary, fontSize: 15),
                              items: kTicketTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) selectedType(v);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Describe the issue',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: col.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InputField(
                        hintText: 'What needs attention?',
                        controller: commentController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => OutlinedButton.icon(
                          onPressed: isUploading.value
                              ? null
                              : chooseAttachmentSource,
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: col.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                          ),
                          icon: isUploading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kBlue),
                                )
                              : Icon(
                                  attachmentUrl.value.isEmpty
                                      ? Icons.attach_file
                                      : Icons.check_circle,
                                  color: attachmentUrl.value.isEmpty
                                      ? kBlue
                                      : kSuccessGreen,
                                  size: 20,
                                ),
                          label: Text(
                            isUploading.value
                                ? 'Uploading...'
                                : attachmentUrl.value.isEmpty
                                    ? 'Attach a photo (optional)'
                                    : 'Attachment added',
                            style: TextStyle(
                              color: attachmentUrl.value.isEmpty
                                  ? col.textPrimary
                                  : kSuccessGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => PrimaryGradientButton(
                          isLoading: controller.isSubmitting.value,
                          text: controller.isSubmitting.value
                              ? 'Submitting...'
                              : 'Submit Ticket',
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            if (comment.isEmpty) {
                              Get.snackbar(
                                'Validation Error',
                                'Please describe the issue',
                                backgroundColor: kRed.withValues(alpha: 0.1),
                                colorText: kRed,
                              );
                              return;
                            }
                            FocusScope.of(sheetContext).unfocus();

                            final success = await controller.createTicket(
                              CreateTicketModel(
                                comment: comment,
                                ticketType: selectedType.value,
                                attachments: attachmentUrl.value,
                              ),
                            );

                            if (success && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              Get.snackbar(
                                'Ticket Created',
                                'Your ticket has been submitted successfully',
                                backgroundColor:
                                    kSuccessGreen.withValues(alpha: 0.12),
                                colorText: kSuccessGreen,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Ticket detail ──────────────────────────────────────────────────────

  void _showTicketDetailSheet(TicketModel ticket) {
    final statusColor = _statusColor(ticket.status);
    final statusLabel = _statusLabel(ticket.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final col = sheetContext.col;
        return GlassContainer(
          isSheet: true,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: col.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.ticketType.isEmpty
                                ? 'Ticket #${ticket.id}'
                                : ticket.ticketType,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: col.textPrimary,
                            ),
                          ),
                        ),
                        _statusBadge(statusLabel, statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ticket #${ticket.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: col.textSecondary,
                      ),
                    ),
                    const Divider(height: 24),
                    _detailRow(col, Icons.person_outline, 'Raised by',
                        ticket.createdByName.isEmpty
                            ? 'Unknown'
                            : ticket.createdByName),
                    const SizedBox(height: 12),
                    _detailRow(col, Icons.schedule, 'Created',
                        _formatDate(ticket.createdAt)),
                    const SizedBox(height: 12),
                    _detailRow(col, Icons.notes_outlined, 'Description',
                        ticket.comment),
                    if (ticket.approvalRemarks.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _detailRow(col, Icons.rate_review_outlined, 'Remarks',
                          ticket.approvalRemarks),
                    ],
                    if (ticket.attachments.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(kRadiusMD),
                        child: Image.network(
                          ticket.attachments,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    if (_canResolve) ...[
                      const SizedBox(height: 24),
                      PrimaryGradientButton(
                        icon: Icons.check_circle_outline,
                        text: 'Update Status',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showResolveSheet(ticket);
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
      AppColors col, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: col.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: 15,
                  color: col.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Resolve ticket (admin / technician) ────────────────────────────────

  void _showResolveSheet(TicketModel ticket) {
    final remarksController = TextEditingController(
      text: ticket.approvalRemarks,
    );
    final selectedStatus = (kResolveStatuses.contains(ticket.status)
            ? ticket.status
            : kResolveStatuses.first)
        .obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final col = sheetContext.col;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: GlassContainer(
            isSheet: true,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: col.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.task_alt,
                                color: kBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Resolve Ticket',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: col.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                            color: col.textSecondary,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'New Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: col.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: col.inputFill,
                            borderRadius: BorderRadius.circular(kRadiusMD),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedStatus.value,
                              isExpanded: true,
                              dropdownColor: col.surface,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: col.textSecondary),
                              style: TextStyle(
                                  color: col.textPrimary, fontSize: 15),
                              items: kResolveStatuses
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) selectedStatus(v);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: col.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InputField(
                        hintText: 'Add a note for the requester',
                        controller: remarksController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => PrimaryGradientButton(
                          isLoading: controller.isSubmitting.value,
                          text: controller.isSubmitting.value
                              ? 'Saving...'
                              : 'Save',
                          onPressed: () async {
                            FocusScope.of(sheetContext).unfocus();
                            final success = await controller.resolveTicket(
                              ticket.id,
                              selectedStatus.value,
                              remarksController.text.trim(),
                            );
                            if (success && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              Get.snackbar(
                                'Ticket Updated',
                                'Ticket #${ticket.id} is now '
                                    '"${selectedStatus.value}"',
                                backgroundColor:
                                    kSuccessGreen.withValues(alpha: 0.12),
                                colorText: kSuccessGreen,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
