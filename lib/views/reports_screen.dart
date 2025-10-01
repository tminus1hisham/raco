import 'package:atom/config/constants.dart';
import 'package:atom/controllers/reports_violations.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ReportsScreen extends StatefulWidget {
  final String numberPlate;

  const ReportsScreen({super.key, required this.numberPlate});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy – HH:mm');
  final ReportsController _reportsController = Get.put(ReportsController());

  String? _selectedReportType;
  final List<String> _reportOptions = [
    "TP Report",
    "1 TP Report",
    "6 TP Report",
    "TRP Report",
  ];

  Future<void> _getReports() async {
    if (_selectedReportType == null) {
      Get.snackbar("Error", "Please select a report type");
      return;
    }
    await _reportsController.fetchReports(
      widget.numberPlate,
      _selectedReportType!,
    );
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
              color: _selectedReportType != null
                  ? kBlue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReportType,
              hint: Text(
                "Report Type",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              items: _reportOptions.map((String value) {
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
                  _selectedReportType = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(DeviceRecord record) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.createdAt != null
                ? _dateFormat.format(record.createdAt!)
                : "Unknown Date",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text("Speed: ${record.spd ?? "--"} km/h"),
          Text("Wire Cut: ${record.wr == 1 ? "Yes" : "No"}"),
          Text("Battery: ${record.bt == 0 ? "Cut" : "On"}"),
          Text("IMEI: ${record.imei ?? "--"}"),
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
              label: "Reports",
              icon: Icons.receipt_long,
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),

            // Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildDropdownButton(),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: CustomButton(
                callBackFunction: _getReports,
                label: "Get Reports",
                backgroundColor: kBlue,
                txtColor: kWhite,
              ),
            ),

            // Reports list
            Expanded(
              child: Obx(() {
                if (_reportsController.isLoading.value) {
                  return Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: kBlue,
                      size: 50,
                    ),
                  );
                }

                if (_reportsController.reports.isEmpty) {
                  return Center(
                    child: Text(
                      "No reports found",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _reportsController.reports.length,
                  itemBuilder: (context, index) =>
                      _buildReportCard(_reportsController.reports[index]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
