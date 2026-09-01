import 'package:flutter/foundation.dart' show kIsWeb;

import 'notification_Service.dart';

/// Clears notification stream + tray on logout.
class AuthLogoutService {
  static Future<void> clearPushSession() async {
    if (kIsWeb) return;
    try {
      await NotificationService.instance.logout();
    } catch (e) {
      print('⚠️ [AuthLogoutService] clearPushSession: $e');
    }
  }
}
