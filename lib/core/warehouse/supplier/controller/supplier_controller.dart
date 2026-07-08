import 'dart:convert';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:get/get.dart';

class SupplierController extends GetxController {
  // ─── State ───────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  final ApiClient apiClient = Get.find<ApiClient>();

  // KPI
  final RxInt totalSuppliers = 0.obs;
  final RxInt activeCount = 0.obs;
  final RxInt inactiveCount = 0.obs;

  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxString errorMessage = ''.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalRecords = 0.obs;
  final int pageSize = 15;

  // Mobile infinite scroll
  final RxBool hasMore = true.obs;
  int _mobilePage = 1;

  // Search / filter
  String _searchQuery = '';
  String _statusFilter = '';

  final List<String> filters = ['All', 'Active', 'Inactive'];

  // ─── Lifecycle ───────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Don't fetch here - let the screen handle it
  }

  // ─── Fetch (web pagination) ───────────────────────────────────
  Future<void> fetchSuppliers({int page = 1}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': pageSize.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      };

      final response = await apiClient.get(
        '/api/warehouse/supplier',
        queryParameters: queryParams,
      );

      if (response.success && response.statusCode == 200) {
        final json = response.data;
        suppliers.value = List<Map<String, dynamic>>.from(json['data'] ?? []);

        // KPI
        final kpi = json['kpi'] ?? {};
        totalSuppliers.value = kpi['total'] ?? 0;
        activeCount.value = kpi['active'] ?? 0;
        inactiveCount.value = kpi['inactive'] ?? 0;

        // Pagination
        final pagination = json['pagination'] ?? {};
        currentPage.value = pagination['page'] ?? 1;
        totalPages.value = pagination['pages'] ?? 1;
        totalRecords.value = pagination['total'] ?? 0;
      } else {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load suppliers';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Mobile: fetch first page fresh ──────────────────────────
  Future<void> fetchSuppliersForMobile() async {
    _mobilePage = 1;
    hasMore.value = true;
    isLoading.value = true;
    suppliers.clear();

    await _fetchMobilePage();
    isLoading.value = false;
  }

  // ─── Mobile: load more (infinite scroll) ─────────────────────
  Future<void> fetchMoreSuppliers() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    _mobilePage++;
    await _fetchMobilePage();
    isLoadingMore.value = false;
  }

  Future<void> _fetchMobilePage() async {
    try {
      final queryParams = {
        'page': _mobilePage.toString(),
        'limit': pageSize.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      };

      final response = await apiClient.get(
        '/api/warehouse/supplier',
        queryParameters: queryParams,
      );

      if (response.success && response.statusCode == 200) {
        final json = response.data;
        final newItems = List<Map<String, dynamic>>.from(json['data'] ?? []);
        suppliers.addAll(newItems);

        final kpi = json['kpi'] ?? {};
        totalSuppliers.value = kpi['total'] ?? 0;
        activeCount.value = kpi['active'] ?? 0;
        inactiveCount.value = kpi['inactive'] ?? 0;

        final pagination = json['pagination'] ?? {};
        totalRecords.value = pagination['total'] ?? 0;
        totalPages.value = pagination['pages'] ?? 1;
        hasMore.value = _mobilePage < (pagination['pages'] ?? 1);
      }
    } catch (e) {
      _mobilePage--; // revert so user can retry
    }
  }

  // ─── Search ───────────────────────────────────────────────────
  void searchSuppliers(String query) {
    _searchQuery = query;
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  void clearSearch() {
    _searchQuery = '';
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  // ─── Filter ───────────────────────────────────────────────────
  void filterSuppliers(String filter) {
    selectedFilter.value = filter;
    _statusFilter = filter == 'All' ? '' : filter.toLowerCase();
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  // ─── Pagination ───────────────────────────────────────────────
  void nextPage() {
    if (currentPage.value < totalPages.value && !isLoading.value) {
      fetchSuppliers(page: currentPage.value + 1);
    }
  }

  void previousPage() {
    if (currentPage.value > 1 && !isLoading.value) {
      fetchSuppliers(page: currentPage.value - 1);
    }
  }

  // ─── Refresh ─────────────────────────────────────────────────
  Future<void> refreshAll() async {
    await fetchSuppliersForMobile();
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Future<bool> createSupplier(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final response = await apiClient.post(
        '/api/warehouse/supplier',
        body: data,
      );

      if (response.success && response.statusCode == 201) {
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateSupplier(String id, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final response = await apiClient.put(
        '/api/warehouse/supplier/$id',
        body: data,
      );

      if (response.success && response.statusCode == 200) {
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      final response = await apiClient.delete('/api/warehouse/supplier/$id');

      if (response.success && response.statusCode == 200) {
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── Utilities ────────────────────────────────────────────────
  String getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Unknown';
    }
  }
}