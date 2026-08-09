// lib/core/warehouse/sales_invoice/controller/sales_invoice_controller.dart

import 'dart:io';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/sales_invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesInvoiceController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<SalesInvoiceModel> invoices = <SalesInvoiceModel>[].obs;
  final RxList<SalesInvoiceModel> filteredInvoices = <SalesInvoiceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<SalesInvoiceModel?> selectedInvoice = Rx<SalesInvoiceModel?>(null);

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
  final Rx<InvoiceStats> stats = InvoiceStats(
    total: 0,
    draft: 0,
    posted: 0,
    partiallyPaid: 0,
    paid: 0,
    cancelled: 0,
    totalValue: 0,
    outstanding: 0,
  ).obs;

  final Rx<Map<String, dynamic>> monthlyStats = Rx<Map<String, dynamic>>({});

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const statusOptions = [
    'all',
    'Draft',
    'Posted',
    'Partially Paid',
    'Paid',
    'Cancelled',
  ];
  static const paymentOptions = ['all', 'Unpaid', 'Partial', 'Paid'];

  // ─── CREATE WIZARD STATE ─────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<Map<String, dynamic>> orderSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<Map<String, dynamic>?> selectedOrder = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<InvoiceLineDraft> lineDrafts = <InvoiceLineDraft>[].obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final orderSearchController = TextEditingController();
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
    print('🟢 [SalesInvoiceController] onInit called');
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
    print('🟢 [SalesInvoiceController] onClose called - disposing controllers');
    orderSearchController.dispose();
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
    print('🔵 [SalesInvoiceController] fetchInvoices called');
    print(
      '🔵 [SalesInvoiceController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [SalesInvoiceController] Reset Page: $resetPage');

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
          '🔵 [SalesInvoiceController] Search filter: ${searchFilter.value}',
        );
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print(
          '🔵 [SalesInvoiceController] Status filter: ${statusFilter.value}',
        );
      }
      if (paymentFilter.value != 'all') {
        params['paymentStatus'] = paymentFilter.value;
        print(
          '🔵 [SalesInvoiceController] Payment filter: ${paymentFilter.value}',
        );
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesInvoiceController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesInvoiceController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [SalesInvoiceController] API Request: GET /api/sales/invoices?$query',
      );

      final response = await _api.get(
        '/api/sales/invoices?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [SalesInvoiceController] Data length: ${list.length}');

        invoices.value = list
            .map(
              (e) => SalesInvoiceModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['kpi'] != null) {
          stats.value = InvoiceStats.fromJson(
            Map<String, dynamic>.from(response.data['kpi']),
          );
          print('🔵 [SalesInvoiceController] Stats: ${stats.value}');
        }

        if (response.data['stats'] != null) {
          monthlyStats.value = Map<String, dynamic>.from(
            response.data['stats'],
          );
          print(
            '🔵 [SalesInvoiceController] Monthly stats: ${monthlyStats.value}',
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
            '✅ [SalesInvoiceController] Invoices fetched successfully: ${invoices.length} invoices',
          );
          print(
            '✅ [SalesInvoiceController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [SalesInvoiceController] Failed to fetch invoices');
        print('❌ [SalesInvoiceController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load invoices');
      }
    } catch (e) {
      print('❌ [SalesInvoiceController] fetchInvoices error: $e');
      print('❌ [SalesInvoiceController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [SalesInvoiceController] fetchInvoices completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [SalesInvoiceController] applyLocalFilters called');
    print(
      '🟣 [SalesInvoiceController] Selected filter: ${selectedFilter.value}',
    );
    print('🟣 [SalesInvoiceController] Search filter: ${searchFilter.value}');

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
            item.customerName.toLowerCase().contains(query) ||
            item.customerEmail?.toLowerCase().contains(query) == true ||
            item.orderNumber?.toLowerCase().contains(query) == true;
        if (!matches) return false;
      }
      return true;
    }).toList();

    print(
      '🟣 [SalesInvoiceController] Filtered invoices: ${filtered.length} out of ${list.length}',
    );
    filteredInvoices.value = filtered;
  }

  void filterInvoices(String filter) {
    print('🟣 [SalesInvoiceController] filterInvoices called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchInvoices(String query) {
    print('🟣 [SalesInvoiceController] searchInvoices called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [SalesInvoiceController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchInvoices(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreInvoices() async {
    print('🟡 [SalesInvoiceController] fetchMoreInvoices called');
    print(
      '🟡 [SalesInvoiceController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [SalesInvoiceController] Skipping load more');
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [SalesInvoiceController] Loading page: ${currentPage.value}');

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
        '🟡 [SalesInvoiceController] API Request: GET /api/sales/invoices?$query',
      );

      final response = await _api.get(
        '/api/sales/invoices?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newInvoices = list
            .map(
              (e) => SalesInvoiceModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        print(
          '🟡 [SalesInvoiceController] Loaded ${newInvoices.length} more invoices',
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
          '🟡 [SalesInvoiceController] Total invoices now: ${invoices.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [SalesInvoiceController] Failed to load more invoices');
      }
    } catch (e) {
      print('❌ [SalesInvoiceController] fetchMoreInvoices error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [SalesInvoiceController] fetchMoreInvoices completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshInvoices() {
    print('🟢 [SalesInvoiceController] refreshInvoices called');
    return fetchInvoices(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [SalesInvoiceController] applyFilters called');
    fetchInvoices(resetPage: true);
  }

  void goToPage(int page) {
    print('🟣 [SalesInvoiceController] goToPage called: $page');
    if (page < 1 || page > totalPages.value) {
      print(
        '🟣 [SalesInvoiceController] Invalid page: $page, totalPages: ${totalPages.value}',
      );
      return;
    }
    currentPage.value = page;
    fetchInvoices();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [SalesInvoiceController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    searchOrders('');
    print(
      '🟢 [SalesInvoiceController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void closeCreateWizard() {
    print('🟢 [SalesInvoiceController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print(
      '🟢 [SalesInvoiceController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void _resetWizard() {
    print('🟢 [SalesInvoiceController] _resetWizard called');
    wizardStep.value = 0;
    selectedOrder.value = null;
    orderSearchResults.clear();
    lineDrafts.clear();
    orderSearchController.clear();
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
    print('✅ [SalesInvoiceController] Wizard reset complete');
  }

  // ─── ORDER SEARCH ─────────────────────────────────────────────

  Future<void> searchOrders(String query) async {
    print('🔵 [SalesInvoiceController] searchOrders called with: "$query"');

    try {
      isSearchingOrders.value = true;
      final params = <String, String>{'limit': '15'};
      if (query.trim().length >= 2) {
        params['search'] = query.trim();
      }
      final qs = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [SalesInvoiceController] API Request: GET /api/sales/invoices/available-orders?$qs',
      );

      final response = await _api.get(
        '/api/sales/invoices/available-orders?$qs',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '🔵 [SalesInvoiceController] Found ${orderSearchResults.length} orders for query: $query',
        );
      } else {
        print('❌ [SalesInvoiceController] No orders found');
        orderSearchResults.clear();
      }
    } catch (e) {
      print('❌ [SalesInvoiceController] searchOrders error: $e');
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
      print('🔵 [SalesInvoiceController] searchOrders completed');
    }
  }

  void selectOrderForInvoice(Map<String, dynamic> order) {
    print('🔵 [SalesInvoiceController] selectOrderForInvoice called');
    print(
      '🔵 [SalesInvoiceController] Selected order: ${order['orderNumber']} - ${order['customerName']}',
    );

    selectedOrder.value = order;
    orderSearchResults.clear();
    orderSearchController.text = order['orderNumber'] ?? '';

    // Create line drafts from order items
    final items = order['items'] as List? ?? [];
    double toD(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int toI(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    lineDrafts.value = items.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      return InvoiceLineDraft(
        productId: item['productId']?.toString() ?? '',
        productName: item['productName']?.toString() ??
            item['product']?['name']?.toString() ??
            '',
        sku: item['sku']?.toString() ?? '',
        quantity: toI(item['quantity']).clamp(1, 999999),
        unitPrice: toD(item['unitPrice']),
        discount: toD(item['discount']),
        taxRate: toD(item['taxRate']),
      );
    }).toList();

    print(
      '🔵 [SalesInvoiceController] Created ${lineDrafts.length} line drafts for order',
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
    final canGo = selectedOrder.value != null;
    print('🔵 [SalesInvoiceController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.isNotEmpty;
    print('🔵 [SalesInvoiceController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print(
      '🟡 [SalesInvoiceController] nextStep called, current step: ${wizardStep.value}',
    );

    if (wizardStep.value == 0 && !canGoToStep2()) {
      print(
        '❌ [SalesInvoiceController] Cannot go to step 2 - no order selected',
      );
      Get.snackbar('Validation', 'Select an order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print('❌ [SalesInvoiceController] Cannot go to step 3 - no items added');
      Get.snackbar('Validation', 'Add at least one item to the invoice');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print('🟡 [SalesInvoiceController] Step changed to: ${wizardStep.value}');
    }
  }

  void previousStep() {
    print(
      '🟡 [SalesInvoiceController] previousStep called, current step: ${wizardStep.value}',
    );
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print('🟡 [SalesInvoiceController] Step changed to: ${wizardStep.value}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE INVOICE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createInvoice() async {
    print('🔵 [SalesInvoiceController] createInvoice called');

    final order = selectedOrder.value;
    if (order == null) {
      print('❌ [SalesInvoiceController] No order selected');
      return false;
    }

    if (lineDrafts.isEmpty) {
      print('❌ [SalesInvoiceController] No items in invoice');
      Get.snackbar('Validation', 'Add at least one item');
      return false;
    }

    final invoiceDate = selectedInvoiceDate.value;
    final dueDate = selectedDueDate.value;

    if (invoiceDate == null || dueDate == null) {
      print('❌ [SalesInvoiceController] Dates not selected');
      Get.snackbar('Validation', 'Please select dates');
      return false;
    }

    try {
      isSubmitting.value = true;

      final items = lineDrafts
          .map(
            (line) => ({
              'productId': line.productId,
              'quantity': line.quantity,
              'unitPrice': line.unitPrice,
              'discount': line.discount,
              'taxRate': line.taxRate,
              'notes': null,
            }),
          )
          .toList();

      final payload = {
        'orderId': order['id'],
        'dueDate': dueDate.toIso8601String().split('T').first,
        'paymentTerms': paymentTermsController.text.trim().isEmpty
            ? 'Net 30'
            : paymentTermsController.text.trim(),
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      };

      print('🔵 [SalesInvoiceController] Submitting invoice payload');
      print(
        '🔵 [SalesInvoiceController] Order: ${order['orderNumber']}, Items: ${items.length}',
      );

      final response = await _api.post(
        '/api/sales/invoices/from-order',
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesInvoiceController] Invoice created successfully!');
        Get.snackbar('Success', 'Invoice created successfully');
        closeCreateWizard();
        await fetchInvoices(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesInvoiceController] Failed to create invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to create invoice');
      return false;
    } catch (e) {
      print('❌ [SalesInvoiceController] createInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INVOICE ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectInvoice(SalesInvoiceModel invoice) {
    print(
      '🔵 [SalesInvoiceController] selectInvoice called for: ${invoice.invoiceNumber}',
    );
    selectedInvoice.value = invoice;
  }

  Future<bool> postInvoice(String id) async {
    print('🟣 [SalesInvoiceController] postInvoice called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/sales/invoices/$id/post',
        body: {},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesInvoiceController] Invoice posted successfully');
        Get.snackbar(
          'Success',
          'Invoice posted and accounting entries created',
        );
        await fetchInvoices();
        return true;
      }

      print(
        '❌ [SalesInvoiceController] Failed to post invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to post invoice');
      return false;
    } catch (e) {
      print('❌ [SalesInvoiceController] postInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelInvoice(String id, {String? reason}) async {
    print('🟣 [SalesInvoiceController] cancelInvoice called for ID: $id');
    print('🟣 [SalesInvoiceController] Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/sales/invoices/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesInvoiceController] Invoice cancelled successfully');
        Get.snackbar('Success', 'Invoice cancelled');
        await fetchInvoices();
        return true;
      }

      print(
        '❌ [SalesInvoiceController] Failed to cancel invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to cancel invoice');
      return false;
    } catch (e) {
      print('❌ [SalesInvoiceController] cancelInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sendInvoice(String id, {String? email}) async {
    print('🟣 [SalesInvoiceController] sendInvoice called for ID: $id');
    print('🟣 [SalesInvoiceController] Email: $email');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/sales/invoices/$id/send',
        body: {'email': email ?? ''},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesInvoiceController] Invoice sent successfully');
        Get.snackbar('Success', 'Invoice sent successfully');
        await fetchInvoices();
        return true;
      }

      print(
        '❌ [SalesInvoiceController] Failed to send invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to send invoice');
      return false;
    } catch (e) {
      print('❌ [SalesInvoiceController] sendInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    print('🔵 [SalesInvoiceController] deleteInvoice called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/sales/invoices/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesInvoiceController] Invoice deleted successfully');
        Get.snackbar('Success', 'Invoice deleted successfully');
        await fetchInvoices(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesInvoiceController] Failed to delete invoice: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete invoice');
      return false;
    } catch (e) {
      print('❌ [SalesInvoiceController] deleteInvoice error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<SalesInvoiceModel?> getInvoiceById(String id) async {
    print('🔵 [SalesInvoiceController] getInvoiceById called for ID: $id');

    try {
      final response = await _api.get(
        '/api/sales/invoices/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesInvoiceController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesInvoiceController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final invoice = SalesInvoiceModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print(
          '✅ [SalesInvoiceController] Invoice found: ${invoice.invoiceNumber}',
        );
        return invoice;
      }
      print('❌ [SalesInvoiceController] Invoice not found');
      return null;
    } catch (e) {
      print('❌ [SalesInvoiceController] getInvoiceById error: $e');
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

  // ═══════════════════════════════════════════════════════════════
  // PDF GENERATION & SHARING
  // ═══════════════════════════════════════════════════════════════

  Future<void> generateAndDownloadPdf(SalesInvoiceModel invoice) async {
    print(
      '🟣 [SalesInvoiceController] generateAndDownloadPdf called for: ${invoice.invoiceNumber}',
    );

    try {
      isSubmitting.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _buildPdfHeader(invoice),
          footer: (ctx) => _buildPdfFooter(ctx),
          build: (ctx) => [_buildInvoiceContent(invoice)],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;

      Get.snackbar('Success', 'PDF generated successfully');
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;
      print('❌ [SalesInvoiceController] PDF generation error: $e');
      Get.snackbar('Error', 'Failed to generate PDF: $e');
    }
  }

  Future<void> shareInvoice(SalesInvoiceModel invoice) async {
    print(
      '🟣 [SalesInvoiceController] shareInvoice called for: ${invoice.invoiceNumber}',
    );

    try {
      isSubmitting.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _buildPdfHeader(invoice),
          footer: (ctx) => _buildPdfFooter(ctx),
          build: (ctx) => [_buildInvoiceContent(invoice)],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text:
            'Please find attached invoice ${invoice.invoiceNumber} for ${invoice.customerName}',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;
      print('❌ [SalesInvoiceController] Share error: $e');
      Get.snackbar('Error', 'Failed to share invoice: $e');
    }
  }

  Future<void> shareViaWhatsApp(SalesInvoiceModel invoice) async {
    print(
      '🟣 [SalesInvoiceController] shareViaWhatsApp called for: ${invoice.invoiceNumber}',
    );

    try {
      isSubmitting.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _buildPdfHeader(invoice),
          footer: (ctx) => _buildPdfFooter(ctx),
          build: (ctx) => [_buildInvoiceContent(invoice)],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;

      // WhatsApp sharing
      final message =
          'Invoice ${invoice.invoiceNumber} for ${invoice.customerName}. Amount: ${formatCurrency(invoice.grandTotal)}';
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );

        // Also share the file after opening WhatsApp
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Invoice ${invoice.invoiceNumber}',
          text: message,
        );
      } else {
        Get.snackbar('Error', 'WhatsApp not installed');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      isSubmitting.value = false;
      print('❌ [SalesInvoiceController] WhatsApp share error: $e');
      Get.snackbar('Error', 'Failed to share via WhatsApp: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PDF BUILDING METHODS
  // ═══════════════════════════════════════════════════════════════

  pw.Widget _buildPdfHeader(SalesInvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo800,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'BisonsTechs',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceContent(SalesInvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Invoice Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice Number:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Due Date:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(invoice.dueDate),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Status:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  invoice.invoiceStatus,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _getPdfStatusColor(invoice.invoiceStatus),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        // Customer Info
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 11)),
        if (invoice.customerEmail != null && invoice.customerEmail!.isNotEmpty)
          pw.Text(
            invoice.customerEmail!,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        pw.SizedBox(height: 16),
        // Items Table
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'Item',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Qty',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Price',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Invoice Items
        ...invoice.items.map((item) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.productName,
                        style: pw.TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                      if (item.sku.isNotEmpty)
                        pw.Text(
                          'SKU: ${item.sku}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    item.quantity.toString(),
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    formatCurrency(item.unitPrice),
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    formatCurrency(item.lineTotal),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 16),
        // Summary
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _summaryRow('Subtotal', formatCurrency(invoice.subtotal)),
              pw.SizedBox(height: 4),
              _summaryRow(
                'Discount',
                '-${formatCurrency(invoice.discountTotal)}',
              ),
              pw.SizedBox(height: 4),
              _summaryRow('Tax', formatCurrency(invoice.taxTotal)),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 1),
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 8),
                child: _summaryRow(
                  'Grand Total',
                  formatCurrency(invoice.grandTotal),
                  bold: true,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        // Payment Status
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: invoice.paymentStatus == 'Paid'
                ? PdfColors.green50
                : PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Payment Status:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                invoice.paymentStatus,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.paymentStatus == 'Paid'
                      ? PdfColors.green700
                      : PdfColors.orange700,
                ),
              ),
            ],
          ),
        ),
        if (invoice.paymentStatus != 'Paid' && invoice.outstanding > 0) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Outstanding: ${formatCurrency(invoice.outstanding)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return PdfColors.orange700;
      case 'Posted':
        return PdfColors.blue700;
      case 'Partially Paid':
        return PdfColors.purple700;
      case 'Paid':
        return PdfColors.green700;
      case 'Cancelled':
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// INVOICE LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class InvoiceLineDraft {
  String productId;
  String productName;
  String sku;
  int quantity;
  double unitPrice;
  double discount;
  double taxRate;

  InvoiceLineDraft({
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

// ═══════════════════════════════════════════════════════════════
// INVOICE STATS MODEL
// ═══════════════════════════════════════════════════════════════

class InvoiceStats {
  final int total;
  final int draft;
  final int posted;
  final int partiallyPaid;
  final int paid;
  final int cancelled;
  final double totalValue;
  final double outstanding;

  InvoiceStats({
    required this.total,
    required this.draft,
    required this.posted,
    required this.partiallyPaid,
    required this.paid,
    required this.cancelled,
    required this.totalValue,
    required this.outstanding,
  });

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      posted: (json['posted'] as num?)?.toInt() ?? 0,
      partiallyPaid: (json['partiallyPaid'] as num?)?.toInt() ?? 0,
      paid: (json['paid'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}
