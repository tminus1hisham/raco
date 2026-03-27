import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.callBackFunction,
    required this.label,
    required this.backgroundColor,
    required this.txtColor,
    this.isLoading = false,
  });

  final VoidCallback callBackFunction;
  final String label;
  final Color backgroundColor;
  final Color txtColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : callBackFunction,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: txtColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: txtColor),
            )
          : Text(
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
