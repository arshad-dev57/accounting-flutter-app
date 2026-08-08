import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:get/get.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      category: json['category'] ?? 'System',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

class NotificationController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  var notifications = <NotificationItem>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var unreadCount = 0.obs;

  var selectedFilter = 'All'.obs; // All, Unread, Important

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final unreadOnly = selectedFilter.value == 'Unread';

      final response = await _api.get(
        '/api/notifications',
        queryParameters: {'unreadOnly': unreadOnly.toString(), 'limit': '50'},
      );

      if (response.success) {
        final data = response.data;
        final List<dynamic> notificationsList = data is Map
            ? (data['data'] ?? [])
            : (data ?? []);
        notifications.value = notificationsList
            .map((item) => NotificationItem.fromJson(item))
            .toList();
      } else {
        hasError.value = true;
        errorMessage.value = response.message;
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load notifications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('/api/notifications/unread-count');

      if (response.success) {
        unreadCount.value = response.data['count'] ?? 0;
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.put('/api/notifications/$notificationId/read');

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updated = NotificationItem(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          type: notifications[index].type,
          category: notifications[index].category,
          isRead: true,
          createdAt: notifications[index].createdAt,
          readAt: DateTime.now(),
          data: notifications[index].data,
        );
        notifications[index] = updated;
      }

      // Update unread count
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.put('/api/notifications/mark-all-read');

      // Update local state
      notifications.value = notifications
          .map(
            (n) => NotificationItem(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              category: n.category,
              isRead: true,
              createdAt: n.createdAt,
              readAt: DateTime.now(),
              data: n.data,
            ),
          )
          .toList();

      unreadCount.value = 0;
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _api.delete('/api/notifications/$notificationId');

      // Remove from local state
      notifications.removeWhere((n) => n.id == notificationId);

      // Update unread count if it was unread
      loadUnreadCount();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    loadNotifications();
  }

  void refresh() {
    loadNotifications(refresh: true);
    loadUnreadCount();
  }
}
