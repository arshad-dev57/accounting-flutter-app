import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'dart:io';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

class InvoiceController extends GetxController {
  var invoices = <Invoice>[].obs;
  var customers = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isCreating = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedCustomerId = ''.obs;
  var startDate = Rx<DateTime?>(null);
  var endDate = Rx<DateTime?>(null);

  var totalAmount = RxDouble(0.0);
  var totalPaid = RxDouble(0.0);
  var totalOutstanding = RxDouble(0.0);

  final ApiClient _api = Get.find<ApiClient>();

  var bankAccounts = <Map<String, dynamic>>[].obs;
  var isProcessingPayment = false.obs;

  /// Safe conversion of any numeric JSON value to double
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Safe conversion of any JSON value to String
  static String toStringSafe(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  // Fetch bank accounts for dropdown
  Future<void> fetchBankAccounts() async {
    try {
      final response = await _api.get('/api/bank-accounts');

      if (response.success) {
        bankAccounts.value = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
    }
  }

  // Record payment
  Future<void> recordPayment({
    required String invoiceId,
    required String customerId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String reference,
    required String bankAccountId,
    String notes = '',
  }) async {
    try {
      isProcessingPayment(true);

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

      final response = await _api.post('/api/payments-received', body: body);

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          response.data['message'] ?? 'Payment recorded successfully',
        );
        await fetchInvoices();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to record payment',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to record payment: $e');
    } finally {
      isProcessingPayment(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
    fetchInvoices();
    fetchBankAccounts();
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await _api.get('/api/accounts-receivable/customers');

      if (response.success) {
        customers.value = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
      }
    } catch (e) {
      print('Error fetching customers: $e');
    }
  }

  Future<void> fetchInvoices() async {
    try {
      isLoading(true);

      Map<String, dynamic> params = {};

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      if (selectedCustomerId.value.isNotEmpty) {
        params['customerId'] = selectedCustomerId.value;
      }

      if (startDate.value != null) {
        params['startDate'] = startDate.value!.toIso8601String();
      }

      if (endDate.value != null) {
        params['endDate'] = endDate.value!.toIso8601String();
      }

      final response = await _api.get(
        '/api/warehouse/invoices',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        // Safe null check for data
        final List<dynamic> invoiceList = data['data'] as List? ?? [];

        invoices.value = invoiceList
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>? ?? {}))
            .toList();

        _calculateSummary();
      } else {
        // Clear invoices on failure
        invoices.clear();
        totalAmount.value = 0.0;
        totalPaid.value = 0.0;
        totalOutstanding.value = 0.0;

        // Show error message
        if (response.data != null) {
          final message =
              response.data['message']?.toString() ?? 'Failed to load invoices';
          AppSnackbar.error(kDanger, 'Error', message);
        }
      }
    } catch (e) {
      print('❌ Error loading invoices: $e');
      // Clear invoices on error
      invoices.clear();
      totalAmount.value = 0.0;
      totalPaid.value = 0.0;
      totalOutstanding.value = 0.0;

      AppSnackbar.error(kDanger, 'Error', 'Failed to load invoices: $e');
    } finally {
      isLoading(false);
    }
  }

  void _calculateSummary() {
    totalAmount.value = invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
    totalPaid.value = invoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);
    totalOutstanding.value = totalAmount.value - totalPaid.value;
  }

  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      isCreating(true);

      final response = await _api.post(
        '/api/warehouse/invoices',
        body: invoiceData,
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Invoice created successfully!\nJournal entry created',
        );
        await fetchInvoices();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to create invoice',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to create invoice: $e');
    } finally {
      isCreating(false);
    }
  }

  Future<void> deleteInvoice(String id, String invoiceNumber) async {
    try {
      final response = await _api.delete('/api/warehouse/invoices/$id');

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Invoice $invoiceNumber deleted successfully',
        );
        await fetchInvoices();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to delete invoice',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to delete invoice: $e');
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchInvoices();
  }

  void filterByCustomer(String customerId) {
    selectedCustomerId.value = customerId;
    fetchInvoices();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    fetchInvoices();
  }

  void clearFilters() {
    selectedFilter.value = 'All';
    selectedCustomerId.value = '';
    startDate.value = null;
    endDate.value = null;
    fetchInvoices();
  }

  // ==================== EXPORT FUNCTIONS ====================

  void exportInvoices() {
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
              'Export Invoices',
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
                exportToExcelFile();
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

  // ==================== SINGLE INVOICE EXPORT FUNCTIONS (Web + Mobile) ====================

  // Main entry point for single invoice PDF export
  Future<void> exportSingleInvoiceToPdf(Invoice invoice) async {
    if (GetPlatform.isWeb) {
      await _exportSingleInvoiceToPdfWeb(invoice);
    } else {
      await _exportSingleInvoiceToPdfMobile(invoice);
    }
  }

  // Main entry point for single invoice Excel export
  Future<void> exportSingleInvoiceToExcel(Invoice invoice) async {
    if (GetPlatform.isWeb) {
      await _exportSingleInvoiceToExcelWeb(invoice);
    } else {
      await _exportSingleInvoiceToExcelMobile(invoice);
    }
  }

  // Mobile PDF Export
  Future<void> _exportSingleInvoiceToPdfMobile(Invoice invoice) async {
    try {
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

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _singleInvoicePdfHeader(),
          footer: (ctx) => _pdfFooter(ctx),
          build: (ctx) => [_singleInvoiceDetailsSection(invoice)],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Invoice ${invoice.invoiceNumber} exported to PDF',
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
    }
  }

  // Web PDF Export
  Future<void> _exportSingleInvoiceToPdfWeb(Invoice invoice) async {
    try {
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

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _singleInvoicePdfHeader(),
          footer: (ctx) => _pdfFooter(ctx),
          build: (ctx) => [_singleInvoiceDetailsSection(invoice)],
        ),
      );

      final pdfBytes = await pdf.save();

      // Web-specific download
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Invoice ${invoice.invoiceNumber} exported to PDF',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
    }
  }

  // Mobile Excel Export
  Future<void> _exportSingleInvoiceToExcelMobile(Invoice invoice) async {
    try {
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

      final excelFile = Excel.createExcel();

      // Invoice Details Sheet
      final invoiceSheet = excelFile['Invoice'];

      _excelSetCell(
        invoiceSheet,
        0,
        0,
        'INVOICE',
        bold: true,
        fontSize: 16,
        bgColor: '1A237E',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(invoiceSheet, 1, 0, 'Invoice Number:', bold: true);
      _excelSetCell(invoiceSheet, 1, 1, invoice.invoiceNumber);
      _excelSetCell(invoiceSheet, 2, 0, 'Date:', bold: true);
      _excelSetCell(
        invoiceSheet,
        2,
        1,
        DateFormat('dd MMM yyyy').format(invoice.date),
      );
      _excelSetCell(invoiceSheet, 3, 0, 'Due Date:', bold: true);
      _excelSetCell(
        invoiceSheet,
        3,
        1,
        DateFormat('dd MMM yyyy').format(invoice.dueDate),
      );
      _excelSetCell(invoiceSheet, 4, 0, 'Status:', bold: true);
      _excelSetCell(invoiceSheet, 4, 1, invoice.status);
      _excelSetCell(invoiceSheet, 6, 0, 'Customer:', bold: true, fontSize: 12);
      _excelSetCell(invoiceSheet, 7, 0, invoice.customerName);

      // Items table
      int row = 9;
      _excelSetCell(
        invoiceSheet,
        row,
        0,
        'Description',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        1,
        'Quantity',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        2,
        'Unit Price',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        'Amount',
        bold: true,
        bgColor: 'E8EAF6',
      );
      row++;

      for (final item in invoice.items) {
        _excelSetCell(invoiceSheet, row, 0, item.description);
        _excelSetCell(invoiceSheet, row, 1, item.quantity);
        _excelSetCell(invoiceSheet, row, 2, item.unitPrice);
        _excelSetCell(invoiceSheet, row, 3, item.amount);
        row++;
      }

      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Subtotal:', bold: true);
      _excelSetCell(invoiceSheet, row, 3, invoice.subtotal);
      row++;
      if (invoice.taxTotal > 0) {
        _excelSetCell(invoiceSheet, row, 2, 'Tax:', bold: true);
        _excelSetCell(invoiceSheet, row, 3, invoice.taxTotal);
        row++;
      }
      if (invoice.discount > 0) {
        _excelSetCell(invoiceSheet, row, 2, 'Discount:', bold: true);
        _excelSetCell(invoiceSheet, row, 3, invoice.discount);
        row++;
      }
      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Total:', bold: true, fontSize: 12);
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        invoice.totalAmount,
        bold: true,
        fontColor: '1A237E',
      );
      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Amount Paid:', bold: true);
      _excelSetCell(invoiceSheet, row, 3, invoice.paidAmount);
      row++;
      _excelSetCell(
        invoiceSheet,
        row,
        2,
        'Balance Due:',
        bold: true,
        fontSize: 12,
      );
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        invoice.outstanding,
        bold: true,
        fontColor: invoice.outstanding > 0 ? 'C62828' : '2E7D32',
      );

      if (invoice.notes.isNotEmpty) {
        row += 2;
        _excelSetCell(invoiceSheet, row, 0, 'Notes:', bold: true);
        row++;
        _excelSetCell(invoiceSheet, row, 0, invoice.notes);
      }

      invoiceSheet.setColumnWidth(0, 40);
      invoiceSheet.setColumnWidth(1, 12);
      invoiceSheet.setColumnWidth(2, 15);
      invoiceSheet.setColumnWidth(3, 15);

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Invoice ${invoice.invoiceNumber} exported to Excel',
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
    }
  }

  // Web Excel Export
  Future<void> _exportSingleInvoiceToExcelWeb(Invoice invoice) async {
    try {
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

      final excelFile = Excel.createExcel();

      // Invoice Details Sheet
      final invoiceSheet = excelFile['Invoice'];

      _excelSetCell(
        invoiceSheet,
        0,
        0,
        'INVOICE',
        bold: true,
        fontSize: 16,
        bgColor: '1A237E',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(invoiceSheet, 1, 0, 'Invoice Number:', bold: true);
      _excelSetCell(invoiceSheet, 1, 1, invoice.invoiceNumber);
      _excelSetCell(invoiceSheet, 2, 0, 'Date:', bold: true);
      _excelSetCell(
        invoiceSheet,
        2,
        1,
        DateFormat('dd MMM yyyy').format(invoice.date),
      );
      _excelSetCell(invoiceSheet, 3, 0, 'Due Date:', bold: true);
      _excelSetCell(
        invoiceSheet,
        3,
        1,
        DateFormat('dd MMM yyyy').format(invoice.dueDate),
      );
      _excelSetCell(invoiceSheet, 4, 0, 'Status:', bold: true);
      _excelSetCell(invoiceSheet, 4, 1, invoice.status);
      _excelSetCell(invoiceSheet, 6, 0, 'Customer:', bold: true, fontSize: 12);
      _excelSetCell(invoiceSheet, 7, 0, invoice.customerName);

      // Items table
      int row = 9;
      _excelSetCell(
        invoiceSheet,
        row,
        0,
        'Description',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        1,
        'Quantity',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        2,
        'Unit Price',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        'Amount',
        bold: true,
        bgColor: 'E8EAF6',
      );
      row++;

      for (final item in invoice.items) {
        _excelSetCell(invoiceSheet, row, 0, item.description);
        _excelSetCell(invoiceSheet, row, 1, item.quantity);
        _excelSetCell(invoiceSheet, row, 2, item.unitPrice);
        _excelSetCell(invoiceSheet, row, 3, item.amount);
        row++;
      }

      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Subtotal:', bold: true);
      _excelSetCell(invoiceSheet, row, 3, invoice.subtotal);
      row++;
      if (invoice.taxTotal > 0) {
        _excelSetCell(invoiceSheet, row, 2, 'Tax:', bold: true);
        _excelSetCell(invoiceSheet, row, 3, invoice.taxTotal);
        row++;
      }
      if (invoice.discount > 0) {
        _excelSetCell(invoiceSheet, row, 2, 'Discount:', bold: true);
        _excelSetCell(invoiceSheet, row, 3, invoice.discount);
        row++;
      }
      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Total:', bold: true, fontSize: 12);
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        invoice.totalAmount,
        bold: true,
        fontColor: '1A237E',
      );
      row++;
      _excelSetCell(invoiceSheet, row, 2, 'Amount Paid:', bold: true);
      _excelSetCell(invoiceSheet, row, 3, invoice.paidAmount);
      row++;
      _excelSetCell(
        invoiceSheet,
        row,
        2,
        'Balance Due:',
        bold: true,
        fontSize: 12,
      );
      _excelSetCell(
        invoiceSheet,
        row,
        3,
        invoice.outstanding,
        bold: true,
        fontColor: invoice.outstanding > 0 ? 'C62828' : '2E7D32',
      );

      if (invoice.notes.isNotEmpty) {
        row += 2;
        _excelSetCell(invoiceSheet, row, 0, 'Notes:', bold: true);
        row++;
        _excelSetCell(invoiceSheet, row, 0, invoice.notes);
      }

      invoiceSheet.setColumnWidth(0, 40);
      invoiceSheet.setColumnWidth(1, 12);
      invoiceSheet.setColumnWidth(2, 15);
      invoiceSheet.setColumnWidth(3, 15);

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      // Web-specific download
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'invoice_${invoice.invoiceNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Invoice ${invoice.invoiceNumber} exported to Excel',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
    }
  }

  pw.Widget _singleInvoicePdfHeader() {
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
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
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

  pw.Widget _singleInvoiceDetailsSection(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Invoice Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice Number:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(invoice.date),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Due Date:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy').format(invoice.dueDate),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Status:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  invoice.status,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice.status == 'Paid'
                        ? PdfColors.green700
                        : (invoice.isOverdue
                              ? PdfColors.red700
                              : PdfColors.orange700),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        // Customer Info
        pw.Text(
          'Bill To:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 16),
        // Items Table
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
                flex: 4,
                child: pw.Text(
                  'Description',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Qty',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Unit Price',
                  textAlign: pw.TextAlign.right,
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
        ...invoice.items
            .map(
              (item) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        item.description,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        item.quantity.toString(),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(item.unitPrice),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(item.amount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        pw.Divider(),
        // Totals
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Column(
            children: [
              _pdfTotalRow('Subtotal', invoice.subtotal),
              if (invoice.taxTotal > 0) _pdfTotalRow('Tax', invoice.taxTotal),
              if (invoice.discount > 0)
                _pdfTotalRow('Discount', invoice.discount, isNegative: true),
              pw.Divider(),
              _pdfTotalRow('Total', invoice.totalAmount, isBold: true),
              _pdfTotalRow(
                'Amount Paid',
                invoice.paidAmount,
                color: PdfColors.green700,
              ),
              _pdfTotalRow(
                'Balance Due',
                invoice.outstanding,
                isBold: true,
                color: invoice.outstanding > 0
                    ? PdfColors.red700
                    : PdfColors.green700,
              ),
            ],
          ),
        ),
        if (invoice.notes.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            invoice.notes,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ],
    );
  }

  pw.Widget _pdfTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isNegative = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '${isNegative ? '- ' : ''}${_formatAmount(amount)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (isBold ? PdfColors.black : PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BULK EXPORT FUNCTIONS (Web + Mobile) ====================

  // Main entry point for bulk PDF export
  Future<void> exportToPdf() async {
    if (GetPlatform.isWeb) {
      await _exportToPdfWeb();
    } else {
      await _exportToPdfMobile();
    }
  }

  // Main entry point for bulk Excel export
  Future<void> exportToExcelFile() async {
    if (GetPlatform.isWeb) {
      await _exportToExcelWeb();
    } else {
      await _exportToExcelMobile();
    }
  }

  // Mobile Bulk PDF Export
  Future<void> _exportToPdfMobile() async {
    try {
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
            _pdfInvoicesSection(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${invoices.length} invoices exported to PDF',
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
    }
  }

  // Web Bulk PDF Export
  Future<void> _exportToPdfWeb() async {
    try {
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
            _pdfInvoicesSection(),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${invoices.length} invoices exported to PDF',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
    }
  }

  // Mobile Bulk Excel Export
  Future<void> _exportToExcelMobile() async {
    try {
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

      final excelFile = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Invoices Report',
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
      if (selectedCustomerId.value.isNotEmpty) {
        final customer = customers.firstWhere(
          (c) => c['_id'] == selectedCustomerId.value,
          orElse: () => {},
        );
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Customer: ${customer['name'] ?? ''}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }

      _excelSetCell(
        summarySheet,
        5,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Invoices', invoices.length.toString()],
        ['Total Amount', _formatAmount(totalAmount.value)],
        ['Total Paid', _formatAmount(totalPaid.value)],
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(
            summarySheet,
            6 + r,
            c,
            summaryRows[r][c],
            bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5',
          );
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Invoices Sheet
      final invoicesSheet = excelFile['Invoices'];
      final headers = [
        'Invoice #',
        'Date',
        'Due Date',
        'Customer',
        'Subtotal',
        'Tax',
        'Discount',
        'Total Amount',
        'Paid Amount',
        'Outstanding',
        'Status',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          invoicesSheet,
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
      for (final invoice in invoices) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(
          invoicesSheet,
          row,
          0,
          invoice.invoiceNumber,
          bgColor: bg,
        );
        _excelSetCell(
          invoicesSheet,
          row,
          1,
          DateFormat('dd MMM yyyy').format(invoice.date),
          bgColor: bg,
        );
        _excelSetCell(
          invoicesSheet,
          row,
          2,
          DateFormat('dd MMM yyyy').format(invoice.dueDate),
          bgColor: bg,
        );
        _excelSetCell(invoicesSheet, row, 3, invoice.customerName, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 4, invoice.subtotal, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 5, invoice.taxTotal, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 6, invoice.discount, bgColor: bg);
        _excelSetCell(
          invoicesSheet,
          row,
          7,
          invoice.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          8,
          invoice.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          9,
          invoice.outstanding,
          bgColor: bg,
          fontColor: invoice.outstanding > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          10,
          invoice.status,
          bgColor: invoice.status == 'Paid'
              ? 'E8F5E9'
              : (invoice.isOverdue ? 'FFEBEE' : 'FFF8E1'),
          fontColor: invoice.status == 'Paid'
              ? '2E7D32'
              : (invoice.isOverdue ? 'C62828' : 'F39C12'),
        );
        _excelSetCell(
          invoicesSheet,
          row,
          11,
          invoice.notes.isEmpty ? '-' : invoice.notes,
          bgColor: bg,
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        invoicesSheet,
        row,
        7,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoicesSheet,
        row,
        8,
        totalPaid.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        invoicesSheet,
        row,
        9,
        totalOutstanding.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [
        15.0,
        12.0,
        12.0,
        25.0,
        12.0,
        12.0,
        12.0,
        15.0,
        15.0,
        15.0,
        12.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        invoicesSheet.setColumnWidth(i, colWidths[i]);
      }

      // Items Sheet
      final itemsSheet = excelFile['Invoice Items'];
      final itemHeaders = [
        'Invoice #',
        'Customer',
        'Description',
        'Quantity',
        'Unit Price',
        'Amount',
        'Tax Rate',
        'Tax Amount',
      ];

      for (int i = 0; i < itemHeaders.length; i++) {
        _excelSetCell(
          itemsSheet,
          0,
          i,
          itemHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int itemRow = 1;
      for (final invoice in invoices) {
        for (final item in invoice.items) {
          final bg = itemRow.isEven ? 'F5F5F5' : 'FFFFFF';
          _excelSetCell(
            itemsSheet,
            itemRow,
            0,
            invoice.invoiceNumber,
            bgColor: bg,
          );
          _excelSetCell(
            itemsSheet,
            itemRow,
            1,
            invoice.customerName,
            bgColor: bg,
          );
          _excelSetCell(itemsSheet, itemRow, 2, item.description, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 3, item.quantity, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 4, item.unitPrice, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 5, item.amount, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 6, item.taxRate, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 7, item.taxAmount, bgColor: bg);
          itemRow++;
        }
      }

      final itemColWidths = [15.0, 25.0, 40.0, 10.0, 12.0, 12.0, 10.0, 12.0];
      for (int i = 0; i < itemColWidths.length; i++) {
        itemsSheet.setColumnWidth(i, itemColWidths[i]);
      }

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${invoices.length} invoices exported to Excel',
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
    }
  }

  // Web Bulk Excel Export
  Future<void> _exportToExcelWeb() async {
    try {
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

      final excelFile = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Invoices Report',
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
      if (selectedCustomerId.value.isNotEmpty) {
        final customer = customers.firstWhere(
          (c) => c['_id'] == selectedCustomerId.value,
          orElse: () => {},
        );
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Customer: ${customer['name'] ?? ''}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }

      _excelSetCell(
        summarySheet,
        5,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Invoices', invoices.length.toString()],
        ['Total Amount', _formatAmount(totalAmount.value)],
        ['Total Paid', _formatAmount(totalPaid.value)],
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(
            summarySheet,
            6 + r,
            c,
            summaryRows[r][c],
            bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5',
          );
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Invoices Sheet
      final invoicesSheet = excelFile['Invoices'];
      final headers = [
        'Invoice #',
        'Date',
        'Due Date',
        'Customer',
        'Subtotal',
        'Tax',
        'Discount',
        'Total Amount',
        'Paid Amount',
        'Outstanding',
        'Status',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          invoicesSheet,
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
      for (final invoice in invoices) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(
          invoicesSheet,
          row,
          0,
          invoice.invoiceNumber,
          bgColor: bg,
        );
        _excelSetCell(
          invoicesSheet,
          row,
          1,
          DateFormat('dd MMM yyyy').format(invoice.date),
          bgColor: bg,
        );
        _excelSetCell(
          invoicesSheet,
          row,
          2,
          DateFormat('dd MMM yyyy').format(invoice.dueDate),
          bgColor: bg,
        );
        _excelSetCell(invoicesSheet, row, 3, invoice.customerName, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 4, invoice.subtotal, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 5, invoice.taxTotal, bgColor: bg);
        _excelSetCell(invoicesSheet, row, 6, invoice.discount, bgColor: bg);
        _excelSetCell(
          invoicesSheet,
          row,
          7,
          invoice.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          8,
          invoice.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          9,
          invoice.outstanding,
          bgColor: bg,
          fontColor: invoice.outstanding > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(
          invoicesSheet,
          row,
          10,
          invoice.status,
          bgColor: invoice.status == 'Paid'
              ? 'E8F5E9'
              : (invoice.isOverdue ? 'FFEBEE' : 'FFF8E1'),
          fontColor: invoice.status == 'Paid'
              ? '2E7D32'
              : (invoice.isOverdue ? 'C62828' : 'F39C12'),
        );
        _excelSetCell(
          invoicesSheet,
          row,
          11,
          invoice.notes.isEmpty ? '-' : invoice.notes,
          bgColor: bg,
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        invoicesSheet,
        row,
        7,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        invoicesSheet,
        row,
        8,
        totalPaid.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        invoicesSheet,
        row,
        9,
        totalOutstanding.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [
        15.0,
        12.0,
        12.0,
        25.0,
        12.0,
        12.0,
        12.0,
        15.0,
        15.0,
        15.0,
        12.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        invoicesSheet.setColumnWidth(i, colWidths[i]);
      }

      // Items Sheet
      final itemsSheet = excelFile['Invoice Items'];
      final itemHeaders = [
        'Invoice #',
        'Customer',
        'Description',
        'Quantity',
        'Unit Price',
        'Amount',
        'Tax Rate',
        'Tax Amount',
      ];

      for (int i = 0; i < itemHeaders.length; i++) {
        _excelSetCell(
          itemsSheet,
          0,
          i,
          itemHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int itemRow = 1;
      for (final invoice in invoices) {
        for (final item in invoice.items) {
          final bg = itemRow.isEven ? 'F5F5F5' : 'FFFFFF';
          _excelSetCell(
            itemsSheet,
            itemRow,
            0,
            invoice.invoiceNumber,
            bgColor: bg,
          );
          _excelSetCell(
            itemsSheet,
            itemRow,
            1,
            invoice.customerName,
            bgColor: bg,
          );
          _excelSetCell(itemsSheet, itemRow, 2, item.description, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 3, item.quantity, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 4, item.unitPrice, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 5, item.amount, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 6, item.taxRate, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 7, item.taxAmount, bgColor: bg);
          itemRow++;
        }
      }

      final itemColWidths = [15.0, 25.0, 40.0, 10.0, 12.0, 12.0, 10.0, 12.0];
      for (int i = 0; i < itemColWidths.length; i++) {
        itemsSheet.setColumnWidth(i, itemColWidths[i]);
      }

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      // Web-specific download
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'invoices_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
        )
        ..click();
      html.Url.revokeObjectUrl(url);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${invoices.length} invoices exported to Excel',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
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
                'Invoices Report',
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
      child: pw.Column(
        children: [
          pw.Text(
            'Period: ${selectedFilter.value}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Invoices',
                invoices.length.toString(),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Total Amount',
                _formatAmount(totalAmount.value),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Total Paid',
                _formatAmount(totalPaid.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Total Outstanding',
                _formatAmount(totalOutstanding.value),
                PdfColors.red700,
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

  pw.Widget _pdfInvoicesSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Invoice Details',
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
                  'Invoice #',
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
                  'Due Date',
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
                  'Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Paid',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Outstanding',
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
        ...invoices
            .map(
              (invoice) => pw.Container(
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
                        invoice.invoiceNumber,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(invoice.date),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(invoice.dueDate),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        invoice.customerName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(invoice.totalAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.indigo700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(invoice.paidAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.green700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(invoice.outstanding),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: invoice.outstanding > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        invoice.status,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: invoice.status == 'Paid'
                              ? PdfColors.green700
                              : (invoice.isOverdue
                                    ? PdfColors.red700
                                    : PdfColors.orange700),
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
                flex: 9,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalAmount.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalPaid.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalOutstanding.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  void printInvoices() {
    AppSnackbar.info('Print', 'Preparing invoices report...');
  }

  void printSingleInvoice(Invoice invoice) {
    AppSnackbar.info('Print', 'Printing invoice ${invoice.invoiceNumber}');
  }

  void _handleSessionExpired() {
    AppSnackbar.error(kWarning, 'Session Expired', 'Please login again');
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxTotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.discount,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.notes,
  });

  double get outstanding => totalAmount - paidAmount;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != 'Paid';

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Safe method to get string value
    String getString(dynamic value) => value?.toString() ?? '';

    // Safe method to get double value
    double getDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Safe method to get DateTime
    DateTime getDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    // Safe method to get customer ID from nested object or string
    String getCustomerId(dynamic value) {
      if (value == null) return '';
      if (value is Map) {
        return value['_id']?.toString() ?? '';
      }
      return value.toString();
    }

    // Safe method to get items list
    List<InvoiceItem> getItems(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is Map) {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            return InvoiceItem.fromJson(Map<String, dynamic>.from(e));
          }
          return InvoiceItem.fromJson({});
        }).toList();
      }
      return [];
    }

    return Invoice(
      id: getString(json['_id']),
      invoiceNumber: getString(json['invoiceNumber']),
      customerId: getCustomerId(json['customerId']),
      customerName: getString(json['customerName']),
      date: getDateTime(json['date']),
      dueDate: getDateTime(json['dueDate']),
      items: getItems(json['items']),
      subtotal: getDouble(json['subtotal']),
      taxTotal: getDouble(json['taxTotal']),
      discount: getDouble(json['discount']),
      totalAmount: getDouble(json['totalAmount']),
      paidAmount: getDouble(json['paidAmount']),
      status: getString(json['status']),
      notes: getString(json['notes']),
    );
  }
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;
  final double taxRate;
  final double taxAmount;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.taxRate,
    required this.taxAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    // Safe method to get string value
    String getString(dynamic value) => value?.toString() ?? '';

    // Safe method to get double value
    double getDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Safe method to get int value
    int getInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return InvoiceItem(
      description: getString(json['description']),
      quantity: getInt(json['quantity']),
      unitPrice: getDouble(json['unitPrice']),
      amount: getDouble(json['amount']),
      taxRate: getDouble(json['taxRate']),
      taxAmount: getDouble(json['taxAmount']),
    );
  }
}
