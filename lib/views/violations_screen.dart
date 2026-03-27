import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/violations_controller.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/services/violations_pdf_service.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/modal/custom_alert.dart';

class ViolationsScreen extends StatefulWidget {
  final String numberPlate;

  const ViolationsScreen({super.key, required this.numberPlate});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final ViolationsController _violationsController = Get.put(
    ViolationsController(),
  );
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _violationsController.violations.clear();
    _violationsController.reportUrl.value = null;
  }

  Future<void> downloadReport(
    String url,
    String documentName,
    BuildContext context,
  ) async {
    try {
      setState(() {
        isDownloading = true;
      });

      String safeName = documentName
          .replaceAll(RegExp(r"[^\w\s]+"), '')
          .replaceAll(' ', '_');

      String fileName =
          "$safeName-${DateTime.now().millisecondsSinceEpoch}.pdf";

      FileDownloader.downloadFile(
        url: url,
        name: fileName,
        onProgress: (fileName, progress) {
          debugPrint('Downloading $fileName: $progress%');
        },
        onDownloadCompleted: (String path) async {
          setState(() {
            isDownloading = false;
          });

          String decodedPath = Uri.decodeFull(path);
          debugPrint("Downloaded path: $decodedPath");

          showCupertinoDialog(
            context: context,
            builder: (context) => ActionDialog(
              title: "Success",
              message: "Document saved to:\n$decodedPath",
              confirmText: "Open",
              cancelText: "Cancel",
              onConfirm: () async {
                final result = await OpenFile.open(decodedPath);
              },
            ),
          );
        },
        onDownloadError: (String error) {
          setState(() {
            isDownloading = false;
          });

          CustomAlertDialog(
            context: context,
            title: "Error",
            message: "Failed to download the violations.",
            icon: "assets/animations/Failed.json",
            buttonColor: kRed,
          );
        },
      );
    } catch (e) {
      setState(() {
        isDownloading = false;
      });

      CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to download the report.",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }
  }

  String? _selectedViolation;
  final List<String> _violationOptions = [
    "Speed Violations",
    "Signal Wire Violations",
    "Power Cut Violations",
  ];

  List<DeviceRecord> _filteredViolations = [];

  Future<void> _getViolations() async {
    if (_startDate == null || _endDate == null || _selectedViolation == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: "Error",
          message:
              "Please confirm you have selected the start date, end date & violation type.",
          confirmText: "Ok",
          cancelText: "Cancel",
          onConfirm: () async {},
        ),
      );
      return;
    }

    final String formattedStartDate = _startDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    final String formattedEndDate = _endDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    await _violationsController.fetchViolations(
      widget.numberPlate,
      formattedStartDate,
      formattedEndDate,
      _selectedViolation ?? '',
    );

    setState(() {
      _filteredViolations = _violationsController.violations;
    });
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: kBlue,
                    onPrimary: kWhite,
                    surface: col.surface,
                    onSurface: col.textPrimary,
                  )
                : ColorScheme.light(
                    primary: kBlue,
                    onPrimary: kWhite,
                    surface: col.surface,
                    onSurface: col.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        showCupertinoDialog(
          context: context,
          builder: (context) => ActionDialog(
            title: "Invalid Date",
            message: "Start date cannot be after the end date.",
            confirmText: "Ok",
            cancelText: "Cancel",
            onConfirm: () async {},
          ),
        );
        return;
      }
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: kBlue,
                    onPrimary: kWhite,
                    surface: col.surface,
                    onSurface: col.textPrimary,
                  )
                : ColorScheme.light(
                    primary: kBlue,
                    onPrimary: kWhite,
                    surface: col.surface,
                    onSurface: col.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        showCupertinoDialog(
          context: context,
          builder: (context) => ActionDialog(
            title: "Invalid Date",
            message: "End date cannot be before the start date.",
            confirmText: "Ok",
            cancelText: "Cancel",
            onConfirm: () async {},
          ),
        );
        return;
      }
      setState(() => _endDate = picked);
    }
  }

  Widget _buildDropdownButton(AppColors col) {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Material(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusMD),
            border: Border.all(
              color: _selectedViolation != null
                  ? kBlue.withValues(alpha: 0.3)
                  : col.border.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedViolation,
              dropdownColor: col.surface,
              hint: Text(
                "Violation Type",
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: col.border),
              items: _violationOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedViolation = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton({
    required AppColors col,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: SizedBox(
        height: 70,
        child: Material(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(kRadiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusMD),
                border: Border.all(
                  color: selectedDate != null
                      ? kBlue.withValues(alpha: 0.3)
                      : col.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selectedDate != null ? kBlue : col.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: col.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedDate != null
                              ? _dateFormat.format(selectedDate)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDate != null
                                ? col.textPrimary
                                : col.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: col.border, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViolationCard(DeviceRecord v, AppColors col) {
    final isSpeedViolation = _selectedViolation == "Speed Violations";
    final speed = double.tryParse(v.spd.toString()) ?? 0;
    final isOverSpeed = isSpeedViolation && speed > 80;
    final speedColor = isOverSpeed ? kRed : kSuccessGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          boxShadow: [kShadowSM],
          border: Border.all(color: kRed.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusMD),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: kRed),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kRed.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: kRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: col.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _dateFormat.format(v.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: col.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isSpeedViolation) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: speedColor.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: speedColor.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.speed_rounded,
                                            size: 12,
                                            color: speedColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${v.spd} km/h',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: speedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final lat = v.lt;
                                  final lng = v.lg;
                                  final url = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: kBlue.withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: kBlue,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Open Location',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: "Violations",
              icon: Icons.warning_amber,
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildDatePickerButton(
                    col: col,
                    label: 'Start Date',
                    selectedDate: _startDate,
                    onTap: () => _pickStartDate(context),
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(width: 12),
                  _buildDatePickerButton(
                    col: col,
                    label: 'End Date',
                    selectedDate: _endDate,
                    onTap: () => _pickEndDate(context),
                    icon: Icons.event_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildDropdownButton(col),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Obx(() {
                final url = _violationsController.reportUrl.value;

                return Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        callBackFunction: _getViolations,
                        label: "Get Violations",
                        backgroundColor: kBlue,
                        txtColor: kWhite,
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (url != null && url.isNotEmpty)
                      Expanded(
                        child: CustomButton(
                          callBackFunction: () async {
                            setState(() => isDownloading = true);
                            try {
                              final path =
                                  await ViolationsPdfService.generateAndSaveReportPdf(
                                    _violationsController.violations,
                                    widget.numberPlate,
                                    _selectedViolation!,
                                  );

                              if (!mounted) return;
                              setState(() => isDownloading = false);

                              showCupertinoDialog(
                                context: context,
                                builder: (context) => ActionDialog(
                                  title: "Success",
                                  message: "PDF saved successfully at:\n$path",
                                  confirmText: "Open",
                                  cancelText: "Close",
                                  onConfirm: () async {
                                    await OpenFile.open(path);
                                  },
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => isDownloading = false);
                              CustomAlertDialog(
                                context: context,
                                title: "Error",
                                message: "Failed to generate the PDF file.",
                                icon: "assets/animations/Failed.json",
                                buttonColor: kRed,
                              );
                            }
                          },
                          label: "Download",
                          backgroundColor: kBlue,
                          txtColor: kWhite,
                        ),
                      ),
                  ],
                );
              }),
            ),

            Expanded(
              child: Obx(() {
                if (_violationsController.isLoading.value || isDownloading) {
                  return Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  );
                }

                if (_filteredViolations.isEmpty) {
                  return Center(
                    child: Text(
                      "No violations found",
                      style: TextStyle(color: col.textSecondary),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      child: Text(
                        "Total Violations: ${_filteredViolations.length}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: col.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _getViolations,
                        color: kBlue,
                        child: ListView.builder(
                          itemCount: _filteredViolations.length,
                          itemBuilder: (context, index) => _buildViolationCard(
                            _filteredViolations[index],
                            col,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
