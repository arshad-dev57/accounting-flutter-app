import 'dart:io';

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/models/equity_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  var isLoadingMore = false.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;
  var serverSupportsPagination = false.obs;

  final List<String> filterOptions = [
    'All',
    'Capital',
    'Retained Earnings',
    'Drawings',
    'Reserves',
  ];

  // Summary data
  var totalCapital = 0.0.obs;
  var totalRetainedEarnings = 0.0.obs;
  var totalReserves = 0.0.obs;
  var totalDrawings = 0.0.obs;
  var totalEquity = 0.0.obs;

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadEquityAccounts(resetPage: true);
    loadTransactions();
    loadSummary();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    loadEquityAccounts(resetPage: true);
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  // ─── LOAD EQUITY ACCOUNTS WITH PAGINATION ──────────────────────────
  Future<void> loadEquityAccounts({bool resetPage = true}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      Map<String, dynamic> params = {};
      params['type'] = 'Equity';

      if (serverSupportsPagination.value) {
        params['page'] = currentPage.value;
        params['limit'] = itemsPerPage.value;
      }

      if (selectedFilter.value != 'All' && selectedFilter.value != 'Equity') {
        params['accountType'] = selectedFilter.value;
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final response = await _apiClient.get(
        '/api/chart-of-accounts',
        queryParameters: params,
      );

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> accountsData = responseData['data'];
          final newAccounts = accountsData
              .map((json) => EquityAccount.fromChartOfAccountsJson(json))
              .toList();

          if (resetPage) {
            allEquityAccounts.value = newAccounts;
            equityAccounts.value = newAccounts;
          } else {
            allEquityAccounts.addAll(newAccounts);
            equityAccounts.addAll(newAccounts);
          }

          // Parse pagination info
          if (responseData['pagination'] != null) {
            final pagination = responseData['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newAccounts.length;
            hasNextPage.value =
                pagination['hasNext'] ??
                pagination['nextPage'] != null ??
                false;
            hasPrevPage.value =
                pagination['hasPrev'] ??
                pagination['prevPage'] != null ??
                false;
            serverSupportsPagination.value = true;
          } else if (responseData['total'] != null) {
            totalPages.value = responseData['pages'] ?? 1;
            totalItems.value = responseData['total'];
            hasNextPage.value = responseData['hasNext'] ?? false;
            hasPrevPage.value = responseData['hasPrev'] ?? false;
            serverSupportsPagination.value = true;
          } else if (responseData['totalCount'] != null) {
            totalItems.value = responseData['totalCount'];
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          } else {
            totalItems.value = equityAccounts.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          _updateSummaryForFiltered(equityAccounts.value);
          equityAccounts.refresh();
        }
      }
    } catch (e) {
      print('Error loading equity accounts: $e');
      _showError('Error loading equity accounts');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── LOAD MORE DATA (LAZY LOADING) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadEquityAccounts(resetPage: false);
    }
  }

  // ─── LOAD TRANSACTIONS ────────────────────────────────────────────
  Future<void> loadTransactions() async {
    try {
      final response = await _apiClient.get('/api/equity/transactions');

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> transactionsData = responseData['data'];
          transactions.value = transactionsData
              .map((json) => OwnerTransaction.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  // ─── LOAD SUMMARY ──────────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      final response = await _apiClient.get('/api/equity/summary');

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          totalCapital.value = (data['totalCapital'] ?? 0).toDouble();
          totalRetainedEarnings.value = (data['totalRetainedEarnings'] ?? 0)
              .toDouble();
          totalReserves.value = (data['totalReserves'] ?? 0).toDouble();
          totalDrawings.value = (data['totalDrawings'] ?? 0).toDouble();
          totalEquity.value = (data['totalEquity'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
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

    totalEquity.value = filteredAccounts.fold(
      0.0,
      (sum, a) => sum + a.currentBalance,
    );
  }

  // ─── SEARCH ──────────────────────────────────────────────────────
  void searchEquity(String query) {
    searchQuery.value = query;
    loadEquityAccounts(resetPage: true);
  }

  // ─── FILTER ──────────────────────────────────────────────────────
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadEquityAccounts(resetPage: true);
  }

  // ─── ADD CAPITAL ──────────────────────────────────────────────────
  Future<void> addCapital({
    required String accountId,
    required double amount,
    required String description,
    required String reference,
  }) async {
    // Show loading dialog
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
                    color: kSuccess,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Adding capital...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
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

      // Close loading dialog
      Get.back();

      if (response.success &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Capital of ${formatAmount(amount)} added successfully',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts(resetPage: true);
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to add capital');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to add capital');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error adding capital: $e');
      _showError('Error adding capital');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── RECORD DRAWINGS ──────────────────────────────────────────────
  Future<void> recordDrawings({
    required String accountId,
    required double amount,
    required String description,
    required String reference,
  }) async {
    // Show loading dialog
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
                    color: kDanger,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Recording drawings...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
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

      // Close loading dialog
      Get.back();

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Drawings of ${formatAmount(amount)} recorded successfully',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts(resetPage: true);
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to record drawings');
        }
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error recording drawings: $e');
      _showError('Error recording drawings');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── TRANSFER TO RETAINED EARNINGS ──────────────────────────────
  Future<void> transferToRetainedEarnings({
    required double amount,
    required String description,
    required String reference,
  }) async {
    // Show loading dialog
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
                  'Processing transfer...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
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

      // Close loading dialog
      Get.back();

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            '${formatAmount(amount)} transferred to retained earnings',
            duration: const Duration(seconds: 3),
          );
          await loadEquityAccounts(resetPage: true);
          await loadTransactions();
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to transfer');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to transfer');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error transferring to retained earnings: $e');
      _showError('Error transferring');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── EXPORT FUNCTIONS ────────────────────────────────────────────
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
            Row(
              children: [
                Text(
                  'Export Equity Report',
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
              '${equityAccounts.length} accounts will be exported',
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
                      exportToExcel();
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
          border: Border.all(color: color.withOpacity(0.3)),
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
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
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
            reportTitle: 'Equity Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfEquityAccountsSection(),
            pw.SizedBox(height: 16),
            _pdfTransactionsSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'equity_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'Equity report exported to PDF');
      await OpenFile.open(file.path);
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
                'Total Capital',
                formatAmount(totalCapital.value),
                accent,
              ),
              _pdfSummaryItem(
                'Retained Earnings',
                formatAmount(totalRetainedEarnings.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Reserves',
                formatAmount(totalReserves.value),
                PdfColors.orange700,
              ),
              _pdfSummaryItem(
                'Drawings',
                formatAmount(totalDrawings.value),
                PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Total Equity',
                formatAmount(totalEquity.value),
                PdfColors.indigo800,
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

  pw.Widget _pdfEquityAccountsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Equity Accounts',
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
                flex: 2,
                child: pw.Text(
                  'Code',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'Account Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Type',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Opening',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Additions',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Withdrawal',
                  textAlign: pw.TextAlign.right,
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
        ...equityAccounts
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
                      flex: 2,
                      child: pw.Text(
                        account.accountCode,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        account.accountName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        account.accountType,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(account.openingBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(account.additions),
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
                        formatAmount(account.withdrawals),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(account.currentBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
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
                flex: 8,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('', textAlign: pw.TextAlign.right),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('', textAlign: pw.TextAlign.right),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('', textAlign: pw.TextAlign.right),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(
                    equityAccounts.fold(
                      0.0,
                      (sum, a) => sum + a.currentBalance,
                    ),
                  ),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTransactionsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction History',
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
                  'Account',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Type',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Date',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Description',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...transactions
            .map(
              (txn) => pw.Container(
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
                        txn.accountName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        txn.type,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: txn.type == 'Additional Capital'
                              ? PdfColors.green700
                              : (txn.type == 'Drawings'
                                    ? PdfColors.red700
                                    : PdfColors.orange700),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(txn.date),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        txn.description,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(txn.amount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: txn.type == 'Additional Capital'
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
      ],
    );
  }

  // ─── EXCEL EXPORT ──────────────────────────────────────────────────
  Future<void> exportToExcel() async {
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

      final excelFile = excel.Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Equity Report',
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
        ['Total Capital', formatAmount(totalCapital.value)],
        ['Retained Earnings', formatAmount(totalRetainedEarnings.value)],
        ['Reserves', formatAmount(totalReserves.value)],
        ['Drawings', formatAmount(totalDrawings.value)],
        ['Total Equity', formatAmount(totalEquity.value)],
        ['Total Accounts', equityAccounts.length.toString()],
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

      // Equity Accounts Sheet
      final accountsSheet = excelFile['Equity Accounts'];
      final accountHeaders = [
        'Account Code',
        'Account Name',
        'Account Type',
        'Opening Balance',
        'Additions',
        'Withdrawals',
        'Current Balance',
        'Last Updated',
        'Notes',
      ];

      for (int i = 0; i < accountHeaders.length; i++) {
        _excelSetCell(
          accountsSheet,
          0,
          i,
          accountHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int row = 1;
      for (final account in equityAccounts) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(accountsSheet, row, 0, account.accountCode, bgColor: bg);
        _excelSetCell(accountsSheet, row, 1, account.accountName, bgColor: bg);
        _excelSetCell(accountsSheet, row, 2, account.accountType, bgColor: bg);
        _excelSetCell(
          accountsSheet,
          row,
          3,
          account.openingBalance,
          bgColor: bg,
        );
        _excelSetCell(
          accountsSheet,
          row,
          4,
          account.additions,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          accountsSheet,
          row,
          5,
          account.withdrawals,
          bgColor: bg,
          fontColor: 'C62828',
        );
        _excelSetCell(
          accountsSheet,
          row,
          6,
          account.currentBalance,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          accountsSheet,
          row,
          7,
          DateFormat('dd MMM yyyy').format(account.lastUpdated),
          bgColor: bg,
        );
        _excelSetCell(
          accountsSheet,
          row,
          8,
          account.notes.isEmpty ? '-' : account.notes,
          bgColor: bg,
        );
        row++;
      }

      final accountColWidths = [
        15.0,
        30.0,
        18.0,
        15.0,
        15.0,
        15.0,
        15.0,
        12.0,
        30.0,
      ];
      for (int i = 0; i < accountColWidths.length; i++) {
        accountsSheet.setColumnWidth(i, accountColWidths[i]);
      }

      // Transactions Sheet
      final transactionsSheet = excelFile['Transactions'];
      final transactionHeaders = [
        'Account Name',
        'Transaction Type',
        'Date',
        'Amount',
        'Description',
        'Reference',
      ];

      for (int i = 0; i < transactionHeaders.length; i++) {
        _excelSetCell(
          transactionsSheet,
          0,
          i,
          transactionHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int txnRow = 1;
      for (final txn in transactions) {
        final bg = txnRow.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(
          transactionsSheet,
          txnRow,
          0,
          txn.accountName,
          bgColor: bg,
        );
        _excelSetCell(
          transactionsSheet,
          txnRow,
          1,
          txn.type,
          bgColor: bg,
          fontColor: txn.type == 'Additional Capital'
              ? '2E7D32'
              : (txn.type == 'Drawings' ? 'C62828' : 'F39C12'),
        );
        _excelSetCell(
          transactionsSheet,
          txnRow,
          2,
          DateFormat('dd MMM yyyy').format(txn.date),
          bgColor: bg,
        );
        _excelSetCell(
          transactionsSheet,
          txnRow,
          3,
          txn.amount,
          bgColor: bg,
          fontColor: txn.type == 'Additional Capital' ? '2E7D32' : 'C62828',
        );
        _excelSetCell(
          transactionsSheet,
          txnRow,
          4,
          txn.description,
          bgColor: bg,
        );
        _excelSetCell(
          transactionsSheet,
          txnRow,
          5,
          txn.reference.isEmpty ? '-' : txn.reference,
          bgColor: bg,
        );
        txnRow++;
      }

      final txnColWidths = [25.0, 18.0, 12.0, 15.0, 35.0, 20.0];
      for (int i = 0; i < txnColWidths.length; i++) {
        transactionsSheet.setColumnWidth(i, txnColWidths[i]);
      }

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'equity_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        'Equity report exported to Excel',
      );
      await OpenFile.open(file.path);
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
      excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
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
      kSuccess,
      'Print',
      'Preparing equity report...',
      duration: const Duration(seconds: 2),
    );
  }

  // ─── SHOW ADD CAPITAL DIALOG ────────────────────────────────────
  void showAddCapitalDialog(EquityAccount account) {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    String reference = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: 420,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kSuccess,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Capital',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                account.accountName,
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isProcessing.value
                              ? null
                              : () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kBgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _detailRow(
                                    'Current Balance',
                                    formatAmount(account.currentBalance),
                                    valueColor: kSuccess,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Amount *',
                              hint: 'Enter capital amount',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  amount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Description *',
                              hint: 'Enter description',
                              onChanged: (v) => description = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference Number',
                              hint: 'e.g., CAP-001',
                              onChanged: (v) => reference = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing.value
                                ? null
                                : () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: isProcessing.value
                                  ? null
                                  : () {
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
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isProcessing.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Add Capital',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── SHOW RECORD DRAWINGS DIALOG ──────────────────────────────────
  void showRecordDrawingsDialog(EquityAccount account) {
    final formKey = GlobalKey<FormState>();
    double amount = 0;
    String description = '';
    String reference = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: 420,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.remove_circle,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Record Drawings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                account.accountName,
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isProcessing.value
                              ? null
                              : () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kBgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _detailRow(
                                    'Current Balance',
                                    formatAmount(account.currentBalance),
                                    valueColor: kDanger,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Amount *',
                              hint: 'Enter drawings amount',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  amount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Description *',
                              hint: 'Enter description',
                              onChanged: (v) => description = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference Number',
                              hint: 'e.g., DRW-001',
                              onChanged: (v) => reference = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing.value
                                ? null
                                : () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: isProcessing.value
                                  ? null
                                  : () {
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
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isProcessing.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Record Drawings',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── SHOW ADD TRANSACTION DIALOG ──────────────────────────────────
  void showAddTransactionDialog() {
    final formKey = GlobalKey<FormState>();
    String transactionType = 'Additional Capital';
    double amount = 0;
    String description = '';
    String reference = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.92,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_task,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Equity Transaction',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record capital, drawings or transfers',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isProcessing.value
                              ? null
                              : () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField(
                              label: 'Transaction Type *',
                              value: transactionType,
                              items: const [
                                'Additional Capital',
                                'Drawings',
                                'Reserve Transfer',
                              ],
                              onChanged: (v) =>
                                  setState(() => transactionType = v!),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Amount *',
                              hint: 'Enter amount',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  amount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Description *',
                              hint: 'Enter description',
                              onChanged: (v) => description = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference Number',
                              hint: 'e.g., REF-001',
                              onChanged: (v) => reference = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing.value
                                ? null
                                : () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: isProcessing.value
                                  ? null
                                  : () {
                                      if (formKey.currentState!.validate()) {
                                        if (transactionType ==
                                            'Additional Capital') {
                                          final capitalAccount = equityAccounts
                                              .firstWhereOrNull(
                                                (a) =>
                                                    a.accountType == 'Capital',
                                              );
                                          if (capitalAccount != null) {
                                            addCapital(
                                              accountId: capitalAccount.id,
                                              amount: amount,
                                              description: description,
                                              reference: reference,
                                            );
                                          } else {
                                            _showError(
                                              'No capital account found',
                                            );
                                          }
                                        } else if (transactionType ==
                                            'Drawings') {
                                          final drawingsAccount = equityAccounts
                                              .firstWhereOrNull(
                                                (a) =>
                                                    a.accountType == 'Drawings',
                                              );
                                          if (drawingsAccount != null) {
                                            recordDrawings(
                                              accountId: drawingsAccount.id,
                                              amount: amount,
                                              description: description,
                                              reference: reference,
                                            );
                                          } else {
                                            _showError(
                                              'No drawings account found',
                                            );
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
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isProcessing.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Save Transaction',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── SHOW ACCOUNT DETAILS ──────────────────────────────────────────
  void showAccountDetails(EquityAccount account) {
    final typeColor = _getTypeColor(account.accountType);

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getTypeIcon(account.accountType),
                              size: 26,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        account.accountName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: kText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        account.accountType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${account.accountCode}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // KPI Cards
                      Row(
                        children: [
                          _miniKpi(
                            'Opening',
                            formatAmount(account.openingBalance),
                            kSubText,
                            Icons.history,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Additions',
                            formatAmount(account.additions),
                            kSuccess,
                            Icons.add_circle,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Withdrawals',
                            formatAmount(account.withdrawals),
                            kDanger,
                            Icons.remove_circle,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Balance',
                            formatAmount(account.currentBalance),
                            typeColor,
                            Icons.account_balance,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Account Type', account.accountType),
                      _detailRow('Account Code', account.accountCode),
                      _detailRow(
                        'Opening Balance',
                        formatAmount(account.openingBalance),
                      ),
                      _detailRow('Additions', formatAmount(account.additions)),
                      _detailRow(
                        'Withdrawals',
                        formatAmount(account.withdrawals),
                      ),
                      _detailRow(
                        'Current Balance',
                        formatAmount(account.currentBalance),
                      ),
                      _detailRow(
                        'Last Updated',
                        DateFormat('dd MMM yyyy').format(account.lastUpdated),
                      ),
                      if (account.notes.isNotEmpty)
                        _detailRow('Notes', account.notes),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: kPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CALCULATE EQUITY ──────────────────────────────────────────────
  void calculateEquity() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Equity Calculator',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kText,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalcRow(
              'Total Capital',
              formatAmount(totalCapital.value),
              kPrimary,
            ),
            const SizedBox(height: 8),
            _buildCalcRow(
              'Retained Earnings',
              formatAmount(totalRetainedEarnings.value),
              kSuccess,
            ),
            const SizedBox(height: 8),
            _buildCalcRow(
              'Reserves',
              formatAmount(totalReserves.value),
              kWarning,
            ),
            const SizedBox(height: 8),
            _buildCalcRow(
              'Drawings',
              formatAmount(totalDrawings.value),
              kDanger,
            ),
            const Divider(),
            _buildCalcRow(
              'Total Equity',
              formatAmount(totalEquity.value),
              kPrimary,
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────────────────────
  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? kText : kSubText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required void Function(String) onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Capital':
        return kPrimary;
      case 'Retained Earnings':
        return kSuccess;
      case 'Reserves':
        return kWarning;
      case 'Drawings':
        return kDanger;
      default:
        return kSubText;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Capital':
        return Icons.account_balance;
      case 'Retained Earnings':
        return Icons.trending_up;
      case 'Reserves':
        return Icons.savings;
      case 'Drawings':
        return Icons.remove_circle;
      default:
        return Icons.account_balance;
    }
  }

  void _showError(String message) {
    AppSnackbar.error(kDanger, 'Error', message);
  }
}
