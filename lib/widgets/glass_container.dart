import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  /// When true, this surface is a bottom sheet. In light mode it renders as a
  /// near-opaque "solid frost" so the dimmed scrim behind can't muddy it,
  /// while keeping a top-lip highlight and blur for depth. Dark mode and the
  /// translucent card look are unaffected.
  final bool isSheet;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2, // Works well for dark mode, might need adjust for light
    this.borderRadius,
    this.border,
    this.isSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.zero;
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    // Light-mode bottom sheets get the near-opaque "solid frost" treatment.
    final bool solidFrost = isSheet && !isDark;

    // Dark mode: white at very low alpha so the blur shows through on a dark bg.
    // Light mode (cards): a brighter frosted white so the panel separates from
    // the near-white scaffold instead of disappearing into it.
    final color = isDark
        ? Colors.white.withValues(alpha: clampedOpacity * 0.12)
        : Colors.white.withValues(alpha: (0.62 + clampedOpacity * 0.12).clamp(0.0, 0.92));

    final decoration = BoxDecoration(
      color: solidFrost ? null : color,
      // Near-opaque top→bottom sheen for the solid-frost sheet.
      gradient: solidFrost
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF6F9FC)],
            )
          : null,
      borderRadius: borderRadius,
      border: border ??
          (solidFrost
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      // Soft blue-grey hairline gives cards a crisp edge.
                      : const Color(0xFFDDE1EC),
                )),
    );

    Widget frosted = DecoratedBox(decoration: decoration, child: child);

    // Bright 1px light strike along the sheet's top lip.
    if (solidFrost) {
      frosted = Stack(
        children: [
          frosted,
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            height: 1,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final glass = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: frosted,
      ),
    );

    // Dark mode already reads well; keep it untouched.
    if (isDark) return glass;

    // Light mode: lift the surface off the background with a soft shadow so the
    // glass is clearly visible. Sheets cast the shadow upward, off the scrim.
    final shadows = solidFrost
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 40,
              spreadRadius: -2,
              offset: const Offset(0, -16),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: glass,
    );
  }
}
