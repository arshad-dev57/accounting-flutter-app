// core/GeneralLedger/Controller/general_ledger_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeneralLedgerController extends GetxController {
  var accountSummaries = <AccountSummary>[].obs;
  var allLedgerEntries = <LedgerEntry>[].obs;
  var ledgerEntries = <LedgerEntry>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var selectedAccount = 'All Accounts'.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var searchQuery = ''.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;

  // For dropdown accounts
  var accountsForDropdown = <Map<String, dynamic>>[].obs;

  // Filter variables
  var showOnlyDebit = false.obs;
  var showOnlyCredit = false.obs;

  // Summary totals from API
  var totalDebitSummary = 0.0.obs;
  var totalCreditSummary = 0.0.obs;
  var netDifferenceSummary = 0.0.obs;
  var isBalancedSummary = true.obs;
  var trialBalanceStatus = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();

  // Computed filtered entries
  List<LedgerEntry> get filteredLedgerEntries {
    List<LedgerEntry> filtered = ledgerEntries.toList();

    if (showOnlyDebit.value) {
      filtered = filtered.where((e) => e.debit > 0).toList();
    } else if (showOnlyCredit.value) {
      filtered = filtered.where((e) => e.credit > 0).toList();
    }

    return filtered;
  }

  // Check if All Accounts is selected
  bool get isAllAccountsSelected => selectedAccount.value == 'All Accounts';

  void toggleDebitFilter() {
    if (showOnlyDebit.value) {
      showOnlyDebit.value = false;
    } else {
      showOnlyDebit.value = true;
      showOnlyCredit.value = false;
    }
    fetchLedgerEntries(resetPage: true);
  }

  void toggleCreditFilter() {
    if (showOnlyCredit.value) {
      showOnlyCredit.value = false;
    } else {
      showOnlyCredit.value = true;
      showOnlyDebit.value = false;
    }
    fetchLedgerEntries(resetPage: true);
  }

  void clearFilters() {
    showOnlyDebit.value = false;
    showOnlyCredit.value = false;
    fetchLedgerEntries(resetPage: true);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    Future(() async {
      await waitForFiscalYearReady();
      fetchAccountSummaries();
      fetchLedgerEntries();
    });
    _fyWorker = listenFiscalYearChanges(() {
      fetchAccountSummaries();
      fetchLedgerEntries();
    });
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    super.onClose();
  }

  // Fetch account summaries for cards and dropdown
  Future<void> fetchAccountSummaries() async {
    try {
      isLoading(true);

      Map<String, dynamic> queryParams = {};

      if (selectedDateRange.value != null) {
        queryParams['startDate'] = selectedDateRange.value!.start
            .toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }
      putFiscalYearId(queryParams);

      final response = await _api.get(
        '/api/general-ledger/accounts',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success) {
        final data = response.data;
        print('📊 API Response structure: ${data.runtimeType}');
        print('📊 Full response keys: ${data.keys}');
        print('📊 Data field: ${data['data']}');
        print('📊 Data field type: ${data['data'].runtimeType}');

        // Handle data field - could be List or Map
        final dataList = data['data'];
        if (dataList is List) {
          print('✅ Data is a List with ${dataList.length} items');
          accountSummaries.value = dataList
              .map((e) => AccountSummary.fromJson(e))
              .toList();

          accountsForDropdown.value = dataList
              .map(
                (e) => {
                  'accountId': e['accountId'],
                  'accountName': e['accountName'],
                  'accountCode': e['accountCode'],
                },
              )
              .toList();
          print('✅ Parsed ${accountSummaries.length} account summaries');
        } else if (dataList is Map) {
          print('⚠️ Data is a Map, looking for nested list...');
          // Handle nested structure: {count, data: [...], summary}
          final nestedList = dataList['data'];
          if (nestedList is List) {
            print(
              '✅ Found nested list in data.data with ${nestedList.length} items',
            );
            accountSummaries.value = nestedList
                .map((e) => AccountSummary.fromJson(e))
                .toList();
            accountsForDropdown.value = nestedList
                .map(
                  (e) => {
                    'accountId': e['accountId'],
                    'accountName': e['accountName'],
                    'accountCode': e['accountCode'],
                  },
                )
                .toList();
          } else {
            // Try other common keys
            final altList =
                dataList['entries'] ??
                dataList['items'] ??
                dataList['accounts'];
            if (altList is List) {
              print('✅ Found nested list with ${altList.length} items');
              accountSummaries.value = altList
                  .map((e) => AccountSummary.fromJson(e))
                  .toList();
              accountsForDropdown.value = altList
                  .map(
                    (e) => {
                      'accountId': e['accountId'],
                      'accountName': e['accountName'],
                      'accountCode': e['accountCode'],
                    },
                  )
                  .toList();
            } else {
              print('❌ No nested list found in Map');
              accountSummaries.value = [];
              accountsForDropdown.value = [];
            }
          }
        } else {
          print(
            '⚠️ API returned non-List data for accounts: ${dataList.runtimeType}',
          );
          accountSummaries.value = [];
          accountsForDropdown.value = [];
        }

        // ─── Update summary totals from API ──────────────────────
        if (data['summary'] != null) {
          final summary = data['summary'];
          totalDebitSummary.value = _toDouble(summary['totalDebit']);
          totalCreditSummary.value = _toDouble(summary['totalCredit']);
          netDifferenceSummary.value = _toDouble(summary['netDifference'] ?? 0);
          isBalancedSummary.value = summary['isBalanced'] ?? true;
          trialBalanceStatus.value =
              summary['status'] ??
              (isBalancedSummary.value ? '✅ Balanced' : '⚠️ Not Balanced');
        }
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          'Failed to load account summaries',
        );
      }
    } catch (e) {
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to load account summaries: $e',
      );
    } finally {
      isLoading(false);
    }
  }

  // Fetch ledger entries with pagination
  Future<void> fetchLedgerEntries({bool resetPage = true}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading(true);
      } else {
        isLoadingMore(true);
      }

      String endpoint;
      Map<String, dynamic> queryParams = {};

      // Build endpoint based on account selection
      if (selectedAccount.value == 'All Accounts') {
        endpoint = '/api/general-ledger/all-entries';
      } else {
        final selected = accountSummaries.firstWhere(
          (a) => a.accountName == selectedAccount.value,
          orElse: () => AccountSummary(
            accountId: '',
            accountCode: '',
            accountName: '',
            accountType: '',
            openingBalance: 0,
            totalDebit: 0,
            totalCredit: 0,
            closingBalance: 0,
          ),
        );

        if (selected.accountId.isEmpty) {
          isLoading(false);
          isLoadingMore(false);
          return;
        }

        endpoint = '/api/general-ledger/entries/${selected.accountId}';
      }

      // Add pagination params
      queryParams['page'] = currentPage.value.toString();
      queryParams['limit'] = itemsPerPage.value.toString();

      // Add date range filter
      if (selectedDateRange.value != null) {
        queryParams['startDate'] = selectedDateRange.value!.start
            .toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }
      putFiscalYearId(queryParams);

      // Add sorting
      queryParams['sortBy'] = 'date';
      queryParams['sortOrder'] = 'desc';

      final response = await _api.get(endpoint, queryParameters: queryParams);

      if (response.success) {
        final data = response.data;
        print('📊 Ledger API Response structure: ${data.runtimeType}');
        print('📊 Full response keys: ${data.keys}');
        print('📊 Data field: ${data['data']}');
        print('📊 Data field type: ${data['data'].runtimeType}');

        // Handle data field - could be List or Map
        final dataList = data['data'];
        List<LedgerEntry> entries = [];

        if (dataList is List) {
          print('✅ Data is a List with ${dataList.length} items');
          entries = dataList.map((e) => LedgerEntry.fromJson(e)).toList();
          print('✅ Parsed ${entries.length} ledger entries');
        } else if (dataList is Map) {
          print('⚠️ Data is a Map, looking for nested list...');
          // Handle nested structure: {count, data: [...], summary}
          final nestedList = dataList['data'];
          if (nestedList is List) {
            print(
              '✅ Found nested list in data.data with ${nestedList.length} items',
            );
            entries = nestedList.map((e) => LedgerEntry.fromJson(e)).toList();
          } else {
            // Try other common keys
            final altList =
                dataList['entries'] ??
                dataList['items'] ??
                dataList['transactions'];
            if (altList is List) {
              print('✅ Found nested list with ${altList.length} items');
              entries = altList.map((e) => LedgerEntry.fromJson(e)).toList();
            } else {
              print('❌ No nested list found in Map');
            }
          }
        } else {
          print(
            '⚠️ API returned non-List data for ledger entries: ${dataList.runtimeType}',
          );
          print('📋 Response data structure: $data');
        }

        // Update pagination info
        if (data['pagination'] != null) {
          totalPages.value = data['pagination']['pages'] ?? 1;
          totalItems.value = data['pagination']['total'] ?? 0;
          hasNextPage.value = data['pagination']['hasNext'] ?? false;
          hasPrevPage.value = data['pagination']['hasPrev'] ?? false;
        }

        // Update summary from response
        if (data['summary'] != null) {
          final summary = data['summary'];
          totalDebitSummary.value = _toDouble(summary['totalDebit'] ?? 0);
          totalCreditSummary.value = _toDouble(summary['totalCredit'] ?? 0);
          netDifferenceSummary.value = _toDouble(summary['netDifference'] ?? 0);
          isBalancedSummary.value = summary['isBalanced'] ?? true;
          trialBalanceStatus.value = isBalancedSummary.value
              ? '✅ Balanced'
              : '⚠️ Not Balanced';
        }

        if (resetPage) {
          allLedgerEntries.value = entries;
          if (searchQuery.value.isNotEmpty) {
            searchEntries(searchQuery.value);
          } else {
            ledgerEntries.value = entries;
          }
        } else {
          allLedgerEntries.addAll(entries);
          if (searchQuery.value.isNotEmpty) {
            searchEntries(searchQuery.value);
          } else {
            ledgerEntries.addAll(entries);
          }
        }
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to load entries',
        );
      }
    } catch (e) {
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to load ledger entries: $e',
      );
    } finally {
      isLoading(false);
      isLoadingMore(false);
    }
  }

  // Load next page for web pagination
  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchLedgerEntries(resetPage: false);
    }
  }

  // Load previous page for web pagination
  Future<void> loadPreviousPage() async {
    if (hasPrevPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value--;
      await fetchLedgerEntries(resetPage: false);
    }
  }

  // Load more data for mobile lazy loading
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchLedgerEntries(resetPage: false);
    }
  }

  // Combined fetch (both summaries and entries)
  Future<void> refreshData() async {
    await fetchAccountSummaries();
    await fetchLedgerEntries(resetPage: true);
  }

  // Filter methods
  void changeAccount(String account) {
    selectedAccount.value = account;
    fetchLedgerEntries(resetPage: true);
    fetchAccountSummaries();
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    if (filter != 'Custom Range') {
      selectedDateRange.value = null;
      _applyDateFilter(filter);
    }
    fetchLedgerEntries(resetPage: true);
    fetchAccountSummaries();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedFilter.value = 'Custom Range';
    }
    fetchLedgerEntries(resetPage: true);
    fetchAccountSummaries();
  }

  void searchEntries(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      ledgerEntries.value = allLedgerEntries.value;
    } else {
      final searchLower = query.toLowerCase();
      final results = allLedgerEntries.where((entry) {
        return entry.description.toLowerCase().contains(searchLower) ||
            entry.reference.toLowerCase().contains(searchLower) ||
            entry.accountName.toLowerCase().contains(searchLower) ||
            entry.accountCode.toLowerCase().contains(searchLower);
      }).toList();
      ledgerEntries.value = results;
    }
  }

  void _applyDateFilter(String filter) {
    final now = DateTime.now();
    DateTime start;

    switch (filter) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        selectedDateRange.value = DateTimeRange(start: start, end: now);
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        selectedDateRange.value = DateTimeRange(start: start, end: now);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        selectedDateRange.value = DateTimeRange(start: start, end: now);
        break;
      case 'This Quarter':
        int quarter = ((now.month - 1) / 3).floor();
        start = DateTime(now.year, quarter * 3 + 1, 1);
        selectedDateRange.value = DateTimeRange(start: start, end: now);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        selectedDateRange.value = DateTimeRange(start: start, end: now);
        break;
      default:
        selectedDateRange.value = null;
    }
  }

  // Export functions
  void exportLedger() {
    AppSnackbar.success(
      kPrimary,
      'Export',
      'Exporting General Ledger to Excel...',
    );
  }

  void printLedger() {
    AppSnackbar.success(
      kPrimary,
      'Print',
      'Preparing General Ledger for printing...',
    );
  }

  // ─── Get summary for current view ──────────────────────────────
  Map<String, dynamic> getCurrentSummary() {
    final entries = filteredLedgerEntries;
    final totalDebit = entries.fold(0.0, (sum, e) => sum + e.debit);
    final totalCredit = entries.fold(0.0, (sum, e) => sum + e.credit);
    final netDifference = totalDebit - totalCredit;
    final isBalanced = netDifference.abs() < 0.01;

    return {
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
      'netDifference': netDifference,
      'isBalanced': isBalanced,
      'entryCount': entries.length,
      'isAllAccounts': isAllAccountsSelected,
    };
  }
}

