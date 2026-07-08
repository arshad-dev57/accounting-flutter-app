// lib/core/warehouse/purchase/controller/purchase_controller.dart

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_dashboard_model.dart';
import 'package:get/get.dart';

class PurchaseController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── STATE ─────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final Rx<PurchaseDashboardModel?> dashboard = Rx<PurchaseDashboardModel?>(null);
  final RxString period = 'month'.obs; // week, month, year

  static const periods = ['week', 'month', 'year'];

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  // ─── FETCH DASHBOARD ──────────────────────────────────────────

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      final params = {'period': period.value};
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      
      final response = await _api.get(
        '/api/purchase/dashboard?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        dashboard.value = PurchaseDashboardModel.fromJson(response.data['data']);
      } else {
        // Fallback to static data if API fails
        dashboard.value = getStaticDashboard();
      }
    } catch (e) {
      print('Error fetching purchase dashboard: $e');
      // Fallback to static data
      dashboard.value = getStaticDashboard();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── SET PERIOD ───────────────────────────────────────────────

  void setPeriod(String period) {
    this.period.value = period;
    fetchDashboard();
  }

  // ─── STATIC DASHBOARD DATA ────────────────────────────────────

  PurchaseDashboardModel getStaticDashboard() {
    return PurchaseDashboardModel(
      orders: PurchaseOrderSummary(
        count: 45,
        totalValue: 1250000,
        approvedCount: 28,
        approvedValue: 850000,
        draftCount: 10,
        sentCount: 5,
        cancelledCount: 2,
        trend: [
          PurchaseTrendPoint(date: '2026-06-01', value: 45000),
          PurchaseTrendPoint(date: '2026-06-02', value: 32000),
          PurchaseTrendPoint(date: '2026-06-03', value: 68000),
          PurchaseTrendPoint(date: '2026-06-04', value: 25000),
          PurchaseTrendPoint(date: '2026-06-05', value: 56000),
          PurchaseTrendPoint(date: '2026-06-06', value: 72000),
          PurchaseTrendPoint(date: '2026-06-07', value: 48000),
        ],
      ),
    );
  }
}