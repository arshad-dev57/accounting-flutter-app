import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
import 'package:get/get.dart';

LocationController? ensureLocationController() {
  if (Get.isRegistered<LocationController>()) {
    return Get.find<LocationController>();
  }
  return Get.put(LocationController(), permanent: true);
}

String? currentLocationId() {
  try {
    if (!Get.isRegistered<LocationController>()) return null;
    final id = Get.find<LocationController>().selectedLocationId;
    if (id == null || id.isEmpty || id == 'all') return null;
    return id;
  } catch (_) {
    return null;
  }
}

bool shouldAttachLocationId(String endpoint) {
  final path = endpoint.split('?').first;
  if (path.contains('/warehouse/locations')) return false;
  if (path.contains('/admin/users')) return false;
  if (path.contains('/users/')) return false;
  return path.contains('/api/warehouse') ||
      path.contains('/api/sales') ||
      path.contains('/api/purchase') ||
      path.contains('/api/pos') ||
      path.contains('/api/goods') ||
      path.contains('/api/accounting');
}

Worker? listenLocationChanges(void Function() reload) {
  if (!Get.isRegistered<LocationController>()) return null;
  String? lastId = currentLocationId();
  return ever(
    Get.find<LocationController>().selectedLocation,
    (loc) {
      final id = loc?.id;
      if (id == lastId) return;
      lastId = id;
      reload();
    },
  );
}

Future<void> hydrateLocationsAfterAuth(dynamic user) async {
  if (user is! Map) return;
  final c = ensureLocationController();
  if (c == null) return;
  await c.hydrateFromUser(Map<String, dynamic>.from(user));
}
