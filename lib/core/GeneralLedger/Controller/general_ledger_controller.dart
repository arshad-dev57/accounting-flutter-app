// core/GeneralLedger/Controller/general_ledger_controller.dart

import 'dart:async';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
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

  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;

  var accountsForDropdown = <Map<String, dynamic>>[].obs;

  var showOnlyDebit = false.obs;
  var showOnlyCredit = false.obs;

  var totalDebitSummary = 0.0.obs;
  var totalCreditSummary = 0.0.obs;
  var netDifferenceSummary = 0.0.obs;
  var isBalancedSummary = true.obs;
  var trialBalanceStatus = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();
  Timer? _searchDebounce;

  List<LedgerEntry> get filteredLedgerEntries => ledgerEntries.toList();

  bool get isAllAccountsSelected => selectedAccount.value == 'All Accounts';

  double get selectedAccountClosingBalance {
    if (isAllAccountsSelected) return 0;
    final match = accountSummaries.where(
      (a) => a.accountName == selectedAccount.value,
    );
    if (match.isEmpty) return 0;
    return match.first.closingBalance;
  }
  Map<String, dynamic> _unwrapPayload(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final map = Map<String, dynamic>.from(raw);
    final inner = map['data'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return map;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final nested =
          raw['data'] ?? raw['entries'] ?? raw['items'] ?? raw['accounts'] ?? raw['transactions'];
      if (nested is List) return nested;
    }
    return const [];
  }

  void _applySummary(Map<String, dynamic>? summary) {
    if (summary == null) return;
    totalDebitSummary.value = _toDouble(summary['totalDebit']);
    totalCreditSummary.value = _toDouble(summary['totalCredit']);
    netDifferenceSummary.value = _toDouble(
      summary['netDifference'] ?? summary['difference'] ?? 0,
    );
    isBalancedSummary.value = summary['isBalanced'] ?? true;
    trialBalanceStatus.value =
        summary['status']?.toString() ??
        (isBalancedSummary.value ? '✅ Balanced' : '⚠️ Not Balanced');
  }

  void _applyPagination(Map<String, dynamic>? pagination, {int fallbackCount = 0}) {
    if (pagination == null) {
      // If API omitted pagination, assume single page of what we got
      if (fallbackCount > 0 && totalItems.value == 0) {
        totalItems.value = fallbackCount;
        totalPages.value = 1;
        hasNextPage.value = false;
        hasPrevPage.value = false;
      }
      return;
    }
    totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
    totalItems.value = (pagination['total'] as num?)?.toInt() ?? 0;
    hasNextPage.value = pagination['hasNext'] == true;
    hasPrevPage.value = pagination['hasPrev'] == true;
    final pageFromApi = (pagination['page'] as num?)?.toInt();
    if (pageFromApi != null && pageFromApi > 0) {
      currentPage.value = pageFromApi;
    }
  }

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
    _searchDebounce?.cancel();
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
        final outer = response.data;
        final list = _extractList(
          outer is Map ? (outer['data'] ?? outer) : outer,
        );

        accountSummaries.value =
            list.map((e) => AccountSummary.fromJson(Map<String, dynamic>.from(e))).toList();
        accountsForDropdown.value = list
            .map(
              (e) => {
                'accountId': e['accountId'],
                'accountName': e['accountName'],
                'accountCode': e['accountCode'],
              },
            )
            .toList();

        final payload = _unwrapPayload(outer);
        final summary = payload['summary'];
        if (summary is Map) {
          _applySummary(Map<String, dynamic>.from(summary));
        } else if (outer is Map && outer['summary'] is Map) {
          _applySummary(Map<String, dynamic>.from(outer['summary']));
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

  Future<void> fetchLedgerEntries({
    bool resetPage = true,
    bool append = false,
  }) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading(true);
      } else if (append) {
        isLoadingMore(true);
      } else {
        isLoading(true);
      }

      const endpoint = '/api/general-ledger/all-entries';
      final queryParams = <String, dynamic>{
        'page': currentPage.value.toString(),
        'limit': itemsPerPage.value.toString(),
        'sortBy': 'date',
        'sortOrder': 'desc',
      };

      if (selectedAccount.value != 'All Accounts') {
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
        queryParams['accountId'] = selected.accountId;
      }

      if (selectedDateRange.value != null) {
        queryParams['startDate'] =
            selectedDateRange.value!.start.toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }
      putFiscalYearId(queryParams);

      if (searchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.value.trim();
      }
      if (showOnlyDebit.value) queryParams['showDebitOnly'] = 'true';
      if (showOnlyCredit.value) queryParams['showCreditOnly'] = 'true';

      final response = await _api.get(endpoint, queryParameters: queryParams);

      if (response.success) {
        final outer = response.data;
        final payload = _unwrapPayload(outer);
        final list = _extractList(
          payload.containsKey('data') || payload.containsKey('entries')
              ? payload
              : (outer is Map ? outer['data'] : outer),
        );

        final entries = list
            .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final pagination = payload['pagination'];
        _applyPagination(
          pagination is Map ? Map<String, dynamic>.from(pagination) : null,
          fallbackCount: entries.length,
        );

        // Prefer entries-response summary (full filtered set); keep prior if absent
        final summary = payload['summary'];
        if (summary is Map) {
          _applySummary(Map<String, dynamic>.from(summary));
        }

        if (append) {
          allLedgerEntries.addAll(entries);
          ledgerEntries.addAll(entries);
        } else {
          allLedgerEntries.value = entries;
          ledgerEntries.value = entries;
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

  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchLedgerEntries(resetPage: false, append: false);
    }
  }

  Future<void> loadPreviousPage() async {
    if (hasPrevPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value--;
      await fetchLedgerEntries(resetPage: false, append: false);
    }
  }

  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchLedgerEntries(resetPage: false, append: true);
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchLedgerEntries(resetPage: true);
    });
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

  // ─── Get summary for current view (API totals — matches Next.js) ───
  Map<String, dynamic> getCurrentSummary() {
    return {
      'totalDebit': totalDebitSummary.value,
      'totalCredit': totalCreditSummary.value,
      'netDifference': netDifferenceSummary.value,
      'isBalanced': isBalancedSummary.value,
      'entryCount': totalItems.value,
      'isAllAccounts': isAllAccountsSelected,
    };
  }
}

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
