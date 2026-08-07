// lib/core/warehouse/purchase_order/controller/purchase_order_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/purchases/model/purchase_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchaseOrderController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<PurchaseOrderModel> orders = <PurchaseOrderModel>[].obs;
  final RxList<PurchaseOrderModel> filteredOrders = <PurchaseOrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<PurchaseOrderModel?> selectedOrder = Rx<PurchaseOrderModel?>(null);

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
  final RxString selectedFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = [
    'all',
    'Draft',
    'Sent',
    'Approved',
    'Cancelled',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<PurchaseOrderStats> stats = PurchaseOrderStats(
    todayCount: 0,
    todayAmount: 0,
    monthCount: 0,
    monthAmount: 0,
  ).obs;

  final Rx<PurchaseOrderStatusCounts> statusCounts = PurchaseOrderStatusCounts(
    draft: 0,
    sent: 0,
    approved: 0,
    cancelled: 0,
    total: 0,
  ).obs;

  // ─── CREATE WIZARD STATE ─────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<Map<String, dynamic>> supplierSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingSuppliers = false.obs;
  final Rx<Map<String, dynamic>?> selectedSupplier = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<PurchaseOrderLineDraft> lineDrafts =
      <PurchaseOrderLineDraft>[].obs;
  final RxList<Map<String, dynamic>> productSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingProducts = false.obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final supplierSearchController = TextEditingController();
  final productSearchController = TextEditingController();
  final orderDateController = TextEditingController();
  final expectedDeliveryDateController = TextEditingController();
  final notesController = TextEditingController();
  final termsConditionsController = TextEditingController();

  // ─── SELECTED DATES ──────────────────────────────────────────
  final Rx<DateTime?> selectedOrderDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedExpectedDeliveryDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🟢 [PurchaseOrderController] onInit called');
    selectedOrderDate.value = DateTime.now();
    selectedExpectedDeliveryDate.value = DateTime.now().add(
      const Duration(days: 7),
    );
    orderDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedOrderDate.value!);
    expectedDeliveryDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedExpectedDeliveryDate.value!);
    fetchOrders();
  }

  @override
  void onClose() {
    print(
      '🟢 [PurchaseOrderController] onClose called - disposing controllers',
    );
    supplierSearchController.dispose();
    productSearchController.dispose();
    orderDateController.dispose();
    expectedDeliveryDateController.dispose();
    notesController.dispose();
    termsConditionsController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  double get selectedSubtotal {
    return lineDrafts.fold(0.0, (sum, line) => sum + line.subtotal);
  }

  double get selectedTotalDiscount {
    return lineDrafts.fold(0.0, (sum, line) => sum + line.discountAmount);
  }

  double get selectedTotalTax {
    return lineDrafts.fold(0.0, (sum, line) => sum + line.taxAmount);
  }

  double get selectedGrandTotal {
    return selectedSubtotal - selectedTotalDiscount + selectedTotalTax;
  }

  int get totalItems {
    return lineDrafts.fold(0, (sum, line) => sum + line.quantity);
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH ORDERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchOrders({bool resetPage = false}) async {
    print('🔵 [PurchaseOrderController] fetchOrders called');
    print(
      '🔵 [PurchaseOrderController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [PurchaseOrderController] Reset Page: $resetPage');

    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print(
          '🔵 [PurchaseOrderController] Search filter: ${searchFilter.value}',
        );
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print(
          '🔵 [PurchaseOrderController] Status filter: ${statusFilter.value}',
        );
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [PurchaseOrderController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [PurchaseOrderController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [PurchaseOrderController] API Request: GET /api/purchase/orders?$query',
      );

      final response = await _api.get(
        '/api/purchase/orders?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [PurchaseOrderController] Data length: ${list.length}');

        orders.value = list
            .map(
              (e) => PurchaseOrderModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          final statsData = response.data['stats'] as Map<String, dynamic>;
          stats.value = PurchaseOrderStats.fromJson(statsData);

          // Also update status counts
          if (statsData['status'] != null) {
            statusCounts.value = PurchaseOrderStatusCounts.fromJson(statsData);
          }
          print('🔵 [PurchaseOrderController] Stats: ${stats.value}');
          print(
            '🔵 [PurchaseOrderController] Status counts: ${statusCounts.value}',
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

          print(
            '✅ [PurchaseOrderController] Orders fetched successfully: ${orders.length} orders',
          );
          print(
            '✅ [PurchaseOrderController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [PurchaseOrderController] Failed to fetch orders');
        print('❌ [PurchaseOrderController] Response data: ${response.data}');
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to load purchase orders',
        );
      }
    } catch (e) {
      print('❌ [PurchaseOrderController] fetchOrders error: $e');
      print('❌ [PurchaseOrderController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [PurchaseOrderController] fetchOrders completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [PurchaseOrderController] applyLocalFilters called');
    print(
      '🟣 [PurchaseOrderController] Selected filter: ${selectedFilter.value}',
    );
    print('🟣 [PurchaseOrderController] Search filter: ${searchFilter.value}');

    final list = orders.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          item.status != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.orderNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.supplierEmail?.toLowerCase().contains(query) == true;
        if (!matches) return false;
      }
      return true;
    }).toList();

    print(
      '🟣 [PurchaseOrderController] Filtered orders: ${filtered.length} out of ${list.length}',
    );
    filteredOrders.value = filtered;
  }

  void filterOrders(String filter) {
    print('🟣 [PurchaseOrderController] filterOrders called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchOrders(String query) {
    print('🟣 [PurchaseOrderController] searchOrders called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [PurchaseOrderController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchOrders(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreOrders() async {
    print('🟡 [PurchaseOrderController] fetchMoreOrders called');
    print(
      '🟡 [PurchaseOrderController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [PurchaseOrderController] Skipping load more');
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [PurchaseOrderController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🟡 [PurchaseOrderController] API Request: GET /api/purchase/orders?$query',
      );

      final response = await _api.get(
        '/api/purchase/orders?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newOrders = list
            .map(
              (e) => PurchaseOrderModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        print(
          '🟡 [PurchaseOrderController] Loaded ${newOrders.length} more orders',
        );
        orders.addAll(newOrders);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print(
          '🟡 [PurchaseOrderController] Total orders now: ${orders.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [PurchaseOrderController] Failed to load more orders');
      }
    } catch (e) {
      print('❌ [PurchaseOrderController] fetchMoreOrders error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [PurchaseOrderController] fetchMoreOrders completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshOrders() {
    print('🟢 [PurchaseOrderController] refreshOrders called');
    return fetchOrders(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [PurchaseOrderController] applyFilters called');
    fetchOrders(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [PurchaseOrderController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    print(
      '🟢 [PurchaseOrderController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void closeCreateWizard() {
    print('🟢 [PurchaseOrderController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print(
      '🟢 [PurchaseOrderController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void _resetWizard() {
    print('🟢 [PurchaseOrderController] _resetWizard called');
    wizardStep.value = 0;
    selectedSupplier.value = null;
    supplierSearchResults.clear();
    lineDrafts.clear();
    productSearchResults.clear();
    supplierSearchController.clear();
    productSearchController.clear();
    notesController.clear();
    termsConditionsController.clear();
    selectedOrderDate.value = DateTime.now();
    selectedExpectedDeliveryDate.value = DateTime.now().add(
      const Duration(days: 7),
    );
    orderDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedOrderDate.value!);
    expectedDeliveryDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedExpectedDeliveryDate.value!);
    print('✅ [PurchaseOrderController] Wizard reset complete');
  }

  // ─── SUPPLIER SEARCH ─────────────────────────────────────────

  Future<void> searchSuppliers(String query) async {
    print('🔵 [PurchaseOrderController] searchSuppliers called with: "$query"');

    if (query.trim().length < 2) {
      print('🔵 [PurchaseOrderController] Query too short, clearing results');
      supplierSearchResults.clear();
      return;
    }

    try {
      isSearchingSuppliers.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print(
        '🔵 [PurchaseOrderController] API Request: GET /api/warehouse/supplier?search=$encoded&limit=10',
      );

      final response = await _api.get(
        '/api/warehouse/supplier?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        supplierSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '🔵 [PurchaseOrderController] Found ${supplierSearchResults.length} suppliers for query: $query',
        );
      } else {
        print('❌ [PurchaseOrderController] No suppliers found');
        supplierSearchResults.clear();
      }
    } catch (e) {
      print('❌ [PurchaseOrderController] searchSuppliers error: $e');
      supplierSearchResults.clear();
    } finally {
      isSearchingSuppliers.value = false;
      print('🔵 [PurchaseOrderController] searchSuppliers completed');
    }
  }

  void selectSupplier(Map<String, dynamic> supplier) {
    print('🔵 [PurchaseOrderController] selectSupplier called');
    print(
      '🔵 [PurchaseOrderController] Selected supplier: ${supplier['name']}',
    );

    selectedSupplier.value = supplier;
    supplierSearchResults.clear();
    supplierSearchController.text = supplier['name'] ?? '';
  }

  // ─── PRODUCT SEARCH ──────────────────────────────────────────

  Future<void> searchProducts(String query) async {
    print('🔵 [PurchaseOrderController] searchProducts called with: "$query"');

    if (query.trim().length < 2) {
      print('🔵 [PurchaseOrderController] Query too short, clearing results');
      productSearchResults.clear();
      return;
    }

    try {
      isSearchingProducts.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print(
        '🔵 [PurchaseOrderController] API Request: GET /api/warehouse/products?search=$encoded&limit=10',
      );

      final response = await _api.get(
        '/api/warehouse/products?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        productSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '🔵 [PurchaseOrderController] Found ${productSearchResults.length} products for query: $query',
        );
      } else {
        print('❌ [PurchaseOrderController] No products found');
        productSearchResults.clear();
      }
    } catch (e) {
      print('❌ [PurchaseOrderController] searchProducts error: $e');
      productSearchResults.clear();
    } finally {
      isSearchingProducts.value = false;
      print('🔵 [PurchaseOrderController] searchProducts completed');
    }
  }

  void addProductToOrder(Map<String, dynamic> product) {
    print('🔵 [PurchaseOrderController] addProductToOrder called');

    // Check if product already exists in drafts
    final existingIndex = lineDrafts.indexWhere(
      (line) => line.productId == product['id'],
    );

    if (existingIndex != -1) {
      // Increment quantity if product already exists
      final existing = lineDrafts[existingIndex];
      existing.quantity += 1;
      lineDrafts[existingIndex] = existing;
      print(
        '🔵 [PurchaseOrderController] Incremented quantity for existing product: ${product['name']}',
      );
    } else {
      // Add new product
      final newLine = PurchaseOrderLineDraft(
        productId: product['id'] ?? '',
        productName: product['name'] ?? '',
        sku: product['sku'] ?? '',
        quantity: 1,
        unitPrice: product['costPrice']?.toDouble() ?? 0,
        discount: 0,
        taxRate: product['taxRate']?.toDouble() ?? 0,
      );
      lineDrafts.add(newLine);
      print(
        '🔵 [PurchaseOrderController] Added new product: ${product['name']}',
      );
    }

    // Clear product search
    productSearchResults.clear();
    productSearchController.clear();
  }

  void removeProductFromOrder(int index) {
    print(
      '🔵 [PurchaseOrderController] removeProductFromOrder called for index: $index',
    );
    lineDrafts.removeAt(index);
  }

  void updateProductQuantity(int index, int quantity) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (quantity > 0) {
        line.quantity = quantity;
        lineDrafts[index] = line;
        print(
          '🔵 [PurchaseOrderController] Updated quantity for product ${line.productName} to $quantity',
        );
      }
    }
  }

  void updateProductUnitPrice(int index, double unitPrice) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (unitPrice >= 0) {
        line.unitPrice = unitPrice;
        lineDrafts[index] = line;
        print(
          '🔵 [PurchaseOrderController] Updated unit price for product ${line.productName} to $unitPrice',
        );
      }
    }
  }

  void updateProductDiscount(int index, double discount) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (discount >= 0 && discount <= 100) {
        line.discount = discount;
        lineDrafts[index] = line;
        print(
          '🔵 [PurchaseOrderController] Updated discount for product ${line.productName} to $discount%',
        );
      }
    }
  }

  void updateProductTaxRate(int index, double taxRate) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (taxRate >= 0) {
        line.taxRate = taxRate;
        lineDrafts[index] = line;
        print(
          '🔵 [PurchaseOrderController] Updated tax rate for product ${line.productName} to $taxRate%',
        );
      }
    }
  }

  // ─── DATE SELECTION ──────────────────────────────────────────

  void selectOrderDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedOrderDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedOrderDate.value = date;
      orderDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  void selectExpectedDeliveryDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedExpectedDeliveryDate.value ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedExpectedDeliveryDate.value = date;
      expectedDeliveryDateController.text = DateFormat(
        'dd MMM yyyy',
      ).format(date);
    }
  }

  // ─── WIZARD NAVIGATION ──────────────────────────────────────

  bool canGoToStep2() {
    final canGo = selectedSupplier.value != null;
    print('🔵 [PurchaseOrderController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    print('🔵 [PurchaseOrderController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print(
      '🟡 [PurchaseOrderController] nextStep called, current step: ${wizardStep.value}',
    );

    if (wizardStep.value == 0 && !canGoToStep2()) {
      print(
        '❌ [PurchaseOrderController] Cannot go to step 2 - no supplier selected',
      );
      Get.snackbar('Validation', 'Select a supplier first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print('❌ [PurchaseOrderController] Cannot go to step 3 - no items added');
      Get.snackbar('Validation', 'Add at least one item to the order');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print(
        '🟡 [PurchaseOrderController] Step changed to: ${wizardStep.value}',
      );
    }
  }

  void previousStep() {
    print(
      '🟡 [PurchaseOrderController] previousStep called, current step: ${wizardStep.value}',
    );
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print(
        '🟡 [PurchaseOrderController] Step changed to: ${wizardStep.value}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE ORDER
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createOrder() async {
    print('🔵 [PurchaseOrderController] createOrder called');

    final supplier = selectedSupplier.value;
    if (supplier == null) {
      print('❌ [PurchaseOrderController] No supplier selected');
      return false;
    }

    if (lineDrafts.isEmpty) {
      print('❌ [PurchaseOrderController] No items in order');
      Get.snackbar('Validation', 'Add at least one item');
      return false;
    }

    final orderDate = selectedOrderDate.value;
    final expectedDeliveryDate = selectedExpectedDeliveryDate.value;

    if (orderDate == null) {
      print('❌ [PurchaseOrderController] Order date not selected');
      Get.snackbar('Validation', 'Please select order date');
      return false;
    }

    try {
      isSubmitting.value = true;

      final items = lineDrafts
          .map(
            (line) => ({
              'productId': line.productId,
              'productName': line.productName,
              'sku': line.sku,
              'quantity': line.quantity,
              'unitPrice': line.unitPrice,
              'discount': line.discount,
              'taxRate': line.taxRate,
              'notes': null,
            }),
          )
          .toList();

      final payload = {
        'supplierId': supplier['id'],
        'supplierName': supplier['name'],
        'supplierEmail': supplier['email'] ?? '',
        'supplierPhone': supplier['phone'] ?? '',
        'supplierAddress': supplier['address'] ?? '',
        'orderDate': orderDate.toIso8601String().split('T').first,
        'expectedDeliveryDate': expectedDeliveryDate
            ?.toIso8601String()
            .split('T')
            .first,
        'items': items,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'termsConditions': termsConditionsController.text.trim().isEmpty
            ? null
            : termsConditionsController.text.trim(),
        'status': 'Draft',
      };

      print('🔵 [PurchaseOrderController] Submitting purchase order payload');
      print(
        '🔵 [PurchaseOrderController] Supplier: ${supplier['name']}, Items: ${items.length}',
      );

      final response = await _api.post(
        '/api/purchase/orders',
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success) {
        print(
          '✅ [PurchaseOrderController] Purchase order created successfully!',
        );
        Get.snackbar('Success', 'Purchase order created successfully');
        closeCreateWizard();
        await fetchOrders(resetPage: true);
        return true;
      }

      print(
        '❌ [PurchaseOrderController] Failed to create purchase order: ${response.message}',
      );
      Get.snackbar(
        'Error',
        response.message ?? 'Failed to create purchase order',
      );
      return false;
    } catch (e) {
      print('❌ [PurchaseOrderController] createOrder error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ORDER ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectOrder(PurchaseOrderModel order) {
    print(
      '🔵 [PurchaseOrderController] selectOrder called for: ${order.orderNumber}',
    );
    selectedOrder.value = order;
  }

  Future<bool> updateOrderStatus(
    String id,
    String status, {
    String? notes,
  }) async {
    print('🟣 [PurchaseOrderController] updateOrderStatus called');
    print('🟣 [PurchaseOrderController] ID: $id, New Status: $status');

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/purchase/orders/$id/status',
        body: {'status': status, 'notes': notes ?? ''},
        requiresAuth: true,
      );

      print(
        '🟣 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseOrderController] Order status updated to $status');
        Get.snackbar('Success', 'Order status updated to $status');
        await fetchOrders();
        return true;
      }

      print(
        '❌ [PurchaseOrderController] Failed to update status: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to update status');
      return false;
    } catch (e) {
      print('❌ [PurchaseOrderController] updateOrderStatus error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sendOrder(String id) async {
    print('🟣 [PurchaseOrderController] sendOrder called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/orders/$id/send',
        body: {},
        requiresAuth: true,
      );

      print(
        '🟣 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseOrderController] Order sent successfully');
        Get.snackbar('Success', 'Purchase order sent to supplier');
        await fetchOrders();
        return true;
      }

      print(
        '❌ [PurchaseOrderController] Failed to send order: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to send order');
      return false;
    } catch (e) {
      print('❌ [PurchaseOrderController] sendOrder error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelOrder(String id, {String? reason}) async {
    print('🟣 [PurchaseOrderController] cancelOrder called for ID: $id');
    print('🟣 [PurchaseOrderController] Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/orders/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseOrderController] Order cancelled successfully');
        Get.snackbar('Success', 'Purchase order cancelled');
        await fetchOrders();
        return true;
      }

      print(
        '❌ [PurchaseOrderController] Failed to cancel order: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to cancel order');
      return false;
    } catch (e) {
      print('❌ [PurchaseOrderController] cancelOrder error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    print('🔵 [PurchaseOrderController] deleteOrder called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/orders/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseOrderController] Order deleted successfully');
        Get.snackbar('Success', 'Purchase order deleted successfully');
        await fetchOrders(resetPage: true);
        return true;
      }

      print(
        '❌ [PurchaseOrderController] Failed to delete order: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete order');
      return false;
    } catch (e) {
      print('❌ [PurchaseOrderController] deleteOrder error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<PurchaseOrderModel?> getOrderById(String id) async {
    print('🔵 [PurchaseOrderController] getOrderById called for ID: $id');

    try {
      final response = await _api.get(
        '/api/purchase/orders/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseOrderController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseOrderController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final order = PurchaseOrderModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print('✅ [PurchaseOrderController] Order found: ${order.orderNumber}');
        return order;
      }
      print('❌ [PurchaseOrderController] Order not found');
      return null;
    } catch (e) {
      print('❌ [PurchaseOrderController] getOrderById error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: GET STATUS COLOR
  // ═══════════════════════════════════════════════════════════════

  Color getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Sent':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'Draft':
        return 'Draft';
      case 'Sent':
        return 'Sent';
      case 'Approved':
        return 'Approved';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: FORMAT CURRENCY
  // ═══════════════════════════════════════════════════════════════

  String formatCurrency(double amount) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(amount);
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderLineDraft {
  String productId;
  String productName;
  String sku;
  int quantity;
  double unitPrice;
  double discount;
  double taxRate;

  PurchaseOrderLineDraft({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.taxRate,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get lineTotal => taxableAmount + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'taxRate': taxRate,
      'lineTotal': lineTotal,
    };
  }
}
