import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetails extends StatefulWidget {
  final String vehiclePlate;
  final Device device;

  VehicleDetails({required this.vehiclePlate, required this.device});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  final _utils = Utils();
  bool _engineToggling = false;
  late bool _engineOn;

  @override
  void initState() {
    super.initState();
    _engineOn = widget.device.ignitionStatus == 1;
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isCertActive = widget.device.certificateActiveStatus;
    final isOnline = widget.device.isDeviceOnline;

    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            customHeader(
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
              label: widget.vehiclePlate,
              icon: Icons.directions_car,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  // ── Vehicle Details ────────────────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Vehicle Details',
                    icon: Icons.directions_car_rounded,
                    color: kBlue,
                  ),
                  _buildCard(
                    col: col,
                    children: [
                      _buildRow(
                        col: col,
                        icon: Icons.car_repair_rounded,
                        iconColor: kBlue,
                        label: 'Make',
                        value: widget.device.make,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.confirmation_number_outlined,
                        iconColor: kBlue,
                        label: 'Chassis Number',
                        value: widget.device.chassis,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.pin_outlined,
                        iconColor: kBlue,
                        label: 'Number Plate',
                        value: widget.device.numberPlate,
                      ),
                    ],
                  ),

                  // ── Ownership & Contact ────────────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Ownership & Contact',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  _buildCard(
                    col: col,
                    children: [
                      _buildRow(
                        col: col,
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Owner ID',
                        value: widget.device.ownerId,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Phone',
                        value: widget.device.phone,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Email',
                        value: widget.device.email,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.business_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Business Reg',
                        value: widget.device.businessReg,
                      ),
                    ],
                  ),

                  // ── Certificate & Compliance ───────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Certificate & Compliance',
                    icon: Icons.verified_rounded,
                    color: isCertActive ? kSuccessGreen : kRed,
                  ),
                  _buildCard(
                    col: col,
                    children: [
                      _buildRow(
                        col: col,
                        icon: Icons.numbers_outlined,
                        iconColor: isCertActive ? kSuccessGreen : kRed,
                        label: 'Certificate Number',
                        value: widget.device.certNo,
                      ),
                      _buildDivider(col),
                      _buildUrlRow(
                        col: col,
                        label: 'Certificate URL',
                        url: widget.device.certificateUrl,
                        color: isCertActive ? kSuccessGreen : kRed,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.shield_outlined,
                        iconColor: isCertActive ? kSuccessGreen : kRed,
                        label: 'Certificate Status',
                        value: isCertActive ? 'Active' : 'Inactive',
                        statusColor: isCertActive ? kSuccessGreen : kRed,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.calendar_today_outlined,
                        iconColor: isCertActive ? kSuccessGreen : kRed,
                        label: 'Certificate Expiry',
                        value: _utils.formatDate(
                          widget.device.certificateExpirey,
                        ),
                      ),
                    ],
                  ),

                  // ── Installation & Device ──────────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Installation & Device',
                    icon: Icons.settings_input_antenna_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildCard(
                    col: col,
                    children: [
                      _buildRow(
                        col: col,
                        icon: Icons.engineering_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Technician Name',
                        value: widget.device.technicianName,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.router_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Device Type',
                        value: widget.device.deviceType,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.wifi_tethering_rounded,
                        iconColor: isOnline ? kSuccessGreen : kRed,
                        label: 'Device Status',
                        value: isOnline ? 'Online' : 'Offline',
                        statusColor: isOnline ? kSuccessGreen : kRed,
                      ),
                    ],
                  ),

                  // ── Agent & Details ────────────────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Agent & Details',
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  _buildCard(
                    col: col,
                    children: [
                      _buildRow(
                        col: col,
                        icon: Icons.person_pin_outlined,
                        iconColor: const Color(0xFF6366F1),
                        label: 'Agent',
                        value: widget.device.agent,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF6366F1),
                        label: 'Agent ID',
                        value: widget.device.agentID,
                      ),
                      _buildDivider(col),
                      _buildRow(
                        col: col,
                        icon: Icons.phone_forwarded_outlined,
                        iconColor: const Color(0xFF6366F1),
                        label: 'Agent Phone',
                        value: widget.device.agentPhone,
                      ),
                    ],
                  ),

                  // ── Engine Control ─────────────────────────────────
                  _buildSectionHeader(
                    col: col,
                    title: 'Engine Control',
                    icon: Icons.power_settings_new_rounded,
                    color: _engineOn ? kSuccessGreen : kRed,
                  ),
                  _buildEngineToggleCard(col: col, isEngineOn: _engineOn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineToggleCard({
    required AppColors col,
    required bool isEngineOn,
  }) {
    final statusColor = isEngineOn ? kSuccessGreen : kRed;
    final statusLabel = isEngineOn ? 'Running' : 'Immobilized';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engine Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: col.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _engineToggling
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: statusColor,
                      ),
                    )
                  : Switch(
                      value: isEngineOn,
                      activeThumbColor: kSuccessGreen,
                      inactiveThumbColor: kRed,
                      inactiveTrackColor: kRed.withValues(alpha: 0.25),
                      onChanged: (_) => _showEngineReasonDialog(
                        command: isEngineOn ? 'Imobilize' : 'Restore',
                        label: isEngineOn ? 'Turn Off Engine' : 'Turn On Engine',
                        color: isEngineOn ? kRed : kSuccessGreen,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEngineReasonDialog({
    required String command,
    required String label,
    required Color color,
  }) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
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
              Text(
                'Vehicle: ${widget.device.numberPlate}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for this action...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusSM),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusSM),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _engineToggling = true);
    try {
      final result = await ApiService.sendVehicleCommand(
        deviceId: widget.device.deviceId,
        serialNumber: widget.device.serial,
        command: command,
        numberPlate: widget.device.numberPlate,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        final success = result['success'] == true;
        if (success) {
          setState(() => _engineOn = command == 'Restore');
        }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _engineToggling = false);
    }
  }

  Widget _buildSectionHeader({
    required AppColors col,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required AppColors col, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRow({
    required AppColors col,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: col.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                if (statusColor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      value.isEmpty ? '—' : value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  )
                else
                  Text(
                    value.isEmpty ? '—' : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: col.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlRow({
    required AppColors col,
    required String label,
    required String url,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.link_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: col.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: () => _openUrl(url),
                  child: Text(
                    url.isEmpty ? '—' : url,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kBlue,
                      decoration: url.isEmpty ? null : TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            GestureDetector(
              onTap: () => _copyToClipboard(url),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: col.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.copy_rounded,
                  color: col.textSecondary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors col) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 68),
      color: col.divider,
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open URL: $url')));
      }
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL copied to clipboard')));
    }
  }
}
