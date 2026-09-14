import 'dart:ui' show ImageFilter;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/utils/signal_tier.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/views/cars/geofencing_screen.dart';
import 'package:atom/views/cars/vehicle_details.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/reports_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:atom/widgets/modal/speed_limit_sheet.dart';
import 'package:atom/widgets/vehicle/vehicle_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectedCarScreen extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final Device devices;

  const SelectedCarScreen({
    super.key,
    required this.carModel,
    required this.licensePlate,
    required this.devices,
  });

  @override
  State<SelectedCarScreen> createState() => _SelectedCarScreenState();
}

class _SelectedCarScreenState extends State<SelectedCarScreen> {
  final _utils = Utils();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _engineToggling = false;
  bool? _localEngineOn; // optimistic local state while API request is in flight

  /// Over-speed threshold, seeded from the dashboard payload and updated
  /// whenever a new one is saved from this screen.
  double? _speedLimit;

  @override
  void initState() {
    super.initState();
    fetchPhoneNumber();
    _speedLimit = widget.devices.customSpeedLimit;
  }

  final RenewCertificateController _controller = Get.put(
    RenewCertificateController(),
  );

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  void fetchPhoneNumber() async {
    final savedPhone = await StorageService.getData('phone');

    setState(() {
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneNumberController.text = savedPhone;
      }
    });
  }

  bool _isCertificateExpired(String expiryDate) {
    try {
      final parsedDate = DateTime.parse(expiryDate);
      final now = DateTime.now();

      return parsedDate.isBefore(now) || parsedDate.isAtSameMomentAs(now);
    } catch (e) {
      return true;
    }
  }

  Future<void> _showEngineReasonDialog(bool turnOn) async {
    if (_engineToggling) return;
    final command = turnOn ? 'Restore' : 'Imobilize';
    final label = turnOn ? 'Turn On Engine' : 'Turn Off Engine';
    final color = turnOn ? kSuccessGreen : kRed;

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final col = ctx.col;
        return AlertDialog(
          backgroundColor: col.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.licensePlate,
                      style: TextStyle(
                        fontSize: 12,
                        color: col.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!turnOn) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRed.withValues(alpha: ctx.isDark ? 0.14 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kRed.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: kRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The engine will not start again until you '
                            'restore it from this screen.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: col.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: col.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Why are you doing this?',
                    filled: true,
                    fillColor: col.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Reason is required'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: col.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: kWhite,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(turnOn ? 'Turn On' : 'Turn Off'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _engineToggling = true);
    try {
      final result = await ApiService.sendVehicleCommand(
        deviceId: widget.devices.deviceId,
        serialNumber: widget.devices.serial,
        command: command,
        numberPlate: widget.devices.numberPlate,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        final success = result['success'] == true;
        if (success) setState(() => _localEngineOn = turnOn);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '$label command sent successfully'
                  : result['message'] ?? 'Command failed',
            ),
            backgroundColor: success ? kSuccessGreen : kRed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _engineToggling = false);
    }
  }

  void _showCertificateDialog(BuildContext context, String certUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.col.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
      ),
      builder: (context) {
        final sheetCol = context.col;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: sheetCol.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              // Icon badge + title
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kSuccessGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kSuccessGreen.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: kSuccessGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Certificate Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: sheetCol.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your certificate is valid. You can view or copy the URL below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: sheetCol.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              // URL display box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sheetCol.inputFill,
                  borderRadius: BorderRadius.circular(kRadiusMD),
                  border: Border.all(color: sheetCol.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 16, color: kBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        certUrl,
                        style: TextStyle(
                          fontSize: 12,
                          color: sheetCol.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: certUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('URL copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: kBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Open button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.open_in_browser_rounded,
                    color: kWhite,
                    size: 18,
                  ),
                  label: const Text(
                    'Open Certificate',
                    style: TextStyle(
                      fontSize: 15,
                      color: kWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.tryParse(certUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: context.col.surface,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
      ),
      builder: (context) {
        final sheetCol = context.col;
        int? selectedIndex;

        return Obx(() {
          if (_controller.isLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final plans = _controller.plans;

          if (plans.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  "No plans available.",
                  style: TextStyle(color: sheetCol.textSecondary),
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                    ),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          height: 5,
                          width: 40,
                          decoration: BoxDecoration(
                            color: sheetCol.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: kRed.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.autorenew_rounded,
                              color: kRed,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Renew Certificate',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: sheetCol.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Choose a plan to renew your certificate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sheetCol.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InputField(
                        hintText: 'Phone number',
                        prefixIcon: Icons.phone,
                        controller: _phoneNumberController,
                        isRequired: true,
                        integerOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This field is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Available Plans',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sheetCol.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(plans.length, (index) {
                        final plan = plans[index];
                        final isSelected = selectedIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kBlue.withValues(alpha: 0.06)
                                  : sheetCol.inputFill,
                              border: Border.all(
                                color: isSelected ? kBlue : sheetCol.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? kBlue
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? kBlue
                                          : sheetCol.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 13,
                                          color: kWhite,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.planName.isNotEmpty
                                            ? plan.planName
                                            : "Unnamed Plan",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: sheetCol.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 11,
                                            color: sheetCol.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${plan.durationInDays} ${plan.durationInDays > 1 ? 'Years' : 'Year'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: sheetCol.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kBlue.withValues(alpha: 0.12)
                                        : sheetCol.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? kBlue.withValues(alpha: 0.3)
                                          : sheetCol.border,
                                    ),
                                  ),
                                  child: Text(
                                    "KES ${plan.price}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isSelected
                                          ? kBlue
                                          : sheetCol.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedIndex != null
                                ? kBlue
                                : sheetCol.border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                            elevation: 0,
                          ),
                          onPressed: selectedIndex != null
                              ? () async {
                                  Navigator.pop(context);
                                  final parentContext = this.context;
                                  showCupertinoDialog(
                                    context: parentContext,
                                    builder: (context) => ActionDialog(
                                      title: "Renew Certificate",
                                      message:
                                          "Do you want to proceed with renewing your certificate using the ${plans[selectedIndex!].planName}?",
                                      confirmText: "Renew",
                                      cancelText: "Cancel",
                                      onConfirm: () async {
                                        bool success = await _controller
                                            .renewCertificate(
                                              parentContext,
                                              widget.licensePlate,
                                              _phoneNumberController.text
                                                  .trim(),
                                              plans[selectedIndex!].price
                                                  .toInt(),
                                              plans[selectedIndex!].id.toInt(),
                                            );
                                        if (!mounted) return;
                                        if (success) {
                                          CustomAlertDialog(
                                            context: parentContext,
                                            title: "Success",
                                            message:
                                                "Payment request successful, please pay to renew your certificate",
                                            icon:
                                                "assets/animations/Success.json",
                                            buttonColor: kSuccessGreen,
                                          );
                                        } else {
                                          CustomAlertDialog(
                                            context: parentContext,
                                            title: "Error",
                                            message: "Payment request failed.",
                                            icon:
                                                "assets/animations/Failed.json",
                                            buttonColor: kRed,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            "Renew Certificate",
                            style: TextStyle(
                              fontSize: 15,
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        });
      },
    );
  }

  void _openLiveLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleLocationScreen(
          deviceId: widget.devices.deviceId,
          serialNumber: widget.devices.serial,
          numberPlate: widget.devices.numberPlate,
          latitude: double.tryParse(widget.devices.latitude) ?? 0.0,
          longitude: double.tryParse(widget.devices.longitude) ?? 0.0,
        ),
      ),
    );
  }

  Future<void> _openSpeedLimitSheet() async {
    final saved = await showSpeedLimitSheet(
      context: context,
      device: widget.devices,
      currentLimit: _speedLimit,
    );
    if (saved == null || !mounted) return;

    setState(() => _speedLimit = saved);

    // This screen was handed a Device instance that the refetch cannot replace,
    // so _speedLimit above keeps it current. The refetch is for the dashboard
    // screens behind it, which rebuild from the controller.
    if (Get.isRegistered<DeviceController>()) {
      Get.find<DeviceController>().fetchDevices(silent: true);
    }
  }

  void _openCertificate(bool isExpired) {
    final certUrl = widget.devices.certificateUrl;
    if (!isExpired &&
        widget.devices.certificateActiveStatus &&
        certUrl.isNotEmpty) {
      _showCertificateDialog(context, certUrl);
    } else {
      _showPlanBottomSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isVehicleActive =
        _localEngineOn ?? (widget.devices.ignitionStatus == 1);
    final isOnline = widget.devices.isDeviceOnline;
    final isCertificateExpired = _isCertificateExpired(
      widget.devices.certificateExpirey,
    );
    final signalTier = SignalTier.from(widget.devices.signalStrength);
    final vehicleLocation = widget.devices.location.trim().isEmpty
        ? "Location unavailable"
        : widget.devices.location;
    final latitude = double.tryParse(widget.devices.latitude) ?? 0.0;
    final longitude = double.tryParse(widget.devices.longitude) ?? 0.0;
    final hasPosition = latitude != 0.0 || longitude != 0.0;

    return Obx(
      () => Scaffold(
        backgroundColor: col.bg,
        body: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const SizedBox(height: 10),
                  customHeader(
                    label: widget.licensePlate,
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VehicleHeroCard(
                          model: widget.carModel,
                          make: widget.devices.make,
                          isOnline: isOnline,
                          speedKph: double.tryParse(widget.devices.speed) ?? 0,
                          signalTier: signalTier,
                          location: vehicleLocation,
                          onLocationTap: hasPosition ? _openLiveLocation : null,
                        ),
                        if (isCertificateExpired) ...[
                          const SizedBox(height: 12),
                          VehicleAlertBanner(
                            icon: Icons.gpp_maybe_rounded,
                            title: 'Certificate expired',
                            message: 'Renew to keep this vehicle compliant.',
                            actionLabel: 'Renew',
                            onAction: () => _showPlanBottomSheet(context),
                          ),
                        ],
                        const SizedBox(height: 12),
                        VehicleEngineCard(
                          isEngineOn: isVehicleActive,
                          isBusy: _engineToggling,
                          onChanged: _showEngineReasonDialog,
                        ),
                        const SizedBox(height: 28),
                        const VehicleSectionLabel('Quick Actions'),
                        const SizedBox(height: 14),
                        VehicleQuickActionGrid(
                          actions: [
                            VehicleQuickAction(
                              title: 'Driver Behaviour',
                              description: 'Safety reports by period',
                              icon: Icons.safety_check_outlined,
                              color: kSuccessGreen,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverBehaviour(
                                      serialNo: widget.devices.serial,
                                      vehiclePlate: widget.devices.numberPlate,
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleQuickAction(
                              title: 'Location History',
                              description: 'Replay recent routes',
                              icon: Icons.route,
                              color: kBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaybackScreen(
                                      numberPlate: widget.devices.numberPlate,
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleQuickAction(
                              title: 'Violations',
                              description: 'Alerts and risk events',
                              icon: Icons.warning_amber_rounded,
                              color: kRed,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViolationsScreen(
                                      numberPlate: widget.devices.numberPlate,
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleQuickAction(
                              title: 'Live Location',
                              description: 'Track on the map',
                              icon: Icons.my_location_rounded,
                              color: Colors.orange,
                              onTap: _openLiveLocation,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const VehicleSectionLabel('Vehicle Management'),
                        const SizedBox(height: 14),
                        VehicleGroupCard(
                          children: [
                            VehicleActionTile(
                              icon: Icons.info_outline_rounded,
                              tint: kBlue,
                              title: 'Details',
                              subtitle: 'Chassis, device and owner records',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetails(
                                      vehiclePlate: widget.licensePlate,
                                      device: widget.devices,
                                      isEngineOn: isVehicleActive,
                                      onEngineChanged: (on) =>
                                          setState(() => _localEngineOn = on),
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleActionTile(
                              icon: Icons.tune_rounded,
                              tint: const Color(0xFF7C3AED),
                              title: 'Commands',
                              subtitle: 'Send a command to this vehicle',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Commands(device: widget.devices),
                                  ),
                                );
                              },
                            ),
                            VehicleActionTile(
                              icon: Icons.speed_rounded,
                              tint: const Color(0xFFF39C12),
                              title: 'Speed Limit',
                              subtitle: _speedLimit == null
                                  ? 'Set a custom over-speed threshold'
                                  : 'Alerts above ${_speedLimit!.toStringAsFixed(0)} km/h',
                              onTap: _openSpeedLimitSheet,
                            ),
                            VehicleActionTile(
                              icon: Icons.history_toggle_off_rounded,
                              tint: const Color(0xFFF59E0B),
                              title: 'Command History',
                              subtitle: 'Every command actioned so far',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.commandHistory,
                                );
                              },
                            ),
                            VehicleActionTile(
                              icon: Icons.gps_fixed_rounded,
                              tint: const Color(0xFF059669),
                              title: 'Geo Fence',
                              subtitle: 'Set where this vehicle may operate',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GeofencingScreen(
                                      numberPlate: widget.licensePlate,
                                      device: widget.devices,
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleActionTile(
                              icon: Icons.bar_chart_rounded,
                              tint: const Color(0xFF6366F1),
                              title: 'Reports',
                              subtitle: 'Trips, distance and activity',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportsScreen(
                                      numberPlate: widget.licensePlate,
                                    ),
                                  ),
                                );
                              },
                            ),
                            VehicleActionTile(
                              icon: Icons.verified_outlined,
                              tint: isCertificateExpired ? kRed : kSuccessGreen,
                              title: 'Certificate',
                              subtitle:
                                  'Expires ${_utils.formatDate(widget.devices.certificateExpirey)}',
                              badge: isCertificateExpired
                                  ? const VehicleStatusBadge(
                                      label: 'Expired',
                                      color: kRed,
                                    )
                                  : null,
                              onTap: () =>
                                  _openCertificate(isCertificateExpired),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.isLoading.value)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kWhite,
                      size: 50,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
