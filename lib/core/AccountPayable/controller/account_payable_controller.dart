// core/AccountsPayable/controllers/accounts_payable_controller.dart

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class AccountsPayableController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // ✅ Changed: vendors → suppliers (using Supplier from warehouse)
  var suppliers = <Supplier>[].obs;
  var bills = <Bill>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var selectedSupplierId = ''.obs;  // ✅ Changed: selectedVendorId → selectedSupplierId
  var startDate = Rx<DateTime?>(null);
  var endDate = Rx<DateTime?>(null);

  var bankAccounts = <Map<String, dynamic>>[].obs;

  var totalOutstanding = 0.0.obs;
  var totalOverdue = 0.0.obs;
  var totalDueThisWeek = 0.0.obs;
  var totalDueThisMonth = 0.0.obs;
  var activeSuppliers = 0.obs;  // ✅ Changed: activeVendors → activeSuppliers

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatAmount(double amount) {
    return CurrencyUtils.format(amount);
  }

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    fetchBankAccounts();
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchSuppliers(), fetchBills(), fetchSummary()]);
  }

  // ─── ✅ FIXED: Fetch Suppliers from Warehouse ────────────────────
  Future<void> fetchSuppliers() async {
    try {
      final response = await _apiClient.get('/api/accounts-payable/suppliers');

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          suppliers.value = (data['data'] as List)
              .map((e) => Supplier.fromJson(e))
              .toList();
          print('✅ Loaded ${suppliers.length} suppliers from warehouse');
        }
      }
    } catch (e) {
      print('❌ Error fetching suppliers: $e');
    }
  }

  Future<void> fetchSummary() async {
    try {
      final response = await _apiClient.get('/api/accounts-payable/summary');

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          totalOutstanding.value = _toDouble(data['data']['totalOutstanding']);
          totalOverdue.value = _toDouble(data['data']['overdue']);
          totalDueThisWeek.value = _toDouble(data['data']['dueThisWeek']);
          totalDueThisMonth.value = _toDouble(data['data']['dueThisMonth']);
          activeSuppliers.value = data['data']['activeSuppliers'] ?? 0;  // ✅ Changed
        }
      }
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  // ─── ✅ FIXED: Fetch Bills with supplier filter ──────────────────
  Future<void> fetchBills() async {
    try {
      isLoading(true);

      String endpoint = '/api/accounts-payable/bills';
      Map<String, dynamic> queryParams = {};

      if (selectedFilter.value != 'All') {
        queryParams['status'] = selectedFilter.value;
      }

      // ✅ Changed: vendorId → supplierId
      if (selectedSupplierId.value.isNotEmpty) {
        queryParams['supplierId'] = selectedSupplierId.value;
      }

      if (startDate.value != null) {
        queryParams['startDate'] = startDate.value!.toIso8601String();
      }

      if (endDate.value != null) {
        queryParams['endDate'] = endDate.value!.toIso8601String();
      }

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          bills.value = (data['data'] as List)
              .map((e) => Bill.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching bills: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBankAccounts() async {
    try {
      final response = await _apiClient.get('/api/bank-accounts');

      if (response.success && response.statusCode == 200) {
        final data = response.data;
        if (data['success'] ?? true) {
          bankAccounts.value = List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
    }
  }

  // ─── ✅ FIXED: Create Bill with supplierId ──────────────────────
  Future<void> createBill(Map<String, dynamic> billData) async {
    try {
      isProcessing(true);

      // ✅ Ensure supplierId is used instead of vendorId
      final payload = {
        'supplierId': billData['supplierId'],  // ✅ Changed
        'date': billData['date'],
        'dueDate': billData['dueDate'],
        'items': billData['items'],
        'discount': billData['discount'] ?? 0,
        'notes': billData['notes'] ?? '',
      };

      final response = await _apiClient.post(
        '/api/accounts-payable/bills',
        body: payload,
      );

      if (response.success && response.statusCode == 201) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Bill created successfully!\nJournal entry created',
          duration: const Duration(seconds: 3),
        );
        await fetchBills();
        await fetchSummary();
        await fetchSuppliers();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to create bill';
        AppSnackbar.error(Colors.red, 'Error', errorMsg);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to create bill: $e');
    } finally {
      isProcessing(false);
    }
  }

  // ─── ✅ FIXED: Record Payment with supplierId ──────────────────
  Future<void> recordPayment({
    required String supplierId,  // ✅ Changed: vendorId → supplierId
    required String billId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String reference,
    required String? bankAccountId,
    String notes = '',
  }) async {
    try {
      isProcessing(true);

      final body = {
        'supplierId': supplierId,  // ✅ Changed
        'billId': billId,
        'amount': amount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'bankAccountId': bankAccountId,
        'notes': notes,
      };

      // ✅ FIXED: Correct endpoint
      final response = await _apiClient.post(
        '/api/accounts-payable/payments',  // ✅ Fixed endpoint
        body: body,
      );

      if (response.success && (response.statusCode == 201 || response.statusCode == 200)) {
        AppSnackbar.success(
          Colors.green,
          'Success',
          'Payment recorded successfully!\nJournal entry created',
          duration: const Duration(seconds: 3),
        );
        await fetchBills();
        await fetchSummary();
        await fetchSuppliers();
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to record payment';
        AppSnackbar.error(Colors.red, 'Error', errorMsg);
      }
    } catch (e) {
      AppSnackbar.error(Colors.red, 'Error', 'Failed to record payment: $e');
    } finally {
      isProcessing(false);
    }
  }

  // ─── Filter Methods ──────────────────────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchBills();
  }

  // ✅ Changed: filterByVendor → filterBySupplier
  void filterBySupplier(String supplierId) {
    selectedSupplierId.value = supplierId;
    fetchBills();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    fetchBills();
  }

  void clearFilters() {
    selectedFilter.value = 'All';
    selectedSupplierId.value = '';
    startDate.value = null;
    endDate.value = null;
    fetchBills();
  }

  Bill? getBillById(String id) {
    try {
      return bills.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // ✅ Changed: getUnpaidBillsForVendor → getUnpaidBillsForSupplier
  List<Bill> getUnpaidBillsForSupplier(String supplierId) {
    return bills
        .where((b) => b.supplierId == supplierId && b.status != 'Paid')
        .toList();
  }

  // ✅ Changed: getSupplierName
  String getSupplierName(String supplierId) {
    try {
      final supplier = suppliers.firstWhere((s) => s.id == supplierId);
      return supplier.name;
    } catch (e) {
      return 'Unknown Supplier';
    }
  }

  // ─── Get Display Suppliers ──────────────────────────────────────
  List<Supplier> get displaySuppliers {
    return suppliers;
  }

  // ─── Export Functions (Same as before, just updated variable names) ──
  void exportReport() {
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
              'Export Accounts Payable',
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

  // ─── PDF Export (Updated to use suppliers) ──────────────────────
  Future<void> exportToPdf() async {
    try {
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
            _pdfSuppliersSection(),
            pw.SizedBox(height: 16),
            _pdfBillsSection(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'accounts_payable_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
          '${bills.length} bills exported to PDF',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${bills.length} bills exported to PDF',
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
                'Accounts Payable Report',
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
                'Total Outstanding',
                _formatAmount(totalOutstanding.value),
                PdfColors.red700,
              ),
              _pdfSummaryItem(
                'Overdue',
                _formatAmount(totalOverdue.value),
                PdfColors.orange700,
              ),
              _pdfSummaryItem(
                'Due This Week',
                _formatAmount(totalDueThisWeek.value),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Due This Month',
                _formatAmount(totalDueThisMonth.value),
                PdfColors.indigo700,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfSummaryItem(
                'Active Suppliers',
                activeSuppliers.value.toString(),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Total Suppliers',
                suppliers.length.toString(),
                PdfColors.grey700,
              ),
              _pdfSummaryItem(
                'Total Bills',
                bills.length.toString(),
                PdfColors.grey700,
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

  // ✅ Changed: _pdfVendorsSection → _pdfSuppliersSection
  pw.Widget _pdfSuppliersSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Supplier Details',
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
                  'Supplier Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Phone',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Bills',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Amount',
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
            ],
          ),
        ),
        ...suppliers
            .map(
              (supplier) => pw.Container(
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
                        supplier.name,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        supplier.phone,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        supplier.billCount.toString(),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(supplier.totalAmount),
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
                        _formatAmount(supplier.paidAmount),
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
                        _formatAmount(supplier.outstandingAmount),
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
                flex: 7,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(
                    suppliers.fold(0.0, (sum, s) => sum + s.totalAmount),
                  ),
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
                  _formatAmount(
                    suppliers.fold(0.0, (sum, s) => sum + s.paidAmount),
                  ),
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
                  _formatAmount(
                    suppliers.fold(0.0, (sum, s) => sum + s.outstandingAmount),
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

  // ─── _pdfBillsSection (Same as before) ──────────────────────────
  pw.Widget _pdfBillsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill Details',
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
                  'Bill #',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Supplier',
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
                flex: 2,
                child: pw.Text(
                  'Due Date',
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
                  'Outstanding',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Status',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...bills
            .map(
              (bill) => pw.Container(
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
                        bill.billNumber,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        bill.supplierName,  // ✅ Changed
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(bill.date),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(bill.dueDate),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(bill.totalAmount),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(bill.outstanding),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: bill.outstanding > 0
                              ? PdfColors.red700
                              : PdfColors.green700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        bill.status,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: bill.status == 'Paid'
                              ? PdfColors.green700
                              : (bill.isOverdue
                                    ? PdfColors.red700
                                    : PdfColors.orange700),
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
                flex: 9,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(
                    bills.fold(0.0, (sum, b) => sum + b.totalAmount),
                  ),
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
                  _formatAmount(
                    bills.fold(0.0, (sum, b) => sum + b.outstanding),
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

  // ─── Excel Export ──────────────────────────────────────────────────
  Future<void> exportToExcel() async {
    try {
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
        'Accounts Payable Report',
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
      if (selectedSupplierId.value.isNotEmpty) {
        final supplier = suppliers.firstWhere(
          (s) => s.id == selectedSupplierId.value,
          orElse: () => suppliers.first,
        );
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Supplier: ${supplier.name}',
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
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
        ['Overdue', _formatAmount(totalOverdue.value)],
        ['Due This Week', _formatAmount(totalDueThisWeek.value)],
        ['Due This Month', _formatAmount(totalDueThisMonth.value)],
        ['Active Suppliers', activeSuppliers.value.toString()],
        ['Total Suppliers', suppliers.length.toString()],
        ['Total Bills', bills.length.toString()],
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

      // Suppliers Sheet
      final suppliersSheet = excel['Suppliers'];
      final supplierHeaders = [
        'Supplier Name',
        'Email',
        'Phone',
        'Address',
        'Tax ID',
        'Payment Terms',
        'Bill Count',
        'Total Amount',
        'Paid Amount',
        'Outstanding Amount',
      ];

      for (int i = 0; i < supplierHeaders.length; i++) {
        _excelSetCell(
          suppliersSheet,
          0,
          i,
          supplierHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int row = 1;
      for (final supplier in suppliers) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(suppliersSheet, row, 0, supplier.name, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 1, supplier.email, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 2, supplier.phone, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 3, supplier.address, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 4, supplier.taxId, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 5, supplier.paymentTerms, bgColor: bg);
        _excelSetCell(suppliersSheet, row, 6, supplier.billCount, bgColor: bg);
        _excelSetCell(
          suppliersSheet,
          row,
          7,
          supplier.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          suppliersSheet,
          row,
          8,
          supplier.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          suppliersSheet,
          row,
          9,
          supplier.outstandingAmount,
          bgColor: bg,
          fontColor: 'C62828',
        );
        row++;
      }

      // Totals row
      _excelSetCell(
        suppliersSheet,
        row,
        6,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        suppliersSheet,
        row,
        7,
        suppliers.fold(0.0, (sum, s) => sum + s.totalAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '1A237E',
      );
      _excelSetCell(
        suppliersSheet,
        row,
        8,
        suppliers.fold(0.0, (sum, s) => sum + s.paidAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        suppliersSheet,
        row,
        9,
        suppliers.fold(0.0, (sum, s) => sum + s.outstandingAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final supplierColWidths = [
        30.0,
        25.0,
        15.0,
        35.0,
        15.0,
        12.0,
        12.0,
        15.0,
        15.0,
        15.0,
      ];
      for (int i = 0; i < supplierColWidths.length; i++) {
        suppliersSheet.setColumnWidth(i, supplierColWidths[i]);
      }

      // Bills Sheet (same as before)
      final billsSheet = excel['Bills'];
      final billHeaders = [
        'Bill #',
        'Supplier',
        'Date',
        'Due Date',
        'Subtotal',
        'Tax',
        'Discount',
        'Total Amount',
        'Paid Amount',
        'Outstanding',
        'Status',
      ];

      for (int i = 0; i < billHeaders.length; i++) {
        _excelSetCell(
          billsSheet,
          0,
          i,
          billHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int billRow = 1;
      for (final bill in bills) {
        final bg = billRow.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(billsSheet, billRow, 0, bill.billNumber, bgColor: bg);
        _excelSetCell(billsSheet, billRow, 1, bill.supplierName, bgColor: bg);
        _excelSetCell(
          billsSheet,
          billRow,
          2,
          DateFormat('dd MMM yyyy').format(bill.date),
          bgColor: bg,
        );
        _excelSetCell(
          billsSheet,
          billRow,
          3,
          DateFormat('dd MMM yyyy').format(bill.dueDate),
          bgColor: bg,
        );
        _excelSetCell(billsSheet, billRow, 4, bill.subtotal, bgColor: bg);
        _excelSetCell(billsSheet, billRow, 5, bill.taxTotal, bgColor: bg);
        _excelSetCell(billsSheet, billRow, 6, bill.discount, bgColor: bg);
        _excelSetCell(
          billsSheet,
          billRow,
          7,
          bill.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          billsSheet,
          billRow,
          8,
          bill.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          billsSheet,
          billRow,
          9,
          bill.outstanding,
          bgColor: bg,
          fontColor: bill.outstanding > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(
          billsSheet,
          billRow,
          10,
          bill.status,
          bgColor: bill.status == 'Paid'
              ? 'E8F5E9'
              : (bill.isOverdue ? 'FFEBEE' : 'FFF8E1'),
          fontColor: bill.status == 'Paid'
              ? '2E7D32'
              : (bill.isOverdue ? 'C62828' : 'F39C12'),
        );
        billRow++;
      }

      // Totals row
      _excelSetCell(
        billsSheet,
        billRow,
        7,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        billsSheet,
        billRow,
        8,
        bills.fold(0.0, (sum, b) => sum + b.paidAmount),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        billsSheet,
        billRow,
        9,
        bills.fold(0.0, (sum, b) => sum + b.outstanding),
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final billColWidths = [
        15.0,
        25.0,
        12.0,
        12.0,
        12.0,
        12.0,
        12.0,
        15.0,
        15.0,
        15.0,
        12.0,
      ];
      for (int i = 0; i < billColWidths.length; i++) {
        billsSheet.setColumnWidth(i, billColWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'accounts_payable_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
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
          '${bills.length} bills exported to Excel',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          Colors.green,
          'Success',
          '${bills.length} bills exported to Excel',
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

// ─────────────────────── MODELS ───────────────────────

// ✅ Changed: Vendor → Supplier
class Supplier {
  final String id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final String paymentTerms;
  final bool isActive;
  final int billCount;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  Supplier({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.paymentTerms,
    required this.isActive,
    required this.billCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Supplier(
      id: json['id'] ?? json['_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      taxId: json['taxId'] ?? json['gstNumber'] ?? '',
      paymentTerms: json['paymentTerms'] ?? 'Net 30',
      isActive: json['isActive'] ?? true,
      billCount: json['billCount'] ?? 0,
      totalAmount: safeToDouble(json['totalAmount']),
      paidAmount: safeToDouble(json['paidAmount']),
      outstandingAmount: safeToDouble(json['outstandingAmount']),
    );
  }
}

class Bill {
  final String id;
  final String billNumber;
  final String supplierId;  // ✅ Changed: vendorId → supplierId
  final String supplierName;  // ✅ Changed: vendorName → supplierName
  final DateTime date;
  final DateTime dueDate;
  final List<BillItem> items;
  final double subtotal;
  final double taxTotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String notes;

  Bill({
    required this.id,
    required this.billNumber,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.discount,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.notes,
  });

  double get outstanding => (totalAmount - paidAmount).toDouble();

  bool get isOverdue {
    if (status == 'Paid') return false;
    return dueDate.isBefore(DateTime.now());
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Handle vendor relation (from backend)
    dynamic vendorData = json['vendor'] ?? json['vendorId'] ?? {};
    String supplierId = '';
    String supplierName = json['vendorName'] ?? '';

    if (vendorData is Map) {
      supplierId = vendorData['id'] ?? vendorData['_id'] ?? '';
      if (supplierName.isEmpty) {
        supplierName = vendorData['name'] ?? '';
      }
    } else if (vendorData is String) {
      supplierId = vendorData;
    }

    return Bill(
      id: json['id'] ?? json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      supplierId: supplierId,
      supplierName: supplierName,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List).map((e) => BillItem.fromJson(e)).toList()
          : [],
      subtotal: safeToDouble(json['subtotal']),
      taxTotal: safeToDouble(json['taxTotal']),
      discount: safeToDouble(json['discount']),
      totalAmount: safeToDouble(json['totalAmount']),
      paidAmount: safeToDouble(json['paidAmount']),
      status: json['status'] ?? 'Unpaid',
      notes: json['notes'] ?? '',
    );
  }
}

class BillItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;
  final double taxRate;
  final double taxAmount;

  BillItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.taxRate,
    required this.taxAmount,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return BillItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: safeToDouble(json['unitPrice']),
      amount: safeToDouble(json['amount']),
      taxRate: safeToDouble(json['taxRate']),
      taxAmount: safeToDouble(json['taxAmount']),
    );
  }
}