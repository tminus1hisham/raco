import 'package:atom/config/constants.dart';
import 'package:atom/controllers/violations_controller.dart';
import 'package:atom/models/playback_model.dart';
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

      // Start downloading
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

    // Cache filtered violations once instead of recalculating in build
    setState(() {
      _filteredViolations = _violationsController.violations;
    });
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
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

  Widget _buildDropdownButton() {
    return Container(
      height: 70,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedViolation != null
                  ? kBlue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedViolation,
              hint: Text(
                "Violation Type",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              items: _violationOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 70,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null
                      ? kBlue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selectedDate != null ? kBlue : Colors.grey[600],
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
                            color: Colors.grey[600],
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
                                ? Colors.black87
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViolationCard(DeviceRecord v) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Violation date + type + location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.createdAt != null
                    ? _dateFormat.format(v.createdAt!)
                    : "Unknown Date",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // ✅ Clickable Location
              InkWell(
                onTap: () async {
                  final lat = v.lt;
                  final lng = v.lg;
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    debugPrint('Could not open Google Maps');
                  }
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Open Location",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Speed if applicable
          if (_selectedViolation == "Speed Violations")
            Text(
              "${v.spd} km/h",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    v.spd != null && double.tryParse(v.spd.toString()) != null
                    ? (double.parse(v.spd.toString()) > 80
                          ? Colors.red
                          : Colors.blue)
                    : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
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
                    label: 'Start Date',
                    selectedDate: _startDate,
                    onTap: () => _pickStartDate(context),
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(width: 12),
                  _buildDatePickerButton(
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
              child: _buildDropdownButton(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Obx(() {
                final url = _violationsController.reportUrl.value;

                return Row(
                  children: [
                    // Get Violations Button
                    Expanded(
                      child: CustomButton(
                        callBackFunction: _getViolations,
                        label: "Get Violations",
                        backgroundColor: kBlue,
                        txtColor: kWhite,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Download Button (only show when URL is available)
                    if (url != null && url.isNotEmpty)
                      Expanded(
                        child: CustomButton(
                          callBackFunction: () async {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => ActionDialog(
                                title: "Download Violations",
                                message: "Are you sure you want to download?",
                                confirmText: "Download",
                                cancelText: "Cancel",
                                onConfirm: () async {
                                  await downloadReport(
                                    url,
                                    _selectedViolation ?? "Violations Report",
                                    context,
                                  );
                                },
                              ),
                            );
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

            // Content area
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
                      style: TextStyle(color: Colors.grey[600]),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredViolations.length,
                        itemBuilder: (context, index) =>
                            _buildViolationCard(_filteredViolations[index]),
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
