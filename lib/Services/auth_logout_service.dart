import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/companyprofile/controller/profile_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// Clears OneSignal, tokens, and local session on logout / account delete.
class AuthLogoutService {
  static Future<void> clearPushSession() async {
    try {
      await NotificationService.instance.logout();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  /// Full local sign-out: push, permissions, API token, SharedPreferences.
  static Future<void> clearLocalSession() async {
    await clearPushSession();
    try {
      if (Get.isRegistered<PermissionService>()) {
        await PermissionService.to.clearUserData();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    try {
      if (Get.isRegistered<ApiClient>()) {
        await Get.find<ApiClient>().clearToken();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clearSession();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
