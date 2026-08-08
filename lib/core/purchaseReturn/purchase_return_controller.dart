// lib/core/warehouse/purchase_return/controller/purchase_return_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/purchaseReturn/purchase_return_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchaseReturnController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<PurchaseReturnModel> returns = <PurchaseReturnModel>[].obs;
  final RxList<PurchaseReturnModel> filteredReturns =
      <PurchaseReturnModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<PurchaseReturnModel?> selectedReturn = Rx<PurchaseReturnModel?>(
    null,
  );

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
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = ['all', 'Processed', 'Cancelled'];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<PurchaseReturnStats> stats = PurchaseReturnStats(
    todayCount: 0,
    todayAmount: 0,
    monthCount: 0,
    monthAmount: 0,
    draftCount: 0,
  ).obs;

  // ─── CREATE FORM STATE ──────────────────────────────────────
  final Rx<Map<String, dynamic>?> selectedSupplier = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<Map<String, dynamic>> supplierSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingSuppliers = false.obs;
  final RxList<InvoiceForReturn> availableInvoices = <InvoiceForReturn>[].obs;
  final Rx<InvoiceForReturn?> selectedInvoice = Rx<InvoiceForReturn?>(null);
  final RxBool isLoadingInvoices = false.obs;
  final RxList<ReturnItemForForm> returnItems = <ReturnItemForForm>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxString returnReason = ''.obs;
  final RxString notes = ''.obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final supplierSearchController = TextEditingController();
  final notesController = TextEditingController();
  final returnDateController = TextEditingController();

  // ─── SELECTED VALUES ─────────────────────────────────────────
  final Rx<DateTime?> selectedReturnDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🟢 [PurchaseReturnController] onInit called');
    selectedReturnDate.value = DateTime.now();
    returnDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedReturnDate.value!);
    fetchReturns();
  }

  @override
  void onClose() {
    print('🟢 [PurchaseReturnController] onClose called');
    supplierSearchController.dispose();
    notesController.dispose();
    returnDateController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  double get totalReturnAmount {
    return returnItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  int get totalReturnQty {
    return returnItems.fold(0, (sum, item) => sum + item.returnQuantity);
  }

  bool get canCreateReturn {
    if (selectedSupplier.value == null) {
      return false;
    }
    if (selectedInvoice.value == null) {
      return false;
    }
    if (returnItems.isEmpty) {
      return false;
    }
    if (totalReturnAmount <= 0) {
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH RETURNS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchReturns({bool resetPage = false}) async {
    print('🔵 [PurchaseReturnController] fetchReturns called');
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
        '🔵 [PurchaseReturnController] API Request: GET /api/purchase/returns?$query',
      );

      final response = await _api.get(
        '/api/purchase/returns?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        returns.value = list
            .map(
              (e) => PurchaseReturnModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = PurchaseReturnStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
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

        print('✅ [PurchaseReturnController] Fetched ${returns.length} returns');
      } else {
        print('❌ [PurchaseReturnController] Failed to fetch returns');
        Get.snackbar('Error', response.message ?? 'Failed to load returns');
      }
    } catch (e) {
      print('❌ [PurchaseReturnController] fetchReturns error: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    final list = returns.toList();
    final filtered = list.where((item) {
      if (selectedFilter.value != 'all' &&
          item.status != selectedFilter.value) {
        return false;
      }
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.returnNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.purchaseInvoiceNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredReturns.value = filtered;
  }

  void filterReturns(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchReturns(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchReturns(resetPage: true);
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshReturns() {
    return fetchReturns(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreReturns() async {
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
        '/api/purchase/returns?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newReturns = list
            .map(
              (e) => PurchaseReturnModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        returns.addAll(newReturns);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      }
    } catch (e) {
      print('❌ [PurchaseReturnController] fetchMoreReturns error: $e');
    } finally {
      isLoadingMore.value = false;
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
    selectedSupplier.value = null;
    supplierSearchResults.clear();
    supplierSearchController.clear();
    availableInvoices.clear();
    selectedInvoice.value = null;
    returnItems.clear();
    returnReason.value = '';
    notesController.clear();
    selectedReturnDate.value = DateTime.now();
    returnDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedReturnDate.value!);
    isLoadingInvoices.value = false;
    isLoadingProducts.value = false;
  }

  // ─── SUPPLIER SEARCH ──────────────────────────────────────────

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
        print(
          '🔵 [PurchaseReturnController] Found ${supplierSearchResults.length} suppliers',
        );
      } else {
        supplierSearchResults.clear();
      }
    } catch (e) {
      print('❌ [PurchaseReturnController] searchSuppliers error: $e');
      supplierSearchResults.clear();
    } finally {
      isSearchingSuppliers.value = false;
    }
  }

  void selectSupplier(Map<String, dynamic> supplier) {
    selectedSupplier.value = supplier;
    supplierSearchResults.clear();
    supplierSearchController.text = supplier['name'] ?? '';
    fetchSupplierInvoices(supplier['id']);
  }

  // ─── SUPPLIER INVOICES ──────────────────────────────────────

  Future<void> fetchSupplierInvoices(String supplierId) async {
    try {
      isLoadingInvoices.value = true;
      availableInvoices.clear();
      selectedInvoice.value = null;

      final response = await _api.get(
        '/api/purchase/returns/supplier/$supplierId/invoices',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        availableInvoices.value = list
            .map((e) => InvoiceForReturn.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print(
          '🔵 [PurchaseReturnController] Found ${availableInvoices.length} invoices',
        );
      }
    } catch (e) {
      print('❌ [PurchaseReturnController] fetchSupplierInvoices error: $e');
    } finally {
      isLoadingInvoices.value = false;
    }
  }

  void selectInvoice(InvoiceForReturn invoice) {
    final status = invoice.invoiceStatus;
    if (status != 'Posted' &&
        status != 'Partially Paid' &&
        status != 'Paid') {
      Get.snackbar(
        'Invoice Not Posted',
        'Only posted invoices can be returned.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    selectedInvoice.value = invoice;
    fetchInvoiceProducts(invoice.id);
  }

  // ─── INVOICE PRODUCTS ──────────────────────────────────────

  Future<void> fetchInvoiceProducts(String invoiceId) async {
    try {
      isLoadingProducts.value = true;
      returnItems.clear();

      final response = await _api.get(
        '/api/purchase/returns/invoice/$invoiceId/products',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final products = data['products'] as List? ?? [];

        returnItems.value = products
            .map(
              (e) => ReturnItemForForm.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        print(
          '🔵 [PurchaseReturnController] Found ${returnItems.length} products for return',
        );
      }
    } catch (e) {
      print('❌ [PurchaseReturnController] fetchInvoiceProducts error: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  // ─── RETURN ITEM MANAGEMENT ──────────────────────────────────

  void updateReturnQuantity(int index, int quantity) {
    if (index >= returnItems.length) return;
    final item = returnItems[index];
    if (quantity > item.availableQuantity) {
      quantity = item.availableQuantity;
    }
    if (quantity < 0) {
      quantity = 0;
    }
    item.returnQuantity = quantity;
    item.lineTotal = quantity * item.unitPrice;
    returnItems.refresh();
  }

  void updateBoxes(int index, int boxes) {
    if (index >= returnItems.length) return;
    final item = returnItems[index];
    if (boxes < 0) boxes = 0;
    item.boxes = boxes;
    if (item.quantityPerBox != null && item.quantityPerBox! > 0) {
      final qty = boxes * item.quantityPerBox!;
      if (qty > item.availableQuantity) {
        item.boxes = (item.availableQuantity / item.quantityPerBox!).floor();
        final maxQty = item.boxes! * item.quantityPerBox!;
        item.returnQuantity = maxQty;
      } else {
        item.returnQuantity = qty;
      }
      item.lineTotal = item.returnQuantity * item.unitPrice;
    }
    returnItems.refresh();
  }

  void updateQtyPerBox(int index, int qtyPerBox) {
    if (index >= returnItems.length) return;
    final item = returnItems[index];
    if (qtyPerBox < 0) qtyPerBox = 0;
    item.quantityPerBox = qtyPerBox;
    if (item.boxes != null && item.boxes! > 0 && qtyPerBox > 0) {
      final qty = item.boxes! * qtyPerBox;
      if (qty > item.availableQuantity) {
        item.boxes = (item.availableQuantity / qtyPerBox).floor();
        final maxQty = item.boxes! * qtyPerBox;
        item.returnQuantity = maxQty;
      } else {
        item.returnQuantity = qty;
      }
      item.lineTotal = item.returnQuantity * item.unitPrice;
    }
    returnItems.refresh();
  }

  void toggleItemSelection(int index) {
    if (index >= returnItems.length) return;
    final item = returnItems[index];
    item.isSelected = !item.isSelected;
    if (item.isSelected) {
      item.returnQuantity = item.availableQuantity > 0
          ? item.availableQuantity
          : 0;
      if (item.isBoxBased && item.boxQuantity > 0) {
        item.boxes = (item.returnQuantity / item.boxQuantity).floor();
        item.quantityPerBox = item.boxQuantity;
        item.returnQuantity = item.boxes! * item.boxQuantity;
      }
      item.lineTotal = item.returnQuantity * item.unitPrice;
    } else {
      item.returnQuantity = 0;
      item.boxes = 0;
      item.quantityPerBox = 0;
      item.lineTotal = 0;
    }
    returnItems.refresh();
  }

  // ─── DATE SELECTION ──────────────────────────────────────────

  void selectReturnDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedReturnDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      selectedReturnDate.value = date;
      returnDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE RETURN
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createDraftReturn() async {
    if (!canCreateReturn) {
      Get.snackbar('Validation', 'Please fill all required fields');
      return false;
    }

    try {
      isSubmitting.value = true;

      final items = returnItems
          .where((item) => item.isSelected && item.returnQuantity > 0)
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'sku': item.sku,
              'purchaseInvoiceItemId': item.purchaseInvoiceItemId,
              'returnQuantity': item.returnQuantity,
              'isBoxBased': item.isBoxBased,
              'boxes': item.boxes ?? 0,
              'quantityPerBox': item.quantityPerBox ?? 0,
              'unitPrice': item.unitPrice,
              'returnReason': item.returnReason.isNotEmpty
                  ? item.returnReason
                  : returnReason.value,
              'notes': item.notes ?? '',
            },
          )
          .toList();

      final payload = {
        'supplierId': selectedSupplier.value?['id'],
        'supplierName': selectedSupplier.value?['name'],
        'purchaseInvoiceId': selectedInvoice.value?.id,
        'purchaseInvoiceNumber': selectedInvoice.value?.invoiceNumber,
        'returnReason': returnReason.value,
        'notes': notesController.text.trim(),
        'items': items,
      };

      print('🔵 [PurchaseReturnController] Creating return...');
      final response = await _api.post(
        '/api/purchase/returns/draft',
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        print('✅ [PurchaseReturnController] Return created successfully');
        Get.snackbar('Success', 'Purchase return created successfully');
        closeCreateForm();
        await fetchReturns(resetPage: true);
        return true;
      }

      print('❌ [PurchaseReturnController] Failed to create return');
      Get.snackbar(
        'Error',
        response.message ?? 'Failed to create return',
      );
      return false;
    } catch (e) {
      print('❌ [PurchaseReturnController] createDraftReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RETURN ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectReturn(PurchaseReturnModel returnItem) {
    selectedReturn.value = returnItem;
  }

  Future<bool> processReturn(String id) async {
    try {
      isSubmitting.value = true;

      final response = await _api.post(
        '/api/purchase/returns/$id/process',
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Return processed successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message ?? 'Failed to process return');
      return false;
    } catch (e) {
      print('❌ [PurchaseReturnController] processReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelReturn(String id, {String? reason}) async {
    try {
      isSubmitting.value = true;

      final response = await _api.post(
        '/api/purchase/returns/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Return cancelled successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message ?? 'Failed to cancel return');
      return false;
    } catch (e) {
      print('❌ [PurchaseReturnController] cancelReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteReturn(String id) async {
    try {
      isSubmitting.value = true;

      final response = await _api.delete(
        '/api/purchase/returns/$id',
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Return deleted successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message ?? 'Failed to delete return');
      return false;
    } catch (e) {
      print('❌ [PurchaseReturnController] deleteReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
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
// RETURN ITEM FOR FORM MODEL
// ═══════════════════════════════════════════════════════════════

class ReturnItemForForm {
  final String productId;
  final String productName;
  final String sku;
  final String purchaseInvoiceItemId;
  final int purchasedQuantity;
  final int previouslyReturned;
  final int availableQuantity;
  final double unitPrice;
  final bool isBoxBased;
  final int boxQuantity;
  final String boxUnitName;
  final String returnReason;
  final String? notes;

  bool isSelected;
  int returnQuantity;
  int? boxes;
  int? quantityPerBox;
  double lineTotal;

  ReturnItemForForm({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.purchaseInvoiceItemId,
    required this.purchasedQuantity,
    required this.previouslyReturned,
    required this.availableQuantity,
    required this.unitPrice,
    required this.isBoxBased,
    required this.boxQuantity,
    required this.boxUnitName,
    required this.returnReason,
    this.notes,
    this.isSelected = false,
    this.returnQuantity = 0,
    this.boxes = 0,
    this.quantityPerBox = 0,
    this.lineTotal = 0,
  });

  factory ReturnItemForForm.fromJson(Map<String, dynamic> json) {
    return ReturnItemForForm(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      purchaseInvoiceItemId: json['id'] ?? '',
      purchasedQuantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previouslyReturned: (json['previouslyReturned'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      isBoxBased: json['isBoxBased'] ?? false,
      boxQuantity: (json['boxQuantity'] as num?)?.toInt() ?? 0,
      boxUnitName: json['boxUnitName'] ?? 'Box',
      returnReason: json['returnReason'] ?? 'Return',
      notes: json['notes'],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE RETURN STATS MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseReturnStats {
  final int todayCount;
  final double todayAmount;
  final int monthCount;
  final double monthAmount;
  final int draftCount;

  PurchaseReturnStats({
    required this.todayCount,
    required this.todayAmount,
    required this.monthCount,
    required this.monthAmount,
    required this.draftCount,
  });

  factory PurchaseReturnStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};
    final draft = json['draft'] as Map<String, dynamic>? ?? {};

    return PurchaseReturnStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      todayAmount: (today['amount'] as num?)?.toDouble() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      monthAmount: (month['amount'] as num?)?.toDouble() ?? 0,
      draftCount: (draft['count'] as num?)?.toInt() ?? 0,
    );
  }
}
