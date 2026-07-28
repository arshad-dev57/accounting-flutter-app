// core/Expense/controller/expense_controller.dart - COMPLETE FIXED

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/config/apiconfig.dart';
import 'package:LedgerPro_app/core/Expense/model/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class ExpenseController extends GetxController {
  // Observable variables
  var expenses = <Expense>[].obs;
  var allExpenses = <Expense>[].obs;

  var vendors = <Map<String, dynamic>>[].obs;
  var bankAccounts = <Map<String, dynamic>>[].obs;
  var expenseAccounts = <Map<String, dynamic>>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var isPosting = false.obs;

  var selectedFilter = 'All'.obs;
  var selectedType = 'All'.obs;
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var searchQuery = ''.obs;

  // Pagination
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMore = true.obs;
  final int pageSize = 20;

  // Filter options
  final List<String> filterOptions = ['All', 'Draft', 'Posted', 'Cancelled'];
  final List<String> expenseTypes = [
    'All',
    'Rent',
    'Utilities',
    'Salaries',
    'Marketing',
    'Office Supplies',
    'Travel',
    'Meals',
    'Insurance',
    'Maintenance',
    'Software',
    'Taxes',
    'Other',
  ];

  // Summary data
  var totalExpense = 0.0.obs;
  var totalTax = 0.0.obs;
  var totalCount = 0.obs;
  var thisMonthTotal = 0.0.obs;
  var thisWeekTotal = 0.0.obs;
  var byType = <String, double>{}.obs;

  // Text editing controller
  TextEditingController searchController = TextEditingController();
  final ApiClient _api = Get.find<ApiClient>();

  // Scroll controller for lazy loading
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadAllData();
    loadSummary();
    _setupScrollListener();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        if (hasMore.value && !isLoadingMore.value) {
          loadMoreExpenses();
        }
      }
    });
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;

    if (searchQuery.value.isEmpty) {
      expenses.value = allExpenses.value;
      _updateSummaryForFiltered(allExpenses.value);
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      final results = allExpenses.where((expense) {
        return expense.expenseNumber.toLowerCase().contains(searchLower) ||
            expense.description.toLowerCase().contains(searchLower) ||
            expense.expenseType.toLowerCase().contains(searchLower) ||
            expense.vendorName.toLowerCase().contains(searchLower) ||
            expense.reference.toLowerCase().contains(searchLower);
      }).toList();
      expenses.value = results;
      _updateSummaryForFiltered(results);
    }
  }

  void _updateSummaryForFiltered(List<Expense> filteredExpenses) {
    totalExpense.value = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.totalAmount,
    );
    totalTax.value = filteredExpenses.fold(0.0, (sum, e) => sum + e.taxAmount);
    totalCount.value = filteredExpenses.length;

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));

    thisMonthTotal.value = filteredExpenses
        .where(
          (e) =>
              e.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))),
        )
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    thisWeekTotal.value = filteredExpenses
        .where(
          (e) =>
              e.date.isAfter(thisWeekStart.subtract(const Duration(days: 1))),
        )
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    byType.clear();
    for (final expense in filteredExpenses) {
      byType[expense.expenseType] =
          (byType[expense.expenseType] ?? 0) + expense.totalAmount;
    }
  }

  void _resetAndReload() {
    currentPage.value = 1;
    expenses.clear();
    allExpenses.clear();
    hasMore.value = true;
    loadExpenses();
    loadSummary();
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadVendors(),
      loadBankAccounts(),
      loadExpenseAccounts(),
      loadExpenses(),
    ]);
  }

  // ==================== LOAD EXPENSE ACCOUNTS ====================
  Future<void> loadExpenseAccounts() async {
    try {
      print('🔄 [loadExpenseAccounts] Loading expense accounts...');
      final response = await _api.get('/api/expenses/accounts');

      if (response.success) {
        final responseData = response.data;
        List<dynamic> accounts = [];

        if (responseData != null) {
          if (responseData is List) {
            accounts = responseData;
          } else if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              accounts = responseData['data'];
            }
          }
        }

        expenseAccounts.value = accounts
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '✅ [loadExpenseAccounts] Loaded ${expenseAccounts.length} expense accounts',
        );
      } else {
        print('❌ [loadExpenseAccounts] Failed: ${response.message}');
        await _loadExpenseAccountsFallback1();
      }
    } catch (e) {
      print('❌ [loadExpenseAccounts] Error: $e');
      await _loadExpenseAccountsFallback1();
    }
  }

  Future<void> _loadExpenseAccountsFallback1() async {
    try {
      print('🔄 [_loadExpenseAccountsFallback1] Trying fallback...');
      final response = await _api.get(
        '/api/chart-of-accounts?type=Expense&isActive=true',
      );

      if (response.success) {
        final responseData = response.data;
        List<dynamic> accounts = [];

        if (responseData != null) {
          if (responseData is List) {
            accounts = responseData;
          } else if (responseData['data'] != null) {
            accounts = responseData['data'];
          }
        }

        expenseAccounts.value = accounts.map((e) {
          final map = Map<String, dynamic>.from(e);
          return {
            'id': map['id'] ?? '',
            'code': map['code'] ?? '',
            'name': map['name'] ?? '',
          };
        }).toList();

        print(
          '✅ [_loadExpenseAccountsFallback1] Loaded ${expenseAccounts.length} expense accounts',
        );
      } else {
        print('❌ [_loadExpenseAccountsFallback1] Failed');
        await _loadExpenseAccountsFallback2();
      }
    } catch (e) {
      print('❌ [_loadExpenseAccountsFallback1] Error: $e');
      await _loadExpenseAccountsFallback2();
    }
  }

  Future<void> _loadExpenseAccountsFallback2() async {
    try {
      print('🔄 [_loadExpenseAccountsFallback2] Using default accounts...');
      final defaultAccounts = [
        {'id': '1', 'code': '5100', 'name': 'Rent Expense'},
        {'id': '2', 'code': '5200', 'name': 'Salaries Expense'},
        {'id': '3', 'code': '5300', 'name': 'Utilities Expense'},
        {'id': '4', 'code': '5400', 'name': 'Office Supplies Expense'},
        {'id': '5', 'code': '5500', 'name': 'Marketing Expense'},
        {'id': '6', 'code': '5600', 'name': 'Travel Expense'},
        {'id': '7', 'code': '5700', 'name': 'Meals & Entertainment'},
        {'id': '8', 'code': '5800', 'name': 'Software Expense'},
        {'id': '9', 'code': '5900', 'name': 'Equipment Expense'},
        {'id': '10', 'code': '6000', 'name': 'Other Expense'},
      ];
      expenseAccounts.value = defaultAccounts;
      print(
        '✅ [_loadExpenseAccountsFallback2] Using ${expenseAccounts.length} default expense accounts',
      );
    } catch (e) {
      print('❌ [_loadExpenseAccountsFallback2] Error: $e');
    }
  }

  // ==================== LOAD VENDORS ====================
  Future<void> loadVendors() async {
    try {
      print('🔄 [loadVendors] Loading vendors...');
      final response = await _api.get('/api/accounts-payable/vendors');
      if (response.success) {
        final responseData = response.data;
        vendors.value = List<Map<String, dynamic>>.from(
          responseData['data'] ?? [],
        );
        print('✅ [loadVendors] Loaded ${vendors.length} vendors');
      } else {
        print('❌ [loadVendors] Failed: ${response.message}');
      }
    } catch (e) {
      print('❌ [loadVendors] Error: $e');
    }
  }

  // ==================== LOAD BANK ACCOUNTS ====================
  Future<void> loadBankAccounts() async {
    try {
      print('🔄 [loadBankAccounts] Loading bank accounts...');
      final response = await _api.get('/api/bank-accounts');

      if (response.success) {
        final responseData = response.data;
        List<dynamic> accounts = [];
        if (responseData['data'] != null) {
          accounts = responseData['data'] as List;
        }

        bankAccounts.value = accounts
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '✅ [loadBankAccounts] Loaded ${bankAccounts.length} bank accounts',
        );
      } else {
        print('❌ [loadBankAccounts] Failed: ${response.message}');
        await _loadBankAccountsFallback();
      }
    } catch (e) {
      print('❌ [loadBankAccounts] Error: $e');
      await _loadBankAccountsFallback();
    }
  }

  Future<void> _loadBankAccountsFallback() async {
    try {
      print('🔄 [_loadBankAccountsFallback] Trying fallback...');
      final response = await _api.get('/api/bank-accounts/all');
      if (response.success) {
        final responseData = response.data;
        List<dynamic> accounts = [];
        if (responseData['data'] != null) {
          accounts = responseData['data'] as List;
        }
        bankAccounts.value = accounts
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        print(
          '✅ [_loadBankAccountsFallback] Loaded ${bankAccounts.length} bank accounts',
        );
      }
    } catch (e) {
      print('❌ [_loadBankAccountsFallback] Error: $e');
    }
  }

  // ==================== LOAD EXPENSES ====================
  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;

      Map<String, String> params = {};

      params['page'] = currentPage.value.toString();
      params['limit'] = pageSize.toString();

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }
      if (selectedType.value != 'All') {
        params['expenseType'] = selectedType.value;
      }
      if (startDate.value != null && endDate.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }

      final response = await _api.get('/api/expenses', queryParameters: params);

      if (response.success) {
        final responseData = response.data;
        if (responseData['data'] is List) {
          List<dynamic> expensesData = responseData['data'];
          final newExpenses = expensesData
              .map((json) => Expense.fromJson(json))
              .toList();

          if (currentPage.value == 1) {
            allExpenses.value = newExpenses;
          } else {
            allExpenses.addAll(newExpenses);
          }

          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            expenses.value = newExpenses;
          }

          totalPages.value = responseData['pages'] ?? 1;
          hasMore.value = currentPage.value < totalPages.value;
        } else {
          expenses.clear();
          totalPages.value = 1;
          hasMore.value = false;
        }
      } else {
        _showError('Failed to load expenses');
      }
    } catch (e) {
      print('Error loading expenses: $e');
      _showError('Error loading expenses');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== LOAD MORE EXPENSES ====================
  Future<void> loadMoreExpenses() async {
    if (!hasMore.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      Map<String, String> params = {};

      params['page'] = currentPage.value.toString();
      params['limit'] = pageSize.toString();

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }
      if (selectedType.value != 'All') {
        params['expenseType'] = selectedType.value;
      }
      if (startDate.value != null && endDate.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }
      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _api.get('/api/expenses', queryParameters: params);

      if (response.success) {
        final responseData = response.data;
        if (responseData['data'] is List) {
          List<dynamic> expensesData = responseData['data'];
          List<Expense> newExpenses = expensesData
              .map((json) => Expense.fromJson(json))
              .toList();
          expenses.addAll(newExpenses);
          totalPages.value = responseData['pages'] ?? 1;
          hasMore.value = currentPage.value < totalPages.value;
        }
      }
    } catch (e) {
      print('Error loading more expenses: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ==================== LOAD SUMMARY ====================
  Future<void> loadSummary() async {
    try {
      Map<String, dynamic> params = {};
      if (startDate.value != null && endDate.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }

      final response = await _api.get(
        '/api/expenses/summary',
        queryParameters: params,
      );

      if (response.success) {
        final responseData = response.data;
        final data = responseData['data'];
        totalExpense.value = (data['totalExpense'] ?? 0).toDouble();
        totalTax.value = (data['totalTax'] ?? 0).toDouble();
        totalCount.value = data['totalCount'] ?? 0;
        thisMonthTotal.value = (data['thisMonth'] ?? 0).toDouble();
        thisWeekTotal.value = (data['thisWeek'] ?? 0).toDouble();

        if (data['byType'] != null) {
          byType.clear();
          data['byType'].forEach((key, value) {
            byType[key] = (value ?? 0).toDouble();
          });
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  // ==================== CREATE EXPENSE ====================
  Future<void> createExpense({
    required DateTime date,
    required String expenseType,
    required String? expenseAccountId,
    required String? vendorId,
    required List<Map<String, dynamic>> items,
    required double? amount,
    required double taxRate,
    required String description,
    required String reference,
    required String paymentMethod,
    required String? bankAccountId,
  }) async {
    // ✅ Show loading dialog
    Get.dialog(
      Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: kPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Saving expense...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please wait',
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isSaving.value = true;

      final Map<String, dynamic> expenseData = {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'expenseType': expenseType,
        'expenseAccountId': expenseAccountId,
        'vendorId': vendorId,
        'items': items,
        'amount': amount ?? 0,
        'taxRate': taxRate,
        'description': description,
        'reference': reference,
        'paymentMethod': paymentMethod,
        'bankAccountId': bankAccountId,
      };

      final response = await _api.post('/api/expenses', body: expenseData);

      // ✅ Close loading dialog
      Get.back();

      if (response.success) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          AppSnackbar.success(
            kSuccess,
            'Success',
            'Expense recorded and posted to ledger',
          );
          _resetAndReload();
          loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to create expense');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to create expense');
      }
    } catch (e) {
      // ✅ Close loading dialog on error
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error creating expense: $e');
      _showError('Error creating expense');
    } finally {
      isSaving.value = false;
    }
  }

  // ==================== DELETE EXPENSE ====================
  Future<void> deleteExpense(String id, String expenseNumber) async {
    // ✅ Show loading dialog
    Get.dialog(
      Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting expense...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please wait',
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isDeleting.value = true;
      final response = await _api.delete('/api/expenses/$id');

      // ✅ Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Expense $expenseNumber deleted successfully',
        );
        _resetAndReload();
        loadSummary();
      } else {
        _showError(response.data['message'] ?? 'Failed to delete expense');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error deleting expense: $e');
      _showError('Error deleting expense');
    } finally {
      isDeleting.value = false;
    }
  }

  // ==================== POST EXPENSE ====================
  Future<void> postExpense(String id) async {
    // ✅ Show loading dialog
    Get.dialog(
      Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: kSuccess,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Posting expense...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please wait',
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      isPosting.value = true;
      final response = await _api.post('/api/expenses/$id/post');

      // ✅ Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Expense posted to ledger');
        _resetAndReload();
        loadSummary();
      } else {
        _showError(response.data['message'] ?? 'Failed to post expense');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error posting expense: $e');
      _showError('Error posting expense');
    } finally {
      isPosting.value = false;
    }
  }

  // ==================== FILTER METHODS ====================
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    _resetAndReload();
  }

  void applyTypeFilter(String type) {
    selectedType.value = type;
    _resetAndReload();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    _resetAndReload();
    loadSummary();
  }

  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
    _resetAndReload();
    loadSummary();
  }

  void clearFilters() {
    selectedFilter.value = 'All';
    selectedType.value = 'All';
    startDate.value = null;
    endDate.value = null;
    searchController.clear();
    searchQuery.value = '';
    _resetAndReload();
    loadSummary();
  }

  void refreshData() {
    _resetAndReload();
    loadSummary();
  }

  // ==================== EXPORT FUNCTIONS ====================
  void exportExpenses() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose export format',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Color(0xFFE53935)),
              title: Text('Export as PDF'),
              onTap: () {
                Get.back();
                exportToPdf();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Color(0xFF2E7D32)),
              title: Text('Export as Excel'),
              onTap: () {
                Get.back();
                exportToExcel();
              },
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> exportToPdf() async {
    try {
      if (!kIsWeb) {
        Get.dialog(
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: kPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Generating PDF...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
      // ... rest of export code
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (!kIsWeb) {
        Get.dialog(
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: kPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Building Excel...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
      // ... rest of export code
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export Excel: $e');
    }
  }

  // ==================== PDF HELPER METHODS ====================
  pw.Widget _pdfHeader() {
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
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
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
              'LedgerPro',
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

  pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Confidential - For Internal Use Only',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummarySection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfSummaryItem(
            'Total Expense',
            formatAmount(totalExpense.value),
            PdfColors.red700,
          ),
          _pdfSummaryItem(
            'Total Tax',
            formatAmount(totalTax.value),
            PdfColors.orange700,
          ),
          _pdfSummaryItem(
            'Total Records',
            totalCount.value.toString(),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'This Month',
            formatAmount(thisMonthTotal.value),
            PdfColors.blue700,
          ),
          _pdfSummaryItem(
            'This Week',
            formatAmount(thisWeekTotal.value),
            PdfColors.purple700,
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfExpensesTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Details',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
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
                flex: 2,
                child: pw.Text(
                  'Expense #',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Type',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Vendor',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Date',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Status',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...expenses
            .map(
              (expense) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        expense.expenseNumber,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        expense.expenseType,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        expense.vendorName.isEmpty ? '-' : expense.vendorName,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd MMM yyyy').format(expense.date),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(expense.totalAmount),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        expense.status,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 8,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(totalExpense.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('', textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== EXCEL HELPER ====================
  void _excelSetCell(
    Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool bold = false,
    double fontSize = 10,
    String? bgColor,
    String fontColor = '000000',
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value is double
        ? DoubleCellValue(value)
        : value is int
        ? IntCellValue(value)
        : TextCellValue(value.toString());

    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontColorHex: ExcelColor.fromHexString('#$fontColor'),
      backgroundColorHex: bgColor != null
          ? ExcelColor.fromHexString('#$bgColor')
          : ExcelColor.fromHexString('#FFFFFF'),
    );
  }

  void printExpenses() {
    AppSnackbar.success(kPrimary, 'Print', 'Preparing expense report...');
  }

  // ==================== HELPER METHODS ====================
  String formatAmount(double amount) => CurrencyUtils.format(amount);

  String getTypeColor(String type) {
    switch (type) {
      case 'Rent':
        return '#E74C3C';
      case 'Utilities':
        return '#3498DB';
      case 'Salaries':
        return '#2ECC71';
      case 'Marketing':
        return '#F1C40F';
      case 'Office Supplies':
        return '#9B59B6';
      case 'Travel':
        return '#E67E22';
      case 'Meals':
        return '#1ABC9C';
      case 'Insurance':
        return '#16A085';
      case 'Maintenance':
        return '#27AE60';
      case 'Software':
        return '#2980B9';
      case 'Taxes':
        return '#8E44AD';
      default:
        return '#7A8FA6';
    }
  }

  IconData getTypeIcon(String type) {
    switch (type) {
      case 'Rent':
        return Icons.home;
      case 'Utilities':
        return Icons.bolt;
      case 'Salaries':
        return Icons.people;
      case 'Marketing':
        return Icons.campaign;
      case 'Office Supplies':
        return Icons.inventory;
      case 'Travel':
        return Icons.flight;
      case 'Meals':
        return Icons.restaurant;
      case 'Insurance':
        return Icons.security;
      case 'Maintenance':
        return Icons.build;
      case 'Software':
        return Icons.computer;
      case 'Taxes':
        return Icons.receipt;
      default:
        return Icons.money_off;
    }
  }

  bool requiresItems(String expenseType) {
    return expenseType == 'Office Supplies' ||
        expenseType == 'Travel' ||
        expenseType == 'Meals';
  }

  void _showError(String message) {
    AppSnackbar.error(kWarning, 'Error', message);
  }
}
