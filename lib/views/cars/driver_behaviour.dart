import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/models/driver_behaviour_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverBehaviour extends StatefulWidget {
  final String? serialNo;
  final String? vehiclePlate;

  const DriverBehaviour({super.key, this.serialNo, this.vehiclePlate});

  @override
  State<DriverBehaviour> createState() => _DriverBehaviourState();
}

class _DriverBehaviourState extends State<DriverBehaviour> {
  _ReportPeriod _period = _ReportPeriod.today;
  DriverBehaviourReport? _report;
  String? _error;
  bool _loading = false;
  int _requestId = 0;

  bool get _hasVehicle => widget.serialNo?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasVehicle) _loadReport();
  }

  Future<void> _loadReport() async {
    if (!_hasVehicle) return;
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await ApiService.fetchDriverBehaviour(
        serialNo: widget.serialNo!,
        reportType: _period.apiValue,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() => _report = report);
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _report = null;
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectPeriod(_ReportPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _report = null;
      _error = null;
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            customHeader(
              label: 'Driver Behaviour',
              icon: Icons.shield_outlined,
              showBackButton: true,
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: !_hasVehicle
                  ? _MissingVehicleState(col: col)
                  : RefreshIndicator(
                      color: kBlue,
                      onRefresh: _loadReport,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                        children: [
                          _VehicleStrip(
                            col: col,
                            plate: widget.vehiclePlate,
                            serialNo: widget.serialNo!,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Report period',
                            style: TextStyle(
                              color: col.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _PeriodPicker(
                            col: col,
                            selected: _period,
                            onSelected: _selectPeriod,
                          ),
                          const SizedBox(height: 18),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildContent(col),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppColors col) {
    if (_loading && _report == null) {
      return _LoadingReport(key: ValueKey('loading-${_period.apiValue}'), col: col);
    }
    if (_error != null) {
      return _ErrorReport(
        key: ValueKey('error-${_period.apiValue}'),
        col: col,
        message: _error!,
        onRetry: _loadReport,
      );
    }

    final report = _report;
    if (report == null || !report.hasData) {
      return _EmptyReport(
        key: ValueKey('empty-${_period.apiValue}'),
        col: col,
        period: _period.label.toLowerCase(),
      );
    }

    return _ReportContent(
      key: ValueKey('report-${_period.apiValue}'),
      col: col,
      report: report,
      period: _period,
      refreshing: _loading,
    );
  }
}

enum _ReportPeriod {
  today('Today', 'Today'),
  yesterday('Yesterday', 'Yesterday'),
  thisWeek('This week', 'ThisWeek'),
  thisMonth('This month', 'ThisMonth'),
  thisYear('This year', 'ThisYear');

  final String label;
  final String apiValue;

  const _ReportPeriod(this.label, this.apiValue);
}

class _VehicleStrip extends StatelessWidget {
  final AppColors col;
  final String? plate;
  final String serialNo;

  const _VehicleStrip({
    required this.col,
    required this.plate,
    required this.serialNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: col.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, color: kBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate?.trim().isNotEmpty == true ? plate! : 'Selected vehicle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Device $serialNo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kSuccessGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SAFETY',
              style: TextStyle(
                color: kSuccessGreen,
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  final AppColors col;
  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onSelected;

  const _PeriodPicker({
    required this.col,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ReportPeriod.values.map((period) {
          final active = period == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey('period-${period.apiValue}'),
              label: Text(period.label),
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onSelected(period),
              selectedColor: kBlue,
              backgroundColor: col.surface,
              side: BorderSide(
                color: active ? kBlue : col.border.withValues(alpha: 0.55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                color: active ? kWhite : col.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final AppColors col;
  final DriverBehaviourReport report;
  final _ReportPeriod period;
  final bool refreshing;

  const _ReportContent({
    super.key,
    required this.col,
    required this.report,
    required this.period,
    required this.refreshing,
  });

  @override
  Widget build(BuildContext context) {
    final score = report.safetyScore?.clamp(0, 100).toDouble();
    final accent = _scoreColor(score, report.totalEvents);
    final rating =
        report.rating ??
        (score != null
            ? _scoreLabel(score)
            : report.totalEvents == 0
            ? 'No risky events'
            : 'Driving attention needed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? const [Color(0xFF1B3551), Color(0xFF15283D)]
                      : const [Color(0xFF0D4D80), Color(0xFF287EC3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _ScoreDial(
                    score: score,
                    eventCount: report.totalEvents,
                    color: accent,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${period.label} driving overview',
                          style: TextStyle(
                            color: kWhite.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kWhite.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Live telematics report',
                            style: const TextStyle(
                              color: kWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (refreshing)
              const Positioned(
                right: 16,
                top: 16,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: kWhite,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          col: col,
          title: 'Risk events',
          subtitle: 'Incidents recorded for ${period.label.toLowerCase()}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RiskMetric(
                col: col,
                icon: Icons.speed_rounded,
                color: kRed,
                value: report.overspeedEvents,
                label: 'Overspeed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RiskMetric(
                col: col,
                icon: Icons.crisis_alert_rounded,
                color: const Color(0xFF7C3AED),
                value: report.recklessDrivingEvents,
                label: 'Reckless driving',
              ),
            ),
          ],
        ),
        if (report.hasTripData) ...[
          const SizedBox(height: 24),
          _SectionTitle(
            col: col,
            title: 'Trip performance',
            subtitle: 'Movement and speed at a glance',
          ),
          const SizedBox(height: 12),
          _TripStats(col: col, report: report),
        ],
        if (report.totalEvents > 0) ...[
          const SizedBox(height: 24),
          _SectionTitle(
            col: col,
            title: 'Risk distribution',
            subtitle: 'Share of recorded driving incidents',
          ),
          const SizedBox(height: 12),
          _RiskDistribution(col: col, report: report),
        ],
        if (report.events.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(
            col: col,
            title: 'Recent events',
            subtitle: '${report.events.length} event records returned',
          ),
          const SizedBox(height: 12),
          _EventList(col: col, events: report.events),
        ],
      ],
    );
  }

  Color _scoreColor(double? score, int eventCount) {
    if (score == null) return eventCount == 0 ? kSuccessGreen : kRed;
    if (score <= 40) return kRed;
    if (score <= 70) return const Color(0xFF7C3AED);
    return kSuccessGreen;
  }

  String _scoreLabel(double? score) {
    if (score == null) return 'Driving summary';
    if (score >= 80) return 'Excellent driving';
    if (score >= 60) return 'Needs attention';
    return 'High risk';
  }
}

class _ScoreDial extends StatelessWidget {
  final double? score;
  final int eventCount;
  final Color color;

  const _ScoreDial({
    required this.score,
    required this.eventCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (score ?? 0) / 100;
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score == null ? 1 : progress,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: kWhite.withValues(alpha: 0.13),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score == null
                    ? eventCount.toString()
                    : score!.round().toString(),
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                score == null ? 'RISK EVENTS' : 'SAFETY SCORE',
                style: TextStyle(
                  color: kWhite.withValues(alpha: 0.7),
                  fontSize: 8,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskMetric extends StatelessWidget {
  final AppColors col;
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _RiskMetric({
    required this.col,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 13),
          Text(
            value.toString(),
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: col.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStats extends StatelessWidget {
  final AppColors col;
  final DriverBehaviourReport report;

  const _TripStats({required this.col, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: col.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _TripStat(
            col: col,
            icon: Icons.route_rounded,
            value: _number(report.distanceKm),
            unit: 'km',
            label: 'Distance',
          ),
          _Divider(col: col),
          _TripStat(
            col: col,
            icon: Icons.av_timer_rounded,
            value: _number(report.averageSpeed),
            unit: 'km/h',
            label: 'Avg speed',
          ),
          _Divider(col: col),
          _TripStat(
            col: col,
            icon: Icons.speed_rounded,
            value: _number(report.topSpeed),
            unit: 'km/h',
            label: 'Top speed',
          ),
        ],
      ),
    );
  }

  String _number(double? value) {
    if (value == null) return '--';
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}

class _TripStat extends StatelessWidget {
  final AppColors col;
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _TripStat({
    required this.col,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: kBlue, size: 19),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                text: value,
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: value == '--' ? '' : ' $unit',
                    style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: col.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppColors col;

  const _Divider({required this.col});

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    color: col.divider,
  );
}

class _RiskDistribution extends StatelessWidget {
  final AppColors col;
  final DriverBehaviourReport report;

  const _RiskDistribution({required this.col, required this.report});

  @override
  Widget build(BuildContext context) {
    final denominator = report.totalEvents <= 0 ? 1 : report.totalEvents;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: col.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _DistributionRow(
            col: col,
            label: 'Overspeed',
            count: report.overspeedEvents,
            progress: report.overspeedEvents / denominator,
            color: kRed,
          ),
          const SizedBox(height: 16),
          _DistributionRow(
            col: col,
            label: 'Reckless driving',
            count: report.recklessDrivingEvents,
            progress: report.recklessDrivingEvents / denominator,
            color: const Color(0xFF7C3AED),
          ),
          if (report.harshBrakingEvents > 0) ...[
            const SizedBox(height: 16),
            _DistributionRow(
              col: col,
              label: 'Harsh braking',
              count: report.harshBrakingEvents,
              progress: report.harshBrakingEvents / denominator,
              color: const Color(0xFFF59E0B),
            ),
          ],
          if (report.rapidAccelerationEvents > 0) ...[
            const SizedBox(height: 16),
            _DistributionRow(
              col: col,
              label: 'Rapid acceleration',
              count: report.rapidAccelerationEvents,
              progress: report.rapidAccelerationEvents / denominator,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final AppColors col;
  final String label;
  final int count;
  final double progress;
  final Color color;

  const _DistributionRow({
    required this.col,
    required this.label,
    required this.count,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            minHeight: 7,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _EventList extends StatelessWidget {
  final AppColors col;
  final List<DriverBehaviourEvent> events;

  const _EventList({required this.col, required this.events});

  @override
  Widget build(BuildContext context) {
    final visibleEvents = events.take(10).toList();
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: col.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < visibleEvents.length; index++) ...[
            _EventTile(col: col, event: visibleEvents[index]),
            if (index != visibleEvents.length - 1)
              Divider(height: 1, indent: 64, color: col.divider),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AppColors col;
  final DriverBehaviourEvent event;

  const _EventTile({required this.col, required this.event});

  @override
  Widget build(BuildContext context) {
    final visual = _eventVisual(event.kind);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: visual.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eventSubtitle(event),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          if (event.speed != null)
            Text(
              '${event.speed!.round()} km/h',
              style: TextStyle(
                color: visual.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  String _eventSubtitle(DriverBehaviourEvent event) {
    final values = <String>[];
    final parsed = DateTime.tryParse(event.occurredAt ?? '');
    if (parsed != null) {
      values.add(DateFormat('d MMM, HH:mm').format(parsed.toLocal()));
    }
    if (event.location?.trim().isNotEmpty == true) values.add(event.location!);
    return values.isEmpty ? 'Event details unavailable' : values.join('  •  ');
  }

  _EventVisual _eventVisual(DriverEventKind kind) {
    switch (kind) {
      case DriverEventKind.overspeed:
        return const _EventVisual(Icons.speed_rounded, kRed);
      case DriverEventKind.reckless:
        return const _EventVisual(
          Icons.crisis_alert_rounded,
          Color(0xFF7C3AED),
        );
      case DriverEventKind.harshBraking:
        return const _EventVisual(
          Icons.warning_amber_rounded,
          Color(0xFFF59E0B),
        );
      case DriverEventKind.rapidAcceleration:
        return const _EventVisual(
          Icons.trending_up_rounded,
          Color(0xFF7C3AED),
        );
      case DriverEventKind.other:
        return const _EventVisual(Icons.info_outline_rounded, kBlue);
    }
  }
}

class _EventVisual {
  final IconData icon;
  final Color color;

  const _EventVisual(this.icon, this.color);
}

class _SectionTitle extends StatelessWidget {
  final AppColors col;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.col,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: col.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: col.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _LoadingReport extends StatelessWidget {
  final AppColors col;

  const _LoadingReport({super.key, required this.col});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kBlue, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Building your safety report…',
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Reviewing the selected vehicle activity',
            style: TextStyle(color: col.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ErrorReport extends StatelessWidget {
  final AppColors col;
  final String message;
  final VoidCallback onRetry;

  const _ErrorReport({
    super.key,
    required this.col,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      col: col,
      icon: Icons.cloud_off_rounded,
      color: kRed,
      title: 'Could not load this report',
      message: message,
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 17),
        label: const Text('Try again'),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  final AppColors col;
  final String period;

  const _EmptyReport({super.key, required this.col, required this.period});

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      col: col,
      icon: Icons.fact_check_outlined,
      color: kSuccessGreen,
      title: 'No driving data found',
      message: 'There is no driver behaviour activity for $period yet.',
    );
  }
}

class _MissingVehicleState extends StatelessWidget {
  final AppColors col;

  const _MissingVehicleState({required this.col});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _MessageCard(
          col: col,
          icon: Icons.directions_car_outlined,
          color: kBlue,
          title: 'Choose a vehicle first',
          message:
              'Open Driver Behaviour from a vehicle to view its safety report.',
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AppColors col;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;

  const _MessageCard({
    required this.col,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: col.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}
