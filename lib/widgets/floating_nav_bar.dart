import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../config/constants.dart';

class NavBarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const NavBarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Floating pill navigation bar.
///
/// Sits inset from the screen edges rather than docked to them, and marks the
/// active destination with a gradient pill that expands to reveal its label.
/// Inactive destinations collapse to their icon alone.
class FloatingNavBar extends StatelessWidget {
  final List<NavBarItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  static const _activeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FA3E3), kBlue],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.col.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE4E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < items.length; i++)
                  Flexible(child: _buildItem(context, i, items[i])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, NavBarItemData item) {
    final selected = index == selectedIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: selected ? _activeGradient : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context, item, selected),
            Flexible(
              child: ClipRect(
                child: AnimatedAlign(
                  duration: _duration,
                  curve: _curve,
                  alignment: Alignment.centerLeft,
                  // widthFactor animates the label open; heightFactor must be
                  // pinned to 1 or the Align expands to fill the bounded height
                  // it is given and stretches the whole bar.
                  widthFactor: selected ? 1.0 : 0.0,
                  heightFactor: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      item.label,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, NavBarItemData item, bool selected) {
    Widget icon = Icon(
      selected ? item.activeIcon : item.icon,
      size: 24,
      color: selected ? kWhite : context.col.textSecondary,
    );

    if (item.badgeCount > 0) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: kRed,
                borderRadius: BorderRadius.circular(10),
                // Ring matches whatever sits behind the badge so the count
                // stays legible on both the plain bar and the active pill.
                border: Border.all(
                  color: selected ? kWhite : context.col.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedScale(
      scale: selected ? 1.08 : 1.0,
      duration: _duration,
      curve: Curves.easeOutBack,
      child: icon,
    );
  }
}
