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

class VendorsController extends GetxController {
  var vendors = <Vendor>[].obs;
  var filteredVendors = <Vendor>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

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
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    try {
      isLoading(true);
      final response = await _api.get('/api/accounts-payable/vendors');
      if (response.success) {
        vendors.value = (response.data['data'] as List)
            .map((e) => Vendor.fromJson(e))
            .toList();
        _applyFilters();
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load vendors: $e');
    } finally {
      isLoading(false);
    }
  }

  void _applyFilters() {
    var filtered = vendors.toList();

    if (selectedFilter.value != 'All') {
      filtered = filtered.where((v) {
        switch (selectedFilter.value) {
          case 'Active':
            return v.isActive;
          case 'Inactive':
            return !v.isActive;
          case 'With Balance':
            return v.outstandingBalance > 0;
          default:
            return true;
        }
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((v) {
        return v.name.toLowerCase().contains(query) ||
            v.email.toLowerCase().contains(query) ||
            v.phone.contains(query) ||
            v.taxId.contains(query);
      }).toList();
    }

    filteredVendors.value = filtered;
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  void searchVendors(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  Future<void> createVendor(Map<String, dynamic> vendorData) async {
    try {
      isProcessing(true);
      final response = await _api.post(
        '/api/accounts-payable/vendors',
        body: vendorData,
      );
      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Vendor added successfully');
        await fetchVendors();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add vendor',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to add vendor: $e');
    } finally {
      isProcessing(false);
    }
  }

  Future<void> updateVendor(String id, Map<String, dynamic> vendorData) async {
    try {
      isProcessing(true);
      final response = await _api.put(
        '/api/accounts-payable/vendors/$id',
        body: vendorData,
      );
      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Vendor updated successfully');
        await fetchVendors();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update vendor',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to update vendor: $e');
    } finally {
      isProcessing(false);
    }
  }

  Future<void> deleteVendor(String id, String name) async {
    try {
      final response = await _api.delete('/api/accounts-payable/vendors/$id');
      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Vendor "$name" deleted successfully',
        );
        await fetchVendors();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete vendor',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to delete vendor: $e');
    }
  }

  // ─────────────────────── EXPORT FUNCTIONS ───────────────────────

