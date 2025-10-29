import 'package:atom/config/constants.dart';
import 'package:atom/controllers/reports_violations.dart';
import 'package:atom/models/report_model.dart';
import 'package:atom/services/pdf_service.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';

class ReportsScreen extends StatefulWidget {
  final String numberPlate;

  const ReportsScreen({super.key, required this.numberPlate});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy – HH:mm');
  final ReportsController _reportsController = Get.put(ReportsController());
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _reportsController.reports.clear();
    _reportsController.reportUrl.value = null;
    _selectedReportType = null;
  }

  String? _selectedReportType;
  final List<String> _reportOptions = [
    "TP Report",
    "1 TP Report",
    "6 TP Report",
    "TRP Report",
  ];

  Future<void> _getReports() async {
    if (_selectedReportType == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: "Infomation",
          message:
              "Please select the report type in order to generate a report.",
          confirmText: "Ok",
          cancelText: "Close",
          onConfirm: () async {},
        ),
      );
      return;
    }
    await _reportsController.fetchReports(
      widget.numberPlate,
      _selectedReportType!,
    );
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
            message: "Failed to download the report.",
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

  Widget _buildReportCard(ReportModel record) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (double.tryParse(record.spd ?? '0') ?? 0) > 80 || record.wr == 1
            ? kRed.withOpacity(0.1)
            : kWhite,

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
          Text("Battery: ${record.bt == 0 ? "Cut" : "Connected"}"),
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

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Obx(() {
                final url = _reportsController.reportUrl.value;
                return Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        callBackFunction: _getReports,
                        label: "Get Report",
                        backgroundColor: kBlue,
                        txtColor: kWhite,
                      ),
                    ),
                    if (url != null && url.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          callBackFunction: () async {
                            setState(() => isDownloading = true);
                            try {
                              final path =
                                  await PdfService.generateAndSaveReportPdf(
                                    _reportsController.reports,
                                    widget.numberPlate,
                                    _selectedReportType!,
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

                            // showCupertinoDialog(
                            //   context: context,
                            //   builder: (context) => ActionDialog(
                            //     title: "Generate PDF",
                            //     message:
                            //         "Do you want to generate and save this report as a PDF file?",
                            //     confirmText: "Generate",
                            //     cancelText: "Cancel",
                            //     onConfirm: () async {
                            //       setState(() => isDownloading = true);
                            //       try {
                            //         final path =
                            //             await PdfService.generateAndSaveReportPdf(
                            //               _reportsController.reports,
                            //               widget.numberPlate,
                            //               _selectedReportType!,
                            //             );
                            //
                            //         if (!mounted) return;
                            //         setState(() => isDownloading = false);
                            //
                            //         showCupertinoDialog(
                            //           context: context,
                            //           builder: (context) => ActionDialog(
                            //             title: "Success",
                            //             message:
                            //                 "PDF saved successfully at:\n$path",
                            //             confirmText: "Open",
                            //             cancelText: "Close",
                            //             onConfirm: () async {
                            //               await OpenFile.open(path);
                            //             },
                            //           ),
                            //         );
                            //       } catch (e) {
                            //         if (!mounted)
                            //           return; // ✅ prevent using disposed context
                            //         setState(() => isDownloading = false);
                            //         CustomAlertDialog(
                            //           context: context,
                            //           title: "Error",
                            //           message:
                            //               "Failed to generate the PDF file.",
                            //           icon: "assets/animations/Failed.json",
                            //           buttonColor: kRed,
                            //         );
                            //       }
                            //     },
                            //   ),
                            // );
                          },
                          label: "Donwload PDF",
                          backgroundColor: kBlue,
                          txtColor: kWhite,
                        ),
                      ),

                      // Expanded(
                      //   child: CustomButton(
                      //     callBackFunction: () async {
                      //       bool isLoading = false;
                      //       showCupertinoDialog(
                      //         context: context,
                      //         builder: (context) => ActionDialog(
                      //           title: "Download Report",
                      //           message:
                      //               "Are you sure you want to download this report?",
                      //           confirmText: "Download",
                      //           cancelText: "Cancel",
                      //           onConfirm: () async {
                      //             await downloadReport(
                      //               url,
                      //               _selectedReportType ?? "Report",
                      //               context,
                      //             );
                      //           },
                      //         ),
                      //       );
                      //     },
                      //     label: "Download",
                      //     backgroundColor: kBlue,
                      //     txtColor: kWhite,
                      //   ),
                      // ),
                    ],
                  ],
                );
              }),
            ),
            SizedBox(height: 10),
            // Reports list
            Expanded(
              child: Obx(() {
                if (_reportsController.isLoading.value || isDownloading) {
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
