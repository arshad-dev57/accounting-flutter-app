// settings_controller.dart
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:flutter/material.dart';

// ============================================================
// MODELS
// ============================================================
class SettingItem {
  final String id;
  final String name;
  final String category;
  final bool isDefault;
  final String? symbol;
  final String? code;
  final String? zone;

  SettingItem({
    required this.id,
    required this.name,
    required this.category,
    this.isDefault = false,
    this.symbol,
    this.code,
    this.zone,
  });

  factory SettingItem.fromJson(Map<String, dynamic> json) {
    return SettingItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      isDefault: json['isDefault'] ?? false,
      symbol: json['symbol']?.toString(),
      code: json['code']?.toString(),
      zone: json['zone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'category': category,
      'isDefault': isDefault,
    };
    if (symbol != null) map['symbol'] = symbol;
    if (code != null) map['code'] = code;
    if (zone != null) map['zone'] = zone;
    return map;
  }
}

class SettingCategory {
  final String id;
  final String label;
  final String description;
  final String iconName;

  const SettingCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.iconName,
  });
}

// ============================================================
// CONSTANTS
// ============================================================
const List<SettingCategory> productSettingCategories = [
  SettingCategory(
    id: 'productType',
    label: 'Product Types',
    description: 'Manage product types',
    iconName: 'package',
  ),
  SettingCategory(
    id: 'rackLocation',
    label: 'Rack Locations',
    description: 'Manage warehouse rack locations',
    iconName: 'map_pin',
  ),
  SettingCategory(
    id: 'zone',
    label: 'Zones',
    description: 'Manage warehouse zones',
    iconName: 'layers',
  ),
  SettingCategory(
    id: 'weightUnit',
    label: 'Weight Units',
    description: 'Manage weight units',
    iconName: 'scale',
  ),
  SettingCategory(
    id: 'dimensionUnit',
    label: 'Dimension Units',
    description: 'Manage dimension units',
    iconName: 'ruler',
  ),
  SettingCategory(
    id: 'size',
    label: 'Sizes',
    description: 'Manage product sizes',
    iconName: 'tag',
  ),
  SettingCategory(
    id: 'shippingClass',
    label: 'Shipping Classes',
    description: 'Manage shipping classes',
    iconName: 'truck',
  ),
  SettingCategory(
    id: 'stockUnit',
    label: 'Stock Units',
    description: 'Manage stock units',
    iconName: 'box',
  ),
];

const List<SettingCategory> orderSettingCategories = [
  SettingCategory(
    id: 'orderType',
    label: 'Order Types',
    description: 'Manage order types',
    iconName: 'shopping_cart',
  ),
  SettingCategory(
    id: 'priority',
    label: 'Priorities',
    description: 'Manage order priorities',
    iconName: 'clock',
  ),
  SettingCategory(
    id: 'orderSource',
    label: 'Order Sources',
    description: 'Manage order sources',
    iconName: 'globe',
  ),
  SettingCategory(
    id: 'shippingMethod',
    label: 'Shipping Methods',
    description: 'Manage shipping methods',
    iconName: 'truck',
  ),
  SettingCategory(
    id: 'paymentMethod',
    label: 'Payment Methods',
    description: 'Manage payment methods',
    iconName: 'credit_card',
  ),
  SettingCategory(
    id: 'shippingCarrier',
    label: 'Shipping Carriers',
    description: 'Manage shipping carriers',
    iconName: 'boxes',
  ),
  SettingCategory(
    id: 'physicalStatus',
    label: 'Physical Status',
    description: 'Manage physical status',
    iconName: 'shield',
  ),
];

