import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

/// A compact page-level navigation header.
///
/// Page content owns the visual personality below this component; the header
/// only provides hierarchy, navigation, and an optional contextual action.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showBackButton = false,
    this.trailingIcon,
    this.onTrailingPressed,
    this.trailingTooltip,
    this.margin = const EdgeInsets.symmetric(horizontal: kSpaceXL),
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBackButton;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final String? trailingTooltip;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.col;
    final hasSubtitle = subtitle?.trim().isNotEmpty ?? false;

    return Semantics(
      container: true,
      header: true,
      label: title,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(kRadiusLG),
          border: Border.all(color: colors.divider),
          boxShadow: context.isDark ? null : [kShadowSM],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            hasSubtitle ? 9 : 8,
            8,
            hasSubtitle ? 9 : 8,
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                _HeaderButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                if (onTrailingPressed != null)
                  _HeaderButton(
                    icon: trailingIcon!,
                    tooltip: trailingTooltip,
                    onPressed: onTrailingPressed!,
                    accent: true,
                  )
                else
                  _HeaderIcon(icon: trailingIcon!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Backwards-compatible adapter used by existing screens.
// ignore: camel_case_types
class customHeader extends StatelessWidget {
  const customHeader({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.showBackButton = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(
      title: label,
      subtitle: subtitle,
      showBackButton: showBackButton,
      onBack: onPressed,
      // A decorative section icon is useful on root pages. On nested pages the
      // back button already establishes hierarchy, so title space wins.
      trailingIcon: showBackButton ? null : icon,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.col;
    final background = accent
        ? kBlue.withValues(alpha: context.isDark ? 0.20 : 0.10)
        : colors.inputFill;
    final foreground = accent ? kBlue : colors.textPrimary;

    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
            side: BorderSide(color: colors.divider),
          ),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kBlue.withValues(alpha: context.isDark ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: kBlue, size: 21),
      ),
    );
  }
}
