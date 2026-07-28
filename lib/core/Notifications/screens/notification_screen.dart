// screens/notification_screen.dart - Professional Notification Screen

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/Notifications/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(NotificationController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: Obx(() => _controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _controller.hasError.value
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: kDanger),
                            const SizedBox(height: 16),
                            Text(
                              _controller.errorMessage.value,
                              textAlign: TextAlign.center,
                              style:  TextStyle(color: kSubText),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _controller.refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildNotificationList()),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stay updated with your activities',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => _controller.unreadCount.value > 0
                      ? GestureDetector(
                          onTap: () => _controller.markAllAsRead(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Mark all read',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black.withOpacity(0.75),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Obx(() => Row(
                children: [
                  _buildFilterTab('All', _controller.selectedFilter.value == 'All'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Unread', _controller.selectedFilter.value == 'Unread'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Important', _controller.selectedFilter.value == 'Important'),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _controller.setFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotificationList() {
    return Obx(() {
      if (_controller.notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: kSubText.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: kSubText.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up!',
                style: TextStyle(
                  fontSize: 14,
                  color: kSubText.withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => _controller.refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = _controller.notifications[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotificationCard(notification),
            );
          },
        ),
      );
    });
  }

  Widget _buildNotificationCard(dynamic notification) {
    final isUnread = !notification.isRead;
    final category = notification.category;
    final time = notification.timeAgo;
    
    IconData icon;
    Color color;
    
    switch (notification.type) {
      case 'success':
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF4CAF50);
        break;
      case 'warning':
        icon = Icons.warning_rounded;
        color = const Color(0xFFFF9800);
        break;
      case 'error':
        icon = Icons.error_rounded;
        color = const Color(0xFFF44336);
        break;
      default:
        icon = Icons.info_rounded;
        color = const Color(0xFF2196F3);
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? kPrimary.withOpacity(0.05) : kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? kPrimary.withOpacity(0.2)
              : Colors.grey.withOpacity(0.15),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.markAsRead(notification.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kText,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: kSubText,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: kSubText.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: kSubText.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildCategoryBadge(category),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    switch (category) {
      case 'System':
        color = kPrimary;
        break;
      case 'Finance':
        color = kSuccess;
        break;
      case 'Alert':
        color = kDanger;
        break;
      default:
        color = kWarning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