// ─── ACCOUNT SUMMARY MODEL ─────────────────────────────────────────
class AccountSummary {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final bool hasOpeningBalanceEntry;

  AccountSummary({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    this.hasOpeningBalanceEntry = false,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    return AccountSummary(
      accountId: json['accountId'] ?? '',
      accountCode: json['accountCode'] ?? '',
      accountName: json['accountName'] ?? '',
      accountType: json['accountType'] ?? '',
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      totalDebit: (json['totalDebit'] ?? 0).toDouble(),
      totalCredit: (json['totalCredit'] ?? 0).toDouble(),
      closingBalance: (json['closingBalance'] ?? 0).toDouble(),
      hasOpeningBalanceEntry: json['hasOpeningBalanceEntry'] ?? false,
    );
  }
}

// ─── LEDGER ENTRY MODEL ────────────────────────────────────────────
class LedgerEntry {
  final String id;
  final DateTime date;
  final String accountId;
  final String accountName;
  final String accountCode;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  final String reference;
  final bool isOpeningBalance;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.reference,
    this.isOpeningBalance = false,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      accountId: json['accountId'] ?? '',
      accountName: json['accountName'] ?? '',
      accountCode: json['accountCode'] ?? '',
      description: json['description'] ?? '',
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      reference: json['reference'] ?? '',
      isOpeningBalance: json['isOpeningBalance'] ?? false,
    );
  }
}
