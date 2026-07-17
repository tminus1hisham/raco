import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'constants.dart';

/// Colour tokens shared by the profile surfaces — the Profile tab and the
/// Account Details screen. These pages run a cooler, bluer palette than the
/// rest of the app, so they resolve their colours here instead of reaching
/// into [AppColors] directly. Dark mode derives from [AppColors] so the pages
/// stay in step with the app theme.
class ProfilePalette {
  final Color bg; // Page background
  final Color accent; // Primary blue for actions and highlights
  final Color headline; // Titles and values
  final Color supporting; // Secondary and body text
  final Color sectionLabel; // Small uppercase group labels, chevrons
  final Color groupBg; // Grouped-card background
  final Color cardFill; // Individual tile / sheet fill
  final Color iconBg; // Icon chip background
  final Color hairline; // Borders and dividers
  final Color dangerBg; // Destructive button background
  final double shadowAlpha;

  const ProfilePalette({
    required this.bg,
    required this.accent,
    required this.headline,
    required this.supporting,
    required this.sectionLabel,
    required this.groupBg,
    required this.cardFill,
    required this.iconBg,
    required this.hairline,
    required this.dangerBg,
    required this.shadowAlpha,
  });

  static const _light = ProfilePalette(
    bg: Color(0xFFF6F7FE),
    accent: Color(0xFF1C55D6),
    headline: Color(0xFF172E69),
    supporting: Color(0xFF536995),
    sectionLabel: Color(0xFF6B7EAA),
    groupBg: Color(0xFFEFF2FF),
    cardFill: kWhite,
    iconBg: Color(0xFFD9E6FF),
    hairline: Color(0xFFE7EBFB),
    dangerBg: Color(0xFFF4DFE8),
    shadowAlpha: 0.04,
  );

  static ProfilePalette _darkFrom(AppColors col) => ProfilePalette(
    bg: col.bg,
    accent: const Color(0xFF8FB6FF),
    headline: col.textPrimary,
    supporting: col.textSecondary,
    sectionLabel: col.textSecondary,
    groupBg: col.surface,
    cardFill: col.surface,
    iconBg: kBlue.withValues(alpha: 0.16),
    hairline: col.border,
    dangerBg: const Color(0xFF40242B),
    shadowAlpha: 0.16,
  );

  static ProfilePalette of(BuildContext context) =>
      context.isDark ? _darkFrom(context.col) : _light;
}

extension ProfilePaletteExt on BuildContext {
  /// Shorthand for the profile surfaces' colour tokens.
  ProfilePalette get profile => ProfilePalette.of(this);
}
