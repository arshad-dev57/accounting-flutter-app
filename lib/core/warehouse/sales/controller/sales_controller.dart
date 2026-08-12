import 'dart:convert';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:BisonsTechs_app/core/warehouse/sales/model/sales_dashboard_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxString period = 'year'.obs;
  final RxString selectedPeriod = 'year'.obs;
  final RxString selectedTimePeriodLabel = 'This Year'.obs;
  final RxString businessLogo = ''.obs;
  final Rx<SalesDashboardModel?> dashboard = Rx<SalesDashboardModel?>(null);

  // Custom date range
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxBool useCustomDateRange = false.obs;

  static const periods = ['today', 'week', 'month', 'year'];

  static const timePeriodLabels = [
    'Today',
    'Last Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
  ];

  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    loadBusinessLogo();
    Future(() async {
      await waitForFiscalYearReady();
      fetchDashboard();
    });
    _fyWorker = listenFiscalYearChanges(fetchDashboard);
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    super.onClose();
  }

  Future<void> loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails =
            userData['businessDetails'] as Map<String, dynamic>?;

        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            businessLogo.value = logo;
          }
        }
      }
    } catch (e) {
      print('❌ [SalesController] Error loading business logo: $e');
    }
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;

      final queryParams = <String, dynamic>{'period': period.value};

      // Add custom date range if selected
      if (useCustomDateRange.value &&
          startDate.value != null &&
          endDate.value != null) {
        queryParams['startDate'] = _formatDate(startDate.value!);
        queryParams['endDate'] = _formatDate(endDate.value!);
        queryParams['period'] = 'custom';
      }
      putFiscalYearId(queryParams);

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

        if (!data.containsKey('pos')) {
          data['pos'] = {
            'count': 0,
            'revenue': 0,
            'todayCount': 0,
            'todayRevenue': 0,
            'trend': [],
          };
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

  void selectTimePeriod(String label) {
    selectedTimePeriodLabel.value = label;
    applyPeriodFilter(_mapPeriod(label));
  }

  String _mapPeriod(String label) {
    switch (label) {
      case 'Today':
        return 'today';
      case 'Last Week':
        return 'week';
      case 'This Month':
        return 'month';
      case 'Last Month':
        return 'month';
      case 'This Quarter':
        return 'year';
      case 'This Year':
        return 'year';
      default:
        return 'today';
    }
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    useCustomDateRange.value = true;
    selectedPeriod.value = 'custom';
    period.value = 'custom';
    selectedTimePeriodLabel.value = 'Custom';
    fetchDashboard();
  }

  void clearCustomDateRange() {
    startDate.value = null;
    endDate.value = null;
    useCustomDateRange.value = false;
    selectedPeriod.value = 'today';
    period.value = 'today';
    selectedTimePeriodLabel.value = 'Today';
    fetchDashboard();
  }

  void navigateTo(String route) => Get.toNamed(route);
}
