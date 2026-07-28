// core/balancesheet/controller/balance_sheet_controller.dart
// COMPLETE CONTROLLER - NO WEB

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class BalanceSheetController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var selectedPeriod = 'All Time'.obs;
  var asOfDate = DateTime.now().obs;

  // Balance Sheet Data
  var liabilitiesData = <String, Map<String, double>>{}.obs;
  var assetsData = <String, Map<String, double>>{}.obs;
  var equityData = <String, Map<String, double>>{}.obs;

  // Totals
  var totalLiabilities = 0.0.obs;
  var totalAssets = 0.0.obs;
  var equity = 0.0.obs;
  var isBalanced = false.obs;
  var balanceDifference = 0.0.obs;

  final List<String> periodOptions = [
    'All Time',
    'This Year',
    'This Quarter',
    'This Month'
  ];

  final ApiClient _api = Get.find<ApiClient>();
  final FiscalYearController _fiscalYearController = Get.find<FiscalYearController>();

  @override
  void onInit() {
    super.onInit();
    loadBalanceSheet();
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  bool get hasEquitySection => equityData.isNotEmpty || equity.value.abs() >= 0.01;

  // ─── LOAD BALANCE SHEET FROM API ──────────────────────────────
  Future<void> loadBalanceSheet() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      Map<String, dynamic> params = {};
      if (selectedPeriod.value != 'All Time') {
        params['period'] = selectedPeriod.value;
      }

      // Add fiscal year ID if selected
      if (_fiscalYearController.selectedFiscalYear.value != null) {
        params['fiscalYearId'] = _fiscalYearController.selectedFiscalYear.value!.id;
      }

      final response = await _api.get('/api/balance-sheet', queryParameters: params);

      if (response.success) {
        final Map<String, dynamic> responseData = response.data;

        if (responseData['success'] == true) {
          final data = responseData['data'];

          // Parse asOfDate
          if (data['asOfDate'] != null) {
            asOfDate.value = DateTime.parse(data['asOfDate']);
          }

          // ─── PARSE ASSETS ──────────────────────────────────────
          assetsData.clear();
          if (data['assets'] != null && data['assets'] is Map) {
            final assetsMap = data['assets'] as Map;
            
            assetsMap.forEach((category, items) {
              if (items is List && items.isNotEmpty) {
                Map<String, double> categoryItems = {};
                for (var item in items) {
                  if (item is Map) {
                    final name = item['name'] ?? '';
                    final balance = item['balance'] ?? 0;
                    if (balance != 0) {
                      categoryItems[name] = (balance as num).toDouble();
                    }
                  }
                }
                if (categoryItems.isNotEmpty) {
                  String displayCategory = _getCategoryDisplayName(category);
                  assetsData[displayCategory] = categoryItems;
                }
              }
            });
          }

          // ─── PARSE LIABILITIES ──────────────────────────────────
          liabilitiesData.clear();
          if (data['liabilities'] != null && data['liabilities'] is Map) {
            final liabilitiesMap = data['liabilities'] as Map;
            
            liabilitiesMap.forEach((category, items) {
              if (items is List && items.isNotEmpty) {
                Map<String, double> categoryItems = {};
                for (var item in items) {
                  if (item is Map) {
                    final name = item['name'] ?? '';
                    final balance = item['balance'] ?? 0;
                    if (balance != 0) {
                      categoryItems[name] = (balance as num).toDouble();
                    }
                  }
                }
                if (categoryItems.isNotEmpty) {
                  String displayCategory = _getCategoryDisplayName(category);
                  liabilitiesData[displayCategory] = categoryItems;
                }
              }
            });
          }

          // ─── PARSE EQUITY ──────────────────────────────────────
          equityData.clear();
          if (data['equity'] != null && data['equity'] is Map) {
            final equityMap = data['equity'] as Map;
            
            // Process owners equity
            if (equityMap['owners'] != null && equityMap['owners'] is List) {
              Map<String, double> ownersItems = {};
              for (var item in equityMap['owners'] as List) {
                if (item is Map) {
                  final name = item['name'] ?? '';
                  final balance = item['balance'] ?? 0;
                  if (balance != 0) {
                    ownersItems[name] = (balance as num).toDouble();
                  }
                }
              }
              if (ownersItems.isNotEmpty) {
                equityData['Owners Equity'] = ownersItems;
              }
            }
            
            // Process retained earnings
            if (equityMap['retainedEarnings'] != null) {
              final retainedEarnings = (equityMap['retainedEarnings'] as num).toDouble();
              if (retainedEarnings != 0) {
                if (equityData['Owners Equity'] == null) {
                  equityData['Owners Equity'] = {};
                }
                equityData['Owners Equity']!['Retained Earnings'] = retainedEarnings;
              }
            }
          }

          // ─── SET TOTALS ──────────────────────────────────────
          if (data['totals'] != null && data['totals'] is Map) {
            final totals = data['totals'] as Map;
            totalAssets.value = (totals['totalAssets'] ?? 0).toDouble();
            totalLiabilities.value = (totals['totalLiabilities'] ?? 0).toDouble();
            equity.value = (totals['totalEquity'] ?? 0).toDouble();
          }

          // Check balance
          final diff = (totalAssets.value - (totalLiabilities.value + equity.value)).abs();
          balanceDifference.value = diff;
          isBalanced.value = diff < 1;
        } else {
          hasError.value = true;
          errorMessage.value = responseData['message'] ?? 'Failed to load balance sheet';
          _showError(errorMessage.value);
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message ?? 'Server error: ${response.statusCode}';
        _showError(errorMessage.value);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error: ${e.toString()}';
      _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── HELPER: GET CATEGORY DISPLAY NAME ──────────────────────────
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'current':
        return 'Current Assets';
      case 'fixed':
        return 'Fixed Assets';
      case 'other':
        return 'Other Assets';
      case 'longTerm':
        return 'Long Term Liabilities';
      default:
        if (category.isNotEmpty) {
          return category[0].toUpperCase() + category.substring(1);
        }
        return category;
    }
  }

  // ─── RETRY LOADING ──────────────────────────────────────────────
  void retryLoad() {
    loadBalanceSheet();
  }

  void changePeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    loadBalanceSheet();
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  // ─── EXPORT FUNCTIONS ────────────────────────────────────────────
  void exportToExcel() {
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
                  'Export Balance Sheet',
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
              'Balance sheet will be exported',
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
                      exportToExcelFile();
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
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PDF EXPORT ──────────────────────────────────────────────────
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
            _pdfAssetsSection(),
            pw.SizedBox(height: 16),
            _pdfLiabilitiesSection(),
            pw.SizedBox(height: 16),
            _pdfEquitySection(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName = 'balance_sheet_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Balance sheet exported to PDF',
      );
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
              pw.Text('Balance Sheet Report',
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
            child: pw.Text('LedgerPro',
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
          pw.Text('Confidential - For Internal Use Only',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
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
            'As of Date: ${DateFormat('dd MMM yyyy').format(asOfDate.value)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Period: ${selectedPeriod.value}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem('Total Assets', _formatAmount(totalAssets.value), PdfColors.green700),
              _pdfSummaryItem('Total Liabilities', _formatAmount(totalLiabilities.value), PdfColors.red700),
              _pdfSummaryItem('Equity', _formatAmount(equity.value), PdfColors.indigo700),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(children: [
      pw.Text(label,
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text(value,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ]);
  }

  pw.Widget _pdfAssetsSection() {
    if (assetsData.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ASSETS',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
          ),
          pw.SizedBox(height: 8),
          pw.Text('No assets found', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ASSETS',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
        ),
        pw.SizedBox(height: 8),
        ...assetsData.keys.map((category) => _pdfCategorySection(category, assetsData[category] ?? {}, false)).toList(),
        pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Total Assets', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(totalAssets.value), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _pdfLiabilitiesSection() {
    if (liabilitiesData.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('LIABILITIES',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
          ),
          pw.SizedBox(height: 8),
          pw.Text('No liabilities found', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('LIABILITIES',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
        ),
        pw.SizedBox(height: 8),
        ...liabilitiesData.keys.map((category) => _pdfCategorySection(category, liabilitiesData[category] ?? {}, true)).toList(),
        pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Total Liabilities', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(totalLiabilities.value), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _pdfEquitySection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('EQUITY',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
        ),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Total Equity', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(equity.value), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
          ]),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Total Liabilities & Equity', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(totalLiabilities.value + equity.value),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
            ),
          ]),
        ),
      ],
    );
  }

  pw.Widget _pdfCategorySection(String category, Map<String, double> items, bool isLiability) {
    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(category,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold,
            color: isLiability ? PdfColors.red600 : PdfColors.green600,
          ),
        ),
        pw.SizedBox(height: 4),
        ...items.entries.map((item) => pw.Container(
          padding: pw.EdgeInsets.only(left: 16),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(item.key, style: pw.TextStyle(fontSize: 10))),
            pw.Text(_formatAmount(item.value), style: pw.TextStyle(fontSize: 10)),
          ]),
        )).toList(),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16, top: 4, bottom: 8),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text('Total $category', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(items.values.fold(0.0, (sum, val) => sum + val)),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ]),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ─── EXCEL EXPORT ──────────────────────────────────────────────────
  Future<void> exportToExcelFile() async {
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

      final excelFile = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(summarySheet, 0, 0, 'Balance Sheet Report',
          bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
      _excelSetCell(summarySheet, 1, 0,
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          fontSize: 9, fontColor: '757575');
      _excelSetCell(summarySheet, 2, 0,
          'As of Date: ${DateFormat('dd MMM yyyy').format(asOfDate.value)}',
          fontSize: 10, fontColor: '1A237E');
      _excelSetCell(summarySheet, 3, 0,
          'Period: ${selectedPeriod.value}',
          fontSize: 10, fontColor: '1A237E');

      _excelSetCell(summarySheet, 5, 0, 'SUMMARY', bold: true, fontSize: 11, bgColor: 'E8EAF6');

      final summaryRows = [
        ['Total Assets', _formatAmount(totalAssets.value)],
        ['Total Liabilities', _formatAmount(totalLiabilities.value)],
        ['Equity', _formatAmount(equity.value)],
        ['Total Liabilities & Equity', _formatAmount(totalLiabilities.value + equity.value)],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(summarySheet, 6 + r, c, summaryRows[r][c],
              bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5');
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Assets Sheet
      final assetsSheet = excelFile['Assets'];
      _excelSetCell(assetsSheet, 0, 0, 'ASSETS', bold: true, fontSize: 14, bgColor: '2E7D32', fontColor: 'FFFFFF');

      int row = 2;
      for (final category in assetsData.keys) {
        final items = assetsData[category] ?? {};
        if (items.isNotEmpty) {
          _excelSetCell(assetsSheet, row, 0, category, bold: true, fontSize: 11, bgColor: 'E8EAF6');
          row++;

          for (final item in items.entries) {
            _excelSetCell(assetsSheet, row, 0, '   ${item.key}', bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF');
            _excelSetCell(assetsSheet, row, 1, item.value, bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF');
            row++;
          }

          _excelSetCell(assetsSheet, row, 0, '   Total $category', bold: true, bgColor: 'E8EAF6');
          _excelSetCell(assetsSheet, row, 1, items.values.fold(0.0, (sum, val) => sum + val),
              bold: true, bgColor: 'E8EAF6', fontColor: '2E7D32');
          row += 2;
        }
      }

      _excelSetCell(assetsSheet, row, 0, 'TOTAL ASSETS', bold: true, fontSize: 12, bgColor: '2E7D32', fontColor: 'FFFFFF');
      _excelSetCell(assetsSheet, row, 1, totalAssets.value, bold: true, bgColor: '2E7D32', fontColor: 'FFFFFF');

      assetsSheet.setColumnWidth(0, 40);
      assetsSheet.setColumnWidth(1, 20);

      // Liabilities Sheet
      final liabilitiesSheet = excelFile['Liabilities'];
      _excelSetCell(liabilitiesSheet, 0, 0, 'LIABILITIES', bold: true, fontSize: 14, bgColor: 'C62828', fontColor: 'FFFFFF');

      row = 2;
      for (final category in liabilitiesData.keys) {
        final items = liabilitiesData[category] ?? {};
        if (items.isNotEmpty) {
          _excelSetCell(liabilitiesSheet, row, 0, category, bold: true, fontSize: 11, bgColor: 'E8EAF6');
          row++;

          for (final item in items.entries) {
            _excelSetCell(liabilitiesSheet, row, 0, '   ${item.key}', bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF');
            _excelSetCell(liabilitiesSheet, row, 1, item.value, bgColor: row.isEven ? 'F5F5F5' : 'FFFFFF');
            row++;
          }

          _excelSetCell(liabilitiesSheet, row, 0, '   Total $category', bold: true, bgColor: 'E8EAF6');
          _excelSetCell(liabilitiesSheet, row, 1, items.values.fold(0.0, (sum, val) => sum + val),
              bold: true, bgColor: 'E8EAF6', fontColor: 'C62828');
          row += 2;
        }
      }

      _excelSetCell(liabilitiesSheet, row, 0, 'TOTAL LIABILITIES', bold: true, fontSize: 12, bgColor: 'C62828', fontColor: 'FFFFFF');
      _excelSetCell(liabilitiesSheet, row, 1, totalLiabilities.value, bold: true, bgColor: 'C62828', fontColor: 'FFFFFF');

      liabilitiesSheet.setColumnWidth(0, 40);
      liabilitiesSheet.setColumnWidth(1, 20);

      // Equity Sheet
      final equitySheet = excelFile['Equity'];
      _excelSetCell(equitySheet, 0, 0, 'EQUITY', bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
      _excelSetCell(equitySheet, 2, 0, 'Total Equity', bold: true);
      _excelSetCell(equitySheet, 2, 1, equity.value, bold: true, fontColor: '1A237E');
      _excelSetCell(equitySheet, 4, 0, 'Total Liabilities & Equity', bold: true, fontSize: 12, bgColor: 'E8EAF6');
      _excelSetCell(equitySheet, 4, 1, totalLiabilities.value + equity.value,
          bold: true, bgColor: 'E8EAF6', fontColor: '1A237E');

      equitySheet.setColumnWidth(0, 30);
      equitySheet.setColumnWidth(1, 20);

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName = 'balance_sheet_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Balance sheet exported to Excel',
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

    if (value == null) {
      cell.value = TextCellValue('0');
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is String) {
      cell.value = TextCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }

    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontColorHex: ExcelColor.fromHexString('#$fontColor'),
      backgroundColorHex: bgColor != null
          ? ExcelColor.fromHexString('#$bgColor')
          : ExcelColor.fromHexString('#FFFFFF'),
    );
  }

  // ─── PRINT BALANCE SHEET ──────────────────────────────────────────
  void printBalanceSheet() {
    AppSnackbar.success(
      kPrimary,
      'Print',
      'Preparing balance sheet for print...',
    );
  }

  // ─── SHOW ERROR ──────────────────────────────────────────────────
  void _showError(String message) {
    AppSnackbar.error(kDanger, 'Error', message);
  }

  // ─── GETTERS FOR UI ──────────────────────────────────────────────
  List<String> get liabilityCategories => liabilitiesData.keys.toList();
  List<String> get assetCategories => assetsData.keys.toList();
  List<String> get equityCategories => equityData.keys.toList();

  Map<String, double> getCategoryItems(String category, bool isLiability) {
    if (isLiability) {
      return liabilitiesData[category] ?? {};
    }
    return assetsData[category] ?? {};
  }

  double getCategoryTotal(String category, bool isLiability) {
    final items = getCategoryItems(category, isLiability);
    return items.values.fold(0.0, (sum, val) => sum + val);
  }

  bool get hasData => liabilitiesData.isNotEmpty || assetsData.isNotEmpty;
}