// ============================================================
// CONTROLLER
// ============================================================
class SettingsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── Tab Controller ──────────────────────────────────────────
  late final TabController tabController;

  final RxString activeCategory = 'productType'.obs;
  final RxList<SettingItem> items = <SettingItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString successMessage = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  List<SettingItem> get filteredItems {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.code?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  SettingCategory? get activeCategoryInfo {
    final all = [...productSettingCategories, ...orderSettingCategories];
    try {
      return all.firstWhere((c) => c.id == activeCategory.value);
    } catch (_) {
      return null;
    }
  }

  // ─── Get categories based on active tab ─────────────────────
  List<SettingCategory> get currentCategories {
    final tabIndex = tabController.index;
    return tabIndex == 0 ? productSettingCategories : orderSettingCategories;
  }

  // ─── Get current tab label ──────────────────────────────────
  String get currentTabLabel {
    return tabController.index == 0 ? 'Product' : 'Order';
  }

  // ─── Lifecycle ──────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        // When tab changes, reset to first category of that tab
        final categories = currentCategories;
        if (categories.isNotEmpty) {
          activeCategory.value = categories.first.id;
          searchQuery.value = '';
          fetchSettings();
        }
      }
    });

    // Initialize with first product category
    if (productSettingCategories.isNotEmpty) {
      activeCategory.value = productSettingCategories.first.id;
    }
    fetchSettings();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ─── Set category and fetch ─────────────────────────────────
  void setCategory(String categoryId) {
    activeCategory.value = categoryId;
    searchQuery.value = '';
    fetchSettings();
  }

  // ─── Fetch Settings ─────────────────────────────────────────
  Future<void> fetchSettings() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.get(
        '/api/settings',
        queryParameters: {'category': activeCategory.value},
      );

      print('Response status: ${response.statusCode}');
      print('Response success: ${response.success}');
      print('Response data: ${response.data}');

      if (response.success) {
        final data = response.data;
        print('Full response data: $data');

        // Check if data is a Map
        if (data is Map<String, dynamic>) {
          // Check if success is true
          if (data['success'] == true) {
            // Get the data array - handle different response structures
            List list = [];

            // Try different possible response structures
            if (data['data'] != null) {
              if (data['data'] is List) {
                // Direct list: { "success": true, "data": [...] }
                list = data['data'] as List;
              } else if (data['data'] is Map && data['data']['data'] != null) {
                // Nested: { "success": true, "data": { "data": [...] } }
                list = data['data']['data'] as List;
              } else if (data['data'] is Map && data['data']['items'] != null) {
                // Nested with items: { "success": true, "data": { "items": [...] } }
                list = data['data']['items'] as List;
              } else if (data['data'] is Map && data['data']['list'] != null) {
                // Nested with list: { "success": true, "data": { "list": [...] } }
                list = data['data']['list'] as List;
              }
            } else if (data['items'] != null && data['items'] is List) {
              // Direct items: { "success": true, "items": [...] }
              list = data['items'] as List;
            } else if (data['list'] != null && data['list'] is List) {
              // Direct list: { "success": true, "list": [...] }
              list = data['list'] as List;
            }

            print('Found ${list.length} items');

            items.value = list.map((e) {
              print('Processing item: $e');
              return SettingItem.fromJson(e as Map<String, dynamic>);
            }).toList();
          } else {
            _showError(data['message'] ?? 'Failed to load settings');
          }
        } else {
          _showError('Invalid response format');
        }
      } else {
        _showError(response.message ?? 'Failed to load settings');
      }
    } catch (e, stackTrace) {
      print('Error fetching settings: $e');
      print('Stack trace: $stackTrace');
      _showError('Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Create Setting ─────────────────────────────────────────
  Future<bool> createSetting(Map<String, dynamic> payload) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.post('/api/settings', body: payload);

      print('Create response: ${response.data}');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          _showSuccess('Item added successfully!');
          await fetchSettings();
          return true;
        } else {
          _showError(data['message'] ?? 'Failed to create');
          return false;
        }
      } else {
        _showError(response.message ?? 'Failed to create');
        return false;
      }
    } catch (e) {
      print('Error creating setting: $e');
      _showError('Network error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Update Setting ─────────────────────────────────────────
  Future<bool> updateSetting(String id, Map<String, dynamic> payload) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final response = await _api.put('/api/settings/$id', body: payload);

      print('Update response: ${response.data}');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          _showSuccess('Item updated successfully!');
          await fetchSettings();
          return true;
        } else {
          _showError(data['message'] ?? 'Failed to update');
          return false;
        }
      } else {
        _showError(response.message ?? 'Failed to update');
        return false;
      }
    } catch (e) {
      print('Error updating setting: $e');
      _showError('Network error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Delete Setting ─────────────────────────────────────────
  Future<void> deleteSetting(String id) async {
    final item = items.firstWhereOrNull((i) => i.id == id);
    if (item?.isDefault == true) {
      _showError('Cannot delete default item. Set another as default first.');
      return;
    }

    try {
      final response = await _api.delete('/api/settings/$id');

      print('Delete response: ${response.data}');

      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          _showSuccess('Item deleted successfully!');
          await fetchSettings();
        } else {
          _showError(data['message'] ?? 'Failed to delete');
        }
      } else {
        _showError(response.message ?? 'Failed to delete');
      }
    } catch (e) {
      print('Error deleting setting: $e');
      _showError('Network error: $e');
    }
  }

  // ─── Helper Methods ─────────────────────────────────────────
  void _showSuccess(String msg) {
    successMessage.value = msg;
    Future.delayed(const Duration(seconds: 3), () => successMessage.value = '');
  }

  void _showError(String msg) {
    errorMessage.value = msg;
    Future.delayed(const Duration(seconds: 3), () => errorMessage.value = '');
  }
}
