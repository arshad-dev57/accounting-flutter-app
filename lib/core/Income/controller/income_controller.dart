// core/Income/controller/income_controller.dart - COMPLETE WITH ALL REQUIRED METHODS

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:BisonsTechs_app/core/Income/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class IncomeController extends GetxController {
  // Observable variables
  var incomes = <Income>[].obs;
  var customers = <Map<String, dynamic>>[].obs;
  var bankAccounts = <Map<String, dynamic>>[].obs;
  var incomeAccounts = <Map<String, dynamic>>[].obs;

  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;
  var isPosting = false.obs;

  var selectedFilter = 'All'.obs;
  var selectedType = 'All'.obs;
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var searchQuery = ''.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;
  var hasNextPage = false.obs;
  var hasPrevPage = false.obs;
  var itemsPerPage = 20.obs;

  var serverSupportsPagination = false.obs;

  final List<String> filterOptions = ['All', 'Draft', 'Posted', 'Cancelled'];
  final List<String> incomeTypes = [
    'All',
    'Sales',
    'Services',
    'Interest Income',
    'Rental Income',
    'Dividend Income',
    'Other Income',
  ];

  var totalIncome = 0.0.obs;
  var totalTax = 0.0.obs;
  var totalCount = 0.obs;
  var thisMonthTotal = 0.0.obs;
  var thisWeekTotal = 0.0.obs;
  var byType = <String, double>{}.obs;

  TextEditingController searchController = TextEditingController();
  final ApiClient _api = Get.find<ApiClient>();

  // ✅ Scroll Controller for Lazy Loading
  final ScrollController scrollController = ScrollController();

  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    Future(() async {
      await waitForFiscalYearReady();
      loadAllData();
      loadSummary();
    });
    _fyWorker = listenFiscalYearChanges(() {
      loadAllData();
      loadSummary();
    });
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    loadIncomes(resetPage: true);
  }

  // ─── Load All Data ─────────────────────────────────────────────────
  Future<void> loadAllData() async {
    await Future.wait([
      loadIncomes(resetPage: true),
      loadCustomers(),
      loadBankAccounts(),
      loadIncomeAccounts(),
    ]);
  }

  // ─── Load Income Accounts ──────────────────────────────────────
  Future<void> loadIncomeAccounts() async {
    try {
      final response = await _api.get('/api/income/accounts');
      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          incomeAccounts.value = List<Map<String, dynamic>>.from(
            responseData['data'],
          );
          print('✅ Loaded ${incomeAccounts.length} income accounts');
        }
      }
    } catch (e) {
      print('Error loading income accounts: $e');
    }
  }

  // ─── Load Incomes ──────────────────────────────────────────────────
  Future<void> loadIncomes({bool resetPage = true}) async {
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
      if (selectedType.value != 'All') {
        params['incomeType'] = selectedType.value;
      }
      if (startDate.value != null && endDate.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }
      if (searchQuery.value.isNotEmpty) {
        params['search'] = searchQuery.value;
      }
      putFiscalYearId(params);

      final response = await _api.get(
        '/api/income/list',
        queryParameters: params,
      );

      if (response.success) {
        final Map<String, dynamic> responseData = response.data;

        print("📥 Income API Response: ${json.encode(responseData)}");

        if (responseData['success'] == true) {
          List<dynamic> incomesData = [];

          if (responseData['data'] is List) {
            incomesData = responseData['data'];
          } else if (responseData['incomes'] is List) {
            incomesData = responseData['incomes'];
          } else {
            incomesData = [];
          }

          print("📊 Incomes data count: ${incomesData.length}");
          print(
            "🔍 Current filters - Type: ${selectedType.value}, Filter: ${selectedFilter.value}, Search: ${searchQuery.value}",
          );

          final newIncomes = incomesData
              .map((json) => Income.fromJson(json))
              .toList();

          print("✅ Parsed incomes count: ${newIncomes.length}");

          if (resetPage) {
            incomes.value = newIncomes;
            print("🔄 Reset page - Total incomes: ${incomes.length}");
          } else {
            incomes.addAll(newIncomes);
            print("➕ Added incomes - Total: ${incomes.length}");
          }

          if (responseData['pagination'] != null) {
            final pagination = responseData['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newIncomes.length;
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
            totalItems.value = incomes.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          incomes.refresh();
        } else {
          _showError(responseData['message'] ?? 'Failed to load incomes');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading incomes: $e');
      _showError('Error loading incomes: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // ─── Refresh ────────────────────────────────────────────────────
  Future<void> refreshData() async {
    await loadAllData();
    await loadSummary();
  }

  // ─── Pagination ────────────────────────────────────────────────────
  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadIncomes(resetPage: false);
    }
  }

  Future<void> loadPreviousPage() async {
    if (hasPrevPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value--;
      await loadIncomes(resetPage: false);
    }
  }

  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadIncomes(resetPage: false);
    }
  }

  // ─── Load Customers ───────────────────────────────────────────────
  Future<void> loadCustomers() async {
    try {
      final response = await _api.get('/api/customers');
      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          customers.value = List<Map<String, dynamic>>.from(
            responseData['data'],
          );
        }
      }
    } catch (e) {
      print('Error loading customers: $e');
    }
  }

  // ─── Load Bank Accounts ──────────────────────────────────────────
  Future<void> loadBankAccounts() async {
    try {
      final response = await _api.get('/api/bank-accounts');
      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
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

  // ─── Load Summary ─────────────────────────────────────────────────
  Future<void> loadSummary() async {
    try {
      Map<String, dynamic> params = {};
      if (startDate.value != null && endDate.value != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
        params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }
      putFiscalYearId(params);

      final response = await _api.get(
        '/api/income/summary',
        queryParameters: params,
      );

      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          totalIncome.value = (data['totalIncome'] ?? 0).toDouble();
          totalTax.value = (data['totalTax'] ?? 0).toDouble();
          totalCount.value = data['totalCount'] ?? 0;
          thisMonthTotal.value = (data['thisMonth'] ?? 0).toDouble();
          thisWeekTotal.value = (data['thisWeek'] ?? 0).toDouble();

          if (data['byType'] != null) {
            byType.clear();
            data['byType'].forEach((key, value) {
              byType[key] = (value ?? 0).toDouble();
            });
          }
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  // ─── CREATE INCOME ──────────────────────────────────────────
  Future<void> createIncome({
    required DateTime date,
    required String incomeType,
    required String? incomeAccountId,
    required String? customerId,
    required List<Map<String, dynamic>> items,
    required double? amount,
    required double taxRate,
    required String description,
    required String reference,
    required String paymentMethod,
    required String? bankAccountId,
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
                  'Saving income...',
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
      isSaving.value = true;

      final Map<String, dynamic> incomeData = {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'incomeType': incomeType,
        'incomeAccountId': incomeAccountId,
        'customerId': customerId,
        'items': items,
        'amount': amount ?? 0,
        'taxRate': taxRate,
        'description': description,
        'reference': reference,
        'paymentMethod': paymentMethod,
      };

      final bool hasValidBankAccount =
          bankAccountId != null &&
          bankAccountId.isNotEmpty &&
          bankAccountId != 'null' &&
          bankAccountId != 'NULL' &&
          bankAccountId != 'undefined';

      if (hasValidBankAccount) {
        incomeData['bankAccountId'] = bankAccountId;
      }

      print("📤 Creating income: ${json.encode(incomeData)}");

      final response = await _api.post('/api/income', body: incomeData);

      print("📥 Create Income Response: ${json.encode(response.data)}");

      // Close loading dialog
      Get.back();

      if (response.success) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Income recorded and posted to ledger',
            duration: const Duration(seconds: 3),
          );
          print("🔄 Calling refreshData after successful income creation");
          await refreshData();
          print("✅ refreshData completed");
        } else {
          _showError(responseData['message'] ?? 'Failed to create income');
        }
      } else {
        _showError(response.message ?? 'Failed to create income');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('❌ Error creating income: $e');
      _showError('Error creating income: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ─── DELETE INCOME ──────────────────────────────────────────
  Future<void> deleteIncome(String id, String incomeNumber) async {
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
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting income...',
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
      isDeleting.value = true;
      final response = await _api.delete('/api/income/$id');

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Income $incomeNumber deleted successfully',
        );
        await refreshData();
      } else {
        _showError(response.message ?? 'Failed to delete income');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error deleting income: $e');
      _showError('Error deleting income');
    } finally {
      isDeleting.value = false;
    }
  }

  // ─── POST INCOME ────────────────────────────────────────────
  Future<void> postIncome(String id) async {
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
                  'Posting income...',
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
      isPosting.value = true;
      final response = await _api.post('/api/income/$id/post');

      // Close loading dialog
      Get.back();

      if (response.success) {
        AppSnackbar.success(kSuccess, 'Success', 'Income posted to ledger');
        await refreshData();
      } else {
        _showError(response.message ?? 'Failed to post income');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error posting income: $e');
      _showError('Error posting income');
    } finally {
      isPosting.value = false;
    }
  }

  // ─── Filters ──────────────────────────────────────────────────────
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadIncomes(resetPage: true);
  }

  void applyTypeFilter(String type) {
    selectedType.value = type;
    loadIncomes(resetPage: true);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    loadIncomes(resetPage: true);
    loadSummary();
  }

  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
    loadIncomes(resetPage: true);
    loadSummary();
  }

  void clearFilters() {
    selectedFilter.value = 'All';
    selectedType.value = 'All';
    startDate.value = null;
    endDate.value = null;
    searchController.clear();
    searchQuery.value = '';
    loadIncomes(resetPage: true);
    loadSummary();
  }

  // ─── Export Functions ─────────────────────────────────────────────
  void exportIncomes() {
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
                  'Export Incomes',
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
              '${incomes.length} entries will be exported',
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
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            reportTitle: 'Income Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfIncomesTable(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'incomes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          '${incomes.length} incomes exported to PDF',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          '${incomes.length} incomes exported to PDF',
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
  }

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
        'Income Report',
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
        4,
        0,
        'SUMMARY',
        bold: true,
        fontSize: 11,
        bgColor: 'E8EAF6',
      );

      final summaryRows = [
        ['Total Income', formatAmount(totalIncome.value)],
        ['Total Tax', formatAmount(totalTax.value)],
        ['Total Records', totalCount.value.toString()],
        ['This Month', formatAmount(thisMonthTotal.value)],
        ['This Week', formatAmount(thisWeekTotal.value)],
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

      // Income Sheet
      final incomeSheet = excel['Incomes'];
      final headers = [
        'Income #',
        'Type',
        'Customer',
        'Date',
        'Amount',
        'Tax',
        'Total',
        'Status',
        'Payment Method',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          incomeSheet,
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
      for (final income in incomes) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(incomeSheet, row, 0, income.incomeNumber, bgColor: bg);
        _excelSetCell(incomeSheet, row, 1, income.incomeType, bgColor: bg);
        _excelSetCell(
          incomeSheet,
          row,
          2,
          income.customerName.isEmpty ? '-' : income.customerName,
          bgColor: bg,
        );
        _excelSetCell(
          incomeSheet,
          row,
          3,
          DateFormat('dd MMM yyyy').format(income.date),
          bgColor: bg,
        );
        _excelSetCell(incomeSheet, row, 4, income.subtotal, bgColor: bg);
        _excelSetCell(incomeSheet, row, 5, income.taxAmount, bgColor: bg);
        _excelSetCell(
          incomeSheet,
          row,
          6,
          income.totalAmount,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(incomeSheet, row, 7, income.status, bgColor: bg);
        _excelSetCell(incomeSheet, row, 8, income.paymentMethod, bgColor: bg);
        row++;
      }

      // Totals row
      _excelSetCell(
        incomeSheet,
        row,
        6,
        'TOTAL',
        bold: true,
        bgColor: 'E8EAF6',
      );
      _excelSetCell(
        incomeSheet,
        row,
        6,
        totalIncome.value,
        bold: true,
        bgColor: 'E8EAF6',
        fontColor: '2E7D32',
      );

      final colWidths = [15.0, 15.0, 25.0, 15.0, 15.0, 15.0, 15.0, 15.0, 18.0];
      for (int i = 0; i < colWidths.length; i++) {
        incomeSheet.setColumnWidth(i, colWidths[i]);
      }

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'incomes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
          kSuccess,
          'Success',
          '${incomes.length} incomes exported to Excel',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          '${incomes.length} incomes exported to Excel',
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

  void printIncomes() {
    AppSnackbar.success(kPrimary, 'Print', 'Preparing income report...');
  }

  // ─── PDF Helpers ──────────────────────────────────────────────────


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
            'Total Income',
            formatAmount(totalIncome.value),
            PdfColors.green700,
          ),
          _pdfSummaryItem(
            'Total Tax',
            formatAmount(totalTax.value),
            PdfColors.orange700,
          ),
          _pdfSummaryItem(
            'Total Records',
            totalCount.value.toString(),
            accent,
          ),
          _pdfSummaryItem(
            'This Month',
            formatAmount(thisMonthTotal.value),
            PdfColors.blue700,
          ),
          _pdfSummaryItem(
            'This Week',
            formatAmount(thisWeekTotal.value),
            PdfColors.purple700,
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

  pw.Widget _pdfIncomesTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Income Details',
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
                  'Income #',
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
                  'Customer',
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
                  'Amount',
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
        ...incomes
            .map(
              (income) => pw.Container(
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
                        income.incomeNumber,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        income.incomeType,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        income.customerName.isEmpty ? '-' : income.customerName,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        DateFormat('dd MMM yyyy').format(income.date),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        formatAmount(income.totalAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        income.status,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 9),
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
                child: pw.Text(
                  formatAmount(totalIncome.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text('', textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────
  String formatAmount(double amount) => CurrencyUtils.format(amount);

  String getTypeColor(String type) {
    switch (type) {
      case 'Sales':
        return '#2ECC71';
      case 'Services':
        return '#3498DB';
      case 'Interest Income':
        return '#F1C40F';
      case 'Rental Income':
        return '#E67E22';
      case 'Dividend Income':
        return '#9B59B6';
      default:
        return '#7A8FA6';
    }
  }

  IconData getTypeIcon(String type) {
    switch (type) {
      case 'Sales':
        return Icons.shopping_cart;
      case 'Services':
        return Icons.handshake;
      case 'Interest Income':
        return Icons.trending_up;
      case 'Rental Income':
        return Icons.home_work;
      case 'Dividend Income':
        return Icons.attach_money;
      default:
        return Icons.receipt;
    }
  }

  void _showError(String message) {
    AppSnackbar.error(Colors.red, 'Error', message);
  }
}
