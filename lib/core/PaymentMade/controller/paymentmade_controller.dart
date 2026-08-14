// core/paymentsMade/controller/payment_made_controller.dart
// COMPLETE WITH LAZY LOADING & PAGINATION (NO WEB)

import 'dart:io';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class PaymentMadeController extends GetxController {
  // Observable variables
  var payments = <PaymentMade>[].obs;
  var allPayments = <PaymentMade>[].obs;
  var suppliers = <SupplierForPayment>[].obs;
  var bankAccounts = <BankAccount>[].obs;
  var unpaidBills = <BillForPayment>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var isRecording = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;

  // ✅ Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;
  var serverSupportsPagination = false.obs;

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
  ];

  // ✅ Search & Scroll Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final ApiClient _api = Get.find<ApiClient>();

  @override
  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadSuppliers();
    loadBankAccounts();
    Future(() async {
      await waitForFiscalYearReady();
      loadPayments(resetPage: true);
      loadSummary();
    });
    _fyWorker = listenFiscalYearChanges(() {
      loadPayments(resetPage: true);
      loadSummary();
    });
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    loadPayments(resetPage: true);
  }

  String formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  // ─── LOAD PAYMENTS WITH PAGINATION ──────────────────────────────
  Future<void> loadPayments({bool resetPage = true}) async {
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

      final response = await _api.get(
        '/api/payments-made',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          List<dynamic> paymentsData = data['data'] ?? [];
          final newPayments = paymentsData
              .map((json) => PaymentMade.fromJson(json))
              .toList();

          if (resetPage) {
            allPayments.value = newPayments;
            payments.value = newPayments;
          } else {
            allPayments.addAll(newPayments);
            payments.addAll(newPayments);
          }

          // Parse pagination info
          if (data['pagination'] != null) {
            final pagination = data['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newPayments.length;
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
            totalItems.value = payments.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          _updateSummaryForFiltered(payments.value);
          payments.refresh();
        }
      } else {
        _showError('Failed to load payments');
      }
    } catch (e) {
      _showError('Error loading payments: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── LOAD MORE DATA (LAZY LOADING) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadPayments(resetPage: false);
    }
  }

  // ─── LOAD SUPPLIERS ──────────────────────────────────────────────
  Future<void> loadSuppliers() async {
    try {
      final response = await _api.get('/api/warehouse/supplier');
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          List<dynamic> suppliersData = data['data'] ?? [];
          suppliers.value = suppliersData
              .map((json) => SupplierForPayment.fromJson(json))
              .toList();
        }
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
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
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

      final response = await _api.get(
        '/api/payments-made/bills/unpaid/$supplierId',
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          List<dynamic> billsData = data['data'] ?? [];
          if (billsData.isEmpty) {
            AppSnackbar.info('Info', 'No unpaid bills found for this supplier');
            currentBills.value = [];
            return [];
          }
          final bills = billsData
              .map((json) => BillForPayment.fromJson(json))
              .toList();
          currentBills.value = bills;
          return bills;
        } else {
          _showError(data['message'] ?? 'Failed to load bills');
          return [];
        }
      } else {
        _showError('Failed to load bills');
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

  // ─── RECORD PAYMENT WITH LOADING DIALOG ──────────────────────────
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

    if (paymentMethod == 'Bank Transfer' &&
        (bankAccountId == null || bankAccountId.isEmpty)) {
      _showError('Please select a bank account');
      return;
    }

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
                    color: kDanger,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Recording payment...',
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

      if (bankAccountId != null &&
          bankAccountId.isNotEmpty &&
          paymentMethod == 'Bank Transfer') {
        paymentData['bankAccountId'] = bankAccountId;
      }

      final response = await _api.post('/api/payments-made', body: paymentData);

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success ✅',
          'Payment recorded successfully!',
          duration: const Duration(seconds: 3),
        );
        clearBillSelections();
        await loadPayments(resetPage: true);
        await loadSummary();
        if (supplierId.isNotEmpty) {
          await getUnpaidBills(supplierId);
        }
      } else {
        _showError(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to record payment',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Error recording payment: $e');
    } finally {
      isRecording.value = false;
    }
  }

  // ─── DELETE PAYMENT WITH LOADING DIALOG ──────────────────────────
  Future<void> deletePayment(String paymentId) async {
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
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting payment...',
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
      final response = await _api.delete('/api/payments-made/$paymentId');

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Payment deleted and journal entry reversed',
        );
        await loadPayments(resetPage: true);
        await loadSummary();
      } else {
        _showError(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete payment',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Error deleting payment: $e');
    }
  }

  // ─── CLEAR CHEQUE PAYMENT WITH LOADING DIALOG ────────────────────
  Future<void> clearChequePayment(String paymentId) async {
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
                  'Clearing cheque...',
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
      final response = await _api.post('/api/payments-made/$paymentId/clear');

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Cheque payment cleared successfully',
        );
        await loadPayments(resetPage: true);
        await loadSummary();
      } else {
        _showError(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to clear cheque',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
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
      _applyDateFilter(filter);
      loadPayments(resetPage: true);
      loadSummary();
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
      default:
        selectedDateRange.value = null;
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
      loadPayments(resetPage: true);
      loadSummary();
    }
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    selectedFilter.value = 'All';
    loadPayments(resetPage: true);
    loadSummary();
  }

  // ─── SEARCH ──────────────────────────────────────────────────────────
  void searchPayments(String query) {
    searchQuery.value = query;
    loadPayments(resetPage: true);
  }

  void _updateSummaryForFiltered(List<PaymentMade> filteredPayments) {
    totalPaid.value = filteredPayments.fold(0.0, (sum, p) => sum + p.amount);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    todayTotal.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            todayStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    thisWeekTotal.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            thisWeekStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    thisMonthTotal.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            thisMonthStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // ─── EXPORT ──────────────────────────────────────────────────────────
  void exportPayments() {
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
                  'Export Payments',
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
              '${payments.length} payments will be exported',
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
                      AppSnackbar.info('Export', 'Excel export coming soon');
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
          border: Border.all(color: color.withOpacity(0.3)),
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

      final branding = await PdfBrandingBundle.load();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => branding.buildHeader(
            reportTitle: 'Payments Made Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfPaymentsSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'payments_made_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          Colors.green,
          'Success',
          '${payments.length} payments exported to PDF',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          Colors.green,
          'Success',
          '${payments.length} payments exported to PDF',
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
  }

  pw.Widget _pdfSummarySection(PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor(accent.red, accent.green, accent.blue, 0.06),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor(accent.red, accent.green, accent.blue, 0.35),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Paid',
                formatAmount(totalPaid.value),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'This Month',
                formatAmount(thisMonthTotal.value),
                accent,
              ),
              _pdfSummaryItem(
                'This Week',
                formatAmount(thisWeekTotal.value),
                accent,
              ),
              _pdfSummaryItem(
                'Today',
                formatAmount(todayTotal.value),
                accent,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Payments',
                payments.length.toString(),
                PdfColors.grey700,
              ),
              _pdfSummaryItem(
                'Filter',
                selectedFilter.value,
                PdfColors.grey700,
              ),
            ],
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

  pw.Widget _pdfPaymentsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Details',
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
                  'Payment #',
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
                flex: 3,
                child: pw.Text(
                  'Supplier',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Bill #',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Method',
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
            ],
          ),
        ),
        ...payments.map(
          (payment) => pw.Container(
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
                    payment.paymentNumber,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    payment.supplierName,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    payment.billNumber,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    payment.paymentMethod,
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    formatAmount(payment.amount),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.red700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPER METHODS ──────────────────────────────────────────────────
  void _showError(String message) {
    AppSnackbar.error(kDanger, 'Error', message);
  }

  void printVoucher(PaymentMade payment) {
    AppSnackbar.info(
      'Print',
      'Printing payment voucher for ${payment.paymentNumber}',
    );
  }

  void viewBill(PaymentMade payment) {
    // Navigate to bill details
    Get.toNamed('/bill-details', arguments: payment.billId);
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
      supplierId: json['supplierId'] is Map
          ? json['supplierId']['id']
          : json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      billId: json['billId'] is Map
          ? json['billId']['id']
          : json['billId'] ?? '',
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
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}