  void exportVendors() {
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
              'Export Vendors',
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
            _pdfVendorsSection(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'vendors_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
          '${filteredVendors.length} vendors exported to PDF',
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
          '${filteredVendors.length} vendors exported to PDF',
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
                'Vendors Report',
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
    final totalVendors = filteredVendors.length;
    final totalActive = filteredVendors.where((v) => v.isActive).length;
    final totalInactive = filteredVendors.where((v) => !v.isActive).length;
    final totalWithBalance = filteredVendors
        .where((v) => v.outstandingBalance > 0)
        .length;
    final totalPurchases = filteredVendors.fold(
      0.0,
      (sum, v) => sum + v.totalPurchases,
    );
    final totalOutstanding = filteredVendors.fold(
      0.0,
      (sum, v) => sum + v.outstandingBalance,
    );

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
                'Total Vendors',
                totalVendors.toString(),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Active',
                totalActive.toString(),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Inactive',
                totalInactive.toString(),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'With Balance',
                totalWithBalance.toString(),
                PdfColors.orange700,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Purchases',
                _formatAmount(totalPurchases),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Total Outstanding',
                _formatAmount(totalOutstanding),
                PdfColors.red700,
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

  pw.Widget _pdfVendorsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Vendor Details',
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
                  'Vendor Name',
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
                  'Tax ID',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Purchases',
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
                flex: 1,
                child: pw.Text(
                  'Status',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...filteredVendors
            .map(
              (vendor) => pw.Container(
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
                        vendor.name,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        vendor.phone,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        vendor.email,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        vendor.taxId,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(vendor.totalPurchases),
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
                        _formatAmount(vendor.outstandingBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: vendor.outstandingBalance > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        vendor.isActive ? 'Active' : 'Inactive',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: vendor.isActive
                              ? PdfColors.green700
                              : PdfColors.red700,
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
                  _formatAmount(
                    filteredVendors.fold(
                      0.0,
                      (sum, v) => sum + v.totalPurchases,
                    ),
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
                    filteredVendors.fold(
                      0.0,
                      (sum, v) => sum + v.outstandingBalance,
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
        'Vendors Report',
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

      final totalVendors = filteredVendors.length;
      final totalActive = filteredVendors.where((v) => v.isActive).length;
      final totalInactive = filteredVendors.where((v) => !v.isActive).length;
      final totalWithBalance = filteredVendors
          .where((v) => v.outstandingBalance > 0)
          .length;
      final totalPurchases = filteredVendors.fold(
        0.0,
        (sum, v) => sum + v.totalPurchases,
      );
      final totalOutstanding = filteredVendors.fold(
        0.0,
        (sum, v) => sum + v.outstandingBalance,
      );

      final summaryRows = [
        ['Total Vendors', totalVendors.toString()],
        ['Active Vendors', totalActive.toString()],
        ['Inactive Vendors', totalInactive.toString()],
        ['Vendors with Balance', totalWithBalance.toString()],
        ['Total Purchases', _formatAmount(totalPurchases)],
        ['Total Outstanding', _formatAmount(totalOutstanding)],
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

      // Vendors Sheet
      final vendorsSheet = excel['Vendors'];
      final headers = [
        'Vendor Name',
        'Email',
        'Phone',
        'Address',
        'Tax ID',
        'Contact Person',
        'Contact Phone',
        'Payment Terms',
        'Total Purchases',
        'Total Paid',
        'Outstanding Balance',
        'Last Purchase Date',
        'Status',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          vendorsSheet,
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
      for (final vendor in filteredVendors) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(vendorsSheet, row, 0, vendor.name, bgColor: bg);
        _excelSetCell(vendorsSheet, row, 1, vendor.email, bgColor: bg);
        _excelSetCell(vendorsSheet, row, 2, vendor.phone, bgColor: bg);
        _excelSetCell(vendorsSheet, row, 3, vendor.address, bgColor: bg);
        _excelSetCell(vendorsSheet, row, 4, vendor.taxId, bgColor: bg);
        _excelSetCell(vendorsSheet, row, 5, vendor.contactPerson, bgColor: bg);
        _excelSetCell(
          vendorsSheet,
          row,
          6,
          vendor.contactPersonPhone,
          bgColor: bg,
        );
        _excelSetCell(vendorsSheet, row, 7, vendor.paymentTerms, bgColor: bg);
        _excelSetCell(
          vendorsSheet,
          row,
          8,
          vendor.totalPurchases,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          vendorsSheet,
          row,
          9,
          vendor.totalPaid,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          vendorsSheet,
          row,
          10,
          vendor.outstandingBalance,
          bgColor: bg,
          fontColor: vendor.outstandingBalance > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(
          vendorsSheet,
          row,
          11,
          vendor.lastPurchaseDate != null
              ? DateFormat('dd MMM yyyy').format(vendor.lastPurchaseDate!)
              : '-',
          bgColor: bg,
        );
        _excelSetCell(
          vendorsSheet,
          row,
          12,
          vendor.isActive ? 'Active' : 'Inactive',
          bgColor: bg,
          fontColor: vendor.isActive ? '2E7D32' : 'C62828',
        );
        _excelSetCell(vendorsSheet, row, 13, vendor.notes, bgColor: bg);
        row++;
      }

      // Totals row
      _excelSetCell(
        vendorsSheet,
        row,
        8,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        vendorsSheet,
        row,
        9,
        totalPurchases,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '1A237E',
      );
      _excelSetCell(
        vendorsSheet,
        row,
        10,
        totalOutstanding,
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
        25.0,
        15.0,
        12.0,
        15.0,
        15.0,
        15.0,
        15.0,
        10.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        vendorsSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'vendors_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
          '${filteredVendors.length} vendors exported to Excel',
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
          '${filteredVendors.length} vendors exported to Excel',
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
}

class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String contactPerson;
  final String contactPersonPhone;
  final String paymentTerms;
  final double totalPurchases;
  final double totalPaid;
  final double outstandingBalance;
  final DateTime? lastPurchaseDate;
  final bool isActive;
  final String notes;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.contactPerson,
    required this.contactPersonPhone,
    required this.paymentTerms,
    required this.totalPurchases,
    required this.totalPaid,
    required this.outstandingBalance,
    this.lastPurchaseDate,
    required this.isActive,
    required this.notes,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Vendor(
      id: json['_id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      taxId: json['taxId'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      contactPersonPhone: json['contactPersonPhone'] ?? '',
      paymentTerms: json['paymentTerms'] ?? 'Net 30',
      totalPurchases: safeToDouble(json['totalAmount']),
      totalPaid: safeToDouble(json['paidAmount']),
      outstandingBalance: safeToDouble(json['outstandingAmount']),
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.parse(json['lastPurchaseDate'])
          : null,
      isActive: json['isActive'] ?? true,
      notes: json['notes'] ?? '',
    );
  }
}
