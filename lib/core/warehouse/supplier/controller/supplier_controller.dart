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
    print('🟢 [SupplierController] onInit called');
    // Load suppliers when controller initializes
    fetchSuppliersForMobile();
  }

  @override
  void onReady() {
    super.onReady();
    print('🟢 [SupplierController] onReady called');
    // Any additional setup after view is rendered
  }

  @override
  void onClose() {
    print('🟢 [SupplierController] onClose called');
    super.onClose();
  }

  // ─── Fetch (web pagination) ───────────────────────────────────
  Future<void> fetchSuppliers({int page = 1}) async {
    print('🔵 [SupplierController] fetchSuppliers called - Page: $page');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': pageSize.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      };

      print('🔵 [SupplierController] API Request: GET /api/warehouse/supplier with params: $queryParams');

      final response = await apiClient.get(
        '/api/warehouse/supplier',
        queryParameters: queryParams,
      );

      print('🔵 [SupplierController] Response Status: ${response.statusCode}');
      print('🔵 [SupplierController] Response Success: ${response.success}');

      if (response.success && response.statusCode == 200) {
        final json = response.data;
        suppliers.value = List<Map<String, dynamic>>.from(json['data'] ?? []);
        print('✅ [SupplierController] Loaded ${suppliers.length} suppliers');

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
        
        print('✅ [SupplierController] Total Records: ${totalRecords.value}, Total Pages: ${totalPages.value}');
      } else {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load suppliers';
        print('❌ [SupplierController] Error: ${errorMessage.value}');
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('❌ [SupplierController] Exception: $e');
    } finally {
      isLoading.value = false;
      print('🔵 [SupplierController] fetchSuppliers completed');
    }
  }

  // ─── Mobile: fetch first page fresh ──────────────────────────
  Future<void> fetchSuppliersForMobile() async {
    print('🟢 [SupplierController] fetchSuppliersForMobile called');
    _mobilePage = 1;
    hasMore.value = true;
    isLoading.value = true;
    suppliers.clear();

    await _fetchMobilePage();
    isLoading.value = false;
    print('✅ [SupplierController] fetchSuppliersForMobile completed');
  }

  // ─── Mobile: load more (infinite scroll) ─────────────────────
  Future<void> fetchMoreSuppliers() async {
    if (isLoadingMore.value || !hasMore.value) {
      print('🟡 [SupplierController] fetchMoreSuppliers skipped - loading: ${isLoadingMore.value}, hasMore: ${hasMore.value}');
      return;
    }
    print('🟡 [SupplierController] fetchMoreSuppliers called - Loading page ${_mobilePage + 1}');
    isLoadingMore.value = true;
    _mobilePage++;
    await _fetchMobilePage();
    isLoadingMore.value = false;
    print('✅ [SupplierController] fetchMoreSuppliers completed');
  }

  Future<void> _fetchMobilePage() async {
    try {
      final queryParams = {
        'page': _mobilePage.toString(),
        'limit': pageSize.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      };

      print('🔵 [SupplierController] _fetchMobilePage - Page: $_mobilePage');

      final response = await apiClient.get(
        '/api/warehouse/supplier',
        queryParameters: queryParams,
      );

      if (response.success && response.statusCode == 200) {
        final json = response.data;
        final newItems = List<Map<String, dynamic>>.from(json['data'] ?? []);
        suppliers.addAll(newItems);
        print('🔵 [SupplierController] Added ${newItems.length} suppliers, total: ${suppliers.length}');

        final kpi = json['kpi'] ?? {};
        totalSuppliers.value = kpi['total'] ?? 0;
        activeCount.value = kpi['active'] ?? 0;
        inactiveCount.value = kpi['inactive'] ?? 0;

        final pagination = json['pagination'] ?? {};
        totalRecords.value = pagination['total'] ?? 0;
        totalPages.value = pagination['pages'] ?? 1;
        hasMore.value = _mobilePage < (pagination['pages'] ?? 1);
        
        print('✅ [SupplierController] _fetchMobilePage - hasMore: ${hasMore.value}');
      }
    } catch (e) {
      _mobilePage--; // revert so user can retry
      print('❌ [SupplierController] _fetchMobilePage error: $e');
    }
  }

  // ─── Search ───────────────────────────────────────────────────
  void searchSuppliers(String query) {
    print('🔵 [SupplierController] searchSuppliers called with: "$query"');
    _searchQuery = query;
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  void clearSearch() {
    print('🔵 [SupplierController] clearSearch called');
    _searchQuery = '';
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  // ─── Filter ───────────────────────────────────────────────────
  void filterSuppliers(String filter) {
    print('🔵 [SupplierController] filterSuppliers called with: $filter');
    selectedFilter.value = filter;
    _statusFilter = filter == 'All' ? '' : filter.toLowerCase();
    currentPage.value = 1;
    fetchSuppliers(page: 1);
  }

  // ─── Pagination ───────────────────────────────────────────────
  void nextPage() {
    if (currentPage.value < totalPages.value && !isLoading.value) {
      print('🔵 [SupplierController] nextPage called - Going to page ${currentPage.value + 1}');
      fetchSuppliers(page: currentPage.value + 1);
    }
  }

  void previousPage() {
    if (currentPage.value > 1 && !isLoading.value) {
      print('🔵 [SupplierController] previousPage called - Going to page ${currentPage.value - 1}');
      fetchSuppliers(page: currentPage.value - 1);
    }
  }

  // ─── Refresh ─────────────────────────────────────────────────
  Future<void> refreshAll() async {
    print('🟢 [SupplierController] refreshAll called');
    await fetchSuppliersForMobile();
    print('✅ [SupplierController] refreshAll completed');
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Future<bool> createSupplier(Map<String, dynamic> data) async {
    print('🔵 [SupplierController] createSupplier called');
    isSubmitting.value = true;
    try {
      final response = await apiClient.post(
        '/api/warehouse/supplier',
        body: data,
      );

      print('🔵 [SupplierController] Create Response: ${response.statusCode}');

      if (response.success && response.statusCode == 201) {
        print('✅ [SupplierController] Supplier created successfully');
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      print('❌ [SupplierController] Failed to create supplier');
      return false;
    } catch (e) {
      print('❌ [SupplierController] createSupplier error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateSupplier(String id, Map<String, dynamic> data) async {
    print('🔵 [SupplierController] updateSupplier called for ID: $id');
    isSubmitting.value = true;
    try {
      final response = await apiClient.put(
        '/api/warehouse/supplier/$id',
        body: data,
      );

      print('🔵 [SupplierController] Update Response: ${response.statusCode}');

      if (response.success && response.statusCode == 200) {
        print('✅ [SupplierController] Supplier updated successfully');
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      print('❌ [SupplierController] Failed to update supplier');
      return false;
    } catch (e) {
      print('❌ [SupplierController] updateSupplier error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    print('🔵 [SupplierController] deleteSupplier called for ID: $id');
    try {
      final response = await apiClient.delete('/api/warehouse/supplier/$id');

      print('🔵 [SupplierController] Delete Response: ${response.statusCode}');

      if (response.success && response.statusCode == 200) {
        print('✅ [SupplierController] Supplier deleted successfully');
        await fetchSuppliers(page: currentPage.value);
        return true;
      }
      print('❌ [SupplierController] Failed to delete supplier');
      return false;
    } catch (e) {
      print('❌ [SupplierController] deleteSupplier error: $e');
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

  // ─── Get Supplier by ID ───────────────────────────────────────
  Map<String, dynamic>? getSupplierById(String id) {
    try {
      return suppliers.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ─── Search Supplier by Name ──────────────────────────────────
  List<Map<String, dynamic>> searchSuppliersByName(String query) {
    if (query.isEmpty) return suppliers;
    final lowerQuery = query.toLowerCase();
    return suppliers.where((s) {
      final name = (s['name'] ?? '').toLowerCase();
      final company = (s['companyName'] ?? '').toLowerCase();
      final email = (s['email'] ?? '').toLowerCase();
      final phone = (s['phone'] ?? '').toLowerCase();
      final contact = (s['contactPerson'] ?? '').toLowerCase();
      return name.contains(lowerQuery) ||
             company.contains(lowerQuery) ||
             email.contains(lowerQuery) ||
             phone.contains(lowerQuery) ||
             contact.contains(lowerQuery);
    }).toList();
  }

  // ─── Get Active Suppliers ─────────────────────────────────────
  List<Map<String, dynamic>> get activeSuppliers {
    return suppliers.where((s) => s['status'] == 'active').toList();
  }

  // ─── Get Inactive Suppliers ───────────────────────────────────
  List<Map<String, dynamic>> get inactiveSuppliers {
    return suppliers.where((s) => s['status'] != 'active').toList();
  }
}