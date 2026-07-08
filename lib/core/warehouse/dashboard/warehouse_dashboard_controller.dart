import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';

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
      'icon': Icons.dashboard,
      'title': 'Dashboard',
      'route': '/warehouse/dashboard',
    },
    {
      'icon': Icons.inventory,
      'title': 'Products',
      'route': '/warehouse/products',
    },
    {
      'icon': Icons.category,
      'title': 'Categories',
      'route': '/warehouse/categories',
    },
    {
      'icon': Icons.people,
      'title': 'Suppliers',
      'route': '/warehouse/suppliers',
    },
    {
      'icon': Icons.trending_up,
      'title': 'Sales',
      'route': '/warehouse/sales',
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Orders',
      'route': '/warehouse/orders',
    },
    {
      'icon': Icons.receipt_long,
      'title': 'Invoices',
      'route': '/warehouse/invoices',
    },
    {
      'icon': Icons.replay,
      'title': 'Refunds',
      'route': '/warehouse/refunds',
    },
    {
      'icon': Icons.assignment_return,
      'title': 'Returns',
      'route': '/warehouse/returns',
    },
    {
      'icon': Icons.local_shipping,
      'title': 'Purchases',
      'route': '/warehouse/purchases',
    },
    {
      'icon': Icons.warehouse,
      'title': 'Stock Movement',
      'route': '/warehouse/stock',
    },
    {
      'icon': Icons.inventory,
      'title': 'Inventory Valuation',
      'route': '/warehouse/inventory',
    },
    {
      'icon': Icons.receipt_long,
      'title': 'Reports',
      'route': '/warehouse/reports',
    },
    {
      'icon': Icons.currency_exchange,
      'title': 'Currency',
      'route': '/warehouse/currency',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    ever(currentRoute, (route) {
      _updateSelectedIndex(route);
    });
  }

  // ─── Currency Helper ──────────────────────────────────────────────
  String formatCurrency(double value) {
    return Get.find<CurrencyController>().formatAmount(value);
  }

  String getCurrencySymbol() {
    return Get.find<CurrencyController>().currencySymbol.value;
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
      );

      print('📊 Metrics Response: ${response.statusCode}');

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

        print(
          '✅ Metrics loaded: Products=${totalProducts.value}, Revenue=${todayRevenue.value}',
        );
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
        print('✅ Stock movement chart loaded: ${stockMovementChart.length}');
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
    return '${now.day}/${now.month}/${now.year}';
  }
}
