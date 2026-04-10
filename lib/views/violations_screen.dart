import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/violations_controller.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/services/violations_pdf_service.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _lightPageBackground = Color(0xFFF8F9FF);
const Color _lightPanelBackground = Color(0xFFF0F3FF);
const Color _lightPanelBorder = Color(0xFFE1E8FD);

class ViolationsScreen extends StatefulWidget {
  final String numberPlate;

  const ViolationsScreen({super.key, required this.numberPlate});

  @override
  State<ViolationsScreen> createState() => _ViolationsScreenState();
}

class _ViolationsScreenState extends State<ViolationsScreen> {
  static const List<_ViolationOption> _violationOptions = [
    _ViolationOption(
      label: 'Speeding',
      apiValue: 'Speed Violations',
      icon: Icons.speed_rounded,
    ),
    _ViolationOption(
      label: 'Signal Wire',
      apiValue: 'Signal Wire Violations',
      icon: Icons.wifi_tethering_error_rounded,
    ),
    _ViolationOption(
      label: 'Power Cut',
      apiValue: 'Power Cut Violations',
      icon: Icons.power_off_rounded,
    ),
  ];

  final ViolationsController _violationsController = Get.put(
    ViolationsController(),
  );
  final DateFormat _fieldDateFormat = DateFormat('MMM dd,\nyyyy');
  final DateFormat _rangeDateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _eventDateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  DateTime? _startDate;
  DateTime? _endDate;
  _ViolationOption? _selectedViolation;
  List<DeviceRecord> _filteredViolations = [];
  bool _hasSearched = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _violationsController.violations.clear();
    _violationsController.reportUrl.value = null;
    _applyDefaultFilters();
  }

  void _applyDefaultFilters() {
    final today = _currentDay();
    _startDate = today.subtract(const Duration(days: 6));
    _endDate = today;
    _selectedViolation = _violationOptions.first;
  }

  DateTime _currentDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _downloadPdf() async {
    if (_selectedViolation == null || _filteredViolations.isEmpty) return;

    setState(() => isDownloading = true);

    try {
      final path = await ViolationsPdfService.generateAndSaveReportPdf(
        _filteredViolations,
        widget.numberPlate,
        _selectedViolation!.label,
      );

      if (!mounted) return;
      setState(() => isDownloading = false);

      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: 'Success',
          message: 'PDF saved successfully at:\n$path',
          confirmText: 'Open',
          cancelText: 'Close',
          onConfirm: () async {
            await OpenFile.open(path);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isDownloading = false);
      CustomAlertDialog(
        context: context,
        title: 'Error',
        message: 'Failed to generate the PDF file.',
        icon: 'assets/animations/Failed.json',
        buttonColor: kRed,
      );
    }
  }

  Future<void> _getViolations() async {
    if (_startDate == null || _endDate == null || _selectedViolation == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: 'Missing Filters',
          message:
              'Please confirm the start date, end date, and violation type.',
          confirmText: 'Ok',
          cancelText: 'Close',
          onConfirm: () async {},
        ),
      );
      return;
    }

    final formattedStartDate = _startDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();
    final formattedEndDate = _endDate!
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();

    try {
      await _violationsController.fetchViolations(
        widget.numberPlate,
        formattedStartDate,
        formattedEndDate,
        _selectedViolation!.apiValue,
      );

      if (!mounted) return;

      setState(() {
        _hasSearched = true;
        _filteredViolations = List<DeviceRecord>.from(
          _violationsController.violations,
        );
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _hasSearched = true);
      CustomAlertDialog(
        context: context,
        title: 'Error',
        message: 'We could not load violations right now. Please try again.',
        icon: 'assets/animations/Failed.json',
        buttonColor: kRed,
      );
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _currentDay(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? _currentDay(),
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

    if (picked == null) return;

    if (_endDate != null && picked.isAfter(_endDate!)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: 'Invalid Date',
          message: 'Start date cannot be after the end date.',
          confirmText: 'Ok',
          cancelText: 'Close',
          onConfirm: () async {},
        ),
      );
      return;
    }

    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final col = context.col;
    final isDark = context.isDark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _currentDay(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: _currentDay(),
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

    if (picked == null) return;

    if (_startDate != null && picked.isBefore(_startDate!)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => ActionDialog(
          title: 'Invalid Date',
          message: 'End date cannot be before the start date.',
          confirmText: 'Ok',
          cancelText: 'Close',
          onConfirm: () async {},
        ),
      );
      return;
    }

    setState(() => _endDate = picked);
  }

  Future<void> _applyQuickRange(int days, {bool fetch = false}) async {
    final today = _currentDay();

    setState(() {
      _startDate = today.subtract(Duration(days: days - 1));
      _endDate = today;
      _selectedViolation ??= _violationOptions.first;
    });

    if (fetch) {
      await _getViolations();
    }
  }

  void _resetFilters() {
    setState(() {
      _applyDefaultFilters();
      _filteredViolations = [];
      _hasSearched = false;
    });
    _violationsController.violations.clear();
    _violationsController.reportUrl.value = null;
  }

  Future<void> _openLocation(DeviceRecord record) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${record.lt},${record.lg}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showQuickFiltersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final col = sheetContext.col;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: col.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: col.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a shortcut to update the page faster.',
                  style: TextStyle(fontSize: 13, color: col.textSecondary),
                ),
                const SizedBox(height: 18),
                _buildSheetAction(
                  col: col,
                  icon: Icons.history_rounded,
                  title: 'Last 7 Days',
                  subtitle: 'Reset to the default range and fetch again.',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _applyQuickRange(7, fetch: true);
                  },
                ),
                _buildSheetAction(
                  col: col,
                  icon: Icons.update_rounded,
                  title: 'Last 30 Days',
                  subtitle: 'Run a broader check for recent events.',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _applyQuickRange(30, fetch: true);
                  },
                ),
                _buildSheetAction(
                  col: col,
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset Filters',
                  subtitle: 'Clear current results and go back to defaults.',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _resetFilters();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppColors col) {
    final actionColor = context.isDark ? kWhite : kBlue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          _TopBarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: actionColor,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Violations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: actionColor,
              ),
            ),
          ),
          _TopBarIconButton(
            icon: Icons.tune_rounded,
            color: actionColor,
            onTap: _showQuickFiltersSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(AppColors col, bool isBusy) {
    final panelColor = context.isDark ? col.surface : _lightPanelBackground;
    final panelBorder = context.isDark
        ? col.border.withValues(alpha: 0.6)
        : _lightPanelBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: panelBorder),
          boxShadow: context.isDark
              ? [kShadowSM]
              : [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildDateFieldCard(
                  col: col,
                  label: 'Start Date',
                  selectedDate: _startDate,
                  icon: Icons.calendar_today_outlined,
                  onTap: isBusy ? null : () => _pickStartDate(context),
                ),
                const SizedBox(width: 14),
                _buildDateFieldCard(
                  col: col,
                  label: 'End Date',
                  selectedDate: _endDate,
                  icon: Icons.calendar_today_outlined,
                  onTap: isBusy ? null : () => _pickEndDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildViolationFieldCard(col, isBusy),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isBusy ? null : _getViolations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: kWhite,
                  elevation: 0,
                  disabledBackgroundColor: kBlue.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: kWhite,
                        ),
                      )
                    : const Text('View Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFieldCard({
    required AppColors col,
    required String label,
    required DateTime? selectedDate,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: _buildFilterCardShell(
        col: col,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel(label),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: kBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _fieldDateFormat.format(selectedDate)
                        : 'Select\ndate',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: selectedDate != null
                          ? col.textPrimary
                          : col.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationFieldCard(AppColors col, bool isBusy) {
    return _buildFilterCardShell(
      col: col,
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Violation Type'),
          const SizedBox(height: 14),
          DropdownButtonHideUnderline(
            child: DropdownButton<_ViolationOption>(
              value: _selectedViolation,
              isExpanded: true,
              dropdownColor: context.isDark ? col.surface : kWhite,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: col.textSecondary,
                size: 24,
              ),
              selectedItemBuilder: (context) {
                return _violationOptions
                    .map(
                      (option) => _buildViolationDropdownLabel(
                        label: option.label,
                        icon: option.icon,
                        textColor: col.textPrimary,
                      ),
                    )
                    .toList();
              },
              items: _violationOptions
                  .map(
                    (option) => DropdownMenuItem<_ViolationOption>(
                      value: option,
                      child: _buildViolationDropdownLabel(
                        label: option.label,
                        icon: option.icon,
                        textColor: col.textPrimary,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isBusy
                  ? null
                  : (value) {
                      setState(() => _selectedViolation = value);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationDropdownLabel({
    required String label,
    required IconData icon,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: kBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: kBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCardShell({
    required AppColors col,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final cardColor = context.isDark ? col.inputFill : kWhite;
    final borderColor = context.isDark
        ? col.border.withValues(alpha: 0.6)
        : _lightPanelBorder;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: kBlue.withValues(alpha: 0.45),
      ),
    );
  }

  Widget _buildEmptyState(AppColors col) {
    final title = _hasSearched ? 'No violations found' : 'Ready to review';
    final description = _hasSearched
        ? "We couldn't find any recorded violations for the selected period. Try adjusting your date range or filters."
        : 'Set the period and violation type above, then tap View Results to check this vehicle.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmptyIllustration(),
          const SizedBox(height: 26),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: col.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 164,
                child: _buildShortcutCard(
                  col: col,
                  title: 'Last 30 Days',
                  description: 'Quick view for recent activity.',
                  icon: Icons.history_toggle_off_rounded,
                  onTap: () => _applyQuickRange(30, fetch: true),
                ),
              ),
              SizedBox(
                width: 164,
                child: _buildShortcutCard(
                  col: col,
                  title: 'Safety Trends',
                  description: 'Check fleet performance insights.',
                  icon: Icons.insert_chart_outlined_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverBehaviour(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIllustration() {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlue.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlue.withValues(alpha: 0.05),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlue.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 46,
              color: kBlue.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required AppColors col,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cardColor = context.isDark ? col.surface : _lightPanelBackground;
    final borderColor = context.isDark
        ? col.border.withValues(alpha: 0.6)
        : _lightPanelBorder;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kBlue, size: 20),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: col.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSummary(AppColors col) {
    final label = _filteredViolations.length == 1 ? 'violation' : 'violations';
    final subtitle = _startDate != null && _endDate != null
        ? '${_rangeDateFormat.format(_startDate!)} - ${_rangeDateFormat.format(_endDate!)}'
        : 'Selected range';
    final cardColor = context.isDark ? col.surface : kWhite;
    final borderColor = context.isDark
        ? col.border.withValues(alpha: 0.6)
        : _lightPanelBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: context.isDark
              ? [kShadowSM]
              : [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: kBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_filteredViolations.length} $label found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: col.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedViolation?.label ?? 'Violation type'} • $subtitle',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: isDownloading ? null : _downloadPdf,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                backgroundColor: kBlue.withValues(alpha: 0.08),
                foregroundColor: kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(isDownloading ? 'Preparing PDF...' : 'Download PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationCard(DeviceRecord record, AppColors col) {
    final violation = _selectedViolation ?? _violationOptions.first;
    final speed = double.tryParse(record.spd) ?? 0;
    final isSpeedViolation = violation.apiValue == 'Speed Violations';
    final speedColor = isSpeedViolation && speed > 80 ? kRed : kSuccessGreen;
    final cardColor = context.isDark ? col.surface : kWhite;
    final borderColor = context.isDark
        ? col.border.withValues(alpha: 0.6)
        : _lightPanelBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: context.isDark
              ? [kShadowSM]
              : [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(violation.icon, color: kBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        violation.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: col.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _eventDateFormat.format(record.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 13,
                          color: col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSpeedViolation)
                  _buildInfoChip(
                    label: '${record.spd} km/h',
                    icon: Icons.speed_rounded,
                    color: speedColor,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildInfoChip(
                  label: 'Heading ${record.course}°',
                  icon: Icons.explore_rounded,
                  color: kBlue,
                ),
                _buildInfoChip(
                  label: record.hasValidCoords
                      ? '${record.lt}, ${record.lg}'
                      : 'Location unavailable',
                  icon: Icons.place_outlined,
                  color: record.hasValidCoords ? kBlue : col.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: record.hasValidCoords
                    ? () => _openLocation(record)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kBlue,
                  side: BorderSide(
                    color: kBlue.withValues(alpha: 0.25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: Text(
                  record.hasValidCoords
                      ? 'Open Location'
                      : 'Location unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetAction({
    required AppColors col,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.isDark ? col.inputFill : _lightPanelBackground,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: context.isDark
                    ? col.border.withValues(alpha: 0.6)
                    : _lightPanelBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: kBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: col.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: col.textSecondary,
                  size: 20,
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
    final pageBackground = context.isDark ? col.bg : _lightPageBackground;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Obx(() {
          final isBusy = _violationsController.isLoading.value || isDownloading;

          return RefreshIndicator(
            color: kBlue,
            onRefresh: _hasSearched ? _getViolations : () async {},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildTopBar(col),
                      const SizedBox(height: 10),
                      _buildFilterPanel(col, isBusy),
                    ],
                  ),
                ),
                if (isBusy)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: LoadingAnimationWidget.fourRotatingDots(
                        color: kBlue,
                        size: 46,
                      ),
                    ),
                  )
                else if (_filteredViolations.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(col),
                  )
                else ...[
                  SliverToBoxAdapter(child: _buildResultsSummary(col)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildViolationCard(
                        _filteredViolations[index],
                        col,
                      );
                    }, childCount: _filteredViolations.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ViolationOption {
  final String label;
  final String apiValue;
  final IconData icon;

  const _ViolationOption({
    required this.label,
    required this.apiValue,
    required this.icon,
  });
}
