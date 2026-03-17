import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class CustomBorderButton extends StatelessWidget {
  const CustomBorderButton({
    super.key,
    required this.callBackFunction,
    required this.label,
    required this.borderColor,
    required this.txtColor,
  });

  final VoidCallback callBackFunction;
  final String label;
  final Color borderColor;
  final Color txtColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: callBackFunction,
      style: OutlinedButton.styleFrom(
        foregroundColor: txtColor,
        side: BorderSide(color: borderColor, width: 1.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: txtColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
