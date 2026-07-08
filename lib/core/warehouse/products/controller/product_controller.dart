import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';

class ProductsController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── KPI Counts ───────────────────────────────────────────────
  RxInt inStockCount    = 0.obs;
  RxInt lowStockCount   = 0.obs;
  RxInt outOfStockCount = 0.obs;
  RxInt categoriesCount = 0.obs;

  // ─── Categories & Suppliers ───────────────────────────────────
  var categories  = <Map<String, dynamic>>[].obs;
  var suppliers   = <Map<String, dynamic>>[].obs;
  var isSubmitting = false.obs;

  // ─── Settings dropdowns ───────────────────────────────────────
  var productTypes      = <Map<String, dynamic>>[].obs;
  var weightUnits       = <Map<String, dynamic>>[].obs;
  var dimensionUnits    = <Map<String, dynamic>>[].obs;
  var stockUnits        = <Map<String, dynamic>>[].obs;
  var taxTypes          = <Map<String, dynamic>>[].obs;
  var rackLocations     = <Map<String, dynamic>>[].obs;
  var zones             = <Map<String, dynamic>>[].obs;
  var sizes             = <Map<String, dynamic>>[].obs;
  var shippingClasses   = <Map<String, dynamic>>[].obs;
  var storageConditions = <Map<String, dynamic>>[].obs;

  // ─── Order Settings ───────────────────────────────────────────
  var orderTypes       = <Map<String, dynamic>>[].obs;
  var priorities       = <Map<String, dynamic>>[].obs;
  var orderSources     = <Map<String, dynamic>>[].obs;
  var shippingMethods  = <Map<String, dynamic>>[].obs;
  var paymentMethods   = <Map<String, dynamic>>[].obs;
  var shippingCarriers = <Map<String, dynamic>>[].obs;

  // ─── Mobile Infinite Scroll ───────────────────────────────────
  var isLoadingMore = false.obs;
  var hasMore       = true.obs;
  int _mobilePage   = 1;

  // ─── Main Products List ───────────────────────────────────────
  var products       = <Map<String, dynamic>>[].obs;
  var isLoading      = false.obs;
  var searchQuery    = ''.obs;
  var selectedFilter = 'All'.obs;
  var currentPage    = 1.obs;
  var totalPages     = 1.obs;
  var totalProducts  = 0.obs;

  final List<String> filters = ['All', 'Low Stock', 'Out of Stock', 'In Stock'];

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      fetchProducts(),
      fetchCategories(),
      fetchSuppliers(),
      _fetchSettings(),
    ]);
  }

  // ─── Currency ─────────────────────────────────────────────────
  String formatCurrency(double amount) {
    try {
      return Get.find<CurrencyController>().formatAmount(amount);
    } catch (_) {
      return 'Rs ${amount.toStringAsFixed(2)}';
    }
  }

  String getCurrencySymbol() {
    try {
      return Get.find<CurrencyController>().currencySymbol.value;
    } catch (_) {
      return 'Rs';
    }
  }

  // ─── Settings ─────────────────────────────────────────────────
  Future<void> _fetchSettings() async {
    final cats = [
      'productType', 'weightUnit', 'dimensionUnit',
      'stockUnit', 'taxType', 'rackLocation',
      'zone', 'size', 'shippingClass', 'storageCondition',
    ];
    await Future.wait(cats.map((cat) => _fetchSetting(cat)));
  }

  Future<void> _fetchSetting(String category) async {
    try {
      final response = await _api.get(
        '/api/settings',
        queryParameters: {'category': category},
      );
      if (response.success == true) {
        // Backend returns: { success: true, data: [...] }
        // formatResponse gives: { id, name, isDefault, displayOrder, isActive, ...metadata }
        final rawData = response.data['data'];
        final List<Map<String, dynamic>> data;

        if (rawData is List) {
          data = List<Map<String, dynamic>>.from(rawData);
        } else if (rawData is Map && rawData['data'] is List) {
          data = List<Map<String, dynamic>>.from(rawData['data']);
        } else {
          data = [];
        }

        // Filter only active settings
        final active = data.where((d) => d['isActive'] != false).toList();

        switch (category) {
          case 'productType':      productTypes.value      = active; break;
          case 'weightUnit':       weightUnits.value       = active; break;
          case 'dimensionUnit':    dimensionUnits.value    = active; break;
          case 'stockUnit':        stockUnits.value        = active; break;
          case 'taxType':          taxTypes.value          = active; break;
          case 'rackLocation':     rackLocations.value     = active; break;
          case 'zone':             zones.value             = active; break;
          case 'size':             sizes.value             = active; break;
          case 'shippingClass':    shippingClasses.value   = active; break;
          case 'storageCondition': storageConditions.value = active; break;
        }
      }
    } catch (e) {
      debugPrint('Error fetching setting $category: $e');
    }
  }

  // ─── Categories ───────────────────────────────────────────────
  // Backend returns tree with 'id' (not '_id') and 'children' (not 'subCategories')
  Future<void> fetchCategories() async {
    try {
      final response = await _api.get(
        '/api/warehouse/categories',
        queryParameters: {'tree': true},
      );
      if (response.success && response.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        final seen = <String>{};
        categories.value = raw.where((c) {
          // Backend uses 'id' (Prisma), not '_id' (MongoDB)
          final id = c['id']?.toString() ?? c['_id']?.toString() ?? '';
          if (id.isEmpty) return false;
          return seen.add(id);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // ─── Suppliers ────────────────────────────────────────────────
  Future<void> fetchSuppliers() async {
    try {
      final response = await _api.get(
        '/api/warehouse/suppliers',
        queryParameters: {'limit': 100},
      );
      if (response.success && response.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        final seen = <String>{};
        suppliers.value = raw.where((s) {
          // Backend uses 'id' (Prisma), not '_id' (MongoDB)
          final id = s['id']?.toString() ?? s['_id']?.toString() ?? '';
          if (id.isEmpty) return false;
          return seen.add(id);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    }
  }

  // ─── Sub-categories helper ────────────────────────────────────
  // Backend tree: { id, name, children: [...] }
  List<Map<String, dynamic>> getSubCategories(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return [];
    final parent = categories.firstWhereOrNull(
      (c) =>
          c['id']?.toString() == categoryId ||   // Prisma 'id'
          c['_id']?.toString() == categoryId,    // fallback MongoDB '_id'
    );
    if (parent == null) return [];
    // Backend returns 'children' from buildCategoryTree()
    final subs = parent['children'] ?? parent['subCategories'] ?? [];
    return List<Map<String, dynamic>>.from(subs);
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final response = await _api.post('/api/warehouse/products', body: data);
      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating product: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      isSubmitting.value = true;
      final response = await _api.put('/api/warehouse/products/$id', body: data);
      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _api.delete('/api/warehouse/products/$id');
      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  String generateSku() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'SKU-${ts.substring(ts.length - 6)}';
  }

  // ─── KPI ──────────────────────────────────────────────────────
  void _updateKpiCounts() {
    inStockCount.value = products
        .where((p) => (p['currentStock'] ?? 0) > 5)
        .length;
    lowStockCount.value = products.where((p) {
      final s = p['currentStock'] ?? 0;
      return s > 0 && s <= 5;
    }).length;
    outOfStockCount.value = products
        .where((p) => (p['currentStock'] ?? 0) <= 0)
        .length;
    categoriesCount.value =
        products.map((p) => p['categoryName']).toSet().length;
  }

  // ─── Query ────────────────────────────────────────────────────
  Map<String, dynamic> _buildQueryParams(int page) {
    final Map<String, dynamic> params = {'page': page, 'limit': 20};
    if (searchQuery.value.isNotEmpty) params['q'] = searchQuery.value;
    if (selectedFilter.value == 'Low Stock')     params['stockStatus'] = 'low';
    if (selectedFilter.value == 'Out of Stock')  params['stockStatus'] = 'out_of_stock';
    return params;
  }

  // ─── Fetch Products ───────────────────────────────────────────
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: _buildQueryParams(currentPage.value),
      );
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          products.value =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
          totalPages.value    = data['pagination']?['pages'] ?? 1;
          totalProducts.value = data['pagination']?['total'] ?? 0;
          _updateKpiCounts();
        }
      }
      _mobilePage = 1;
      hasMore.value = totalPages.value > 1;
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Infinite Scroll ──────────────────────────────────────────
  Future<void> fetchMoreProducts() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final nextPage = _mobilePage + 1;
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: _buildQueryParams(nextPage),
      );
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          final newItems =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
          final pages = data['pagination']?['pages'] ?? 1;
          products.addAll(newItems);
          totalPages.value    = pages;
          totalProducts.value =
              data['pagination']?['total'] ?? totalProducts.value;
          _mobilePage = nextPage;
          hasMore.value = _mobilePage < pages && newItems.isNotEmpty;
          _updateKpiCounts();
        }
      }
    } catch (e) {
      debugPrint('Error fetching more: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────
  void refreshAll() {
    currentPage.value = 1;
    _mobilePage       = 1;
    hasMore.value     = true;
    fetchProducts();
  }

  Future<void> refreshProducts() async {
    await Future.wait([
      fetchCategories(),
      fetchSuppliers(),
      fetchProducts(),
    ]);
  }

  // ─── Search & Filter ──────────────────────────────────────────
  void searchProducts(String query) { searchQuery.value = query; refreshAll(); }
  void clearSearch()                { searchQuery.value = '';    refreshAll(); }
  void filterProducts(String filter){ selectedFilter.value = filter; refreshAll(); }

  // ─── Pagination (Web) ─────────────────────────────────────────
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchProducts();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchProducts();
    }
  }

  // ─── Stock Helpers ────────────────────────────────────────────
  String getStockStatus(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  Color getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }
}