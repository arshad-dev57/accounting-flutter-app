// lib/core/transactions/controller/transaction_controller.dart - FIXED

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:sizer/sizer.dart';

class TransactionController extends GetxController {
  // Observable variables
  var transactions = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Filter variables
  var selectedTab = 0.obs; // 0 = All, 1 = Income, 2 = Expense
  var selectedPeriod = 'This Month'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;
  var selectedType = 'All'.obs;

  // Summary data - ✅ FIXED: Use 0.0 as default
  var totalIncome = 0.0.obs;
  var totalExpense = 0.0.obs;
  var totalReceivable = 0.0.obs;
  var totalPayable = 0.0.obs;
  var netCashFlow = 0.0.obs;

  // Pagination
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMore = true.obs;
  final int pageSize = 10;

  // Text editing controller
  TextEditingController searchController = TextEditingController();

  // Scroll controller for lazy loading
  final ScrollController scrollController = ScrollController();

  // Categories
  var incomeCategories = <String>[].obs;
  var expenseCategories = <String>[].obs;
  var otherCategories = <String>[].obs;

  final List<String> periodOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range',
  ];

  final List<String> typeOptions = [
    'All',
    'Income',
    'Expense',
    'Receivable',
    'Payable',
    'Adjustment',
    'Financing',
    'Investment',
  ];

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    scrollController.addListener(_onScroll);
    loadCategories();
    loadTransactions();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    _resetAndReload();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {
      if (hasMore.value && !isLoadingMore.value) {
        loadMoreTransactions();
      }
    }
  }

  void _resetAndReload() {
    print("🔄 Resetting and reloading...");
    currentPage.value = 1;
    transactions.clear();
    hasMore.value = true;
    loadTransactions();
  }

  Future<void> loadCategories() async {
    try {
      final response = await _api.get('/api/transactions/categories');

      if (response.success) {
        final data = response.data;
        if (data['data'] != null) {
          incomeCategories.value = List<String>.from(
            data['data']['income'] ?? [],
          );
          expenseCategories.value = List<String>.from(
            data['data']['expense'] ?? [],
          );
          otherCategories.value = List<String>.from(
            data['data']['other'] ?? [],
          );
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      // Fallback categories
      incomeCategories.value = [
        'Sales',
        'Services',
        'Consulting',
        'Interest',
        'Rental',
        'Dividend',
        'Other',
        'Receipt',
      ];
      expenseCategories.value = [
        'Rent',
        'Salaries',
        'Utilities',
        'Office Supplies',
        'Marketing',
        'Travel',
        'Meals',
        'Software',
        'Equipment',
        'Payment',
        'Other',
      ];
      otherCategories.value = [
        'Sales',
        'Purchase',
        'Adjustment',
        'Financing',
        'Investment',
        'Fixed Asset',
      ];
    }
  }

  // ✅ FIXED: Helper to safely parse numeric values
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  Future<void> loadTransactions() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      Map<String, dynamic> params = {
        'page': currentPage.value.toString(),
        'limit': pageSize.toString(),
      };

      if (selectedType.value != 'All') {
        params['type'] = selectedType.value.toLowerCase();
      }

      print("🔍 ========== LOAD TRANSACTIONS DEBUG ==========");
      print("📅 SELECTED PERIOD: ${selectedPeriod.value}");
      print("📅 SELECTED DATE RANGE: ${selectedDateRange.value}");
      print("📅 SEARCH QUERY: ${searchQuery.value}");
      print("📅 SELECTED TYPE: ${selectedType.value}");
      print("==========================================");

      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
      } else {
        final now = DateTime.now();
        switch (selectedPeriod.value) {
          case 'Today':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month, now.day));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Week':
            final start = now.subtract(Duration(days: now.weekday - 1));
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(start.year, start.month, start.day));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Month':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Quarter':
            final quarter = (now.month - 1) ~/ 3;
            final startMonth = quarter * 3 + 1;
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, startMonth, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Year':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, 1, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
        }
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      print("📤 FINAL PARAMS SENT TO API: $params");

      final response = await _api.get(
        '/api/transactions',
        queryParameters: params,
      );

      print("📡 Response Status Code: ${response.statusCode}");

      if (response.success) {
        final data = response.data;

        // ✅ FIXED: Safe data extraction
        final dataList = data['data'] as List? ?? [];
        transactions.value = dataList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        totalPages.value = _safeInt(data['pages']);
        hasMore.value = currentPage.value < totalPages.value;

        // ✅ FIXED: Safe summary extraction
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        totalIncome.value = _safeDouble(summary['totalIncome']);
        totalExpense.value = _safeDouble(summary['totalExpense']);
        totalReceivable.value = _safeDouble(summary['totalReceivable']);
        totalPayable.value = _safeDouble(summary['totalPayable']);
        netCashFlow.value = _safeDouble(summary['netCashFlow']);

        print("✅ Transactions loaded: ${transactions.length} records");
        print("✅ Total pages: $totalPages");
        print(
          "✅ Summary: Income=${totalIncome.value}, Expense=${totalExpense.value}",
        );
      } else {
        hasError.value = true;
        errorMessage.value = 'Failed to load transactions';
        print("❌ Failed to load transactions: ${response.statusCode}");
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'error: $e';
      print('🔥 Error loading transactions: $e');
    } finally {
      isLoading.value = false;
      print("🔍 ========== LOAD TRANSACTIONS END ==========\n");
    }
  }

  Future<void> loadMoreTransactions() async {
    if (!hasMore.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      print("🔄 Loading more transactions - Page: ${currentPage.value}");

      Map<String, dynamic> params = {
        'page': currentPage.value.toString(),
        'limit': pageSize.toString(),
      };

      if (selectedType.value != 'All') {
        params['type'] = selectedType.value.toLowerCase();
      }

      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
      } else {
        final now = DateTime.now();
        switch (selectedPeriod.value) {
          case 'Today':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month, now.day));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Week':
            final start = now.subtract(Duration(days: now.weekday - 1));
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(start.year, start.month, start.day));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Month':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, now.month, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Quarter':
            final quarter = (now.month - 1) ~/ 3;
            final startMonth = quarter * 3 + 1;
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, startMonth, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
          case 'This Year':
            params['startDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime(now.year, 1, 1));
            params['endDate'] = DateFormat('yyyy-MM-dd').format(now);
            break;
        }
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _api.get(
        '/api/transactions',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        final dataList = data['data'] as List? ?? [];
        transactions.addAll(
          dataList.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        totalPages.value = _safeInt(data['pages']);
        hasMore.value = currentPage.value < totalPages.value;
        print(
          "✅ Loaded ${dataList.length} more transactions. Total: ${transactions.length}",
        );
      }
    } catch (e) {
      print('Error loading more transactions: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> createTransaction({
    required String type,
    required String title,
    required String description,
    required double amount,
    required DateTime date,
    required String category,
    required String paymentMethod,
    required String reference,
  }) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> transactionData = {
        'type': type,
        'title': title,
        'description': description,
        'amount': amount,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'category': category,
        'paymentMethod': paymentMethod,
        'reference': reference,
      };

      final response = await _api.post(
        '/api/transactions',
        body: transactionData,
      );

      if (response.success) {
        Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          '${type == 'income' ? 'Income' : 'Expense'} recorded successfully\nJournal entry created',
        );
        _resetAndReload();
      } else {
        final errorData = response.data as Map<String, dynamic>? ?? {};
        AppSnackbar.error(
          kDanger,
          'Error',
          errorData['message'] ?? 'Failed to create transaction',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to create transaction: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    if (index == 0) {
      selectedType.value = 'All';
    } else if (index == 1) {
      selectedType.value = 'Income';
    } else if (index == 2) {
      selectedType.value = 'Expense';
    }
    _resetAndReload();
  }

  void changeType(String type) {
    selectedType.value = type;
    if (type == 'All') {
      selectedTab.value = 0;
    } else if (type == 'Income') {
      selectedTab.value = 1;
    } else if (type == 'Expense') {
      selectedTab.value = 2;
    }
    _resetAndReload();
  }

  void changePeriod(String period) {
    print("🔄 Changing period to: $period");
    selectedPeriod.value = period;
    if (period != 'Custom Range') {
      selectedDateRange.value = null;
      print("🔄 Date range cleared");
    }
    _resetAndReload();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedPeriod.value = 'Custom Range';
    }
    _resetAndReload();
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    selectedPeriod.value = 'This Month';
    _resetAndReload();
  }

  void clearFilters() {
    searchController.clear();
    searchQuery.value = '';
    selectedDateRange.value = null;
    selectedPeriod.value = 'This Month';
    selectedType.value = 'All';
    selectedTab.value = 0;
    _resetAndReload();
  }

  void refreshData() {
    _resetAndReload();
  }

  IconData getIconForTransaction(Map<String, dynamic> transaction) {
    final source = transaction['source'] ?? '';
    final type = transaction['type'] ?? '';

    switch (source) {
      case 'income':
        return Icons.trending_up;
      case 'expense':
        return Icons.trending_down;
      case 'invoice':
        return Icons.receipt;
      case 'bill':
        return Icons.receipt;
      case 'payment_received':
        return Icons.arrow_downward;
      case 'payment_made':
        return Icons.arrow_upward;
      case 'credit_note':
        return Icons.note;
      case 'journal_entry':
        return Icons.book;
      case 'loan':
        return Icons.credit_card;
      case 'fixed_asset':
        return Icons.business_center;
      default:
        return type == 'income' ? Icons.trending_up : Icons.trending_down;
    }
  }

  Color getColorForTransaction(Map<String, dynamic> transaction) {
    final source = transaction['source'] ?? '';
    final type = transaction['type'] ?? '';

    if (transaction['color'] != null) {
      final colorStr = transaction['color'] as String;
      try {
        return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
      } catch (_) {
        // Fallback if color parsing fails
      }
    }

    switch (source) {
      case 'income':
      case 'payment_received':
        return kSuccess;
      case 'expense':
      case 'payment_made':
        return kDanger;
      case 'invoice':
        return const Color(0xFF3498DB);
      case 'bill':
        return const Color(0xFFE67E22);
      case 'credit_note':
        return const Color(0xFFF1C40F);
      case 'journal_entry':
        return const Color(0xFF9B59B6);
      case 'loan':
        return const Color(0xFF3498DB);
      case 'fixed_asset':
        return const Color(0xFF1ABC9C);
      default:
        return type == 'income' ? kSuccess : kDanger;
    }
  }

  String getTransactionTitle(Map<String, dynamic> transaction) {
    final source = transaction['source'] ?? '';
    final title = transaction['title'] ?? '';
    final transactionNumber = transaction['transactionNumber'] ?? '';

    switch (source) {
      case 'invoice':
        return 'Invoice: $transactionNumber';
      case 'bill':
        return 'Bill: $transactionNumber';
      case 'payment_received':
        return 'Payment Received';
      case 'payment_made':
        return 'Payment Made';
      case 'credit_note':
        return 'Credit Note: $transactionNumber';
      case 'journal_entry':
        return 'Journal Entry: $transactionNumber';
      case 'loan':
        return 'Loan: $transactionNumber';
      case 'fixed_asset':
        return 'Asset Purchase: $transactionNumber';
      default:
        return title;
    }
  }

  String getTransactionSubtitle(Map<String, dynamic> transaction) {
    final source = transaction['source'] ?? '';
    final category = transaction['category'] ?? '';
    final customerName = transaction['customerName'] ?? '';
    final vendorName = transaction['vendorName'] ?? '';
    final dueDate = transaction['dueDate'];

    String subtitle = category;

    if (customerName.isNotEmpty) {
      subtitle = '$customerName • $subtitle';
    } else if (vendorName.isNotEmpty) {
      subtitle = '$vendorName • $subtitle';
    }

    if (dueDate != null) {
      try {
        subtitle =
            '$subtitle • Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(dueDate))}';
      } catch (_) {
        // If date parsing fails, just ignore
      }
    }

    return subtitle;
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  void exportTransactions() {
    AppSnackbar.info('Export', 'Exporting transactions to Excel...');
  }

  void _showError(String message) {
    AppSnackbar.error(kDanger, 'Error', message);
  }
}
