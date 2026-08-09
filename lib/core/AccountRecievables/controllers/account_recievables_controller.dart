// core/AccountRecievables/controllers/account_recievables_controller.dart

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class AccountsReceivableController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  var customers = <Customer>[].obs;
  var filteredCustomers = <Customer>[].obs;
  var isLoading = true.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  var totalOutstanding = 0.0.obs;
  var totalOverdue = 0.0.obs;
  var totalDueThisWeek = 0.0.obs;
  var totalDueThisMonth = 0.0.obs;
  var activeCustomers = 0.obs;

  // ✅ Bank accounts for payment dropdown
  var bankAccounts = <Map<String, dynamic>>[].obs;

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
    fetchAllData();
    fetchBankAccounts();
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchCustomers(), fetchSummary()]);
  }

  // ─── Fetch Bank Accounts ──────────────────────────────────────────
  Future<void> fetchBankAccounts() async {
    try {
      final response = await _apiClient.get('/api/bank-accounts');
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          bankAccounts.value = List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
    }
  }

  // ─── Fetch Summary ────────────────────────────────────────────────
  Future<void> fetchSummary() async {
    try {
      final response = await _apiClient.get('/api/accounts-receivable/summary');

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          totalOutstanding.value = _toDouble(data['data']['totalOutstanding']);
          totalOverdue.value = _toDouble(data['data']['overdue']);
          totalDueThisWeek.value = _toDouble(data['data']['dueThisWeek']);
          totalDueThisMonth.value = _toDouble(data['data']['dueThisMonth']);
          activeCustomers.value = data['data']['activeCustomers'] ?? 0;
        }
      }
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  // ─── Fetch Customers ──────────────────────────────────────────────
  Future<void> fetchCustomers() async {
    try {
      isLoading(true);

      Map<String, dynamic> queryParams = {};
      if (selectedFilter.value != 'All') {
        queryParams['filter'] = selectedFilter.value;
      }

      final response = await _apiClient.get(
        '/api/accounts-receivable/customers',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          customers.value = (data['data'] as List)
              .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _applyLocalSearch();
          await fetchSummary();
          // Prefer live sum from customer rows if summary still lags/caches
          final fromCustomers = customers.fold<double>(
            0,
            (s, c) => s + c.outstandingAmount,
          );
          if (fromCustomers > 0 && totalOutstanding.value == 0) {
            totalOutstanding.value = fromCustomers;
          }
        }
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to load customers: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Search ────────────────────────────────────────────────────────
  void searchCustomers(String query) {
    searchQuery.value = query;
    _applyLocalSearch();
  }

  void _applyLocalSearch() {
    if (searchQuery.value.isEmpty) {
      filteredCustomers.value = customers;
    } else {
      filteredCustomers.value = customers
          .where(
            (customer) =>
                customer.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                customer.email.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                customer.phone.contains(searchQuery.value),
          )
          .toList();
    }
  }

  // ─── Create Customer ──────────────────────────────────────────────
  Future<void> createCustomer(Map<String, dynamic> customerData) async {
    try {
      isLoading(true);

      final response = await _apiClient.post(
        '/api/accounts-receivable/customers',
        body: customerData,
      );

      if (response.success && response.statusCode == 201) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Customer added successfully',
        );
        await fetchCustomers();
        await fetchSummary();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to add customer';
        AppSnackbar.error(Colors.red, 'Error', errorMsg);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to add customer: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── ✅ FIXED: Record Payment ─────────────────────────────────────
  Future<void> recordPayment({
    required String customerId,
    required String invoiceId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String reference,
    required String? bankAccountId,
    String notes = '',
  }) async {
    try {
      isLoading(true);

      final body = {
        'customerId': customerId,
        'invoiceId': invoiceId,
        'amount': amount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'bankAccountId': bankAccountId, // ✅ Send null for Cash
        'notes': notes,
      };

      print('📤 Recording payment: ${json.encode(body)}');

      // ✅ FIX: Correct endpoint
      final response = await _apiClient.post(
        '/api/accounts-receivable/payments', // ✅ Fixed endpoint
        body: body,
      );

      print('📥 Payment response: ${response.statusCode}');

      if (response.success &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        AppSnackbar.success(
          Colors.green,
          '✅ Success',
          'Payment recorded successfully!\nJournal entry created',
          duration: const Duration(seconds: 3),
        );
        // ✅ Refresh all data
        await fetchCustomers();
        await fetchSummary();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to record payment';
        AppSnackbar.error(Colors.red, 'Error', errorMsg);
      }
    } catch (e) {
      print('❌ Error recording payment: $e');
      AppSnackbar.error(Colors.red, 'Error', 'Failed to record payment: $e');
    } finally {
      isLoading(false);
    }
  }

  // ─── Filter ────────────────────────────────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchCustomers();
  }

  // ─── View Invoices ───────────────────────────────────────────────
  void viewInvoices(Customer customer) {
    // TODO: Navigate to invoices list for this customer
    AppSnackbar.success(
      Colors.blue,
      'Invoices',
      'Viewing invoices for ${customer.name}',
      duration: const Duration(seconds: 2),
    );
  }

  // ─── ✅ FIXED: Show Record Payment Dialog ─────────────────────────
  void showRecordPayment(Customer customer) {
    // TODO: Show payment dialog with invoice selection
    AppSnackbar.success(
      Colors.green,
      'Record Payment',
      'Recording payment for ${customer.name}',
    );
  }

  // ─── Get Display Customers ────────────────────────────────────────
  List<Customer> get displayCustomers {
    if (searchQuery.value.isNotEmpty) {
      return filteredCustomers;
    }
    return customers;
  }

  // ─── Export Functions ─────────────────────────────────────────────
  void exportReport() {
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
              'Export Accounts Receivable',
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

  // ─── PDF Export ────────────────────────────────────────────────────
  Future<void> exportToPdf() async {
    try {
      if (!kIsWeb) {
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

      final branding = await PdfBrandingBundle.load();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => branding.buildHeader(
            reportTitle: 'Accounts Receivable Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfCustomersSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'accounts_receivable_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
          '${displayCustomers.length} customers exported to PDF',
          duration: const Duration(seconds: 2),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${displayCustomers.length} customers exported to PDF',
          duration: const Duration(seconds: 2),
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
                'Total Outstanding',
                _formatAmount(totalOutstanding.value),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'Overdue',
                _formatAmount(totalOverdue.value),
                PdfColors.orange700,
              ),
              _pdfSummaryItem(
                'Due This Week',
                _formatAmount(totalDueThisWeek.value),
                accent,
              ),
              _pdfSummaryItem(
                'Due This Month',
                _formatAmount(totalDueThisMonth.value),
                accent,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Active Customers',
                activeCustomers.value.toString(),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Total Customers',
                displayCustomers.length.toString(),
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
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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

  pw.Widget _pdfCustomersSection() {
    final dataToExport = displayCustomers;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Customer Details',
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
                flex: 3,
                child: pw.Text(
                  'Customer Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Phone',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Invoices',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Amount',
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
            ],
          ),
        ),
        ...dataToExport
            .map(
              (customer) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        customer.name,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        customer.phone,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        customer.totalInvoices.toString(),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(customer.totalAmount),
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
                        _formatAmount(customer.paidAmount),
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
                        _formatAmount(customer.outstandingAmount),
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
                  _formatAmount(
                    dataToExport.fold(0.0, (sum, c) => sum + c.totalAmount),
                  ),
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
                  _formatAmount(
                    dataToExport.fold(0.0, (sum, c) => sum + c.paidAmount),
                  ),
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
                  _formatAmount(
                    dataToExport.fold(
                      0.0,
                      (sum, c) => sum + c.outstandingAmount,
                    ),
                  ),
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

  // ─── Excel Export ──────────────────────────────────────────────────
  Future<void> exportToExcel() async {
    try {
      if (!kIsWeb) {
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
      final dataToExport = displayCustomers;

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Accounts Receivable Report',
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
      if (searchQuery.value.isNotEmpty) {
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Search: ${searchQuery.value}',
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
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
        ['Overdue', _formatAmount(totalOverdue.value)],
        ['Due This Week', _formatAmount(totalDueThisWeek.value)],
        ['Due This Month', _formatAmount(totalDueThisMonth.value)],
        ['Active Customers', activeCustomers.value.toString()],
        ['Total Customers', dataToExport.length.toString()],
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

      // Customers Sheet
      final customersSheet = excel['Customers'];
      final headers = [
        'Customer Name',
        'Email',
        'Phone',
        'Total Invoices',
        'Total Amount',
        'Paid Amount',
        'Outstanding Amount',
        'Last Payment Date',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          customersSheet,
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
      for (final customer in dataToExport) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(customersSheet, row, 0, customer.name, bgColor: bg);
        _excelSetCell(customersSheet, row, 1, customer.email, bgColor: bg);
        _excelSetCell(customersSheet, row, 2, customer.phone, bgColor: bg);
        _excelSetCell(
          customersSheet,
          row,
          3,
          customer.totalInvoices,
          bgColor: bg,
        );
        _excelSetCell(
          customersSheet,
          row,
          4,
          customer.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          customersSheet,
          row,
          5,
          customer.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          customersSheet,
          row,
          6,
          customer.outstandingAmount,
          bgColor: bg,
          fontColor: 'C62828',
        );
        _excelSetCell(
          customersSheet,
          row,
          7,
          customer.lastPaymentDate != null
              ? DateFormat('dd MMM yyyy').format(customer.lastPaymentDate!)
              : '-',
          bgColor: bg,
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        customersSheet,
        row,
        3,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        customersSheet,
        row,
        4,
        dataToExport.fold(0.0, (sum, c) => sum + c.totalAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '1A237E',
      );
      _excelSetCell(
        customersSheet,
        row,
        5,
        dataToExport.fold(0.0, (sum, c) => sum + c.paidAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        customersSheet,
        row,
        6,
        dataToExport.fold(0.0, (sum, c) => sum + c.outstandingAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [30.0, 25.0, 15.0, 12.0, 15.0, 15.0, 15.0, 15.0];
      for (int i = 0; i < colWidths.length; i++) {
        customersSheet.setColumnWidth(i, colWidths[i]);
      }

      // Invoices Sheet
      final invoicesSheet = excel['Invoices'];
      final invoiceHeaders = [
        'Customer',
        'Invoice #',
        'Date',
        'Due Date',
        'Amount',
        'Paid',
        'Outstanding',
        'Status',
      ];

      for (int i = 0; i < invoiceHeaders.length; i++) {
        _excelSetCell(
          invoicesSheet,
          0,
          i,
          invoiceHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int invoiceRow = 1;
      for (final customer in dataToExport) {
        for (final invoice in customer.invoices) {
          final bg = invoiceRow.isEven ? 'F5F5F5' : 'FFFFFF';
          double outstanding = invoice.amount - invoice.paidAmount;
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            0,
            customer.name,
            bgColor: bg,
          );
          _excelSetCell(invoicesSheet, invoiceRow, 1, invoice.id, bgColor: bg);
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            2,
            DateFormat('dd MMM yyyy').format(invoice.date),
            bgColor: bg,
          );
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            3,
            DateFormat('dd MMM yyyy').format(invoice.dueDate),
            bgColor: bg,
          );
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            4,
            invoice.amount,
            bgColor: bg,
            fontColor: '1A237E',
          );
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            5,
            invoice.paidAmount,
            bgColor: bg,
            fontColor: '2E7D32',
          );
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            6,
            outstanding,
            bgColor: bg,
            fontColor: outstanding > 0 ? 'C62828' : '2E7D32',
          );
          _excelSetCell(
            invoicesSheet,
            invoiceRow,
            7,
            invoice.status,
            bgColor: invoice.status == 'Paid'
                ? 'E8F5E9'
                : (invoice.status == 'Overdue' ? 'FFEBEE' : 'FFF8E1'),
            fontColor: invoice.status == 'Paid'
                ? '2E7D32'
                : (invoice.status == 'Overdue' ? 'C62828' : 'F39C12'),
          );
          invoiceRow++;
        }
      }

      final invoiceColWidths = [25.0, 15.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0];
      for (int i = 0; i < invoiceColWidths.length; i++) {
        invoicesSheet.setColumnWidth(i, invoiceColWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'accounts_receivable_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([
          bytes,
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${dataToExport.length} customers exported to Excel',
          duration: const Duration(seconds: 2),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${dataToExport.length} customers exported to Excel',
          duration: const Duration(seconds: 2),
        );

        await OpenFile.open(file.path);
      }
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

  void printReport() {
    AppSnackbar.success(
      Colors.green,
      'Print',
      'Preparing Accounts Receivable report...',
      duration: const Duration(seconds: 2),
    );
  }

  double _getDueThisWeekAmount() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    double total = 0;
    for (var customer in customers) {
      for (var invoice in customer.invoices) {
        if (invoice.dueDate.isAfter(now) &&
            invoice.dueDate.isBefore(endOfWeek) &&
            invoice.status != 'Paid') {
          total += invoice.amount - invoice.paidAmount;
        }
      }
    }
    return total;
  }

  double _getDueThisMonthAmount() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    double total = 0;
    for (var customer in customers) {
      for (var invoice in customer.invoices) {
        if (invoice.dueDate.isAfter(now) &&
            invoice.dueDate.isBefore(endOfMonth) &&
            invoice.status != 'Paid') {
          total += invoice.amount - invoice.paidAmount;
        }
      }
    }
    return total;
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }

  bool _isDueThisWeek(DateTime dueDate) {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    return dueDate.isAfter(now) && dueDate.isBefore(endOfWeek);
  }

  bool _isDueThisMonth(DateTime dueDate) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return dueDate.isAfter(now) && dueDate.isBefore(endOfMonth);
  }
}

// ─────────────────────── MODELS ───────────────────────

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int totalInvoices;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final List<Invoice> invoices;
  final DateTime? lastPaymentDate;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalInvoices,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.invoices,
    this.lastPaymentDate,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final invoices = json['invoices'] != null
        ? (json['invoices'] as List)
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <Invoice>[];

    // Prefer API outstanding; fall back to sum of invoice lines
    double outstanding = _d(
      json['outstandingAmount'] ?? json['outstanding'],
    );
    if (outstanding == 0 && invoices.isNotEmpty) {
      outstanding = invoices.fold<double>(
        0,
        (s, inv) => s + (inv.amount - inv.paidAmount).clamp(0, double.infinity),
      );
    }

    return Customer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      totalInvoices: _i(json['invoiceCount'] ?? json['totalInvoices'] ?? invoices.length),
      totalAmount: _d(json['totalAmount']),
      paidAmount: _d(json['paidAmount']),
      outstandingAmount: outstanding,
      invoices: invoices,
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.tryParse(json['lastPaymentDate'].toString())
          : null,
    );
  }
}

class Invoice {
  final String id;
  final DateTime date;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final String status;

  Invoice({
    required this.id,
    required this.date,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
    required this.status,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['invoiceNumber']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.tryParse(json['invoiceDate']?.toString() ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
          DateTime.now(),
      amount: _d(json['totalAmount'] ?? json['amount'] ?? json['grandTotal']),
      paidAmount: _d(json['paidAmount']),
      status: json['status']?.toString() ??
          json['paymentStatus']?.toString() ??
          'Unpaid',
    );
  }
}
