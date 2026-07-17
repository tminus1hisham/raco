import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/config/profile_palette.dart';
import 'package:flutter/material.dart';

/// Building blocks shared by the Profile tab and the Account Details screen so
/// the two read as one surface. All colours come from [ProfilePalette].

/// Initials derived from a display name, e.g. "Jane Doe" -> "JD".
String profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  if (parts.isNotEmpty) {
    return parts.first[0].toUpperCase();
  }
  return 'P';
}

/// Circular avatar that falls back to initials on a gradient when there is no
/// image, or when the network image fails to load.
class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String displayName;
  final double size;

  /// Small action button pinned to the bottom-right, e.g. edit or camera.
  final Widget? badge;

  /// Ring around the avatar. Defaults to the page surface; pass white when the
  /// avatar sits on the gradient hero.
  final Color? borderColor;

  final double borderWidth;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.displayName,
    this.size = 104,
    this.badge,
    this.borderColor,
    this.borderWidth = 5,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    final hasImage = imageUrl.trim().isNotEmpty;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? col.surface : const Color(0xFFE9D8BE),
        border: Border.all(
          color: borderColor ?? (isDark ? col.surface : kWhite),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _Initials(displayName: displayName, size: size),
              )
            : _Initials(displayName: displayName, size: size),
      ),
    );

    if (badge == null) return avatar;

    return SizedBox(
      width: size + 18,
      height: size + 16,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(right: 0, bottom: 0, child: badge!),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String displayName;
  final double size;

  const _Initials({required this.displayName, required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? const [Color(0xFF2D3652), Color(0xFF1C2440)]
              : const [Color(0xFFDAB98B), Color(0xFF8A6A46)],
        ),
      ),
      child: Center(
        child: Text(
          profileInitials(displayName),
          style: TextStyle(
            color: kWhite,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Round action button used for the avatar badge and top-bar actions.
class ProfileCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? iconColor;

  const ProfileCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.background,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.profile.accent;
    final fill = background ?? accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: fill.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor ?? kWhite, size: size * 0.5),
        ),
      ),
    );
  }
}

/// Gradient identity card that heads both profile surfaces: avatar, name,
/// subtitle and status chips, with an optional footer row below a hairline.
/// The gradient matches [customHeader] so the profile pages sit in the app's
/// brand language.
class ProfileHeroCard extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String imageUrl;
  final Widget? avatarBadge;
  final List<Widget> chips;
  final Widget? footer;

  const ProfileHeroCard({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.imageUrl,
    this.avatarBadge,
    this.chips = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF111827), Color(0xFF1A3352), Color(0xFF1D6FA8)]
              : const [Color(0xFF1565C0), Color(0xFF287ec3), Color(0xFF42A5F5)],
        ),
        border: isDark
            ? Border.all(color: kBlue.withValues(alpha: 0.30))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : kBlue.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Soft blobs echo the app's gradient header.
            Positioned(
              right: -30,
              top: -34,
              child: _Blob(size: 128, alpha: isDark ? 0.06 : 0.10),
            ),
            Positioned(
              left: -20,
              bottom: -30,
              child: _Blob(size: 74, alpha: isDark ? 0.05 : 0.08),
            ),
            Positioned(
              top: 0,
              left: 28,
              right: 28,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: isDark ? 0.25 : 0.50),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfileAvatar(
                        imageUrl: imageUrl,
                        displayName: displayName,
                        size: 74,
                        borderWidth: 3,
                        borderColor: Colors.white.withValues(alpha: 0.85),
                        badge: avatarBadge,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: kWhite.withValues(alpha: 0.78),
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (chips.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(spacing: 8, runSpacing: 8, children: chips),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    const SizedBox(height: 4),
                    footer!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;

  const _Blob({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Full-width tappable row rendered on the gradient hero.
class ProfileHeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ProfileHeroAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: kWhite.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: kWhite.withValues(alpha: 0.75),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One option inside a [ProfileSegmentedControl].
class ProfileSegment<T> {
  final T value;
  final String label;
  final IconData icon;

  const ProfileSegment({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Compact pill-shaped selector — replaces a row of large option cards.
class ProfileSegmentedControl<T> extends StatelessWidget {
  final List<ProfileSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  const ProfileSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.groupBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _Segment<T>(
                segment: segment,
                selected: segment.value == value,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  final ProfileSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? palette.cardFill : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.30 : 0.10,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  segment.icon,
                  size: 17,
                  color: selected ? palette.accent : palette.supporting,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? palette.accent : palette.supporting,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page heading shared by the profile surfaces: an optional back button, the
/// title, and an optional trailing action.
class ProfileTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const ProfileTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.profile.accent;

    return Row(
      children: [
        if (onBack != null) ...[
          _TopBarButton(
            icon: Icons.arrow_back_rounded,
            color: accent,
            onTap: onBack!,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionIcon != null && onAction != null)
          _TopBarButton(icon: actionIcon!, color: accent, onTap: onAction!),
      ],
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 28, color: color),
        ),
      ),
    );
  }
}

/// Small uppercase label that heads each group of cards.
class ProfileSectionLabel extends StatelessWidget {
  final String text;

  const ProfileSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: context.profile.sectionLabel,
      ),
    );
  }
}

/// Rounded container that groups related rows together.
class ProfileGroupCard extends StatelessWidget {
  final List<Widget> children;

  /// Gap inserted between children when [divided] is false.
  final double spacing;

  /// Separate rows with a hairline rule inset past the icon chip, rather than
  /// floating them apart. Reads as a tighter, more deliberate group.
  final bool divided;

  const ProfileGroupCard({
    super.key,
    required this.children,
    this.spacing = 6,
    this.divided = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: divided ? 4 : 10),
      decoration: BoxDecoration(
        color: palette.groupBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.shadowAlpha),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              divided
                  ? Divider(
                      height: 1,
                      thickness: 1,
                      indent: 70,
                      color: palette.hairline,
                    )
                  : SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

/// Square icon chip that leads a row.
class ProfileIconChip extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const ProfileIconChip({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;
    final tint = color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint == null ? palette.iconBg : tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: tint ?? palette.accent, size: size * 0.5),
    );
  }
}

/// Tappable row with an icon chip, title, subtitle and chevron.
class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? tint;

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ProfileIconChip(icon: icon, color: tint),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tint ?? palette.headline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.supporting,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.sectionLabel,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill used for role and status badges.
class ProfileChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const ProfileChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shell: floating rounded card with a grab handle and title.
class ProfileSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSheet({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = context.profile;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: palette.cardFill,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.22 : 0.08,
                ),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.col.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.headline,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
