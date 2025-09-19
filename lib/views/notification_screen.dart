import 'package:atom/config/constants.dart';
import 'package:atom/widgets/cards/notifications_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'New Message',
      message: 'You have received a new message from John Doe',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    NotificationItem(
      id: '2',
      title: 'Payment Successful',
      message: 'Your payment of \$99.99 has been processed successfully',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
    ),
    NotificationItem(
      id: '3',
      title: 'App Update Available',
      message: 'Version 2.1.0 is now available with new features and bug fixes',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
    ),
    NotificationItem(
      id: '4',
      title: 'Security Alert',
      message: 'New login detected from Chrome on Windows',
      timestamp: DateTime.now().subtract(Duration(days: 2)),
    ),
    NotificationItem(
      id: '5',
      title: 'Weekly Report',
      message: 'Your weekly activity report is ready to view',
      timestamp: DateTime.now().subtract(Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            customHeader(label: "Notifications", icon: Icons.notifications),
            const SizedBox(height: 10),
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return NotificationCard(
                          notification: notifications[index],
                          onTap: () =>
                              _handleNotificationTap(notifications[index]),
                          onDelete: () =>
                              _deleteNotification(notifications[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(NotificationItem notification) {
    setState(() {
      notifications.remove(notification);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
  }

  void _handleNotificationTap(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: kBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.notifications, color: kBlue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Divider(color: Colors.grey[200]),
                          const SizedBox(height: 20),

                          // Message
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
