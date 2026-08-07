// core/chartofaccounts/controller/chart_of_account_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChartOfAccountController extends GetxController {
  var accounts = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;

  // Summary totals
  var totalAssets = 0.0.obs;
  var totalLiabilities = 0.0.obs;
  var totalEquity = 0.0.obs;
  var totalIncome = 0.0.obs;
  var totalExpenses = 0.0.obs;

  // Account type stats
  var accountTypeStats = <String, dynamic>{}.obs;
  var hasIncorrectCashAccounts = false.obs;

  // Opening balance status
  var hasOpeningBalance = false.obs;
  var openingBalanceDetails = <String, dynamic>{}.obs;

  final ApiClient _api = Get.find<ApiClient>();

  // ─── TYPE MAPPING ──────────────────────────────────────────────────
  static const Map<String, String> typeMap = {
    'Assets': 'Asset',
    'Liabilities': 'Liability',
    'Equity': 'Equity',
    'Income': 'Revenue',
    'Expenses': 'Expense',
  };

  static const Map<String, String> reverseTypeMap = {
    'Asset': 'Assets',
    'Liability': 'Liabilities',
    'Equity': 'Equity',
    'Revenue': 'Income',
    'Expense': 'Expenses',
  };

  // ─── Helper: Map type to backend ──────────────────────────────────
  String mapTypeToBackend(String frontendType) {
    return typeMap[frontendType] ?? frontendType;
  }

  // ─── Helper: Map type to frontend ──────────────────────────────────
  String mapTypeToFrontend(String backendType) {
    return reverseTypeMap[backendType] ?? backendType;
  }

  // ─── Helper: Convert to double safely ────────────────────────────
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void onInit() {
    super.onInit();
    fetchAccounts();
    fetchAccountTypeStats();
    checkOpeningBalanceStatus();
  }

  // ─── Fetch account type stats ────────────────────────────────────
  Future<void> fetchAccountTypeStats() async {
    try {
      final response = await _api.get('/api/chart-of-accounts/type-stats');
      if (response.success) {
        final data = response.data;
        accountTypeStats.value = data['data'] ?? {};
        hasIncorrectCashAccounts.value =
            data['data']?['issues']?['hasIssues'] ?? false;

        if (hasIncorrectCashAccounts.value) {
          final count = data['data']?['issues']?['incorrectCashAccounts'] ?? 0;
          print('⚠️ $count cash/bank account(s) have incorrect type');
        }
      }
    } catch (e) {
      print('Error fetching account type stats: $e');
    }
  }

  // ─── Fix cash accounts ──────────────────────────────────────────
  Future<void> fixCashAccounts() async {
    try {
      isLoading(true);
      final response = await _api.post(
        '/api/chart-of-accounts/fix-cash-accounts',
      );

      if (response.success) {
        final count = response.data['count'] ?? 0;
        if (count > 0) {
          AppSnackbar.success(
            Colors.green,
            '✅ Success',
            '$count cash/bank account(s) fixed successfully',
          );
          await fetchAccounts();
          await fetchAccountTypeStats();
        } else {
          AppSnackbar.success(
            Colors.green,
            '✅ All Good',
            'No incorrect cash/bank accounts found',
          );
        }
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to fix accounts',
        );
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to fix cash accounts: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Fetch accounts with pagination ──────────────────────────────
  Future<void> fetchAccounts({bool resetPage = true}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading(true);
      } else {
        isLoadingMore(true);
      }

      Map<String, dynamic> queryParams = {};
      queryParams['page'] = currentPage.value.toString();

      // 🔥 FIX: Increase limit for 'All' filter to show more accounts
      if (selectedFilter.value == 'All') {
        queryParams['limit'] =
            '50'; // Show more accounts when 'All' is selected
      } else {
        queryParams['limit'] = '10';
      }

      // Only add type filter if not 'All'
      if (selectedFilter.value != 'All') {
        final backendType = mapTypeToBackend(selectedFilter.value);
        queryParams['type'] = backendType;
      }

      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      // 🔥 ADD: Debug logging
      print(
        '📊 Fetching accounts - Filter: ${selectedFilter.value}, Page: ${currentPage.value}, Limit: ${queryParams['limit']}',
      );
      print('📊 Query params: $queryParams');

      final response = await _api.get(
        '/api/chart-of-accounts',
        queryParameters: queryParams,
      );

      if (response.success) {
        final data = response.data;
        List<Map<String, dynamic>> newAccounts =
            List<Map<String, dynamic>>.from(data['data']);

        // 🔥 FIX: Clear accounts only when resetPage is true
        if (resetPage) {
          accounts.value = newAccounts;
        } else {
          accounts.addAll(newAccounts);
        }

        if (data['pagination'] != null) {
          totalPages.value = data['pagination']['pages'] ?? 1;
          totalItems.value = data['pagination']['total'] ?? 0;
          hasNextPage.value = data['pagination']['hasNext'] ?? false;
          hasPrevPage.value = data['pagination']['hasPrev'] ?? false;

          // 🔥 ADD: Debug logging for pagination
          print(
            '📊 Total items: ${totalItems.value}, Total pages: ${totalPages.value}, Has next: ${hasNextPage.value}',
          );
        }

        if (resetPage && data['summary'] != null) {
          totalAssets.value = _toDouble(data['summary']['Assets']);
          totalLiabilities.value = _toDouble(data['summary']['Liabilities']);
          totalEquity.value = _toDouble(data['summary']['Equity']);
          totalIncome.value = _toDouble(data['summary']['Income']);
          totalExpenses.value = _toDouble(data['summary']['Expenses']);
        } else if (resetPage) {
          _calculateSummary();
        }
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Something went wrong',
        );
      }
    } catch (e) {
      print('❌ Error fetching accounts: $e');
      AppSnackbar.error(Colors.red, 'Error', 'Failed to load accounts: $e');
    } finally {
      isLoading(false);
      isLoadingMore(false);
    }
  }

  // ─── Load next page ──────────────────────────────────────────────
  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoadingMore.value) {
      currentPage.value++;
      await fetchAccounts(resetPage: false);
    }
  }

  // ─── Load previous page ──────────────────────────────────────────
  Future<void> loadPreviousPage() async {
    if (hasPrevPage.value && !isLoadingMore.value) {
      currentPage.value--;
      await fetchAccounts(resetPage: false);
    }
  }

  // ─── Load more data for lazy loading ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchAccounts(resetPage: false);
    }
  }

  // ─── Change filter with proper reset ──────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    currentPage.value = 1; // Reset to first page
    accounts.clear(); // Clear existing accounts
    fetchAccounts(resetPage: true);
  }

  // ─── Search accounts ──────────────────────────────────────────────
  void searchAccounts(String query) {
    searchQuery.value = query;
    currentPage.value = 1; // Reset to first page
    accounts.clear(); // Clear existing accounts
    fetchAccounts(resetPage: true);
  }

  // ─── Create new account ──────────────────────────────────────────
  Future<void> createAccount(Map<String, dynamic> accountData) async {
    try {
      // Map type to backend
      final backendType = mapTypeToBackend(accountData['type'] ?? 'Assets');
      final mappedData = Map<String, dynamic>.from(accountData);
      mappedData['type'] = backendType;

      // Frontend validation for cash/bank
      final name = mappedData['name'] ?? '';
      final nameLower = name.toLowerCase();
      final isCashOrBank =
          nameLower.contains('cash') ||
          nameLower.contains('bank') ||
          nameLower.contains('money') ||
          nameLower.contains('checking') ||
          nameLower.contains('saving');

      if (isCashOrBank && backendType != 'Asset') {
        AppSnackbar.error(
          Colors.red,
          'Invalid Account Type',
          '"$name" must be of type "Asset". Please select "Assets" as account type.',
        );
        return;
      }

      // Check: If Equity account with opening balance and opening balance already exists
      if (backendType == 'Equity' && (accountData['openingBalance'] ?? 0) > 0) {
        final hasExistingOB = await checkOpeningBalanceStatus();
        if (hasExistingOB) {
          AppSnackbar.error(
            Colors.orange,
            '⚠️ Opening Balance Exists',
            'An opening balance entry already exists. Please set opening balance to 0 for this Equity account.',
          );
          return;
        }
      }

      final response = await _api.post(
        '/api/chart-of-accounts',
        body: mappedData,
      );

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Account "${mappedData['name']}" added successfully',
        );
        await fetchAccounts();
        await fetchAccountTypeStats();
        await checkOpeningBalanceStatus();
      } else {
        String errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to create account';

        if (response.data != null && response.data['suggestion'] != null) {
          errorMessage = response.data['suggestion'];
        }

        if (response.data != null &&
            response.data['hasExistingOpeningBalance'] == true) {
          errorMessage =
              '⚠️ Opening balance already exists! Please set opening balance to 0 for this account.';
        }

        AppSnackbar.error(Colors.red, 'Error', errorMessage);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to create account: $e');
    }
  }

  // ─── Update account ──────────────────────────────────────────────
  Future<void> updateAccount(
    String id,
    Map<String, dynamic> accountData,
  ) async {
    try {
      if (accountData.containsKey('type')) {
        final backendType = mapTypeToBackend(accountData['type']);
        accountData['type'] = backendType;
      }

      final name = accountData['name'] ?? '';
      final nameLower = name.toLowerCase();
      final isCashOrBank =
          nameLower.contains('cash') ||
          nameLower.contains('bank') ||
          nameLower.contains('money') ||
          nameLower.contains('checking') ||
          nameLower.contains('saving');

      if (isCashOrBank && accountData['type'] != 'Asset') {
        AppSnackbar.error(
          Colors.red,
          'Invalid Account Type',
          '"$name" must be of type "Asset". Please select "Assets" as account type.',
        );
        return;
      }

      final response = await _api.put(
        '/api/chart-of-accounts/$id',
        body: accountData,
      );

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Account updated successfully',
        );
        await fetchAccounts();
        await fetchAccountTypeStats();
        await checkOpeningBalanceStatus();
      } else {
        String errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to update account';

        if (response.data != null && response.data['suggestion'] != null) {
          errorMessage = response.data['suggestion'];
        }

        AppSnackbar.error(Colors.red, 'Error', errorMessage);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to update account: $e');
    }
  }

  // ─── Fix account type ──────────────────────────────────────────────
  Future<void> fixAccountType(String id, String newType) async {
    try {
      isLoading(true);

      final backendType = mapTypeToBackend(newType);

      final response = await _api.patch(
        '/api/chart-of-accounts/$id/fix-type',
        body: {'type': backendType},
      );

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          '✅ Success',
          response.data['message'] ?? 'Account type fixed successfully',
        );
        await fetchAccounts();
        await fetchAccountTypeStats();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to fix account type',
        );
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to fix account type: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Archive account ──────────────────────────────────────────────
  Future<void> archiveAccount(String id, bool isActive) async {
    try {
      isLoading(true);

      final response = await _api.patch(
        '/api/chart-of-accounts/$id/archive',
        body: {'isActive': isActive},
      );

      if (response.success) {
        final data = response.data;
        AppSnackbar.success(
          Colors.green,
          'Success',
          data['message'] ??
              'Account ${isActive ? 'activated' : 'archived'} successfully',
        );
        await fetchAccounts();
        await fetchAccountTypeStats();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to archive account',
        );
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to archive account: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Delete account ──────────────────────────────────────────────
  Future<void> deleteAccount(String id) async {
    try {
      isLoading(true);

      final response = await _api.delete('/api/chart-of-accounts/$id');

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Account deleted successfully',
        );
        await fetchAccounts();
        await fetchAccountTypeStats();
      } else {
        String errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete account';

        if (response.data != null && response.data['suggestion'] != null) {
          errorMessage = response.data['suggestion'];
        }

        AppSnackbar.error(Colors.red, 'Error', errorMessage);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to delete account: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Refresh all accounts ──────────────────────────────────────────
  void refreshAllAccounts() {
    currentPage.value = 1;
    accounts.clear();
    fetchAccounts(resetPage: true);
  }

  // ─── Calculate summary from local data ──────────────────────────
  void _calculateSummary() {
    totalAssets.value = accounts
        .where((a) => a['type'] == 'Asset')
        .fold(
          0.0,
          (sum, a) => sum + _toDouble(a['currentBalance'] ?? a['balance']),
        );

    totalLiabilities.value = accounts
        .where((a) => a['type'] == 'Liability')
        .fold(
          0.0,
          (sum, a) => sum + _toDouble(a['currentBalance'] ?? a['balance']),
        );

    totalEquity.value = accounts
        .where((a) => a['type'] == 'Equity')
        .fold(
          0.0,
          (sum, a) => sum + _toDouble(a['currentBalance'] ?? a['balance']),
        );

    totalIncome.value = accounts
        .where((a) => a['type'] == 'Revenue')
        .fold(
          0.0,
          (sum, a) => sum + _toDouble(a['currentBalance'] ?? a['balance']),
        );

    totalExpenses.value = accounts
        .where((a) => a['type'] == 'Expense')
        .fold(
          0.0,
          (sum, a) => sum + _toDouble(a['currentBalance'] ?? a['balance']),
        );
  }

  // ─── Map API account to UI format ──────────────────────────────
  Map<String, dynamic> mapAccountToUI(Map<String, dynamic> apiAccount) {
    final backendType = apiAccount['type'] ?? '';
    final frontendType = mapTypeToFrontend(backendType);

    return {
      'id': apiAccount['id'] ?? apiAccount['_id'],
      'code': apiAccount['code'] ?? '',
      'name': apiAccount['name'] ?? '',
      'type': frontendType,
      'backendType': backendType,
      'typeIcon': _getTypeIcon(backendType),
      'typeColor': _getTypeColor(backendType),
      'balance': _toDouble(
        apiAccount['currentBalance'] ?? apiAccount['openingBalance'],
      ),
      'balanceType':
          apiAccount['balanceType'] ??
          (backendType == 'Asset' || backendType == 'Expense'
              ? 'Debit'
              : 'Credit'),
      'description': apiAccount['description'] ?? '',
      'isActive': apiAccount['isActive'] ?? true,
      'parentAccount': apiAccount['parentAccount'] ?? '',
      'taxCode': apiAccount['taxCode'] ?? 'N/A',
    };
  }

  // ─── Get type icon ──────────────────────────────────────────────
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Asset':
        return Icons.account_balance;
      case 'Liability':
        return Icons.payment;
      case 'Equity':
        return Icons.account_balance_wallet;
      case 'Revenue':
        return Icons.trending_up;
      case 'Expense':
        return Icons.trending_down;
      default:
        return Icons.account_balance;
    }
  }

  // ─── Get type color ──────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Asset':
        return const Color(0xFF2ECC71);
      case 'Liability':
        return const Color(0xFFE74C3C);
      case 'Equity':
        return const Color(0xFF3498DB);
      case 'Revenue':
        return const Color(0xFF2ECC71);
      case 'Expense':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF7A8FA6);
    }
  }

  // ─── Check if cash/bank account has incorrect type ──────────────
  bool isIncorrectCashAccount(Map<String, dynamic> account) {
    final name = (account['name'] ?? '').toLowerCase();
    final type = account['backendType'] ?? account['type'] ?? '';
    final isCashOrBank =
        name.contains('cash') ||
        name.contains('bank') ||
        name.contains('money') ||
        name.contains('checking') ||
        name.contains('saving');
    return isCashOrBank && type != 'Asset';
  }

  // ─── Check if opening balance exists ────────────────────────────
  Future<bool> checkOpeningBalanceStatus() async {
    try {
      final response = await _api.get(
        '/api/chart-of-accounts/check-opening-balance',
      );
      if (response.success) {
        final data = response.data;
        hasOpeningBalance.value = data['hasOpeningBalance'] ?? false;
        openingBalanceDetails.value = data;
        return hasOpeningBalance.value;
      }
      return false;
    } catch (e) {
      print('Error checking opening balance: $e');
      return false;
    }
  }

  // ─── Get detailed opening balance information ────────────────────
  Future<Map<String, dynamic>> getOpeningBalanceDetails() async {
    try {
      final response = await _api.get(
        '/api/chart-of-accounts/opening-balance-status',
      );
      if (response.success) {
        return response.data ?? {};
      }
      return {};
    } catch (e) {
      print('Error getting opening balance details: $e');
      return {};
    }
  }
}
