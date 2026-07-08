// core/paymentReceived/controller/payment_received_controller.dart
// COMPLETE FIXED VERSION - WITH MULTI-INVOICE SUPPORT

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
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
  var isRecording = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var searchQuery = ''.obs;

  // ✅ NEW: Selected invoices for payment
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
    print('🔵 [DEBUG] PaymentReceivedController onInit called');
    fetchCustomers();
    fetchBankAccounts();
    fetchPayments();
    fetchSummary();
  }

  // ─── Fetch Customers from Warehouse ─────────────────────────────
  Future<void> fetchCustomers() async {
    print('🟡 [DEBUG] fetchCustomers called');
    try {
      final response = await _api.get('/api/warehouse/customers');
      print('🟡 [DEBUG] fetchCustomers statusCode: ${response.statusCode}');
      
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          customers.value = (data['data'] as List)
              .map((e) => Customer.fromJson(e))
              .toList();
          print('🟡 [DEBUG] fetchCustomers customers count: ${customers.length}');
        }
      }
    } catch (e) {
      print('❌ [DEBUG] fetchCustomers error: $e');
    }
  }

  // ─── Fetch Bank Accounts ──────────────────────────────────────────
  Future<void> fetchBankAccounts() async {
    print('🟡 [DEBUG] fetchBankAccounts called');
    try {
      final response = await _api.get('/api/bank-accounts');
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          bankAccounts.value = (data['data'] as List)
              .map((e) => BankAccount.fromJson(e))
              .toList();
          print('🟡 [DEBUG] fetchBankAccounts count: ${bankAccounts.length}');
        }
      }
    } catch (e) {
      print('❌ [DEBUG] fetchBankAccounts error: $e');
    }
  }

  // ─── Fetch Unpaid Invoices from Warehouse ──────────────────────
  Future<void> fetchUnpaidInvoices(String customerId) async {
    print('🟡 [DEBUG] fetchUnpaidInvoices called for customerId: $customerId');
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
          
          // Clear selections when customer changes
          selectedInvoiceIds.clear();
          totalSelectedOutstanding.value = 0;
          totalSelectedAmount.value = 0;
          
          print('🟡 [DEBUG] fetchUnpaidInvoices count: ${unpaidInvoices.length}');
        } else {
          unpaidInvoices.value = [];
        }
      } else {
        unpaidInvoices.value = [];
      }
    } catch (e) {
      print('❌ [DEBUG] fetchUnpaidInvoices error: $e');
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
    print('🟡 [DEBUG] Selected invoices: ${selectedInvoiceIds.length}, Total: ${totalSelectedOutstanding.value}');
  }

  // ─── Clear all selections ────────────────────────────────────────
  void clearInvoiceSelections() {
    selectedInvoiceIds.clear();
    totalSelectedOutstanding.value = 0;
    totalSelectedAmount.value = 0;
  }

  // ─── Fetch Payments ──────────────────────────────────────────────
 Future<void> fetchPayments() async {
  print('🟡 [DEBUG] fetchPayments called');
  print('🟡 [DEBUG] selectedDateRange: ${selectedDateRange.value}');
  print('🟡 [DEBUG] searchQuery: ${searchQuery.value}');
  print('🟡 [DEBUG] selectedFilter: ${selectedFilter.value}');
  
  try {
    isLoading(true);

    Map<String, dynamic> queryParams = {};
    if (selectedDateRange.value != null) {
      queryParams['startDate'] = selectedDateRange.value!.start.toIso8601String();
      queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      print('🟡 [DEBUG] Date range applied: ${queryParams['startDate']} to ${queryParams['endDate']}');
    }

    print('🟡 [DEBUG] Calling API: /api/accounts-receivable/payments with params: $queryParams');
    final response = await _api.get(
      '/api/payments-received',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    print('🟡 [DEBUG] fetchPayments statusCode: ${response.statusCode}');
    print('🟡 [DEBUG] fetchPayments success: ${response.success}');
    print('🟡 [DEBUG] fetchPayments response data: ${response.data}');

    if (response.success) {
      final data = response.data;
      print('🟡 [DEBUG] response.data["success"]: ${data['success']}');
      
      if (data['success'] == true) {
        print('🟡 [DEBUG] response.data["data"] type: ${data['data'].runtimeType}');
        print('🟡 [DEBUG] response.data["data"] length: ${data['data'] != null ? (data['data'] as List).length : 0}');
        
        final paymentsData = (data['data'] as List)
            .map((e) => Payment.fromJson(e))
            .toList();
        print('🟡 [DEBUG] paymentsData parsed count: ${paymentsData.length}');
        
        allPayments.value = paymentsData;
        print('🟡 [DEBUG] allPayments updated with ${allPayments.length} payments');
        
        if (searchQuery.value.isNotEmpty) {
          print('🟡 [DEBUG] searchQuery is not empty: ${searchQuery.value} - calling searchPayments');
          searchPayments(searchQuery.value);
        } else {
          print('🟡 [DEBUG] Setting payments to allPayments (${allPayments.length} items)');
          payments.value = paymentsData;
        }
      } else {
        print('❌ [DEBUG] API returned success: false - ${data['message']}');
      }
    } else {
      print('❌ [DEBUG] fetchPayments failed: ${response.message}');
      print('❌ [DEBUG] statusCode: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ [DEBUG] fetchPayments error: $e');
    print('❌ [DEBUG] Stack trace: ${StackTrace.current}');
    AppSnackbar.error(Colors.red, 'Error', 'Failed to load payments: $e');
  } finally {
    isLoading(false);
    print('🟡 [DEBUG] fetchPayments isLoading set to false');
  }
}
  // ─── Fetch Summary ──────────────────────────────────────────────
  Future<void> fetchSummary() async {
    print('🟡 [DEBUG] fetchSummary called');
    try {
      Map<String, dynamic> queryParams = {};
      if (selectedDateRange.value != null) {
        queryParams['startDate'] = selectedDateRange.value!.start.toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      final response = await _api.get(
        '/api/accounts-receivable/payments/summary',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
      print('❌ [DEBUG] fetchSummary error: $e');
    }
  }

 // ─── Record Payment (SINGLE INVOICE) ──────────────────────────────
Future<void> recordPayment({
  required String customerId,
  required String invoiceId,  // ✅ Changed from List<String> to String
  required double amount,
  required DateTime paymentDate,
  required String paymentMethod,
  required String reference,
  required String? bankAccountId,
  required String notes,
}) async {
  print('🟢 [DEBUG] recordPayment called');
  print('🟢 [DEBUG] invoiceId: $invoiceId, amount: $amount');
  
  try {
    isRecording(true);

    final body = {
      'customerId': customerId,
      'invoiceId': invoiceId,  // ✅ Changed from invoiceIds to invoiceId
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'reference': reference,
      'bankAccountId': bankAccountId,
      'notes': notes,
    };
    print('🟢 [DEBUG] recordPayment body: $body');

    final response = await _api.post('/api/accounts-receivable/payments', body: body);
    print('🟢 [DEBUG] recordPayment statusCode: ${response.statusCode}');

    if (response.success) {
      AppSnackbar.success(
        kSuccess,
        'Success',
        'Payment recorded successfully!\nJournal entry created',
        duration: const Duration(seconds: 3),
      );
      clearInvoiceSelections();
      await fetchPayments();
      await fetchSummary();
      await fetchUnpaidInvoices(customerId);
    } else {
      AppSnackbar.error(
        kDanger,
        'Error',
        response.message.isNotEmpty ? response.message : 'Failed to record payment',
      );
    }
  } catch (e) {
    print('❌ [DEBUG] recordPayment error: $e');
    AppSnackbar.error(Colors.red, 'Error', 'Failed to record payment: $e');
  } finally {
    isRecording(false);
  }
}
  // ─── Delete Payment with Reversal ───────────────────────────────
  Future<void> deletePayment(String paymentId) async {
    print('🟢 [DEBUG] deletePayment called: $paymentId');
    
    try {
      final response = await _api.delete('/api/accounts-receivable/payments/$paymentId');
      
      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Payment deleted and journal entry reversed',
        );
        await fetchPayments();
        await fetchSummary();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to delete payment',
        );
      }
    } catch (e) {
      print('❌ [DEBUG] deletePayment error: $e');
      AppSnackbar.error(Colors.red, 'Error', 'Failed to delete payment: $e');
    }
  }

  // ─── Clear Cheque Payment ──────────────────────────────────────
  Future<void> clearChequePayment(String paymentId) async {
    print('🟢 [DEBUG] clearChequePayment called: $paymentId');
    
    try {
      final response = await _api.post('/api/accounts-receivable/payments/$paymentId/clear');
      
      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Cheque payment cleared successfully',
        );
        await fetchPayments();
        await fetchSummary();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to clear cheque',
        );
      }
    } catch (e) {
      print('❌ [DEBUG] clearChequePayment error: $e');
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
    fetchPayments();
    fetchSummary();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedFilter.value = 'Custom Range';
    }
    fetchPayments();
    fetchSummary();
  }

  void searchPayments(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      payments.value = allPayments.value;
      _updateSummaryForFiltered(allPayments.value);
    } else {
      final searchLower = query.toLowerCase();
      final results = allPayments.where((payment) {
        return payment.paymentNumber.toLowerCase().contains(searchLower) ||
            payment.customerName.toLowerCase().contains(searchLower) ||
            payment.invoiceNumber.toLowerCase().contains(searchLower) ||
            payment.paymentMethod.toLowerCase().contains(searchLower) ||
            payment.reference.toLowerCase().contains(searchLower);
      }).toList();
      payments.value = results;
      _updateSummaryForFiltered(results);
    }
  }

  void _updateSummaryForFiltered(List<Payment> filteredPayments) {
    totalReceived.value = filteredPayments.fold(0.0, (sum, p) => sum + p.amount);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    today.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(todayStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, p) => sum + p.amount);

    thisWeek.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(thisWeekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, p) => sum + p.amount);

    thisMonth.value = filteredPayments
        .where((p) => p.paymentDate.isAfter(thisMonthStart.subtract(const Duration(days: 1))))
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
    // Navigate to invoice details
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
            Text(
              'Export Payments',
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
    print('🟢 [DEBUG] exportToPdf called');
    try {
      if (!kIsWeb) {
        print('🟢 [DEBUG] exportToPdf showing loading dialog');
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Generating PDF...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      }

      final pdf = pw.Document();
      print('🟢 [DEBUG] exportToPdf PDF document created');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _pdfHeader(),
          footer: (ctx) => _pdfFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(),
            pw.SizedBox(height: 16),
            _pdfPaymentsSection(),
          ],
        ),
      );
      print('🟢 [DEBUG] exportToPdf PDF page added');

      final bytes = await pdf.save();
      print('🟢 [DEBUG] exportToPdf PDF bytes saved, size: ${bytes.length}');
      
      final fileName =
          'payments_received_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      print('🟢 [DEBUG] exportToPdf fileName: $fileName');

      if (kIsWeb) {
        print('🟢 [DEBUG] exportToPdf web platform - downloading PDF');
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
        print('🟢 [DEBUG] exportToPdf mobile platform - saving PDF');
        final dir = await getTemporaryDirectory();
        print('🟢 [DEBUG] exportToPdf temporary directory: ${dir.path}');
        
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        print('🟢 [DEBUG] exportToPdf file saved: ${file.path}');

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${payments.length} payments exported to PDF',
        );

        print('🟢 [DEBUG] exportToPdf opening file');
        await OpenFile.open(file.path);
      }
    } catch (e, stackTrace) {
      print('❌ [DEBUG] exportToPdf error: $e');
      print('❌ [DEBUG] exportToPdf stackTrace: $stackTrace');
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
  }

  pw.Widget _pdfHeader() {
    print('🟡 [DEBUG] _pdfHeader called');
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
                'Payments Received Report',
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
    print('🟡 [DEBUG] _pdfSummarySection called');
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200),
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
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'This Week',
                _formatAmount(thisWeek.value),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Today',
                _formatAmount(today.value),
                PdfColors.indigo700,
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
    print('🟡 [DEBUG] _pdfPaymentsSection called, payments count: ${payments.length}');
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

  Future<void> exportToExcel() async {
    print('🟢 [DEBUG] exportToExcel called');
    try {
      if (!kIsWeb) {
        print('🟢 [DEBUG] exportToExcel showing loading dialog');
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Building Excel...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      }

      final excel = Excel.createExcel();
      print('🟢 [DEBUG] exportToExcel Excel created');

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');
      print('🟢 [DEBUG] exportToExcel Summary sheet created');

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
        ['Total Amount', _formatAmount(payments.fold(0.0, (sum, p) => sum + p.amount))],
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
      print('🟢 [DEBUG] exportToExcel Payments sheet created');
      
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
      print('🟢 [DEBUG] exportToExcel adding ${payments.length} payment rows');
      for (final payment in payments) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(paymentsSheet, row, 0, payment.paymentNumber, bgColor: bg);
        _excelSetCell(
          paymentsSheet,
          row,
          1,
          DateFormat('dd MMM yyyy').format(payment.paymentDate),
          bgColor: bg,
        );
        _excelSetCell(paymentsSheet, row, 2, payment.customerName, bgColor: bg);
        _excelSetCell(paymentsSheet, row, 3, payment.invoiceNumber, bgColor: bg);
        _excelSetCell(paymentsSheet, row, 4, payment.invoiceAmount, bgColor: bg);
        _excelSetCell(
          paymentsSheet,
          row,
          5,
          payment.amount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(paymentsSheet, row, 6, payment.paymentMethod, bgColor: bg);
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

      final colWidths = [15.0, 12.0, 25.0, 15.0, 15.0, 15.0, 15.0, 15.0, 20.0, 30.0];
      for (int i = 0; i < colWidths.length; i++) {
        paymentsSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');
      print('🟢 [DEBUG] exportToExcel deleted default Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');
      print('🟢 [DEBUG] exportToExcel Excel saved, size: ${bytes.length}');

      final fileName =
          'payments_received_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      print('🟢 [DEBUG] exportToExcel fileName: $fileName');

      if (kIsWeb) {
        print('🟢 [DEBUG] exportToExcel web platform - downloading Excel');
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${payments.length} payments exported to Excel',
        );
      } else {
        print('🟢 [DEBUG] exportToExcel mobile platform - saving Excel');
        final dir = await getTemporaryDirectory();
        print('🟢 [DEBUG] exportToExcel temporary directory: ${dir.path}');
        
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        print('🟢 [DEBUG] exportToExcel file saved: ${file.path}');

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${payments.length} payments exported to Excel',
        );

        print('🟢 [DEBUG] exportToExcel opening file');
        await OpenFile.open(file.path);
      }
    } catch (e, stackTrace) {
      print('❌ [DEBUG] exportToExcel error: $e');
      print('❌ [DEBUG] exportToExcel stackTrace: $stackTrace');
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
    print('🟡 [DEBUG] printPayments called');
    AppSnackbar.success(kPrimary, 'Print', 'Preparing payments report...');
  }

  void _handleSessionExpired() {
    print('⚠️ [DEBUG] _handleSessionExpired called');
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
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : DateTime.now(),
      customerId: json['customerId'] is Map 
          ? (json['customerId']['id'] ?? json['customerId']['_id'] ?? '').toString()
          : json['customerId']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      invoiceId: json['invoiceId'] is Map
          ? (json['invoiceId']['id'] ?? json['invoiceId']['_id'] ?? '').toString()
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
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
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
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      totalAmount: safeToDouble(json['totalAmount']),
      paidAmount: safeToDouble(json['paidAmount']),
      outstanding: safeToDouble(json['outstanding']),
      status: json['status'] ?? '',
    );
  }
}