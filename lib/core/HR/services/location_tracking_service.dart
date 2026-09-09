import 'dart:async';

import 'package:BisonsTechs_app/core/HR/services/hr_tracking_api.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Continuous employee GPS tracking → server ping → auto attendance.
class LocationTrackingService extends GetxService {
  static LocationTrackingService get to => Get.find();

  final isTracking = false.obs;
  final lastMessage = ''.obs;
  final lastLat = 0.0.obs;
  final lastLng = 0.0.obs;
  final isCheckedIn = false.obs;
  final checkInTime = ''.obs;
  final insideGeofence = false.obs;
  final statusLabel = 'Idle'.obs;

  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;
  String _employeeId = 'EMP-001';
  String _employeeName = 'Ahmed Khan';
  String? _officeName = 'Head Office';
  DateTime? _lastSentAt;

  Future<LocationTrackingService> initProfile({
    required String employeeId,
    required String employeeName,
    String? officeName,
  }) async {
    _employeeId = employeeId;
    _employeeName = employeeName;
    _officeName = officeName;
    return this;
  }

  Future<bool> ensurePermissions() async {
    // Web / desktop: browser prompt via geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      lastMessage.value = 'Location permission denied';
      return false;
    }

    if (!kIsWeb) {
      final whenInUse = await Permission.locationWhenInUse.request();
      if (!whenInUse.isGranted) {
        lastMessage.value = 'Location permission required for attendance';
        return false;
      }
      // Best-effort background permission (Android 10+ / iOS)
      await Permission.locationAlways.request();
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      lastMessage.value = 'Please enable GPS / location services';
      return false;
    }
    return true;
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;
    final ok = await ensurePermissions();
    if (!ok) return;

    isTracking.value = true;
    statusLabel.value = 'Tracking…';
    lastMessage.value = 'Live location tracking started';

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25, // meters
    );

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
      (pos) => _handlePosition(pos, isBackground: false),
      onError: (e) {
        lastMessage.value = 'Location stream error: $e';
      },
    );

    // Also ping on a fixed interval (helps web + background gaps)
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      if (!isTracking.value) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _handlePosition(pos, isBackground: !kIsWeb);
      } catch (_) {}
    });

    // Immediate first ping
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _handlePosition(pos, isBackground: false);
    } catch (e) {
      lastMessage.value = 'Could not get current location: $e';
    }
  }

  Future<void> stopTracking() async {
    isTracking.value = false;
    statusLabel.value = 'Stopped';
    await _positionSub?.cancel();
    _positionSub = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    lastMessage.value = 'Tracking stopped';
  }

  Future<void> _handlePosition(Position pos, {required bool isBackground}) async {
    lastLat.value = pos.latitude;
    lastLng.value = pos.longitude;

    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!).inSeconds < 12) {
      return; // throttle network
    }
    _lastSentAt = now;

    try {
      final data = await HrTrackingApi.instance.pingLocation(
        employeeId: _employeeId,
        employeeName: _employeeName,
        officeName: _officeName,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        heading: pos.heading,
        isBackground: isBackground,
      );

      final tracked = data['tracked'] as Map<String, dynamic>?;
      final attendance = data['attendance'] as Map<String, dynamic>?;
      final auto = data['autoCheckedIn'] == true;
      final message = data['message']?.toString() ?? '';

      if (tracked != null) {
        insideGeofence.value = tracked['insideGeofence'] == true;
        statusLabel.value = tracked['status']?.toString() ?? statusLabel.value;
      }
      if (attendance != null && attendance['checkIn'] != null) {
        isCheckedIn.value = true;
        checkInTime.value = attendance['checkIn'].toString();
      }
      lastMessage.value = auto
          ? '✅ Auto attendance: $message'
          : message.isNotEmpty
              ? message
              : 'Location synced';
    } catch (e) {
      lastMessage.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void onClose() {
    _positionSub?.cancel();
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
