import 'dart:io';

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/CapitalEquity/models/equity_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;

class EquityController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  
  // Observable variables
  var allEquityAccounts = <EquityAccount>[].obs;
  var equityAccounts = <EquityAccount>[].obs;
  var transactions = <OwnerTransaction>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;
  
  final List<String> filterOptions = ['All', 'Capital', 'Retained Earnings', 'Drawings', 'Reserves'];
  
  // Summary data
  var totalCapital = 0.0.obs;
  var totalRetainedEarnings = 0.0.obs;
  var totalReserves = 0.0.obs;
  var totalDrawings = 0.0.obs;
  var totalEquity = 0.0.obs;
  
  TextEditingController searchController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadEquityAccounts();
    loadTransactions();
    loadSummary();
  }
  
  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.onClose();
  }
  
  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    
    if (searchQuery.value.isEmpty) {
      equityAccounts.value = allEquityAccounts.value;
      _updateSummaryForFiltered(allEquityAccounts.value);
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      final results = allEquityAccounts.where((account) {
        return account.accountName.toLowerCase().contains(searchLower) ||
               account.accountCode.toLowerCase().contains(searchLower) ||
               account.accountType.toLowerCase().contains(searchLower);
      }).toList();
      equityAccounts.value = results;
      _updateSummaryForFiltered(results);
    }
  }
  
  void _updateSummaryForFiltered(List<EquityAccount> filteredAccounts) {
    totalCapital.value = filteredAccounts
        .where((a) => a.accountType == 'Capital')
        .fold(0.0, (sum, a) => sum + a.currentBalance);
        
    totalRetainedEarnings.value = filteredAccounts
        .where((a) => a.accountType == 'Retained Earnings')
        .fold(0.0, (sum, a) => sum + a.currentBalance);
        
    totalReserves.value = filteredAccounts
        .where((a) => a.accountType == 'Reserves')
        .fold(0.0, (sum, a) => sum + a.currentBalance);
        
    totalDrawings.value = filteredAccounts
        .where((a) => a.accountType == 'Drawings')
        .fold(0.0, (sum, a) => sum + a.currentBalance);
        
    totalEquity.value = filteredAccounts
        .fold(0.0, (sum, a) => sum + a.currentBalance);
  }
  
  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }
  
  Future<void> loadEquityAccounts() async {
    try {
      isLoading.value = true;
      
      Map<String, dynamic> params = {};
      params['type'] = 'Equity';
      
      if (selectedFilter.value != 'All' && selectedFilter.value != 'Equity') {
        params['accountType'] = selectedFilter.value;
      }
      
      final response = await _apiClient.get(
        '/api/chart-of-accounts',
        queryParameters: params,
      );
      
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> accountsData = responseData['data'];
          final newAccounts = accountsData.map((json) => EquityAccount.fromChartOfAccountsJson(json)).toList();
          
          allEquityAccounts.value = newAccounts;
          
          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            equityAccounts.value = newAccounts;
          }
        }
      }
    } catch (e) {
      print('Error loading equity accounts: $e');
      _showError('Error loading equity accounts');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadTransactions() async {
    try {
      final response = await _apiClient.get('/api/equity/transactions');
      
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> transactionsData = responseData['data'];
          transactions.value = transactionsData.map((json) => OwnerTransaction.fromJson(json)).toList();
        }
      } 
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }
  
  Future<void> loadSummary() async {
    try {
      final response = await _apiClient.get('/api/equity/summary');
      
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          totalCapital.value = (data['totalCapital'] ?? 0).toDouble();
          totalRetainedEarnings.value = (data['totalRetainedEarnings'] ?? 0).toDouble();
          totalReserves.value = (data['totalReserves'] ?? 0).toDouble();
          totalDrawings.value = (data['totalDrawings'] ?? 0).toDouble();
          totalEquity.value = (data['totalEquity'] ?? 0).toDouble();
        }
      } 
    } catch (e) {
      print('Error loading summary: $e');
    }
  }
  
  Future<void> addCapital({
    required String accountId,
    required double amount,
    required String description,
    required String reference,
  }) async {
    try {
      isProcessing.value = true;
      
      final Map<String, dynamic> capitalData = {
        'accountId': accountId,
        'amount': amount,
        'description': description,
        'reference': reference,
      };
      
      final response = await _apiClient.post(
        '/api/equity/add-capital',
        body: capitalData,
      );
      
      if (response.success && (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          Get.back();
          AppSnackbar.success(
            Colors.green,
            'Success',
            'Capital of ${formatAmount(amount)} added successfully\nJournal entry created',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts();
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to add capital');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to add capital');
      }
    } catch (e) {
      print('Error adding capital: $e');
      _showError('Error adding capital');
    } finally {
      isProcessing.value = false;
    }
  }
  
  Future<void> recordDrawings({
    required String accountId,
    required double amount,
    required String description,
    required String reference,
  }) async {
    try {
      isProcessing.value = true;
      
      final Map<String, dynamic> drawingsData = {
        'accountId': accountId,
        'amount': amount,
        'description': description,
        'reference': reference,
      };
      
      final response = await _apiClient.post(
        '/api/equity/record-drawings',
        body: drawingsData,
      );
      
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          Get.back();
          AppSnackbar.success(
            Colors.green,
            'Success',
            'Drawings of ${formatAmount(amount)} recorded successfully\nJournal entry created',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts();
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to record drawings');
        }
      } 
    } catch (e) {
      print('Error recording drawings: $e');
      _showError('Error recording drawings');
    } finally {
      isProcessing.value = false;
    }
  }
  
  Future<void> transferToRetainedEarnings({
    required double amount,
    required String description,
    required String reference,
  }) async {
    try {
      isProcessing.value = true;
      
      final Map<String, dynamic> transferData = {
        'amount': amount,
        'description': description,
        'reference': reference,
      };
      
      final response = await _apiClient.post(
        '/api/equity/transfer-retained-earnings',
        body: transferData,
      );
      
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          Get.back();
          AppSnackbar.success(
            Colors.green,
            'Success',
            '${formatAmount(amount)} transferred to retained earnings\nJournal entry created',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts();
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to transfer');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to transfer');
      }
    } catch (e) {
      print('Error transferring to retained earnings: $e');
      _showError('Error transferring');
    } finally {
      isProcessing.value = false;
    }
  }
  
  // ==================== EXPORT FUNCTIONS ====================
  
  void exportEquity() {
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
              'Export Equity Report',
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
            _pdfEquityAccountsSection(),
            pw.SizedBox(height: 16),
            _pdfTransactionsSection(),
          ],
        ),
      );
      
      final bytes = await pdf.save();
      final fileName = 'equity_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      
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
          'Equity report exported to PDF',
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
          'Equity report exported to PDF',
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
            pw.Text('Equity Report',
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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem('Total Capital', _formatAmount(totalCapital.value), PdfColors.indigo700),
              _pdfSummaryItem('Retained Earnings', _formatAmount(totalRetainedEarnings.value), PdfColors.green700),
              _pdfSummaryItem('Reserves', _formatAmount(totalReserves.value), PdfColors.orange700),
              _pdfSummaryItem('Drawings', _formatAmount(totalDrawings.value), PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem('Total Equity', _formatAmount(totalEquity.value), PdfColors.indigo800),
              _pdfSummaryItem('Filter', selectedFilter.value, PdfColors.grey700),
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
  
  pw.Widget _pdfEquityAccountsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Equity Accounts',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
          child: pw.Row(children: [
            pw.Expanded(flex: 2, child: pw.Text('Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 4, child: pw.Text('Account Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Opening', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Additions', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Withdrawal', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Balance', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ]),
        ),
        ...equityAccounts.map((account) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
          child: pw.Row(children: [
            pw.Expanded(flex: 2, child: pw.Text(account.accountCode, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 4, child: pw.Text(account.accountName, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(account.accountType, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(account.openingBalance), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(account.additions), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: PdfColors.green700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(account.withdrawals), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: PdfColors.red700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(account.currentBalance), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          ]),
        )).toList(),
        pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(children: [
            pw.Expanded(flex: 8, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('', textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 2, child: pw.Text('', textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 2, child: pw.Text('', textAlign: pw.TextAlign.right)),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(equityAccounts.fold(0.0, (sum, a) => sum + a.currentBalance)),
                textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800))),
          ]),
        ),
      ],
    );
  }
  
  pw.Widget _pdfTransactionsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Transaction History',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
          child: pw.Row(children: [
            pw.Expanded(flex: 3, child: pw.Text('Account', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ]),
        ),
        ...transactions.map((txn) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
          child: pw.Row(children: [
            pw.Expanded(flex: 3, child: pw.Text(txn.accountName, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(txn.type, style: pw.TextStyle(fontSize: 9, color: txn.type == 'Additional Capital' ? PdfColors.green700 : (txn.type == 'Drawings' ? PdfColors.red700 : PdfColors.orange700)))),
            pw.Expanded(flex: 2, child: pw.Text(DateFormat('dd/MM/yyyy').format(txn.date), style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 3, child: pw.Text(txn.description, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(txn.amount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: txn.type == 'Additional Capital' ? PdfColors.green700 : PdfColors.red700))),
          ]),
        )).toList(),
      ],
    );
  }
  
  Future<void> exportToExcel() async {
    try {
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
      
      final excelFile = excel.Excel.createExcel();
      
      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');
      
      _excelSetCell(summarySheet, 0, 0, 'Equity Report',
          bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
      _excelSetCell(summarySheet, 1, 0,
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          fontSize: 9, fontColor: '757575');
      _excelSetCell(summarySheet, 2, 0,
          'Filter: ${selectedFilter.value}',
          fontSize: 10, fontColor: '1A237E');
      if (searchQuery.value.isNotEmpty) {
        _excelSetCell(summarySheet, 3, 0,
          'Search: ${searchQuery.value}',
          fontSize: 10, fontColor: '1A237E');
      }
      
      _excelSetCell(summarySheet, 5, 0, 'SUMMARY', bold: true, fontSize: 11, bgColor: 'E8EAF6');
      
      final summaryRows = [
        ['Total Capital', _formatAmount(totalCapital.value)],
        ['Retained Earnings', _formatAmount(totalRetainedEarnings.value)],
        ['Reserves', _formatAmount(totalReserves.value)],
        ['Drawings', _formatAmount(totalDrawings.value)],
        ['Total Equity', _formatAmount(totalEquity.value)],
        ['Total Accounts', equityAccounts.length.toString()],
      ];
      
      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(summarySheet, 6 + r, c, summaryRows[r][c],
              bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5');
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);
      
      // Equity Accounts Sheet
      final accountsSheet = excelFile['Equity Accounts'];
      final accountHeaders = [
        'Account Code', 'Account Name', 'Account Type', 'Opening Balance',
        'Additions', 'Withdrawals', 'Current Balance', 'Last Updated', 'Notes'
      ];
      
      for (int i = 0; i < accountHeaders.length; i++) {
        _excelSetCell(accountsSheet, 0, i, accountHeaders[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }
      
      int row = 1;
      for (final account in equityAccounts) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(accountsSheet, row, 0, account.accountCode, bgColor: bg);
        _excelSetCell(accountsSheet, row, 1, account.accountName, bgColor: bg);
        _excelSetCell(accountsSheet, row, 2, account.accountType, bgColor: bg);
        _excelSetCell(accountsSheet, row, 3, account.openingBalance, bgColor: bg);
        _excelSetCell(accountsSheet, row, 4, account.additions, bgColor: bg, fontColor: '2E7D32');
        _excelSetCell(accountsSheet, row, 5, account.withdrawals, bgColor: bg, fontColor: 'C62828');
        _excelSetCell(accountsSheet, row, 6, account.currentBalance, bgColor: bg, fontColor: '1A237E');
        _excelSetCell(accountsSheet, row, 7, DateFormat('dd MMM yyyy').format(account.lastUpdated), bgColor: bg);
        _excelSetCell(accountsSheet, row, 8, account.notes.isEmpty ? '-' : account.notes, bgColor: bg);
        row++;
      }
      
      final accountColWidths = [15.0, 30.0, 18.0, 15.0, 15.0, 15.0, 15.0, 12.0, 30.0];
      for (int i = 0; i < accountColWidths.length; i++) {
        accountsSheet.setColumnWidth(i, accountColWidths[i]);
      }
      
      // Transactions Sheet
      final transactionsSheet = excelFile['Transactions'];
      final transactionHeaders = [
        'Account Name', 'Transaction Type', 'Date', 'Amount', 'Description', 'Reference'
      ];
      
      for (int i = 0; i < transactionHeaders.length; i++) {
        _excelSetCell(transactionsSheet, 0, i, transactionHeaders[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }
      
      int txnRow = 1;
      for (final txn in transactions) {
        final bg = txnRow.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(transactionsSheet, txnRow, 0, txn.accountName, bgColor: bg);
        _excelSetCell(transactionsSheet, txnRow, 1, txn.type, 
            bgColor: bg, fontColor: txn.type == 'Additional Capital' ? '2E7D32' : (txn.type == 'Drawings' ? 'C62828' : 'F39C12'));
        _excelSetCell(transactionsSheet, txnRow, 2, DateFormat('dd MMM yyyy').format(txn.date), bgColor: bg);
        _excelSetCell(transactionsSheet, txnRow, 3, txn.amount, bgColor: bg, fontColor: txn.type == 'Additional Capital' ? '2E7D32' : 'C62828');
        _excelSetCell(transactionsSheet, txnRow, 4, txn.description, bgColor: bg);
        _excelSetCell(transactionsSheet, txnRow, 5, txn.reference.isEmpty ? '-' : txn.reference, bgColor: bg);
        txnRow++;
      }
      
      final txnColWidths = [25.0, 18.0, 12.0, 15.0, 35.0, 20.0];
      for (int i = 0; i < txnColWidths.length; i++) {
        transactionsSheet.setColumnWidth(i, txnColWidths[i]);
      }
      
      excelFile.delete('Sheet1');
      
      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');
      
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'equity_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (Get.isDialogOpen ?? false) Get.back();
        
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Equity report exported to Excel',
          duration: const Duration(seconds: 2),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final fileName = 'equity_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (Get.isDialogOpen ?? false) Get.back();
        
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Equity report exported to Excel',
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
    excel.Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool bold = false,
    double fontSize = 10,
    String? bgColor,
    String fontColor = '000000',
  }) {
    final cell = sheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value is double
        ? excel.DoubleCellValue(value)
        : value is int
            ? excel.IntCellValue(value)
            : excel.TextCellValue(value.toString());

    cell.cellStyle = excel.CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontColorHex: excel.ExcelColor.fromHexString('#$fontColor'),
      backgroundColorHex: bgColor != null
          ? excel.ExcelColor.fromHexString('#$bgColor')
          : excel.ExcelColor.fromHexString('#FFFFFF'),
    );
  }
  
  void printEquity() {
    AppSnackbar.success(
      Colors.green,
      'Print',
      'Preparing equity report...',
      duration: const Duration(seconds: 2),
    );
  }
  
  // ==================== SHOW ADD CAPITAL DIALOG ====================
  void showAddCapitalDialog(EquityAccount account) {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    String reference = '';
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 85.w,
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Capital', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Text('Account: ${account.accountName}', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  Text('Current Balance: ${formatAmount(account.currentBalance)}', style: TextStyle(fontSize: 12.sp, color: kSuccess)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount *',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => amount = double.tryParse(v) ?? 0,
                          validator: (v) => v == null || v.isEmpty ? 'Amount required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          maxLines: 2,
                          onChanged: (v) => description = v,
                          validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          onChanged: (v) => reference = v,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: isProcessing.value ? null : () {
                            if (formKey.currentState!.validate()) {
                              addCapital(
                                accountId: account.id,
                                amount: amount,
                                description: description,
                                reference: reference,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Add Capital', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        )),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  void showRecordDrawingsDialog(EquityAccount account) {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    String reference = '';
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 85.w,
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Record Drawings', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Text('Account: ${account.accountName}', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  Text('Current Balance: ${formatAmount(account.currentBalance)}', style: TextStyle(fontSize: 12.sp, color: kDanger)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount *',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => amount = double.tryParse(v) ?? 0,
                          validator: (v) => v == null || v.isEmpty ? 'Amount required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          maxLines: 2,
                          onChanged: (v) => description = v,
                          validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          onChanged: (v) => reference = v,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: isProcessing.value ? null : () {
                            if (formKey.currentState!.validate()) {
                              recordDrawings(
                                accountId: account.id,
                                amount: amount,
                                description: description,
                                reference: reference,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Record Drawings', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        )),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  void showTransferToRetainedEarningsDialog() {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    String reference = '';
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 85.w,
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Transfer to Retained Earnings', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Text('Transfer from Profit & Loss to Retained Earnings', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount *',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => amount = double.tryParse(v) ?? 0,
                          validator: (v) => v == null || v.isEmpty ? 'Amount required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          maxLines: 2,
                          onChanged: (v) => description = v,
                          validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                            labelStyle: TextStyle(fontSize: 12.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          onChanged: (v) => reference = v,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: isProcessing.value ? null : () {
                            if (formKey.currentState!.validate()) {
                              transferToRetainedEarnings(
                                amount: amount,
                                description: description,
                                reference: reference,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Transfer', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        )),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  void showAddTransactionDialog() {
    final formKey = GlobalKey<FormState>();
    String transactionType = 'Additional Capital';
    double amount = 0;
    String description = '';
    String reference = ''; 

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 90.w,
          constraints: BoxConstraints(maxHeight: 75.h),
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Equity Transaction', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: transactionType,
                                decoration: InputDecoration(
                                  labelText: 'Transaction Type *',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                                  labelStyle: TextStyle(fontSize: 12.sp, color: kSubText),
                                ),
                                style: TextStyle(fontSize: 14.sp, color: kText),
                                dropdownColor: kCardBg,
                                items: const [
                                  DropdownMenuItem(value: 'Additional Capital', child: Text('Additional Capital')),
                                  DropdownMenuItem(value: 'Drawings', child: Text('Drawings')),
                                  DropdownMenuItem(value: 'Reserve Transfer', child: Text('Reserve Transfer')),
                                ],
                                onChanged: (value) => transactionType = value!,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Amount *',
                                prefixText: CurrencyUtils.prefix,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => amount = double.tryParse(v) ?? 0,
                              validator: (v) => v == null || v.isEmpty ? 'Amount required' : null,
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Description *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              maxLines: 2,
                              onChanged: (v) => description = v,
                              validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Reference Number',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              onChanged: (v) => reference = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: isProcessing.value ? null : () {
                            if (formKey.currentState!.validate()) {
                              if (transactionType == 'Additional Capital') {
                                final capitalAccount = equityAccounts.firstWhereOrNull(
                                  (a) => a.accountType == 'Capital',
                                );
                                if (capitalAccount != null) {
                                  addCapital(
                                    accountId: capitalAccount.id,
                                    amount: amount,
                                    description: description,
                                    reference: reference,
                                  );
                                } else {
                                  _showError('No capital account found');
                                }
                              } else if (transactionType == 'Drawings') {
                                final drawingsAccount = equityAccounts.firstWhereOrNull(
                                  (a) => a.accountType == 'Drawings',
                                );
                                if (drawingsAccount != null) {
                                  recordDrawings(
                                    accountId: drawingsAccount.id,
                                    amount: amount,
                                    description: description,
                                    reference: reference,
                                  );
                                } else {
                                  _showError('No drawings account found');
                                }
                              } else {
                                transferToRetainedEarnings(
                                  amount: amount,
                                  description: description,
                                  reference: reference,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Save Transaction', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                        )),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  void showAccountDetails(EquityAccount account) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: 70.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: _getTypeColor(account.accountType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getTypeIcon(account.accountType), size: 12.w, color: _getTypeColor(account.accountType)),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.accountName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                      Text(account.accountCode, style: TextStyle(fontSize: 12.sp, color: kSubText)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildDetailRow('Account Type', account.accountType),
            _buildDetailRow('Opening Balance', formatAmount(account.openingBalance)),
            _buildDetailRow('Additions', formatAmount(account.additions)),
            _buildDetailRow('Withdrawals', formatAmount(account.withdrawals)),
            _buildDetailRow('Current Balance', formatAmount(account.currentBalance)),
            _buildDetailRow('Last Updated', DateFormat('dd MMM yyyy').format(account.lastUpdated)),
            if (account.notes.isNotEmpty) _buildDetailRow('Notes', account.notes),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
  
  void showTransactionHistory(EquityAccount account) {
    final accountTransactions = transactions.where((t) => t.accountName == account.accountName).toList();
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction History - ${account.accountName}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
            SizedBox(height: 2.h),
            Expanded(
              child: accountTransactions.isEmpty
                  ? Center(child: Text('No transactions found', style: TextStyle(fontSize: 12.sp, color: kSubText)))
                  : ListView.builder(
                      itemCount: accountTransactions.length,
                      itemBuilder: (context, index) {
                        final txn = accountTransactions[index];
                        Color typeColor = txn.type == 'Additional Capital' ? kSuccess :
                                        txn.type == 'Retained Earnings' ? kPrimary :
                                        txn.type == 'Reserve Transfer' ? kWarning : kDanger;
                        return Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10.w, height: 10.w,
                                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(txn.type == 'Additional Capital' ? Icons.add_circle : Icons.remove_circle, size: 5.w, color: typeColor),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(txn.type, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: kText)),
                                    Text(txn.description, style: TextStyle(fontSize: 11.sp, color: kSubText)),
                                    Text('Ref: ${txn.reference}', style: TextStyle(fontSize: 10.sp, color: kSubText)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatAmount(txn.amount), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: typeColor)),
                                  Text(DateFormat('dd MMM yyyy').format(txn.date), style: TextStyle(fontSize: 10.sp, color: kSubText)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Close', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  void calculateEquity() {
    Get.dialog(
      AlertDialog(
        title: Text('Equity Calculator', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalcRow('Total Capital', formatAmount(totalCapital.value), kPrimary),
            _buildCalcRow('Retained Earnings', formatAmount(totalRetainedEarnings.value), kSuccess),
            _buildCalcRow('Reserves', formatAmount(totalReserves.value), kWarning),
            _buildCalcRow('Drawings', formatAmount(totalDrawings.value), kDanger),
            const Divider(),
            _buildCalcRow('Total Equity', formatAmount(totalEquity.value), kPrimary, isBold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Close', style: TextStyle(fontSize: 12.sp))),
        ],
      ),
    );
  }
  
  Widget _buildCalcRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: kSubText)),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: isBold ? FontWeight.w800 : FontWeight.w700, color: color)),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 30.w, child: Text(label, style: TextStyle(fontSize: 12.sp, color: kSubText, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14.sp, color: kText, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Capital': return kPrimary;
      case 'Retained Earnings': return kSuccess;
      case 'Reserves': return kWarning;
      case 'Drawings': return kDanger;
      default: return kSubText;
    }
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Capital': return Icons.account_balance;
      case 'Retained Earnings': return Icons.trending_up;
      case 'Reserves': return Icons.savings;
      case 'Drawings': return Icons.remove_circle;
      default: return Icons.account_balance;
    }
  }
  
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadEquityAccounts();
  }
  
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    equityAccounts.value = allEquityAccounts.value;
    _updateSummaryForFiltered(allEquityAccounts.value);
  }
  
  String formatAmount(double amount) => CurrencyUtils.format(amount);
  

  
  void _showError(String message) {
    AppSnackbar.error(Colors.red, 'Error', message);
  }
}