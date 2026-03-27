import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

// ─── Semantic color tokens ─────────────────────────────────────────────────

/// Context-aware color tokens used throughout the app.
/// Access via `context.col.*`.
class AppColors extends ThemeExtension<AppColors> {
  final Color surface; // Card / sheet / dialog background
  final Color bg; // Scaffold / page background
  final Color textPrimary; // Headings and body text
  final Color textSecondary; // Hints, captions, secondary text
  final Color border; // Borders, inactive outlines
  final Color divider; // Thin separator lines
  final Color inputFill; // Text field fill

  const AppColors({
    required this.surface,
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.inputFill,
  });

  static const light = AppColors(
    surface: Color(0xFFFFFFFF),
    bg: Color(0xFFF2F2F2),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF7A7A73),
    border: Color(0xFFBDBDBD),
    divider: Color(0xFFE8E8E8),
    inputFill: Color(0xFFF5F5F5),
  );

  static const dark = AppColors(
    surface: Color(0xFF1E2232),
    bg: Color(0xFF141720),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFF9EA3B4),
    border: Color(0xFF3A4060),
    divider: Color(0xFF2A2F45),
    inputFill: Color(0xFF252A3D),
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? bg,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? divider,
    Color? inputFill,
  }) => AppColors(
    surface: surface ?? this.surface,
    bg: bg ?? this.bg,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    inputFill: inputFill ?? this.inputFill,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

// ─── BuildContext extension ────────────────────────────────────────────────

extension AppColorsExt on BuildContext {
  /// Shorthand for the current theme's semantic colors.
  AppColors get col => Theme.of(this).extension<AppColors>()!;

  /// Whether the current theme is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ─── Theme definitions ─────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    colors: AppColors.light,
    systemOverlay: const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    colorScheme: ColorScheme.light(
      primary: kBlue,
      onPrimary: kWhite,
      secondary: kSuccessGreen,
      error: kRed,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF000000),
      outline: kLightGrey,
    ),
  );

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
    systemOverlay: const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E2232),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    colorScheme: ColorScheme.dark(
      primary: kBlue,
      onPrimary: kWhite,
      secondary: kSuccessGreen,
      error: kRed,
      surface: const Color(0xFF1E2232),
      onSurface: const Color(0xFFF0F0F0),
      outline: const Color(0xFF3A4060),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required SystemUiOverlayStyle systemOverlay,
    required ColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: colorScheme,
      extensions: [colors],
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: colors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colors.textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kWhite,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
        systemOverlayStyle: systemOverlay,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlue,
          foregroundColor: kWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colors.textSecondary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: kBlue,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? kBlue : null,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? kBlue : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? kBlue.withValues(alpha: 0.4)
              : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF2A2F45)
            : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Color(0xFFF0F0F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: kBlue,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: kBlue,
      ),
    );
  }
}
