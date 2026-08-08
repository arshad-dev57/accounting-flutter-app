// core/bills/controller/bills_controller.dart - COMPLETE WITH LAZY LOADING

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class BillController extends GetxController {
  var bills = <Bill>[].obs;
  var suppliers = <Map<String, dynamic>>[].obs;
  var bankAccounts = <Map<String, dynamic>>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var isProcessing = false.obs;
  var isSaving = false.obs;
  var isPaying = false.obs;

  var selectedFilter = 'All'.obs;
  var selectedSupplierId = ''.obs;
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var searchQuery = ''.obs;

  // ✅ Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;
  var serverSupportsPagination = false.obs;

  // Summary totals
  var totalAmount = 0.0.obs;
  var totalPaid = 0.0.obs;
  var totalOutstanding = 0.0.obs;

  // ✅ Search controller
  final TextEditingController searchController = TextEditingController();

  // ✅ Scroll controller for lazy loading
  final ScrollController scrollController = ScrollController();

  final ApiClient _api = Get.find<ApiClient>();

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
    searchController.addListener(_onSearchChanged);
    fetchSuppliers();
    fetchBankAccounts();
    fetchBills(resetPage: true);
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
    fetchBills(resetPage: true);
  }

  // ─── Fetch Suppliers ──────────────────────────────────────────────
  Future<void> fetchSuppliers() async {
    try {
      final response = await _api.get('/api/accounts-payable/suppliers');

      if (response.success) {
        suppliers.value = (response.data['data'] as List).map((e) {
          return {
            '_id': e['id']?.toString() ?? e['_id']?.toString() ?? '',
            'id': e['id']?.toString() ?? e['_id']?.toString() ?? '',
            'name': e['name'] ?? '',
            'code': e['code'] ?? '',
          };
        }).toList();

        print('✅ Loaded ${suppliers.length} suppliers');

        if (selectedSupplierId.value.isNotEmpty) {
          bool supplierExists = suppliers.value.any(
            (s) => s['_id'] == selectedSupplierId.value,
          );
          if (!supplierExists) {
            selectedSupplierId.value = '';
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching suppliers: $e');
    }
  }

  // ─── Fetch Bank Accounts ──────────────────────────────────────────
  Future<void> fetchBankAccounts() async {
    try {
      final response = await _api.get('/api/bank-accounts');

      if (response.success) {
        bankAccounts.value = List<Map<String, dynamic>>.from(
          response.data['data'],
        );
      }
    } catch (e) {
      print('Error fetching bank accounts: $e');
    }
  }

  // ─── Fetch Bills with Pagination ──────────────────────────────────
  Future<void> fetchBills({bool resetPage = true}) async {
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

      if (selectedSupplierId.value.isNotEmpty) {
        params['supplierId'] = selectedSupplierId.value;
      }

      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }

      if (startDate.value != null) {
        params['startDate'] = startDate.value!.toIso8601String();
      }

      if (endDate.value != null) {
        params['endDate'] = endDate.value!.toIso8601String();
      }

      final response = await _api.get(
        '/api/accounts-payable/bills',
        queryParameters: params,
      );

      if (response.success) {
        final data = response.data;
        final newBills = (data['data'] as List)
            .map((e) => Bill.fromJson(e))
            .toList();

        if (resetPage) {
          bills.value = newBills;
        } else {
          bills.addAll(newBills);
        }

        // Parse pagination info
        if (data['pagination'] != null) {
          final pagination = data['pagination'];
          totalPages.value =
              pagination['pages'] ?? pagination['totalPages'] ?? 1;
          totalItems.value =
              pagination['total'] ??
              pagination['totalItems'] ??
              newBills.length;
          hasNextPage.value =
              pagination['hasNext'] ?? pagination['nextPage'] != null ?? false;
          hasPrevPage.value =
              pagination['hasPrev'] ?? pagination['prevPage'] != null ?? false;
          serverSupportsPagination.value = true;
        } else if (data['total'] != null) {
          totalPages.value = data['pages'] ?? 1;
          totalItems.value = data['total'];
          hasNextPage.value = data['hasNext'] ?? false;
          hasPrevPage.value = data['hasPrev'] ?? false;
          serverSupportsPagination.value = true;
        } else if (data['totalCount'] != null) {
          totalItems.value = data['totalCount'];
          totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
          hasNextPage.value =
              (currentPage.value * itemsPerPage.value) < totalItems.value;
          hasPrevPage.value = currentPage.value > 1;
          serverSupportsPagination.value = false;
        } else {
          totalItems.value = bills.length;
          totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
          hasNextPage.value =
              (currentPage.value * itemsPerPage.value) < totalItems.value;
          hasPrevPage.value = currentPage.value > 1;
          serverSupportsPagination.value = false;
        }

        _calculateSummary();
        bills.refresh();
      }
    } catch (e) {
      print('❌ Error fetching bills: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── Load More Data (Lazy Loading) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await fetchBills(resetPage: false);
    }
  }

  // ─── Refresh Data ────────────────────────────────────────────────
  Future<void> refreshData() async {
    await fetchSuppliers();
    await fetchBankAccounts();
    await fetchBills(resetPage: true);
  }

  // ─── Calculate Summary ────────────────────────────────────────────
  void _calculateSummary() {
    totalAmount.value = bills.fold(0.0, (sum, b) => sum + b.totalAmount);
    totalPaid.value = bills.fold(0.0, (sum, b) => sum + b.paidAmount);
    totalOutstanding.value = totalAmount.value - totalPaid.value;
  }

  // ─── Create Bill WITH LOADING DIALOG ─────────────────────────────
  Future<void> createBill(Map<String, dynamic> billData) async {
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
                  'Creating bill...',
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
      isSaving(true);

      // Calculate totals from items
      double subtotal = 0;
      final items = (billData['items'] as List).map((item) {
        final qty = (item['quantity'] as num).toDouble();
        final price = (item['unitPrice'] as num).toDouble();
        final amount = qty * price;
        subtotal += amount;
        return {
          'description': item['description'],
          'quantity': qty.toInt(),
          'unitPrice': price,
          'amount': amount,
          'taxRate': 0,
          'taxAmount': 0,
        };
      }).toList();

      final taxRate = (billData['taxRate'] ?? 0).toDouble();
      final discount = (billData['discount'] ?? 0).toDouble();
      final taxAmount = subtotal * (taxRate / 100);
      final totalAmount = subtotal + taxAmount - discount;

      final payload = {
        'supplierId': billData['supplierId'],
        'billNumber':
            billData['billNumber'] ??
            'BILL-${DateTime.now().millisecondsSinceEpoch}',
        'date': billData['date'],
        'dueDate': billData['dueDate'],
        'reference': billData['reference'] ?? '',
        'description': billData['description'] ?? '',
        'items': items,
        'subtotal': subtotal,
        'taxRate': taxRate,
        'taxTotal': taxAmount,
        'discount': discount,
        'totalAmount': totalAmount,
        'notes': billData['notes'] ?? '',
      };

      final response = await _api.post(
        '/api/accounts-payable/bills',
        body: payload,
      );

      Get.back();

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success ✅',
          'Bill created successfully!',
          duration: const Duration(seconds: 3),
        );
        await refreshData();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to create bill',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to create bill: $e');
    } finally {
      isSaving(false);
    }
  }

  // ─── Record Payment WITH LOADING DIALOG ──────────────────────────
  Future<void> recordPayment({
    required String supplierId,
    required String billId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String reference,
    required String? bankAccountId,
    String notes = '',
  }) async {
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
      isPaying(true);

      final body = {
        'supplierId': supplierId,
        'billId': billId,
        'amount': amount,
        'paymentDate': DateFormat('yyyy-MM-dd').format(paymentDate),
        'paymentMethod': paymentMethod,
        'reference': reference,
        'bankAccountId': bankAccountId,
        'notes': notes,
      };

      final response = await _api.post(
        '/api/accounts-payable/payments',
        body: body,
      );

      Get.back();

      if (response.success) {
        AppSnackbar.success(
          Colors.green,
          'Success ✅',
          'Payment recorded successfully!',
          duration: const Duration(seconds: 3),
        );
        await refreshData();
      } else {
        AppSnackbar.error(
          Colors.red,
          'Error',
          response.data['message'] ?? 'Failed to record payment',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to record payment: $e');
    } finally {
      isPaying(false);
    }
  }

  // ─── Filter Methods ──────────────────────────────────────────────
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchBills(resetPage: true);
  }

  void filterBySupplier(String supplierId) {
    selectedSupplierId.value = supplierId;
    fetchBills(resetPage: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    fetchBills(resetPage: true);
  }

  void clearFilters() {
    selectedFilter.value = 'All';
    selectedSupplierId.value = '';
    startDate.value = null;
    endDate.value = null;
    searchController.clear();
    searchQuery.value = '';
    fetchBills(resetPage: true);
  }

  Bill? getBillById(String id) {
    try {
      return bills.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Bill> getUnpaidBillsForSupplier(String supplierId) {
    return bills
        .where((b) => b.supplierId == supplierId && b.status != 'Paid')
        .toList();
  }

  String getSupplierName(String supplierId) {
    try {
      final supplier = suppliers.firstWhere((s) => s['_id'] == supplierId);
      return supplier['name'] ?? 'Unknown Supplier';
    } catch (e) {
      return 'Unknown Supplier';
    }
  }

  // ─── Export Functions ─────────────────────────────────────────────
  void exportBills() {
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
                  'Export Bills',
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
              '${bills.length} bills will be exported',
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

  // ─── PDF Export ──────────────────────────────────────────────────
  Future<void> exportToPdf() async {
    try {
      if (!kIsWeb) {
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
      }

      final branding = await PdfBrandingBundle.load();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => branding.buildHeader(
            reportTitle: 'Bills Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfBillsSection(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'bills_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
            'Total Bills',
            bills.length.toString(),
            accent,
          ),
          _pdfSummaryItem(
            'Total Amount',
            _formatAmount(totalAmount.value),
            accent,
          ),
          _pdfSummaryItem(
            'Total Paid',
            _formatAmount(totalPaid.value),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            'Outstanding',
            _formatAmount(totalOutstanding.value),
            PdfColors.red700,
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
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        bill.supplierName,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(bill.date),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(bill.dueDate),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(bill.totalAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatAmount(bill.paidAmount),
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
                flex: 7,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  _formatAmount(totalAmount.value),
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
                  _formatAmount(totalPaid.value),
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
                  _formatAmount(totalOutstanding.value),
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
      }

      final excel = Excel.createExcel();

      // Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(
        summarySheet,
        0,
        0,
        'Bills Report',
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
          (s) => s['_id'] == selectedSupplierId.value,
          orElse: () => {},
        );
        _excelSetCell(
          summarySheet,
          3,
          0,
          'Supplier: ${supplier['name'] ?? ''}',
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
        ['Total Bills', bills.length.toString()],
        ['Total Amount', _formatAmount(totalAmount.value)],
        ['Total Paid', _formatAmount(totalPaid.value)],
        ['Total Outstanding', _formatAmount(totalOutstanding.value)],
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

      // Bills Sheet
      final billsSheet = excel['Bills'];
      final headers = [
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
        'Notes',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          billsSheet,
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
      for (final bill in bills) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(billsSheet, row, 0, bill.billNumber, bgColor: bg);
        _excelSetCell(billsSheet, row, 1, bill.supplierName, bgColor: bg);
        _excelSetCell(
          billsSheet,
          row,
          2,
          DateFormat('dd MMM yyyy').format(bill.date),
          bgColor: bg,
        );
        _excelSetCell(
          billsSheet,
          row,
          3,
          DateFormat('dd MMM yyyy').format(bill.dueDate),
          bgColor: bg,
        );
        _excelSetCell(billsSheet, row, 4, bill.subtotal, bgColor: bg);
        _excelSetCell(billsSheet, row, 5, bill.taxTotal, bgColor: bg);
        _excelSetCell(billsSheet, row, 6, bill.discount, bgColor: bg);
        _excelSetCell(
          billsSheet,
          row,
          7,
          bill.totalAmount,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(
          billsSheet,
          row,
          8,
          bill.paidAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          billsSheet,
          row,
          9,
          bill.outstanding,
          bgColor: bg,
          fontColor: bill.outstanding > 0 ? 'C62828' : '2E7D32',
        );
        _excelSetCell(
          billsSheet,
          row,
          10,
          bill.status,
          bgColor: bill.status == 'Paid'
              ? 'E8F5E9'
              : (bill.isOverdue ? 'FFEBEE' : 'FFF8E1'),
          fontColor: bill.status == 'Paid'
              ? '2E7D32'
              : (bill.isOverdue ? 'C62828' : 'F39C12'),
        );
        _excelSetCell(billsSheet, row, 11, bill.notes, bgColor: bg);
        row++;
      }

      // Totals row
      _excelSetCell(billsSheet, row, 7, 'TOTAL', bold: true, bgColor: 'E8EAF6');
      _excelSetCell(
        billsSheet,
        row,
        8,
        totalPaid.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );
      _excelSetCell(
        billsSheet,
        row,
        9,
        totalOutstanding.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: 'C62828',
      );

      final colWidths = [
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
        30.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        billsSheet.setColumnWidth(i, colWidths[i]);
      }

      // Items Sheet
      final itemsSheet = excel['Bill Items'];
      final itemHeaders = [
        'Bill #',
        'Supplier',
        'Description',
        'Quantity',
        'Unit Price',
        'Amount',
        'Tax Rate',
        'Tax Amount',
      ];

      for (int i = 0; i < itemHeaders.length; i++) {
        _excelSetCell(
          itemsSheet,
          0,
          i,
          itemHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      int itemRow = 1;
      for (final bill in bills) {
        for (final item in bill.items) {
          final bg = itemRow.isEven ? 'F5F5F5' : 'FFFFFF';
          _excelSetCell(itemsSheet, itemRow, 0, bill.billNumber, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 1, bill.supplierName, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 2, item.description, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 3, item.quantity, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 4, item.unitPrice, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 5, item.amount, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 6, item.taxRate, bgColor: bg);
          _excelSetCell(itemsSheet, itemRow, 7, item.taxAmount, bgColor: bg);
          itemRow++;
        }
      }

      final itemColWidths = [15.0, 25.0, 40.0, 10.0, 12.0, 12.0, 10.0, 12.0];
      for (int i = 0; i < itemColWidths.length; i++) {
        itemsSheet.setColumnWidth(i, itemColWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'bills_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
class Bill {
  final String id;
  final String billNumber;
  final String supplierId;
  final String supplierName;
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
  final String? reference; // ✅ CHANGED: Made nullable

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
    this.reference, // ✅ CHANGED: Nullable
  });

  double get outstanding => totalAmount - paidAmount;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != 'Paid';

  factory Bill.fromJson(Map<String, dynamic> json) {
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    dynamic vendorData = json['vendor'] ?? json['vendorId'] ?? {};
    String supplierId = '';
    String supplierName = json['vendorName'] ?? '';

    if (vendorData is Map) {
      supplierId =
          vendorData['id']?.toString() ?? vendorData['_id']?.toString() ?? '';
      if (supplierName.isEmpty) {
        supplierName = vendorData['name'] ?? '';
      }
    } else if (vendorData is String) {
      supplierId = vendorData;
    }

    return Bill(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
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
      status: json['status']?.toString() ?? 'Unpaid',
      notes: json['notes']?.toString() ?? '',
      reference: json['reference']?.toString(), // ✅ Nullable
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
      description: json['description']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: safeToDouble(json['unitPrice']),
      amount: safeToDouble(json['amount']),
      taxRate: safeToDouble(json['taxRate']),
      taxAmount: safeToDouble(json['taxAmount']),
    );
  }
}
