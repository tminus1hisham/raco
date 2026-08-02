import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Speed limit presets offered as one-tap chips.
const List<double> _kSpeedPresets = [40, 60, 80, 100, 120];

const Color _kSpeedTint = Color(0xFFF39C12);

/// Opens the sheet that sets a custom over-speed threshold for [device].
///
/// Resolves to the saved limit in km/h, or null when nothing was saved.
Future<double?> showSpeedLimitSheet({
  required BuildContext context,
  required Device device,
  double? currentLimit,
}) {
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SpeedLimitSheet(device: device, currentLimit: currentLimit),
  );
}

class _SpeedLimitSheet extends StatefulWidget {
  const _SpeedLimitSheet({required this.device, this.currentLimit});

  final Device device;
  final double? currentLimit;

  @override
  State<_SpeedLimitSheet> createState() => _SpeedLimitSheetState();
}

class _SpeedLimitSheetState extends State<_SpeedLimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;
  bool _loading = false;
  bool _userEdited = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit == null
          ? ''
          : _format(widget.currentLimit!),
    );
    _loadCurrentLimit();
  }

  /// Confirms the limit against the server, since the seeded value may be a
  /// stale dashboard reading or another user may have changed it since.
  Future<void> _loadCurrentLimit() async {
    setState(() => _loading = true);
    final limit = await ApiService.fetchSpeedLimit(widget.device.deviceId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      // Never overwrite what the user is in the middle of typing.
      if (limit != null && !_userEdited && !_saving) {
        _controller.text = _format(limit);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  String? _validate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter a speed limit';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Speed limit must be above 0';
    if (parsed > 300) return 'Speed limit cannot exceed 300 km/h';
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final limit = double.parse(_controller.text.trim());
    // Captured up front: the sheet is popped on success, so its context can no
    // longer resolve a messenger by the time the result is reported.
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    try {
      final result = await ApiService.updateSpeedLimit(
        deviceId: widget.device.deviceId,
        newSpeedLimit: limit,
      );
      if (!mounted) return;
      final success = result['success'] == true;
      if (success) {
        Navigator.pop(context, limit);
      } else {
        setState(() => _saving = false);
      }
      _notify(
        messenger,
        success
            ? 'Speed limit set to ${_format(limit)} km/h'
            : (result['message'] ?? 'Failed to update speed limit'),
        success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _notify(messenger, '$e'.replaceFirst('Exception: ', ''), false);
    }
  }

  void _notify(ScaffoldMessengerState? messenger, String message, bool success) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? kSuccessGreen : kRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kRadiusLG),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: col.border,
                    borderRadius: BorderRadius.circular(kRadiusPill),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kSpeedTint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.speed_rounded,
                      color: _kSpeedTint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speed Limit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: col.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.device.numberPlate,
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
              const SizedBox(height: 16),
              Text(
                'The device raises an over-speed alert once the vehicle goes '
                'above this value.',
                style: TextStyle(fontSize: 12, color: col.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                enabled: !_saving,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validate,
                onChanged: (_) => _userEdited = true,
                decoration: InputDecoration(
                  labelText: 'Speed limit',
                  hintText: _loading ? 'Loading current limit…' : 'e.g. 80',
                  suffixText: 'km/h',
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kSpeedTint,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: col.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMD),
                    borderSide: BorderSide(color: col.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMD),
                    borderSide: BorderSide(color: col.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(kRadiusMD),
                    borderSide: const BorderSide(color: _kSpeedTint, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: _kSpeedPresets.map((preset) {
                  final isSelected =
                      double.tryParse(_controller.text.trim()) == preset;
                  return ChoiceChip(
                    label: Text('${_format(preset)} km/h'),
                    selected: isSelected,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() {
                            _userEdited = true;
                            _controller.text = _format(preset);
                          }),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _kSpeedTint : col.textSecondary,
                    ),
                    backgroundColor: col.inputFill,
                    selectedColor: _kSpeedTint.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: isSelected ? _kSpeedTint : col.border,
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kSpeedTint,
                    foregroundColor: kWhite,
                    disabledBackgroundColor: _kSpeedTint.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: kWhite,
                          ),
                        )
                      : const Text(
                          'Save Speed Limit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kWhite,
                          ),
                        ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
