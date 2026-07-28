import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _inited = false;

  static const String _oneSignalAppId = "c769361a-6190-451b-b0b9-9a4fef5c436e";
  static const String _envName = "dev";
  static const String _envTagKey = "env";

  String? _lastExternalId;

  /// Get the last external user ID used for login
  String? get lastExternalId => _lastExternalId;

  /// Get the current OneSignal subscription ID
  String? get subscriptionId => OneSignal.User.pushSubscription.id;

  Future<void> init() async {
    print('🔔🔔🔔 [NotificationService] INIT START 🔔🔔🔔');
    if (_inited) {
      print('🔔 [NotificationService] Already initialized, skipping');
      return;
    }

    print('🔔 [NotificationService] Initializing OneSignal...');
    print('🔔 [NotificationService] App ID: $_oneSignalAppId');
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(_oneSignalAppId);
    print('🔔 [NotificationService] OneSignal.initialize() called');

    // ✅ Permission request
    print('🔔 [NotificationService] Requesting permission...');
    final granted = await OneSignal.Notifications.requestPermission(true);
    print('🔔 [NotificationService] Permission granted = $granted');

    // ✅ Opt-in push
    print('🔔 [NotificationService] Opting in to push notifications...');
    OneSignal.User.pushSubscription.optIn();
    print('🔔 [NotificationService] Opt-in called');

    // ✅ Clear old notifications
    print('🔔 [NotificationService] Clearing old notifications...');
    OneSignal.Notifications.clearAll();
    print('🔔 [NotificationService] Old notifications cleared');

    // ✅ FOREGROUND mein bhi notification display karo
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('🔔🔔🔔 [NotificationService] FOREGROUND NOTIFICATION RECEIVED 🔔🔔🔔');
      print('🔔 [NotificationService] Title: ${event.notification.title}');
      print('🔔 [NotificationService] Body: ${event.notification.body}');
      print('🔔 [NotificationService] Data: ${event.notification.additionalData}');
      print('🔔 [NotificationService] Calling display()...');

      // ✅ YAHI KEY HAI — foreground mein force display karo
      event.notification.display();

      print('🔔 [NotificationService] display() called successfully');
      print('🔔🔔🔔 [NotificationService] FOREGROUND NOTIFICATION END 🔔🔔🔔');
    });

    // ✅ Notification click handler
    OneSignal.Notifications.addClickListener((event) {
      final data = Map<String, dynamic>.from(
        event.notification.additionalData ?? {},
      );

      print('🔔 [NotificationService] Notification Clicked: ${event.notification.title}');
      print('🔔 [NotificationService] Notification Data: $data');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (data["screen"] == "home") {
          print("🔔 [NotificationService] Home screen notification clicked");
        } else if (data["type"] == "auth") {
          print("🔔 [NotificationService] Auth notification clicked");
        }
      });
    });

    // ✅ Subscription change observer
    OneSignal.User.pushSubscription.addObserver((state) {
      print('🔔 [NotificationService] PushSubscription changed:');
      print('   - optedIn=${state.current.optedIn}');
      print('   - id=${state.current.id}');
      print('   - token=${state.current.token}');
    });

    _inited = true;
    print('✅ [NotificationService] OneSignal initialized successfully');
    print('🔔🔔🔔 [NotificationService] INIT END 🔔🔔🔔');
  }

  /// Build external id like "dev:<mongoUserId>"
  String _buildExternalId(String mongoUserId) {
    final id = mongoUserId.trim();
    if (id.isEmpty) return "";
    return "$_envName:$id";
  }

  /// Subscription ready hone ka wait karo
  Future<bool> waitForSubscription({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    print('🔔 [NotificationService] Waiting for push subscription to be ready...');

    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      final subscription = OneSignal.User.pushSubscription;

      if (subscription.id != null && subscription.id!.isNotEmpty) {
        print('✅ [NotificationService] Push subscription is ready! ID: ${subscription.id}');
        return true;
      }

      print('⏳ [NotificationService] Still waiting... (${DateTime.now().difference(startTime).inSeconds}s)');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('❌ [NotificationService] Timeout waiting for push subscription');
    return false;
  }

  /// Login ke baad call karo
  Future<void> login(String mongoUserId) async {
    print('🔔🔔🔔 [NotificationService] LOGIN START 🔔🔔🔔');
    final externalUserId = _buildExternalId(mongoUserId);

    if (externalUserId.isEmpty) {
      print('🔔 [NotificationService] OneSignal.login skipped (empty userId)');
      return;
    }

    print('🔔 [NotificationService] ATTEMPTING OneSignal login');
    print('🔔 [NotificationService] External ID: $externalUserId');
    print('🔔 [NotificationService] Original mongoUserId: $mongoUserId');

    try {
      if (!_inited) {
        print('🔔 [NotificationService] Not initialized, calling init()...');
        await init();
      }

      // ✅ Pehle logout karo
      print('🔔 [NotificationService] Logging out from any previous session');
      await OneSignal.logout();
      await Future.delayed(const Duration(milliseconds: 500));

      final oldSubId = OneSignal.User.pushSubscription.id;
      print('🔔 [NotificationService] Old subscription ID: $oldSubId');

      // ✅ Login
      print('🔔 [NotificationService] Calling OneSignal.login()...');
      await OneSignal.login(externalUserId);
      print('🔔 [NotificationService] OneSignal.login() completed');

      // ✅ Subscription ready hone ka wait
      print('🔔 [NotificationService] Waiting for subscription to be ready...');
      final subscribed = await waitForSubscription(
        timeout: const Duration(seconds: 15),
      );

      if (!subscribed) {
        print('⚠️ [NotificationService] Subscription not ready, trying to opt-in manually');
        OneSignal.User.pushSubscription.optIn();
        await Future.delayed(const Duration(seconds: 3));
      }

      // ✅ Environment tag
      print('🔔 [NotificationService] Setting environment tag...');
      await OneSignal.User.addTagWithKey(_envTagKey, _envName);
      print('🔔 [NotificationService] Environment tag set: $_envTagKey=$_envName');

      _lastExternalId = externalUserId;
      print('🔔 [NotificationService] Calling verifyDeviceRegistration()...');
      await verifyDeviceRegistration();

      print('✅ [NotificationService] OneSignal login completed successfully');
      print('🔔🔔🔔 [NotificationService] LOGIN END 🔔🔔🔔');
    } catch (e) {
      print('❌ [NotificationService] OneSignal login error: $e');
      print('🔔🔔🔔 [NotificationService] LOGIN FAILED 🔔🔔🔔');
    }
  }

  /// Logout
  Future<void> logout() async {
    print('🔔 [NotificationService] Logging out...');
    _lastExternalId = null;
    await OneSignal.logout();
    print('✅ [NotificationService] OneSignal logout completed');
  }

  /// Device registration verify karo
  Future<void> verifyDeviceRegistration() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      print('🔍 [NotificationService] VERIFICATION - Device Registration Status:');
      print('   - Push subscription ID: ${subscription.id}');
      print('   - Push token: ${subscription.token}');
      print('   - Opted in: ${subscription.optedIn}');
      print('   - External ID set: $_lastExternalId');
      print('   - Permission granted: ${OneSignal.Notifications.permission}');

      if (subscription.id == null || subscription.id!.isEmpty) {
        print('❌ [NotificationService] No push subscription ID! Trying to opt-in again...');
        OneSignal.User.pushSubscription.optIn();
        await Future.delayed(const Duration(seconds: 2));
      } else {
        print('✅ [NotificationService] Device successfully registered with OneSignal');
        print('✅ [NotificationService] Device ID: ${subscription.id}');
      }
    } catch (e) {
      print('❌ [NotificationService] Verification error: $e');
    }
  }

  /// Debug state print
  Future<void> debugPrintState({String from = ""}) async {
    try {
      final permission = OneSignal.Notifications.permission;
      final sub = OneSignal.User.pushSubscription;

      print('🔎 [NotificationService] OneSignalState[$from]');
      print('   - permission=$permission');
      print('   - optedIn=${sub.optedIn}');
      print('   - subId=${sub.id}');
      print('   - token=${sub.token}');
      print('   - externalId=$_lastExternalId');
      print('   - OneSignal initialized: $_inited');
    } catch (e) {
      print('❌ [NotificationService] debugPrintState error: $e');
    }
  }
}