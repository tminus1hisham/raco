import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Future<void> CustomAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String icon,
  required Color buttonColor,
  String buttonText = "OK",
  VoidCallback? onPressed,
}) {
  return showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLG),
      ),
      elevation: 8,
      backgroundColor: kWhite,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),

      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 120, child: Lottie.asset(icon, fit: BoxFit.contain)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 23,
              color: buttonColor,
            ),
          ),
        ],
      ),

      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: kGrey, height: 1.4),
      ),

      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: kWhite,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusSM),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ),
      ],
    ),
  );
}
