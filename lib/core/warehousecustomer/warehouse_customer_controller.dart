// lib/core/warehouse/customer/controller/customer_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WarehouseCustomerController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<CustomerModel?> selectedCustomer = Rx<CustomerModel?>(null);

  // ─── PAGINATION ──────────────────────────────────────────────
  final RxInt currentPage = 1.obs;
  final RxInt pageLimit = 10.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNext = false.obs;
  final RxBool hasPrev = false.obs;
  final RxBool hasMore = false.obs;
  final RxBool isLoadingMore = false.obs;

  // ─── FILTERS ──────────────────────────────────────────────────
  final RxString searchFilter = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedType = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> statusFilters = ['all', 'Active', 'Inactive', 'Blocked'];
  final List<String> typeFilters = [
    'all',
    'Individual',
    'Business',
    'Wholesale',
    'Retail',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<CustomerStats?> stats = Rx<CustomerStats?>(null);

  // ─── CREATE FORM STATE ──────────────────────────────────────
  final RxString customerType = 'Individual'.obs;
  final RxString status = 'Active'.obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final companyController = TextEditingController();
  final taxIdController = TextEditingController();
  final notesController = TextEditingController();
  final loyaltyPointsController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    print('🟢 [CustomerController] onInit called');
    fetchCustomers();
    fetchStats();
  }

  @override
  void onClose() {
    print('🟢 [CustomerController] onClose called');
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    companyController.dispose();
    taxIdController.dispose();
    notesController.dispose();
    loyaltyPointsController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────
  int get activeCount => customers.where((c) => c.isActiveCustomer).length;
  int get inactiveCount => customers.where((c) => c.isInactive).length;
  int get totalSpent =>
      customers.fold(0, (sum, c) => sum + c.totalSpent.toInt());

  // ═══════════════════════════════════════════════════════════════
  // FETCH CUSTOMERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchCustomers({bool resetPage = false}) async {
    print('🔵 [CustomerController] fetchCustomers called');
    if (resetPage) currentPage.value = 1;

    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
      }
      if (selectedStatus.value != 'all') {
        params['status'] = selectedStatus.value;
      }
      if (selectedType.value != 'all') {
        params['type'] = selectedType.value;
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [CustomerController] API Request: GET /api/warehouse/customers?$query',
      );

      final response = await _api.get(
        '/api/warehouse/customers?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        customers.value = list
            .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        applyLocalFilters();

        // Update stats from response
        if (response.data['stats'] != null) {
          final statsData = response.data['stats'] as Map<String, dynamic>;
          stats.value = CustomerStats(
            totalCustomers: (statsData['totalCustomers'] as num?)?.toInt() ?? 0,
            activeCount: (statsData['activeCount'] as num?)?.toInt() ?? 0,
            inactiveCount: (statsData['inactiveCount'] as num?)?.toInt() ?? 0,
            newThisMonth: (statsData['newThisMonth'] as num?)?.toInt() ?? 0,
            totalRevenue: (statsData['totalRevenue'] as num?)?.toDouble() ?? 0,
            averageOrderValue:
                (statsData['averageOrderValue'] as num?)?.toDouble() ?? 0,
            typeDistribution: statsData['typeDistribution'] is Map
                ? Map<String, int>.from(statsData['typeDistribution'])
                : {},
            topCustomers: [],
          );
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
          pageLimit.value = (pagination['limit'] as num?)?.toInt() ?? 10;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
          hasNext.value = pagination['hasNext'] == true;
          hasPrev.value = pagination['hasPrev'] == true;
          hasMore.value = pagination['hasNext'] == true;
        }

        print('✅ [CustomerController] Fetched ${customers.length} customers');
      } else {
        print('❌ [CustomerController] Failed to fetch customers');
        Get.snackbar('Error', response.message ?? 'Failed to load customers');
      }
    } catch (e) {
      print('❌ [CustomerController] fetchCustomers error: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    final list = customers.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedStatus.value != 'all' &&
          item.status != selectedStatus.value) {
        return false;
      }
      // Type filter
      if (selectedType.value != 'all' &&
          item.customerType != selectedType.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.name.toLowerCase().contains(query) ||
            item.customerNumber.toLowerCase().contains(query) ||
            (item.email?.toLowerCase().contains(query) ?? false) ||
            (item.phone?.toLowerCase().contains(query) ?? false) ||
            (item.company?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredCustomers.value = filtered;
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    applyLocalFilters();
  }

  void filterByType(String type) {
    selectedType.value = type;
    applyLocalFilters();
  }

  void searchCustomers(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchCustomers(resetPage: true);
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshCustomers() {
    return fetchCustomers(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreCustomers() async {
    if (!hasMore.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final response = await _api.get(
        '/api/warehouse/customers?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newCustomers = list
            .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        customers.addAll(newCustomers);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      }
    } catch (e) {
      print('❌ [CustomerController] fetchMoreCustomers error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH STATS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchStats() async {
    try {
      final response = await _api.get(
        '/api/warehouse/customers/stats',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        stats.value = CustomerStats(
          totalCustomers: (data['totalCustomers'] as num?)?.toInt() ?? 0,
          activeCount: (data['activeCount'] as num?)?.toInt() ?? 0,
          inactiveCount: (data['inactiveCount'] as num?)?.toInt() ?? 0,
          newThisMonth: (data['newThisMonth'] as num?)?.toInt() ?? 0,
          totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0,
          averageOrderValue:
              (data['averageOrderValue'] as num?)?.toDouble() ?? 0,
          typeDistribution: data['typeDistribution'] is Map
              ? Map<String, int>.from(data['typeDistribution'])
              : {},
          topCustomers: [],
        );
      }
    } catch (e) {
      print('❌ [CustomerController] fetchStats error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE FORM
  // ═══════════════════════════════════════════════════════════════

  void openCreateForm() {
    _resetCreateForm();
    showCreateForm.value = true;
  }

  void closeCreateForm() {
    showCreateForm.value = false;
    _resetCreateForm();
  }

  void _resetCreateForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    companyController.clear();
    taxIdController.clear();
    notesController.clear();
    loyaltyPointsController.clear();
    customerType.value = 'Individual';
    status.value = 'Active';
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createCustomer() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Validation', 'Customer name is required');
      return false;
    }

    try {
      isSubmitting.value = true;

      final payload = {
        'name': name,
        'email': emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'company': companyController.text.trim().isEmpty
            ? null
            : companyController.text.trim(),
        'customerType': customerType.value,
        'taxId': taxIdController.text.trim().isEmpty
            ? null
            : taxIdController.text.trim(),
        'status': status.value,
        'loyaltyPoints': int.tryParse(loyaltyPointsController.text) ?? 0,
        'notes': notesController.text.trim(),
        'tags': [],
        'address': {},
        'shippingAddress': {},
        'billingAddress': {},
        'preferences': {},
      };

      print('🔵 [CustomerController] Creating customer...');
      final response = await _api.post(
        '/api/warehouse/customers',
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('✅ [CustomerController] Customer created successfully');
        Get.snackbar('Success', 'Customer created successfully');
        closeCreateForm();
        await fetchCustomers(resetPage: true);
        await fetchStats();
        return true;
      }

      print('❌ [CustomerController] Failed to create customer');
      Get.snackbar('Error', response.message ?? 'Failed to create customer');
      return false;
    } catch (e) {
      print('❌ [CustomerController] createCustomer error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateCustomer(String id) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Validation', 'Customer name is required');
      return false;
    }

    try {
      isSubmitting.value = true;

      final payload = {
        'name': name,
        'email': emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'company': companyController.text.trim().isEmpty
            ? null
            : companyController.text.trim(),
        'customerType': customerType.value,
        'taxId': taxIdController.text.trim().isEmpty
            ? null
            : taxIdController.text.trim(),
        'status': status.value,
        'loyaltyPoints': int.tryParse(loyaltyPointsController.text) ?? 0,
        'notes': notesController.text.trim(),
        'tags': [],
        'address': {},
        'shippingAddress': {},
        'billingAddress': {},
        'preferences': {},
      };

      print('🔵 [CustomerController] Updating customer...');
      final response = await _api.put(
        '/api/warehouse/customers/$id',
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('✅ [CustomerController] Customer updated successfully');
        Get.snackbar('Success', 'Customer updated successfully');
        closeCreateForm();
        await fetchCustomers(resetPage: true);
        await fetchStats();
        return true;
      }

      print('❌ [CustomerController] Failed to update customer');
      Get.snackbar('Error', response.message ?? 'Failed to update customer');
      return false;
    } catch (e) {
      print('❌ [CustomerController] updateCustomer error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateCustomerStatus(String id, String status) async {
    try {
      isSubmitting.value = true;

      final response = await _api.patch(
        '/api/warehouse/customers/$id/status',
        body: {'status': status},
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Customer status updated');
        await fetchCustomers(resetPage: true);
        await fetchStats();
        return true;
      }

      Get.snackbar('Error', response.message ?? 'Failed to update status');
      return false;
    } catch (e) {
      print('❌ [CustomerController] updateCustomerStatus error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      isSubmitting.value = true;

      final response = await _api.delete(
        '/api/warehouse/customers/$id',
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Customer deleted successfully');
        await fetchCustomers(resetPage: true);
        await fetchStats();
        return true;
      }

      Get.snackbar('Error', response.message ?? 'Failed to delete customer');
      return false;
    } catch (e) {
      print('❌ [CustomerController] deleteCustomer error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── GET CUSTOMER BY ID ──────────────────────────────────────

  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final response = await _api.get(
        '/api/warehouse/customers/$id',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CustomerModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ [CustomerController] getCustomerById error: $e');
      return null;
    }
  }

  // ─── SEARCH CUSTOMERS (For dropdown/autocomplete) ──────────

  Future<List<CustomerModel>> searchCustomersApi(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final encoded = Uri.encodeComponent(query.trim());
      final response = await _api.get(
        '/api/warehouse/customers/search?q=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        return list
            .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ [CustomerController] searchCustomersApi error: $e');
      return [];
    }
  }

  // ─── GET CUSTOMER ORDERS ─────────────────────────────────────

  Future<List<CustomerOrderSummary>> getCustomerOrders(
    String customerId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/api/warehouse/customers/$customerId/orders?page=$page&limit=$limit',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        return list
            .map(
              (e) =>
                  CustomerOrderSummary.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ [CustomerController] getCustomerOrders error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: FORMAT CURRENCY
  // ═══════════════════════════════════════════════════════════════

  String formatCurrency(double amount) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return 'green';
      case 'Inactive':
        return 'grey';
      case 'Blocked':
        return 'red';
      default:
        return 'grey';
    }
  }
}
