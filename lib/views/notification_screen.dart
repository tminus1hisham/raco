import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/dashboard_controller.dart';
import 'package:atom/controllers/markAsRead_contoller.dart';
import 'package:atom/controllers/notifcations_controller.dart';
import 'package:atom/models/notifications_model.dart';
import 'package:atom/views/settings_screen.dart';
import 'package:atom/widgets/cards/notifications_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationsController _controller;
  late final MarkasreadController _markAsReadController;
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  DashboardController? get _dashboardControllerOrNull =>
      Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : null;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    _markAsReadController = Get.isRegistered<MarkasreadController>()
        ? Get.find<MarkasreadController>()
        : Get.put(MarkasreadController());
    _controller.fetchNotifications();
  }

  Future<void> _refreshNotifications() => _controller.fetchNotifications();

  Future<void> _markAllAsRead() async {
    final unreadIds = _controller.notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id.toString())
        .toList();

    if (unreadIds.isEmpty) return;

    final success = await _markAsReadController.markAsRead(context, unreadIds);
    if (!success) return;

    for (final notification in _controller.notifications) {
      notification.isRead = true;
    }
    _controller.notifications.refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        backgroundColor: kBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
      ),
    );
  }

  Future<void> _markOneAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final success = await _markAsReadController.markAsRead(context, [
      notification.id.toString(),
    ]);
    if (!success) return;

    notification.isRead = true;
    _controller.notifications.refresh();
  }

  void _handleBack() {
    final dashboard = _dashboardControllerOrNull;
    if (dashboard != null) {
      dashboard.setIndex(0);
      return;
    }
    Navigator.maybePop(context);
  }

  void _openSettings() {
    final dashboard = _dashboardControllerOrNull;
    if (dashboard != null) {
      dashboard.setIndex(2);
      return;
    }
    Get.to(() => SettingsScreen());
  }

  List<NotificationModel> _filteredNotifications() {
    final allItems = _controller.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    switch (_selectedFilter) {
      case _NotificationFilter.all:
        return allItems;
      case _NotificationFilter.unread:
        return allItems.where((notification) => !notification.isRead).toList();
      case _NotificationFilter.geofence:
        return allItems
            .where(
              (notification) => _matchesCategory(
                notification,
                _NotificationFilter.geofence,
              ),
            )
            .toList();
      case _NotificationFilter.battery:
        return allItems
            .where(
              (notification) => _matchesCategory(
                notification,
                _NotificationFilter.battery,
              ),
            )
            .toList();
      case _NotificationFilter.speed:
        return allItems
            .where(
              (notification) => _matchesCategory(
                notification,
                _NotificationFilter.speed,
              ),
            )
            .toList();
    }
  }

  bool _matchesCategory(
    NotificationModel notification,
    _NotificationFilter filter,
  ) {
    final haystack = '${notification.title} ${notification.message}'
        .toLowerCase();

    switch (filter) {
      case _NotificationFilter.geofence:
        return haystack.contains('geofence') ||
            haystack.contains('fence') ||
            haystack.contains('zone') ||
            haystack.contains('location');
      case _NotificationFilter.battery:
        return haystack.contains('battery') ||
            haystack.contains('power') ||
            haystack.contains('charging');
      case _NotificationFilter.speed:
        return haystack.contains('speed') ||
            haystack.contains('overspeed') ||
            haystack.contains('km/h') ||
            haystack.contains('kph');
      case _NotificationFilter.all:
      case _NotificationFilter.unread:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: _pageBackground(col),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _buildTopBar(col),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: _buildHero(col),
            ),
            const SizedBox(height: 18),
            _buildFilterRow(col),
            const SizedBox(height: 18),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return _buildLoadingState(col);
                }

                final items = _filteredNotifications();
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildFeed(
                    items,
                    col,
                    key: ValueKey(_selectedFilter),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _pageBackground(AppColors col) {
    return context.isDark ? col.bg : const Color(0xFFF5F4FE);
  }

  Color _titleColor(AppColors col) {
    return context.isDark ? col.textPrimary : const Color(0xFF1454C4);
  }

  Widget _buildTopBar(AppColors col) {
    final titleColor = context.isDark
        ? col.textPrimary
        : const Color(0xFF184FE2);

    return Row(
      children: [
        _TopIconButton(
          icon: Icons.arrow_back_rounded,
          color: titleColor,
          onTap: _handleBack,
        ),
        const SizedBox(width: 8),
        Text(
          'Alerts',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const Spacer(),
        _TopIconButton(
          icon: Icons.settings_rounded,
          color: titleColor,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _buildHero(AppColors col) {
    final eyebrowColor = context.isDark
        ? col.textSecondary
        : const Color(0xFF42558F);

    return Obx(() {
      final unreadCount = _controller.notifications
          .where((notification) => !notification.isRead)
          .length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLEET STATUS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.8,
              color: eyebrowColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Feed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: context.isDark
                            ? col.textPrimary
                            : const Color(0xFF15285D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unreadCount > 0
                          ? '$unreadCount alerts waiting for review'
                          : 'Everything has been acknowledged',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.isDark
                            ? col.textSecondary
                            : const Color(0xFF7180A8),
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    foregroundColor: _titleColor(col),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _titleColor(col),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildFilterRow(AppColors col) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _NotificationFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _NotificationFilter.values[index];
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? kBlue
                    : context.isDark
                    ? col.surface.withValues(alpha: 0.9)
                    : const Color(0xFFEEF1FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? kWhite
                        : context.isDark
                        ? col.textPrimary
                        : const Color(0xFF3E537F),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeed(
    List<NotificationModel> items,
    AppColors col, {
    Key? key,
  }) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: kBlue,
      displacement: 8,
      child: ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          if (items.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.36,
              child: _buildEmptyState(col),
            )
          else
            ...items.map(
              (notification) => NotificationCard(
                notification: notification,
                isRead: notification.isRead,
                onTap: () => _handleNotificationTap(notification),
              ),
            ),
          const SizedBox(height: 6),
          _buildRouteOverviewCard(col),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors col) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 42,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _selectedFilter.emptyTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.isDark ? col.textPrimary : const Color(0xFF15285D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter.emptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: col.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColors col) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      physics: const BouncingScrollPhysics(),
      children: [
        for (int i = 0; i < 4; i++) _buildSkeletonCard(col),
        _buildRouteSkeleton(col),
      ],
    );
  }

  Widget _buildSkeletonCard(AppColors col) {
    final cardColor = context.isDark ? col.surface : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(
            width: 68,
            height: 68,
            radius: 20,
            color: col.divider,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _shimmerBox(
                        width: double.infinity,
                        height: 18,
                        radius: 8,
                        color: col.divider,
                      ),
                    ),
                    const SizedBox(width: 18),
                    _shimmerBox(
                      width: 52,
                      height: 12,
                      radius: 6,
                      color: col.divider,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _shimmerBox(width: 150, height: 30, radius: 14, color: col.divider),
                const SizedBox(height: 12),
                _shimmerBox(
                  width: double.infinity,
                  height: 14,
                  radius: 6,
                  color: col.divider,
                ),
                const SizedBox(height: 8),
                _shimmerBox(
                  width: 210,
                  height: 14,
                  radius: 6,
                  color: col.divider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSkeleton(AppColors col) {
    return Container(
      height: 224,
      decoration: BoxDecoration(
        color: context.isDark ? col.surface : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildRouteOverviewCard(AppColors col) {
    return Container(
      height: 224,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.24 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: context.isDark
                        ? const [
                            Color(0xFF223247),
                            Color(0xFF1A324A),
                            Color(0xFF10253C),
                          ]
                        : const [
                            Color(0xFFF1ECD9),
                            Color(0xFFD9E6E1),
                            Color(0xFFB8CBDD),
                          ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePreviewPainter(isDark: context.isDark),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF17345F).withValues(alpha: 0.12),
                      const Color(0xFF17345F).withValues(alpha: 0.88),
                    ],
                    stops: const [0.18, 0.52, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 114,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Compliance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kWhite.withValues(alpha: 0.96),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All units currently following optimized paths.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: kWhite.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: kBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kBlue.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: kWhite,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailSheet(context, notification),
    );
    _markOneAsRead(notification);
  }

  Widget _buildDetailSheet(
    BuildContext context,
    NotificationModel notification,
  ) {
    final col = context.col;
    final meta = _resolveNotificationMeta(notification);
    final vehicleCode = _extractVehicleCode(notification);
    final secondaryDetail = _extractDetailLabel(notification, meta.kind);

    return DraggableScrollableSheet(
      initialChildSize: 0.64,
      minChildSize: 0.48,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.isDark ? col.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: col.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: meta.softColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: meta.color,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(meta.icon, color: kWhite, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: context.isDark
                                      ? col.textPrimary
                                      : const Color(0xFF15285D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRelativeTime(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: col.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (vehicleCode != null)
                          _DetailChip(
                            label: vehicleCode,
                            backgroundColor: context.isDark
                                ? meta.softColor
                                : const Color(0xFFE5E9FF),
                            textColor: context.isDark
                                ? col.textPrimary
                                : const Color(0xFF596AAB),
                          ),
                        _DetailChip(
                          label: secondaryDetail,
                          backgroundColor: meta.softColor,
                          textColor: meta.color,
                        ),
                        _DetailChip(
                          label: notification.isRead ? 'Read' : 'Unread',
                          backgroundColor: notification.isRead
                              ? const Color(0xFFE8F3EC)
                              : const Color(0xFFE7F0FF),
                          textColor: notification.isRead
                              ? const Color(0xFF157347)
                              : kBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.75,
                        color: context.isDark
                            ? col.textPrimary
                            : const Color(0xFF3A4D7B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Created by',
                      value: notification.createdByName.trim().isEmpty
                          ? 'Fleet system'
                          : notification.createdByName,
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.schedule_rounded,
                      label: 'Timestamp',
                      value: DateFormat(
                        'EEEE, MMM d, yyyy - h:mm a',
                      ).format(notification.createdAt.toLocal()),
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Notification ID',
                      value: '#${notification.id}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _NotificationMeta _resolveNotificationMeta(NotificationModel notification) {
    final haystack = '${notification.title} ${notification.message}'
        .toLowerCase();

    if (haystack.contains('speed') || haystack.contains('overspeed')) {
      return _NotificationMeta(
        kind: _NotificationKind.speed,
        icon: Icons.speed_rounded,
        color: const Color(0xFFC92D2D),
        softColor: const Color(0xFFFFEAEA),
      );
    }
    if (haystack.contains('geofence') ||
        haystack.contains('fence') ||
        haystack.contains('zone') ||
        haystack.contains('location')) {
      return _NotificationMeta(
        kind: _NotificationKind.geofence,
        icon: Icons.place_rounded,
        color: const Color(0xFF135FBF),
        softColor: const Color(0xFFEAF3FF),
      );
    }
    if (haystack.contains('battery') ||
        haystack.contains('power') ||
        haystack.contains('charging')) {
      return _NotificationMeta(
        kind: _NotificationKind.battery,
        icon: Icons.battery_alert_rounded,
        color: const Color(0xFF0B8E3A),
        softColor: const Color(0xFFEAF8EE),
      );
    }
    if (haystack.contains('system') ||
        haystack.contains('maintenance') ||
        haystack.contains('diagnostic') ||
        haystack.contains('check')) {
      return _NotificationMeta(
        kind: _NotificationKind.system,
        icon: Icons.build_rounded,
        color: const Color(0xFF0F6AA8),
        softColor: const Color(0xFFEAF4FB),
      );
    }

    return _NotificationMeta(
      kind: _NotificationKind.alert,
      icon: Icons.notifications_active_rounded,
      color: kBlue,
      softColor: const Color(0xFFEAF3FF),
    );
  }

  String? _extractVehicleCode(NotificationModel notification) {
    final haystack = '${notification.title} ${notification.message}'.toUpperCase();
    final match = RegExp(r'\b[A-Z]{1,4}[-\s]?\d{2,5}\b').firstMatch(haystack);
    if (match == null) return null;
    return match.group(0)?.replaceAll(' ', '-');
  }

  String _extractDetailLabel(
    NotificationModel notification,
    _NotificationKind kind,
  ) {
    final haystack = '${notification.title} ${notification.message}';
    final speedMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(km\/h|kmh|kph)',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (speedMatch != null) {
      return '${speedMatch.group(1)} Km/h';
    }

    final batteryMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*%',
      caseSensitive: false,
    ).firstMatch(haystack);
    if (batteryMatch != null) {
      return '${batteryMatch.group(1)}% Remaining';
    }

    if (kind == _NotificationKind.geofence) {
      return _extractLocation(notification.message) ?? 'Zone event';
    }
    if (kind == _NotificationKind.system) {
      return 'Scheduled';
    }
    if (kind == _NotificationKind.battery) {
      return 'Battery status';
    }
    if (kind == _NotificationKind.speed) {
      return 'Overspeed';
    }

    return 'Fleet alert';
  }

  String? _extractLocation(String message) {
    final match = RegExp(
      r'(?:at|in|to)\s+([A-Za-z0-9]+(?:\s+[A-Za-z0-9]+){0,3})',
      caseSensitive: false,
    ).firstMatch(message);

    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    return value.replaceAll(RegExp(r'[.,]$'), '');
  }

  String _formatRelativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp.toLocal());

    if (difference.inMinutes < 1) return 'JUST NOW';
    if (difference.inMinutes < 60) return '${difference.inMinutes}M AGO';
    if (difference.inHours < 24) return '${difference.inHours}H AGO';
    if (difference.inDays < 7) return '${difference.inDays}D AGO';
    return DateFormat('MMM d').format(timestamp.toLocal()).toUpperCase();
  }
}

enum _NotificationFilter { all, unread, geofence, battery, speed }

extension _NotificationFilterCopy on _NotificationFilter {
  String get label {
    switch (this) {
      case _NotificationFilter.all:
        return 'All';
      case _NotificationFilter.unread:
        return 'Unread';
      case _NotificationFilter.geofence:
        return 'Geofence';
      case _NotificationFilter.battery:
        return 'Battery';
      case _NotificationFilter.speed:
        return 'Speed';
    }
  }

  String get emptyTitle {
    switch (this) {
      case _NotificationFilter.all:
        return 'No notifications yet';
      case _NotificationFilter.unread:
        return 'All caught up';
      case _NotificationFilter.geofence:
        return 'No geofence alerts';
      case _NotificationFilter.battery:
        return 'No battery alerts';
      case _NotificationFilter.speed:
        return 'No speed alerts';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case _NotificationFilter.all:
        return 'Fresh alerts will show up here as soon as the fleet reports them.';
      case _NotificationFilter.unread:
        return 'Every alert in this feed has already been reviewed.';
      case _NotificationFilter.geofence:
        return 'There are no zone entry or exit events in this view right now.';
      case _NotificationFilter.battery:
        return 'Battery health looks stable across the fleet at the moment.';
      case _NotificationFilter.speed:
        return 'No overspeed events match the current filter.';
    }
  }
}

enum _NotificationKind { speed, geofence, battery, system, alert }

class _NotificationMeta {
  final _NotificationKind kind;
  final IconData icon;
  final Color color;
  final Color softColor;

  const _NotificationMeta({
    required this.kind,
    required this.icon,
    required this.color,
    required this.softColor,
  });
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopIconButton({
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
          child: Icon(icon, size: 26, color: color),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _DetailChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final surfaceColor = context.isDark
        ? col.bg.withValues(alpha: 0.65)
        : const Color(0xFFF5F7FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: col.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: col.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  final bool isDark;

  const _RoutePreviewPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFFFFFFFF)).withValues(
        alpha: isDark ? 0.10 : 0.28,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final roadPaintThin = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFFDEE5EA)).withValues(
        alpha: isDark ? 0.08 : 0.65,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final routeGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF132A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final horizontalRoads = <Path>[
      Path()
        ..moveTo(size.width * 0.02, size.height * 0.18)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.08,
          size.width * 0.55,
          size.height * 0.16,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          size.height * 0.24,
          size.width * 1.04,
          size.height * 0.13,
        ),
      Path()
        ..moveTo(size.width * -0.04, size.height * 0.38)
        ..quadraticBezierTo(
          size.width * 0.24,
          size.height * 0.28,
          size.width * 0.47,
          size.height * 0.42,
        )
        ..quadraticBezierTo(
          size.width * 0.73,
          size.height * 0.52,
          size.width * 1.06,
          size.height * 0.34,
        ),
      Path()
        ..moveTo(size.width * -0.03, size.height * 0.62)
        ..quadraticBezierTo(
          size.width * 0.30,
          size.height * 0.47,
          size.width * 0.56,
          size.height * 0.66,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.86,
          size.width * 1.04,
          size.height * 0.72,
        ),
    ];

    final verticalRoads = <Path>[
      Path()
        ..moveTo(size.width * 0.12, size.height * -0.02)
        ..quadraticBezierTo(
          size.width * 0.04,
          size.height * 0.26,
          size.width * 0.16,
          size.height * 0.54,
        )
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.82,
          size.width * 0.18,
          size.height * 1.04,
        ),
      Path()
        ..moveTo(size.width * 0.44, size.height * -0.03)
        ..quadraticBezierTo(
          size.width * 0.52,
          size.height * 0.27,
          size.width * 0.42,
          size.height * 0.50,
        )
        ..quadraticBezierTo(
          size.width * 0.34,
          size.height * 0.74,
          size.width * 0.48,
          size.height * 1.04,
        ),
      Path()
        ..moveTo(size.width * 0.78, size.height * -0.02)
        ..quadraticBezierTo(
          size.width * 0.68,
          size.height * 0.24,
          size.width * 0.82,
          size.height * 0.56,
        )
        ..quadraticBezierTo(
          size.width * 0.94,
          size.height * 0.82,
          size.width * 0.84,
          size.height * 1.06,
        ),
    ];

    for (final path in horizontalRoads) {
      canvas.drawPath(path, roadPaint);
    }
    for (final path in verticalRoads) {
      canvas.drawPath(path, roadPaintThin);
    }

    final routePath = Path()
      ..moveTo(size.width * 0.20, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.66,
        size.width * 0.47,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.60,
        size.height * 0.64,
        size.width * 0.72,
        size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.34,
        size.width * 0.86,
        size.height * 0.20,
      );

    canvas.drawPath(routePath, routeGlow);
    canvas.drawPath(routePath, routePaint);

    _drawMarker(
      canvas,
      Offset(size.width * 0.18, size.height * 0.58),
      const Color(0xFFE52A2A),
    );
    _drawMarker(
      canvas,
      Offset(size.width * 0.66, size.height * 0.57),
      const Color(0xFF114E96),
    );
    _drawMarker(
      canvas,
      Offset(size.width * 0.84, size.height * 0.18),
      const Color(0xFF114E96),
    );
  }

  void _drawMarker(Canvas canvas, Offset center, Color color) {
    final outer = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final inner = Paint()..color = color;
    canvas.drawCircle(center, 7, outer);
    canvas.drawCircle(center, 4, inner);
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
