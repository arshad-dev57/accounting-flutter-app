import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class CustomerController extends GetxController {
  var customers = <Customer>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  // Summary totals
  var totalCustomers = 0.obs;
  var activeCustomers = 0.obs;
  var totalOutstanding = 0.0.obs;
  var totalSales = 0.0.obs;

  final ApiClient _api = Get.find<ApiClient>();

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatAmount(double amount) {
    return '\$. ${amount.toStringAsFixed(2)}';
  }

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      isLoading(true);

      Map<String, dynamic> params = {};

      if (selectedFilter.value != 'All') {
        if (selectedFilter.value == 'Active') {
          params['status'] = 'active';
        } else if (selectedFilter.value == 'Inactive') {
          params['status'] = 'inactive';
        } else if (selectedFilter.value == 'With Balance') {
          // This will be filtered on client side
        }
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _api.get(
        '/api/accounts-receivable/customers',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        if (data['success']) {
          customers.value = (data['data'] as List)
              .map((e) => Customer.fromJson(e))
              .toList();

          _calculateSummary();
        }
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load customers: $e');
    } finally {
      isLoading(false);
    }
  }

  void _calculateSummary() {
    totalCustomers.value = customers.length;
    activeCustomers.value = customers.where((c) => c.isActive).length;
    totalOutstanding.value = customers.fold(
      0.0,
      (sum, c) => sum + c.outstandingAmount,
    );
    totalSales.value = customers.fold(0.0, (sum, c) => sum + c.totalAmount);
  }

  Future<void> createCustomer(Map<String, dynamic> customerData) async {
    try {
      isProcessing(true);

      final response = await _api.post(
        '/api/accounts-receivable/customers',
        body: customerData,
      );

      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Customer added successfully');
        await fetchCustomers();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to add customer',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to add customer: $e');
    } finally {
      isProcessing(false);
    }
  }

  Future<void> updateCustomer(
    String id,
    Map<String, dynamic> customerData,
  ) async {
    try {
      isProcessing(true);

      final response = await _api.put(
        '/api/accounts-receivable/customers/$id',
        body: customerData,
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Customer updated successfully',
        );
        await fetchCustomers();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to update customer',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to update customer: $e');
    } finally {
      isProcessing(false);
    }
  }

  Future<void> deleteCustomer(String id, String name) async {
    try {
      final response = await _api.delete(
        '/api/accounts-receivable/customers/$id',
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Customer "$name" deleted successfully',
        );
        await fetchCustomers();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data['message'] ?? 'Failed to delete customer',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to delete customer: $e');
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchCustomers();
  }

  void searchCustomers(String query) {
    searchQuery.value = query;
    fetchCustomers();
  }

  List<Customer> getFilteredCustomers() {
    var filtered = customers.toList();

    if (selectedFilter.value == 'With Balance') {
      filtered = filtered.where((c) => c.outstandingAmount > 0).toList();
    }

    return filtered;
  }

  // ─────────────────────── EXPORT FUNCTIONS ───────────────────────

  void exportCustomers() {
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
              'Export Customers',
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
    try {
      // Show loading only on mobile
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
            _pdfCustomersSection(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'customers_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        // WEB: Download using HTML anchor tag
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          kSuccess,
          'Success',
          '${customers.length} customers exported to PDF',
        );
      } else {
        // MOBILE: Save to file and open
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          kSuccess,
          'Success',
          '${customers.length} customers exported to PDF',
        );

        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
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
                'Customers Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
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
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
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
            'Total Customers',
            totalCustomers.value.toString(),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'Active Customers',
            activeCustomers.value.toString(),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            'Total Sales',
            _formatAmount(totalSales.value),
            PdfColors.indigo700,
          ),
          _pdfSummaryItem(
            'Total Outstanding',
            _formatAmount(totalOutstanding.value),
            PdfColors.red700,
          ),
          _pdfSummaryItem('Filter', selectedFilter.value, PdfColors.grey700),
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
                  'Email',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Invoices',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Sales',
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
        ...customers
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
                        customer.email,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        customer.invoiceCount.toString(),
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
                        _formatAmount(customer.outstandingAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: customer.outstandingAmount > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
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
                    customers.fold(0.0, (sum, c) => sum + c.totalAmount),
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
                    customers.fold(0.0, (sum, c) => sum + c.outstandingAmount),
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

  Future<void> exportToExcel() async {
    try {
      // Show loading only on mobile
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

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Customers Report',
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
        ['Total Customers', totalCustomers.value.toString()],
        ['Active Customers', activeCustomers.value.toString()],
        ['Total Sales', _formatAmount(totalSales.value)],
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

      // Customers Sheet
      final customersSheet = excel['Customers'];
      final headers = [
        'Customer Name',
        'Email',
        'Phone',
        'Address',
        'Tax ID',
        'Payment Terms',
        'Status',
        'Invoices',
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
      for (final customer in customers) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(customersSheet, row, 0, customer.name, bgColor: bg);
        _excelSetCell(customersSheet, row, 1, customer.email, bgColor: bg);
        _excelSetCell(customersSheet, row, 2, customer.phone, bgColor: bg);
        _excelSetCell(customersSheet, row, 3, customer.address, bgColor: bg);
        _excelSetCell(customersSheet, row, 4, customer.taxId, bgColor: bg);
        _excelSetCell(
          customersSheet,
          row,
          5,
          customer.paymentTerms,
          bgColor: bg,
        );
        _excelSetCell(
          customersSheet,
          row,
          6,
          customer.isActive ? 'Active' : 'Inactive',
          bgColor: bg,
          fontColor: customer.isActive ? '2E7D32' : 'C62828',
        );
        _excelSetCell(
          customersSheet,
          row,
          7,
          customer.invoiceCount,
          bgColor: bg,
        );
        _excelSetCell(
          customersSheet,
          row,
          8,
          customer.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          customersSheet,
          row,
          9,
          customer.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          customersSheet,
          row,
          10,
          customer.outstandingAmount,
          bgColor: bg,
          fontColor: 'C62828',
        );
        _excelSetCell(
          customersSheet,
          row,
          11,
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
        7,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        customersSheet,
        row,
        8,
        customers.fold(0.0, (sum, c) => sum + c.totalAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '1A237E',
      );
      _excelSetCell(
        customersSheet,
        row,
        9,
        customers.fold(0.0, (sum, c) => sum + c.paidAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        customersSheet,
        row,
        10,
        customers.fold(0.0, (sum, c) => sum + c.outstandingAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [
        30.0,
        25.0,
        15.0,
        35.0,
        15.0,
        12.0,
        10.0,
        10.0,
        15.0,
        15.0,
        15.0,
        15.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        customersSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'customers_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        // WEB: Download Excel
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
          kSuccess,
          'Success',
          '${customers.length} customers exported to Excel',
        );
      } else {
        // MOBILE: Save and open
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          kSuccess,
          'Success',
          '${customers.length} customers exported to Excel',
        );

        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
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

  void _handleSessionExpired() {
    AppSnackbar.error(kDanger, 'Session Expired', 'Please login again');
  }
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String paymentTerms;
  final bool isActive;
  final int invoiceCount;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? lastPaymentDate;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.paymentTerms,
    required this.isActive,
    required this.invoiceCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    this.lastPaymentDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      taxId: json['taxId'] ?? '',
      paymentTerms: json['paymentTerms'] ?? 'Net 30',
      isActive: json['isActive'] ?? true,
      invoiceCount: json['invoiceCount'] ?? 0,
      totalAmount: safeToDouble(json['totalAmount']),
      paidAmount: safeToDouble(json['paidAmount']),
      outstandingAmount: safeToDouble(json['outstandingAmount']),
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'])
          : null,
    );
  }
}
