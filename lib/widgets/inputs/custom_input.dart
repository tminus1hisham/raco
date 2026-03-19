import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  InputField({
    required this.hintText,
    this.password = false,
    this.readOnly = false,
    this.onChanged,
    this.integerOnly = false,
    this.isEnabled = true,
    this.controller,
    this.onTap,
    this.isRequired = false,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
  });

  final String hintText;
  final bool password;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final bool integerOnly;
  final bool isEnabled;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final bool isRequired;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;
  String? _errorMessage;

  String? _validateField(String? value) {
    String? error;

    if (widget.validator != null) {
      error = widget.validator!(value);
    } else if (widget.isRequired && (value == null || value.trim().isEmpty)) {
      error = "This field is required";
    }

    setState(() {
      _errorMessage = error;
    });

    return error;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            obscureText: widget.password ? _obscureText : false,
            readOnly: widget.readOnly,
            enabled: widget.isEnabled,
            style: TextStyle(color: context.col.textPrimary, fontSize: 16),
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            controller: widget.controller,
            onTap: widget.onTap,
            validator: _validateField,
            inputFormatters: widget.integerOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: context.col.textSecondary),
              filled: true,
              fillColor: context.col.inputFill,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: context.col.textSecondary)
                  : null,
              suffixIcon: widget.password
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: context.col.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: hasError
                    ? const BorderSide(color: kRed, width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: BorderSide(
                  color: hasError ? kRed : kBlue,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: const BorderSide(color: kRed, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusMD),
                borderSide: const BorderSide(color: kRed, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),

          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: kRed, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
