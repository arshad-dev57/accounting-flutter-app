// controllers/journal_entry_controller.dart

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/journalEntries/model/journal_entry_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JournalEntryController extends GetxController {
  // Observables
  var journalEntries = <JournalEntry>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var allEntries = <JournalEntry>[].obs;
  var isSearching = false.obs;

  // Pagination
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMore = true.obs;
  final int pageSize = 10;

  // Summary totals
  var totalDebit = 0.0.obs;
  var totalCredit = 0.0.obs;
  var difference = 0.0.obs;
  var postedCount = 0.obs;
  var draftCount = 0.obs;

  // Accounts for dropdown
  var accounts = <Map<String, dynamic>>[].obs;

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Balance updates
  var lastBalanceUpdates = <BalanceUpdate>[].obs;

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    fetchJournalEntries();
    fetchAccountsForDropdown();
    _setupScrollListener();
    
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        if (hasMore.value && !isLoadingMore.value) {
          loadMoreJournalEntries();
        }
      }
    });
  }

  void _resetAndReload() {
    currentPage.value = 1;
    journalEntries.clear();
    hasMore.value = true;
    fetchJournalEntries();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ─── API Methods ─────────────────────────────────────────────

  Future<void> fetchAccountsForDropdown() async {
    try {
      final response = await _api.get('/api/chart-of-accounts');
      
      if (response.success) {
        accounts.value = List<Map<String, dynamic>>.from(response.data['data']);
      }
    } catch (e) {
      // Silently fail for dropdown
    }
  }

  // ✅ FIXED: fetchJournalEntries with null safety
  Future<void> fetchJournalEntries() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {
        'page': currentPage.value.toString(),
        'limit': pageSize.toString(),
      };

      if (selectedFilter.value != 'All' && selectedFilter.value != 'Custom Range') {
        params['status'] = selectedFilter.value;
      }

      if (selectedDateRange.value != null) {
        params['startDate'] = selectedDateRange.value!.start.toIso8601String();
        params['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      final response = await _api.get('/api/journal-entries', queryParameters: params);

      if (response.success) {
        final data = response.data;
        
        // ✅ SAFE: Handle null data
        final entriesData = data['data'] as List? ?? [];
        final entries = entriesData
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        
        if (currentPage.value == 1) {
          allEntries.value = entries;
        } else {
          allEntries.addAll(entries);
        }
        
        journalEntries.value = entries;

        // ✅ SAFE: Handle null pages
        totalPages.value = data['pages'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;

        // ✅ SAFE: Handle null summary with fallback
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        
        totalDebit.value = _toDouble(summary['totalDebit']);
        totalCredit.value = _toDouble(summary['totalCredit']);
        difference.value = _toDouble(summary['difference']);
        postedCount.value = _toDouble(summary['postedCount']).toInt();
        draftCount.value = _toDouble(summary['draftCount']).toInt();
      } else {
        // ✅ Handle unsuccessful response
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to load entries',
        );
      }
    } catch (e) {
      print('❌ Error fetching journal entries: $e');
      // ✅ Don't show error for empty state - just show empty list
      // AppSnackbar.error(Colors.red, 'Error', 'Failed to load journal entries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ FIXED: loadMoreJournalEntries with null safety
  Future<void> loadMoreJournalEntries() async {
    if (!hasMore.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      Map<String, dynamic> params = {
        'page': currentPage.value.toString(),
        'limit': pageSize.toString(),
      };

      if (selectedFilter.value != 'All' && selectedFilter.value != 'Custom Range') {
        params['status'] = selectedFilter.value;
      }
      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }
      if (selectedDateRange.value != null) {
        params['startDate'] = selectedDateRange.value!.start.toIso8601String();
        params['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      final response = await _api.get('/api/journal-entries', queryParameters: params);

      if (response.success) {
        final data = response.data;
        final entriesData = data['data'] as List? ?? [];
        List<JournalEntry> newEntries = entriesData
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        journalEntries.addAll(newEntries);

        totalPages.value = data['pages'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
      }
    } catch (e) {
      print('❌ Error loading more entries: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── Create Journal Entry ─────────────────────────────────────

  Future<void> createJournalEntry({
    required DateTime date,
    required String description,
    required String reference,
    required List<Map<String, dynamic>> lines,
  }) async {
    final body = {
      'date': date.toIso8601String(),
      'description': description,
      'reference': reference,
      'lines': lines,
    };

    try {
      isLoading.value = true;
      final response = await _api.post('/api/journal-entries', body: body);

      if (response.success) {
        // Store balance updates for display
        if (response.data['balanceUpdates'] != null) {
          lastBalanceUpdates.value = (response.data['balanceUpdates'] as List)
              .map((e) => BalanceUpdate.fromJson(e as Map<String, dynamic>))
              .toList();
          
          _showBalanceUpdateSummary();
        }

        _resetAndReload();
        
        AppSnackbar.success(
          Colors.green,
          'Success ✅',
          'Journal entry posted successfully!',
        );
      } else {
        // Handle balance validation errors
        if (response.data?['errors'] != null) {
          final errors = response.data['errors'] as List;
          _showBalanceErrors(errors);
        } else {
          AppSnackbar.error(
            Colors.red,
            'Error',
            response.message.isNotEmpty ? response.message : 'Failed to create entry',
          );
        }
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to create journal entry: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Delete Journal Entry ─────────────────────────────────────

  Future<void> deleteJournalEntry(String id) async {
    try {
      isLoading.value = true;
      final response = await _api.delete('/api/journal-entries/$id');
      
      if (response.success) {
        _resetAndReload();
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Journal entry deleted and balances reversed',
        );
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to delete',
        );
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to delete: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Show Balance Update Summary ─────────────────────────────

  void _showBalanceUpdateSummary() {
    if (lastBalanceUpdates.isEmpty) return;

    String message = 'Balance Updates:\n';
    for (var update in lastBalanceUpdates) {
      final changeSymbol = update.change >= 0 ? '+' : '';
      message += '${update.account}: ${_formatAmount(update.oldBalance)} → ${_formatAmount(update.newBalance)} '
          '(${changeSymbol}${_formatAmount(update.change)})\n';
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.account_balance, color: kSuccess, size: 24),
            const SizedBox(width: 8),
            const Text('Balance Updated', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lastBalanceUpdates.map((update) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(update.account, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kText)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: update.change >= 0 ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                update.accountType,
                                style: TextStyle(fontSize: 9, color: update.change >= 0 ? kSuccess : kDanger),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Old: ${_formatAmount(update.oldBalance)}', style: TextStyle(fontSize: 12, color: kSubText)),
                            Icon(Icons.arrow_forward, size: 14, color: kSubText),
                            Text('New: ${_formatAmount(update.newBalance)}', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, 
                                    color: update.change >= 0 ? kSuccess : kDanger)),
                            Text('${update.change >= 0 ? '+' : ''}${_formatAmount(update.change)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                    color: update.change >= 0 ? kSuccess : kDanger)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ─── Show Balance Errors ──────────────────────────────────────

  void _showBalanceErrors(List<dynamic> errors) {
    String message = '❌ Insufficient Balance:\n\n';
    for (var error in errors) {
      message += '• $error\n';
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: kDanger, size: 24),
            const SizedBox(width: 8),
            const Text('Balance Validation Failed', style: TextStyle(fontWeight: FontWeight.w700, color: kDanger)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Text(
            message,
            style: TextStyle(fontSize: 13, color: kText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ─── Filtering Methods ───────────────────────────────────────

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    if (filter != 'Custom Range') {
      selectedDateRange.value = null;
    }
    _resetAndReload();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedFilter.value = 'Custom Range';
    }
    _resetAndReload();
  }

  void searchEntries(String query) {
    searchQuery.value = query;
    
    if (query.isEmpty) {
      journalEntries.value = allEntries.value;
    } else {
      final searchLower = query.toLowerCase();
      final results = allEntries.where((entry) {
        return entry.entryNumber.toLowerCase().contains(searchLower) ||
               entry.description.toLowerCase().contains(searchLower) ||
               entry.reference.toLowerCase().contains(searchLower);
      }).toList();
      journalEntries.value = results;
    }
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}