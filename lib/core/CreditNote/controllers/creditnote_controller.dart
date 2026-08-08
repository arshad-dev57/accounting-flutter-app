// core/CreditNote/controllers/creditnote_controller.dart
// COMPLETE CONTROLLER WITH ALL DIALOGS

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'dart:io';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/CreditNote/models/credit_note_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CreditNoteController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  var creditNotes = <CreditNote>[].obs;
  var allCreditNotes = <CreditNote>[].obs;
  var customers = <Customer>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;
  var isLoadingBills = false.obs;
  var currentCustomerId = ''.obs;
  var unpaidInvoices = <InvoiceForCreditNote>[].obs;
  var isCreatingCreditNote = false.obs;
  var isApplyingCreditNote = false.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;
  var serverSupportsPagination = false.obs;

  // Summary totals
  var totalCount = 0.obs;
  var totalAmount = 0.0.obs;
  var appliedAmount = 0.0.obs;
  var remainingAmount = 0.0.obs;
  var expiredAmount = 0.0.obs;
  var thisMonthTotal = 0.0.obs;
  var thisWeekTotal = 0.0.obs;

  // Search & Scroll Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadCreditNotesData(resetPage: true);
    loadCustomers();
    loadSummary();
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
    loadCreditNotesData(resetPage: true);
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  // ─── LOAD CREDIT NOTES WITH PAGINATION ──────────────────────────
  Future<void> loadCreditNotesData({bool resetPage = true}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      Map<String, dynamic> params = {};

      if (serverSupportsPagination.value) {
        params['page'] = currentPage.value;
        params['limit'] = itemsPerPage.value;
      }

      if (selectedFilter.value != 'All' &&
          selectedFilter.value != 'Custom Range') {
        params['status'] = selectedFilter.value;
      }

      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _apiClient.get(
        '/api/credit-notes',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final newNotes = (data['data'] as List)
              .map((j) => CreditNote.fromJson(j))
              .toList();

          if (resetPage) {
            allCreditNotes.value = newNotes;
            creditNotes.value = newNotes;
          } else {
            allCreditNotes.addAll(newNotes);
            creditNotes.addAll(newNotes);
          }

          // Parse pagination info
          if (data['pagination'] != null) {
            final pagination = data['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newNotes.length;
            hasNextPage.value =
                pagination['hasNext'] ??
                pagination['nextPage'] != null ??
                false;
            hasPrevPage.value =
                pagination['hasPrev'] ??
                pagination['prevPage'] != null ??
                false;
            serverSupportsPagination.value = true;
          } else if (data['total'] != null) {
            totalPages.value = data['pages'] ?? 1;
            totalItems.value = data['total'];
            hasNextPage.value = data['hasNext'] ?? false;
            hasPrevPage.value = data['hasPrev'] ?? false;
            serverSupportsPagination.value = true;
          } else if (data['totalCount'] != null) {
            totalItems.value = data['totalCount'];
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          } else {
            totalItems.value = creditNotes.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          _updateSummaryForFiltered(creditNotes.value);
          creditNotes.refresh();
        }
      }
    } catch (e) {
      _showError('Error loading credit notes');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── LOAD MORE DATA (LAZY LOADING) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadCreditNotesData(resetPage: false);
    }
  }

  // ─── LOAD CUSTOMERS ──────────────────────────────────────────────
  Future<void> loadCustomers() async {
    try {
      final response = await _apiClient.get(
        '/api/accounts-receivable/customers',
      );
      if (response.success && response.data['success'] == true) {
        customers.value = (response.data['data'] as List)
            .map((j) => Customer.fromJson(j))
            .toList();
      }
    } catch (e) {
      _showError('Error loading customers');
    }
  }

  // ─── LOAD SUMMARY ──────────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      Map<String, dynamic> params = {};
      if (selectedDateRange.value != null) {
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
      }

      final response = await _apiClient.get(
        '/api/credit-notes/summary',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.data['success'] == true) {
        final d = response.data['data'];
        totalCount.value = d['totalCount'] ?? 0;
        totalAmount.value = (d['totalAmount'] ?? 0).toDouble();
        appliedAmount.value = (d['appliedAmount'] ?? 0).toDouble();
        remainingAmount.value = (d['remainingAmount'] ?? 0).toDouble();
        expiredAmount.value = (d['expiredAmount'] ?? 0).toDouble();
        thisMonthTotal.value = (d['thisMonth'] ?? 0).toDouble();
        thisWeekTotal.value = (d['thisWeek'] ?? 0).toDouble();
      }
    } catch (e) {
      // silent
    }
  }

  void _updateSummaryForFiltered(List<CreditNote> notes) {
    totalCount.value = notes.length;
    totalAmount.value = notes.fold(0.0, (s, n) => s + n.amount);
    appliedAmount.value = notes.fold(0.0, (s, n) => s + n.appliedAmount);
    remainingAmount.value = notes.fold(0.0, (s, n) => s + n.remainingAmount);
    expiredAmount.value = notes
        .where(
          (n) => n.expiryDate != null && n.expiryDate!.isBefore(DateTime.now()),
        )
        .fold(0.0, (s, n) => s + n.remainingAmount);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    thisMonthTotal.value = notes
        .where(
          (n) => n.date.isAfter(monthStart.subtract(const Duration(days: 1))),
        )
        .fold(0.0, (s, n) => s + n.amount);
    thisWeekTotal.value = notes
        .where(
          (n) => n.date.isAfter(weekStart.subtract(const Duration(days: 1))),
        )
        .fold(0.0, (s, n) => s + n.amount);
  }

  // ─── GET INVOICES FOR CREDIT NOTE / APPLY ───────────────────────
  Future<List<InvoiceForCreditNote>> getUnpaidInvoices(
    String customerId, {
    String purpose = 'create',
  }) async {
    try {
      isLoadingBills.value = true;
      currentCustomerId.value = customerId;
      unpaidInvoices.value = [];

      final response = await _apiClient.get(
        '/api/credit-notes/unpaid-invoices/$customerId',
        queryParameters: {'purpose': purpose},
      );

      if (response.success && response.data['success'] == true) {
        unpaidInvoices.value = (response.data['data'] as List)
            .map((j) => InvoiceForCreditNote.fromJson(j))
            .toList();
      }
      return unpaidInvoices.value;
    } catch (e) {
      unpaidInvoices.value = [];
      return [];
    } finally {
      isLoadingBills.value = false;
    }
  }

  // ─── CREATE CREDIT NOTE ──────────────────────────────────────────
  Future<void> createCreditNote({
    required String customerId,
    required String originalInvoiceId,
    required double amount,
    required String reason,
    required String reasonType,
    required List<Map<String, dynamic>> items,
    String? notes,
    int? expiryDays,
  }) async {
    // Show loading dialog
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
                    color: kWarning,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Creating credit note...',
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
      isCreatingCreditNote.value = true;

      final body = {
        'customerId': customerId,
        'originalInvoiceId': originalInvoiceId,
        'amount': amount,
        'reason': reason,
        'reasonType': reasonType,
        'items': items,
        'notes': notes ?? '',
        if (expiryDays != null) 'expiryDays': expiryDays,
      };

      final response = await _apiClient.post('/api/credit-notes', body: body);

      // Close loading dialog
      Get.back();

      if (response.success &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        if (response.data['success'] == true) {
          // Close the main "New Credit Note" form dialog
          if (Get.isDialogOpen ?? false) Get.back();
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Credit note created successfully',
          );
          await loadCreditNotesData(resetPage: true);
          await loadSummary();
        } else {
          _showError(
            response.data['message'] ?? 'Failed to create credit note',
          );
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to create credit note');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Error creating credit note');
    } finally {
      isCreatingCreditNote.value = false;
    }
  }

  // ─── APPLY CREDIT NOTE ──────────────────────────────────────────
  Future<void> applyCreditNote({
    required String creditNoteId,
    required String invoiceId,
    required double amount,
  }) async {
    // Show loading dialog
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
                  'Applying credit note...',
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
      isApplyingCreditNote.value = true;

      final response = await _apiClient.post(
        '/api/credit-notes/apply',
        body: {
          'creditNoteId': creditNoteId,
          'invoiceId': invoiceId,
          'amount': amount,
        },
      );

      // Close loading dialog
      Get.back();

      if (response.success && response.data['success'] == true) {
        // Close the main "Apply Credit Note" form dialog
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success ✅',
          'Credit note applied successfully',
        );
        await loadCreditNotesData(resetPage: true);
        await loadSummary();
      } else {
        _showError(response.data['message'] ?? 'Failed to apply credit note');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Error applying credit note');
    } finally {
      isApplyingCreditNote.value = false;
    }
  }

  // ─── FILTERS ──────────────────────────────────────────────────────
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    if (filter == 'Custom Range') {
      selectDateRange();
    } else {
      selectedDateRange.value = null;
      loadCreditNotesData(resetPage: true);
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
      loadCreditNotesData(resetPage: true);
      loadSummary();
    }
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    selectedFilter.value = 'All';
    loadCreditNotesData(resetPage: true);
    loadSummary();
  }

  // ─── SEARCH ──────────────────────────────────────────────────────
  void searchNotes(String query) {
    searchQuery.value = query;
    loadCreditNotesData(resetPage: true);
  }

  // ─── UI ACTIONS ──────────────────────────────────────────────────
  void viewCreditNoteDetails(CreditNote cn) => _showCreditNoteDetailsDialog(cn);

  void printCreditNote(CreditNote cn) {
    AppSnackbar.info('Print', 'Printing ${cn.creditNoteNumber}');
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE CREDIT NOTE DIALOG
  // ═══════════════════════════════════════════════════════════════

  void showCreateCreditNoteDialog() {
    final formKey = GlobalKey<FormState>();

    // Reactive state
    final selectedCustomerId = ''.obs;
    final selectedInvoiceId = ''.obs;
    final selectedInvoice = Rxn<InvoiceForCreditNote>();
    final selectedReasonType = 'Return'.obs;
    final returnedItems = <String, int>{}.obs; // lineItemId -> return qty
    final computedCreditAmount = 0.0.obs;

    // Controllers
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.92,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: kWarning.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kWarning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.note_add_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Credit Note',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create a credit note for customer',
                            style: TextStyle(fontSize: 12, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: isCreatingCreditNote.value
                          ? null
                          : () {
                              reasonController.dispose();
                              amountController.dispose();
                              notesController.dispose();
                              Get.back();
                            },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => DropdownButtonFormField<String>(
                                  decoration: _inputDecoration(
                                    'Select Customer *',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: kCardBg,
                                  value: selectedCustomerId.value.isEmpty
                                      ? null
                                      : selectedCustomerId.value,
                                  items: customers.map((c) {
                                    return DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) async {
                                    selectedCustomerId.value = val!;
                                    selectedInvoiceId.value = '';
                                    selectedInvoice.value = null;
                                    amountController.clear();
                                    await getUnpaidInvoices(val);
                                  },
                                  validator: (v) =>
                                      v == null ? 'Customer required' : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () =>
                                  Get.toNamed('/sales/warehouse-customers'),
                              icon: Icon(Icons.add, size: 20, color: kPrimary),
                              style: IconButton.styleFrom(
                                backgroundColor: kPrimary.withOpacity(0.1),
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(36, 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Invoice Selection
                        Obx(() {
                          if (selectedCustomerId.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          if (isLoadingBills.value) {
                            return _invoiceLoadingState();
                          }
                          if (unpaidInvoices.isEmpty) {
                            return _noInvoicesState();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Invoice *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...unpaidInvoices.map((inv) {
                                final isSelected =
                                    inv.id == selectedInvoiceId.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimary.withOpacity(0.05)
                                        : kBgLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,

                                        color: isSelected
                                            ? kPrimary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      inv.invoiceNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? kPrimary : kText,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(inv.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kSubText,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${formatAmount(inv.amount)}  •  Paid: ${formatAmount(inv.paidAmount)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kSubText,
                                          ),
                                        ),
                                        Text(
                                          'Credited: ${formatAmount(inv.totalCredited)}  •  Eligible: ${formatAmount(inv.eligibleCredit)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      formatAmount(inv.amount),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kText,
                                      ),
                                    ),
                                    onTap: () {
                                      selectedInvoiceId.value = inv.id;
                                      selectedInvoice.value = inv;
                                      returnedItems.clear();
                                      amountController.text = inv.eligibleCredit
                                          .toStringAsFixed(2);
                                      computedCreditAmount.value =
                                          inv.eligibleCredit;
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        // Invoice summary when selected
                        Obx(() {
                          final inv = selectedInvoice.value;
                          if (inv == null) return const SizedBox.shrink();
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: kPrimary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _invoiceSummaryRow(
                                  'Invoice Total',
                                  formatAmount(inv.amount),
                                ),
                                _invoiceSummaryRow(
                                  'Paid Amount',
                                  formatAmount(inv.paidAmount),
                                ),
                                _invoiceSummaryRow(
                                  'Already Credited',
                                  formatAmount(inv.totalCredited),
                                ),
                                _invoiceSummaryRow(
                                  'Eligible Credit',
                                  formatAmount(inv.eligibleCredit),
                                  bold: true,
                                  color: kPrimary,
                                ),
                                _invoiceSummaryRow(
                                  'Outstanding',
                                  formatAmount(inv.netOutstanding),
                                  color: inv.netOutstanding < 0
                                      ? kSuccess
                                      : kWarning,
                                ),
                              ],
                            ),
                          );
                        }),

                        // Returned goods line item selector
                        Obx(() {
                          final inv = selectedInvoice.value;
                          final isReturn = [
                            'Return',
                            'Damaged Goods',
                          ].contains(selectedReasonType.value);
                          if (inv == null || !isReturn || inv.items.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Returned Items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...inv.items.map((item) {
                                final returnQty = returnedItems[item.id] ?? 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kBgLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Sold: ${item.quantity}  •  ${formatAmount(item.unitPrice)}/unit',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: kSubText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: TextFormField(
                                          initialValue: returnQty > 0
                                              ? '$returnQty'
                                              : '',
                                          decoration: InputDecoration(
                                            labelText: 'Qty',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            final qty = int.tryParse(v) ?? 0;
                                            if (qty <= 0) {
                                              returnedItems.remove(item.id);
                                            } else if (qty <= item.quantity) {
                                              returnedItems[item.id] = qty;
                                            } else {
                                              returnedItems[item.id] =
                                                  item.quantity;
                                            }
                                            // Auto-calculate credit from returned items
                                            double total = 0;
                                            for (final li in inv.items) {
                                              final rq =
                                                  returnedItems[li.id] ?? 0;
                                              if (rq > 0) {
                                                final lineSub =
                                                    li.unitPrice * rq;
                                                final lineDisc =
                                                    (li.discount /
                                                        li.quantity) *
                                                    rq;
                                                final lineTax =
                                                    (li.taxAmount /
                                                        li.quantity) *
                                                    rq;
                                                total +=
                                                    lineSub -
                                                    lineDisc +
                                                    lineTax;
                                              }
                                            }
                                            computedCreditAmount.value = total;
                                            if (total > 0) {
                                              amountController.text = total
                                                  .toStringAsFixed(2);
                                            }
                                            returnedItems.refresh();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        // Reason Type
                        Obx(
                          () => DropdownButtonFormField<String>(
                            value: selectedReasonType.value,
                            decoration: _inputDecoration('Reason Type *'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            dropdownColor: kCardBg,
                            items: const [
                              DropdownMenuItem(
                                value: 'Return',
                                child: Text('Returned Goods'),
                              ),
                              DropdownMenuItem(
                                value: 'Refund',
                                child: Text('Service Refund'),
                              ),
                              DropdownMenuItem(
                                value: 'Discount',
                                child: Text('Discount Allowed'),
                              ),
                              DropdownMenuItem(
                                value: 'Price Adjustment',
                                child: Text('Price Adjustment'),
                              ),
                              DropdownMenuItem(
                                value: 'Damaged Goods',
                                child: Text('Damaged Items'),
                              ),
                            ],
                            onChanged: (v) => selectedReasonType.value = v!,
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reason Description
                        TextFormField(
                          controller: reasonController,
                          decoration: _inputDecoration(
                            'Reason Description *',
                            hint:
                                'e.g. Customer returned 5 units, item damaged',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Reason required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Amount
                        Obx(() {
                          final inv = selectedInvoice.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credit Amount *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              if (inv != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Eligible credit: ${formatAmount(inv.eligibleCredit)}  •  Outstanding: ${formatAmount(inv.netOutstanding)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: amountController,
                                decoration: _inputDecoration('Amount').copyWith(
                                  prefixText: '${CurrencyUtils.prefix} ',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount required';
                                  }
                                  final amt = double.tryParse(v.trim()) ?? 0;
                                  if (amt <= 0) {
                                    return 'Amount must be greater than 0';
                                  }
                                  final inv = selectedInvoice.value;
                                  if (inv != null && amt > inv.eligibleCredit) {
                                    return 'Cannot exceed eligible credit: ${formatAmount(inv.eligibleCredit)}';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: notesController,
                          decoration: _inputDecoration(
                            'Notes',
                            hint: 'Any additional notes...',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isCreatingCreditNote.value
                            ? null
                            : () {
                                reasonController.dispose();
                                amountController.dispose();
                                notesController.dispose();
                                Get.back();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: isCreatingCreditNote.value
                              ? null
                              : () {
                                  if (selectedInvoiceId.value.isEmpty) {
                                    _showError('Please select an invoice');
                                    return;
                                  }
                                  if (formKey.currentState!.validate()) {
                                    final amt =
                                        double.tryParse(
                                          amountController.text.trim(),
                                        ) ??
                                        0;
                                    final inv = selectedInvoice.value;

                                    // Build line items payload
                                    List<Map<String, dynamic>> itemsPayload =
                                        [];
                                    final isReturn = [
                                      'Return',
                                      'Damaged Goods',
                                    ].contains(selectedReasonType.value);

                                    if (isReturn &&
                                        inv != null &&
                                        returnedItems.isNotEmpty) {
                                      for (final li in inv.items) {
                                        final rq = returnedItems[li.id] ?? 0;
                                        if (rq <= 0) continue;
                                        final lineSub = li.unitPrice * rq;
                                        final lineDisc =
                                            (li.discount / li.quantity) * rq;
                                        final lineTax =
                                            (li.taxAmount / li.quantity) * rq;
                                        itemsPayload.add({
                                          'productId': li.productId,
                                          'productName': li.productName,
                                          'description': li.productName,
                                          'quantity': rq,
                                          'unitPrice': li.unitPrice,
                                          'discount': lineDisc,
                                          'taxRate': li.taxRate,
                                          'taxAmount': lineTax,
                                          'amount':
                                              lineSub - lineDisc + lineTax,
                                        });
                                      }
                                    } else {
                                      itemsPayload = [
                                        {
                                          'description': reasonController.text
                                              .trim(),
                                          'quantity': 1,
                                          'unitPrice': amt,
                                          'amount': amt,
                                        },
                                      ];
                                    }

                                    createCreditNote(
                                      customerId: selectedCustomerId.value,
                                      originalInvoiceId:
                                          selectedInvoiceId.value,
                                      amount: amt,
                                      reason: reasonController.text.trim(),
                                      reasonType: selectedReasonType.value,
                                      items: itemsPayload,
                                      notes: notesController.text.trim(),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWarning,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isCreatingCreditNote.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                )
                              : const Text(
                                  'Create Credit Note',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APPLY CREDIT NOTE DIALOG
  // ═══════════════════════════════════════════════════════════════

  void showApplyCreditNoteDialog(CreditNote cn) {
    final formKey = GlobalKey<FormState>();
    final selectedInvoiceId = ''.obs;
    final selectedInvoice = Rxn<InvoiceForCreditNote>();
    final amountController = TextEditingController(
      text: cn.remainingAmount.toStringAsFixed(2),
    );

    // Load invoices with outstanding balance for apply flow
    if (currentCustomerId.value != cn.customerId || unpaidInvoices.isEmpty) {
      getUnpaidInvoices(cn.customerId, purpose: 'apply');
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.85,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kSuccess,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply Credit Note',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cn.creditNoteNumber}  •  ${formatAmount(cn.remainingAmount)} available',
                            style: TextStyle(fontSize: 12, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: isApplyingCreditNote.value
                          ? null
                          : () {
                              amountController.dispose();
                              Get.back();
                            },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoice Selection
                        Obx(() {
                          if (isLoadingBills.value) {
                            return _invoiceLoadingState();
                          }
                          if (unpaidInvoices.isEmpty) {
                            return _noInvoicesState();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Invoice *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...unpaidInvoices.map((inv) {
                                final isSelected =
                                    inv.id == selectedInvoiceId.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimary.withOpacity(0.05)
                                        : kBgLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,

                                        color: isSelected
                                            ? kPrimary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      inv.invoiceNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? kPrimary : kText,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(inv.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kSubText,
                                          ),
                                        ),
                                        Text(
                                          'Outstanding: ${formatAmount(inv.outstanding)}  •  Total: ${formatAmount(inv.amount)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kWarning,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      formatAmount(inv.amount),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kText,
                                      ),
                                    ),
                                    onTap: () {
                                      selectedInvoiceId.value = inv.id;
                                      selectedInvoice.value = inv;
                                      final maxAmt =
                                          inv.outstanding < cn.remainingAmount
                                          ? inv.outstanding
                                          : cn.remainingAmount;
                                      amountController.text = maxAmt
                                          .toStringAsFixed(2);
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        // Amount
                        Obx(() {
                          final inv = selectedInvoice.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount to Apply *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              if (inv != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Invoice outstanding: ${formatAmount(inv.outstanding)}  •  CN available: ${formatAmount(cn.remainingAmount)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: amountController,
                                decoration: _inputDecoration('Amount').copyWith(
                                  prefixText: '${CurrencyUtils.prefix} ',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount required';
                                  }
                                  final amt = double.tryParse(v.trim()) ?? 0;
                                  if (amt <= 0) return 'Must be > 0';
                                  if (amt > cn.remainingAmount) {
                                    return 'Cannot exceed CN remaining: ${formatAmount(cn.remainingAmount)}';
                                  }
                                  final inv = selectedInvoice.value;
                                  if (inv != null && amt > inv.outstanding) {
                                    return 'Cannot exceed invoice outstanding: ${formatAmount(inv.outstanding)}';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isApplyingCreditNote.value
                            ? null
                            : () {
                                amountController.dispose();
                                Get.back();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: isApplyingCreditNote.value
                              ? null
                              : () {
                                  if (selectedInvoiceId.value.isEmpty) {
                                    _showError('Please select an invoice');
                                    return;
                                  }
                                  if (formKey.currentState!.validate()) {
                                    final amt =
                                        double.tryParse(
                                          amountController.text.trim(),
                                        ) ??
                                        0;
                                    applyCreditNote(
                                      creditNoteId: cn.id,
                                      invoiceId: selectedInvoiceId.value,
                                      amount: amt,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isApplyingCreditNote.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CREDIT NOTE DETAILS DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showCreditNoteDetailsDialog(CreditNote cn) {
    final statusColor = cn.status == 'Issued'
        ? kWarning
        : cn.status == 'Applied'
        ? kSuccess
        : kDanger;

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.note_alt_outlined,
                              size: 26,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cn.creditNoteNumber,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: kText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cn.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${DateFormat('dd MMM yyyy').format(cn.date)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // KPI Cards
                      Row(
                        children: [
                          _miniKpi(
                            'Credit',
                            formatAmount(cn.amount),
                            kWarning,
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Applied',
                            formatAmount(cn.appliedAmount),
                            kSuccess,
                            Icons.check_circle,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Remaining',
                            formatAmount(cn.remainingAmount),
                            kPrimary,
                            Icons.pending_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Customer', cn.customerName),
                      _detailRow('Invoice', cn.originalInvoiceNumber),
                      _detailRow(
                        'Invoice Amount',
                        formatAmount(cn.originalInvoiceAmount),
                      ),
                      _detailRow('Reason Type', cn.reasonType),
                      _detailRow('Reason', cn.reason),
                      if (cn.expiryDate != null)
                        _detailRow(
                          'Expiry',
                          DateFormat('dd MMM yyyy').format(cn.expiryDate!),
                          valueColor: cn.expiryDate!.isBefore(DateTime.now())
                              ? kDanger
                              : null,
                        ),
                      if (cn.notes.isNotEmpty) _detailRow('Notes', cn.notes),
                      _detailRow(
                        'Created',
                        DateFormat('dd MMM yyyy, hh:mm a').format(cn.createdAt),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Footer Buttons
                      Row(
                        children: [
                          if (cn.status == 'Issued') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showApplyCreditNoteDialog(cn);
                                  },
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kSuccess,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimary,
                                  side: const BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════

  void exportCreditNotes() {
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
            Row(
              children: [
                Text(
                  'Export Credit Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.black),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${creditNotes.length} notes will be exported',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _exportOptionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    subtitle: 'Formatted report',
                    color: const Color(0xFFE53935),
                    bgColor: const Color(0xFFFFEBEE),
                    onTap: () {
                      Get.back();
                      exportToPdf();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _exportOptionCard(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    subtitle: 'Spreadsheet',
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () {
                      Get.back();
                      exportToExcel();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: kCardBg,
    );
  }

  Widget _exportOptionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PDF EXPORT ──────────────────────────────────────────────────
  Future<void> exportToPdf() async {
    try {
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _pdfHeader(),
          footer: (ctx) => _pdfFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(),
            pw.SizedBox(height: 16),
            _pdfCreditNotesTable(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'credit_notes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        Colors.green,
        'Success',
        '${creditNotes.length} credit notes exported to PDF',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Failed to export PDF: $e');
    }
  }

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
                'Credit Notes Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
              'BisonsTechs',
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
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
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
            'Total Notes',
            totalCount.value.toString(),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'Total Amount',
            formatAmount(totalAmount.value),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'Applied',
            formatAmount(appliedAmount.value),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            'Remaining',
            formatAmount(remainingAmount.value),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'Expired',
            formatAmount(expiredAmount.value),
            PdfColors.red700,
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
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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

  pw.Widget _pdfCreditNotesTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Credit Note Details',
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
                  'CN #',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Customer',
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
                  'Applied',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Remaining',
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
        ...creditNotes
            .map(
              (note) => pw.Container(
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
                        note.creditNoteNumber,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        note.customerName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yy').format(note.date),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(note.amount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(note.appliedAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(note.remainingAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        note.status,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 9),
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
                flex: 7,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(creditNotes.fold(0.0, (s, n) => s + n.amount)),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(
                    creditNotes.fold(0.0, (s, n) => s + n.appliedAmount),
                  ),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(
                    creditNotes.fold(0.0, (s, n) => s + n.remainingAmount),
                  ),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── EXCEL EXPORT ──────────────────────────────────────────────────
  Future<void> exportToExcel() async {
    try {
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

      final workbook = excel.Excel.createExcel();

      // Summary Sheet
      final summarySheet = workbook['Summary'];
      workbook.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Credit Notes Report',
        bold: true,
        fontSize: 14,
        bgColor: '1A237E',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(
        summarySheet,
        1,
        0,
        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
        fontSize: 9,
        fontColor: '757575',
      );
      _excelSetCell(
        summarySheet,
        2,
        0,
        'Filter: ${selectedFilter.value}',
        fontSize: 10,
        fontColor: '1A237E',
      );

      _excelSetCell(
        summarySheet,
        4,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Notes', totalCount.value.toString()],
        ['Total Amount', formatAmount(totalAmount.value)],
        ['Applied Amount', formatAmount(appliedAmount.value)],
        ['Remaining Amount', formatAmount(remainingAmount.value)],
        ['Expired Amount', formatAmount(expiredAmount.value)],
        ['This Month', formatAmount(thisMonthTotal.value)],
        ['This Week', formatAmount(thisWeekTotal.value)],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(
            summarySheet,
            5 + r,
            c,
            summaryRows[r][c],
            bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5',
          );
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Credit Notes Sheet
      final notesSheet = workbook['Credit Notes'];
      final headers = [
        'CN #',
        'Date',
        'Customer',
        'Invoice #',
        'Amount',
        'Applied',
        'Remaining',
        'Reason Type',
        'Status',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          notesSheet,
          0,
          i,
          headers[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int row = 1;
      for (final note in creditNotes) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(notesSheet, row, 0, note.creditNoteNumber, bgColor: bg);
        _excelSetCell(
          notesSheet,
          row,
          1,
          DateFormat('dd MMM yyyy').format(note.date),
          bgColor: bg,
        );
        _excelSetCell(notesSheet, row, 2, note.customerName, bgColor: bg);
        _excelSetCell(
          notesSheet,
          row,
          3,
          note.originalInvoiceNumber,
          bgColor: bg,
        );
        _excelSetCell(notesSheet, row, 4, note.amount, bgColor: bg);
        _excelSetCell(notesSheet, row, 5, note.appliedAmount, bgColor: bg);
        _excelSetCell(notesSheet, row, 6, note.remainingAmount, bgColor: bg);
        _excelSetCell(notesSheet, row, 7, note.reasonType, bgColor: bg);
        _excelSetCell(notesSheet, row, 8, note.status, bgColor: bg);
        _excelSetCell(notesSheet, row, 9, note.notes, bgColor: bg);
        row++;
      }

      final colWidths = [
        15.0,
        12.0,
        25.0,
        15.0,
        15.0,
        15.0,
        15.0,
        18.0,
        12.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        notesSheet.setColumnWidth(i, colWidths[i]);
      }

      workbook.delete('Sheet1');

      final bytes = workbook.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'credit_notes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        Colors.green,
        'Success',
        '${creditNotes.length} credit notes exported to Excel',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Failed to export Excel: $e');
    }
  }

  void _excelSetCell(
    excel.Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool bold = false,
    double fontSize = 10,
    String? bgColor,
    String fontColor = '000000',
  }) {
    final cell = sheet.cell(
      excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value is double
        ? excel.DoubleCellValue(value)
        : value is int
        ? excel.IntCellValue(value)
        : excel.TextCellValue(value.toString());

    cell.cellStyle = excel.CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontColorHex: excel.ExcelColor.fromHexString('#$fontColor'),
      backgroundColorHex: bgColor != null
          ? excel.ExcelColor.fromHexString('#$bgColor')
          : excel.ExcelColor.fromHexString('#FFFFFF'),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: kSubText.withOpacity(0.6), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: kBgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kDanger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: kDanger, width: 1.5),
      ),
    );
  }

  Widget _invoiceLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading invoices...',
            style: TextStyle(fontSize: 12, color: kSubText),
          ),
        ],
      ),
    );
  }

  Widget _noInvoicesState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 18,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'No invoices eligible for credit note',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Get.toNamed('/warehouse/invoices'),
            icon: Icon(Icons.add, size: 20, color: kPrimary),
            style: IconButton.styleFrom(
              backgroundColor: kPrimary.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceSummaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? kText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────
  void _showError(String msg) => AppSnackbar.error(kDanger, 'Error', msg);
}
