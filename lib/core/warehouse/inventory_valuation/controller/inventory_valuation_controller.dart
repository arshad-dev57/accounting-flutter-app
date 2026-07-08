import 'package:LedgerPro_app/core/warehouse/inventory_valuation/model/inventory_valuation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';

class InventoryValuationController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxList<InventoryValuationModel> items = <InventoryValuationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;

  final RxString selectedCategory = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'name'.obs;
  final RxString sortOrder = 'asc'.obs;

  final Rx<ValuationSummary?> summary = Rx<ValuationSummary?>(null);

  final RxList<CategoryBreakdown> categoryBreakdown = <CategoryBreakdown>[].obs;

  final RxList<String> categories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchValuationData();
  }

  Future<void> fetchValuationData() async {
    isLoading.value = true;
    try {
      final queryParams = <String, dynamic>{};
      if (selectedCategory.value != 'all') {
        queryParams['category'] = selectedCategory.value;
      }
      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }
      queryParams['sortBy'] = sortBy.value;
      queryParams['sortOrder'] = sortOrder.value;

      print('Fetching valuation data with params: $queryParams');

      final response = await _apiClient.get(
        '/api/warehouse/inventory/valuation',
        queryParameters: queryParams,
        requiresAuth: true,
      );

      print('Valuation response success: ${response.success}');
      print('Valuation response data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data['data'];

        if (data != null) {
          final itemsList = data['items'] as List? ?? [];
          print('Items count: ${itemsList.length}');

          items.value = itemsList
              .map((item) => InventoryValuationModel.fromJson(item))
              .toList();

          print('Parsed items count: ${items.value.length}');
          if (data['summary'] != null) {
            summary.value = ValuationSummary.fromJson(data['summary']);
            print('Summary parsed successfully');
          }
          final breakdownList = data['categoryBreakdown'] as List? ?? [];
          categoryBreakdown.value = breakdownList
              .map((item) => CategoryBreakdown.fromJson(item))
              .toList();

          // Extract categories for filter
          final categoryNames = items.value
              .map((item) => item.category)
              .toSet()
              .toList();
          categories.value = categoryNames;
        }
      } else {
        print('Valuation API failed: ${response.message}');
      }
    } catch (e) {
      print('Error fetching valuation data: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await fetchValuationData();
  }

  // Filter by category
  void filterByCategory(String category) {
    selectedCategory.value = category;
    fetchValuationData();
  }

  // Search products
  void searchProducts(String query) {
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;
    fetchValuationData();
  }

  void clearSearch() {
    searchQuery.value = '';
    isSearching.value = false;
    fetchValuationData();
  }

  // Sort products
  void sortByField(String field) {
    if (sortBy.value == field) {
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      sortBy.value = field;
      sortOrder.value = 'asc';
    }
    fetchValuationData();
  }

  // ─── Helper Methods ────────────────────────────────────────────

  String formatCurrency(double value) {
    final currencyController = Get.find<CurrencyController>();
    return currencyController.formatAmount(value);
  }

  String formatCurrencyWithDecimal(double value) {
    final currencyController = Get.find<CurrencyController>();
    return currencyController.formatAmount(value);
  }

  Color getProfitColor(double profit) {
    if (profit > 0) return const Color(0xFF2ECC71);
    if (profit < 0) return const Color(0xFFE74C3C);
    return Colors.grey;
  }

  String getSortIcon(String field) {
    if (sortBy.value != field) return '⇅';
    return sortOrder.value == 'asc' ? '↑' : '↓';
  }
}
