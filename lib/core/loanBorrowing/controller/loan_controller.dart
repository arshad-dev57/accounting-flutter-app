import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'dart:io';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:BisonsTechs_app/core/loanBorrowing/models/loan_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;

class LoanController extends GetxController {
  var allLoans = <Loan>[].obs;
  var loans = <Loan>[].obs;
  var bankAccounts = <Map<String, dynamic>>[].obs;

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
  var loanSaved = false.obs;
  final List<String> filterOptions = [
    'All',
    'Active',
    'Fully Paid',
    'Overdue',
    'Defaulted',
  ];

  var totalLoans = 0.obs;
  var totalPrincipal = 0.0.obs;
  var totalOutstanding = 0.0.obs;
  var totalPaid = 0.0.obs;
  var totalEMI = 0.0.obs;

  // Text editing controller & Scroll controller
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final String baseUrl = Apiconfig().baseUrl;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadLoans(resetPage: true);
    loadBankAccounts();
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
    loadLoans(resetPage: true);
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  // ─── HELPER: GET TOKEN ──────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ─── HELPER: GET HEADERS ──────────────────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── LOAD LOANS WITH PAGINATION ──────────────────────────────────
  Future<void> loadLoans({bool resetPage = true}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      Map<String, dynamic> params = {};

      if (serverSupportsPagination.value) {
        params['page'] = currentPage.value;
        params['limit'] = itemsPerPage.value;
      }

      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      final headers = await _getHeaders();
      final uri = Uri.parse(
        '$baseUrl/api/loans',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> loansData = responseData['data'];
          final newLoans = loansData
              .map((json) => Loan.fromJson(json))
              .toList();

          if (resetPage) {
            allLoans.value = newLoans;
            loans.value = newLoans;
          } else {
            allLoans.addAll(newLoans);
            loans.addAll(newLoans);
          }

          // Parse pagination info
          if (responseData['pagination'] != null) {
            final pagination = responseData['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newLoans.length;
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
            totalItems.value = loans.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          _updateSummaryForFiltered(loans.value);
          loans.refresh();
        } else {
          _showError('Failed to load loans');
        }
      } else {
        _showError('Failed to load loans: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading loans: $e');
      _showError('Error loading loans');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadLoans(resetPage: false);
    }
  }

  // ─── LOAD BANK ACCOUNTS ──────────────────────────────────────────
  Future<void> loadBankAccounts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/bank-accounts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          bankAccounts.value = List<Map<String, dynamic>>.from(
            responseData['data'],
          );
        }
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
  }

  // ─── LOAD SUMMARY ──────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/loans/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          totalLoans.value = data['totalLoans'] ?? 0;
          totalPrincipal.value = (data['totalPrincipal'] ?? 0).toDouble();
          totalOutstanding.value = (data['totalOutstanding'] ?? 0).toDouble();
          totalPaid.value = (data['totalPaid'] ?? 0).toDouble();
          totalEMI.value = (data['totalEMI'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  void _updateSummaryForFiltered(List<Loan> filteredLoans) {
    totalLoans.value = filteredLoans.length;
    totalPrincipal.value = filteredLoans.fold(
      0.0,
      (sum, l) => sum + l.loanAmount,
    );
    totalOutstanding.value = filteredLoans.fold(
      0.0,
      (sum, l) => sum + l.outstandingBalance,
    );
    totalPaid.value = filteredLoans.fold(0.0, (sum, l) => sum + l.totalPaid);
    totalEMI.value = filteredLoans.fold(0.0, (sum, l) => sum + l.emiAmount);
  }

  // ─── SEARCH ──────────────────────────────────────────────────────
  void searchLoans(String query) {
    searchQuery.value = query;
    loadLoans(resetPage: true);
  }

  // ─── FILTER ──────────────────────────────────────────────────────
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadLoans(resetPage: true);
  }

  Future<void> createLoan({
    required String loanType,
    required String lenderName,
    required double loanAmount,
    required DateTime disbursementDate,
    required double interestRate,
    required int tenureMonths,
    required String purpose,
    required String collateral,
    String? bankAccountId,
    String? notes,
  }) async {
    Get.dialog(
      Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                const SizedBox(height: 16),
                Text(
                  'Creating loan...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
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

      final Map<String, dynamic> loanData = {
        'loanType': loanType,
        'lenderName': lenderName,
        'loanAmount': loanAmount,
        'disbursementDate': DateFormat('yyyy-MM-dd').format(disbursementDate),
        'interestRate': interestRate,
        'tenureMonths': tenureMonths,
        'purpose': purpose,
        'collateral': collateral,
        'notes': notes ?? '',
      };

      if (bankAccountId != null &&
          bankAccountId.isNotEmpty &&
          bankAccountId != 'null') {
        loanData['bankAccountId'] = bankAccountId;
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans'),
        headers: headers,
        body: json.encode(loanData),
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) Get.back();

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          await loadLoans(resetPage: true);
          await loadSummary();
          await loadBankAccounts(); // refresh bank balance after disbursement
          loanSaved.value = true; // ✅ signal
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Loan created successfully',
          );
        } else {
          _showError(responseData['message'] ?? 'Failed to create loan');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to create loan');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error creating loan: $e');
      _showError('Error creating loan');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── RECORD PAYMENT ──────────────────────────────────────────────
  Future<void> recordPayment({
    required String loanId,
    required double amount,
    required DateTime paymentDate,
    String? reference,
    String? notes,
    String? type,
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
                  'Recording payment...',
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

      if (loanId.trim().isEmpty) {
        if (Get.isDialogOpen ?? false) Get.back();
        _showError('Loan ID is missing. Please refresh and try again.');
        return;
      }

      final Map<String, dynamic> paymentData = {
        'loanId': loanId,
        'amount': amount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'reference': reference ?? '',
        'notes': notes ?? '',
        'type': type ?? 'EMI',
      };

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans/payment'),
        headers: headers,
        body: json.encode(paymentData),
      );

      // Close loading dialog
      Get.back();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          AppSnackbar.success(
            kSuccess,
            'Payment Recorded ✅',
            'Payment of ${formatAmount(amount)} recorded',
          );
          await loadLoans(resetPage: true);
          await loadSummary();
          await loadBankAccounts(); // refresh bank balance after EMI payment
        } else {
          _showError(responseData['message'] ?? 'Failed to record payment');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to record payment');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error recording payment: $e');
      _showError('Error recording payment');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── PREPAY LOAN ──────────────────────────────────────────────
  Future<void> prepayLoan({
    required String loanId,
    required double prepaymentAmount,
    required DateTime paymentDate,
    String? reference,
  }) async {
    try {
      isProcessing.value = true;

      final calcResponse = await http.post(
        Uri.parse('$baseUrl/api/loans/prepayment/calculate'),
        headers: await _getHeaders(),
        body: json.encode({
          'loanId': loanId,
          'prepaymentAmount': prepaymentAmount,
        }),
      );

      if (calcResponse.statusCode != 200) {
        _showError('Failed to calculate prepayment');
        return;
      }

      final calcData = json.decode(calcResponse.body);
      final prepaymentInfo = calcData['data'];

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text(
            'Prepayment Confirmation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prepayment Amount: ${formatAmount(prepaymentAmount)}',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                'Interest Saved: ${formatAmount(prepaymentInfo['interestSaved'])}',
                style: TextStyle(fontSize: 13, color: kSuccess),
              ),
              SizedBox(height: 8),
              Text(
                'Prepayment Penalty: ${formatAmount(prepaymentInfo['prepaymentPenalty'])}',
                style: TextStyle(fontSize: 13, color: kWarning),
              ),
              SizedBox(height: 8),
              Divider(),
              Text(
                'Net Saving: ${formatAmount(prepaymentInfo['netSaving'])}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: prepaymentInfo['netSaving'] > 0 ? kSuccess : kDanger,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Do you want to proceed with prepayment?',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: kWarning),
              child: const Text('Prepay'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final prepayData = {
        'loanId': loanId,
        'prepaymentAmount': prepaymentAmount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'reference': reference ?? '',
      };

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans/prepayment'),
        headers: headers,
        body: json.encode(prepayData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Get.back();
          AppSnackbar.success(
            kSuccess,
            'Prepayment Successful ✅',
            'Prepayment of ${formatAmount(prepaymentAmount)} recorded',
          );
          await loadLoans(resetPage: true);
          await loadSummary();
          await loadBankAccounts();
        } else {
          _showError(responseData['message'] ?? 'Failed to process prepayment');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to process prepayment');
      }
    } catch (e) {
      print('Error prepaying loan: $e');
      _showError('Error prepaying loan');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── EXPORT FUNCTIONS ────────────────────────────────────────────
  void exportLoans() {
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
                  'Export Loans',
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
              '${loans.length} loans will be exported',
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
            reportTitle: 'Loans Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfLoansSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'loans_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${loans.length} loans exported to PDF',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
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
            'Total Loans',
            totalLoans.value.toString(),
            accent,
          ),
          _pdfSummaryItem(
            'Total Principal',
            formatAmount(totalPrincipal.value),
            accent,
          ),
          _pdfSummaryItem(
            'Total Paid',
            formatAmount(totalPaid.value),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            'Total Outstanding',
            formatAmount(totalOutstanding.value),
            PdfColors.red700,
          ),
          _pdfSummaryItem(
            'Total EMI',
            formatAmount(totalEMI.value),
            PdfColors.orange700,
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

  pw.Widget _pdfLoansSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Loan Details',
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
                  'Loan #',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Lender',
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
                  'Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'EMI',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Paid',
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
                flex: 2,
                child: pw.Text(
                  'Status',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...loans
            .map(
              (loan) => pw.Container(
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
                        loan.loanNumber,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loan.lenderName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loan.loanType,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(loan.loanAmount),
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
                        formatAmount(loan.emiAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.orange700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(loan.totalPaid),
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
                        formatAmount(loan.outstandingBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: loan.outstandingBalance > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        loan.status,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: loan.status == 'Active'
                              ? PdfColors.orange700
                              : (loan.status == 'Fully Paid'
                                    ? PdfColors.green700
                                    : PdfColors.red700),
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
                flex: 6,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(loans.fold(0.0, (sum, l) => sum + l.loanAmount)),
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
                  formatAmount(loans.fold(0.0, (sum, l) => sum + l.emiAmount)),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  formatAmount(loans.fold(0.0, (sum, l) => sum + l.totalPaid)),
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
                  formatAmount(
                    loans.fold(0.0, (sum, l) => sum + l.outstandingBalance),
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
        'Loans Report',
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
        5,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Loans', totalLoans.value.toString()],
        ['Total Principal', formatAmount(totalPrincipal.value)],
        ['Total Paid', formatAmount(totalPaid.value)],
        ['Total Outstanding', formatAmount(totalOutstanding.value)],
        ['Total EMI (Monthly)', formatAmount(totalEMI.value)],
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

      // Loans Sheet
      final loansSheet = excelFile['Loans'];
      final headers = [
        'Loan #',
        'Lender',
        'Loan Type',
        'Amount',
        'Disbursement Date',
        'Interest Rate (%)',
        'Tenure (Months)',
        'EMI Amount',
        'Total Paid',
        'Outstanding Balance',
        'Purpose',
        'Collateral',
        'Status',
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          loansSheet,
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
      for (final loan in loans) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(loansSheet, row, 0, loan.loanNumber, bgColor: bg);
        _excelSetCell(loansSheet, row, 1, loan.lenderName, bgColor: bg);
        _excelSetCell(loansSheet, row, 2, loan.loanType, bgColor: bg);
        _excelSetCell(
          loansSheet,
          row,
          3,
          loan.loanAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          loansSheet,
          row,
          4,
          DateFormat('dd MMM yyyy').format(loan.disbursementDate),
          bgColor: bg,
        );
        _excelSetCell(loansSheet, row, 5, loan.interestRate, bgColor: bg);
        _excelSetCell(loansSheet, row, 6, loan.tenureMonths, bgColor: bg);
        _excelSetCell(
          loansSheet,
          row,
          7,
          loan.emiAmount,
          bgColor: bg,
          fontColor: 'F39C12',
        );
        _excelSetCell(
          loansSheet,
          row,
          8,
          loan.totalPaid,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          loansSheet,
          row,
          9,
          loan.outstandingBalance,
          bgColor: bg,
          fontColor: loan.outstandingBalance > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(loansSheet, row, 10, loan.purpose, bgColor: bg);
        _excelSetCell(
          loansSheet,
          row,
          11,
          loan.collateral.isEmpty ? '-' : loan.collateral,
          bgColor: bg,
        );
        _excelSetCell(
          loansSheet,
          row,
          12,
          loan.status,
          bgColor: loan.status == 'Active'
              ? 'FFF8E1'
              : (loan.status == 'Fully Paid' ? 'E8F5E9' : 'FFEBEE'),
          fontColor: loan.status == 'Active'
              ? 'F39C12'
              : (loan.status == 'Fully Paid' ? '2E7D32' : 'C62828'),
        );
        _excelSetCell(
          loansSheet,
          row,
          13,
          loan.notes.isEmpty ? '-' : loan.notes,
          bgColor: bg,
        );
        row++;
      }

      // Totals row
      _excelSetCell(loansSheet, row, 3, 'TOTAL', bold: true, bgColor: 'E8EAF6');
      _excelSetCell(
        loansSheet,
        row,
        7,
        loans.fold(0.0, (sum, l) => sum + l.emiAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'F39C12',
      );
      _excelSetCell(
        loansSheet,
        row,
        8,
        loans.fold(0.0, (sum, l) => sum + l.totalPaid),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        loansSheet,
        row,
        9,
        loans.fold(0.0, (sum, l) => sum + l.outstandingBalance),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [
        15.0,
        25.0,
        15.0,
        15.0,
        12.0,
        12.0,
        12.0,
        15.0,
        15.0,
        15.0,
        25.0,
        20.0,
        12.0,
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        loansSheet.setColumnWidth(i, colWidths[i]);
      }

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName =
          'loans_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(
        kSuccess,
        'Success',
        '${loans.length} loans exported to Excel',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export Excel: $e');
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

  // ─── SHOW EMI CALCULATOR ──────────────────────────────────────────
  Future<void> showEMICalculator() async {
    final formKey = GlobalKey<FormState>();
    double loanAmount = 0;
    double interestRate = 0;
    int tenureMonths = 12;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            Icons.calculate,
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
                                'EMI Calculator',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Calculate your monthly EMI',
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
                            _buildTextField(
                              label: 'Loan Amount *',
                              hint: 'Enter loan amount',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  loanAmount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Interest Rate (%) *',
                              hint: 'Enter annual interest rate',
                              onChanged: (v) =>
                                  interestRate = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Tenure (months) *',
                              hint: 'Enter loan tenure in months',
                              onChanged: (v) =>
                                  tenureMonths = int.tryParse(v) ?? 12,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
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
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: isProcessing.value
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  isProcessing.value = true;
                                  try {
                                    final headers = await _getHeaders();
                                    final response = await http.post(
                                      Uri.parse(
                                        '$baseUrl/api/loans/calculate-emi',
                                      ),
                                      headers: headers,
                                      body: json.encode({
                                        'loanAmount': loanAmount,
                                        'interestRate': interestRate,
                                        'tenureMonths': tenureMonths,
                                      }),
                                    );

                                    if (response.statusCode == 200) {
                                      final data = json.decode(response.body);
                                      if (data['success']) {
                                        final result = data['data'];
                                        Get.back();
                                        Get.dialog(
                                          AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              'EMI Calculation Result',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: kText,
                                              ),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildCalcRow(
                                                  'Monthly EMI',
                                                  formatAmount(result['emi']),
                                                  kPrimary,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildCalcRow(
                                                  'Total Payment',
                                                  formatAmount(
                                                    result['totalPayment'],
                                                  ),
                                                  kText,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildCalcRow(
                                                  'Total Interest',
                                                  formatAmount(
                                                    result['totalInterest'],
                                                  ),
                                                  kWarning,
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Get.back(),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    isProcessing.value = false;
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                'Calculate EMI',
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: kSubText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── VIEW PAYMENT SCHEDULE ──────────────────────────────────────────
  Future<void> viewPaymentSchedule(Loan loan) async {
    try {
      isProcessing.value = true;

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/loans/${loan.id}/schedule'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> scheduleData = responseData['data'];

          Get.bottomSheet(
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              constraints: BoxConstraints(maxHeight: Get.height * 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_view_month,
                          size: 22,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loan.loanNumber,
                              style: TextStyle(fontSize: 12, color: kSubText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scheduleData.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final payment = scheduleData[index];
                        final statusColor = payment['status'] == 'Paid'
                            ? kSuccess
                            : payment['status'] == 'Overdue'
                            ? kDanger
                            : kPrimary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kBgLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Installment ${payment['installmentNo']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: kText,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      payment['status'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildScheduleDetail(
                                      'Due Date',
                                      DateFormat('dd MMM yyyy').format(
                                        DateTime.parse(payment['dueDate']),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildScheduleDetail(
                                      'EMI',
                                      formatAmount(payment['emiAmount']),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildScheduleDetail(
                                      'Principal',
                                      formatAmount(payment['principal']),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildScheduleDetail(
                                      'Interest',
                                      formatAmount(payment['interest']),
                                    ),
                                  ),
                                ],
                              ),
                              _buildScheduleDetail(
                                'Ending Balance',
                                formatAmount(payment['endingBalance']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading payment schedule: $e');
      _showError('Error loading payment schedule');
    } finally {
      isProcessing.value = false;
    }
  }

  Widget _buildScheduleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHOW RECORD PAYMENT DIALOG ──────────────────────────────────
  void showRecordPaymentDialog(Loan loan) {
    final formKey = GlobalKey<FormState>();
    double amount = loan.emiAmount;
    DateTime paymentDate = DateTime.now();
    String reference = '';
    String notes = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.85,
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
                            Icons.payment,
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
                                'Record Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loan.loanNumber,
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
                            // Loan Summary
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
                                  _detailRow('Lender', loan.lenderName),
                                  _detailRow(
                                    'Outstanding',
                                    formatAmount(loan.outstandingBalance),
                                    valueColor: kDanger,
                                  ),
                                  _detailRow(
                                    'Monthly EMI',
                                    formatAmount(loan.emiAmount),
                                    valueColor: kWarning,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Payment Amount *',
                              hint: loan.emiAmount.toString(),
                              prefixText: CurrencyUtils.prefix,
                              initialValue: amount.toString(),
                              onChanged: (v) =>
                                  amount = double.tryParse(v) ?? 0,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Amount required';
                                final val = double.tryParse(v);
                                if (val == null) return 'Invalid amount';
                                if (val <= 0)
                                  return 'Amount must be greater than 0';
                                if (val > loan.outstandingBalance)
                                  return 'Amount exceeds outstanding balance';
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildDatePickerField(
                              'Payment Date *',
                              paymentDate,
                              (d) => setState(() => paymentDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference Number',
                              hint: 'e.g., TRX-001, CHQ-123',
                              onChanged: (v) => reference = v,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Notes',
                              hint: 'Additional notes',
                              onChanged: (v) => notes = v,
                              maxLines: 2,
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
                                        Get.back();
                                        recordPayment(
                                          loanId: loan.id,
                                          amount: amount,
                                          paymentDate: paymentDate,
                                          reference: reference,
                                          notes: notes,
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
                                      'Record Payment',
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

  void showAddLoanDialog() {
    final formKey = GlobalKey<FormState>();
    String loanType = 'Bank Loan';
    String lenderName = '';
    double loanAmount = 0;
    DateTime disbursementDate = DateTime.now();
    double interestRate = 0;
    int tenureMonths = 12;
    String purpose = '';
    String collateral = '';
    String? selectedBankAccountId;
    String notes = '';

    loanSaved.value = false; // reset

    final worker = ever(loanSaved, (bool saved) {
      if (saved) {
        if (Get.isDialogOpen ?? false) Get.back();
      }
    });

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
                            Icons.credit_card,
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
                                'Add New Loan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record a new loan or borrowing',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isProcessing.value
                              ? null
                              : () {
                                  worker.dispose(); // ✅
                                  Get.back();
                                },
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
                              label: 'Loan Type *',
                              value: loanType,
                              items: const [
                                'Bank Loan',
                                'Business Loan',
                                'Vehicle Loan',
                                'Personal Loan',
                                'Overdraft',
                                'Lease Financing',
                              ],
                              onChanged: (v) => setState(() => loanType = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Lender/Bank Name *',
                              hint: 'Enter lender name',
                              onChanged: (v) => lenderName = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Loan Amount *',
                              hint: 'Enter loan amount',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  loanAmount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              'Disbursement Date *',
                              disbursementDate,
                              (d) => setState(() => disbursementDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Interest Rate (%) *',
                              hint: 'Enter annual interest rate',
                              onChanged: (v) =>
                                  interestRate = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Tenure (months) *',
                              hint: 'Enter loan tenure in months',
                              onChanged: (v) =>
                                  tenureMonths = int.tryParse(v) ?? 12,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Purpose',
                              hint: 'Purpose of loan',
                              onChanged: (v) => purpose = v,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Collateral',
                              hint: 'Collateral/security provided',
                              onChanged: (v) => collateral = v,
                            ),
                            const SizedBox(height: 16),
                            _buildBankAccountDropdown(
                              selectedBankAccountId,
                              (v) => setState(() => selectedBankAccountId = v),
                              bankAccounts.toList(),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Notes',
                              hint: 'Additional notes',
                              onChanged: (v) => notes = v,
                              maxLines: 2,
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
                                : () {
                                    worker.dispose(); // ✅
                                    Get.back();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
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
                                        createLoan(
                                          loanType: loanType,
                                          lenderName: lenderName,
                                          loanAmount: loanAmount,
                                          disbursementDate: disbursementDate,
                                          interestRate: interestRate,
                                          tenureMonths: tenureMonths,
                                          purpose: purpose,
                                          collateral: collateral,
                                          bankAccountId: selectedBankAccountId,
                                          notes: notes,
                                        );
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
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Add Loan',
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
      barrierDismissible: false,
    ).then((_) => worker.dispose()); // ✅ cleanup
  }

  void showLoanDetails(Loan loan) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                              color: getLoanTypeColor(
                                loan.loanType,
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              getLoanIcon(loan.loanType),
                              size: 26,
                              color: getLoanTypeColor(loan.loanType),
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
                                        loan.loanNumber,
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
                                        color: loan.status == 'Active'
                                            ? kPrimary.withOpacity(0.08)
                                            : loan.status == 'Fully Paid'
                                            ? kSuccess.withOpacity(0.08)
                                            : kDanger.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        loan.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: loan.status == 'Active'
                                              ? kPrimary
                                              : loan.status == 'Fully Paid'
                                              ? kSuccess
                                              : kDanger,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${loan.loanType}',
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
                            'Amount',
                            formatAmount(loan.loanAmount),
                            kPrimary,
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'EMI',
                            formatAmount(loan.emiAmount),
                            kWarning,
                            Icons.calendar_month,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Outstanding',
                            formatAmount(loan.outstandingBalance),
                            kDanger,
                            Icons.payment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Lender', loan.lenderName),
                      _detailRow('Loan Type', loan.loanType),
                      _detailRow(
                        'Disbursement Date',
                        DateFormat('dd MMM yyyy').format(loan.disbursementDate),
                      ),
                      _detailRow(
                        'Interest Rate',
                        '${loan.interestRate.toStringAsFixed(1)}%',
                      ),
                      _detailRow('Tenure', '${loan.tenureMonths} months'),
                      _detailRow('Total Paid', formatAmount(loan.totalPaid)),
                      if (loan.nextPaymentDate != null)
                        _detailRow(
                          'Next Payment',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(loan.nextPaymentDate!),
                        ),
                      if (loan.lastPaymentDate != null)
                        _detailRow(
                          'Last Payment',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(loan.lastPaymentDate!),
                        ),
                      _detailRow('Purpose', loan.purpose),
                      _detailRow(
                        'Collateral',
                        loan.collateral.isEmpty ? 'None' : loan.collateral,
                      ),
                      if (loan.notes.isNotEmpty)
                        _detailRow('Notes', loan.notes),

                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Payment History
                      if (loan.payments.isNotEmpty) ...[
                        Text(
                          'Payment History',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...loan.payments
                            .map(
                              (payment) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kBgLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(payment.date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: kText,
                                            ),
                                          ),
                                          Text(
                                            payment.type == 'Prepayment'
                                                ? 'Prepayment'
                                                : 'EMI Payment',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: kSubText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatAmount(payment.amount),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kSuccess,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kSuccess.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        payment.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: kSuccess,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: Colors.grey.withOpacity(0.12),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Footer Buttons
                      Row(
                        children: [
                          if (loan.status == 'Active') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showRecordPaymentDialog(loan);
                                  },
                                  icon: const Icon(
                                    Icons.payment,
                                    size: 16,
                                    color: kSuccess,
                                  ),
                                  label: Text(
                                    'Pay EMI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: kSuccess,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: kSuccess),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  viewPaymentSchedule(loan);
                                },
                                icon: Icon(
                                  Icons.calendar_view_month,
                                  size: 16,
                                  color: kPrimary,
                                ),
                                label: Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required void Function(String) onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    String? initialValue,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
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

  Widget _buildBankAccountDropdown(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> bankAccounts,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Disbursement Bank Account',
        helperText: 'Loan amount will be credited to this account',
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      dropdownColor: kCardBg,
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('None')),
        ...bankAccounts.map((account) {
          return DropdownMenuItem<String>(
            value: (account['_id'] ?? account['id']).toString(),
            child: Text(
              '${account['accountName']} • ${account['accountNumber']}',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        // If value is empty string, send null
        if (value == '') {
          onChanged(null);
        } else {
          onChanged(value);
        }
      },
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    void Function(DateTime) onChanged,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: kSubText),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────
  Color getLoanTypeColor(String loanType) {
    switch (loanType) {
      case 'Bank Loan':
        return const Color(0xFF3498DB);
      case 'Business Loan':
        return const Color(0xFF2ECC71);
      case 'Vehicle Loan':
        return const Color(0xFFE67E22);
      case 'Personal Loan':
        return const Color(0xFF9B59B6);
      case 'Overdraft':
        return const Color(0xFFE74C3C);
      default:
        return kPrimary;
    }
  }

  IconData getLoanIcon(String loanType) {
    switch (loanType) {
      case 'Bank Loan':
        return Icons.account_balance;
      case 'Business Loan':
        return Icons.business;
      case 'Vehicle Loan':
        return Icons.directions_car;
      case 'Personal Loan':
        return Icons.person;
      case 'Overdraft':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  void _showError(String message) {
    AppSnackbar.error(kWarning, 'Error', message);
  }
}
