import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/CreditNote/models/credit_note_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;

class CreditNoteController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  var creditNotes = <CreditNote>[].obs;
  var allCreditNotes = <CreditNote>[].obs;
  var customers = <Customer>[].obs;
  var isLoading = true.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;
  var isLoadingBills = false.obs;
  var currentCustomerId = ''.obs;
  var unpaidInvoices = <InvoiceForCreditNote>[].obs;
  var isCreatingCreditNote = false.obs;
  var isApplyingCreditNote = false.obs;

  var totalCount = 0.obs;
  var totalAmount = 0.0.obs;
  var appliedAmount = 0.0.obs;
  var remainingAmount = 0.0.obs;
  var expiredAmount = 0.0.obs;
  var thisMonthTotal = 0.0.obs;
  var thisWeekTotal = 0.0.obs;

  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadCreditNotesData();
    loadCustomers();
    loadSummary();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    if (searchQuery.value.isEmpty) {
      creditNotes.value = allCreditNotes.value;
      _updateSummaryForFiltered(allCreditNotes.value);
    } else {
      final q = searchQuery.value.toLowerCase();
      final results = allCreditNotes.where((n) {
        return n.creditNoteNumber.toLowerCase().contains(q) ||
            n.customerName.toLowerCase().contains(q) ||
            n.reason.toLowerCase().contains(q) ||
            n.reasonType.toLowerCase().contains(q) ||
            n.originalInvoiceNumber.toLowerCase().contains(q);
      }).toList();
      creditNotes.value = results;
      _updateSummaryForFiltered(results);
    }
  }

  void _updateSummaryForFiltered(List<CreditNote> notes) {
    totalCount.value = notes.length;
    totalAmount.value = notes.fold(0.0, (s, n) => s + n.amount);
    appliedAmount.value = notes.fold(0.0, (s, n) => s + n.appliedAmount);
    remainingAmount.value = notes.fold(0.0, (s, n) => s + n.remainingAmount);
    expiredAmount.value = notes
        .where((n) =>
            n.expiryDate != null && n.expiryDate!.isBefore(DateTime.now()))
        .fold(0.0, (s, n) => s + n.remainingAmount);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    thisMonthTotal.value = notes
        .where((n) => n.date.isAfter(monthStart.subtract(const Duration(days: 1))))
        .fold(0.0, (s, n) => s + n.amount);
    thisWeekTotal.value = notes
        .where((n) => n.date.isAfter(weekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (s, n) => s + n.amount);
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  // ============================================================
  // API CALLS
  // ============================================================

  Future<void> loadCreditNotesData() async {
    try {
      isLoading.value = true;
      final Map<String, dynamic> params = {};
      if (selectedFilter.value != 'All' &&
          selectedFilter.value != 'Custom Range') {
        params['status'] = selectedFilter.value;
      }
      if (selectedDateRange.value != null) {
        params['startDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start);
        params['endDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end);
      }

      final response = await _apiClient.get(
        '/api/credit-notes',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final notes = (data['data'] as List)
              .map((j) => CreditNote.fromJson(j))
              .toList();
          allCreditNotes.value = notes;
          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            creditNotes.value = notes;
          }
        }
      }
    } catch (e) {
      _showError('Error loading credit notes');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCustomers() async {
    try {
      final response =
          await _apiClient.get('/api/accounts-receivable/customers');
      if (response.success && response.data['success'] == true) {
        customers.value = (response.data['data'] as List)
            .map((j) => Customer.fromJson(j))
            .toList();
      }
    } catch (e) {
      _showError('Error loading customers');
    }
  }

  Future<void> loadSummary() async {
    try {
      final Map<String, dynamic> params = {};
      if (selectedDateRange.value != null) {
        params['startDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start);
        params['endDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end);
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

  Future<List<InvoiceForCreditNote>> getUnpaidInvoices(
      String customerId) async {
    try {
      isLoadingBills.value = true;
      currentCustomerId.value = customerId;
      unpaidInvoices.value = [];

      final response = await _apiClient.get(
        '/api/credit-notes/unpaid-invoices/$customerId',
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

      if (response.success &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        if (response.data['success'] == true) {
          Get.back();
          AppSnackbar.success(
            kSuccess,
            'Success',
            'Credit note created successfully',
          );
          await loadCreditNotesData();
          await loadSummary();
        } else {
          _showError(
              response.data['message'] ?? 'Failed to create credit note');
        }
      } else {
        _showError(
            response.data['message'] ?? 'Failed to create credit note');
      }
    } catch (e) {
      _showError('Error creating credit note');
    } finally {
      isCreatingCreditNote.value = false;
    }
  }

  Future<void> applyCreditNote({
    required String creditNoteId,
    required String invoiceId,
    required double amount,
  }) async {
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

      if (response.success && response.data['success'] == true) {
        Get.back();
        AppSnackbar.success(kSuccess, 'Success', 'Credit note applied');
        await loadCreditNotesData();
        await loadSummary();
      } else {
        _showError(
            response.data['message'] ?? 'Failed to apply credit note');
      }
    } catch (e) {
      _showError('Error applying credit note');
    } finally {
      isApplyingCreditNote.value = false;
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  void applyDateFilter(String filter) {
    selectedFilter.value = filter;
    if (filter == 'Custom Range') {
      selectDateRange();
    } else {
      selectedDateRange.value = null;
      loadCreditNotesData();
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
      loadCreditNotesData();
      loadSummary();
    }
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    selectedFilter.value = 'All';
    loadCreditNotesData();
    loadSummary();
  }

  // ============================================================
  // UI ACTIONS
  // ============================================================

  void viewCreditNoteDetails(CreditNote cn) =>
      _showCreditNoteDetailsDialog(cn);

  void printCreditNote(CreditNote cn) {
    AppSnackbar.info('Print', 'Printing ${cn.creditNoteNumber}');
  }

  // ============================================================
  // CREATE CREDIT NOTE DIALOG
  // ============================================================

  void showCreateCreditNoteDialog() {
    final formKey = GlobalKey<FormState>();

    // Reactive state
    final selectedCustomerId = ''.obs;
    final selectedInvoiceId = ''.obs;
    final selectedInvoice = Rxn<InvoiceForCreditNote>();
    final selectedReasonType = 'Return'.obs;

    // Controllers — needed so amount field updates when invoice changes
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 90.h),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.note_add_outlined,
                      size: 18,
                      color: kWarning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Credit Note',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close, size: 16, color: kSubText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Step 1: Customer ────────────────────
                        _stepLabel('1', 'Select Customer'),
                        const SizedBox(height: 8),
                        Obx(() => DropdownButtonFormField<String>(
                              decoration:
                                  _inputDeco('Select customer'),
                              style: TextStyle(
                                  fontSize: 13.sp, color: kText),
                              dropdownColor: kCardBg,
                              value: selectedCustomerId.value.isEmpty
                                  ? null
                                  : selectedCustomerId.value,
                              items: customers.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      overflow: TextOverflow.ellipsis),
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
                            )),
                        const SizedBox(height: 16),

                        // ── Step 2: Invoice ─────────────────────
                        Obx(() {
                          if (selectedCustomerId.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _stepLabel('2', 'Select Invoice'),
                              const SizedBox(height: 8),
                              Obx(() {
                                if (isLoadingBills.value) {
                                  return _invoiceLoadingState();
                                }
                                if (unpaidInvoices.isEmpty) {
                                  return _noInvoicesState();
                                }
                                return _buildInvoiceList(
                                  invoices: unpaidInvoices,
                                  selectedId: selectedInvoiceId,
                                  onSelect: (inv) {
                                    selectedInvoiceId.value = inv.id;
                                    selectedInvoice.value = inv;
                                    // Pre-fill amount with full outstanding
                                    amountController.text =
                                        inv.outstanding.toStringAsFixed(2);
                                  },
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        // ── Step 3: Reason type ─────────────────
                        _stepLabel('3', 'Reason Type'),
                        const SizedBox(height: 8),
                        Obx(() => DropdownButtonFormField<String>(
                              value: selectedReasonType.value,
                              decoration: _inputDeco(''),
                              style: TextStyle(
                                  fontSize: 13.sp, color: kText),
                              dropdownColor: kCardBg,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Return',
                                    child: Text('Returned Goods')),
                                DropdownMenuItem(
                                    value: 'Refund',
                                    child: Text('Service Refund')),
                                DropdownMenuItem(
                                    value: 'Discount',
                                    child: Text('Discount Allowed')),
                                DropdownMenuItem(
                                    value: 'Price Adjustment',
                                    child: Text('Price Adjustment')),
                                DropdownMenuItem(
                                    value: 'Damaged Goods',
                                    child: Text('Damaged Items')),
                              ],
                              onChanged: (v) =>
                                  selectedReasonType.value = v!,
                            )),
                        const SizedBox(height: 16),

                        // ── Step 4: Reason description ──────────
                        _stepLabel('4', 'Reason Description'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: reasonController,
                          decoration: _inputDeco(
                              'e.g. Customer returned 5 units, item damaged'),
                          style:
                              TextStyle(fontSize: 13.sp, color: kText),
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Reason required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ── Step 5: Credit amount ───────────────
                        Obx(() {
                          final inv = selectedInvoice.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _stepLabel('5', 'Credit Amount'),
                              if (inv != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Invoice: ${formatAmount(inv.amount)}  •  Outstanding: ${formatAmount(inv.outstanding)}',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: amountController,
                                decoration: _inputDeco('0.00')
                                    .copyWith(prefixText: 'Rs. '),
                                style: TextStyle(
                                    fontSize: 13.sp, color: kText),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount required';
                                  }
                                  final amt =
                                      double.tryParse(v.trim()) ?? 0;
                                  if (amt <= 0) {
                                    return 'Amount must be greater than 0';
                                  }
                                  final inv = selectedInvoice.value;
                                  if (inv != null &&
                                      amt > inv.outstanding) {
                                    return 'Cannot exceed outstanding: ${formatAmount(inv.outstanding)}';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 16),

                        // ── Notes (optional) ────────────────────
                        _stepLabel('6', 'Notes (optional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: notesController,
                          decoration:
                              _inputDeco('Any additional notes...'),
                          style:
                              TextStyle(fontSize: 13.sp, color: kText),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Footer buttons ────────────────────────────────
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCreatingCreditNote.value
                              ? null
                              : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13.sp, color: kSubText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCreatingCreditNote.value
                              ? null
                              : () {
                                  // Validate invoice selected
                                  if (selectedInvoiceId.value.isEmpty) {
                                    _showError(
                                        'Please select an invoice');
                                    return;
                                  }
                                  if (formKey.currentState!.validate()) {
                                    final amt = double.tryParse(
                                            amountController.text
                                                .trim()) ??
                                        0;
                                    createCreditNote(
                                      customerId:
                                          selectedCustomerId.value,
                                      originalInvoiceId:
                                          selectedInvoiceId.value,
                                      amount: amt,
                                      reason: reasonController.text.trim(),
                                      reasonType:
                                          selectedReasonType.value,
                                      items: [
                                        {
                                          'description':
                                              reasonController.text
                                                  .trim(),
                                          'quantity': 1,
                                          'unitPrice': amt,
                                          'amount': amt,
                                        }
                                      ],
                                      notes: notesController.text.trim(),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWarning,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isCreatingCreditNote.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text('Create Credit Note',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // APPLY CREDIT NOTE DIALOG
  // ============================================================

  void showApplyCreditNoteDialog(CreditNote cn) {
    final formKey = GlobalKey<FormState>();
    final selectedInvoiceId = ''.obs;
    final selectedInvoice = Rxn<InvoiceForCreditNote>();
    final amountController =
        TextEditingController(text: cn.remainingAmount.toStringAsFixed(2));

    // Load invoices for this customer if not already loaded
    if (currentCustomerId.value != cn.customerId ||
        unpaidInvoices.isEmpty) {
      getUnpaidInvoices(cn.customerId);
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 80.h),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.check_circle_outline,
                        size: 18, color: kSuccess),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Credit Note',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: kText),
                        ),
                        Text(
                          '${cn.creditNoteNumber}  •  ${formatAmount(cn.remainingAmount)} available',
                          style:
                              TextStyle(fontSize: 10.sp, color: kSubText),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close, size: 16, color: kSubText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepLabel('1', 'Select Invoice to Apply Against'),
                        const SizedBox(height: 8),
                        Obx(() {
                          if (isLoadingBills.value) {
                            return _invoiceLoadingState();
                          }
                          if (unpaidInvoices.isEmpty) {
                            return _noInvoicesState();
                          }
                          return _buildInvoiceList(
                            invoices: unpaidInvoices,
                            selectedId: selectedInvoiceId,
                            onSelect: (inv) {
                              selectedInvoiceId.value = inv.id;
                              selectedInvoice.value = inv;
                              // Cap amount at min(remaining, outstanding)
                              final maxAmt = inv.outstanding < cn.remainingAmount
                                  ? inv.outstanding
                                  : cn.remainingAmount;
                              amountController.text =
                                  maxAmt.toStringAsFixed(2);
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                        _stepLabel('2', 'Amount to Apply'),
                        const SizedBox(height: 8),
                        Obx(() {
                          final inv = selectedInvoice.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (inv != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Invoice outstanding: ${formatAmount(inv.outstanding)}  •  CN remaining: ${formatAmount(cn.remainingAmount)}',
                                    style: TextStyle(
                                        fontSize: 11.sp,
                                        color: kPrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              TextFormField(
                                controller: amountController,
                                decoration: _inputDeco('0.00')
                                    .copyWith(prefixText: 'Rs. '),
                                style: TextStyle(
                                    fontSize: 13.sp, color: kText),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Amount required';
                                  }
                                  final amt =
                                      double.tryParse(v.trim()) ?? 0;
                                  if (amt <= 0) return 'Must be > 0';
                                  if (amt > cn.remainingAmount) {
                                    return 'Cannot exceed CN remaining: ${formatAmount(cn.remainingAmount)}';
                                  }
                                  final inv = selectedInvoice.value;
                                  if (inv != null &&
                                      amt > inv.outstanding) {
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

              const SizedBox(height: 16),
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isApplyingCreditNote.value
                              ? null
                              : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13.sp, color: kSubText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isApplyingCreditNote.value
                              ? null
                              : () {
                                  if (selectedInvoiceId.value.isEmpty) {
                                    _showError(
                                        'Please select an invoice');
                                    return;
                                  }
                                  if (formKey.currentState!.validate()) {
                                    final amt = double.tryParse(
                                            amountController.text
                                                .trim()) ??
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isApplyingCreditNote.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text('Apply',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // DETAIL DIALOG
  // ============================================================

  void _showCreditNoteDetailsDialog(CreditNote cn) {
    final statusColor = cn.status == 'Issued'
        ? kWarning
        : cn.status == 'Applied'
            ? kSuccess
            : kDanger;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 88.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.12))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.note_alt_outlined,
                          size: 20, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cn.creditNoteNumber,
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: kText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy')
                                .format(cn.date),
                            style: TextStyle(
                                fontSize: 11.sp, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close,
                                size: 15, color: kSubText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cn.status,
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: statusColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Amount strip ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: kBg,
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.12))),
                ),
                child: Row(
                  children: [
                    _amountChip(
                        'Credit', formatAmount(cn.amount), kWarning),
                    _vDivider(),
                    _amountChip('Applied',
                        formatAmount(cn.appliedAmount), kSuccess),
                    _vDivider(),
                    _amountChip('Remaining',
                        formatAmount(cn.remainingAmount), kPrimary),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailSection('Invoice Information', [
                        _detailRow('Customer', cn.customerName),
                        _detailRow('Invoice', cn.originalInvoiceNumber),
                        _detailRow('Invoice Amount',
                            formatAmount(cn.originalInvoiceAmount)),
                      ]),
                      const SizedBox(height: 16),
                      _detailSection('Credit Details', [
                        _detailRow('Reason Type', cn.reasonType),
                        _detailRow('Reason', cn.reason),
                        if (cn.expiryDate != null)
                          _detailRow(
                            'Expiry',
                            DateFormat('dd MMM yyyy')
                                .format(cn.expiryDate!),
                            valueColor: cn.expiryDate!
                                    .isBefore(DateTime.now())
                                ? kDanger
                                : null,
                          ),
                        if (cn.notes.isNotEmpty)
                          _detailRow('Notes', cn.notes),
                        _detailRow(
                          'Created',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(cn.createdAt),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Footer ────────────────────────────────────────
              if (cn.status == 'Issued')
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    border: Border(
                        top: BorderSide(
                            color: Colors.grey.withOpacity(0.12))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        showApplyCreditNoteDialog(cn);
                      },
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.white),
                      label: Text(
                        'Apply to Invoice',
                        style: TextStyle(
                            fontSize: 13.sp, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED INVOICE LIST WIDGET
  // ============================================================

  Widget _buildInvoiceList({
    required List<InvoiceForCreditNote> invoices,
    required RxString selectedId,
    required Function(InvoiceForCreditNote) onSelect,
  }) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.grey.withOpacity(0.25)),
          ),
          child: Column(
            children: invoices.asMap().entries.map((entry) {
              final idx = entry.key;
              final inv = entry.value;
              final isSelected = inv.id == selectedId.value;
              final isLast = idx == invoices.length - 1;

              return GestureDetector(
                onTap: () => onSelect(inv),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withOpacity(0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: idx == 0
                          ? const Radius.circular(10)
                          : Radius.zero,
                      topRight: idx == 0
                          ? const Radius.circular(10)
                          : Radius.zero,
                      bottomLeft: isLast
                          ? const Radius.circular(10)
                          : Radius.zero,
                      bottomRight: isLast
                          ? const Radius.circular(10)
                          : Radius.zero,
                    ),
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                                color:
                                    Colors.grey.withOpacity(0.12))),
                  ),
                  child: Row(
                    children: [
                      // Radio indicator
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? kPrimary
                                : Colors.grey.withOpacity(0.4),
                            width: 1.8,
                          ),
                          color: isSelected
                              ? kPrimary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 11, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Invoice info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.invoiceNumber,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : kText,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy')
                                  .format(inv.date),
                              style: TextStyle(
                                  fontSize: 10.sp, color: kSubText),
                            ),
                          ],
                        ),
                      ),
                      // Amounts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatAmount(inv.amount),
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: kText),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: kWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Due: ${formatAmount(inv.outstanding)}',
                              style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: kWarning),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  // ============================================================
  // EXPORT
  // ============================================================

  void exportCreditNotes() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Credit Notes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kText),
            ),
            const SizedBox(height: 10),
            Text('Choose export format',
                style: TextStyle(fontSize: 14, color: kSubText)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf,
                  color: Color(0xFFE53935)),
              title: Text('Export as PDF',
                  style: TextStyle(color: kText)),
              onTap: () {
                Get.back();
                exportToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart,
                  color: Color(0xFF2E7D32)),
              title: Text('Export as Excel',
                  style: TextStyle(color: kText)),
              onTap: () {
                Get.back();
                exportToExcel();
              },
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> exportToPdf() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Text('Credit Notes Report',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: [
                'CN #',
                'Customer',
                'Date',
                'Amount',
                'Applied',
                'Remaining',
                'Status'
              ],
              data: creditNotes
                  .map((n) => [
                        n.creditNoteNumber,
                        n.customerName,
                        DateFormat('dd/MM/yy').format(n.date),
                        formatAmount(n.amount),
                        formatAmount(n.appliedAmount),
                        formatAmount(n.remainingAmount),
                        n.status,
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'credit_notes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
      AppSnackbar.success(
          kSuccess, 'Success', 'Exported to PDF');
    } catch (e) {
      _showError('Failed to export PDF: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Credit Notes'];
      excel.setDefaultSheet('Credit Notes');

      final headers = [
        'CN #',
        'Date',
        'Customer',
        'Invoice #',
        'Amount',
        'Applied',
        'Remaining',
        'Reason Type',
        'Status'
      ];
      for (int i = 0; i < headers.length; i++) {
        _excelCell(sheet, 0, i, headers[i], bold: true);
      }
      int row = 1;
      for (final n in creditNotes) {
        _excelCell(sheet, row, 0, n.creditNoteNumber);
        _excelCell(
            sheet, row, 1, DateFormat('dd/MM/yyyy').format(n.date));
        _excelCell(sheet, row, 2, n.customerName);
        _excelCell(sheet, row, 3, n.originalInvoiceNumber);
        _excelCell(sheet, row, 4, formatAmount(n.amount));
        _excelCell(sheet, row, 5, formatAmount(n.appliedAmount));
        _excelCell(sheet, row, 6, formatAmount(n.remainingAmount));
        _excelCell(sheet, row, 7, n.reasonType);
        _excelCell(sheet, row, 8, n.status);
        row++;
      }
      excel.delete('Sheet1');
      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'credit_notes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
      AppSnackbar.success(
          kSuccess, 'Success', 'Exported to Excel');
    } catch (e) {
      _showError('Failed to export Excel: $e');
    }
  }

  void _excelCell(Sheet sheet, int row, int col, dynamic value,
      {bool bold = false}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value.toString());
    if (bold) {
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  Widget _stepLabel(String step, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: kSubText,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: kSubText.withOpacity(0.6), fontSize: 12.sp),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: kBg,
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
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: kPrimary),
          ),
          const SizedBox(width: 10),
          Text('Loading invoices...',
              style: TextStyle(fontSize: 12.sp, color: kSubText)),
        ],
      ),
    );
  }

  Widget _noInvoicesState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 18, color: kSubText.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text('No unpaid invoices found',
              style: TextStyle(fontSize: 12.sp, color: kSubText)),
        ],
      ),
    );
  }

  Widget _amountChip(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.sp, color: kSubText)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: Colors.grey.withOpacity(0.2));

  Widget _detailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: kText),
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11.sp,
                  color: kSubText,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: valueColor ?? kText,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) =>
      AppSnackbar.error(kDanger, 'Error', msg);
}