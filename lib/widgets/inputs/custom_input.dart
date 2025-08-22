import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatefulWidget {
  InputField({
    required this.hintText,
    this.password = false,
    this.readOnly = false,
    this.onChanged,
    this.integerOnly = false,
    this.errorText,
    this.isEnabled = true,
    this.controller,
    this.onTap,
    this.isRequired = false,
    this.validator,
    this.prefixIcon, // Added prefix icon support
  });

  String hintText;
  bool password;
  bool readOnly;
  final ValueChanged<String>? onChanged;
  final bool integerOnly;
  final String? errorText;
  bool isEnabled;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  bool isRequired;
  final String? Function(String?)? validator;
  final IconData? prefixIcon; // Added prefix icon

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String? _errorMessage;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              obscureText: widget.password ? _obscureText : false,
              readOnly: widget.readOnly,
              enabled: widget.isEnabled,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
              ),
              onChanged: (value) {
                setState(() {
                  if (widget.validator != null) {
                    _errorMessage = widget.validator!(value);
                  } else if (widget.isRequired && value.isEmpty) {
                    _errorMessage = "This field is required";
                  } else {
                    _errorMessage = null;
                  }
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
              },
              controller: widget.controller,
              onTap: widget.onTap,
              inputFormatters: widget.integerOnly
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                  widget.prefixIcon,
                  color: Colors.grey.shade500,
                )
                    : null,
                suffixIcon: widget.password
                    ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          if (_errorMessage != null || widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16.0),
              child: Text(
                _errorMessage ?? widget.errorText ?? '',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}