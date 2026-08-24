// core/warehouse/locations/controller/location_controller.dart

import 'dart:convert';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/model/location_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kSelectedLocationStorageKey = 'selected_location_id';
const String kCachedLocationsStorageKey = 'cached_locations';

class LocationController extends GetxController {
  var locations = <WarehouseLocation>[].obs;
  var isLoading = true.obs;
  var selectedLocation = Rx<WarehouseLocation?>(null);
  var error = ''.obs;
  var isLocationAdmin = false.obs;

  /// Restored from disk before the list API returns.
  final RxnString storedSelectedId = RxnString();

  final ApiClient _api = Get.find<ApiClient>();
  Future<void>? _fetchInFlight;
  int _fetchGeneration = 0;
  bool _hasAttemptedFetch = false;

  static const locationTypes = ['Warehouse', 'Shop', 'POS_Store'];

  @override
  void onInit() {
    super.onInit();
    Future(() async {
      await _hydrateStoredSelection();
      await ensureLocationsLoaded();
    });
  }

  Future<void> _hydrateStoredSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString(kSelectedLocationStorageKey);
      if (storedId != null && storedId.isNotEmpty) {
        storedSelectedId.value = storedId;
      }
      final cached = prefs.getString(kCachedLocationsStorageKey);
      if (cached != null && cached.isNotEmpty && locations.isEmpty) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is List) {
            locations.value = parsedLocations(decoded);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  List<WarehouseLocation> parsedLocations(List raw) {
    final parsed = <WarehouseLocation>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        parsed.add(WarehouseLocation.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return parsed;
  }

  Future<void> hydrateFromUser(Map<String, dynamic> user) async {
    final role = user['role']?.toString().toLowerCase().trim() ?? '';
    isLocationAdmin.value =
        user['isLocationAdmin'] == true ||
        role == 'admin' ||
        role == 'owner' ||
        role == 'superadmin';

    final rawLocs = user['locations'];
    if (rawLocs is List && rawLocs.isNotEmpty) {
      final parsed = parsedLocations(rawLocs);
      if (parsed.isNotEmpty) {
        locations.value = parsed;
        await _cacheLocations(parsed);
        await _reconcileSelection(parsed);
        isLoading(false);
      }
    }
    await fetchLocations(force: true);
  }

  Future<void> _cacheLocations(List<WarehouseLocation> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kCachedLocationsStorageKey,
        jsonEncode(list.map((l) => l.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Load locations when authenticated. Safe to call many times — shares
  /// one in-flight request and skips if already loaded (unless [force]).
  Future<void> ensureLocationsLoaded({bool force = false}) async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      isLoading(false);
      return;
    }
    if (!force &&
        locations.isNotEmpty &&
        (selectedLocation.value != null ||
            (storedSelectedId.value != null &&
                storedSelectedId.value!.isNotEmpty))) {
      isLoading(false);
      return;
    }
    await fetchLocations(force: force);
  }

  Future<void> fetchLocations({bool force = false}) async {
    if (_fetchInFlight != null) {
      await _fetchInFlight;
      if (!force) return;
    }
    final future = _doFetchLocations();
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_fetchInFlight, future)) {
        _fetchInFlight = null;
      }
    }
  }

  Future<void> _doFetchLocations() async {
    final generation = ++_fetchGeneration;
    try {
      isLoading(true);
      error.value = '';
      _hasAttemptedFetch = true;

      final token = await _api.getToken();
      if (token == null || token.isEmpty) {
        error.value = '';
        return;
      }

      final response = await _api.get('/api/warehouse/locations');
      if (generation != _fetchGeneration) return;

      if (response.success) {
        final data = response.data;
        final raw = data is Map ? (data['data'] ?? data) : data;
        final list = raw is List ? raw : <dynamic>[];
        final parsed = <WarehouseLocation>[];
        for (final e in list) {
          if (e is! Map) continue;
          try {
            parsed.add(
              WarehouseLocation.fromJson(Map<String, dynamic>.from(e)),
            );
          } catch (_) {
            // Skip malformed rows instead of failing the whole load.
          }
        }

        locations.value = parsed;
        await _cacheLocations(parsed);
        await _reconcileSelection(parsed);
      } else {
        error.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load locations';
        if (response.statusCode != 401 && response.statusCode != 403) {
          AppSnackbar.error(kDanger, 'Error', error.value);
        }
      }
    } catch (e) {
      if (generation == _fetchGeneration) {
        error.value = 'Failed to load locations: $e';
      }
    } finally {
      if (generation == _fetchGeneration) {
        isLoading(false);
      }
    }
  }

  Future<void> _reconcileSelection(List<WarehouseLocation> list) async {
    if (list.isEmpty) {
      selectedLocation.value = null;
      await _persistSelectedId(null);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedId =
        prefs.getString(kSelectedLocationStorageKey) ?? storedSelectedId.value;
    WarehouseLocation? chosen;

    if (storedId != null && storedId.isNotEmpty) {
      chosen = list.firstWhereOrNull((l) => l.id == storedId);
    }
    chosen ??= list.firstWhereOrNull((l) => l.isDefault) ?? list.first;

    if (selectedLocation.value?.id == chosen.id) {
      await _persistSelectedId(chosen.id);
      return;
    }
    selectedLocation.value = chosen;
    await _persistSelectedId(chosen.id);
  }

  Future<void> _persistSelectedId(String? id) async {
    storedSelectedId.value = (id == null || id.isEmpty) ? null : id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(kSelectedLocationStorageKey);
    } else {
      await prefs.setString(kSelectedLocationStorageKey, id);
    }
  }

  Future<bool> create({
    required String name,
    required String code,
    String type = 'Shop',
    bool isDefault = false,
    String? address,
    String? phone,
    String? notes,
  }) async {
    try {
      isLoading(true);

      final response = await _api.post(
        '/api/warehouse/locations',
        body: {
          'name': name.trim(),
          'code': code.trim(),
          'type': type,
          'isDefault': isDefault,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Location created successfully',
        );
        await fetchLocations(force: true);

        final created = response.data is Map
            ? (response.data['data'] ?? response.data)
            : null;
        if (created is Map && created['id'] != null) {
          final match = locations.firstWhereOrNull(
            (l) => l.id == created['id'].toString(),
          );
          if (match != null) await selectLocation(match);
        }
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to create location',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to create location: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateLocation({
    required String id,
    String? name,
    String? code,
    String? type,
    bool? isDefault,
    String? address,
    String? phone,
    String? notes,
  }) async {
    try {
      isLoading(true);

      final response = await _api.put(
        '/api/warehouse/locations/$id',
        body: {
          if (name != null) 'name': name.trim(),
          if (code != null) 'code': code.trim(),
          if (type != null) 'type': type,
          if (isDefault != null) 'isDefault': isDefault,
          if (address != null) 'address': address.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (notes != null) 'notes': notes.trim(),
        },
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Location updated successfully',
        );
        await fetchLocations(force: true);
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update location',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to update location: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> delete(String id) async {
    try {
      isLoading(true);

      final response = await _api.delete('/api/warehouse/locations/$id');

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Location deleted successfully',
        );
        await fetchLocations(force: true);
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete location',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to delete location: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> selectLocation(WarehouseLocation? location) async {
    if (selectedLocation.value?.id == location?.id) return;
    selectedLocation.value = location;
    await _persistSelectedId(location?.id);
  }

  String? get selectedLocationId {
    final live = selectedLocation.value?.id;
    if (live != null && live.isNotEmpty) return live;
    final stored = storedSelectedId.value;
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  bool get hasLoadedList => _hasAttemptedFetch && !isLoading.value;

  Future<void> clearSession() async {
    _fetchGeneration++;
    _fetchInFlight = null;
    _hasAttemptedFetch = false;
    locations.clear();
    selectedLocation.value = null;
    error.value = '';
    isLocationAdmin.value = false;
    isLoading(false);
    await _persistSelectedId(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kCachedLocationsStorageKey);
    } catch (_) {}
  }
}
