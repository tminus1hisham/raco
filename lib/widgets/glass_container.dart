import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2, // Works well for dark mode, might need adjust for light
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark mode: white at very low alpha so the blur shows through on a dark bg.
    // Light mode: white at the caller's opacity (clamped to [0, 1]).
    final color = isDark
        ? Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.12)
        : Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.5),
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
