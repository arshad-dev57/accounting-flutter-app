// core/profitlossStatement/controllers/profit_and_loss_controller.dart
// COMPLETE CONTROLLER - NO WEB

import 'dart:convert';
import 'dart:io';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class PLController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var selectedPeriod = 'This Month'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();

  // Report Data
  var periodText = ''.obs;
  var totalRevenue = 0.0.obs;
  var costOfGoodsSold = 0.0.obs;
  var grossProfit = 0.0.obs;
  var operatingExpenses = 0.0.obs;
  var netProfit = 0.0.obs;
  var netProfitMargin = 0.0.obs;

  var revenueItems = <ReportItem>[].obs;
  var expenseItems = <ReportItem>[].obs;
  var otherIncomeItems = <ReportItem>[].obs;
  var otherExpenseItems = <ReportItem>[].obs;

  final List<String> periodOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range',
  ];

  final ApiClient _api = Get.find<ApiClient>();
  final FiscalYearController _fiscalYearController =
      Get.find<FiscalYearController>();

  @override
  void onInit() {
    super.onInit();
    loadReportData();
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  Future<void> loadReportData() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {};

      if (selectedPeriod.value == 'Custom Range' &&
          selectedDateRange.value != null) {
        params['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDateRange.value!.end);
      } else {
        params['period'] = selectedPeriod.value;
      }

      // Add fiscal year ID if selected
      if (_fiscalYearController.selectedFiscalYear.value != null) {
        params['fiscalYearId'] =
            _fiscalYearController.selectedFiscalYear.value!.id;
      }

      final response = await _api.get(
        '/api/reports/profit-loss',
        queryParameters: params,
      );

      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];

          periodText.value = data['period']['displayText'] ?? '';
          totalRevenue.value = (data['revenue']?['total'] ?? 0).toDouble();
          costOfGoodsSold.value = (data['costOfGoodsSold'] ?? 0).toDouble();
          grossProfit.value = (data['grossProfit'] ?? 0).toDouble();
          operatingExpenses.value = (data['operatingExpenses']?['total'] ?? 0)
              .toDouble();
          netProfit.value = (data['netProfit'] ?? 0).toDouble();
          netProfitMargin.value = (data['netProfitMargin'] ?? 0).toDouble();

          revenueItems.value = (data['revenue']?['items'] as List? ?? [])
              .map(
                (item) => ReportItem(
                  name: item['name'] ?? '',
                  amount: (item['amount'] ?? 0).toDouble(),
                ),
              )
              .toList();

          expenseItems.value =
              (data['operatingExpenses']?['items'] as List? ?? [])
                  .map(
                    (item) => ReportItem(
                      name: item['name'] ?? '',
                      amount: (item['amount'] ?? 0).toDouble(),
                    ),
                  )
                  .toList();

          otherIncomeItems.value =
              (data['otherIncome']?['items'] as List? ?? [])
                  .map(
                    (item) => ReportItem(
                      name: item['name'] ?? '',
                      amount: (item['amount'] ?? 0).toDouble(),
                    ),
                  )
                  .toList();

          otherExpenseItems.value =
              (data['otherExpenses']?['items'] as List? ?? [])
                  .map(
                    (item) => ReportItem(
                      name: item['name'] ?? '',
                      amount: (item['amount'] ?? 0).toDouble(),
                    ),
                  )
                  .toList();
        } else {
          AppSnackbar.error(
            kDanger,
            'Error',
            responseData['message'] ?? 'Failed to load report',
          );
        }
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading P&L report: $e');
      AppSnackbar.error(kDanger, 'Error', 'error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
    if (period != 'Custom Range') {
      selectedDateRange.value = null;
    }
    loadReportData();
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedPeriod.value = 'Custom Range';
      loadReportData();
    }
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    selectedPeriod.value = 'This Month';
    loadReportData();
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${CurrencyUtils.prefix} ${formatter.format(amount)}';
  }

  // ─── EXPORT FUNCTIONS ────────────────────────────────────────────

  void exportToPdf() async {
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
            reportTitle: 'Profit & Loss Statement',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfRevenueSection(),
            pw.SizedBox(height: 16),
            _pdfExpenseSection(),
            if (otherIncomeItems.isNotEmpty ||
                otherExpenseItems.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _pdfOtherSection(),
            ],
            pw.SizedBox(height: 16),
            _pdfProfitSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'profit_loss_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Profit & Loss report exported to PDF',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(
        kDanger,
        'Error',
        'Failed to export PDF: ${e.toString()}',
      );
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
          pw.Text(
            'Period: ${periodText.value}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Revenue',
                _formatAmount(totalRevenue.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'COGS',
                _formatAmount(costOfGoodsSold.value),
                PdfColors.orange700,
              ),
              _pdfSummaryItem(
                'Gross Profit',
                _formatAmount(grossProfit.value),
                accent,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Operating Expenses',
                _formatAmount(operatingExpenses.value),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'Net Profit',
                _formatAmount(netProfit.value),
                netProfit.value >= 0 ? PdfColors.green700 : PdfColors.red700,
              ),
              _pdfSummaryItem(
                'Net Profit Margin',
                '${netProfitMargin.value.toStringAsFixed(2)}%',
                netProfitMargin.value >= 0
                    ? PdfColors.green700
                    : PdfColors.red700,
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

  pw.Widget _pdfRevenueSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Revenue',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green700,
          ),
        ),
        pw.SizedBox(height: 8),
        _pdfItemList(revenueItems, totalRevenue.value, 'Total Revenue'),
        pw.SizedBox(height: 8),
        pw.Text(
          'Cost of Goods Sold',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Total COGS', style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Text(
                _formatAmount(costOfGoodsSold.value),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.orange700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Gross Profit',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatAmount(grossProfit.value),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfExpenseSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Operating Expenses',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
        pw.SizedBox(height: 8),
        _pdfItemList(
          expenseItems,
          operatingExpenses.value,
          'Total Operating Expenses',
        ),
      ],
    );
  }

  pw.Widget _pdfOtherSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (otherIncomeItems.isNotEmpty) ...[
          pw.Text(
            'Other Income',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfItemList(
            otherIncomeItems,
            otherIncomeItems.fold(0.0, (sum, item) => sum + item.amount),
            'Total Other Income',
          ),
          pw.SizedBox(height: 16),
        ],
        if (otherExpenseItems.isNotEmpty) ...[
          pw.Text(
            'Other Expenses',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfItemList(
            otherExpenseItems,
            otherExpenseItems.fold(0.0, (sum, item) => sum + item.amount),
            'Total Other Expenses',
          ),
        ],
      ],
    );
  }

  pw.Widget _pdfProfitSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: netProfit.value >= 0 ? PdfColors.green50 : PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(
              color: netProfit.value >= 0
                  ? PdfColors.green200
                  : PdfColors.red200,
            ),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Net Profit / (Loss)',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    _formatAmount(netProfit.value),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: netProfit.value >= 0
                          ? PdfColors.green700
                          : PdfColors.red700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Net Profit Margin',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    '${netProfitMargin.value.toStringAsFixed(2)}%',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: netProfitMargin.value >= 0
                          ? PdfColors.green700
                          : PdfColors.red700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfItemList(
    List<ReportItem> items,
    double total,
    String totalLabel,
  ) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          'No transactions found',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      );
    }

    return pw.Column(
      children: [
        ...items
            .map(
              (item) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        item.name,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      _formatAmount(item.amount),
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        pw.Divider(),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  totalLabel,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                _formatAmount(total),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void exportToExcelFile() async {
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

      final excelFile = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Profit & Loss Statement',
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
        'Period: ${periodText.value}',
        fontSize: 10,
        fontColor: '1A237E',
      );

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
        ['Total Revenue', _formatAmount(totalRevenue.value)],
        ['Cost of Goods Sold', _formatAmount(costOfGoodsSold.value)],
        ['Gross Profit', _formatAmount(grossProfit.value)],
        ['Operating Expenses', _formatAmount(operatingExpenses.value)],
        ['Net Profit', _formatAmount(netProfit.value)],
        ['Net Profit Margin', '${netProfitMargin.value.toStringAsFixed(2)}%'],
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

      // Revenue Sheet
      final revenueSheet = excelFile['Revenue'];
      _excelSetCell(
        revenueSheet,
        0,
        0,
        'Revenue Details',
        bold: true,
        fontSize: 12,
        bgColor: '2E7D32',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(
        revenueSheet,
        1,
        0,
        'Description',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        revenueSheet,
        1,
        1,
        'Amount',
        bold: true,
        bgColor: 'E8EAF6',
      );

      int row = 2;
      for (final item in revenueItems) {
        _excelSetCell(
          revenueSheet,
          row,
          0,
          item.name,
          bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF',
        );
        _excelSetCell(
          revenueSheet,
          row,
          1,
          item.amount,
          bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF',
        );
        row++;
      }
      _excelSetCell(
        revenueSheet,
        row,
        0,
        'Total Revenue',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        revenueSheet,
        row,
        1,
        totalRevenue.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );

      _excelSetCell(
        revenueSheet,
        row + 2,
        0,
        'Cost of Goods Sold',
        bold: true,
        fontSize: 12,
        bgColor: 'F39C12',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(revenueSheet, row + 3, 0, 'Total COGS', bgColor: 'F5F5F5');
      _excelSetCell(
        revenueSheet,
        row + 3,
        1,
        costOfGoodsSold.value,
        bgColor: 'F5F5F5',
        fontColor: 'F39C12',
      );
      _excelSetCell(
        revenueSheet,
        row + 5,
        0,
        'Gross Profit',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        revenueSheet,
        row + 5,
        1,
        grossProfit.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '1A237E',
      );

      revenueSheet.setColumnWidth(0, 40);
      revenueSheet.setColumnWidth(1, 20);

      // Expenses Sheet
      final expenseSheet = excelFile['Expenses'];
      _excelSetCell(
        expenseSheet,
        0,
        0,
        'Operating Expenses',
        bold: true,
        fontSize: 12,
        bgColor: 'C62828',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(
        expenseSheet,
        1,
        0,
        'Description',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        expenseSheet,
        1,
        1,
        'Amount',
        bold: true,
        bgColor: 'E8EAF6',
      );

      row = 2;
      for (final item in expenseItems) {
        _excelSetCell(
          expenseSheet,
          row,
          0,
          item.name,
          bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF',
        );
        _excelSetCell(
          expenseSheet,
          row,
          1,
          item.amount,
          bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF',
        );
        row++;
      }
      _excelSetCell(
        expenseSheet,
        row,
        0,
        'Total Operating Expenses',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        expenseSheet,
        row,
        1,
        operatingExpenses.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      expenseSheet.setColumnWidth(0, 40);
      expenseSheet.setColumnWidth(1, 20);

      // Other Items Sheet
      if (otherIncomeItems.isNotEmpty || otherExpenseItems.isNotEmpty) {
        final otherSheet = excelFile['Other Items'];
        int otherRow = 0;

        if (otherIncomeItems.isNotEmpty) {
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Other Income',
            bold: true,
            fontSize: 12,
            bgColor: '2E7D32',
            fontColor: 'FFFFFF',
          );
          otherRow++;
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Description',
            bold: true,
            bgColor: 'E8EAF6',
          );
          _excelSetCell(
            otherSheet,
            otherRow,
            1,
            'Amount',
            bold: true,
            bgColor: 'E8EAF6',
          );
          otherRow++;

          for (final item in otherIncomeItems) {
            _excelSetCell(
              otherSheet,
              otherRow,
              0,
              item.name,
              bgColor: otherRow.isEven ? 'F5F5F5' : 'FFFFFF',
            );
            _excelSetCell(
              otherSheet,
              otherRow,
              1,
              item.amount,
              bgColor: otherRow.isEven ? 'F5F5F5' : 'FFFFFF',
            );
            otherRow++;
          }
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Total Other Income',
            bold: true,
            bgColor: 'E8EAF6',
          );
          _excelSetCell(
            otherSheet,
            otherRow,
            1,
            otherIncomeItems.fold(0.0, (sum, i) => sum + i.amount),
            bold: true,
            bgColor: 'E8EAF6',
            fontColor: '2E7D32',
          );
          otherRow += 2;
        }

        if (otherExpenseItems.isNotEmpty) {
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Other Expenses',
            bold: true,
            fontSize: 12,
            bgColor: 'C62828',
            fontColor: 'FFFFFF',
          );
          otherRow++;
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Description',
            bold: true,
            bgColor: 'E8EAF6',
          );
          _excelSetCell(
            otherSheet,
            otherRow,
            1,
            'Amount',
            bold: true,
            bgColor: 'E8EAF6',
          );
          otherRow++;

          for (final item in otherExpenseItems) {
            _excelSetCell(
              otherSheet,
              otherRow,
              0,
              item.name,
              bgColor: otherRow.isEven ? 'F5F5F5' : 'FFFFFF',
            );
            _excelSetCell(
              otherSheet,
              otherRow,
              1,
              item.amount,
              bgColor: otherRow.isEven ? 'F5F5F5' : 'FFFFFF',
            );
            otherRow++;
          }
          _excelSetCell(
            otherSheet,
            otherRow,
            0,
            'Total Other Expenses',
            bold: true,
            bgColor: 'E8EAF6',
          );
          _excelSetCell(
            otherSheet,
            otherRow,
            1,
            otherExpenseItems.fold(0.0, (sum, i) => sum + i.amount),
            bold: true,
            bgColor: 'E8EAF6',
            fontColor: 'C62828',
          );
        }

        otherSheet.setColumnWidth(0, 40);
        otherSheet.setColumnWidth(1, 20);
      }

      // Profit Summary Sheet
      final profitSheet = excelFile['Profit Summary'];
      _excelSetCell(
        profitSheet,
        0,
        0,
        'Profit Summary',
        bold: true,
        fontSize: 14,
        bgColor: '1A237E',
        fontColor: 'FFFFFF',
      );
      _excelSetCell(profitSheet, 1, 0, 'Net Profit / (Loss)', bold: true);
      _excelSetCell(
        profitSheet,
        1,
        1,
        netProfit.value,
        bold: true,
        fontColor: netProfit.value >= 0 ? '2E7D32' : 'C62828',
      );
      _excelSetCell(profitSheet, 2, 0, 'Net Profit Margin', bold: true);
      _excelSetCell(
        profitSheet,
        2,
        1,
        '${netProfitMargin.value.toStringAsFixed(2)}%',
        bold: true,
      );

      profitSheet.setColumnWidth(0, 25);
      profitSheet.setColumnWidth(1, 20);

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'profit_loss_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Profit & Loss report exported to Excel',
      );
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
}

class ReportItem {
  final String name;
  final double amount;

  ReportItem({required this.name, required this.amount});
}
