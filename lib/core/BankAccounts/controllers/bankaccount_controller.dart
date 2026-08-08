import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:BisonsTechs_app/core/GeneralLedger/Screen/general_ledger_screen.dart';
import 'package:BisonsTechs_app/core/Transfer/screen/transfer_screen.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class BankAccountController extends GetxController {
  var bankAccounts = <BankAccount>[].obs;
  var isLoading = true.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;
  var allBankAccounts =
      <BankAccount>[].obs; // Store all accounts for local search

  // Summary totals
  var totalBalance = 0.0.obs;
  var total$ = 0.0.obs;
  var totalUSD = 0.0.obs;
  var activeCount = 0.obs;

  final ApiClient _api = Get.find<ApiClient>();

  // Predefined colors for bank accounts
  final List<Color> _accountColors = [
    const Color(0xFF1AB4F5),
    const Color(0xFFE74C3C),
    const Color(0xFF2ECC71),
    const Color(0xFFF39C12),
    const Color(0xFF9B59B6),
    const Color(0xFF3498DB),
    const Color(0xFFE67E22),
  ];

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color _getColorForAccount(String accountName) {
    int hash = accountName.hashCode;
    return _accountColors[hash.abs() % _accountColors.length];
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  @override
  void onInit() {
    super.onInit();
    fetchBankAccounts();
  }

  Future<void> fetchBankAccounts() async {
    try {
      isLoading(true);

      Map<String, dynamic> params = {};

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      final response = await _api.get(
        '/api/bank-accounts',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true || data['success'] == null) {
          final List<dynamic> accountsData = data['data'] ?? [];

          final accounts = accountsData
              .map(
                (e) => BankAccount.fromJson(
                  e as Map<String, dynamic>,
                  _getColorForAccount((e['accountName'] ?? '').toString()),
                ),
              )
              .toList();

          allBankAccounts.value = accounts;

          if (searchQuery.value.isNotEmpty) {
            searchAccounts(searchQuery.value);
          } else {
            bankAccounts.value = accounts;

            final summary = data['summary'] ?? {};
            // Use API summary if available, otherwise calculate locally
            if (summary.isNotEmpty &&
                summary['totalBalance'] != null &&
                summary['totalBalance'] != 0) {
              totalBalance.value = _toDouble(summary['totalBalance']);
              total$.value = _toDouble(summary['total\$']);
              totalUSD.value = _toDouble(summary['totalUSD']);
              activeCount.value = (summary['activeCount'] ?? 0).toInt();
            } else {
              // Fallback to local calculation
              _updateSummaryTotals();
            }
          }
        }
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to load accounts',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to load bank accounts: $e',
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<bool> createBankAccount(Map<String, dynamic> accountData) async {
    try {
      final response = await _api.post('/api/bank-accounts', body: accountData);

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Bank account added successfully\nJournal entry created for opening balance',
          duration: const Duration(seconds: 3),
        );

        await fetchBankAccounts();
        return true;
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to create account',
          duration: const Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      print('Error creating bank account: $e');
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to create account: $e',
        duration: const Duration(seconds: 2),
      );
      return false;
    }
  }

  Future<void> updateBankAccount(
    String id,
    Map<String, dynamic> accountData,
  ) async {
    try {
      isLoading(true);

      final response = await _api.put(
        '/api/bank-accounts/$id',
        body: accountData,
      );

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Bank account updated successfully',
          duration: const Duration(seconds: 2),
        );

        await fetchBankAccounts();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to update account',
        );
      }
    } catch (e) {
      print('Error updating bank account: $e');
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to update account: $e',
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteBankAccount(String id, String accountName) async {
    try {
      final response = await _api.delete('/api/bank-accounts/$id');

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Bank account "$accountName" deleted successfully',
          duration: const Duration(seconds: 2),
        );
        await fetchBankAccounts();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to delete account',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Error deleting bank account: $e');
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to delete account: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    // API call karo but without search parameter
    _fetchWithFilters();
  }

  // New method to fetch with filters and preserve search
  Future<void> _fetchWithFilters() async {
    try {
      isLoading(true);

      Map<String, dynamic> params = {};

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      final response = await _api.get(
        '/api/bank-accounts',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        if (data['success'] == true || data['success'] == null) {
          final List<dynamic> accountsData = data['data'] ?? [];

          final accounts = accountsData
              .map(
                (e) => BankAccount.fromJson(
                  e as Map<String, dynamic>,
                  _getColorForAccount((e['accountName'] ?? '').toString()),
                ),
              )
              .toList();

          allBankAccounts.value = accounts;

          // Apply local search if any
          if (searchQuery.value.isNotEmpty) {
            searchAccounts(searchQuery.value);
          } else {
            bankAccounts.value = accounts;
          }

          final summary = data['summary'] ?? {};
          // Use API summary if available, otherwise calculate locally
          if (summary.isNotEmpty &&
              summary['totalBalance'] != null &&
              summary['totalBalance'] != 0) {
            totalBalance.value = _toDouble(summary['totalBalance']);
            total$.value = _toDouble(summary['total\$']);
            totalUSD.value = _toDouble(summary['totalUSD']);
            activeCount.value = (summary['activeCount'] ?? 0).toInt();
          } else {
            // Fallback to local calculation
            _updateSummaryTotals();
          }
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      isLoading(false);
    }
  }

  void searchAccounts(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Agar search empty hai to original accounts dikhao
      bankAccounts.value = allBankAccounts.value;
      _updateSummaryTotals(); // Update totals for filtered data
    } else {
      // Local search - koi API call nahi
      final searchLower = query.toLowerCase();
      final results = allBankAccounts.where((account) {
        return account.accountName.toLowerCase().contains(searchLower) ||
            account.accountNumber.toLowerCase().contains(searchLower) ||
            account.bankName.toLowerCase().contains(searchLower) ||
            account.accountType.toLowerCase().contains(searchLower);
      }).toList();
      bankAccounts.value = results;
      _updateSummaryTotalsForFiltered(
        results,
      ); // Update totals for search results
    }
  }

  void _updateSummaryTotals() {
    totalBalance.value = allBankAccounts.fold(
      0.0,
      (sum, acc) => sum + acc.currentBalance,
    );
    total$.value = allBankAccounts
        .where((acc) => acc.currency == '\$')
        .fold(0.0, (sum, acc) => sum + acc.currentBalance);
    totalUSD.value = allBankAccounts
        .where((acc) => acc.currency == 'USD')
        .fold(0.0, (sum, acc) => sum + acc.currentBalance);
    activeCount.value = allBankAccounts
        .where((acc) => acc.status == 'Active')
        .length;
  }

  void _updateSummaryTotalsForFiltered(List<BankAccount> filtered) {
    totalBalance.value = filtered.fold(
      0.0,
      (sum, acc) => sum + acc.currentBalance,
    );
    total$.value = filtered
        .where((acc) => acc.currency == '\$')
        .fold(0.0, (sum, acc) => sum + acc.currentBalance);
    totalUSD.value = filtered
        .where((acc) => acc.currency == 'USD')
        .fold(0.0, (sum, acc) => sum + acc.currentBalance);
    activeCount.value = filtered.where((acc) => acc.status == 'Active').length;
  }

  void syncAccounts() {
    // Manual ledger accounts — no external bank sync in this app.
  }

  void reconcileAccount(BankAccount account) {
    // Bank reconciliation is not used — accounts are manual cash/bank ledgers.
  }

  void viewTransactions(BankAccount account) {
    Get.to(
      () => GeneralLedgerScreen(),
      arguments: {'accountId': account.chartOfAccountId},
    );
  }

  void transferMoney(BankAccount account) {
    Get.to(() => TransferScreen(), arguments: {'fromAccountId': account.id});
  }

  /// Add Money / Deposit into an existing bank account (proper JE on backend).
  Future<bool> depositToBankAccount({
    required String bankAccountId,
    required String sourceAccountId,
    required double amount,
    required DateTime date,
    String? description,
    String? reference,
    String? notes,
  }) async {
    try {
      final body = {
        'amount': amount,
        'sourceAccountId': sourceAccountId,
        'date': date.toIso8601String(),
        if (description != null && description.isNotEmpty)
          'description': description,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _api.post(
        '/api/bank-accounts/$bankAccountId/deposit',
        body: body,
      );

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Deposit posted successfully',
        );
        await fetchBankAccounts();
        return true;
      }

      AppSnackbar.error(
        Colors.red,
        'Error',
        response.message.isNotEmpty
            ? response.message
            : (response.data is Map
                  ? (response.data['message']?.toString() ?? 'Deposit failed')
                  : 'Deposit failed'),
      );
      return false;
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Deposit failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepositSourceAccounts() async {
    try {
      final response = await _api.get(
        '/api/chart-of-accounts',
        queryParameters: {'limit': '200', 'status': 'All'},
      );
      if (!response.success) return [];
      final root = response.data;
      final list = (root is Map ? root['data'] : null);
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((a) {
            final type = (a['type'] ?? '').toString();
            // Suitable credit sources for deposits (not the bank asset itself)
            return type == 'Equity' ||
                type == 'Liability' ||
                type == 'Revenue' ||
                type == 'Asset';
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────── EXPORT FUNCTIONS ───────────────────────

  void exportAccounts() {
    // Show export options bottom sheet
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
              'Export Bank Accounts',
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

      final branding = await PdfBrandingBundle.load();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => branding.buildHeader(
            reportTitle: 'Bank Accounts Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfBankAccountsTable(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'bank_accounts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
          '${bankAccounts.length} accounts exported to PDF',
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
          '${bankAccounts.length} accounts exported to PDF',
          duration: const Duration(seconds: 2),
        );

        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to export PDF: $e',
        duration: const Duration(seconds: 2),
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
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfSummaryItem(
            'Total Balance',
            _formatAmount(totalBalance.value),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            '${CurrencyUtils.code} Balance',
            _formatAmount(total$.value),
            accent,
          ),
          _pdfSummaryItem(
            'USD Balance',
            _formatAmount(totalUSD.value),
            PdfColors.orange700,
          ),
          _pdfSummaryItem(
            'Active Accounts',
            activeCount.value.toString(),
            accent,
          ),
          _pdfSummaryItem(
            'Total Accounts',
            bankAccounts.length.toString(),
            PdfColors.grey700,
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

  pw.Widget _pdfBankAccountsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bank Account Details',
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
                flex: 2,
                child: pw.Text(
                  'Bank',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Account No.',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Currency',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Balance',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...bankAccounts
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
                        account.accountNumber.substring(0, 4),
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
                      flex: 2,
                      child: pw.Text(
                        account.bankName,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        account.accountNumber,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        account.currency,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(account.currentBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: account.currentBalance >= 0
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
                flex: 10,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalBalance.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
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
        'Bank Accounts Report',
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
        ['Total Balance (All Currencies)', _formatAmount(totalBalance.value)],
        ['${CurrencyUtils.code} Balance', _formatAmount(total$.value)],
        ['USD Balance', _formatAmount(totalUSD.value)],
        ['Active Accounts', activeCount.value.toString()],
        ['Total Accounts', bankAccounts.length.toString()],
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

      // Bank Accounts Sheet
      final accountsSheet = excel['Bank Accounts'];
      final headers = [
        'Account Name',
        'Account Number',
        'Bank Name',
        'Branch Code',
        'Account Type',
        'Currency',
        'Opening Balance',
        'Current Balance',
        'Status',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          accountsSheet,
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
      for (final account in bankAccounts) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(accountsSheet, row, 0, account.accountName, bgColor: bg);
        _excelSetCell(
          accountsSheet,
          row,
          1,
          account.accountNumber,
          bgColor: bg,
        );
        _excelSetCell(accountsSheet, row, 2, account.bankName, bgColor: bg);
        _excelSetCell(accountsSheet, row, 3, account.branchCode, bgColor: bg);
        _excelSetCell(accountsSheet, row, 4, account.accountType, bgColor: bg);
        _excelSetCell(accountsSheet, row, 5, account.currency, bgColor: bg);
        _excelSetCell(
          accountsSheet,
          row,
          6,
          account.openingBalance,
          bgColor: bg,
        );
        _excelSetCell(
          accountsSheet,
          row,
          7,
          account.currentBalance,
          bgColor: bg,
        );
        _excelSetCell(
          accountsSheet,
          row,
          8,
          account.status,
          bgColor: account.status == 'Active' ? 'E8F5E9' : 'FFEBEE',
          fontColor: account.status == 'Active' ? '2E7D32' : 'C62828',
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        accountsSheet,
        row,
        6,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        accountsSheet,
        row,
        7,
        totalBalance.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );

      final colWidths = [30.0, 20.0, 25.0, 15.0, 15.0, 10.0, 15.0, 15.0, 12.0];
      for (int i = 0; i < colWidths.length; i++) {
        accountsSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'bank_accounts_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
          Colors.green,
          'Success',
          '${bankAccounts.length} accounts exported to Excel',
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
          '${bankAccounts.length} accounts exported to Excel',
          duration: const Duration(seconds: 2),
        );

        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to export Excel: $e',
        duration: const Duration(seconds: 2),
      );
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
    AppSnackbar.error(
      Colors.red,
      'Session Expired',
      'Please login again',
      duration: const Duration(seconds: 2),
    );
  }
}

class BankAccount {
  final String id;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String branchCode;
  final String accountType;
  final String currency;
  final double openingBalance;
  final double currentBalance;
  final String status;
  final DateTime lastReconciled;
  final Color color;
  final String chartOfAccountId;

  BankAccount({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.branchCode,
    required this.accountType,
    required this.currency,
    required this.openingBalance,
    required this.currentBalance,
    required this.status,
    required this.lastReconciled,
    required this.color,
    this.chartOfAccountId = '',
  });

  factory BankAccount.fromJson(Map<String, dynamic> json, Color color) {
    // Handle chartOfAccountId - it could be a String (ID) or populated Object
    String chartOfAccountId = '';
    if (json['chartOfAccountId'] != null) {
      if (json['chartOfAccountId'] is String) {
        chartOfAccountId = json['chartOfAccountId'];
      } else if (json['chartOfAccountId'] is Map) {
        chartOfAccountId =
            json['chartOfAccountId']['_id'] ??
            json['chartOfAccountId']['id'] ??
            '';
      }
    }

    // Handle lastReconciled
    DateTime lastReconciled;
    if (json['lastReconciled'] != null) {
      if (json['lastReconciled'] is String) {
        lastReconciled = DateTime.parse(json['lastReconciled']);
      } else if (json['lastReconciled'] is DateTime) {
        lastReconciled = json['lastReconciled'];
      } else {
        lastReconciled = DateTime.now();
      }
    } else {
      lastReconciled = DateTime.now();
    }

    return BankAccount(
      id: (json['id'] ?? json['_id']).toString(),
      accountName: json['accountName'].toString(),
      accountNumber: json['accountNumber'].toString(),
      bankName: json['bankName'].toString(),
      branchCode: json['branchCode']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'Current',
      currency: json['currency']?.toString() ?? '\$',
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'Active',
      lastReconciled: lastReconciled,
      color: color,
      chartOfAccountId: chartOfAccountId,
    );
  }
}
