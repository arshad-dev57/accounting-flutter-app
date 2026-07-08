// core/paymentsMade/controller/payment_made_controller.dart
import 'dart:async';

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentMadeController extends GetxController {
  // Observable variables
  var payments = <PaymentMade>[].obs;
  var allPayments = <PaymentMade>[].obs;
  var suppliers = <SupplierForPayment>[].obs;
  var bankAccounts = <BankAccount>[].obs;
  var unpaidBills = <BillForPayment>[].obs;
  
  var isLoading = false.obs;
  var isRecording = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;
  
  // Multi-bill selection
  var selectedBillIds = <String>[].obs;
  var totalSelectedOutstanding = 0.0.obs;
  var totalSelectedAmount = 0.0.obs;
  
  // Summary data
  var totalPaid = 0.0.obs;
  var thisMonthTotal = 0.0.obs;
  var thisWeekTotal = 0.0.obs;
  var todayTotal = 0.0.obs;
  var pendingCount = 0.obs;
  
  // Loading states
  var isLoadingBills = false.obs;
  var currentSupplierId = ''.obs;
  var currentBills = <BillForPayment>[].obs;
  
  // Filter options
  final List<String> filterOptions = [
    'All', 
    'Today', 
    'This Week', 
    'This Month', 
    'Custom Range'
  ];
  
  final TextEditingController searchController = TextEditingController();
  final ApiClient _api = Get.find<ApiClient>();
  
  // Debounce for search
  Timer? _debounceTimer;
  
  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadPayments();
    loadSuppliers();
    loadBankAccounts();
    loadSummary();
  }
  
  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
  
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = searchController.text;
      _applySearchFilter();
    });
  }
  
  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      payments.value = allPayments.value;
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      final results = allPayments.where((payment) {
        return payment.paymentNumber.toLowerCase().contains(searchLower) ||
               payment.supplierName.toLowerCase().contains(searchLower) ||
               payment.billNumber.toLowerCase().contains(searchLower) ||
               payment.paymentMethod.toLowerCase().contains(searchLower) ||
               payment.reference.toLowerCase().contains(searchLower);
      }).toList();
      payments.value = results;
    }
    _updateSummaryForFiltered(payments.value);
  }
  
  void _updateSummaryForFiltered(List<PaymentMade> filteredPayments) {
    totalPaid.value = filteredPayments.fold(0.0, (sum, p) => sum + p.amount);
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    
    todayTotal.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(todayStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, p) => sum + p.amount);
        
    thisWeekTotal.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(thisWeekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, p) => sum + p.amount);
        
    thisMonthTotal.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(thisMonthStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, p) => sum + p.amount);
  }
  
  String formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }
  
  // ─── LOAD PAYMENTS ──────────────────────────────────────────────────
  Future<void> loadPayments() async {
    try {
      isLoading.value = true;
      
      Map<String, dynamic> params = {};
      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end);
      }
      
      final response = await _api.get('/api/payments-made', queryParameters: params.isNotEmpty ? params : null);
      
      if (response.success) {
        List<dynamic> paymentsData = response.data['data'] ?? [];
        final newPayments = paymentsData.map((json) => PaymentMade.fromJson(json)).toList();
        allPayments.value = newPayments;
        _applySearchFilter();
      } else {
        _showError('Failed to load payments');
      }
    } catch (e) {
      _showError('Error loading payments: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // ─── LOAD SUPPLIERS ──────────────────────────────────────────────
  Future<void> loadSuppliers() async {
    try {
      final response = await _api.get('/api/warehouse/supplier');
      if (response.success) {
        List<dynamic> suppliersData = response.data['data'] ?? [];
        suppliers.value = suppliersData.map((json) => SupplierForPayment.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }
  
  // ─── LOAD BANK ACCOUNTS ──────────────────────────────────────────
  Future<void> loadBankAccounts() async {
    try {
      final response = await _api.get('/api/bank-accounts');
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          bankAccounts.value = (data['data'] as List)
              .map((e) => BankAccount.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
  }
  
  // ─── LOAD SUMMARY ──────────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      Map<String, dynamic> params = {};
      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end);
      }
      
      final response = await _api.get(
        '/api/payments-made/summary',
        queryParameters: params.isNotEmpty ? params : null,
      );
      
      if (response.success) {
        final data = response.data['data'] ?? {};
        totalPaid.value = (data['totalPaid'] ?? 0).toDouble();
        thisWeekTotal.value = (data['thisWeek'] ?? 0).toDouble();
        thisMonthTotal.value = (data['thisMonth'] ?? 0).toDouble();
        todayTotal.value = (data['today'] ?? 0).toDouble();
        pendingCount.value = data['pending'] ?? 0;
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
  }
  
  // ─── GET UNPAID BILLS ──────────────────────────────────────────────
  Future<List<BillForPayment>> getUnpaidBills(String supplierId) async {
    if (supplierId.isEmpty) return [];
    
    try {
      currentSupplierId.value = supplierId;
      isLoadingBills.value = true;
      clearBillSelections();
      
      final response = await _api.get('/api/payments-made/bills/unpaid/$supplierId');
      
      if (response.success) {
        List<dynamic> billsData = response.data['data'] ?? [];
        if (billsData.isEmpty) {
          AppSnackbar.info('Info', 'No unpaid bills found for this supplier');
          currentBills.value = [];
          return [];
        }
        final bills = billsData.map((json) => BillForPayment.fromJson(json)).toList();
        currentBills.value = bills;
        return bills;
      } else {
        _showError(response.message.isNotEmpty ? response.message : 'Failed to load bills');
        return [];
      }
    } catch (e) {
      _showError('Error loading bills: $e');
      return [];
    } finally {
      isLoadingBills.value = false;
    }
  }
  
  // ─── TOGGLE BILL SELECTION ────────────────────────────────────────
  void toggleBillSelection(String billId, double outstanding) {
    if (selectedBillIds.contains(billId)) {
      selectedBillIds.remove(billId);
      totalSelectedOutstanding.value -= outstanding;
    } else {
      selectedBillIds.add(billId);
      totalSelectedOutstanding.value += outstanding;
    }
    totalSelectedAmount.value = totalSelectedOutstanding.value;
  }
  
  // ─── CLEAR BILL SELECTIONS ────────────────────────────────────────
  void clearBillSelections() {
    selectedBillIds.clear();
    totalSelectedOutstanding.value = 0;
    totalSelectedAmount.value = 0;
  }
  
  // ─── RECORD PAYMENT ──────────────────────────────────────────────────
  Future<void> recordPayment({
    required String supplierId,
    required List<String> billIds,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? reference,
    String? bankAccountId,
    String? notes,
  }) async {
    if (billIds.isEmpty) {
      _showError('Please select at least one bill');
      return;
    }
    
    if (amount <= 0) {
      _showError('Please enter a valid payment amount');
      return;
    }
    
    if (paymentMethod == 'Bank Transfer' && (bankAccountId == null || bankAccountId.isEmpty)) {
      _showError('Please select a bank account');
      return;
    }
    
    try {
      isRecording.value = true;
      
      final Map<String, dynamic> paymentData = {
        'supplierId': supplierId,
        'billIds': billIds,
        'amount': amount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'paymentMethod': paymentMethod,
        'reference': reference ?? '',
        'notes': notes ?? '',
      };
      
      if (bankAccountId != null && bankAccountId.isNotEmpty && paymentMethod == 'Bank Transfer') {
        paymentData['bankAccountId'] = bankAccountId;
      }
      
      final response = await _api.post('/api/payments-made', body: paymentData);
      
      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Payment recorded successfully\nJournal entry created');
        clearBillSelections();
        await loadPayments();
        await loadSummary();
        if (supplierId.isNotEmpty) {
          await getUnpaidBills(supplierId);
        }
      } else {
        _showError(response.message.isNotEmpty ? response.message : 'Failed to record payment');
      }
    } catch (e) {
      _showError('Error recording payment: $e');
    } finally {
      isRecording.value = false;
    }
  }
  
  // ─── DELETE PAYMENT ──────────────────────────────────────────────────
  Future<void> deletePayment(String paymentId) async {
    try {
      final response = await _api.delete('/api/payments-made/$paymentId');
      
      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Payment deleted and journal entry reversed');
        await loadPayments();
        await loadSummary();
      } else {
        _showError(response.message.isNotEmpty ? response.message : 'Failed to delete payment');
      }
    } catch (e) {
      _showError('Error deleting payment: $e');
    }
  }
  
  // ─── CLEAR CHEQUE PAYMENT ──────────────────────────────────────────
  Future<void> clearChequePayment(String paymentId) async {
    try {
      final response = await _api.post('/api/payments-made/$paymentId/clear');
      
      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Cheque payment cleared successfully');
        await loadPayments();
        await loadSummary();
      } else {
        _showError(response.message.isNotEmpty ? response.message : 'Failed to clear cheque');
      }
    } catch (e) {
      _showError('Error clearing cheque: $e');
    }
  }
  
  // ─── APPLY FILTERS ──────────────────────────────────────────────────
  void applyDateFilter(String filter) {
    selectedFilter.value = filter;
    
    if (filter == 'Custom Range') {
      selectDateRange();
    } else {
      selectedDateRange.value = null;
      loadPayments();
      loadSummary();
    }
  }
  
  Future<void> selectDateRange() async {
    final picked = await Get.dialog<DateTimeRange>(
      DateRangePickerDialog(
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: selectedDateRange.value,
      ),
    );
    
    if (picked != null) {
      selectedDateRange.value = picked;
      selectedFilter.value = 'Custom Range';
      loadPayments();
      loadSummary();
    }
  }
  
  void clearDateRange() {
    selectedDateRange.value = null;
    selectedFilter.value = 'All';
    loadPayments();
    loadSummary();
  }
  
  // ─── HELPER METHODS ──────────────────────────────────────────────────
  void _showError(String message) {
    AppSnackbar.error(kDanger, 'Error', message);
  }
  
  void printVoucher(PaymentMade payment) {
    AppSnackbar.info('Print', 'Printing payment voucher for ${payment.paymentNumber}');
  }
  
  void viewBill(PaymentMade payment) {
    // Navigate to bill details
    Get.toNamed('/bill-details', arguments: payment.billId);
  }
  
  void exportPayments() {
    AppSnackbar.info('Export', 'Exporting payments...');
  }
}

// ─────────────────────── MODELS ───────────────────────

class PaymentMade {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String supplierId;
  final String supplierName;
  final String billId;
  final String billNumber;
  final double billAmount;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String bankAccountId;
  final String bankAccountName;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMade({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.supplierId,
    required this.supplierName,
    required this.billId,
    required this.billNumber,
    required this.billAmount,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.bankAccountId,
    required this.bankAccountName,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMade.fromJson(Map<String, dynamic> json) {
    return PaymentMade(
      id: json['id'] ?? json['_id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : DateTime.now(),
      supplierId: json['supplierId'] is Map ? json['supplierId']['id'] : json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      billId: json['billId'] is Map ? json['billId']['id'] : json['billId'] ?? '',
      billNumber: json['billNumber'] ?? '',
      billAmount: (json['billAmount'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      reference: json['reference'] ?? '',
      bankAccountId: json['bankAccountId'] ?? '',
      bankAccountName: json['bankAccountName'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}

class SupplierForPayment {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? companyName;

  SupplierForPayment({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.companyName,
  });

  factory SupplierForPayment.fromJson(Map<String, dynamic> json) {
    return SupplierForPayment(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      companyName: json['companyName'] ?? '',
    );
  }
}

class BankAccount {
  final String id;
  final String name;
  final String number;
  final double balance;

  BankAccount({
    required this.id,
    required this.name,
    required this.number,
    required this.balance,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['accountName'] ?? '',
      number: json['accountNumber'] ?? '',
      balance: (json['currentBalance'] ?? 0).toDouble(),
    );
  }
}

class BillForPayment {
  final String id;
  final String billNumber;
  final DateTime date;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final double outstanding;
  final String status;

  BillForPayment({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstanding,
    required this.status,
  });

  factory BillForPayment.fromJson(Map<String, dynamic> json) {
    return BillForPayment(
      id: json['id'] ?? json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}