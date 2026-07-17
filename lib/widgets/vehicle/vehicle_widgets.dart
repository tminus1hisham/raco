import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/utils/signal_tier.dart';
import 'package:flutter/material.dart';

/// Presentation building blocks for the vehicle surfaces.
///
/// These run softer corners and deeper, lower-alpha shadows than the app
/// defaults so the vehicle pages read as the product's centrepiece. Colours
/// resolve from [AppColors] rather than a page-local palette, so a vehicle page
/// sits in the same tonal range as the car list it opens from.

const _kRadiusHero = 28.0;
const _kRadiusCard = 24.0;
const _kRadiusTile = 22.0;
const _kRadiusChip = 14.0;

/// Leading icon chip width + its trailing gap + the group's horizontal padding.
/// Row dividers inset by this so they start under the title, not the chip.
const _kRowDividerIndent = 70.0;

// ─── Section label ─────────────────────────────────────────────────────────

/// Small uppercase label that heads a group of cards.
class VehicleSectionLabel extends StatelessWidget {
  const VehicleSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: context.col.textSecondary,
      ),
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────

/// Gradient identity card that heads the vehicle page: the vehicle's name, its
/// live connection state, its two live telemetry readings, and its last known
/// position as a tappable footer.
class VehicleHeroCard extends StatelessWidget {
  const VehicleHeroCard({
    super.key,
    required this.model,
    required this.make,
    required this.isOnline,
    required this.speedKph,
    required this.signalTier,
    required this.location,
    this.onLocationTap,
  });

  final String model;
  final String make;
  final bool isOnline;
  final double speedKph;
  final SignalTier signalTier;
  final String location;

  /// Null leaves the footer inert — used when there is no position to open.
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kRadiusHero),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF111827), Color(0xFF1A3352), Color(0xFF1D6FA8)]
              : const [Color(0xFF1565C0), kBlue, Color(0xFF42A5F5)],
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
        borderRadius: BorderRadius.circular(_kRadiusHero),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -40,
              child: _Blob(size: 140, alpha: isDark ? 0.06 : 0.10),
            ),
            Positioned(
              left: -24,
              bottom: -34,
              child: _Blob(size: 84, alpha: isDark ? 0.05 : 0.08),
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _identity(),
                  const SizedBox(height: 20),
                  _telemetry(),
                  const SizedBox(height: 14),
                  _hairline(),
                  const SizedBox(height: 4),
                  _VehicleHeroLocation(
                    location: location,
                    onTap: onLocationTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: kWhite.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kWhite.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: kWhite,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                make.trim().isNotEmpty ? make : 'Tracked vehicle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kWhite.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _LivePill(isOnline: isOnline),
      ],
    );
  }

  Widget _telemetry() {
    final String speedCaption;
    if (!isOnline) {
      speedCaption = 'No signal';
    } else if (speedKph > 0) {
      speedCaption = 'In motion';
    } else {
      speedCaption = 'Stationary';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _HeroMetric(
              label: 'Speed',
              caption: speedCaption,
              value: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    speedKph.round().toString(),
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'km/h',
                    style: TextStyle(
                      color: kWhite.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: kWhite.withValues(alpha: 0.16)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _HeroMetric(
                label: 'Signal',
                caption: isOnline ? 'Live connection' : 'Last known reading',
                value: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _SignalBars(tier: signalTier, isOnline: isOnline),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        isOnline ? signalTier.label : 'Offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hairline() => Container(
    height: 1,
    color: kWhite.withValues(alpha: 0.16),
  );
}

/// One label / value / caption stack inside the hero. The value sits in a fixed
/// band so metrics of different type sizes still share a baseline grid.
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final Widget value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: kWhite.withValues(alpha: 0.62),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: Align(alignment: Alignment.bottomLeft, child: value),
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: kWhite.withValues(alpha: 0.60),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VehicleHeroLocation extends StatelessWidget {
  const _VehicleHeroLocation({required this.location, required this.onTap});

  final String location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.location_on_rounded,
              color: kWhite.withValues(alpha: 0.85),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: kWhite.withValues(alpha: 0.75),
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRadiusChip),
        splashColor: kWhite.withValues(alpha: 0.12),
        child: row,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});

  final double size;
  final double alpha;

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

// ─── Live state ────────────────────────────────────────────────────────────

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? kSuccessGreen : const Color(0xFFFFC857);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
      decoration: BoxDecoration(
        color: kWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kWhite.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, animate: isOnline),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'LIVE' : 'OFFLINE',
            style: const TextStyle(
              color: kWhite,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status dot that emits a slow expanding ring while the device is reporting.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Built eagerly rather than lazily: an offline dot never animates, and a
    // lazy controller would first be constructed by dispose(), which builds a
    // Ticker while the element is being torn down.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = 7.0;
    const ring = 16.0;

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.animate)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeOut.transform(_controller.value);
                final size = dot + (ring - dot) * t;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                  ),
                );
              },
            ),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bars lit for [tier] on a four-bar meter, strongest tier lighting all four.
