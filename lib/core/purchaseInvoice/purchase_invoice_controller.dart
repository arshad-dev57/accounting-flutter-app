// lib/core/warehouse/purchase_invoice/controller/purchase_invoice_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/purchaseInvoice/purchase_invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchaseInvoiceController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<PurchaseInvoiceModel> invoices = <PurchaseInvoiceModel>[].obs;
  final RxList<PurchaseInvoiceModel> filteredInvoices =
      <PurchaseInvoiceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<PurchaseInvoiceModel?> selectedInvoice = Rx<PurchaseInvoiceModel?>(
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
  final RxString statusFilter = 'all'.obs;
  final RxString paymentFilter = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = [
    'all',
    'Unpaid',
    'Partial',
    'Paid',
    'Cancelled',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<PurchaseInvoiceStats> stats = PurchaseInvoiceStats(
    todayCount: 0,
    todayAmount: 0,
    monthCount: 0,
    monthAmount: 0,
    draft: 0,
    posted: 0,
    partiallyPaid: 0,
    paid: 0,
    cancelled: 0,
    totalOutstanding: 0,
  ).obs;

  // ─── CREATE WIZARD STATE ─────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<Map<String, dynamic>> sourceResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingSource = false.obs;
  final RxString sourceType = 'grn'.obs; // 'grn' or 'po'
  final Rx<Map<String, dynamic>?> selectedSource = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<PurchaseInvoiceLineDraft> lineDrafts =
      <PurchaseInvoiceLineDraft>[].obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final sourceSearchController = TextEditingController();
  final supplierInvoiceNoController = TextEditingController();
  final invoiceDateController = TextEditingController();
  final dueDateController = TextEditingController();
  final paymentTermsController = TextEditingController(text: 'Net 30');
  final notesController = TextEditingController();

  // ─── SELECTED DATES ──────────────────────────────────────────
  final Rx<DateTime?> selectedInvoiceDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedDueDate = Rx<DateTime?>(null);

  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    selectedInvoiceDate.value = DateTime.now();
    selectedDueDate.value = DateTime.now().add(const Duration(days: 30));
    invoiceDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedInvoiceDate.value!);
    dueDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedDueDate.value!);
    Future(() async {
      await waitForFiscalYearReady();
      fetchInvoices();
    });
    _fyWorker = listenFiscalYearChanges(() => fetchInvoices());
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    sourceSearchController.dispose();
    supplierInvoiceNoController.dispose();
    invoiceDateController.dispose();
    dueDateController.dispose();
    paymentTermsController.dispose();
    notesController.dispose();
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
  // FETCH INVOICES
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchInvoices({bool resetPage = false}) async {

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
      if (paymentFilter.value != 'all') {
        params['paymentStatus'] = paymentFilter.value;
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
      }
      final fyId = currentFiscalYearId();
      if (fyId != null) params['fiscalYearId'] = fyId;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/purchase/invoices?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        invoices.value = list
            .map(
              (e) =>
                  PurchaseInvoiceModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = PurchaseInvoiceStats.fromJson(
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

    final list = invoices.toList();
    final filtered = list.where((item) {
      // Payment / cancel filters
      if (selectedFilter.value == 'Unpaid' && item.paymentStatus != 'Unpaid') {
        return false;
      }
      if (selectedFilter.value == 'Partial' && item.paymentStatus != 'Partial') {
        return false;
      }
      if (selectedFilter.value == 'Paid' && item.paymentStatus != 'Paid') {
        return false;
      }
      if (selectedFilter.value == 'Cancelled' &&
          item.invoiceStatus != 'Cancelled') {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.invoiceNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.supplierInvoiceNo?.toLowerCase().contains(query) == true ||
            item.purchaseOrderNumber?.toLowerCase().contains(query) == true;
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredInvoices.value = filtered;
  }

  void filterInvoices(String filter) {
    selectedFilter.value = filter;
    // Payment states use paymentStatus; Cancelled uses invoiceStatus
    if (filter == 'Unpaid' || filter == 'Partial' || filter == 'Paid') {
      statusFilter.value = 'all';
      paymentFilter.value = filter;
    } else if (filter == 'Cancelled') {
      statusFilter.value = 'Cancelled';
      paymentFilter.value = 'all';
    } else {
      statusFilter.value = 'all';
      paymentFilter.value = 'all';
    }
    fetchInvoices(resetPage: true);
  }

  void searchInvoices(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchInvoices(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreInvoices() async {

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
      if (paymentFilter.value != 'all')
        params['paymentStatus'] = paymentFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/purchase/invoices?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newInvoices = list
            .map(
              (e) =>
                  PurchaseInvoiceModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        invoices.addAll(newInvoices);
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
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshInvoices() {
    return fetchInvoices(resetPage: true);
  }

  void applyFilters() {
    fetchInvoices(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    _resetWizard();
    showCreateWizard.value = true;
    searchSource('');
  }

  void closeCreateWizard() {
    showCreateWizard.value = false;
    _resetWizard();
  }

  void _resetWizard() {
    wizardStep.value = 0;
    selectedSource.value = null;
    sourceResults.clear();
    lineDrafts.clear();
    sourceSearchController.clear();
    supplierInvoiceNoController.clear();
    notesController.clear();
    paymentTermsController.text = 'Net 30';
    selectedInvoiceDate.value = DateTime.now();
    selectedDueDate.value = DateTime.now().add(const Duration(days: 30));
    invoiceDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedInvoiceDate.value!);
    dueDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedDueDate.value!);
  }

  // ─── SOURCE SEARCH ───────────────────────────────────────────

  void setSourceType(String type) {
    sourceType.value = type;
    sourceSearchController.clear();
    sourceResults.clear();
    selectedSource.value = null;
    lineDrafts.clear();
    // Load recent available sources (GRN optional for PO invoices)
    searchSource('');
  }

  Future<void> searchSource(String query) async {

    try {
      isSearchingSource.value = true;
      final trimmed = query.trim();
      final encoded = Uri.encodeComponent(trimmed);
      final endpoint = sourceType.value == 'grn'
          ? '/api/purchase/invoices/available-grns?search=$encoded&limit=20'
          : '/api/purchase/invoices/available-pos?search=$encoded&limit=20';


      final response = await _api.get(endpoint, requiresAuth: true);

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        sourceResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        sourceResults.clear();
      }
    } catch (e) {
      sourceResults.clear();
    } finally {
      isSearchingSource.value = false;
    }
  }

  void selectSource(Map<String, dynamic> source) {
    final displayName = sourceType.value == 'grn'
        ? source['grnNumber']
        : source['orderNumber'];

    if (source['hasInvoice'] == true) {
      Get.snackbar(
        'Already Invoiced',
        'This ${sourceType.value == 'grn' ? 'GRN' : 'PO'} already has invoice(s).',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    selectedSource.value = source;
    sourceResults.clear();
    sourceSearchController.text = displayName ?? '';

    // Line drafts from source items (PO ordered qty or GRN received qty)
    final items = source['items'] as List? ?? [];
    lineDrafts.value = items.map((item) {
      final qty =
          item['receivingQuantity'] ??
          item['quantity'] ??
          0;
      return PurchaseInvoiceLineDraft(
        productId: item['productId'] ?? '',
        productName: item['productName'] ?? '',
        sku: item['sku'] ?? '',
        quantity: qty is int ? qty : (qty as num).toInt(),
        unitPrice:
            (item['unitPrice'] as num?)?.toDouble() ??
            (item['costPrice'] as num?)?.toDouble() ??
            0,
        discount: (item['discount'] as num?)?.toDouble() ?? 0,
        taxRate: (item['taxRate'] as num?)?.toDouble() ?? 0,
        notes: item['notes'],
      );
    }).where((line) => line.quantity > 0).toList();

    if (lineDrafts.isEmpty) {
      Get.snackbar(
        'No Items',
        'No quantities available to invoice for this source.',
        snackPosition: SnackPosition.BOTTOM,
      );
      selectedSource.value = null;
      return;
    }

  }

  // ─── DATE SELECTION ──────────────────────────────────────────

  void selectInvoiceDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedInvoiceDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedInvoiceDate.value = date;
      invoiceDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  void selectDueDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedDueDate.value ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedDueDate.value = date;
      dueDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  // ─── WIZARD NAVIGATION ──────────────────────────────────────

  bool canGoToStep2() {
    final canGo = selectedSource.value != null && lineDrafts.isNotEmpty;
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    return canGo;
  }

  void nextStep() {

    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select a source first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar('Validation', 'No items available for invoicing');
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
  // CREATE INVOICE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createInvoice() async {

    final source = selectedSource.value;
    if (source == null) {
      return false;
    }

    if (lineDrafts.isEmpty) {
      Get.snackbar('Validation', 'No items to invoice');
      return false;
    }

    final invoiceDate = selectedInvoiceDate.value;
    final dueDate = selectedDueDate.value;

    if (invoiceDate == null || dueDate == null) {
      Get.snackbar('Validation', 'Please select dates');
      return false;
    }

    try {
      isSubmitting.value = true;

      final payload = {
        if (sourceType.value == 'grn')
          'goodsReceivingId': source['id']
        else
          'purchaseOrderId': source['id'],
        'supplierInvoiceNo': supplierInvoiceNoController.text.trim().isEmpty
            ? null
            : supplierInvoiceNoController.text.trim(),
        'invoiceDate': invoiceDate.toIso8601String().split('T').first,
        'dueDate': dueDate.toIso8601String().split('T').first,
        'paymentTerms': paymentTermsController.text.trim().isEmpty
            ? 'Net 30'
            : paymentTermsController.text.trim(),
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      };

      final endpoint = sourceType.value == 'grn'
          ? '/api/purchase/invoices/from-grn'
          : '/api/purchase/invoices/from-po';


      final response = await _api.post(
        endpoint,
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase invoice created successfully');
        closeCreateWizard();
        await fetchInvoices(resetPage: true);
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
  // INVOICE ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectInvoice(PurchaseInvoiceModel invoice) {
    selectedInvoice.value = invoice;
  }

  Future<bool> postInvoice(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/invoices/$id/post',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar(
          'Success',
          'Purchase invoice posted and accounting entries created',
        );
        await fetchInvoices();
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

  Future<bool> cancelInvoice(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/invoices/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase invoice cancelled');
        await fetchInvoices();
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

  Future<bool> deleteInvoice(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/invoices/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Purchase invoice deleted successfully');
        await fetchInvoices(resetPage: true);
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

  Future<PurchaseInvoiceModel?> getInvoiceById(String id) async {

    try {
      final response = await _api.get(
        '/api/purchase/invoices/$id',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final invoice = PurchaseInvoiceModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        return invoice;
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
      case 'Posted':
        return Colors.blue;
      case 'Partially Paid':
        return Colors.purple;
      case 'Paid':
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
      case 'Posted':
        return 'Posted';
      case 'Partially Paid':
        return 'Partial Paid';
      case 'Paid':
        return 'Paid';
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
// PURCHASE INVOICE LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceLineDraft {
  String productId;
  String productName;
  String sku;
  int quantity;
  double unitPrice;
  double discount;
  double taxRate;
  String? notes;

  PurchaseInvoiceLineDraft({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.taxRate,
    this.notes,
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
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE STATS MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceStats {
  final int todayCount;
  final double todayAmount;
  final int monthCount;
  final double monthAmount;
  final int draft;
  final int posted;
  final int partiallyPaid;
  final int paid;
  final int cancelled;
  final double totalOutstanding;

  PurchaseInvoiceStats({
    required this.todayCount,
    required this.todayAmount,
    required this.monthCount,
    required this.monthAmount,
    required this.draft,
    required this.posted,
    required this.partiallyPaid,
    required this.paid,
    required this.cancelled,
    required this.totalOutstanding,
  });

  factory PurchaseInvoiceStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};
    final status = json['status'] as Map<String, dynamic>? ?? {};

    return PurchaseInvoiceStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      todayAmount: (today['amount'] as num?)?.toDouble() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      monthAmount: (month['amount'] as num?)?.toDouble() ?? 0,
      draft: (status['draft'] as num?)?.toInt() ?? 0,
      posted: (status['posted'] as num?)?.toInt() ?? 0,
      partiallyPaid: (status['partiallyPaid'] as num?)?.toInt() ?? 0,
      paid: (status['paid'] as num?)?.toInt() ?? 0,
      cancelled: (status['cancelled'] as num?)?.toInt() ?? 0,
      totalOutstanding: (json['totalOutstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}
