// lib/core/warehouse/quotation/controller/quotation_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/quotation/quotation_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class QuotationController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<QuotationModel> quotations = <QuotationModel>[].obs;
  final RxList<QuotationModel> filteredQuotations = <QuotationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<QuotationModel?> selectedQuotation = Rx<QuotationModel?>(null);

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
    'Accepted',
    'Rejected',
    'Expired',
    'Converted',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<QuotationStats> stats = QuotationStats(
    total: 0,
    draft: 0,
    sent: 0,
    accepted: 0,
    rejected: 0,
    expired: 0,
    converted: 0,
    totalValue: 0,
    convertedValue: 0,
  ).obs;

  final Rx<Map<String, dynamic>> monthlyStats = Rx<Map<String, dynamic>>({});

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const statusOptions = [
    'all',
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Expired',
    'Converted',
  ];

  // ─── WIZARD STATE ─────────────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<Map<String, dynamic>> customerSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingCustomers = false.obs;
  final Rx<Map<String, dynamic>?> selectedCustomer = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<QuotationLineDraft> lineDrafts = <QuotationLineDraft>[].obs;
  final RxList<Map<String, dynamic>> productSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingProducts = false.obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final customerSearchController = TextEditingController();
  final productSearchController = TextEditingController();
  final quotationDateController = TextEditingController();
  final validUntilController = TextEditingController();
  final salesPersonController = TextEditingController();
  final notesController = TextEditingController();
  final termsConditionsController = TextEditingController();

  // ─── SELECTED DATES ──────────────────────────────────────────
  final Rx<DateTime?> selectedQuotationDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedValidUntil = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Set default dates
    selectedQuotationDate.value = DateTime.now();
    selectedValidUntil.value = DateTime.now().add(const Duration(days: 30));
    quotationDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedQuotationDate.value!);
    validUntilController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedValidUntil.value!);
    fetchQuotations();
  }

  @override
  void onClose() {
    customerSearchController.dispose();
    productSearchController.dispose();
    quotationDateController.dispose();
    validUntilController.dispose();
    salesPersonController.dispose();
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
  // FETCH QUOTATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchQuotations({bool resetPage = false}) async {

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
        '/api/quotations?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        quotations.value = list
            .map((e) => QuotationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        applyLocalFilters();

        if (response.data['kpi'] != null) {
          stats.value = QuotationStats.fromJson(
            Map<String, dynamic>.from(response.data['kpi']),
          );
        }

        if (response.data['stats'] != null) {
          monthlyStats.value = Map<String, dynamic>.from(
            response.data['stats'],
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
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {

    final list = quotations.toList();
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
            item.quotationNumber.toLowerCase().contains(query) ||
            item.customerName.toLowerCase().contains(query) ||
            item.customerEmail?.toLowerCase().contains(query) == true ||
            item.customerCompany?.toLowerCase().contains(query) == true;
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredQuotations.value = filtered;
  }

  void filterQuotations(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchQuotations(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchQuotations(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreQuotations() async {

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
        '/api/quotations?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newQuotations = list
            .map((e) => QuotationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        quotations.addAll(newQuotations);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshQuotations() {
    return fetchQuotations(resetPage: true);
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
    selectedCustomer.value = null;
    customerSearchResults.clear();
    lineDrafts.clear();
    productSearchResults.clear();
    customerSearchController.clear();
    productSearchController.clear();
    salesPersonController.clear();
    notesController.clear();
    termsConditionsController.clear();
    selectedQuotationDate.value = DateTime.now();
    selectedValidUntil.value = DateTime.now().add(const Duration(days: 30));
    quotationDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedQuotationDate.value!);
    validUntilController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedValidUntil.value!);
  }

  // ─── CUSTOMER SEARCH ──────────────────────────────────────

  Future<void> searchCustomers(String query) async {

    if (query.trim().length < 2) {
      customerSearchResults.clear();
      return;
    }

    try {
      isSearchingCustomers.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/customers?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        customerSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        customerSearchResults.clear();
      }
    } catch (e) {
      customerSearchResults.clear();
    } finally {
      isSearchingCustomers.value = false;
    }
  }

  void selectCustomer(Map<String, dynamic> customer) {
    selectedCustomer.value = customer;
    customerSearchResults.clear();
    customerSearchController.text = customer['name'] ?? '';
  }

  // ─── PRODUCT SEARCH ──────────────────────────────────────

  Future<void> searchProducts(String query) async {

    if (query.trim().length < 2) {
      productSearchResults.clear();
      return;
    }

    try {
      isSearchingProducts.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/products?search=$encoded&limit=10',
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

  void addProductToQuotation(Map<String, dynamic> product) {

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
      final newLine = QuotationLineDraft(
        productId: product['id'] ?? '',
        productName: product['name'] ?? '',
        sku: product['sku'] ?? '',
        quantity: 1,
        unitPrice: product['sellingPrice']?.toDouble() ?? 0,
        discount: 0,
        taxRate: product['taxRate']?.toDouble() ?? 0,
      );
      lineDrafts.add(newLine);
    }

    // Clear product search
    productSearchResults.clear();
    productSearchController.clear();
  }

  void removeProductFromQuotation(int index) {
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

  // ─── DATE SELECTION ──────────────────────────────────────

  void selectQuotationDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedQuotationDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedQuotationDate.value = date;
      quotationDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  void selectValidUntilDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedValidUntil.value ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedValidUntil.value = date;
      validUntilController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  // ─── WIZARD NAVIGATION ──────────────────────────────────

  bool canGoToStep2() {
    final canGo = selectedCustomer.value != null;
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    return canGo;
  }

  void nextStep() {

    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select a customer first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar('Validation', 'Add at least one item to the quotation');
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
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createQuotation() async {

    final customer = selectedCustomer.value;
    if (customer == null) {
      return false;
    }

    if (lineDrafts.isEmpty) {
      Get.snackbar('Validation', 'Add at least one item');
      return false;
    }

    final quotationDate = selectedQuotationDate.value;
    final validUntil = selectedValidUntil.value;

    if (quotationDate == null || validUntil == null) {
      Get.snackbar('Validation', 'Please select dates');
      return false;
    }

    try {
      isSubmitting.value = true;

      final items = lineDrafts
          .map(
            (line) => {
              'productId': line.productId,
              'quantity': line.quantity,
              'unitPrice': line.unitPrice,
              'discount': line.discount,
              'taxRate': line.taxRate,
              'notes': null,
            },
          )
          .toList();

      final payload = {
        'customerId': customer['id'],
        'customerName': customer['name'],
        'customerEmail': customer['email'] ?? '',
        'customerPhone': customer['phone'] ?? '',
        'customerCompany': customer['company'] ?? '',
        'quotationDate': quotationDate.toIso8601String().split('T').first,
        'validUntil': validUntil.toIso8601String().split('T').first,
        'salesPerson': salesPersonController.text.trim().isEmpty
            ? null
            : salesPersonController.text.trim(),
        'items': items,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'termsConditions': termsConditionsController.text.trim().isEmpty
            ? null
            : termsConditionsController.text.trim(),
        'status': 'Draft',
      };


      final response = await _api.post(
        '/api/quotations',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation created successfully');
        closeCreateWizard();
        await fetchQuotations(resetPage: true);
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

  Future<bool> updateQuotation(String id, Map<String, dynamic> data) async {

    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/quotations/$id',
        body: data,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation updated successfully');
        await fetchQuotations(resetPage: true);
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

  Future<bool> deleteQuotation(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/quotations/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation deleted successfully');
        await fetchQuotations(resetPage: true);
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

  // ═══════════════════════════════════════════════════════════════
  // QUOTATION ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectQuotation(QuotationModel item) {
    selectedQuotation.value = item;
  }

  Future<bool> updateQuotationStatus(
    String id,
    String status, {
    String? notes,
  }) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/quotations/$id/status',
        body: {'status': status, 'notes': notes ?? ''},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation status updated to $status');
        await fetchQuotations();
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

  Future<bool> convertToOrder(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/quotations/$id/convert',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation converted to sales order');
        await fetchQuotations();
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

  Future<bool> sendQuotation(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/quotations/$id/send',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Quotation sent successfully');
        await fetchQuotations();
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

  // ═══════════════════════════════════════════════════════════════
  // HELPER: GET STATUS COLOR
  // ═══════════════════════════════════════════════════════════════

  Color getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Sent':
        return Colors.blue;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.grey;
      case 'Converted':
        return Colors.purple;
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
      case 'Accepted':
        return 'Accepted';
      case 'Rejected':
        return 'Rejected';
      case 'Expired':
        return 'Expired';
      case 'Converted':
        return 'Converted';
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
// QUOTATION LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class QuotationLineDraft {
  String productId;
  String productName;
  String sku;
  int quantity;
  double unitPrice;
  double discount;
  double taxRate;

  QuotationLineDraft({
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
