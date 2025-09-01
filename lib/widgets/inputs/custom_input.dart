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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container for the input field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              obscureText: widget.password ? _obscureText : false,
              readOnly: widget.readOnly,
              enabled: widget.isEnabled,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
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
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: Colors.grey.shade500)
                    : null,
                suffixIcon: widget.password
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                // 🚨 Hide Flutter's inline error completely
                errorStyle: const TextStyle(height: 0, fontSize: 0),
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
