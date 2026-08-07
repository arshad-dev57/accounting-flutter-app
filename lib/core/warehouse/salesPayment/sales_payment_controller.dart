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
    print('🟢 [SalesPaymentController] onInit called');
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedPaymentDate.value!);
    fetchPayments();
    fetchBankAccounts();
  }

  @override
  void onClose() {
    print('🟢 [SalesPaymentController] onClose called - disposing controllers');
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
    print('🔵 [SalesPaymentController] fetchPayments called');
    print(
      '🔵 [SalesPaymentController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [SalesPaymentController] Reset Page: $resetPage');

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
          '🔵 [SalesPaymentController] Search filter: ${searchFilter.value}',
        );
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesPaymentController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesPaymentController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [SalesPaymentController] API Request: GET /api/sales/payments?$query',
      );

      final response = await _api.get(
        '/api/sales/payments?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesPaymentController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesPaymentController] Response Success: ${response.success}',
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [SalesPaymentController] Data length: ${list.length}');

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
          print('🔵 [SalesPaymentController] Stats: ${stats.value}');
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
            '✅ [SalesPaymentController] Payments fetched successfully: ${payments.length} payments',
          );
          print(
            '✅ [SalesPaymentController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [SalesPaymentController] Failed to fetch payments');
        print('❌ [SalesPaymentController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load payments');
      }
    } catch (e) {
      print('❌ [SalesPaymentController] fetchPayments error: $e');
      print('❌ [SalesPaymentController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [SalesPaymentController] fetchPayments completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [SalesPaymentController] applyLocalFilters called');
    print(
      '🟣 [SalesPaymentController] Selected filter: ${selectedFilter.value}',
    );
    print('🟣 [SalesPaymentController] Search filter: ${searchFilter.value}');

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

    print(
      '🟣 [SalesPaymentController] Filtered payments: ${filtered.length} out of ${list.length}',
    );
    filteredPayments.value = filtered;
  }

  void filterPayments(String filter) {
    print('🟣 [SalesPaymentController] filterPayments called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchPayments(String query) {
    print('🟣 [SalesPaymentController] searchPayments called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [SalesPaymentController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchPayments(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMorePayments() async {
    print('🟡 [SalesPaymentController] fetchMorePayments called');
    print(
      '🟡 [SalesPaymentController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [SalesPaymentController] Skipping load more');
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [SalesPaymentController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🟡 [SalesPaymentController] API Request: GET /api/sales/payments?$query',
      );

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

        print(
          '🟡 [SalesPaymentController] Loaded ${newPayments.length} more payments',
        );
        payments.addAll(newPayments);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print(
          '🟡 [SalesPaymentController] Total payments now: ${payments.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [SalesPaymentController] Failed to load more payments');
      }
    } catch (e) {
      print('❌ [SalesPaymentController] fetchMorePayments error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [SalesPaymentController] fetchMorePayments completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshPayments() {
    print('🟢 [SalesPaymentController] refreshPayments called');
    return fetchPayments(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [SalesPaymentController] applyFilters called');
    fetchPayments(resetPage: true);
  }

  void openCreateForm() {
    print('🟢 [SalesPaymentController] openCreateForm called');
    _resetCreateForm();
    showCreateForm.value = true;
    print(
      '🟢 [SalesPaymentController] showCreateForm: ${showCreateForm.value}',
    );
  }

  void closeCreateForm() {
    print('🟢 [SalesPaymentController] closeCreateForm called');
    showCreateForm.value = false;
    _resetCreateForm();
    print(
      '🟢 [SalesPaymentController] showCreateForm: ${showCreateForm.value}',
    );
  }

  void _resetCreateForm() {
    print('🟢 [SalesPaymentController] _resetCreateForm called');
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
    print('✅ [SalesPaymentController] Create form reset complete');
  }

  // ─── CUSTOMER SEARCH ──────────────────────────────────────

  Future<void> searchCustomers(String query) async {
    print('🔵 [SalesPaymentController] searchCustomers called with: "$query"');

    if (query.trim().length < 2) {
      print('🔵 [SalesPaymentController] Query too short, clearing results');
      customerSearchResults.clear();
      return;
    }

    try {
      isSearchingCustomers.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print(
        '🔵 [SalesPaymentController] API Request: GET /api/warehouse/customers?search=$encoded&limit=10',
      );

      final response = await _api.get(
        '/api/warehouse/customers?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        customerSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '🔵 [SalesPaymentController] Found ${customerSearchResults.length} customers for query: $query',
        );
      } else {
        print('❌ [SalesPaymentController] No customers found');
        customerSearchResults.clear();
      }
    } catch (e) {
      print('❌ [SalesPaymentController] searchCustomers error: $e');
      customerSearchResults.clear();
    } finally {
      isSearchingCustomers.value = false;
      print('🔵 [SalesPaymentController] searchCustomers completed');
    }
  }

  void selectCustomer(Map<String, dynamic> customer) {
    print('🔵 [SalesPaymentController] selectCustomer called');
    print('🔵 [SalesPaymentController] Selected customer: ${customer['name']}');

    selectedCustomer.value = customer;
    customerSearchResults.clear();
    customerSearchController.text = customer['name'] ?? '';

    // Fetch invoices for this customer
    fetchCustomerInvoices(customer['id']);
  }

  // ─── CUSTOMER INVOICES ──────────────────────────────────────

  Future<void> fetchCustomerInvoices(String customerId) async {
    print(
      '🔵 [SalesPaymentController] fetchCustomerInvoices called for customer: $customerId',
    );

    try {
      isLoadingInvoices.value = true;
      print(
        '🔵 [SalesPaymentController] API Request: GET /api/sales/payments/customer/$customerId/invoices',
      );

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

        print(
          '🔵 [SalesPaymentController] Found ${availableInvoices.length} invoices for customer',
        );
      } else {
        print('❌ [SalesPaymentController] No invoices found');
        availableInvoices.clear();
        selectedInvoices.clear();
      }
    } catch (e) {
      print('❌ [SalesPaymentController] fetchCustomerInvoices error: $e');
      availableInvoices.clear();
      selectedInvoices.clear();
    } finally {
      isLoadingInvoices.value = false;
      print('🔵 [SalesPaymentController] fetchCustomerInvoices completed');
    }
  }

  void toggleInvoiceSelection(InvoiceForPayment invoice) {
    print('🔵 [SalesPaymentController] toggleInvoiceSelection called');

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

    print(
      '🔵 [SalesPaymentController] Selected invoices: ${selectedInvoices.length}',
    );
  }

  void updateInvoiceAmount(InvoiceForPayment invoice, double amount) {
    print('🔵 [SalesPaymentController] updateInvoiceAmount called');

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
    print('🔵 [SalesPaymentController] fetchBankAccounts called');

    try {
      final response = await _api.get('/api/bank-accounts', requiresAuth: true);

      if (response.success && response.data != null) {
        bankAccounts.value = List<Map<String, dynamic>>.from(
          response.data['data'],
        );
        print(
          '🔵 [SalesPaymentController] Found ${bankAccounts.length} bank accounts',
        );
      }
    } catch (e) {
      print('❌ [SalesPaymentController] fetchBankAccounts error: $e');
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
    print('🔵 [SalesPaymentController] receivePayment called');

    final customer = selectedCustomer.value;
    if (customer == null) {
      print('❌ [SalesPaymentController] No customer selected');
      Get.snackbar('Validation', 'Please select a customer');
      return false;
    }

    if (selectedInvoices.isEmpty) {
      print('❌ [SalesPaymentController] No invoices selected');
      Get.snackbar('Validation', 'Please select at least one invoice');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      print('❌ [SalesPaymentController] Invalid amount');
      Get.snackbar('Validation', 'Enter a valid payment amount');
      return false;
    }

    if (paymentMethod.value == 'Bank Transfer' &&
        selectedBankAccount.value == null) {
      print(
        '❌ [SalesPaymentController] No bank account selected for bank transfer',
      );
      Get.snackbar(
        'Validation',
        'Please select a bank account for bank transfer',
      );
      return false;
    }

    final paymentDate = selectedPaymentDate.value;
    if (paymentDate == null) {
      print('❌ [SalesPaymentController] No payment date selected');
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
        'bankAccountId': selectedBankAccount.value?['id'],
        'bankAccountName': selectedBankAccount.value?['accountName'] ?? '',
        'reference': referenceController.text.trim(),
        'notes': notesController.text.trim(),
        'invoicePayments': invoicePayments,
      };

      print('🔵 [SalesPaymentController] Submitting payment payload');
      print(
        '🔵 [SalesPaymentController] Customer: ${customer['name']}, Amount: $amount, Invoices: ${invoicePayments.length}',
      );

      final response = await _api.post(
        '/api/sales/payments/receive',
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesPaymentController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesPaymentController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesPaymentController] Payment received successfully!');
        Get.snackbar('Success', 'Payment received successfully');
        closeCreateForm();
        await fetchPayments(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesPaymentController] Failed to receive payment: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to receive payment');
      return false;
    } catch (e) {
      print('❌ [SalesPaymentController] receivePayment error: $e');
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
    print(
      '🔵 [SalesPaymentController] selectPayment called for: ${payment.paymentNumber}',
    );
    selectedPayment.value = payment;
  }

  Future<bool> cancelPayment(String id, {String? reason}) async {
    print('🟣 [SalesPaymentController] cancelPayment called for ID: $id');
    print('🟣 [SalesPaymentController] Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/sales/payments/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesPaymentController] Response Status: ${response.statusCode}',
      );
      print(
        '🟣 [SalesPaymentController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesPaymentController] Payment cancelled successfully');
        Get.snackbar('Success', 'Payment cancelled successfully');
        await fetchPayments();
        return true;
      }

      print(
        '❌ [SalesPaymentController] Failed to cancel payment: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to cancel payment');
      return false;
    } catch (e) {
      print('❌ [SalesPaymentController] cancelPayment error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deletePayment(String id) async {
    print('🔵 [SalesPaymentController] deletePayment called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/sales/payments/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesPaymentController] Response Status: ${response.statusCode}',
      );
      print(
        '🔵 [SalesPaymentController] Response Success: ${response.success}',
      );

      if (response.success) {
        print('✅ [SalesPaymentController] Payment deleted successfully');
        Get.snackbar('Success', 'Payment deleted successfully');
        await fetchPayments(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesPaymentController] Failed to delete payment: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete payment');
      return false;
    } catch (e) {
      print('❌ [SalesPaymentController] deletePayment error: $e');
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
