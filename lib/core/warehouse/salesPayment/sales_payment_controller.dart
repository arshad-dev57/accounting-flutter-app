// lib/core/warehouse/sales_payment/controller/sales_payment_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesPayment/sales_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SalesPaymentController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxList<SalesPaymentModel> payments = <SalesPaymentModel>[].obs;
  final RxList<SalesPaymentModel> filteredPayments = <SalesPaymentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<SalesPaymentModel?> selectedPayment = Rx<SalesPaymentModel?>(null);

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
  final Rx<PaymentStats> stats = PaymentStats(
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
  final Rx<Map<String, dynamic>?> selectedCustomer = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<Map<String, dynamic>> customerSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingCustomers = false.obs;
  final RxList<InvoiceForPayment> availableInvoices = <InvoiceForPayment>[].obs;
  final RxList<InvoiceForPayment> selectedInvoices = <InvoiceForPayment>[].obs;
  final RxBool isLoadingInvoices = false.obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final customerSearchController = TextEditingController();
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
    customerSearchController.dispose();
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

  bool get canReceivePayment {
    return selectedCustomer.value != null &&
        selectedInvoices.isNotEmpty &&
        selectedTotalAmount > 0;
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
        '/api/sales/payments?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        payments.value = list
            .map(
              (e) => SalesPaymentModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = PaymentStats.fromJson(
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
            item.customerName.toLowerCase().contains(query) ||
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
        '/api/sales/payments?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newPayments = list
            .map(
              (e) => SalesPaymentModel.fromJson(Map<String, dynamic>.from(e)),
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

  void openCreateForm() {
    _resetCreateForm();
    showCreateForm.value = true;
  }

  void closeCreateForm() {
    showCreateForm.value = false;
    _resetCreateForm();
  }

  void _resetCreateForm() {
    selectedCustomer.value = null;
    customerSearchResults.clear();
    customerSearchController.clear();
    amountController.clear();
    referenceController.clear();
    notesController.clear();
    paymentMethod.value = 'Cash';
    selectedBankAccount.value = null;
    availableInvoices.clear();
    selectedInvoices.clear();
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedPaymentDate.value!);
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
        '/api/warehouse/customers?search=$encoded&limit=10',
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

    // Fetch invoices for this customer
    fetchCustomerInvoices(customer['id']);
  }

  // ─── CUSTOMER INVOICES ──────────────────────────────────────

  Future<void> fetchCustomerInvoices(String customerId) async {

    try {
      isLoadingInvoices.value = true;

      final response = await _api.get(
        '/api/sales/payments/customer/$customerId/invoices',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        availableInvoices.value = list
            .map(
              (e) => InvoiceForPayment.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        // Auto-select all invoices
        selectedInvoices.clear();
        for (var invoice in availableInvoices) {
          invoice.isSelected = true;
          invoice.amountToPay = invoice.outstanding;
          selectedInvoices.add(invoice);
        }

        // Update amount
        amountController.text = selectedTotalAmount.toStringAsFixed(2);

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

  void toggleInvoiceSelection(InvoiceForPayment invoice) {

    final index = selectedInvoices.indexWhere((inv) => inv.id == invoice.id);
    if (index != -1) {
      selectedInvoices.removeAt(index);
    } else {
      invoice.isSelected = true;
      invoice.amountToPay = invoice.outstanding;
      selectedInvoices.add(invoice);
    }

    // Update amount
    amountController.text = selectedTotalAmount.toStringAsFixed(2);

  }

  void updateInvoiceAmount(InvoiceForPayment invoice, double amount) {

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
        bankAccounts.value = List<Map<String, dynamic>>.from(
          response.data['data'],
        );
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
  // RECEIVE PAYMENT
  // ═══════════════════════════════════════════════════════════════

  Future<bool> receivePayment() async {

    final customer = selectedCustomer.value;
    if (customer == null) {
      Get.snackbar('Validation', 'Please select a customer');
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

    final method = paymentMethod.value;
    final needsBank =
        method == 'Bank Transfer' || method == 'Cheque';
    if (needsBank && selectedBankAccount.value == null) {
      Get.snackbar('Validation', 'Please select a bank account');
      return false;
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

      final payload = {
        'customerId': customer['id'],
        'customerName': customer['name'],
        'amount': amount,
        'paymentMethod': paymentMethod.value,
        'reference': referenceController.text.trim(),
        'notes': notesController.text.trim(),
        'invoicePayments': invoicePayments,
      };

      // Bank GL only when the user actually picked a bank (never for Cash)
      final bank = selectedBankAccount.value;
      if (method != 'Cash' && bank != null && bank['id'] != null) {
        payload['bankAccountId'] = bank['id'];
        payload['bankAccountName'] = bank['accountName'] ?? '';
      }


      final response = await _api.post(
        '/api/sales/payments/receive',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Payment received successfully');
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

  void selectPayment(SalesPaymentModel payment) {
    selectedPayment.value = payment;
  }

  Future<bool> cancelPayment(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/sales/payments/$id/cancel',
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
        '/api/sales/payments/$id',
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
// INVOICE FOR PAYMENT MODEL
// ═══════════════════════════════════════════════════════════════

class InvoiceForPayment {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final String invoiceStatus;
  final String paymentStatus;
  bool isSelected;
  double amountToPay;

  InvoiceForPayment({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.invoiceStatus,
    required this.paymentStatus,
    this.isSelected = false,
    this.amountToPay = 0,
  });

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && outstanding > 0;
  }

  factory InvoiceForPayment.fromJson(Map<String, dynamic> json) {
    return InvoiceForPayment(
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
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      invoiceStatus: json['invoiceStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      isSelected: json['isSelected'] ?? false,
      amountToPay: (json['amountToPay'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT STATS MODEL
// ═══════════════════════════════════════════════════════════════

class PaymentStats {
  final int todayCount;
  final double todayAmount;
  final int monthCount;
  final double monthAmount;

  PaymentStats({
    required this.todayCount,
    required this.todayAmount,
    required this.monthCount,
    required this.monthAmount,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};

    return PaymentStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      todayAmount: (today['amount'] as num?)?.toDouble() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      monthAmount: (month['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
