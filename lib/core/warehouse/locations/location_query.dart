import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart'
    show LocationController, kAllLocationsId;
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
    if (id == null || id.isEmpty || id == kAllLocationsId) return null;
    return id;
  } catch (_) {
    return null;
  }
}

bool isAllLocationsSelected() {
  try {
    if (!Get.isRegistered<LocationController>()) return false;
    return Get.find<LocationController>().isAllLocationsSelected;
  } catch (_) {
    return false;
  }
}

/// API paths that accept locationId (mirrors web + fiscal-year whitelist).
const List<String> kLocationQueryPaths = [
  '/api/warehouse',
  '/api/sales',
  '/api/sales-invoices',
  '/api/purchase',
  '/api/purchases',
  '/api/pos',
  '/api/goods',
  '/api/accounting',
  '/api/dashboard',
  '/api/expenses',
  '/api/income',
  '/api/journal-entries',
  '/api/balance-sheet',
  '/api/reports/',
  '/api/trial-balance',
  '/api/general-ledger',
  '/api/accounts-receivable',
  '/api/accounts-payable',
  '/api/aged-receivables',
  '/api/payments-made',
  '/api/payments-received',
  '/api/credit-notes',
  '/api/bills',
  '/api/deliveries',
  '/api/quotations',
  '/api/orders/',
  '/api/product/search',
  '/api/transactions',
  '/api/fixed-assets',
  '/api/loans',
  '/api/purchaseinvoice',
];

const List<String> kLocationQueryExcludedPaths = [
  '/warehouse/locations',
  '/admin/users',
  '/users/',
  '/api/profile',
  '/api/chart-of-accounts',
  '/api/bank-accounts',
  '/api/warehouse/categories',
];

bool shouldAttachLocationId(String endpoint) {
  final path = endpoint.split('?').first;
  for (final excluded in kLocationQueryExcludedPaths) {
    if (path.contains(excluded)) return false;
  }
  return kLocationQueryPaths.any((p) => path.contains(p));
}

Worker? listenLocationChanges(void Function() reload) {
  if (!Get.isRegistered<LocationController>()) return null;
  return ever(
    Get.find<LocationController>().storedSelectedId,
    (_) => reload(),
  );
}

Future<void> hydrateLocationsAfterAuth(dynamic user) async {
  if (user is! Map) return;
  final c = ensureLocationController();
  if (c == null) return;
  await c.hydrateFromUser(Map<String, dynamic>.from(user));
}

/// Accounting module routes — admin may pick "All locations" (web parity).
bool routeAllowsAllLocations(String route) {
  if (route.isEmpty || route == '/') return false;
  return route.startsWith('/accounting') ||
      route == '/dashboard' ||
      route.startsWith('/pos');
}
