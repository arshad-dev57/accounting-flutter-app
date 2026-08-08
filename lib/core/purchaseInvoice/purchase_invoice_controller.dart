// lib/core/warehouse/purchase_invoice/controller/purchase_invoice_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
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
    'Draft',
    'Posted',
    'Partially Paid',
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

  @override
  void onInit() {
    super.onInit();
    print('🟢 [PurchaseInvoiceController] onInit called');
    selectedInvoiceDate.value = DateTime.now();
    selectedDueDate.value = DateTime.now().add(const Duration(days: 30));
    invoiceDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedInvoiceDate.value!);
    dueDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedDueDate.value!);
    fetchInvoices();
  }

  @override
  void onClose() {
    print(
      '🟢 [PurchaseInvoiceController] onClose called - disposing controllers',
    );
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
    print('🔵 [PurchaseInvoiceController] fetchInvoices called');
    print(
      '🔵 [PurchaseInvoiceController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [PurchaseInvoiceController] Reset Page: $resetPage');

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
          '🔵 [PurchaseInvoiceController] Search filter: ${searchFilter.value}',
        );
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print(
          '🔵 [PurchaseInvoiceController] Status filter: ${statusFilter.value}',
        );
      }
      if (paymentFilter.value != 'all') {
        params['paymentStatus'] = paymentFilter.value;
        print(
          '🔵 [PurchaseInvoiceController] Payment filter: ${paymentFilter.value}',
        );
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print(
          '🔵 [PurchaseInvoiceController] From date: ${params['fromDate']}',
        );
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [PurchaseInvoiceController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [PurchaseInvoiceController] API Request: GET /api/purchase/invoices?$query',
      );

      final response = await _api.get(
        '/api/purchase/invoices?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [PurchaseInvoiceController] Data length: ${list.length}');

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
          print('🔵 [PurchaseInvoiceController] Stats: ${stats.value}');
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
            '✅ [PurchaseInvoiceController] Invoices fetched successfully: ${invoices.length} invoices',
          );
          print(
            '✅ [PurchaseInvoiceController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [PurchaseInvoiceController] Failed to fetch invoices');
        print('❌ [PurchaseInvoiceController] Response data: ${response.data}');
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to load purchase invoices',
        );
      }
    } catch (e) {
      print('❌ [PurchaseInvoiceController] fetchInvoices error: $e');
      print('❌ [PurchaseInvoiceController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [PurchaseInvoiceController] fetchInvoices completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [PurchaseInvoiceController] applyLocalFilters called');
    print(
      '🟣 [PurchaseInvoiceController] Selected filter: ${selectedFilter.value}',
    );
    print(
      '🟣 [PurchaseInvoiceController] Search filter: ${searchFilter.value}',
    );

    final list = invoices.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          item.invoiceStatus != selectedFilter.value) {
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

    print(
      '🟣 [PurchaseInvoiceController] Filtered invoices: ${filtered.length} out of ${list.length}',
    );
    filteredInvoices.value = filtered;
  }

  void filterInvoices(String filter) {
    print('🟣 [PurchaseInvoiceController] filterInvoices called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchInvoices(String query) {
    print('🟣 [PurchaseInvoiceController] searchInvoices called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [PurchaseInvoiceController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchInvoices(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreInvoices() async {
    print('🟡 [PurchaseInvoiceController] fetchMoreInvoices called');
    print(
      '🟡 [PurchaseInvoiceController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [PurchaseInvoiceController] Skipping load more');
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print(
        '🟡 [PurchaseInvoiceController] Loading page: ${currentPage.value}',
      );

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
      print(
        '🟡 [PurchaseInvoiceController] API Request: GET /api/purchase/invoices?$query',
      );

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

        print(
          '🟡 [PurchaseInvoiceController] Loaded ${newInvoices.length} more invoices',
        );
        invoices.addAll(newInvoices);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print(
          '🟡 [PurchaseInvoiceController] Total invoices now: ${invoices.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [PurchaseInvoiceController] Failed to load more invoices');
      }
    } catch (e) {
      print('❌ [PurchaseInvoiceController] fetchMoreInvoices error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [PurchaseInvoiceController] fetchMoreInvoices completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshInvoices() {
    print('🟢 [PurchaseInvoiceController] refreshInvoices called');
    return fetchInvoices(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [PurchaseInvoiceController] applyFilters called');
    fetchInvoices(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [PurchaseInvoiceController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    print(
      '🟢 [PurchaseInvoiceController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void closeCreateWizard() {
    print('🟢 [PurchaseInvoiceController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print(
      '🟢 [PurchaseInvoiceController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void _resetWizard() {
    print('🟢 [PurchaseInvoiceController] _resetWizard called');
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
    print('✅ [PurchaseInvoiceController] Wizard reset complete');
  }

  // ─── SOURCE SEARCH ───────────────────────────────────────────

  void setSourceType(String type) {
    print('🟢 [PurchaseInvoiceController] setSourceType called: $type');
    sourceType.value = type;
    sourceSearchController.clear();
    sourceResults.clear();
    selectedSource.value = null;
    lineDrafts.clear();
  }

  Future<void> searchSource(String query) async {
    print('🔵 [PurchaseInvoiceController] searchSource called with: "$query"');

    if (query.trim().length < 2) {
      print('🔵 [PurchaseInvoiceController] Query too short, clearing results');
      sourceResults.clear();
      return;
    }

    try {
      isSearchingSource.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      final endpoint = sourceType.value == 'grn'
          ? '/api/purchase/invoices/available-grns?search=$encoded&limit=10'
          : '/api/purchase/invoices/available-pos?search=$encoded&limit=10';

      print('🔵 [PurchaseInvoiceController] API Request: GET $endpoint');

      final response = await _api.get(endpoint, requiresAuth: true);

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        sourceResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '🔵 [PurchaseInvoiceController] Found ${sourceResults.length} results for query: $query',
        );
      } else {
        print('❌ [PurchaseInvoiceController] No results found');
        sourceResults.clear();
      }
    } catch (e) {
      print('❌ [PurchaseInvoiceController] searchSource error: $e');
      sourceResults.clear();
    } finally {
      isSearchingSource.value = false;
      print('🔵 [PurchaseInvoiceController] searchSource completed');
    }
  }

  void selectSource(Map<String, dynamic> source) {
    print('🔵 [PurchaseInvoiceController] selectSource called');
    final displayName = sourceType.value == 'grn'
        ? source['grnNumber']
        : source['orderNumber'];
    print('🔵 [PurchaseInvoiceController] Selected source: $displayName');

    selectedSource.value = source;
    sourceResults.clear();
    sourceSearchController.text = displayName ?? '';

    // Create line drafts from source items
    final items = source['items'] as List? ?? [];
    lineDrafts.value = items.map((item) {
      return PurchaseInvoiceLineDraft(
        productId: item['productId'] ?? '',
        productName: item['productName'] ?? '',
        sku: item['sku'] ?? '',
        quantity: item['quantity'] ?? item['receivingQuantity'] ?? 0,
        unitPrice:
            item['unitPrice']?.toDouble() ?? item['costPrice']?.toDouble() ?? 0,
        discount: item['discount']?.toDouble() ?? 0,
        taxRate: item['taxRate']?.toDouble() ?? 0,
        notes: item['notes'],
      );
    }).toList();

    print(
      '🔵 [PurchaseInvoiceController] Created ${lineDrafts.length} line drafts',
    );
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
    print('🔵 [PurchaseInvoiceController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    print('🔵 [PurchaseInvoiceController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print(
      '🟡 [PurchaseInvoiceController] nextStep called, current step: ${wizardStep.value}',
    );

    if (wizardStep.value == 0 && !canGoToStep2()) {
      print(
        '❌ [PurchaseInvoiceController] Cannot go to step 2 - no source selected',
      );
      Get.snackbar('Validation', 'Select a source first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print(
        '❌ [PurchaseInvoiceController] Cannot go to step 3 - no items available',
      );
      Get.snackbar('Validation', 'No items available for invoicing');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print(
        '🟡 [PurchaseInvoiceController] Step changed to: ${wizardStep.value}',
      );
    }
  }

  void previousStep() {
    print(
      '🟡 [PurchaseInvoiceController] previousStep called, current step: ${wizardStep.value}',
    );
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print(
        '🟡 [PurchaseInvoiceController] Step changed to: ${wizardStep.value}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE INVOICE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createInvoice() async {
    print('🔵 [PurchaseInvoiceController] createInvoice called');

    final source = selectedSource.value;
    if (source == null) {
      print('❌ [PurchaseInvoiceController] No source selected');
      return false;
    }

    if (lineDrafts.isEmpty) {
      print('❌ [PurchaseInvoiceController] No items in invoice');
      Get.snackbar('Validation', 'No items to invoice');
      return false;
    }

    final invoiceDate = selectedInvoiceDate.value;
    final dueDate = selectedDueDate.value;

    if (invoiceDate == null || dueDate == null) {
      print('❌ [PurchaseInvoiceController] Dates not selected');
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

      print('🔵 [PurchaseInvoiceController] Submitting invoice payload');
      print('🔵 [PurchaseInvoiceController] Endpoint: $endpoint');

      final response = await _api.post(
        endpoint,
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print(
          '✅ [PurchaseInvoiceController] Purchase invoice created successfully!',
        );
        Get.snackbar('Success', 'Purchase invoice created successfully');
        closeCreateWizard();
        await fetchInvoices(resetPage: true);
        return true;
      }

      print(
        '❌ [PurchaseInvoiceController] Failed to create invoice: ${response.message}',
      );
      Get.snackbar(
        'Error',
        response.message ?? 'Failed to create purchase invoice',
      );
      return false;
    } catch (e) {
      print('❌ [PurchaseInvoiceController] createInvoice error: $e');
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
    print(
      '🔵 [PurchaseInvoiceController] selectInvoice called for: ${invoice.invoiceNumber}',
    );
    selectedInvoice.value = invoice;
  }

  Future<bool> postInvoice(String id) async {
    print('🟣 [PurchaseInvoiceController] postInvoice called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/invoices/$id/post',
        body: {},
        requiresAuth: true,
      );

      print(
        '🟣 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseInvoiceController] Invoice posted successfully');
        Get.snackbar(
          'Success',
          'Purchase invoice posted and accounting entries created',
        );
        await fetchInvoices();
        return true;
      }

      print(
        '❌ [PurchaseInvoiceController] Failed to post invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to post invoice');
      return false;
    } catch (e) {
      print('❌ [PurchaseInvoiceController] postInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelInvoice(String id, {String? reason}) async {
    print('🟣 [PurchaseInvoiceController] cancelInvoice called for ID: $id');
    print('🟣 [PurchaseInvoiceController] Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/invoices/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseInvoiceController] Invoice cancelled successfully');
        Get.snackbar('Success', 'Purchase invoice cancelled');
        await fetchInvoices();
        return true;
      }

      print(
        '❌ [PurchaseInvoiceController] Failed to cancel invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to cancel invoice');
      return false;
    } catch (e) {
      print('❌ [PurchaseInvoiceController] cancelInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    print('🔵 [PurchaseInvoiceController] deleteInvoice called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/invoices/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [PurchaseInvoiceController] Invoice deleted successfully');
        Get.snackbar('Success', 'Purchase invoice deleted successfully');
        await fetchInvoices(resetPage: true);
        return true;
      }

      print(
        '❌ [PurchaseInvoiceController] Failed to delete invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete invoice');
      return false;
    } catch (e) {
      print('❌ [PurchaseInvoiceController] deleteInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<PurchaseInvoiceModel?> getInvoiceById(String id) async {
    print('🔵 [PurchaseInvoiceController] getInvoiceById called for ID: $id');

    try {
      final response = await _api.get(
        '/api/purchase/invoices/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [PurchaseInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [PurchaseInvoiceController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final invoice = PurchaseInvoiceModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print(
          '✅ [PurchaseInvoiceController] Invoice found: ${invoice.invoiceNumber}',
        );
        return invoice;
      }
      print('❌ [PurchaseInvoiceController] Invoice not found');
      return null;
    } catch (e) {
      print('❌ [PurchaseInvoiceController] getInvoiceById error: $e');
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
