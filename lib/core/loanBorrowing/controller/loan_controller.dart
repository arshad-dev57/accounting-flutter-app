import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/config/apiconfig.dart';
import 'package:LedgerPro_app/core/loanBorrowing/models/loan_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
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
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  final List<String> filterOptions = ['All', 'Active', 'Fully Paid', 'Overdue', 'Defaulted'];

  var totalLoans = 0.obs;
  var totalPrincipal = 0.0.obs;
  var totalOutstanding = 0.0.obs;
  var totalPaid = 0.0.obs;
  var totalEMI = 0.0.obs;

  TextEditingController searchController = TextEditingController();
  final String baseUrl = Apiconfig().baseUrl;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadLoans();
    loadBankAccounts();
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
      loans.value = allLoans.value;
      _updateSummaryForFiltered(allLoans.value);
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      final results = allLoans.where((loan) {
        return loan.loanNumber.toLowerCase().contains(searchLower) ||
            loan.lenderName.toLowerCase().contains(searchLower) ||
            loan.loanType.toLowerCase().contains(searchLower) ||
            loan.purpose.toLowerCase().contains(searchLower) ||
            loan.accountNumber.toLowerCase().contains(searchLower);
      }).toList();
      loans.value = results;
      _updateSummaryForFiltered(results);
    }
  }

  void _updateSummaryForFiltered(List<Loan> filteredLoans) {
    totalLoans.value = filteredLoans.length;
    totalPrincipal.value = filteredLoans.fold(0.0, (sum, l) => sum + l.loanAmount);
    totalOutstanding.value = filteredLoans.fold(0.0, (sum, l) => sum + l.outstandingBalance);
    totalPaid.value = filteredLoans.fold(0.0, (sum, l) => sum + l.totalPaid);
    totalEMI.value = filteredLoans.fold(0.0, (sum, l) => sum + l.emiAmount);
  }

  // ==================== HELPER: GET TOKEN ====================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ==================== HELPER: GET HEADERS ====================
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== HELPER: FORMAT AMOUNT ====================
  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  Future<void> loadLoans() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {};
      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/loans').replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> loansData = responseData['data'];
          final newLoans = loansData.map((json) => Loan.fromJson(json)).toList();
          allLoans.value = newLoans;

          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            loans.value = newLoans;
          }
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
    }
  }

  // ==================== LOAD BANK ACCOUNTS ====================
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
          bankAccounts.value = List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
  }

  // ==================== LOAD SUMMARY ====================
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

  // ==================== CREATE LOAN ====================
  Future<void> createLoan({
    required String loanType,
    required String lenderName,
    required double loanAmount,
    required DateTime disbursementDate,
    required double interestRate,
    required int tenureMonths,
    required String purpose,
    required String collateral,
    required String accountNumber,
    String? bankAccountId,
    String? notes,
  }) async {
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
        'accountNumber': accountNumber,
        'notes': notes ?? '',
      };

      // ✅ ONLY add bankAccountId if not null and not empty
      if (bankAccountId != null && bankAccountId.isNotEmpty && bankAccountId != 'null') {
        loanData['bankAccountId'] = bankAccountId;
        print('✅ Adding bankAccountId: $bankAccountId');
      } else {
        print('ℹ️ No bank account selected, skipping bankAccountId');
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans'),
        headers: headers,
        body: json.encode(loanData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Get.back();
          AppSnackbar.success(kSuccess, 'Success', 'Loan created successfully\nJournal entry created');
          loadLoans();
          loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to create loan');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to create loan');
      }
    } catch (e) {
      print('Error creating loan: $e');
      _showError('Error creating loan');
    } finally {
      isProcessing.value = false;
    }
  }

  // ==================== RECORD PAYMENT ====================
  Future<void> recordPayment({
    required String loanId,
    required double amount,
    required DateTime paymentDate,
    String? reference,
    String? notes,
    String? type,
  }) async {
    try {
      isProcessing.value = true;

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          Get.back();
          AppSnackbar.success(kSuccess, 'Payment Recorded',
              'Payment of ${formatAmount(amount)} recorded\nPrincipal: ${formatAmount(data['payment']['principal'])}\nInterest: ${formatAmount(data['payment']['interest'])}');
          loadLoans();
          loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to record payment');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to record payment');
      }
    } catch (e) {
      print('Error recording payment: $e');
      _showError('Error recording payment');
    } finally {
      isProcessing.value = false;
    }
  }

  // ==================== PREPAY LOAN ====================
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
        body: json.encode({'loanId': loanId, 'prepaymentAmount': prepaymentAmount}),
      );

      if (calcResponse.statusCode != 200) {
        _showError('Failed to calculate prepayment');
        return;
      }

      final calcData = json.decode(calcResponse.body);
      final prepaymentInfo = calcData['data'];

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Prepayment Confirmation', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prepayment Amount: ${formatAmount(prepaymentAmount)}', style: TextStyle(fontSize: 12.sp)),
              SizedBox(height: 1.h),
              Text('Interest Saved: ${formatAmount(prepaymentInfo['interestSaved'])}', style: TextStyle(fontSize: 12.sp, color: kSuccess)),
              SizedBox(height: 1.h),
              Text('Prepayment Penalty: ${formatAmount(prepaymentInfo['prepaymentPenalty'])}', style: TextStyle(fontSize: 12.sp, color: kWarning)),
              SizedBox(height: 1.h),
              Divider(),
              Text('Net Saving: ${formatAmount(prepaymentInfo['netSaving'])}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: prepaymentInfo['netSaving'] > 0 ? kSuccess : kDanger)),
              SizedBox(height: 2.h),
              Text('Do you want to proceed with prepayment?', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: kWarning),
              child: Text('Prepay', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
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
          AppSnackbar.success(kSuccess, 'Prepayment Successful',
              'Prepayment of ${formatAmount(prepaymentAmount)} recorded\n${responseData['data']['prepayment']['netSaving'] > 0 ? 'Savings' : 'Loss'}: ${formatAmount(responseData['data']['prepayment']['netSaving'].abs())}');
          loadLoans();
          loadSummary();
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

  // ==================== EXPORT FUNCTIONS ====================

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
            Text(
              'Export Loans',
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
            _pdfLoansSection(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'loans_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(kSuccess, 'Success', '${loans.length} loans exported to PDF');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(kSuccess, 'Success', '${loans.length} loans exported to PDF');

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
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Loans Report',
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
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfSummaryItem('Total Loans', totalLoans.value.toString(), PdfColors.indigo700),
          _pdfSummaryItem('Total Principal', _formatAmount(totalPrincipal.value), PdfColors.indigo700),
          _pdfSummaryItem('Total Paid', _formatAmount(totalPaid.value), PdfColors.green700),
          _pdfSummaryItem('Total Outstanding', _formatAmount(totalOutstanding.value), PdfColors.red700),
          _pdfSummaryItem('Total EMI', _formatAmount(totalEMI.value), PdfColors.orange700),
          _pdfSummaryItem('Filter', selectedFilter.value, PdfColors.grey700),
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

  pw.Widget _pdfLoansSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Loan Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
          child: pw.Row(children: [
            pw.Expanded(flex: 2, child: pw.Text('Loan #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Lender', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('EMI', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Paid', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 3, child: pw.Text('Outstanding', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('Status', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ]),
        ),
        ...loans.map((loan) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
          child: pw.Row(children: [
            pw.Expanded(flex: 2, child: pw.Text(loan.loanNumber, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(loan.lenderName, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(loan.loanType, style: pw.TextStyle(fontSize: 9))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loan.loanAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: PdfColors.indigo700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loan.emiAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: PdfColors.orange700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loan.totalPaid), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: PdfColors.green700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loan.outstandingBalance), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, color: loan.outstandingBalance > 0 ? PdfColors.red700 : PdfColors.green700))),
            pw.Expanded(flex: 2, child: pw.Text(loan.status, textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 9, color: loan.status == 'Active' ? PdfColors.orange700 : (loan.status == 'Fully Paid' ? PdfColors.green700 : PdfColors.red700)))),
          ]),
        )).toList(),
        pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(children: [
            pw.Expanded(flex: 6, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loans.fold(0.0, (sum, l) => sum + l.loanAmount)),
                textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loans.fold(0.0, (sum, l) => sum + l.emiAmount)),
                textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loans.fold(0.0, (sum, l) => sum + l.totalPaid)),
                textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green700))),
            pw.Expanded(flex: 2, child: pw.Text(_formatAmount(loans.fold(0.0, (sum, l) => sum + l.outstandingBalance)),
                textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red700))),
          ]),
        ),
      ],
    );
  }

  Future<void> exportToExcel() async {
    try {
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

      final excelFile = excel.Excel.createExcel();

      // Summary Sheet
      final summarySheet = excelFile['Summary'];
      excelFile.setDefaultSheet('Summary');

      _excelSetCell(summarySheet, 0, 0, 'Loans Report',
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
        ['Total Loans', totalLoans.value.toString()],
        ['Total Principal', _formatAmount(totalPrincipal.value)],
        ['Total Paid', _formatAmount(totalPaid.value)],
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
        ['Total EMI (Monthly)', _formatAmount(totalEMI.value)],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(summarySheet, 6 + r, c, summaryRows[r][c],
              bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5');
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // Loans Sheet
      final loansSheet = excelFile['Loans'];
      final headers = [
        'Loan #', 'Lender', 'Loan Type', 'Amount', 'Disbursement Date',
        'Interest Rate (%)', 'Tenure (Months)', 'EMI Amount', 'Total Paid',
        'Outstanding Balance', 'Purpose', 'Collateral', 'Account Number', 'Status', 'Notes'
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(loansSheet, 0, i, headers[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }

      int row = 1;
      for (final loan in loans) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(loansSheet, row, 0, loan.loanNumber, bgColor: bg);
        _excelSetCell(loansSheet, row, 1, loan.lenderName, bgColor: bg);
        _excelSetCell(loansSheet, row, 2, loan.loanType, bgColor: bg);
        _excelSetCell(loansSheet, row, 3, loan.loanAmount, bgColor: bg, fontColor: '1A237E');
        _excelSetCell(loansSheet, row, 4, DateFormat('dd MMM yyyy').format(loan.disbursementDate), bgColor: bg);
        _excelSetCell(loansSheet, row, 5, loan.interestRate, bgColor: bg);
        _excelSetCell(loansSheet, row, 6, loan.tenureMonths, bgColor: bg);
        _excelSetCell(loansSheet, row, 7, loan.emiAmount, bgColor: bg, fontColor: 'F39C12');
        _excelSetCell(loansSheet, row, 8, loan.totalPaid, bgColor: bg, fontColor: '2E7D32');
        _excelSetCell(loansSheet, row, 9, loan.outstandingBalance, bgColor: bg, fontColor: loan.outstandingBalance > 0 ? 'C62828' : '2E7D32');
        _excelSetCell(loansSheet, row, 10, loan.purpose, bgColor: bg);
        _excelSetCell(loansSheet, row, 11, loan.collateral.isEmpty ? '-' : loan.collateral, bgColor: bg);
        _excelSetCell(loansSheet, row, 12, loan.accountNumber, bgColor: bg);
        _excelSetCell(loansSheet, row, 13, loan.status,
            bgColor: loan.status == 'Active' ? 'FFF8E1' : (loan.status == 'Fully Paid' ? 'E8F5E9' : 'FFEBEE'),
            fontColor: loan.status == 'Active' ? 'F39C12' : (loan.status == 'Fully Paid' ? '2E7D32' : 'C62828'));
        _excelSetCell(loansSheet, row, 14, loan.notes.isEmpty ? '-' : loan.notes, bgColor: bg);
        row++;
      }

      // Totals row
      _excelSetCell(loansSheet, row, 3, 'TOTAL', bold: true, bgColor: 'E8EAF6');
      _excelSetCell(loansSheet, row, 7, loans.fold(0.0, (sum, l) => sum + l.emiAmount),
          bold: true, bgColor: 'E8EAF6', fontColor: 'F39C12');
      _excelSetCell(loansSheet, row, 8, loans.fold(0.0, (sum, l) => sum + l.totalPaid),
          bold: true, bgColor: 'E8EAF6', fontColor: '2E7D32');
      _excelSetCell(loansSheet, row, 9, loans.fold(0.0, (sum, l) => sum + l.outstandingBalance),
          bold: true, bgColor: 'E8EAF6', fontColor: 'C62828');

      final colWidths = [15.0, 25.0, 15.0, 15.0, 12.0, 12.0, 12.0, 15.0, 15.0, 15.0, 25.0, 20.0, 18.0, 12.0, 30.0];
      for (int i = 0; i < colWidths.length; i++) {
        loansSheet.setColumnWidth(i, colWidths[i]);
      }

      // Payments History Sheet
      final paymentsSheet = excelFile['Payment History'];
      final paymentHeaders = ['Loan #', 'Lender', 'Date', 'Type', 'Amount', 'Reference', 'Notes'];

      for (int i = 0; i < paymentHeaders.length; i++) {
        _excelSetCell(paymentsSheet, 0, i, paymentHeaders[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }

      int paymentRow = 1;
      for (final loan in loans) {
        for (final payment in loan.payments) {
          final bg = paymentRow.isEven ? 'F5F5F5' : 'FFFFFF';
          _excelSetCell(paymentsSheet, paymentRow, 0, loan.loanNumber, bgColor: bg);
          _excelSetCell(paymentsSheet, paymentRow, 1, loan.lenderName, bgColor: bg);
          _excelSetCell(paymentsSheet, paymentRow, 2, DateFormat('dd MMM yyyy').format(payment.date), bgColor: bg);
          _excelSetCell(paymentsSheet, paymentRow, 3, payment.type, bgColor: bg);
          _excelSetCell(paymentsSheet, paymentRow, 4, payment.amount, bgColor: bg, fontColor: '2E7D32');
          _excelSetCell(paymentsSheet, paymentRow, 5, payment.reference.isEmpty ? '-' : payment.reference, bgColor: bg);
          _excelSetCell(paymentsSheet, paymentRow, 6, payment.notes.isEmpty ? '-' : payment.notes, bgColor: bg);
          paymentRow++;
        }
      }

      final paymentColWidths = [15.0, 25.0, 12.0, 12.0, 15.0, 15.0, 30.0];
      for (int i = 0; i < paymentColWidths.length; i++) {
        paymentsSheet.setColumnWidth(i, paymentColWidths[i]);
      }

      excelFile.delete('Sheet1');

      final bytes = excelFile.save();
      if (bytes == null) throw Exception('Excel save failed');

      final dir = await getTemporaryDirectory();
      final fileName = 'loans_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

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

  void printLoans() {
    AppSnackbar.info('Print', 'Preparing loans report...');
  }

  // ==================== CALCULATE EMI ====================
  Future<void> showEMICalculator() async {
    final formKey = GlobalKey<FormState>();
    double loanAmount = 0;
    double interestRate = 0;
    int tenureMonths = 12;

    await Get.dialog(
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
                  Text('EMI Calculator', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Loan Amount',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => loanAmount = double.tryParse(v) ?? 0,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Interest Rate (%)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => interestRate = double.tryParse(v) ?? 0,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Tenure (months)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => tenureMonths = int.tryParse(v) ?? 12,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Obx(() => ElevatedButton(
                    onPressed: isProcessing.value
                        ? null
                        : () async {
                      if (formKey.currentState!.validate()) {
                        isProcessing.value = true;
                        try {
                          final headers = await _getHeaders();
                          final response = await http.post(
                            Uri.parse('$baseUrl/api/loans/calculate-emi'),
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
                                  title: Text('EMI Calculation Result', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCalcRow('Monthly EMI', formatAmount(result['emi']), kPrimary),
                                      _buildCalcRow('Total Payment', formatAmount(result['totalPayment']), kText),
                                      _buildCalcRow('Total Interest', formatAmount(result['totalInterest']), kWarning),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text('Close', style: TextStyle(fontSize: 12.sp)),
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
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isProcessing.value
                        ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                        : Text('Calculate EMI', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: kSubText)),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ==================== VIEW PAYMENT SCHEDULE ====================
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
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              constraints: BoxConstraints(maxHeight: 85.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Schedule - ${loan.loanNumber}',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText),
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scheduleData.length,
                      itemBuilder: (context, index) {
                        final payment = scheduleData[index];
                        final statusColor = payment['status'] == 'Paid' ? kSuccess :
                        payment['status'] == 'Overdue' ? kDanger : kPrimary;

                        return Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Installment ${payment['installmentNo']}',
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: kText),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      payment['status'],
                                      style: TextStyle(fontSize: 12.sp, color: statusColor, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 0.8.h),
                              Row(
                                children: [
                                  Expanded(child: _buildScheduleDetail('Due Date', DateFormat('dd MMM yyyy').format(DateTime.parse(payment['dueDate'])))),
                                  Expanded(child: _buildScheduleDetail('EMI', formatAmount(payment['emiAmount']))),
                                ],
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  Expanded(child: _buildScheduleDetail('Principal', formatAmount(payment['principal']))),
                                  Expanded(child: _buildScheduleDetail('Interest', formatAmount(payment['interest']))),
                                ],
                              ),
                              _buildScheduleDetail('Ending Balance', formatAmount(payment['endingBalance'])),
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
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: kSubText)),
          Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: kText)),
        ],
      ),
    );
  }

  // ==================== SHOW RECORD PAYMENT DIALOG ====================
  void showRecordPaymentDialog(Loan loan) {
    final formKey = GlobalKey<FormState>();
    double amount = loan.emiAmount;
    DateTime paymentDate = DateTime.now();
    String reference = '';
    String notes = '';

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
                  Text('Record Payment', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Text('Loan: ${loan.loanNumber}', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  Text('Outstanding: ${formatAmount(loan.outstandingBalance)}', style: TextStyle(fontSize: 12.sp, color: kDanger, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: amount.toString(),
                          decoration: InputDecoration(
                            labelText: 'Payment Amount',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => amount = double.tryParse(v) ?? 0,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Amount required';
                            final val = double.tryParse(v);
                            if (val == null) return 'Invalid amount';
                            if (val <= 0) return 'Amount must be greater than 0';
                            if (val > loan.outstandingBalance) return 'Amount exceeds outstanding balance';
                            return null;
                          },
                        ),
                        SizedBox(height: 2.h),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: Get.context!,
                              initialDate: paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => paymentDate = picked);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 5.w, color: kPrimary),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Payment Date', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                                      Text(DateFormat('dd MMM yyyy').format(paymentDate), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: kText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            hintText: 'e.g., TRX-001, CHQ-123',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          onChanged: (v) => reference = v,
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          maxLines: 2,
                          onChanged: (v) => notes = v,
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
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Record Payment', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
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

  // ==================== SHOW PREPAY DIALOG ====================
  void showPrepayDialog(Loan loan) {
    final formKey = GlobalKey<FormState>();
    double prepaymentAmount = loan.outstandingBalance;
    DateTime paymentDate = DateTime.now();
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
                  Text('Prepay Loan', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Text('Loan: ${loan.loanNumber}', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  Text('Outstanding: ${formatAmount(loan.outstandingBalance)}', style: TextStyle(fontSize: 12.sp, color: kDanger, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: prepaymentAmount.toString(),
                          decoration: InputDecoration(
                            labelText: 'Prepayment Amount',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => prepaymentAmount = double.tryParse(v) ?? 0,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Amount required';
                            final val = double.tryParse(v);
                            if (val == null) return 'Invalid amount';
                            if (val <= 0) return 'Amount must be greater than 0';
                            if (val > loan.outstandingBalance) return 'Amount exceeds outstanding balance';
                            return null;
                          },
                        ),
                        SizedBox(height: 2.h),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: Get.context!,
                              initialDate: paymentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => paymentDate = picked);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 5.w, color: kPrimary),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Payment Date', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                                      Text(DateFormat('dd MMM yyyy').format(paymentDate), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: kText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: kCardBg,
                            filled: true,
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
                          onPressed: isProcessing.value
                              ? null
                              : () {
                            if (formKey.currentState!.validate()) {
                              Get.back();
                              prepayLoan(
                                loanId: loan.id,
                                prepaymentAmount: prepaymentAmount,
                                paymentDate: paymentDate,
                                reference: reference,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kWarning,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isProcessing.value
                              ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
                              : Text('Prepay Loan', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
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

  // ==================== SHOW ADD LOAN DIALOG ====================
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
    String accountNumber = '';
    String? selectedBankAccountId;
    String notes = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 90.w,
          constraints: BoxConstraints(maxHeight: 85.h),
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Loan', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            _buildDropdown('Loan Type', loanType, const [
                              'Bank Loan', 'Business Loan', 'Vehicle Loan', 'Personal Loan', 'Overdraft', 'Lease Financing'
                            ], (v) => loanType = v!),
                            SizedBox(height: 2.h),
                            _buildTextField('Lender/Bank Name', (v) => lenderName = v, validator: true),
                            SizedBox(height: 2.h),
                            _buildTextField('Loan Amount', (v) => loanAmount = double.tryParse(v) ?? 0, prefix: CurrencyUtils.prefix, isNumber: true, validator: true),
                            SizedBox(height: 2.h),
                            _buildDatePicker('Disbursement Date', disbursementDate, (date) => disbursementDate = date),
                            SizedBox(height: 2.h),
                            _buildTextField('Interest Rate (%)', (v) => interestRate = double.tryParse(v) ?? 0, isNumber: true, validator: true),
                            SizedBox(height: 2.h),
                            _buildTextField('Tenure (months)', (v) => tenureMonths = int.tryParse(v) ?? 12, isNumber: true, validator: true),
                            SizedBox(height: 2.h),
                            _buildTextField('Purpose', (v) => purpose = v),
                            SizedBox(height: 2.h),
                            _buildTextField('Collateral', (v) => collateral = v),
                            SizedBox(height: 2.h),
                            _buildTextField('Account Number', (v) => accountNumber = v),
                            SizedBox(height: 2.h),
                            Obx(() => _buildBankAccountDropdown(selectedBankAccountId, (v) {
                              selectedBankAccountId = v;
                            })),
                            SizedBox(height: 2.h),
                            _buildTextField('Notes', (v) => notes = v, maxLines: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(child: _buildCancelButton()),
                      SizedBox(width: 3.w),
                      Expanded(child: _buildSubmitButton(formKey, () {
                        createLoan(
                          loanType: loanType,
                          lenderName: lenderName,
                          loanAmount: loanAmount,
                          disbursementDate: disbursementDate,
                          interestRate: interestRate,
                          tenureMonths: tenureMonths,
                          purpose: purpose,
                          collateral: collateral,
                          accountNumber: accountNumber,
                          bankAccountId: selectedBankAccountId,
                          notes: notes,
                        );
                      })),
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

  // ==================== SHOW LOAN DETAILS ====================
  void showLoanDetails(Loan loan) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: 85.h),
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
                    color: getLoanTypeColor(loan.loanType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(getLoanIcon(loan.loanType), size: 7.w, color: getLoanTypeColor(loan.loanType)),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.loanNumber, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: kText)),
                      Text(loan.lenderName, style: TextStyle(fontSize: 12.sp, color: kSubText)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: loan.status == 'Active' ? kPrimary.withOpacity(0.1) :
                    loan.status == 'Fully Paid' ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(loan.status, style: TextStyle(fontSize: 12.sp, color: loan.status == 'Active' ? kPrimary : loan.status == 'Fully Paid' ? kSuccess : kDanger, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildDetailRow('Loan Type', loan.loanType),
            _buildDetailRow('Loan Amount', formatAmount(loan.loanAmount)),
            _buildDetailRow('Disbursement Date', DateFormat('dd MMM yyyy').format(loan.disbursementDate)),
            _buildDetailRow('Interest Rate', '${loan.interestRate.toStringAsFixed(1)}%'),
            _buildDetailRow('Tenure', '${loan.tenureMonths} months'),
            _buildDetailRow('EMI Amount', formatAmount(loan.emiAmount)),
            _buildDetailRow('Total Paid', formatAmount(loan.totalPaid)),
            _buildDetailRow('Outstanding Balance', formatAmount(loan.outstandingBalance)),
            if (loan.nextPaymentDate != null) _buildDetailRow('Next Payment', DateFormat('dd MMM yyyy').format(loan.nextPaymentDate!)),
            if (loan.lastPaymentDate != null) _buildDetailRow('Last Payment', DateFormat('dd MMM yyyy').format(loan.lastPaymentDate!)),
            _buildDetailRow('Purpose', loan.purpose),
            _buildDetailRow('Collateral', loan.collateral.isEmpty ? 'None' : loan.collateral),
            _buildDetailRow('Account Number', loan.accountNumber),
            if (loan.notes.isNotEmpty) _buildDetailRow('Notes', loan.notes),

            SizedBox(height: 2.h),
            Text('Payment History', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: kText)),
            SizedBox(height: 1.h),
            ...loan.payments.map((payment) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(payment.date), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: kText)),
                        Text(payment.type == 'Prepayment' ? 'Prepayment' : 'EMI Payment', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                      ],
                    ),
                  ),
                  Text(formatAmount(payment.amount), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: kSuccess)),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                    decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(payment.status, style: TextStyle(fontSize: 12.sp, color: kSuccess, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )).toList(),

            SizedBox(height: 2.h),
            Row(
              children: [
                if (loan.status == 'Active')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Get.back(); showRecordPaymentDialog(loan); },
                      icon: Icon(Icons.payment, size: 4.5.w),
                      label: Text('Record Payment', style: TextStyle(fontSize: 12.sp)),
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h)),
                    ),
                  ),
                if (loan.status == 'Active') SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Get.back(); viewPaymentSchedule(loan); },
                    icon: Icon(Icons.calendar_view_month, size: 4.5.w),
                    label: Text('Payment Schedule', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildTextField(String label, Function(String) onChanged, {String? prefix, bool isNumber = false, bool validator = false, int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label + (validator ? ' *' : ''),
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: kCardBg,
        filled: true,
        labelStyle: TextStyle(fontSize: 12.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 14.sp, color: kText),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label + ' *',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          labelStyle: TextStyle(fontSize: 12.sp, color: kSubText),
        ),
        style: TextStyle(fontSize: 14.sp, color: kText),
        dropdownColor: kCardBg,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(color: kText)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBankAccountDropdown(String? selectedId, Function(String?) onChanged) {
    if (bankAccounts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: kWarning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, size: 4.w, color: kWarning),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'No bank accounts found. Add a bank account first.',
                style: TextStyle(fontSize: 12.sp, color: kWarning),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedId,
        decoration: InputDecoration(
          labelText: 'Bank Account (Optional)',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          labelStyle: TextStyle(fontSize: 12.sp, color: kSubText),
        ),
        style: TextStyle(fontSize: 14.sp, color: kText),
        dropdownColor: kCardBg,
        items: [
          // ✅ ADD "None" option
          const DropdownMenuItem<String>(
            value: '',
            child: Text(
              'None',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ...bankAccounts.map((account) {
            return DropdownMenuItem<String>(
              value: account['_id'].toString(),
              child: Text(
                '${account['accountName']} • ${account['accountNumber']}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
        ],
        selectedItemBuilder: (context) {
          return [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('None', overflow: TextOverflow.ellipsis),
            ),
            ...bankAccounts.map<Widget>((account) {
              return Text(
                account['accountName'],
                overflow: TextOverflow.ellipsis,
              );
            }).toList(),
          ];
        },
        onChanged: (value) {
          // ✅ If value is empty string, send null
          if (value == '') {
            onChanged(null);
          } else {
            onChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 5.w, color: kPrimary),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label + ' *', style: TextStyle(fontSize: 12.sp, color: kSubText)),
                  Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: kText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: () => Get.back(),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
    );
  }

  Widget _buildSubmitButton(GlobalKey<FormState> formKey, VoidCallback onPressed) {
    return Obx(() => ElevatedButton(
      onPressed: isProcessing.value ? null : () { if (formKey.currentState!.validate()) onPressed(); },
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isProcessing.value
          ? SizedBox(width: 5.w, height: 5.w, child: CircularProgressIndicator(strokeWidth: 2.w, color: Colors.white))
          : Text('Add Loan', style: TextStyle(fontSize: 14.sp, color: Colors.white)),
    ));
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

  Color getLoanTypeColor(String loanType) {
    switch (loanType) {
      case 'Bank Loan': return const Color(0xFF3498DB);
      case 'Business Loan': return const Color(0xFF2ECC71);
      case 'Vehicle Loan': return const Color(0xFFE67E22);
      case 'Personal Loan': return const Color(0xFF9B59B6);
      case 'Overdraft': return const Color(0xFFE74C3C);
      default: return kPrimary;
    }
  }

  IconData getLoanIcon(String loanType) {
    switch (loanType) {
      case 'Bank Loan': return Icons.account_balance;
      case 'Business Loan': return Icons.business;
      case 'Vehicle Loan': return Icons.directions_car;
      case 'Personal Loan': return Icons.person;
      case 'Overdraft': return Icons.credit_card;
      default: return Icons.credit_card;
    }
  }

  // ==================== FILTER METHODS ====================
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    _fetchWithFilters();
  }

  Future<void> _fetchWithFilters() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {};
      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/loans').replace(queryParameters: params);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> loansData = responseData['data'];
          final newLoans = loansData.map((json) => Loan.fromJson(json)).toList();

          allLoans.value = newLoans;

          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            loans.value = newLoans;
          }
        }
      }
    } catch (e) {
      print('Error fetching loans: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterLoans() {
    loadLoans();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadLoans();
  }

  // ==================== HELPER METHODS ====================
  String formatAmount(double amount) => CurrencyUtils.format(amount);

  void _showError(String message) {
    AppSnackbar.error(kWarning, 'Error', message);
  }
}