import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
//
//
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class TrialBalanceController extends GetxController {
  var trialBalanceData = <TrialBalanceAccount>[].obs;
  var isLoading = true.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var showZeroBalance = true.obs;
  var searchQuery = ''.obs;
  var allTrialBalanceData =
      <TrialBalanceAccount>[].obs; // Store all data for local search

  // Summary totals
  var totalDebit = 0.0.obs;
  var totalCredit = 0.0.obs;
  var difference = 0.0.obs;
  var isBalanced = false.obs;

  final ApiClient _api = Get.find<ApiClient>();

  void searchEntries(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      trialBalanceData.value = allTrialBalanceData.value;
    } else {
      final searchLower = query.toLowerCase();
      final results = allTrialBalanceData.where((account) {
        return account.accountName.toLowerCase().contains(searchLower) ||
            account.accountCode.toLowerCase().contains(searchLower) ||
            account.accountType.toLowerCase().contains(searchLower);
      }).toList();
      trialBalanceData.value = results;
    }

    _updateTotalsForFilteredData();
  }

  void _updateTotalsForFilteredData() {
    final filtered = trialBalanceData.value;
    totalDebit.value = filtered.fold(0.0, (sum, acc) => sum + acc.debitBalance);
    totalCredit.value = filtered.fold(
      0.0,
      (sum, acc) => sum + acc.creditBalance,
    );
    difference.value = totalDebit.value - totalCredit.value;
    isBalanced.value = (difference.value.abs() < 0.01);
  }

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
    fetchTrialBalance();
  }

  Future<void> fetchTrialBalance() async {
    try {
      isLoading(true);

      Map<String, dynamic> queryParams = {};

      if (selectedFilter.value != 'All') {
        queryParams['accountType'] = selectedFilter.value;
      }

      if (selectedDateRange.value != null) {
        queryParams['startDate'] = selectedDateRange.value!.start
            .toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      queryParams['showZeroBalance'] = showZeroBalance.value.toString();

      final response = await _api.get(
        '/api/trial-balance',
        queryParameters: queryParams,
      );

      if (response.success) {
        final data = response.data;
        final accounts = (data['data'] as List)
            .map((e) => TrialBalanceAccount.fromJson(e))
            .toList();

        allTrialBalanceData.value = accounts;

        if (searchQuery.value.isNotEmpty) {
          searchEntries(searchQuery.value);
        } else {
          trialBalanceData.value = accounts;

          // Update summary
          totalDebit.value = _toDouble(data['summary']['totalDebit']);
          totalCredit.value = _toDouble(data['summary']['totalCredit']);
          difference.value = _toDouble(data['summary']['difference']);
          isBalanced.value = data['summary']['isBalanced'] ?? false;
        }
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load trial balance: $e');
    } finally {
      isLoading(false);
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchTrialBalance();
  }

  void toggleZeroBalance(bool value) {
    showZeroBalance.value = value;
    fetchTrialBalance();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    fetchTrialBalance();
  }

  // ─────────────────────── EXPORT FUNCTIONS ───────────────────────

  void exportToPdf() async {
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
            _pdfTrialBalanceTable(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'trial_balance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'PDF exported successfully');

      await OpenFile.open(file.path);
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
                'Trial Balance Report',
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
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Debit',
                _formatAmount(totalDebit.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Total Credit',
                _formatAmount(totalCredit.value),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'Difference',
                _formatAmount(difference.value),
                isBalanced.value ? PdfColors.green700 : PdfColors.orange700,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            isBalanced.value
                ? '✓ TRIAL BALANCE IS BALANCED'
                : '✗ TRIAL BALANCE IS NOT BALANCED',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: isBalanced.value ? PdfColors.green700 : PdfColors.red700,
            ),
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

  pw.Widget _pdfTrialBalanceTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trial Balance Details',
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
                flex: 1,
                child: pw.Text(
                  'Code',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Account Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Type',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Debit',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Credit',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...trialBalanceData
            .map(
              (account) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        account.accountCode,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        account.accountName,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        account.accountType,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        account.debitBalance > 0
                            ? _formatAmount(account.debitBalance)
                            : '-',
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
                        account.creditBalance > 0
                            ? _formatAmount(account.creditBalance)
                            : '-',
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
                flex: 5,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalDebit.value),
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
                  _formatAmount(totalCredit.value),
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

  void exportToExcel() async {
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

      final excel = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Trial Balance Report',
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

      if (selectedDateRange.value != null) {
        _excelSetCell(
          summarySheet,
          2,
          0,
          'Period: ${DateFormat('dd MMM yyyy').format(selectedDateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange.value!.end)}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }

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
        ['Total Debit', _formatAmount(totalDebit.value)],
        ['Total Credit', _formatAmount(totalCredit.value)],
        ['Difference', _formatAmount(difference.value)],
        ['Status', isBalanced.value ? 'Balanced ✓' : 'Not Balanced ✗'],
        ['Total Accounts', trialBalanceData.length.toString()],
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

      // Trial Balance Sheet
      final tbSheet = excel['Trial Balance'];
      final headers = [
        'Account Code',
        'Account Name',
        'Account Type',
        'Debit',
        'Credit',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          tbSheet,
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
      for (final account in trialBalanceData) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(tbSheet, row, 0, account.accountCode, bgColor: bg);
        _excelSetCell(tbSheet, row, 1, account.accountName, bgColor: bg);
        _excelSetCell(tbSheet, row, 2, account.accountType, bgColor: bg);
        _excelSetCell(
          tbSheet,
          row,
          3,
          account.debitBalance > 0 ? account.debitBalance : '',
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          tbSheet,
          row,
          4,
          account.creditBalance > 0 ? account.creditBalance : '',
          bgColor: bg,
          fontColor: 'C62828',
        );
        row++;
      }

      // Totals row
      _excelSetCell(tbSheet, row, 2, 'TOTAL', bold: true, bgColor: 'E8EAF6');
      _excelSetCell(
        tbSheet,
        row,
        3,
        totalDebit.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        tbSheet,
        row,
        4,
        totalCredit.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [15.0, 35.0, 15.0, 15.0, 15.0];
      for (int i = 0; i < colWidths.length; i++) {
        tbSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'trial_balance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'Excel exported successfully');

      await OpenFile.open(file.path);
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

  void exportTrialBalance() {
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

  void printTrialBalance() {
    AppSnackbar.info('Print', 'Preparing Trial Balance for printing...');
  }
}

class TrialBalanceAccount {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final double debitBalance;
  final double creditBalance;

  TrialBalanceAccount({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.debitBalance,
    required this.creditBalance,
  });

  factory TrialBalanceAccount.fromJson(Map<String, dynamic> json) {
    return TrialBalanceAccount(
      accountId: json['accountId'],
      accountCode: json['accountCode'],
      accountName: json['accountName'],
      accountType: json['accountType'],
      debitBalance: (json['debitBalance'] ?? 0).toDouble(),
      creditBalance: (json['creditBalance'] ?? 0).toDouble(),
    );
  }
}
