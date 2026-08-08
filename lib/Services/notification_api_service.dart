import 'dart:convert';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:http/http.dart' as http;

class NotificationApi {
  static Future<Map<String, dynamic>> sendLoginSuccessPush({
    required String userId,
    String? subscriptionId,
    String title = "Login Successful",
    String message = "Welcome back to Templink ✅",
  }) async {
    print('🔔🔔🔔 [NotificationApi] SEND PUSH START 🔔🔔🔔');
    final uri = Uri.parse("${Apiconfig().baseUrl}/api/notifications/send");

    print('🔔 [NotificationApi] Sending Login Push');
    print('🔔 [NotificationApi] URL: $uri');
    print('🔔 [NotificationApi] UserId: $userId');
    print('🔔 [NotificationApi] SubscriptionId: $subscriptionId');
    print('🔔 [NotificationApi] Title: $title');
    print('🔔 [NotificationApi] Message: $message');

    final body = {
      "userId": userId,
      "subscriptionId": subscriptionId,
      "title": title,
      "message": message,
      "data": {"type": "auth", "screen": "home"},
    };

    print('🔔 [NotificationApi] Request Body: ${jsonEncode(body)}');

    try {
      print('🔔 [NotificationApi] Sending HTTP POST request...');
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print('🔔 [NotificationApi] Response received');
      print('🔔 [NotificationApi] Response Status: ${res.statusCode}');
      print('🔔 [NotificationApi] Response Body: ${res.body}');

      Map<String, dynamic> responseData = {};
      try {
        if (res.body.isNotEmpty) {
          print('🔔 [NotificationApi] Parsing response JSON...');
          responseData = jsonDecode(res.body);
          print('🔔 [NotificationApi] Parsed data: $responseData');
        }
      } catch (e) {
        print('❌ [NotificationApi] Response parsing error: $e');
        return {
          'success': false,
          'error': 'Failed to parse response',
          'status': 'error',
        };
      }

      if (responseData['result'] != null &&
          responseData['result']['errors'] != null &&
          responseData['result']['errors'].toString().contains(
            "not subscribed",
          )) {
        print('⚠️ [NotificationApi] User not subscribed yet');
        return {
          'success': true,
          'status': 'subscription_pending',
          'message': 'Notification queued, subscription activating',
        };
      } else if (res.statusCode >= 200 && res.statusCode < 300) {
        if (responseData['success'] == true || responseData['ok'] == true) {
          print('✅ [NotificationApi] Push notification sent successfully');
          print('🔔🔔🔔 [NotificationApi] SEND PUSH SUCCESS 🔔🔔🔔');
          return {'success': true, 'status': 'sent'};
        }
      }

      print('⚠️ [NotificationApi] Push notification response: $responseData');
      print('🔔🔔🔔 [NotificationApi] SEND PUSH FAILED 🔔🔔🔔');
      return {'success': false, 'error': responseData, 'status': 'failed'};
    } catch (e) {
      print('❌ [NotificationApi] Exception sending push: $e');
      print('❌ [NotificationApi] Exception type: ${e.runtimeType}');
      print('🔔🔔🔔 [NotificationApi] SEND PUSH ERROR 🔔🔔🔔');
      return {'success': false, 'error': e.toString(), 'status': 'error'};
    } finally {
      print('🔔🔔🔔 [NotificationApi] SEND PUSH END 🔔🔔🔔');
    }
  }

  static Future<void> sendDelayedNotification({
    required String userId,
    String? subscriptionId,
    int delaySeconds = 10,
  }) async {
    await Future.delayed(Duration(seconds: delaySeconds));

    print("🟡 Sending delayed notification after $delaySeconds seconds");
    await sendLoginSuccessPush(
      userId: userId,
      subscriptionId: subscriptionId,
      title: "Welcome to Templink",
      message: "Your device is now ready to receive notifications",
    );
  }
}
