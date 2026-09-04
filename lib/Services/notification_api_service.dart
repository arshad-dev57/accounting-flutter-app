import 'dart:convert';

import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:http/http.dart' as http;

/// Sends a notification through own backend (inbox + OneSignal push).
class NotificationApi {
  static Future<Map<String, dynamic>> sendToUser({
    required String authToken,
    required String userId,
    String title = 'Notification',
    String message = '',
    Map<String, dynamic>? data,
  }) async {
    final uri = Uri.parse('${Apiconfig().baseUrl}/api/notifications/send');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
      }),
    );

    Map<String, dynamic> responseData = {};
    if (res.body.isNotEmpty) {
      try {
        responseData = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && responseData['success'] == true) {
      return {'success': true, 'status': 'sent', 'data': responseData['data']};
    }

    return {'success': false, 'status': 'failed', 'error': responseData};
  }
}
