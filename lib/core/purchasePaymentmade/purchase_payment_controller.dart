// lib/core/warehouse/purchase_payment/controller/purchase_payment_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchasePaymentController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<PurchasePaymentModel> payments = <PurchasePaymentModel>[].obs;
  final RxList<PurchasePaymentModel> filteredPayments =
      <PurchasePaymentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<PurchasePaymentModel?> selectedPayment = Rx<PurchasePaymentModel?>(
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

  final List<String> filters = [
    'all',
    'Completed',
    'Pending',
    'Failed',
    'Cancelled',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<PurchasePaymentStats> stats = PurchasePaymentStats(
    todayCount: 0,
    todayAmount: 0,
    monthCount: 0,
    monthAmount: 0,
  ).obs;

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Credit Card',
    'Online Payment',
    'Other',
  ];

  // ─── CREATE FORM STATE ──────────────────────────────────────
  final Rx<Map<String, dynamic>?> selectedSupplier = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<Map<String, dynamic>> supplierSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingSuppliers = false.obs;
  final RxList<PurchaseInvoiceForPayment> availableInvoices =
      <PurchaseInvoiceForPayment>[].obs;
  final RxList<PurchaseInvoiceForPayment> selectedInvoices =
      <PurchaseInvoiceForPayment>[].obs;
  final RxBool isLoadingInvoices = false.obs;
  final RxBool lockSupplier = false.obs;
  final RxnString lockedInvoiceId = RxnString();

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final supplierSearchController = TextEditingController();
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  final paymentDateController = TextEditingController();

  // ─── SELECTED VALUES ─────────────────────────────────────────
  final RxString paymentMethod = 'Cash'.obs;
  final Rx<Map<String, dynamic>?> selectedBankAccount =
      Rx<Map<String, dynamic>?>(null);
  final Rx<DateTime?> selectedPaymentDate = Rx<DateTime?>(null);
  final RxList<Map<String, dynamic>> bankAccounts =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedPaymentDate.value!);
    fetchPayments();
    fetchBankAccounts();
  }

  @override
  void onClose() {
    supplierSearchController.dispose();
    amountController.dispose();
    referenceController.dispose();
    notesController.dispose();
    paymentDateController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  double get selectedTotalAmount {
    return selectedInvoices.fold(0.0, (sum, inv) => sum + inv.amountToPay);
  }

  double get totalOutstanding {
    return availableInvoices.fold(0.0, (sum, inv) => sum + inv.outstanding);
  }

  bool get canMakePayment {
    if (selectedSupplier.value == null) {
      return false;
    }
    if (selectedInvoices.isEmpty) {
      return false;
    }
    if (selectedTotalAmount <= 0) {
      return false;
    }

    // Check bank account for non-cash payments
    if (paymentMethod.value != 'Cash' && selectedBankAccount.value == null) {
      return false;
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH PAYMENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchPayments({bool resetPage = false}) async {

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

      final response = await _api.get(
        '/api/purchase/payments?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        payments.value = list
            .map(
              (e) =>
                  PurchasePaymentModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = PurchasePaymentStats.fromJson(
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

    final list = payments.toList();
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
            item.paymentNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.reference.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredPayments.value = filtered;
  }

  void filterPayments(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchPayments(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchPayments(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMorePayments() async {

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

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/purchase/payments?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newPayments = list
            .map(
              (e) =>
                  PurchasePaymentModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        payments.addAll(newPayments);
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

  Future<void> refreshPayments() {
    return fetchPayments(resetPage: true);
  }

  void applyFilters() {
    fetchPayments(resetPage: true);
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

  /// Prefill the purchase-payment form for one Purchase Invoice (AP Pay).
  Future<void> prepareForInvoicePayment({
    required String supplierId,
    required String supplierName,
    required String invoiceId,
  }) async {
    _resetCreateForm();
    lockSupplier.value = true;
    lockedInvoiceId.value = invoiceId;
    selectedSupplier.value = {'id': supplierId, 'name': supplierName};
    supplierSearchController.text = supplierName;
    showCreateForm.value = true;
    await fetchBankAccounts();
    await fetchSupplierInvoices(
      supplierId,
      selectOnlyInvoiceId: invoiceId,
    );
  }

  void _resetCreateForm() {
    selectedSupplier.value = null;
    supplierSearchResults.clear();
    supplierSearchController.clear();
    amountController.clear();
    referenceController.clear();
    notesController.clear();
    paymentMethod.value = 'Cash';
    selectedBankAccount.value = null;
    availableInvoices.clear();
    selectedInvoices.clear();
    lockSupplier.value = false;
    lockedInvoiceId.value = null;
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedPaymentDate.value!);
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

    // Fetch invoices for this supplier
    fetchSupplierInvoices(supplier['id']);
  }

  // ─── SUPPLIER INVOICES ──────────────────────────────────────

  Future<void> fetchSupplierInvoices(
    String supplierId, {
    String? selectOnlyInvoiceId,
  }) async {

    try {
      isLoadingInvoices.value = true;

      final response = await _api.get(
        '/api/purchase/payments/supplier/$supplierId/invoices',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        var invoices = list
            .map(
              (e) => PurchaseInvoiceForPayment.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .where((invoice) => invoice.outstanding > 0)
            .toList();

        if (selectOnlyInvoiceId != null) {
          invoices = invoices
              .where((invoice) => invoice.id == selectOnlyInvoiceId)
              .toList();
        }

        availableInvoices.value = invoices;

        selectedInvoices.clear();
        for (var invoice in availableInvoices) {
          if (!invoice.payable) continue;
          invoice.isSelected = true;
          invoice.amountToPay = invoice.outstanding;
          selectedInvoices.add(invoice);
        }

        amountController.text = selectedTotalAmount.toStringAsFixed(2);

       

        if (selectOnlyInvoiceId != null && selectedInvoices.isEmpty) {
          Get.snackbar(
            'Not Payable',
            'This purchase invoice is not posted or has no outstanding amount.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        } else if (availableInvoices.isNotEmpty && selectedInvoices.isEmpty) {
          Get.snackbar(
            'No Payable Invoices',
            'No unpaid posted invoices found for this supplier.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        availableInvoices.clear();
        selectedInvoices.clear();
      }
    } catch (e) {
      availableInvoices.clear();
      selectedInvoices.clear();
    } finally {
      isLoadingInvoices.value = false;
    }
  }

  // ─── INVOICE SELECTION ──────────────────────────────────────

  void toggleInvoiceSelection(PurchaseInvoiceForPayment invoice) {

    if (!invoice.payable) {
      Get.snackbar(
        'Post Invoice First',
        '${invoice.invoiceNumber} is still Draft. Post it in Purchase Invoices before paying.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final index = selectedInvoices.indexWhere((inv) => inv.id == invoice.id);
    if (index != -1) {
      selectedInvoices.removeAt(index);
      invoice.isSelected = false;
    } else {
      invoice.isSelected = true;
      invoice.amountToPay = invoice.outstanding;
      selectedInvoices.add(invoice);
    }

    // Update amount
    amountController.text = selectedTotalAmount.toStringAsFixed(2);

  }

  void updateInvoiceAmount(PurchaseInvoiceForPayment invoice, double amount) {

    if (amount > invoice.outstanding) {
      amount = invoice.outstanding;
    }
    if (amount < 0) {
      amount = 0;
    }

    invoice.amountToPay = amount;

    // Update total amount
    amountController.text = selectedTotalAmount.toStringAsFixed(2);
  }

  // ─── BANK ACCOUNTS ──────────────────────────────────────────

  Future<void> fetchBankAccounts() async {

    try {
      final response = await _api.get('/api/bank-accounts', requiresAuth: true);

      if (response.success && response.data != null) {
        final data = response.data['data'] as List? ?? [];
        bankAccounts.value = data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Log the first account for debugging
        if (bankAccounts.isNotEmpty) {
        }
      } else {
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ─── DATE SELECTION ──────────────────────────────────────────

  void selectPaymentDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedPaymentDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      selectedPaymentDate.value = date;
      paymentDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MAKE PAYMENT (FIXED)
  // ═══════════════════════════════════════════════════════════════

  Future<bool> makePayment() async {

    final supplier = selectedSupplier.value;
    if (supplier == null) {
      Get.snackbar('Validation', 'Please select a supplier');
      return false;
    }

    if (selectedInvoices.isEmpty) {
      Get.snackbar('Validation', 'Please select at least one invoice');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('Validation', 'Enter a valid payment amount');
      return false;
    }

    // ─── Check if payment method requires bank account ──────────
    final isBankTransfer =
        paymentMethod.value == 'Bank Transfer' ||
        paymentMethod.value == 'Cheque' ||
        paymentMethod.value == 'Online Payment';

    if (isBankTransfer) {
      if (selectedBankAccount.value == null) {
        Get.snackbar(
          'Validation',
          'Please select a bank account for ${paymentMethod.value}',
        );
        return false;
      }

      final bankId = selectedBankAccount.value?['id'];
      if (bankId == null || bankId.toString().isEmpty) {
        Get.snackbar('Validation', 'Invalid bank account selected');
        return false;
      }

    }

    final paymentDate = selectedPaymentDate.value;
    if (paymentDate == null) {
      Get.snackbar('Validation', 'Please select a payment date');
      return false;
    }

    try {
      isSubmitting.value = true;

      final invoicePayments = selectedInvoices
          .map(
            (inv) => ({
              'invoiceId': inv.id,
              'invoiceNumber': inv.invoiceNumber,
              'amountPaid': inv.amountToPay,
            }),
          )
          .toList();

      // ─── Build payload ──────────────────────────────────────────
      final payload = <String, dynamic>{
        'supplierId': supplier['id'],
        'supplierName': supplier['name'],
        'amount': amount,
        'paymentMethod': paymentMethod.value,
        'reference': referenceController.text.trim(),
        'notes': notesController.text.trim(),
        'invoicePayments': invoicePayments,
      };

      // ─── Add bank account only if needed ──────────────────────
      if (isBankTransfer) {
        payload['bankAccountId'] = selectedBankAccount.value?['id'];
        payload['bankAccountName'] =
            selectedBankAccount.value?['accountName'] ??
            selectedBankAccount.value?['name'] ??
            'Bank Account';
      }


      final response = await _api.post(
        '/api/purchase/payments/make',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Payment made successfully');
        closeCreateForm();
        await fetchPayments(resetPage: true);
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
  // PAYMENT ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectPayment(PurchasePaymentModel payment) {
    selectedPayment.value = payment;
  }

  Future<bool> cancelPayment(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/payments/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Payment cancelled successfully');
        await fetchPayments();
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

  Future<bool> deletePayment(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/payments/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Payment deleted successfully');
        await fetchPayments(resetPage: true);
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
  // HELPER: FORMAT CURRENCY
  // ═══════════════════════════════════════════════════════════════

  String formatCurrency(double amount) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(amount);
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE FOR PAYMENT MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceForPayment {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final String invoiceStatus;
  final String paymentStatus;
  final String? supplierInvoiceNo;
  final bool payable;
  bool isSelected;
  double amountToPay;

  PurchaseInvoiceForPayment({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.invoiceStatus,
    required this.paymentStatus,
    this.supplierInvoiceNo,
    this.payable = true,
    this.isSelected = false,
    this.amountToPay = 0,
  });

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && outstanding > 0;
  }

  bool get isDraft => invoiceStatus == 'Draft';

  factory PurchaseInvoiceForPayment.fromJson(Map<String, dynamic> json) {
    final status = json['invoiceStatus'] ?? '';
    final outstanding = (json['outstanding'] as num?)?.toDouble() ?? 0;
    final payableFlag = json['payable'];
    final payable = payableFlag is bool
        ? payableFlag
        : (status == 'Posted' || status == 'Partially Paid') && outstanding > 0;

    return PurchaseInvoiceForPayment(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      outstanding: outstanding,
      invoiceStatus: status,
      paymentStatus: json['paymentStatus'] ?? '',
      supplierInvoiceNo: json['supplierInvoiceNo'],
      payable: payable,
      isSelected: json['isSelected'] ?? false,
      amountToPay: (json['amountToPay'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE PAYMENT STATS MODEL
// ═══════════════════════════════════════════════════════════════

class PurchasePaymentStats {
  final int todayCount;
  final double todayAmount;
  final int monthCount;
  final double monthAmount;

  PurchasePaymentStats({
    required this.todayCount,
    required this.todayAmount,
    required this.monthCount,
    required this.monthAmount,
  });

  factory PurchasePaymentStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};

    return PurchasePaymentStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      todayAmount: (today['amount'] as num?)?.toDouble() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      monthAmount: (month['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
