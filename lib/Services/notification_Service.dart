import 'dart:async';
import 'dart:convert';

import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Own-backend notifications via SSE + local device alerts (no OneSignal).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _inited = false;
  http.Client? _sseClient;
  StreamSubscription<String>? _sseSub;
  VoidCallback? _disconnectStream;

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb || _inited) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );

    if (!kIsWeb) {
      await _local
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _inited = true;
  }

  Future<void> login(String userId, {String? token}) async {
    if (kIsWeb || userId.trim().isEmpty) return;
    if (!_inited) await init();

    final authToken = token ?? await _readToken();
    if (authToken == null || authToken.isEmpty) return;

    await _stopStream();
    _startStream(authToken);
  }

  Future<void> logout() async {
    await _stopStream();
    try {
      await _local.cancelAll();
    } catch (_) {}
  }

  /// Kept for older call sites — no-op now that OneSignal is removed.
  Future<void> verifyDeviceRegistration() async {}

  Future<void> debugPrintState({String from = ''}) async {}

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _startStream(String token) {
    _sseClient?.close();
    _sseClient = http.Client();

    final request = http.Request(
      'GET',
      Uri.parse('${Apiconfig().baseUrl}/api/notifications/stream'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });

    _sseClient!
        .send(request)
        .then((response) {
          if (response.statusCode != 200) {
            _scheduleReconnect(token);
            return;
          }

          var buffer = '';
          _sseSub = response.stream.transform(utf8.decoder).listen(
            (chunk) {
              buffer += chunk;
              final parts = buffer.split('\n\n');
              buffer = parts.isNotEmpty ? parts.removeLast() : '';

              for (final part in parts) {
                final dataLine = part
                    .split('\n')
                    .map((line) => line.trim())
                    .firstWhere(
                      (line) => line.startsWith('data:'),
                      orElse: () => '',
                    );
                if (dataLine.isEmpty) continue;

                try {
                  final payload = jsonDecode(dataLine.replaceFirst('data:', '').trim());
                  if (payload is Map && payload['event'] == 'notification') {
                    final notification = payload['notification'];
                    if (notification is Map) {
                      _showLocal(Map<String, dynamic>.from(notification));
                    }
                  }
                } catch (_) {}
              }
            },
            onDone: () => _scheduleReconnect(token),
            onError: (_) => _scheduleReconnect(token),
            cancelOnError: true,
          );
        })
        .catchError((_) {
          _scheduleReconnect(token);
          return null;
        });

    _disconnectStream = () {
      _sseSub?.cancel();
      _sseSub = null;
      _sseClient?.close();
      _sseClient = null;
    };
  }

  void _scheduleReconnect(String token) {
    Future.delayed(const Duration(seconds: 4), () {
      if (_disconnectStream != null) _startStream(token);
    });
  }

  Future<void> _stopStream() async {
    _disconnectStream?.call();
    _disconnectStream = null;
    await _sseSub?.cancel();
    _sseSub = null;
    _sseClient?.close();
    _sseClient = null;
  }

  Future<void> _showLocal(Map<String, dynamic> notification) async {
    final id = notification['id']?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _local.show(
      id,
      notification['title']?.toString() ?? 'Notification',
      notification['message']?.toString() ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bisonstechs_alerts',
          'Bisonstechs Alerts',
          channelDescription: 'Alerts from your Bisonstechs server',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
