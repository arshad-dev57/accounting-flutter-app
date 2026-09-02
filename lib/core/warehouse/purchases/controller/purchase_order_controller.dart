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
    'Approved',
    'Partially Received',
    'Received',
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
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
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

      final response = await _api.get(
        '/api/purchase/orders?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

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
      } else {
        Get.snackbar(
          'Error',
          response.message,
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {

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

    filteredOrders.value = filtered;
  }

  void filterOrders(String filter) {
    selectedFilter.value = filter;
    statusFilter.value = filter;
    fetchOrders(resetPage: true);
  }

  void searchOrders(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchOrders(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreOrders() async {

    if (!hasMore.value || isLoadingMore.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

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

        orders.addAll(newOrders);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      } else {
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshOrders() {
    return fetchOrders(resetPage: true);
  }

  void applyFilters() {
    fetchOrders(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    _resetWizard();
    showCreateWizard.value = true;
  }

  void closeCreateWizard() {
    showCreateWizard.value = false;
    _resetWizard();
  }

  void _resetWizard() {
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
  }

  // ─── SUPPLIER SEARCH ─────────────────────────────────────────

  Future<void> searchSuppliers(String query) async {

    if (query.trim().length < 2) {
      supplierSearchResults.clear();
      return;
    }

    try {
      isSearchingSuppliers.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/warehouse/supplier?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        supplierSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        supplierSearchResults.clear();
      }
    } catch (e) {
      supplierSearchResults.clear();
    } finally {
      isSearchingSuppliers.value = false;
    }
  }

  void selectSupplier(Map<String, dynamic> supplier) {

    selectedSupplier.value = supplier;
    supplierSearchResults.clear();
    supplierSearchController.text = supplier['name'] ?? '';
  }

  // ─── PRODUCT SEARCH ──────────────────────────────────────────

  Future<void> searchProducts(String query) async {

    if (query.trim().length < 2) {
      productSearchResults.clear();
      return;
    }

    try {
      isSearchingProducts.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/warehouse/products?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        productSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        productSearchResults.clear();
      }
    } catch (e) {
      productSearchResults.clear();
    } finally {
      isSearchingProducts.value = false;
    }
  }

  void addProductToOrder(Map<String, dynamic> product) {

    // Check if product already exists in drafts
    final existingIndex = lineDrafts.indexWhere(
      (line) => line.productId == product['id'],
    );

    if (existingIndex != -1) {
      // Increment quantity if product already exists
      final existing = lineDrafts[existingIndex];
      existing.quantity += 1;
      lineDrafts[existingIndex] = existing;
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
    }

    // Clear product search
    productSearchResults.clear();
    productSearchController.clear();
  }

  void removeProductFromOrder(int index) {
    lineDrafts.removeAt(index);
  }

  void updateProductQuantity(int index, int quantity) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (quantity > 0) {
        line.quantity = quantity;
        lineDrafts[index] = line;
      }
    }
  }

  void updateProductUnitPrice(int index, double unitPrice) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (unitPrice >= 0) {
        line.unitPrice = unitPrice;
        lineDrafts[index] = line;
      }
    }
  }

  void updateProductDiscount(int index, double discount) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (discount >= 0 && discount <= 100) {
        line.discount = discount;
        lineDrafts[index] = line;
      }
    }
  }

  void updateProductTaxRate(int index, double taxRate) {
    if (index < lineDrafts.length) {
      final line = lineDrafts[index];
      if (taxRate >= 0) {
        line.taxRate = taxRate;
        lineDrafts[index] = line;
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
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    return canGo;
  }

  void nextStep() {

    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select a supplier first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar('Validation', 'Add at least one item to the order');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
    }
  }

  void previousStep() {
    if (wizardStep.value > 0) {
      wizardStep.value--;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE ORDER
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createOrder() async {

    final supplier = selectedSupplier.value;
    if (supplier == null) {
      return false;
    }

    if (lineDrafts.isEmpty) {
      Get.snackbar('Validation', 'Add at least one item');
      return false;
    }

    final orderDate = selectedOrderDate.value;
    final expectedDeliveryDate = selectedExpectedDeliveryDate.value;

    if (orderDate == null) {
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
        'status': 'Approved',
      };


      final response = await _api.post(
        '/api/purchase/orders',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase order created successfully');
        closeCreateWizard();
        await fetchOrders(resetPage: true);
        return true;
      }

      Get.snackbar(
        'Error',
        response.message,
      );
      return false;
    } catch (e) {
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
    selectedOrder.value = order;
  }

  Future<bool> updateOrderStatus(
    String id,
    String status, {
    String? notes,
  }) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/purchase/orders/$id/status',
        body: {'status': status, 'notes': notes ?? ''},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Order status updated to $status');
        await fetchOrders();
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sendOrder(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/orders/$id/send',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase order sent to supplier');
        await fetchOrders();
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelOrder(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/orders/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase order cancelled');
        await fetchOrders();
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteOrder(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/orders/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase order deleted successfully');
        await fetchOrders(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<PurchaseOrderModel?> getOrderById(String id) async {

    try {
      final response = await _api.get(
        '/api/purchase/orders/$id',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final order = PurchaseOrderModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        return order;
      }
      return null;
    } catch (e) {
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
      case 'Partially Received':
        return Colors.teal;
      case 'Received':
        return Colors.indigo;
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
      case 'Partially Received':
        return 'Partially Received';
      case 'Received':
        return 'Received';
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
