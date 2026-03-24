import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

// ignore: camel_case_types
class customHeader extends StatefulWidget {
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
  State<customHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<customHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: false);
    _shimmerAnim = Tween<double>(begin: -1.6, end: 2.2).animate(
      CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // Light: vivid sky-blue sweep. Dark: deep navy card with blue horizon.
    final gradientColors = isDark
        ? [
            const Color(0xFF111827),
            const Color(0xFF1A3352),
            const Color(0xFF1D6FA8),
          ]
        : [
            const Color(0xFF1565C0),
            const Color(0xFF287ec3),
            const Color(0xFF42A5F5),
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpaceXL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusLG),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // In dark mode: subtle blue glow border so the card reads against
        // the #141720 scaffold instead of blending in.
        border: isDark
            ? Border.all(
                color: kBlue.withValues(alpha: 0.30),
                width: 1.0,
              )
            : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: kBlue.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusLG),
        child: AnimatedBuilder(
          animation: _shimmerAnim,
          builder: (context, child) {
            return Stack(
              children: [
                // ── Blob: large top-right ──────────────────────────
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withValues(alpha: isDark ? 0.06 : 0.10),
                    ),
                  ),
                ),
                // ── Blob: medium bottom-center ─────────────────────
                Positioned(
                  right: 64,
                  bottom: -30,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withValues(alpha: isDark ? 0.05 : 0.08),
                    ),
                  ),
                ),
                // ── Blob: small bottom-left ────────────────────────
                Positioned(
                  left: -8,
                  bottom: -16,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withValues(alpha: isDark ? 0.04 : 0.06),
                    ),
                  ),
                ),

                // ── Shimmer sweep ──────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnim.value - 0.6, -0.4),
                        end: Alignment(_shimmerAnim.value + 0.6, 0.4),
                        colors: [
                          Colors.transparent,
                          Colors.white
                              .withValues(alpha: isDark ? 0.08 : 0.13),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Top glass-edge highlight ───────────────────────
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  height: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(
                              alpha: isDark ? 0.25 : 0.50),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Left accent strip ──────────────────────────────
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  width: 3.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                          alpha: isDark ? 0.30 : 0.45),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────
                child!,
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                if (widget.showBackButton) ...[
                  _BackButton(onTap: widget.onPressed),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Color(0x44000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: kWhite.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _IconBadge(icon: widget.icon, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.white.withValues(alpha: 0.25),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kWhite,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _IconBadge({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? kBlue.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.20),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, color: kWhite, size: 26),
    );
  }
}
