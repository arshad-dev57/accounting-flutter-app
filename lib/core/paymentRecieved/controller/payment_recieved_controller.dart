// core/paymentReceived/controller/payment_received_controller.dart
// COMPLETE FIXED VERSION - WITH LAZY LOADING & PAGINATION (NO WEB)

import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/screen/warehouse_invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class PaymentReceivedController extends GetxController {
  var payments = <Payment>[].obs;
  var customers = <Customer>[].obs;
  var bankAccounts = <BankAccount>[].obs;
  var unpaidInvoices = <InvoiceForPayment>[].obs;
  var allPayments = <Payment>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var isRecording = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var searchQuery = ''.obs;

  // ✅ Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;
  var serverSupportsPagination = false.obs;

  // ✅ Selected invoices for payment
  var selectedInvoiceIds = <String>[].obs;
  var totalSelectedOutstanding = 0.0.obs;
  var totalSelectedAmount = 0.0.obs;

  // Summary totals
  var totalReceived = 0.0.obs;
  var thisMonth = 0.0.obs;
  var thisWeek = 0.0.obs;
  var today = 0.0.obs;
  var pendingCount = 0.obs;
  var prefillCustomerId = ''.obs;
  var prefillInvoiceId = ''.obs;

  // ✅ Search & Scroll Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final ApiClient _api = Get.find<ApiClient>();

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    fetchCustomers();
    fetchBankAccounts();
    fetchPayments(resetPage: true);
    fetchSummary();
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
    fetchPayments(resetPage: true);
  }

  // ─── Fetch Customers ─────────────────────────────────────────────
  Future<void> fetchCustomers() async {
    try {
      final response = await _api.get('/api/warehouse/customers');

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          customers.value = (data['data'] as List)
              .map((e) => Customer.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error fetching customers: $e');
    }
  }

  // ─── Fetch Bank Accounts ──────────────────────────────────────────
  Future<void> fetchBankAccounts() async {
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
      print('❌ Error fetching bank accounts: $e');
    }
  }

  // ─── Fetch Unpaid Invoices ──────────────────────────────────────
  Future<void> fetchUnpaidInvoices(String customerId) async {
    try {
      final response = await _api.get(
        '/api/accounts-receivable/customers/$customerId/invoices/unpaid',
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          unpaidInvoices.value = (data['data'] as List)
              .map((e) => InvoiceForPayment.fromJson(e))
              .toList();

          selectedInvoiceIds.clear();
          totalSelectedOutstanding.value = 0;
          totalSelectedAmount.value = 0;
        } else {
          unpaidInvoices.value = [];
        }
      } else {
        unpaidInvoices.value = [];
      }
    } catch (e) {
      print('❌ Error fetching unpaid invoices: $e');
      unpaidInvoices.value = [];
    }
  }

  // ─── Toggle invoice selection ────────────────────────────────────
  void toggleInvoiceSelection(String invoiceId, double outstanding) {
    if (selectedInvoiceIds.contains(invoiceId)) {
      selectedInvoiceIds.remove(invoiceId);
      totalSelectedOutstanding.value -= outstanding;
    } else {
      selectedInvoiceIds.add(invoiceId);
      totalSelectedOutstanding.value += outstanding;
    }
    totalSelectedAmount.value = totalSelectedOutstanding.value;
  }

  // ─── Clear all selections ────────────────────────────────────────
  void clearInvoiceSelections() {
    selectedInvoiceIds.clear();
    totalSelectedOutstanding.value = 0;
    totalSelectedAmount.value = 0;
  }

  // ─── Fetch Payments with Pagination ─────────────────────────────
  Future<void> fetchPayments({bool resetPage = true}) async {
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
        params['startDate'] = selectedDateRange.value!.start.toIso8601String();
        params['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _api.get(
        '/api/payments-received',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          final newPayments = (data['data'] as List)
              .map((e) => Payment.fromJson(e))
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
      }
    } catch (e) {
      print('❌ Error fetching payments: $e');
      AppSnackbar.error(Colors.red, 'Error', 'Failed to load payments: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── Load More Data (Lazy Loading) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchPayments(resetPage: false);
    }
  }

  // ─── Fetch Summary ──────────────────────────────────────────────
  Future<void> fetchSummary() async {
    try {
      Map<String, dynamic> params = {};
      if (selectedDateRange.value != null) {
        params['startDate'] = selectedDateRange.value!.start.toIso8601String();
        params['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      final response = await _api.get(
        '/api/accounts-receivable/payments/summary',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          totalReceived.value = _toDouble(data['data']['totalReceived']);
          thisMonth.value = _toDouble(data['data']['thisMonth']);
          thisWeek.value = _toDouble(data['data']['thisWeek']);
          today.value = _toDouble(data['data']['today']);
          pendingCount.value = data['data']['pending'] ?? 0;
        }
      }
    } catch (e) {
      print('❌ Error fetching summary: $e');
    }
  }

  // ─── Record Payment ──────────────────────────────────────────────
  Future<void> recordPayment({
    required String customerId,
    required String invoiceId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String reference,
    required String? bankAccountId,
    required String notes,
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
      isRecording(true);

      final body = {
        'customerId': customerId,
        'invoiceId': invoiceId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'bankAccountId': bankAccountId,
        'notes': notes,
      };

      final response = await _api.post(
        '/api/accounts-receivable/payments',
        body: body,
      );

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success ✅',
          'Payment recorded successfully!',
          duration: const Duration(seconds: 3),
        );
        clearInvoiceSelections();
        await fetchPayments(resetPage: true);
        await fetchSummary();
        await fetchUnpaidInvoices(customerId);
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to record payment',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to record payment: $e');
    } finally {
      isRecording(false);
    }
  }

  // ─── Delete Payment ──────────────────────────────────────────────
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
      final response = await _api.delete(
        '/api/accounts-receivable/payments/$paymentId',
      );

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Payment deleted and journal entry reversed',
        );
        await fetchPayments(resetPage: true);
        await fetchSummary();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete payment',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to delete payment: $e');
    }
  }

  // ─── Clear Cheque Payment ──────────────────────────────────────
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
      final response = await _api.post(
        '/api/accounts-receivable/payments/$paymentId/clear',
      );

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Cheque payment cleared successfully',
        );
        await fetchPayments(resetPage: true);
        await fetchSummary();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to clear cheque',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to clear cheque: $e');
    }
  }

  // ─── Filters ──────────────────────────────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    if (filter != 'Custom Range') {
      selectedDateRange.value = null;
      _applyDateFilter(filter);
    }
    fetchPayments(resetPage: true);
    fetchSummary();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedFilter.value = 'Custom Range';
    }
    fetchPayments(resetPage: true);
    fetchSummary();
  }

  void searchPayments(String query) {
    searchQuery.value = query;
    fetchPayments(resetPage: true);
  }

  void _updateSummaryForFiltered(List<Payment> filteredPayments) {
    totalReceived.value = filteredPayments.fold(
      0.0,
      (sum, p) => sum + p.amount,
    );

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    today.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            todayStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    thisWeek.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            thisWeekStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    thisMonth.value = filteredPayments
        .where(
          (p) => p.paymentDate.isAfter(
            thisMonthStart.subtract(const Duration(days: 1)),
          ),
        )
        .fold(0.0, (sum, p) => sum + p.amount);
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

  void viewInvoice(Payment payment) {
    Get.to(() => const WarehouseInvoiceScreen());
  }

  void printReceipt(Payment payment) {
    AppSnackbar.success(
      kPrimary,
      'Print',
      'Printing receipt for ${payment.paymentNumber}',
    );
  }

  // ─── Export Functions ─────────────────────────────────────────────
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

  // ─── PDF Export ──────────────────────────────────────────────────
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

      final branding = await PdfBrandingBundle.load();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => branding.buildHeader(
            reportTitle: 'Payments Received Report',
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

      final dir = await getTemporaryDirectory();
      final fileName =
          'payments_received_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        Colors.green,
        'Success',
        '${payments.length} payments exported to PDF',
      );

      await OpenFile.open(file.path);
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
                'Total Received',
                _formatAmount(totalReceived.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'This Month',
                _formatAmount(thisMonth.value),
                accent,
              ),
              _pdfSummaryItem(
                'This Week',
                _formatAmount(thisWeek.value),
                accent,
              ),
              _pdfSummaryItem(
                'Today',
                _formatAmount(today.value),
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
                  'Customer',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Invoice #',
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
        ...payments
            .map(
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
                        payment.customerName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        payment.invoiceNumber,
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
                        _formatAmount(payment.amount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.green700,
                        ),
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
                flex: 11,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(payments.fold(0.0, (sum, p) => sum + p.amount)),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Excel Export ──────────────────────────────────────────────────
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

      final excel = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Payments Received Report',
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
      if (selectedDateRange.value != null) {
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Period: ${DateFormat('dd MMM yyyy').format(selectedDateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange.value!.end)}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }
      if (searchQuery.value.isNotEmpty) {
        _excelSetCell(
          summarySheet,
          4,
          0,
          'Search: ${searchQuery.value}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }

      _excelSetCell(
        summarySheet,
        6,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Received', _formatAmount(totalReceived.value)],
        ['This Month', _formatAmount(thisMonth.value)],
        ['This Week', _formatAmount(thisWeek.value)],
        ['Today', _formatAmount(today.value)],
        ['Total Payments', payments.length.toString()],
        [
          'Total Amount',
          _formatAmount(payments.fold(0.0, (sum, p) => sum + p.amount)),
        ],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(
            summarySheet,
            7 + r,
            c,
            summaryRows[r][c],
            bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5',
          );
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Payments Sheet
      final paymentsSheet = excel['Payments'];
      final headers = [
        'Payment #',
        'Date',
        'Customer',
        'Invoice #',
        'Invoice Amount',
        'Amount Paid',
        'Payment Method',
        'Reference',
        'Bank Account',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          paymentsSheet,
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
      for (final payment in payments) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(
          paymentsSheet,
          row,
          0,
          payment.paymentNumber,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          1,
          DateFormat('dd MMM yyyy').format(payment.paymentDate),
          bgColor: bg,
        );
        _excelSetCell(paymentsSheet, row, 2, payment.customerName, bgColor: bg);
        _excelSetCell(
          paymentsSheet,
          row,
          3,
          payment.invoiceNumber,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          4,
          payment.invoiceAmount,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          5,
          payment.amount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          paymentsSheet,
          row,
          6,
          payment.paymentMethod,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          7,
          payment.reference.isEmpty ? '-' : payment.reference,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          8,
          payment.bankAccountName.isEmpty ? '-' : payment.bankAccountName,
          bgColor: bg,
        );
        _excelSetCell(
          paymentsSheet,
          row,
          9,
          payment.notes.isEmpty ? '-' : payment.notes,
          bgColor: bg,
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        paymentsSheet,
        row,
        4,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        paymentsSheet,
        row,
        5,
        payments.fold(0.0, (sum, p) => sum + p.amount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );

      final colWidths = [
        15.0,
        12.0,
        25.0,
        15.0,
        15.0,
        15.0,
        15.0,
        15.0,
        20.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        paymentsSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'payments_received_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        Colors.green,
        'Success',
        '${payments.length} payments exported to Excel',
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export Excel: $e');
    }
  }

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

  void printPayments() {
    AppSnackbar.success(kPrimary, 'Print', 'Preparing payments report...');
  }

  void _handleSessionExpired() {
    AppSnackbar.error(kDanger, 'Session Expired', 'Please login again');
  }
}

// ─────────────────────── MODELS ───────────────────────

class Payment {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final String invoiceNumber;
  final double invoiceAmount;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String bankAccountId;
  final String bankAccountName;
  final String notes;
  final String status;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceAmount,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.bankAccountId,
    required this.bankAccountName,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Payment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : DateTime.now(),
      customerId: json['customerId'] is Map
          ? (json['customerId']['id'] ?? json['customerId']['_id'] ?? '')
                .toString()
          : json['customerId']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      invoiceId: json['invoiceId'] is Map
          ? (json['invoiceId']['id'] ?? json['invoiceId']['_id'] ?? '')
                .toString()
          : json['invoiceId']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceAmount: safeToDouble(json['invoiceAmount']),
      amount: safeToDouble(json['amount']),
      paymentMethod: json['paymentMethod'] ?? '',
      reference: json['reference'] ?? '',
      bankAccountId: json['bankAccountId']?.toString() ?? '',
      bankAccountName: json['bankAccountName'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
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
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BankAccount(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['accountName'] ?? '',
      number: json['accountNumber'] ?? '',
      balance: safeToDouble(json['currentBalance']),
    );
  }
}

class InvoiceForPayment {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final double outstanding;
  final String status;

  InvoiceForPayment({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstanding,
    required this.status,
  });

  factory InvoiceForPayment.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return InvoiceForPayment(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      totalAmount: safeToDouble(json['totalAmount']),
      paidAmount: safeToDouble(json['paidAmount']),
      outstanding: safeToDouble(json['outstanding']),
      status: json['status'] ?? '',
    );
  }
}
