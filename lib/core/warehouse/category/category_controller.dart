// lib/core/warehouse/category/category_controller.dart - WITH SUB-CATEGORY SUPPORT

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  var categories = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'All'.obs;

  // KPI
  RxInt totalCategories = 0.obs;
  RxInt totalSubCategories = 0.obs;
  RxInt totalProducts = 0.obs;
  RxInt rootCategories = 0.obs;

  final List<String> filters = ['All', 'Main Categories', 'Sub-Categories', 'With Products', 'Empty'];

  var filteredCategories = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final response = await _api.get('/api/warehouse/categories');
      if (response.success && response.data['success'] == true) {
        categories.value = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        _applyFilter();
        _updateKpi();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCategories() async {
    await fetchCategories();
  }

  void _updateKpi() {
    totalCategories.value = categories.length;
    rootCategories.value = categories.where((c) => c['parentId'] == null).length;
    totalSubCategories.value = categories.where((c) => c['parentId'] != null).length;
    totalProducts.value = categories.fold(
      0,
      (sum, c) => sum + ((c['productCount'] ?? 0) as int),
    );
  }

  void _applyFilter() {
    List<Map<String, dynamic>> list = List.from(categories);

    // Search
    if (searchQuery.value.isNotEmpty) {
      list = list
          .where(
            (c) => (c['name'] ?? '').toString().toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ),
          )
          .toList();
    }

    // Filter
    if (selectedFilter.value == 'Main Categories') {
      list = list.where((c) => c['parentId'] == null).toList();
    } else if (selectedFilter.value == 'Sub-Categories') {
      list = list.where((c) => c['parentId'] != null).toList();
    } else if (selectedFilter.value == 'With Products') {
      list = list.where((c) => (c['productCount'] ?? 0) > 0).toList();
    } else if (selectedFilter.value == 'Empty') {
      list = list.where((c) => (c['productCount'] ?? 0) == 0).toList();
    }

    filteredCategories.value = list;
  }

  void searchCategories(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void clearSearch() {
    searchQuery.value = '';
    _applyFilter();
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final response = await _api.post('/api/warehouse/categories', body: data);
      if (response.success && response.data['success'] == true) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/warehouse/categories/$id',
        body: data,
      );
      if (response.success && response.data['success'] == true) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _api.delete('/api/warehouse/categories/$id');
      if (response.success && response.data['success'] == true) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSubCategories(String parentId) async {
    try {
      final response = await _api.get(
        '/api/warehouse/categories/$parentId/sub-categories',
      );
      if (response.success && response.data['success'] == true) {
        final data = response.data['data'];
        final subCategories = data['subCategories'] as List? ?? [];
        return List<Map<String, dynamic>>.from(subCategories);
      }
      return [];
    } catch (e) {
      print('Error fetching sub-categories: $e');
      return [];
    }
  }

  Color getCategoryColor(int level) {
    final colors = [
      const Color(0xFF3498DB), // Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFE74C3C), // Red
      const Color(0xFFF39C12), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE67E22), // Dark Orange
      const Color(0xFF34495E), // Navy
    ];
    return colors[(level - 1) % colors.length];
  }
}