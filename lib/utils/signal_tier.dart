import 'package:flutter/material.dart';

enum SignalTier {
  excellent('Excellent', Color(0xFF2dda94)),
  good('Good', Color(0xFF8BC34A)),
  fair('Fair', Color(0xFFFFB300)),
  poor('Poor', Color(0xFFE62727));

  final String label;
  final Color color;
  const SignalTier(this.label, this.color);

  static SignalTier from(int strength) {
    if (strength >= 25) return excellent;
    if (strength >= 20) return good;
    if (strength >= 15) return fair;
    return poor;
  }
}
