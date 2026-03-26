import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/markAsRead_contoller.dart';
import 'package:atom/controllers/notifcations_controller.dart';
import 'package:atom/models/notifications_model.dart';
import 'package:atom/widgets/cards/notifications_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final NotificationsController _controller = Get.put(NotificationsController());
  final MarkasreadController _markAsReadController = Get.put(MarkasreadController());

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final allIds = _controller.notifications
        .where((n) => !n.isRead)
        .map((n) => n.id.toString())
        .toList();

    if (allIds.isEmpty) return;

    final success = await _markAsReadController.markAsRead(context, allIds);

    if (success) {
      for (var n in _controller.notifications) {
        n.isRead = true;
      }
      _controller.notifications.refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("All notifications marked as read"),
            backgroundColor: kBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markOneAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final success = await _markAsReadController.markAsRead(
      context,
      [notification.id.toString()],
    );
    if (success) {
      notification.isRead = true;
      _controller.notifications.refresh();
    }
  }

  Map<String, List<NotificationModel>> _groupByDate(
      List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<NotificationModel>> grouped = {};

    for (var n in items) {
      final date = DateTime(
          n.createdAt.toLocal().year,
          n.createdAt.toLocal().month,
          n.createdAt.toLocal().day);
      String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else if (date.isAfter(weekAgo)) {
        key = 'This Week';
      } else {
        key = 'Earlier';
      }
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(col),
            _buildTabBar(col),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return _buildLoadingState(col);
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_controller.notifications.toList(), col),
                    _buildList(
                      _controller.notifications.where((n) => !n.isRead).toList(),
                      col,
                      emptyLabel: 'All caught up!',
                      emptySubtitle: 'No unread notifications',
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors col) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: col.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() {
                  final unread = _controller.notifications
                      .where((n) => !n.isRead)
                      .length;
                  return Text(
                    unread > 0 ? '$unread unread' : 'All caught up',
                    style: TextStyle(
                      fontSize: 13,
                      color: unread > 0 ? kBlue : col.textSecondary,
                      fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final hasUnread =
                _controller.notifications.any((n) => !n.isRead);
            return hasUnread
                ? TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 17),
                    label: const Text('Mark all read'),
                    style: TextButton.styleFrom(
                      foregroundColor: kBlue,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppColors col) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kBlue,
          borderRadius: BorderRadius.circular(kRadiusSM),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: kWhite,
        unselectedLabelColor: col.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          const Tab(text: 'All'),
          Tab(
            child: Obx(() {
              final unread =
                  _controller.notifications.where((n) => !n.isRead).length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unread'),
                  if (unread > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: kRed,
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<NotificationModel> items,
    AppColors col, {
    String emptyLabel = 'No notifications yet',
    String emptySubtitle = 'You\'re all caught up',
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _controller.fetchNotifications(),
        color: kBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildEmptyState(col, label: emptyLabel, subtitle: emptySubtitle),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByDate(items);

    return RefreshIndicator(
      onRefresh: () => _controller.fetchNotifications(),
      color: kBlue,
      child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: grouped.entries.fold<int>(
        0,
        (sum, entry) => sum + 1 + entry.value.length,
      ),
      itemBuilder: (context, index) {
        int cursor = 0;
        for (final entry in grouped.entries) {
          if (index == cursor) {
            return _buildDateHeader(entry.key, col);
          }
          cursor++;
          for (int i = 0; i < entry.value.length; i++) {
            if (index == cursor) {
              final notification = entry.value[i];
              return NotificationCard(
                notification: notification,
                isRead: notification.isRead,
                onTap: () => _handleNotificationTap(notification),
              );
            }
            cursor++;
          }
        }
        return const SizedBox.shrink();
      },
    ),
    );
  }

  Widget _buildDateHeader(String label, AppColors col) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: col.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppColors col) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: 6,
      itemBuilder: (_, __) => _buildSkeletonCard(col),
    );
  }

  Widget _buildSkeletonCard(AppColors col) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpaceMD),
      padding: const EdgeInsets.all(kSpaceLG),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(col, width: 44, height: 44, radius: kRadiusMD),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(col, width: 160, height: 14, radius: 4),
                const SizedBox(height: 8),
                _shimmerBox(col, width: double.infinity, height: 12, radius: 4),
                const SizedBox(height: 6),
                _shimmerBox(col, width: 120, height: 12, radius: 4),
                const SizedBox(height: 8),
                _shimmerBox(col, width: 80, height: 10, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
    AppColors col, {
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: col.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmptyState(AppColors col,
      {required String label, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 44,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: col.textSecondary),
          ),
        ],
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
      BuildContext context, NotificationModel notification) {
    final col = context.col;
    final meta = _resolveNotificationMeta(notification.title);

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: icon + close
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(kRadiusMD),
                            ),
                            child: Icon(meta.icon, color: meta.color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: col.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'From ${notification.createdByName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: col.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: col.bg,
                                borderRadius: BorderRadius.circular(kRadiusSM),
                              ),
                              child: Icon(Icons.close_rounded,
                                  color: col.textSecondary, size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: col.divider, height: 1),
                      const SizedBox(height: 20),

                      // Message body
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: col.textPrimary,
                          height: 1.65,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Metadata row
                      Container(
                        padding: const EdgeInsets.all(kSpaceLG),
                        decoration: BoxDecoration(
                          color: col.bg,
                          borderRadius: BorderRadius.circular(kRadiusMD),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: col.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy • h:mm a')
                                  .format(notification.createdAt.toLocal()),
                              style: TextStyle(
                                  fontSize: 13, color: col.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _NotificationMeta _resolveNotificationMeta(String title) {
    final t = title.toLowerCase();
    if (t.contains('speed') || t.contains('overspeed')) {
      return _NotificationMeta(
          Icons.speed_rounded, const Color(0xFFF97316));
    }
    if (t.contains('geofence') || t.contains('fence')) {
      return _NotificationMeta(Icons.my_location_rounded, kBlue);
    }
    if (t.contains('engine') || t.contains('ignition')) {
      return _NotificationMeta(
          Icons.power_settings_new_rounded, const Color(0xFF10B981));
    }
    if (t.contains('alert') ||
        t.contains('warning') ||
        t.contains('violation')) {
      return _NotificationMeta(
          Icons.warning_amber_rounded, const Color(0xFFEF4444));
    }
    return _NotificationMeta(Icons.notifications_rounded, kBlue);
  }
}

class _NotificationMeta {
  final IconData icon;
  final Color color;
  const _NotificationMeta(this.icon, this.color);
}
