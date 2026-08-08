// lib/core/purchasedashboard/purchase_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_dashboard_model.dart';
import 'package:get/get.dart';

class PurchaseController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── STATE ────────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxString period = 'month'.obs;

  final Rx<PurchaseDashboardModel?> dashboard = Rx<PurchaseDashboardModel?>(
    null,
  );
  final RxList<PurchaseSpendPoint> spendTrend = <PurchaseSpendPoint>[].obs;
  final RxList<PurchaseOrderStatus> orderStatuses = <PurchaseOrderStatus>[].obs;
  final RxList<PurchaseSupplier> topSuppliers = <PurchaseSupplier>[].obs;
  final RxList<PurchaseActivity> activities = <PurchaseActivity>[].obs;

  // Custom date
  final Rx<DateTime?> customStart = Rx<DateTime?>(null);
  final Rx<DateTime?> customEnd = Rx<DateTime?>(null);

  static const periods = [
    'today',
    'week',
    'month',
    'last_month',
    'quarter',
    'year',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  // ─── PERIOD ───────────────────────────────────────────────────────────────

  void setPeriod(String p, {DateTime? start, DateTime? end}) {
    period.value = p;
    if (p == 'custom') {
      customStart.value = start;
      customEnd.value = end;
    } else {
      customStart.value = null;
      customEnd.value = null;
    }
    fetchDashboard();
  }

  Map<String, String> get _periodParams {
    final params = <String, String>{'period': period.value};
    if (period.value == 'custom') {
      if (customStart.value != null) {
        params['startDate'] = customStart.value!.toIso8601String();
      }
      if (customEnd.value != null) {
        params['endDate'] = customEnd.value!.toIso8601String();
      }
    }
    return params;
  }

  String getPeriodLabel() {
    switch (period.value) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'quarter':
        return 'This Quarter';
      case 'year':
        return 'This Year';
      case 'custom':
        if (customStart.value != null && customEnd.value != null) {
          final s = customStart.value!;
          final e = customEnd.value!;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom';
      default:
        return 'This Month';
    }
  }

  // ─── FETCH ────────────────────────────────────────────────────────────────

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      print(
        '🔵 [PurchaseDashboard] fetch period=${period.value} params=$_periodParams',
      );

      await Future.wait([
        _fetchMetrics(),
        _fetchSpendTrend(),
        _fetchOrderStatus(),
        _fetchTopSuppliers(),
        _fetchActivities(),
      ]);

      print(
        '✅ [PurchaseDashboard] loaded '
        'spend=${dashboard.value?.invoices.totalSpend} '
        'orders=${dashboard.value?.orders.total} '
        'trend=${spendTrend.length} '
        'activities=${activities.length}',
      );
    } catch (e) {
      print('Purchase dashboard fetch error: $e');
      Get.snackbar('Purchase Dashboard', 'Failed to load dashboard data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMetrics() async {
    try {
      final res = await _api.get(
        '/api/purchase/dashboard/metrics',
        requiresAuth: true,
        queryParameters: _periodParams,
      );
      print('🔵 [PurchaseDashboard] metrics success=${res.success}');
      if (res.success && res.data != null) {
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        dashboard.value = PurchaseDashboardModel.fromMetrics(data);
      }
    } catch (e) {
      print('Metrics error: $e');
    }
  }

  Future<void> _fetchSpendTrend() async {
    try {
      final res = await _api.get(
        '/api/purchase/dashboard/charts/spend-trend',
        requiresAuth: true,
        queryParameters: _periodParams,
      );
      if (res.success && res.data != null) {
        final list = res.data['data'] as List? ?? [];
        spendTrend.value = list
            .map(
              (e) => PurchaseSpendPoint.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (e) {
      print('Spend trend error: $e');
    }
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final res = await _api.get(
        '/api/purchase/dashboard/charts/order-status',
        requiresAuth: true,
        queryParameters: _periodParams,
      );
      if (res.success && res.data != null) {
        final list = res.data['data'] as List? ?? [];
        orderStatuses.value = list
            .map(
              (e) => PurchaseOrderStatus.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (e) {
      print('Order status error: $e');
    }
  }

  Future<void> _fetchTopSuppliers() async {
    try {
      final res = await _api.get(
        '/api/purchase/dashboard/charts/top-suppliers',
        requiresAuth: true,
        queryParameters: _periodParams,
      );
      if (res.success && res.data != null) {
        final list = res.data['data'] as List? ?? [];
        topSuppliers.value = list
            .map((e) => PurchaseSupplier.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      print('Top suppliers error: $e');
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final res = await _api.get(
        '/api/purchase/dashboard/activities',
        requiresAuth: true,
      );
      if (res.success && res.data != null) {
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        final list = data['activities'] as List? ?? [];
        activities.value = list
            .map((e) => PurchaseActivity.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      print('Activities error: $e');
    }
  }

  Future<void> refreshDashboard() => fetchDashboard();
}
