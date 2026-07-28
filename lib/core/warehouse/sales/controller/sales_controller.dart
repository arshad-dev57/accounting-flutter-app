import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/warehouse/sales/model/sales_dashboard_model.dart';
import 'package:get/get.dart';

class SalesController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxString period = 'month'.obs;
  final RxString selectedPeriod = 'month'.obs;
  final Rx<SalesDashboardModel?> dashboard = Rx<SalesDashboardModel?>(null);
  
  // Custom date range
  final Rx<DateTime ?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxBool useCustomDateRange = false.obs;

  static const periods = ['today', 'week', 'month', 'year'];

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      
      final queryParams = <String, dynamic>{'period': period.value};
      
      // Add custom date range if selected
      if (useCustomDateRange.value && startDate.value != null && endDate.value != null) {
        queryParams['startDate'] = _formatDate(startDate.value!);
        queryParams['endDate'] = _formatDate(endDate.value!);
        queryParams['period'] = 'custom';
      }
      
      final response = await _api.get(
        '/api/warehouse/sales/dashboard',
        queryParameters: queryParams,
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final data = Map<String, dynamic>.from(response.data['data'] ?? {});
        
        // Provide default comparison data if not present
        if (!data.containsKey('comparison')) {
          data['comparison'] = {
            'today': _getDefaultComparison(),
            'week': _getDefaultComparison(),
            'month': _getDefaultComparison(),
            'year': _getDefaultComparison(),
          };
        }
        
        // Provide default recent activity if not present
        if (!data.containsKey('recentActivity')) {
          data['recentActivity'] = [];
        }
        
        // Provide default top products if not present
        if (!data.containsKey('topProducts')) {
          data['topProducts'] = [];
        }
        
        // Provide default top customers if not present
        if (!data.containsKey('topCustomers')) {
          data['topCustomers'] = [];
        }
        
        // Provide default revenue breakdown if not present
        if (!data.containsKey('revenueBreakdown')) {
          data['revenueBreakdown'] = _getDefaultRevenueBreakdown();
        }
        
        dashboard.value = SalesDashboardModel.fromJson(data);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _getDefaultComparison() {
    return {
      'currentSales': 0.0,
      'priorSales': 0.0,
      'currentReturns': 0.0,
      'priorReturns': 0.0,
      'salesChangePercent': 0.0,
      'returnsChangePercent': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultRevenueBreakdown() {
    return {
      'grossRevenue': 0.0,
      'lineItemDiscounts': 0.0,
      'orderLevelDiscounts': 0.0,
      'netRevenue': 0.0,
      'taxAmount': 0.0,
      'shippingAmount': 0.0,
    };
  }

  void setPeriod(String p) {
    period.value = p;
    fetchDashboard();
  }

  void applyPeriodFilter(String p) {
    selectedPeriod.value = p;
    period.value = p;
    useCustomDateRange.value = false;
    startDate.value = null;
    endDate.value = null;
    fetchDashboard();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    useCustomDateRange.value = true;
    selectedPeriod.value = 'custom';
    period.value = 'custom';
    fetchDashboard();
  }

  void clearCustomDateRange() {
    startDate.value = null;
    endDate.value = null;
    useCustomDateRange.value = false;
    selectedPeriod.value = 'month';
    period.value = 'month';
    fetchDashboard();
  }

  void navigateTo(String route) => Get.toNamed(route);
}
