import 'dart:io';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TrialBalanceController extends GetxController {
  var trialBalanceData = <TrialBalanceAccount>[].obs;
  var isLoading = true.obs;
  var selectedFilter = 'All'.obs;
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var showZeroBalance = true.obs;
  var searchQuery = ''.obs;
  var totalAccounts = 0.obs;

  // Summary totals
  var totalDebit = 0.0.obs;
  var totalCredit = 0.0.obs;
  var difference = 0.0.obs;
  var isBalanced = false.obs;

  final ApiClient _api = Get.find<ApiClient>();
  final FiscalYearController _fiscalYearController =
      Get.find<FiscalYearController>();

  Worker? _fiscalYearWorker;

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
    _bootstrap();
  }

  @override
  void onClose() {
    _fiscalYearWorker?.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    if (_fiscalYearController.isLoading.value) {
      while (_fiscalYearController.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (_fiscalYearController.fiscalYears.isEmpty) {
      await _fiscalYearController.fetchFiscalYears();
    }

    _fiscalYearWorker = ever(_fiscalYearController.selectedFiscalYear, (_) {
      fetchTrialBalance();
    });

    await fetchTrialBalance();
  }

  Future<void> fetchTrialBalance() async {
    try {
      isLoading(true);
      trialBalanceData.clear();

      final queryParams = <String, dynamic>{
        'showZeroBalance': showZeroBalance.value.toString(),
      };

      if (selectedFilter.value != 'All') {
        queryParams['accountType'] = selectedFilter.value;
      }

      if (selectedDateRange.value != null) {
        queryParams['startDate'] = selectedDateRange.value!.start
            .toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      final selectedYear = _fiscalYearController.selectedFiscalYear.value;
      if (selectedYear != null) {
        queryParams['fiscalYearId'] = selectedYear.id;
      }

      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      final response = await _api.get(
        '/api/trial-balance',
        queryParameters: queryParams,
      );

      if (response.success) {
        final data = response.data;
        final accounts = (data['data'] as List? ?? [])
            .map((e) => TrialBalanceAccount.fromJson(e as Map<String, dynamic>))
            .toList();

        trialBalanceData.value = accounts;
        totalAccounts.value = data['count'] ?? accounts.length;

        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        totalDebit.value = _toDouble(summary['totalDebit']);
        totalCredit.value = _toDouble(summary['totalCredit']);
        difference.value = _toDouble(summary['difference']);
        isBalanced.value = summary['isBalanced'] == true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to load trial balance',
        );
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

  void searchAccounts(String query) {
    searchQuery.value = query;
    fetchTrialBalance();
  }

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
        ...trialBalanceData.map(
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
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.green700),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    account.creditBalance > 0
                        ? _formatAmount(account.creditBalance)
                        : '-',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.red700),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        ['Total Accounts', totalAccounts.value.toString()],
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
      accountId: json['accountId']?.toString() ?? '',
      accountCode: json['accountCode']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      debitBalance: (json['debitBalance'] as num?)?.toDouble() ?? 0.0,
      creditBalance: (json['creditBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
