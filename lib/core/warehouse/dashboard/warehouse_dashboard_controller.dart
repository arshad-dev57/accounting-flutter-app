import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarehouseDashboardController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final RxMap<String, int> orderStatus = <String, int>{}.obs;

  var selectedIndex = 0.obs;
  var isSidebarOpen = true.obs;
  var currentRoute = '/warehouse/dashboard'.obs;

  final RxInt reportSubIndex = 0.obs;
  final RxBool isReportView = false.obs;

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;
  final RxString businessLogo = ''.obs;

  // Dashboard Metrics
  final RxInt totalProducts = 0.obs;
  final RxDouble totalStockValue = 0.0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxInt outOfStockCount = 0.obs;
  final RxInt overstockCount = 0.obs;
  final RxInt expiringCount = 0.obs;
  final RxInt todayStockIn = 0.obs;
  final RxInt todayStockOut = 0.obs;
  final RxInt pendingOrders = 0.obs;
  final RxDouble todayRevenue = 0.0.obs;
  final RxInt totalOrders = 0.obs;

  // Period Filter — today | week | month | year | custom
  final RxString selectedPeriod = 'year'.obs;
  final RxString selectedPeriodLabel = 'This Year'.obs;
  final Rx<DateTime?> customStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> customEndDate = Rx<DateTime?>(null);

  static const periodLabels = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  // Chart Data
  final RxList<Map<String, dynamic>> stockMovementChart =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categoryDistribution =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topProducts = <Map<String, dynamic>>[].obs;

  // Activities
  final RxList<Map<String, dynamic>> recentActivities =
      <Map<String, dynamic>>[].obs;

  // Menu Items with routes
  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.dashboard_rounded,
      'title': 'Dashboard',
      'route': '/warehouse/dashboard',
    },
    {
      'icon': Icons.inventory_2_rounded,
      'title': 'Products',
      'route': '/warehouse/products',
    },
    {
      'icon': Icons.category_rounded,
      'title': 'Categories',
      'route': '/warehouse/categories',
    },
    {
      'icon': Icons.people_rounded,
      'title': 'Suppliers',
      'route': '/warehouse/suppliers',
    },
    {
      'icon': Icons.people_outline_rounded,
      'title': 'Customers',
      'route': '/sales/warehouse-customers',
    },
    {
      'icon': Icons.receipt_rounded,
      'title': 'Invoices',
      'route': '/warehouse/invoices',
    },
    {
      'icon': Icons.local_shipping_rounded,
      'title': 'Stock Movement',
      'route': '/warehouse/stock',
    },
    {
      'icon': Icons.assessment_rounded,
      'title': 'Inventory Valuation',
      'route': '/warehouse/inventory',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Reports',
      'route': '/warehouse/reports',
    },
  ];
  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    loadBusinessLogo();
    Future(() async {
      await waitForFiscalYearReady();
      loadDashboardData();
    });
    _fyWorker = listenFiscalYearChanges(loadDashboardData);
    ever(currentRoute, (route) {
      _updateSelectedIndex(route);
    });
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
      print('❌ [WarehouseDashboardController] Error loading business logo: $e');
    }
  }

  // ─── Currency Helper ──────────────────────────────────────────────
  String formatCurrency(double value) {
    return Get.find<CurrencyController>().formatAmount(value);
  }

  String getCurrencySymbol() {
    return Get.find<CurrencyController>().currencySymbol.value;
  }

  // ─── Period Filter ────────────────────────────────────────
  String mapPeriodLabel(String label) {
    switch (label) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'week';
      case 'This Month':
        return 'month';
      case 'This Year':
        return 'year';
      case 'Custom':
        return 'custom';
      default:
        return 'today';
    }
  }

  Future<void> selectPeriodLabel(String label) async {
    selectedPeriodLabel.value = label;
    await applyPeriodFilter(mapPeriodLabel(label));
  }

  Future<void> applyPeriodFilter(
    String period, {
    DateTime? start,
    DateTime? end,
  }) async {
    selectedPeriod.value = period;
    if (period == 'custom') {
      selectedPeriodLabel.value = 'Custom';
      customStartDate.value = start;
      customEndDate.value = end;
    } else {
      customStartDate.value = null;
      customEndDate.value = null;
      selectedPeriodLabel.value = getPeriodLabel();
    }
    await loadDashboardData();
  }

  Map<String, dynamic> get _periodQueryParams {
    final params = <String, dynamic>{'period': selectedPeriod.value};
    if (selectedPeriod.value == 'custom') {
      if (customStartDate.value != null)
        params['startDate'] = customStartDate.value!.toIso8601String();
      if (customEndDate.value != null)
        params['endDate'] = customEndDate.value!.toIso8601String();
    }
    putFiscalYearId(params);
    return params;
  }

  // ─── Navigation ──────────────────────────────────────────────────
  void navigateTo(int index) {
    final route = menuItems[index]['route'];
    selectedIndex.value = index;
    isReportView.value = false;
    reportSubIndex.value = 0;
    currentRoute.value = route;
    Get.toNamed(route);
  }

  void navigateToReportDetail(int index) {
    reportSubIndex.value = index;
    isReportView.value = true;

    String route;
    switch (index) {
      case 0:
        route = '/warehouse/reports/stock-summary';
        break;
      case 1:
        route = '/warehouse/reports/low-stock';
        break;
      case 2:
        route = '/warehouse/reports/expiry';
        break;
      default:
        route = '/warehouse/reports';
    }

    currentRoute.value = route;
    Get.toNamed(route);
  }

  void _updateSelectedIndex(String route) {
    for (int i = 0; i < menuItems.length; i++) {
      if (menuItems[i]['route'] == route) {
        selectedIndex.value = i;
        isReportView.value = false;
        return;
      }
    }
    if (route.contains('/warehouse/reports')) {
      isReportView.value = true;
    }
  }

  void toggleSidebar() {
    isSidebarOpen.value = !isSidebarOpen.value;
  }

  // ─── Dashboard Data ──────────────────────────────────────────────
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      error.value = '';

      await Future.wait([
        _fetchMetrics(),
        _fetchActivities(),
        _fetchStockMovementChart(),
        _fetchCategoryDistribution(),
        _fetchTopProducts(),
        _fetchOrderStatus(),
      ]);

      print('✅ Dashboard data loaded successfully');
    } catch (e) {
      error.value = e.toString();
      print('❌ Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMetrics() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/metrics',
        requiresAuth: true,
        queryParameters: _periodQueryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;

        totalProducts.value = data['totalProducts'] ?? 0;
        totalStockValue.value = (data['totalStockValue'] ?? 0).toDouble();
        lowStockCount.value = data['lowStockCount'] ?? 0;
        outOfStockCount.value = data['outOfStockCount'] ?? 0;
        overstockCount.value = data['overstockCount'] ?? 0;
        expiringCount.value = data['expiringCount'] ?? 0;
        todayStockIn.value = data['todayStockIn'] ?? 0;
        todayStockOut.value = data['todayStockOut'] ?? 0;
        pendingOrders.value = data['pendingOrders'] ?? 0;
        todayRevenue.value = (data['todayRevenue'] ?? 0).toDouble();
      } else {
        print('❌ Metrics API failed: ${response.message}');
      }
    } catch (e) {
      print('❌ Error fetching metrics: $e');
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/activities',
        requiresAuth: true,
      );

      print('📋 Activities Response: ${response.statusCode}');

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final activities = data['activities'] as List? ?? [];

        recentActivities.value = activities.map((item) {
          return {
            'id': item['_id'] ?? '',
            'user': item['user']?['name'] ?? item['userName'] ?? 'Unknown',
            'action': item['action'] ?? '',
            'details': item['details'] ?? '',
            'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        print('✅ Activities loaded: ${recentActivities.length}');
      } else {
        print('❌ Activities API failed: ${response.message}');
      }
    } catch (e) {
      print('❌ Error fetching activities: $e');
    }
  }

  Future<void> _fetchStockMovementChart() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/charts/stock-movement',
        requiresAuth: true,
        queryParameters: _periodQueryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as List? ?? [];
        stockMovementChart.value = data.map((item) {
          return {
            'label': item['label'] ?? '',
            'stockIn': item['stockIn'] ?? 0,
            'stockOut': item['stockOut'] ?? 0,
            'date': item['date'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      print('❌ Error fetching stock movement chart: $e');
    }
  }

  Future<void> _fetchCategoryDistribution() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/charts/categories',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final categories = data['categories'] as List? ?? [];
        categoryDistribution.value = categories.map((item) {
          return {
            'categoryName': item['categoryName'] ?? 'Unknown',
            'productCount': item['productCount'] ?? 0,
            'percentage': item['percentage'] ?? 0.0,
            'color': item['color'] ?? '#2196F3',
          };
        }).toList();
        print('✅ Category distribution loaded: ${categoryDistribution.length}');
      }
    } catch (e) {
      print('❌ Error fetching category distribution: $e');
    }
  }

  Future<void> _fetchTopProducts() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/charts/top-products',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as List? ?? [];
        topProducts.value = data.map((item) {
          return {
            'label': item['label'] ?? 'Product',
            'value': item['value'] ?? 0,
            'color': item['color'] ?? '#2196F3',
          };
        }).toList();
        print('✅ Top products loaded: ${topProducts.length}');
      }
    } catch (e) {
      print('❌ Error fetching top products: $e');
    }
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final response = await _apiClient.get(
        '/api/warehouse/dashboard/charts/order-status',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;

        orderStatus.value = {
          'pending': data['pending'] ?? 0,
          'processing': data['processing'] ?? 0,
          'shipped': data['shipped'] ?? 0,
          'completed': data['completed'] ?? 0,
          'cancelled': data['cancelled'] ?? 0,
        };

        print('✅ Order status loaded: ${orderStatus.value}');
      }
    } catch (e) {
      print('❌ Error fetching order status: $e');
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String getPeriodLabel() {
    switch (selectedPeriod.value) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      case 'custom':
        if (customStartDate.value != null && customEndDate.value != null) {
          final s = customStartDate.value!;
          final e = customEndDate.value!;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom';
      default:
        return 'Today';
    }
  }
}
