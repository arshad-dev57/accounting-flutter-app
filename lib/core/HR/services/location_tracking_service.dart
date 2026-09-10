import 'dart:async';

import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _localWatchTimer;
  int _session = 0;
  String _employeeId = '';
  String _employeeName = '';
  String? _officeName;
  double? _officeLat;
  double? _officeLng;
  double _officeRadius = 150;
  bool _isFieldEmployee = false;

  bool? _stableInside;
  bool? _pendingInside;
  DateTime? _pendingSince;
  DateTime? _lastEventAt;
  DateTime? _lastHeartbeatAt;
  DateTime? _lastMoveAt;
  double? _lastMoveLat;
  double? _lastMoveLng;

  static const _prefKey = 'hr_location_tracking_enabled';
  static const _dwell = Duration(seconds: 75);
  static const _heartbeatEvery = Duration(minutes: 2);
  static const _liveMoveEvery = Duration(seconds: 90);
  static const _liveMoveMeters = 80.0;
  static const _eventCooldown = Duration(minutes: 2);

  Future<LocationTrackingService> initProfile({
    required String employeeId,
    required String employeeName,
    String? officeName,
    double? officeLat,
    double? officeLng,
    double? officeRadius,
    bool isFieldEmployee = false,
    bool checkedIn = false,
    String? checkInTimeIso,
  }) async {
    _employeeId = employeeId;
    _employeeName = employeeName;
    _officeName = officeName;
    _officeLat = officeLat;
    _officeLng = officeLng;
    _officeRadius = officeRadius ?? 150;
    _isFieldEmployee = isFieldEmployee;
    isCheckedIn.value = checkedIn;
    checkInTime.value = checkInTimeIso ?? '';
    return this;
  }

  Future<bool> ensurePermissions() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        lastMessage.value = 'Please enable GPS / location services';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        lastMessage.value = 'Location permission denied';
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        lastMessage.value =
            'Location permission is blocked. Enable it in App settings.';
        return false;
      }
      return true;
    } catch (e) {
      lastMessage.value = 'Could not start location: $e';
      return false;
    }
  }

  Future<void> _maybeRequestBackgroundPermission() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.locationAlways.status;
      if (status.isGranted || status.isPermanentlyDenied) return;
      await Permission.locationAlways.request();
    } catch (_) {}
  }

  Future<bool> isTrackingPreferred() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  Future<void> _setPreferred(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  Future<void> startTracking() async {
    if (isTracking.value) return;
    final session = ++_session;
    isTracking.value = true;
    statusLabel.value = 'Starting';
    lastMessage.value = 'Starting location tracking…';

    final ok = await ensurePermissions();
    if (session != _session) return;
    if (!ok) {
      isTracking.value = false;
      statusLabel.value = 'Stopped';
      return;
    }

    await _setPreferred(true);
    if (session != _session) return;

    _resetGeofenceState();
    statusLabel.value = 'Sharing live location';
    lastMessage.value = _officeLat == null
        ? 'Live location is on. HR can see you. Assign an office for auto attendance.'
        : 'Live location is on. Office radius is only for check-in / check-out.';

    unawaited(_maybeRequestBackgroundPermission());

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 40,
    );

    await _positionSub?.cancel();
    if (session != _session) return;
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
      _onLocalPosition,
      onError: (e) {
        lastMessage.value = 'Location stream error: $e';
      },
    );

    _localWatchTimer?.cancel();
    _localWatchTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (session != _session || !isTracking.value) return;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _onLocalPosition(pos);
      } catch (_) {}
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (session != _session) return;
      await _onLocalPosition(pos);
    } catch (e) {
      if (session != _session) return;
      lastMessage.value = 'Could not get current location: $e';
    }
  }

  Future<void> stopTracking() async {
    final session = ++_session;
    isTracking.value = false;
    statusLabel.value = 'Stopped';
    lastLat.value = 0;
    lastLng.value = 0;
    insideGeofence.value = false;
    lastMessage.value = 'Location tracking is off — HR will not see you live';
    _resetGeofenceState();
    await _tearDownLocation();
    await _setPreferred(false);
    if (session != _session) return;
    try {
      await HrApiService.instance.trackingEvent(event: 'stop');
    } catch (_) {}
  }

  Future<void> _tearDownLocation() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _localWatchTimer?.cancel();
    _localWatchTimer = null;
  }

  void _resetGeofenceState() {
    _stableInside = null;
    _pendingInside = null;
    _pendingSince = null;
    _lastEventAt = null;
    _lastHeartbeatAt = null;
    _lastMoveAt = null;
    _lastMoveLat = null;
    _lastMoveLng = null;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensurePermissions();
    if (!ok) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _onLocalPosition(Position pos) async {
    if (!isTracking.value) return;
    lastLat.value = pos.latitude;
    lastLng.value = pos.longitude;

    final inside = _isInside(pos.latitude, pos.longitude);
    insideGeofence.value = inside;
    statusLabel.value = inside
        ? 'Inside office'
        : (_isFieldEmployee ? 'In the field' : 'Away from office');

    final now = DateTime.now();
    if (_pendingInside != inside) {
      _pendingInside = inside;
      _pendingSince = now;
    }

    final dwellReady = _officeLat != null &&
        _pendingSince != null &&
        now.difference(_pendingSince!) >= _dwell &&
        _stableInside != inside;

    if (dwellReady) {
      _stableInside = inside;
      await _sendEvent(inside ? 'enter' : 'exit', pos);
      return;
    }

    final moved = _lastMoveLat == null
        ? true
        : Geolocator.distanceBetween(
              _lastMoveLat!,
              _lastMoveLng!,
              pos.latitude,
              pos.longitude,
            ) >=
            _liveMoveMeters;
    if (moved &&
        (_lastMoveAt == null ||
            now.difference(_lastMoveAt!) >= _liveMoveEvery)) {
      await _sendEvent('move', pos);
      return;
    }

    if (_lastHeartbeatAt == null ||
        now.difference(_lastHeartbeatAt!) >= _heartbeatEvery) {
      await _sendEvent('heartbeat', pos);
    }
  }

  bool _isInside(double lat, double lng) {
    if (_officeLat == null || _officeLng == null) return false;
    final meters = Geolocator.distanceBetween(
      lat,
      lng,
      _officeLat!,
      _officeLng!,
    );
    return meters <= _officeRadius;
  }

  Future<void> _sendEvent(String event, Position pos) async {
    if (!isTracking.value && event != 'stop') return;
    final now = DateTime.now();
    if (event == 'enter' || event == 'exit') {
      if (_lastEventAt != null &&
          now.difference(_lastEventAt!) < _eventCooldown) {
        return;
      }
      _lastEventAt = now;
    }
    if (event == 'heartbeat') _lastHeartbeatAt = now;
    if (event == 'move') {
      _lastHeartbeatAt = now;
      _lastMoveAt = now;
      _lastMoveLat = pos.latitude;
      _lastMoveLng = pos.longitude;
    }

    try {
      final data = await HrApiService.instance.trackingEvent(
        event: event,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
      );
      final tracked = data['tracked'] as Map<String, dynamic>?;
      final attendance = data['attendance'] as Map<String, dynamic>?;
      final message = data['message']?.toString() ?? '';

      if (tracked != null) {
        insideGeofence.value = tracked['insideGeofence'] == true;
        statusLabel.value = tracked['status']?.toString() ?? statusLabel.value;
      }
      if (attendance != null && attendance['checkIn'] != null) {
        isCheckedIn.value = attendance['isCheckedIn'] == true;
        checkInTime.value = attendance['checkIn'].toString();
        if (attendance['checkOut'] != null) {
          isCheckedIn.value = false;
        }
      }
      lastMessage.value = data['autoCheckedIn'] == true
          ? 'Auto check-in: $message'
          : data['autoCheckedOut'] == true
              ? 'Auto check-out: $message'
              : message.isNotEmpty
                  ? message
                  : 'Synced';
    } catch (e) {
      lastMessage.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void onClose() {
    _positionSub?.cancel();
    _localWatchTimer?.cancel();
    super.onClose();
  }
}