///
/// [SignalTier] declares its strongest tier first, so rank counts down from the
/// end of the enum rather than up from its index.
int signalBarsLit(SignalTier tier) => SignalTier.values.length - tier.index;

/// Four-bar signal meter. Bars fill to the tier's rank; offline reads empty.
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.tier, required this.isOnline});

  final SignalTier tier;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final filled = isOnline ? signalBarsLit(tier) : 0;
    const heights = [7.0, 10.0, 13.0, 16.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < heights.length; i++) ...[
          if (i > 0) const SizedBox(width: 2.5),
          Container(
            width: 3,
            height: heights[i],
            decoration: BoxDecoration(
              color: i < filled ? kWhite : kWhite.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Alert banner ──────────────────────────────────────────────────────────

/// Inline alert for a vehicle-level problem that has a single fix, e.g. an
/// expired certificate. Surfaces the problem next to the hero rather than
/// leaving it to be discovered at the bottom of a list.
class VehicleAlertBanner extends StatelessWidget {
  const VehicleAlertBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.color = kRed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: isDark ? 0.14 : 0.07),
          col.surface,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: col.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: col.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              backgroundColor: color,
              foregroundColor: kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Engine control ────────────────────────────────────────────────────────

/// The one consequential control on the vehicle page, so it carries its state
/// in the surface tint rather than in a chip elsewhere on the page.
class VehicleEngineCard extends StatelessWidget {
  const VehicleEngineCard({
    super.key,
    required this.isEngineOn,
    required this.isBusy,
    required this.onChanged,
  });

  final bool isEngineOn;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    final state = isEngineOn ? kSuccessGreen : kRed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          state.withValues(alpha: isDark ? 0.10 : 0.05),
          col.surface,
        ),
        borderRadius: BorderRadius.circular(_kRadiusCard),
        border: Border.all(color: state.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: state.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(_kRadiusChip),
              border: Border.all(color: state.withValues(alpha: 0.22)),
            ),
            child: Icon(
              isEngineOn ? Icons.power_rounded : Icons.power_off_rounded,
              color: state,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Engine Control',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: col.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isEngineOn ? 'Running' : 'Immobilized',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: state,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(
              child: isBusy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: state,
                      ),
                    )
                  : Switch(
                      value: isEngineOn,
                      activeThumbColor: kSuccessGreen,
                      activeTrackColor: kSuccessGreen.withValues(alpha: 0.35),
                      inactiveThumbColor: kRed,
                      inactiveTrackColor: kRed.withValues(alpha: 0.25),
                      onChanged: onChanged,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ─────────────────────────────────────────────────────────

/// Grid tile for a high-traffic destination. Sizes to its parent so paired
/// tiles share a height even when their descriptions wrap differently.
class VehicleQuickAction extends StatefulWidget {
  const VehicleQuickAction({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<VehicleQuickAction> createState() => _VehicleQuickActionState();
}

class _VehicleQuickActionState extends State<VehicleQuickAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.description}',
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: col.surface,
          borderRadius: BorderRadius.circular(_kRadiusTile),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            splashColor: widget.color.withValues(alpha: 0.10),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadiusTile),
                border: Border.all(
                  color: isDark
                      ? col.border.withValues(alpha: 0.6)
                      : widget.color.withValues(alpha: 0.14),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(_kRadiusChip),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 21),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: col.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays quick actions out two-up, keeping each row's tiles equal in height.
class VehicleQuickActionGrid extends StatelessWidget {
  const VehicleQuickActionGrid({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final rows = <Widget>[];

    for (int i = 0; i < actions.length; i += 2) {
      final hasSecond = i + 1 < actions.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: actions[i]),
              const SizedBox(width: gap),
              Expanded(child: hasSecond ? actions[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < actions.length) rows.add(const SizedBox(height: gap));
    }

    return Column(children: rows);
  }
}

// ─── Grouped rows ──────────────────────────────────────────────────────────

/// Rounded container that groups related rows behind one surface.
class VehicleGroupCard extends StatelessWidget {
  const VehicleGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(_kRadiusCard),
        border: Border.all(color: col.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: _kRowDividerIndent,
                color: col.divider,
              ),
          ],
        ],
      ),
    );
  }
}

/// Tappable row inside a [VehicleGroupCard].
class VehicleActionTile extends StatelessWidget {
  const VehicleActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tint = kBlue,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color tint;

  /// Optional status pill shown before the chevron.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(_kRadiusChip),
                  border: Border.all(color: tint.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: col.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: col.textSecondary.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status pill, e.g. the "Expired" marker on the certificate row.
class VehicleStatusBadge extends StatelessWidget {
  const VehicleStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
