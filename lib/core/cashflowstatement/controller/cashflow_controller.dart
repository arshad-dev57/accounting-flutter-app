import 'dart:convert';
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class CashFlowController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var selectedPeriod = 'This Month'.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  
  // Cash Flow Data
  var openingCashBalance = 0.0.obs;
  var closingCashBalance = 0.0.obs;
  var netCashFlow = 0.0.obs;
  var netCashFlowPercentage = 0.0.obs;
  
  // Activities
  var operatingItems = <CashFlowItem>[].obs;
  var investingItems = <CashFlowItem>[].obs;
  var financingItems = <CashFlowItem>[].obs;
  
  var cashFlowFromOperations = 0.0.obs;
  var cashFlowFromInvesting = 0.0.obs;
  var cashFlowFromFinancing = 0.0.obs;
  
  var periodText = ''.obs;
  
  final List<String> periodOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range'
  ];
  
  final ApiClient _api = Get.find<ApiClient>();
  
  @override
  void onInit() {
    super.onInit();
    loadCashFlowData();
  }
  
  String _formatAmount(double amount) {
    return '\$. ${amount.toStringAsFixed(2)}';
  }
  
  Future<void> loadCashFlowData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      Map<String, dynamic> params = {};
      
      if (selectedPeriod.value == 'Custom Range' && selectedDateRange.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.start);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(selectedDateRange.value!.end);
      } else {
        params['period'] = selectedPeriod.value;
      }
      
      final response = await _api.get('/api/reports/cash-flow', queryParameters: params);
      
      print("📡 Response Status: ${response.statusCode}");
      
      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          
          // Period text
          periodText.value = data['period']['displayText'];
          
          // Operating Activities
          if (data['operatingActivities'] != null) {
            operatingItems.value = (data['operatingActivities']['items'] as List)
                .map((item) => CashFlowItem(
                  name: item['name'],
                  amount: (item['amount'] as num).toDouble(),
                  type: item['type']
                )).toList();
            cashFlowFromOperations.value = (data['operatingActivities']['total'] as num).toDouble();
          }
          
          // Investing Activities
          if (data['investingActivities'] != null) {
            investingItems.value = (data['investingActivities']['items'] as List)
                .map((item) => CashFlowItem(
                  name: item['name'],
                  amount: (item['amount'] as num).toDouble(),
                  type: item['type']
                )).toList();
            cashFlowFromInvesting.value = (data['investingActivities']['total'] as num).toDouble();
          }
          
          // Financing Activities
          if (data['financingActivities'] != null) {
            financingItems.value = (data['financingActivities']['items'] as List)
                .map((item) => CashFlowItem(
                  name: item['name'],
                  amount: (item['amount'] as num).toDouble(),
                  type: item['type']
                )).toList();
            cashFlowFromFinancing.value = (data['financingActivities']['total'] as num).toDouble();
          }
          
          // Totals
          netCashFlow.value = (data['netCashFlow'] as num).toDouble();
          openingCashBalance.value = (data['openingCashBalance'] as num).toDouble();
          closingCashBalance.value = (data['closingCashBalance'] as num).toDouble();
          netCashFlowPercentage.value = (data['netCashFlowPercentage'] as num).toDouble();
          
          print("✅ Cash Flow loaded successfully");
          print("📊 Net Cash Flow: ${netCashFlow.value}");
          
        } else {
          hasError.value = true;
          errorMessage.value = responseData['message'] ?? 'Failed to load cash flow';
          _showError(errorMessage.value);
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message ?? 'Server error: ${response.statusCode}';
        _showError(errorMessage.value);
      }
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'error: ${e.toString()}';
      print("🔥 Error loading cash flow: $e");
      _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
  
  void changePeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    if (period != 'Custom Range') {
      selectedDateRange.value = null;
    }
    loadCashFlowData();
  }
  
  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    if (range != null) {
      selectedPeriod.value = 'Custom Range';
      loadCashFlowData();
    }
  }
  
  void clearDateRange() {
    selectedDateRange.value = null;
    selectedPeriod.value = 'This Month';
    loadCashFlowData();
  }
  
  void retryLoad() {
    loadCashFlowData();
  }
  
  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '\$ ${formatter.format(amount)}';
  }
  
  // ==================== EXPORT FUNCTIONS ====================
  
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
           Text(
              'Export Cash Flow Statement',
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
              title:Text('Export as PDF'),
              onTap: () {
                Get.back();
                exportToPdf();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Color(0xFF2E7D32)),
              title:Text('Export as Excel'),
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
  Future<void> exportToPdf() async {
  try {
    // Show loading only on mobile
    if (!kIsWeb) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          _pdfOperatingSection(),
          pw.SizedBox(height: 16),
          _pdfInvestingSection(),
          pw.SizedBox(height: 16),
          _pdfFinancingSection(),
          pw.SizedBox(height: 16),
          _pdfTotalsSection(),
        ],
      ),
    );
    
    final bytes = await pdf.save();
    final fileName = 'cash_flow_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    
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
        Colors.green,
        'Success',
        'Cash flow statement exported to PDF',
        duration: const Duration(seconds: 2),
      );
    } else {
      // MOBILE: Save to file and open
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      if (Get.isDialogOpen ?? false) Get.back();
      
      AppSnackbar.success(
        Colors.green,
        'Success',
        'Cash flow statement exported to PDF',
        duration: const Duration(seconds: 2),
      );
      
      await OpenFile.open(file.path);
    }
  } catch (e) {
    if (Get.isDialogOpen ?? false) Get.back();
    AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
  }
}
  pw.Widget _pdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Cash Flow Statement',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800)),
            pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
                color: PdfColors.indigo800,
                borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text('LedgerPro',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10)),
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
              top: pw.BorderSide(color: PdfColors.grey300, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Confidential - For Internal Use Only',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
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
          border: pw.Border.all(color: PdfColors.indigo200)),
      child: pw.Column(
        children: [
          pw.Text('Period: ${periodText.value}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem('Opening Balance', _formatAmount(openingCashBalance.value), PdfColors.indigo700),
              _pdfSummaryItem('Closing Balance', _formatAmount(closingCashBalance.value), PdfColors.indigo700),
              _pdfSummaryItem('Net Cash Flow', _formatAmount(netCashFlow.value), 
                  netCashFlow.value >= 0 ? PdfColors.green700 : PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Net Cash Flow Change: ', style: pw.TextStyle(fontSize: 9)),
              pw.Text('${netCashFlowPercentage.value.toStringAsFixed(1)}%', 
                  style: pw.TextStyle(fontSize: 9, color: netCashFlowPercentage.value >= 0 ? PdfColors.green700 : PdfColors.red700)),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(children: [
      pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.SizedBox(height: 4),
      pw.Text(value,
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }
  
  pw.Widget _pdfOperatingSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Cash Flow from Operating Activities',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
        pw.SizedBox(height: 8),
        _pdfItemList(operatingItems, 'Total Operating Cash Flow', cashFlowFromOperations.value),
      ],
    );
  }
  
  pw.Widget _pdfInvestingSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Cash Flow from Investing Activities',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
        pw.SizedBox(height: 8),
        _pdfItemList(investingItems, 'Total Investing Cash Flow', cashFlowFromInvesting.value),
      ],
    );
  }
  
  pw.Widget _pdfFinancingSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Cash Flow from Financing Activities',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
        pw.SizedBox(height: 8),
        _pdfItemList(financingItems, 'Total Financing Cash Flow', cashFlowFromFinancing.value),
      ],
    );
  }
  
  pw.Widget _pdfItemList(List<CashFlowItem> items, String totalLabel, double total) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text('No transactions found', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      );
    }
    
    return pw.Column(
      children: [
        ...items.map((item) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(item.name, style: pw.TextStyle(fontSize: 10))),
            pw.Text(_formatAmount(item.amount), 
                style: pw.TextStyle(fontSize: 10, color: item.amount >= 0 ? PdfColors.green700 : PdfColors.red700)),
          ]),
        )).toList(),
        pw.Divider(),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(totalLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(total), 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, 
                    color: total >= 0 ? PdfColors.green700 : PdfColors.red700)),
          ]),
        ),
      ],
    );
  }
  
  pw.Widget _pdfTotalsSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.indigo200)),
      child: pw.Column(
        children: [
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Opening Cash Balance', style: pw.TextStyle(fontSize: 11))),
            pw.Text(_formatAmount(openingCashBalance.value), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Net Cash Flow', style: pw.TextStyle(fontSize: 11))),
            pw.Text(_formatAmount(netCashFlow.value), 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, 
                    color: netCashFlow.value >= 0 ? PdfColors.green700 : PdfColors.red700)),
          ]),
          pw.Divider(),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Closing Cash Balance', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
            pw.Text(_formatAmount(closingCashBalance.value), 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
          ]),
        ],
      ),
    );
  }
  Future<void> exportToExcelFile() async {
  try {
    // Show loading only on mobile
    if (!kIsWeb) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    
    final excelFile = Excel.createExcel();
    
    // Summary Sheet
    final summarySheet = excelFile['Summary'];
    excelFile.setDefaultSheet('Summary');
    
    _excelSetCell(summarySheet, 0, 0, 'Cash Flow Statement',
        bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
    _excelSetCell(summarySheet, 1, 0,
        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
        fontSize: 9, fontColor: '757575');
    _excelSetCell(summarySheet, 2, 0,
        'Period: ${periodText.value}',
        fontSize: 10, fontColor: '1A237E');
    
    _excelSetCell(summarySheet, 4, 0, 'SUMMARY', bold: true, fontSize: 11, bgColor: 'E8EAF6');
    
    final summaryRows = [
      ['Opening Cash Balance', _formatAmount(openingCashBalance.value)],
      ['Net Cash Flow', _formatAmount(netCashFlow.value)],
      ['Closing Cash Balance', _formatAmount(closingCashBalance.value)],
      ['Net Cash Flow Change', '${netCashFlowPercentage.value.toStringAsFixed(1)}%'],
    ];
    
    for (int r = 0; r < summaryRows.length; r++) {
      for (int c = 0; c < 2; c++) {
        _excelSetCell(summarySheet, 5 + r, c, summaryRows[r][c],
            bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5');
      }
    }
    summarySheet.setColumnWidth(0, 25);
    summarySheet.setColumnWidth(1, 20);
    
    // Operating Activities Sheet
    final operatingSheet = excelFile['Operating Activities'];
    _excelSetCell(operatingSheet, 0, 0, 'Cash Flow from Operating Activities', 
        bold: true, fontSize: 12, bgColor: '2E7D32', fontColor: 'FFFFFF');
    _excelSetCell(operatingSheet, 1, 0, 'Description', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(operatingSheet, 1, 1, 'Amount', bold: true, bgColor: 'E8EAF6');
    
    int row = 2;
    for (final item in operatingItems) {
      final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
      _excelSetCell(operatingSheet, row, 0, item.name, bgColor: bg);
      _excelSetCell(operatingSheet, row, 1, item.amount, bgColor: bg, fontColor: item.amount >= 0 ? '2E7D32' : 'C62828');
      row++;
    }
    _excelSetCell(operatingSheet, row, 0, 'Total Operating Cash Flow', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(operatingSheet, row, 1, cashFlowFromOperations.value, bold: true, bgColor: 'E8EAF6', fontColor: cashFlowFromOperations.value >= 0 ? '2E7D32' : 'C62828');
    
    operatingSheet.setColumnWidth(0, 40);
    operatingSheet.setColumnWidth(1, 20);
    
    // Investing Activities Sheet
    final investingSheet = excelFile['Investing Activities'];
    _excelSetCell(investingSheet, 0, 0, 'Cash Flow from Investing Activities', 
        bold: true, fontSize: 12, bgColor: 'F39C12', fontColor: 'FFFFFF');
    _excelSetCell(investingSheet, 1, 0, 'Description', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(investingSheet, 1, 1, 'Amount', bold: true, bgColor: 'E8EAF6');
    
    row = 2;
    for (final item in investingItems) {
      final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
      _excelSetCell(investingSheet, row, 0, item.name, bgColor: bg);
      _excelSetCell(investingSheet, row, 1, item.amount, bgColor: bg, fontColor: item.amount >= 0 ? '2E7D32' : 'C62828');
      row++;
    }
    _excelSetCell(investingSheet, row, 0, 'Total Investing Cash Flow', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(investingSheet, row, 1, cashFlowFromInvesting.value, bold: true, bgColor: 'E8EAF6', fontColor: cashFlowFromInvesting.value >= 0 ? '2E7D32' : 'C62828');
    
    investingSheet.setColumnWidth(0, 40);
    investingSheet.setColumnWidth(1, 20);
    
    // Financing Activities Sheet
    final financingSheet = excelFile['Financing Activities'];
    _excelSetCell(financingSheet, 0, 0, 'Cash Flow from Financing Activities', 
        bold: true, fontSize: 12, bgColor: 'C62828', fontColor: 'FFFFFF');
    _excelSetCell(financingSheet, 1, 0, 'Description', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(financingSheet, 1, 1, 'Amount', bold: true, bgColor: 'E8EAF6');
    
    row = 2;
    for (final item in financingItems) {
      final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
      _excelSetCell(financingSheet, row, 0, item.name, bgColor: bg);
      _excelSetCell(financingSheet, row, 1, item.amount, bgColor: bg, fontColor: item.amount >= 0 ? '2E7D32' : 'C62828');
      row++;
    }
    _excelSetCell(financingSheet, row, 0, 'Total Financing Cash Flow', bold: true, bgColor: 'E8EAF6');
    _excelSetCell(financingSheet, row, 1, cashFlowFromFinancing.value, bold: true, bgColor: 'E8EAF6', fontColor: cashFlowFromFinancing.value >= 0 ? '2E7D32' : 'C62828');
    
    financingSheet.setColumnWidth(0, 40);
    financingSheet.setColumnWidth(1, 20);
    
    // Totals Sheet
    final totalsSheet = excelFile['Totals'];
    _excelSetCell(totalsSheet, 0, 0, 'Cash Flow Summary', bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
    _excelSetCell(totalsSheet, 2, 0, 'Cash Flow from Operations', bold: true);
    _excelSetCell(totalsSheet, 2, 1, cashFlowFromOperations.value, fontColor: cashFlowFromOperations.value >= 0 ? '2E7D32' : 'C62828');
    _excelSetCell(totalsSheet, 3, 0, 'Cash Flow from Investing', bold: true);
    _excelSetCell(totalsSheet, 3, 1, cashFlowFromInvesting.value, fontColor: cashFlowFromInvesting.value >= 0 ? '2E7D32' : 'C62828');
    _excelSetCell(totalsSheet, 4, 0, 'Cash Flow from Financing', bold: true);
    _excelSetCell(totalsSheet, 4, 1, cashFlowFromFinancing.value, fontColor: cashFlowFromFinancing.value >= 0 ? '2E7D32' : 'C62828');
    _excelSetCell(totalsSheet, 5, 0, 'Net Cash Flow', bold: true);
    _excelSetCell(totalsSheet, 5, 1, netCashFlow.value, bold: true, fontColor: netCashFlow.value >= 0 ? '2E7D32' : 'C62828');
    _excelSetCell(totalsSheet, 7, 0, 'Opening Cash Balance', bold: true);
    _excelSetCell(totalsSheet, 7, 1, openingCashBalance.value);
    _excelSetCell(totalsSheet, 8, 0, 'Net Cash Flow', bold: true);
    _excelSetCell(totalsSheet, 8, 1, netCashFlow.value, fontColor: netCashFlow.value >= 0 ? '2E7D32' : 'C62828');
    _excelSetCell(totalsSheet, 9, 0, 'Closing Cash Balance', bold: true, fontSize: 12);
    _excelSetCell(totalsSheet, 9, 1, closingCashBalance.value, bold: true, fontColor: '1A237E');
    _excelSetCell(totalsSheet, 11, 0, 'Net Cash Flow Change', bold: true);
    _excelSetCell(totalsSheet, 11, 1, '${netCashFlowPercentage.value.toStringAsFixed(1)}%');
    
    totalsSheet.setColumnWidth(0, 30);
    totalsSheet.setColumnWidth(1, 20);
    
    excelFile.delete('Sheet1');
    
    final bytes = excelFile.save();
    if (bytes == null) throw Exception('Excel save failed');
    
    final fileName = 'cash_flow_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    
    if (kIsWeb) {
      // WEB: Download Excel
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
        'Cash flow statement exported to Excel',
        duration: const Duration(seconds: 2),
      );
    } else {
      // MOBILE: Save and open
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      if (Get.isDialogOpen ?? false) Get.back();
      
      AppSnackbar.success(
        Colors.green,
        'Success',
        'Cash flow statement exported to Excel',
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
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
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
    AppSnackbar.error(
      Colors.blue,
      'Print',
      'Preparing print...',
      
      duration: const Duration(seconds: 2),
    );
  }
  
  void _handleSessionExpired() {
    AppSnackbar.error(
      Colors.red,
      'Session Expired',
      'Please login again',
      
      duration: const Duration(seconds: 2),
    );
  }
  
  void _showError(String message) {
    AppSnackbar.error(
      Colors.red,
      'Error',
      message,
    );
  }
}

class CashFlowItem {
  final String name;
  final double amount;
  final String type;
  
  CashFlowItem({required this.name, required this.amount, required this.type});
}