// lib/core/warehouse/purchase_payment/controller/purchase_payment_controller.dart

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/purchasePaymentmade/purchase_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchasePaymentController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<PurchasePaymentModel> payments = <PurchasePaymentModel>[].obs;
  final RxList<PurchasePaymentModel> filteredPayments = <PurchasePaymentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<PurchasePaymentModel?> selectedPayment = Rx<PurchasePaymentModel?>(null);

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

  final List<String> filters = ['all', 'Completed', 'Pending', 'Failed', 'Cancelled'];

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
    'Other'
  ];

  // ─── CREATE FORM STATE ──────────────────────────────────────
  final Rx<Map<String, dynamic>?> selectedSupplier = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> supplierSearchResults = <Map<String, dynamic>>[].obs;
  final RxBool isSearchingSuppliers = false.obs;
  final RxList<PurchaseInvoiceForPayment> availableInvoices = <PurchaseInvoiceForPayment>[].obs;
  final RxList<PurchaseInvoiceForPayment> selectedInvoices = <PurchaseInvoiceForPayment>[].obs;
  final RxBool isLoadingInvoices = false.obs;
  
  // ─── CONTROLLERS ─────────────────────────────────────────────
  final supplierSearchController = TextEditingController();
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  final paymentDateController = TextEditingController();
  
  // ─── SELECTED VALUES ─────────────────────────────────────────
  final RxString paymentMethod = 'Cash'.obs;
  final Rx<Map<String, dynamic>?> selectedBankAccount = Rx<Map<String, dynamic>?>(null);
  final Rx<DateTime?> selectedPaymentDate = Rx<DateTime?>(null);
  final RxList<Map<String, dynamic>> bankAccounts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('🟢 [PurchasePaymentController] onInit called');
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat('dd MMM yyyy').format(selectedPaymentDate.value!);
    fetchPayments();
    fetchBankAccounts();
  }

  @override
  void onClose() {
    print('🟢 [PurchasePaymentController] onClose called - disposing controllers');
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
      print('❌ [PurchasePaymentController] No supplier selected');
      return false;
    }
    if (selectedInvoices.isEmpty) {
      print('❌ [PurchasePaymentController] No invoices selected');
      return false;
    }
    if (selectedTotalAmount <= 0) {
      print('❌ [PurchasePaymentController] Total amount is 0 or negative');
      return false;
    }
    
    // Check bank account for non-cash payments
    if (paymentMethod.value != 'Cash' && selectedBankAccount.value == null) {
      print('❌ [PurchasePaymentController] No bank account selected for ${paymentMethod.value}');
      return false;
    }
    
    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH PAYMENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchPayments({bool resetPage = false}) async {
    print('🔵 [PurchasePaymentController] fetchPayments called');
    print('🔵 [PurchasePaymentController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}');
    print('🔵 [PurchasePaymentController] Reset Page: $resetPage');
    
    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print('🔵 [PurchasePaymentController] Search filter: ${searchFilter.value}');
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [PurchasePaymentController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [PurchasePaymentController] To date: ${params['toDate']}');
      }

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🔵 [PurchasePaymentController] API Request: GET /api/purchase/payments?$query');

      final response = await _api.get('/api/purchase/payments?$query', requiresAuth: true);

      print('🔵 [PurchasePaymentController] Response Status: ${response.statusCode}');
      print('🔵 [PurchasePaymentController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [PurchasePaymentController] Data length: ${list.length}');
        
        payments.value = list
            .map((e) => PurchasePaymentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = PurchasePaymentStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
          print('🔵 [PurchasePaymentController] Stats: ${stats.value}');
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
          
          print('✅ [PurchasePaymentController] Payments fetched successfully: ${payments.length} payments');
          print('✅ [PurchasePaymentController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}');
        }
      } else {
        print('❌ [PurchasePaymentController] Failed to fetch payments');
        print('❌ [PurchasePaymentController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load payments');
      }
    } catch (e) {
      print('❌ [PurchasePaymentController] fetchPayments error: $e');
      print('❌ [PurchasePaymentController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print('🔵 [PurchasePaymentController] fetchPayments completed, isLoading: ${isLoading.value}');
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [PurchasePaymentController] applyLocalFilters called');
    print('🟣 [PurchasePaymentController] Selected filter: ${selectedFilter.value}');
    print('🟣 [PurchasePaymentController] Search filter: ${searchFilter.value}');
    
    final list = payments.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' && item.status != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches = item.paymentNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.reference.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
    
    print('🟣 [PurchasePaymentController] Filtered payments: ${filtered.length} out of ${list.length}');
    filteredPayments.value = filtered;
  }

  void filterPayments(String filter) {
    print('🟣 [PurchasePaymentController] filterPayments called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchPayments(String query) {
    print('🟣 [PurchasePaymentController] searchPayments called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [PurchasePaymentController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchPayments(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMorePayments() async {
    print('🟡 [PurchasePaymentController] fetchMorePayments called');
    print('🟡 [PurchasePaymentController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}');
    
    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [PurchasePaymentController] Skipping load more');
      return;
    }
    
    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [PurchasePaymentController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🟡 [PurchasePaymentController] API Request: GET /api/purchase/payments?$query');

      final response = await _api.get('/api/purchase/payments?$query', requiresAuth: true);

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newPayments = list
            .map((e) => PurchasePaymentModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        print('🟡 [PurchasePaymentController] Loaded ${newPayments.length} more payments');
        payments.addAll(newPayments);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print('🟡 [PurchasePaymentController] Total payments now: ${payments.length}, hasMore: ${hasMore.value}');
      } else {
        print('❌ [PurchasePaymentController] Failed to load more payments');
      }
    } catch (e) {
      print('❌ [PurchasePaymentController] fetchMorePayments error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [PurchasePaymentController] fetchMorePayments completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshPayments() {
    print('🟢 [PurchasePaymentController] refreshPayments called');
    return fetchPayments(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [PurchasePaymentController] applyFilters called');
    fetchPayments(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE FORM
  // ═══════════════════════════════════════════════════════════════

  void openCreateForm() {
    print('🟢 [PurchasePaymentController] openCreateForm called');
    _resetCreateForm();
    showCreateForm.value = true;
    print('🟢 [PurchasePaymentController] showCreateForm: ${showCreateForm.value}');
  }

  void closeCreateForm() {
    print('🟢 [PurchasePaymentController] closeCreateForm called');
    showCreateForm.value = false;
    _resetCreateForm();
    print('🟢 [PurchasePaymentController] showCreateForm: ${showCreateForm.value}');
  }

  void _resetCreateForm() {
    print('🟢 [PurchasePaymentController] _resetCreateForm called');
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
    selectedPaymentDate.value = DateTime.now();
    paymentDateController.text = DateFormat('dd MMM yyyy').format(selectedPaymentDate.value!);
    print('✅ [PurchasePaymentController] Create form reset complete');
  }

  // ─── SUPPLIER SEARCH ──────────────────────────────────────────

  Future<void> searchSuppliers(String query) async {
    print('🔵 [PurchasePaymentController] searchSuppliers called with: "$query"');
    
    if (query.trim().length < 2) {
      print('🔵 [PurchasePaymentController] Query too short, clearing results');
      supplierSearchResults.clear();
      return;
    }
    
    try {
      isSearchingSuppliers.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      
      print('🔵 [PurchasePaymentController] API Request: GET /api/warehouse/supplier?search=$encoded&limit=10');
      
      final response = await _api.get(
        '/api/warehouse/supplier?search=$encoded&limit=10',
        requiresAuth: true,
      );
      
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        supplierSearchResults.value = list
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print('🔵 [PurchasePaymentController] Found ${supplierSearchResults.length} suppliers for query: $query');
      } else {
        print('❌ [PurchasePaymentController] No suppliers found');
        supplierSearchResults.clear();
      }
    } catch (e) {
      print('❌ [PurchasePaymentController] searchSuppliers error: $e');
      supplierSearchResults.clear();
    } finally {
      isSearchingSuppliers.value = false;
      print('🔵 [PurchasePaymentController] searchSuppliers completed');
    }
  }

  void selectSupplier(Map<String, dynamic> supplier) {
    print('🔵 [PurchasePaymentController] selectSupplier called');
    print('🔵 [PurchasePaymentController] Selected supplier: ${supplier['name']}');
    
    selectedSupplier.value = supplier;
    supplierSearchResults.clear();
    supplierSearchController.text = supplier['name'] ?? '';
    
    // Fetch invoices for this supplier
    fetchSupplierInvoices(supplier['id']);
  }

  // ─── SUPPLIER INVOICES ──────────────────────────────────────

  Future<void> fetchSupplierInvoices(String supplierId) async {
    print('🔵 [PurchasePaymentController] fetchSupplierInvoices called for supplier: $supplierId');
    
    try {
      isLoadingInvoices.value = true;
      print('🔵 [PurchasePaymentController] API Request: GET /api/purchase/payments/supplier/$supplierId/invoices');
      
      final response = await _api.get(
        '/api/purchase/payments/supplier/$supplierId/invoices',
        requiresAuth: true,
      );
      
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        availableInvoices.value = list
            .map((e) => PurchaseInvoiceForPayment.fromJson(Map<String, dynamic>.from(e)))
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
        
        print('🔵 [PurchasePaymentController] Found ${availableInvoices.length} invoices for supplier');
      } else {
        print('❌ [PurchasePaymentController] No invoices found');
        availableInvoices.clear();
        selectedInvoices.clear();
      }
    } catch (e) {
      print('❌ [PurchasePaymentController] fetchSupplierInvoices error: $e');
      availableInvoices.clear();
      selectedInvoices.clear();
    } finally {
      isLoadingInvoices.value = false;
      print('🔵 [PurchasePaymentController] fetchSupplierInvoices completed');
    }
  }

  // ─── INVOICE SELECTION ──────────────────────────────────────

  void toggleInvoiceSelection(PurchaseInvoiceForPayment invoice) {
    print('🔵 [PurchasePaymentController] toggleInvoiceSelection called');
    
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
    
    print('🔵 [PurchasePaymentController] Selected invoices: ${selectedInvoices.length}');
  }

  void updateInvoiceAmount(PurchaseInvoiceForPayment invoice, double amount) {
    print('🔵 [PurchasePaymentController] updateInvoiceAmount called');
    
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
    print('🔵 [PurchasePaymentController] fetchBankAccounts called');
    
    try {
      final response = await _api.get('/api/bank-accounts', requiresAuth: true);
      
      if (response.success && response.data != null) {
        final data = response.data['data'] as List? ?? [];
        bankAccounts.value = data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print('🔵 [PurchasePaymentController] Found ${bankAccounts.length} bank accounts');
        
        // Log the first account for debugging
        if (bankAccounts.isNotEmpty) {
          print('🔵 [PurchasePaymentController] First account: ${bankAccounts.first['accountName']} (ID: ${bankAccounts.first['id']})');
        }
      } else {
        print('❌ [PurchasePaymentController] Failed to fetch bank accounts');
      }
    } catch (e) {
      print('❌ [PurchasePaymentController] fetchBankAccounts error: $e');
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
    print('🔵 [PurchasePaymentController] makePayment called');
    
    final supplier = selectedSupplier.value;
    if (supplier == null) {
      print('❌ [PurchasePaymentController] No supplier selected');
      Get.snackbar('Validation', 'Please select a supplier');
      return false;
    }

    if (selectedInvoices.isEmpty) {
      print('❌ [PurchasePaymentController] No invoices selected');
      Get.snackbar('Validation', 'Please select at least one invoice');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      print('❌ [PurchasePaymentController] Invalid amount');
      Get.snackbar('Validation', 'Enter a valid payment amount');
      return false;
    }

    // ─── Check if payment method requires bank account ──────────
    final isBankTransfer = paymentMethod.value == 'Bank Transfer' || 
                           paymentMethod.value == 'Cheque' || 
                           paymentMethod.value == 'Online Payment';
    
    if (isBankTransfer) {
      if (selectedBankAccount.value == null) {
        print('❌ [PurchasePaymentController] No bank account selected for ${paymentMethod.value}');
        Get.snackbar('Validation', 'Please select a bank account for ${paymentMethod.value}');
        return false;
      }
      
      final bankId = selectedBankAccount.value?['id'];
      if (bankId == null || bankId.toString().isEmpty) {
        print('❌ [PurchasePaymentController] Bank account ID is null or empty');
        Get.snackbar('Validation', 'Invalid bank account selected');
        return false;
      }
      
      print('🔵 [PurchasePaymentController] Selected Bank Account ID: $bankId');
      print('🔵 [PurchasePaymentController] Selected Bank Account Name: ${selectedBankAccount.value?['accountName']}');
    }

    final paymentDate = selectedPaymentDate.value;
    if (paymentDate == null) {
      print('❌ [PurchasePaymentController] No payment date selected');
      Get.snackbar('Validation', 'Please select a payment date');
      return false;
    }

    try {
      isSubmitting.value = true;
      
      final invoicePayments = selectedInvoices.map((inv) => ({
        'invoiceId': inv.id,
        'invoiceNumber': inv.invoiceNumber,
        'amountPaid': inv.amountToPay,
      })).toList();

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
        payload['bankAccountName'] = selectedBankAccount.value?['accountName'] ?? 
                                      selectedBankAccount.value?['name'] ?? 
                                      'Bank Account';
      }

      print('🔵 [PurchasePaymentController] Submitting payment payload');
      print('🔵 [PurchasePaymentController] Supplier: ${supplier['name']}, Amount: $amount, Invoices: ${invoicePayments.length}');
      print('🔵 [PurchasePaymentController] Payment Method: ${paymentMethod.value}');
      print('🔵 [PurchasePaymentController] Bank Account ID: ${payload['bankAccountId'] ?? 'N/A'}');
      print('🔵 [PurchasePaymentController] Bank Account Name: ${payload['bankAccountName'] ?? 'N/A'}');

      final response = await _api.post(
        '/api/purchase/payments/make',
        body: payload,
        requiresAuth: true,
      );

      print('🔵 [PurchasePaymentController] Response Status: ${response.statusCode}');
      print('🔵 [PurchasePaymentController] Response Success: ${response.success}');
      print('🔵 [PurchasePaymentController] Response Message: ${response.message}');

      if (response.success) {
        print('✅ [PurchasePaymentController] Payment made successfully!');
        Get.snackbar('Success', 'Payment made successfully');
        closeCreateForm();
        await fetchPayments(resetPage: true);
        return true;
      }
      
      print('❌ [PurchasePaymentController] Failed to make payment: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to make payment');
      return false;
    } catch (e) {
      print('❌ [PurchasePaymentController] makePayment error: $e');
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
    print('🔵 [PurchasePaymentController] selectPayment called for: ${payment.paymentNumber}');
    selectedPayment.value = payment;
  }

  Future<bool> cancelPayment(String id, {String? reason}) async {
    print('🟣 [PurchasePaymentController] cancelPayment called for ID: $id');
    print('🟣 [PurchasePaymentController] Reason: $reason');
    
    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/payments/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print('🟣 [PurchasePaymentController] Response Status: ${response.statusCode}');
      print('🟣 [PurchasePaymentController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [PurchasePaymentController] Payment cancelled successfully');
        Get.snackbar('Success', 'Payment cancelled successfully');
        await fetchPayments();
        return true;
      }
      
      print('❌ [PurchasePaymentController] Failed to cancel payment: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to cancel payment');
      return false;
    } catch (e) {
      print('❌ [PurchasePaymentController] cancelPayment error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deletePayment(String id) async {
    print('🔵 [PurchasePaymentController] deletePayment called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/payments/$id',
        requiresAuth: true,
      );

      print('🔵 [PurchasePaymentController] Response Status: ${response.statusCode}');
      print('🔵 [PurchasePaymentController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [PurchasePaymentController] Payment deleted successfully');
        Get.snackbar('Success', 'Payment deleted successfully');
        await fetchPayments(resetPage: true);
        return true;
      }
      
      print('❌ [PurchasePaymentController] Failed to delete payment: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to delete payment');
      return false;
    } catch (e) {
      print('❌ [PurchasePaymentController] deletePayment error: $e');
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
    this.isSelected = false,
    this.amountToPay = 0,
  });

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && outstanding > 0;
  }

  factory PurchaseInvoiceForPayment.fromJson(Map<String, dynamic> json) {
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
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      invoiceStatus: json['invoiceStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      supplierInvoiceNo: json['supplierInvoiceNo'],
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