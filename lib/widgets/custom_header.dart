import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

// ignore: camel_case_types
class customHeader extends StatelessWidget {
  const customHeader({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.showBackButton = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpaceXL),
      padding: const EdgeInsets.all(kSpaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlue, kBlue.withValues(alpha: 0.3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusLG),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: onPressed,
              child: const Icon(Icons.arrow_back_ios, color: kWhite),
            ),
            const SizedBox(width: kSpaceXS),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: kWhite,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 70,
            height: 50,
            decoration: BoxDecoration(
              color: kWhite.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
            child: Icon(icon, color: kWhite, size: 30),
          ),
        ],
      ),
    );
  }
}
