import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _inited = false;

  static const String _oneSignalAppId = 'c769361a-6190-451b-b0b9-9a4fef5c436e';
  static const String _envName = kReleaseMode ? 'prod' : 'dev';
  static const String _envTagKey = 'env';

  String? _lastExternalId;

  String? get lastExternalId => _lastExternalId;

  String? get subscriptionId =>
      kIsWeb ? null : OneSignal.User.pushSubscription.id;

  Future<void> init() async {
    if (_inited) return;
    if (kIsWeb) {
      _inited = true;
      return;
    }

    OneSignal.Debug.setLogLevel(OSLogLevel.warn);
    OneSignal.initialize(_oneSignalAppId);
    OneSignal.Notifications.clearAll();

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      final data = Map<String, dynamic>.from(
        event.notification.additionalData ?? {},
      );
      debugPrint('[OneSignal] clicked ${event.notification.title} data=$data');
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    });

    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint(
        '[OneSignal] subscription optedIn=${state.current.optedIn} id=${state.current.id}',
      );
    });

    _inited = true;
  }

  String _buildExternalId(String mongoUserId) {
    final id = mongoUserId.trim();
    if (id.isEmpty) return '';
    return '$_envName:$id';
  }

  Future<bool> waitForSubscription({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (kIsWeb) return false;
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      final id = OneSignal.User.pushSubscription.id;
      if (id != null && id.isNotEmpty) return true;
      await Future.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  Future<void> login(String mongoUserId, {String? token}) async {
    if (kIsWeb) return;
    final externalUserId = _buildExternalId(mongoUserId);
    if (externalUserId.isEmpty) return;

    try {
      if (!_inited) await init();

      await OneSignal.Notifications.requestPermission(false);
      OneSignal.User.pushSubscription.optIn();

      await OneSignal.logout();
      await Future.delayed(const Duration(milliseconds: 300));
      await OneSignal.login(externalUserId);

      final subscribed = await waitForSubscription();
      if (!subscribed) {
        OneSignal.User.pushSubscription.optIn();
        await Future.delayed(const Duration(seconds: 2));
      }

      await OneSignal.User.addTagWithKey(_envTagKey, _envName);
      _lastExternalId = externalUserId;
      await verifyDeviceRegistration();
    } catch (e) {
      debugPrint('[OneSignal] login error: $e');
    }
  }

  Future<void> logout() async {
    _lastExternalId = null;
    if (kIsWeb) return;
    try {
      OneSignal.Notifications.clearAll();
      await OneSignal.logout();
    } catch (e) {
      debugPrint('[OneSignal] logout error: $e');
    }
  }

  Future<void> verifyDeviceRegistration() async {
    if (kIsWeb) return;
    try {
      final subscription = OneSignal.User.pushSubscription;
      if (subscription.id == null || subscription.id!.isEmpty) {
        OneSignal.User.pushSubscription.optIn();
      }
    } catch (e) {
      debugPrint('[OneSignal] verify error: $e');
    }
  }

  Future<void> debugPrintState({String from = ''}) async {
    if (kIsWeb) return;
    try {
      final sub = OneSignal.User.pushSubscription;
      debugPrint(
        '[OneSignal] state[$from] permission=${OneSignal.Notifications.permission} optedIn=${sub.optedIn} subId=${sub.id} externalId=$_lastExternalId',
      );
    } catch (e) {
      debugPrint('[OneSignal] debugPrintState error: $e');
    }
  }
}
