import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/config/apiconfig.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:LedgerPro_app/core/FixedAssets/models/fixed_asset_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;

class FixedAssetController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  var allAssets = <FixedAsset>[].obs;
  var assets = <FixedAsset>[].obs;
  var vendors = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var selectedFilter = 'All'.obs;
  var searchQuery = ''.obs;

  final List<String> filterOptions = [
    'All',
    'Active',
    'Fully Depreciated',
    'Disposed',
  ];

  var totalAssets = 0.obs;
  var totalCost = 0.0.obs;
  var totalDepreciation = 0.0.obs;
  var totalNetBookValue = 0.0.obs;

  // Text editing controller
  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadFixedAssets();
    loadVendors();
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
      assets.value = allAssets.value;
      _updateSummaryForFiltered(allAssets.value);
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      final results = allAssets.where((asset) {
        return asset.name.toLowerCase().contains(searchLower) ||
            asset.assetCode.toLowerCase().contains(searchLower) ||
            asset.category.toLowerCase().contains(searchLower) ||
            asset.location.toLowerCase().contains(searchLower) ||
            asset.supplier.toLowerCase().contains(searchLower);
      }).toList();
      assets.value = results;
      _updateSummaryForFiltered(results);
    }
  }

  void _updateSummaryForFiltered(List<FixedAsset> filteredAssets) {
    totalAssets.value = filteredAssets.length;
    totalCost.value = filteredAssets.fold(
      0.0,
      (sum, a) => sum + a.purchaseCost,
    );
    totalDepreciation.value = filteredAssets.fold(
      0.0,
      (sum, a) => sum + a.accumulatedDepreciation,
    );
    totalNetBookValue.value = filteredAssets.fold(
      0.0,
      (sum, a) => sum + a.netBookValue,
    );
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  String _formatAmountSimple(double amount) {
    return CurrencyUtils.format(amount);
  }

  Future<void> loadFixedAssets() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> params = {};
      if (selectedFilter.value != 'All') {
        params['status'] = selectedFilter.value;
      }

      final response = await _apiClient.get(
        '/api/fixed-assets',
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          List<dynamic> assetsData = responseData['data'];
          final newAssets = assetsData
              .map((json) => FixedAsset.fromJson(json))
              .toList();

          allAssets.value = newAssets;

          if (searchQuery.value.isNotEmpty) {
            _onSearchChanged();
          } else {
            assets.value = newAssets;
          }
        } else {
          _showError('Failed to load fixed assets');
        }
      } else {
        _showError('Failed to load fixed assets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading fixed assets: $e');
      _showError('Error loading fixed assets');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVendors() async {
    try {
      final response = await _apiClient.get('/api/warehouse/supplier');

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          vendors.value = List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
    } catch (e) {
      print('Error loading vendors: $e');
    }
  }

  Future<void> loadSummary() async {
    try {
      final response = await _apiClient.get('/api/fixed-assets/summary');

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          totalAssets.value = data['totalAssets'] ?? 0;
          totalCost.value = (data['totalCost'] ?? 0).toDouble();
          totalDepreciation.value = (data['accumulatedDepreciation'] ?? 0)
              .toDouble();
          totalNetBookValue.value = (data['netBookValue'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  Future<void> createFixedAsset({
  required String name,
  required String category,
  required DateTime purchaseDate,
  required double purchaseCost,
  required int usefulLife,
  required double salvageValue,
  required String location,
  String? supplierId,
  DateTime? warrantyExpiry,
  String? notes,
}) async {
  try {
    isProcessing.value = true;

    final Map<String, dynamic> assetData = {
      'name': name,
      'category': category,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
      'purchaseCost': purchaseCost,
      'usefulLife': usefulLife,
      'salvageValue': salvageValue,
      'location': location,
      'notes': notes ?? '',
    };

    // ✅ Only add supplierId if it's not null and not empty
    if (supplierId != null && supplierId.isNotEmpty && supplierId != 'null') {
      assetData['supplierId'] = supplierId;
      print('✅ Adding supplierId: $supplierId');
    } else {
      print('ℹ️ No supplier selected, skipping supplier');
    }
    
    if (warrantyExpiry != null) {
      assetData['warrantyExpiry'] = DateFormat('yyyy-MM-dd').format(warrantyExpiry);
    }

    print('📦 Request Body: ${assetData}');

    final response = await _apiClient.post(
      '/api/fixed-assets',
      body: assetData,
    );

    if (response.success && response.statusCode == 201) {
      final responseData = response.data;
      if (responseData['success'] == true) {
        Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fixed asset added successfully\nJournal entry created',
          duration: const Duration(seconds: 3),
        );

        loadFixedAssets();
        loadSummary();
      } else {
        _showError(responseData['message'] ?? 'Failed to add asset');
      }
    } else {
      _showError(response.data['message'] ?? 'Failed to add asset');
    }
  } catch (e) {
    print('Error creating fixed asset: $e');
    _showError('Error creating fixed asset');
  } finally {
    isProcessing.value = false;
  }
}
  Future<void> updateFixedAsset({
  required String id,
  required String name,
  required String category,
  required DateTime purchaseDate,
  required double purchaseCost,
  required int usefulLife,
  required double salvageValue,
  required String location,
  String? supplierId,
  DateTime? warrantyExpiry,
  String? notes,
}) async {
  try {
    isProcessing.value = true;

    final Map<String, dynamic> assetData = {
      'name': name,
      'category': category,
      'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
      'purchaseCost': purchaseCost,
      'usefulLife': usefulLife,
      'salvageValue': salvageValue,
      'location': location,
      'notes': notes ?? '',
    };

    // ✅ Only add supplierId if it's not null and not empty
    if (supplierId != null && supplierId.isNotEmpty && supplierId != 'null') {
      assetData['supplierId'] = supplierId;
      print('✅ Adding supplierId: $supplierId');
    } else {
      print('ℹ️ No supplier selected, skipping supplier');
    }
    
    if (warrantyExpiry != null) {
      assetData['warrantyExpiry'] = DateFormat('yyyy-MM-dd').format(warrantyExpiry);
    }

    print('📦 Request Body: ${assetData}');

    final response = await _apiClient.put(
      '/api/fixed-assets/$id',
      body: assetData,
    );

    if (response.success && response.statusCode == 200) {
      final responseData = response.data;
      if (responseData['success'] == true) {
        Get.back();
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fixed asset updated successfully',
          duration: const Duration(seconds: 3),
        );

        loadFixedAssets();
        loadSummary();
      } else {
        _showError(responseData['message'] ?? 'Failed to update asset');
      }
    } else {
      _showError(response.data['message'] ?? 'Failed to update asset');
    }
  } catch (e) {
    print('Error updating fixed asset: $e');
    _showError('Error updating fixed asset');
  } finally {
    isProcessing.value = false;
  }
}
  Future<void> depreciateAsset(FixedAsset asset) async {
    try {
      isProcessing.value = true;

      final Map<String, dynamic> depData = {
        'assetId': asset.id,
        'depreciationDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final response = await _apiClient.post(
        '/api/fixed-assets/depreciate',
        body: depData,
      );

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          AppSnackbar.success(
            kSuccess,
            'Depreciation Complete',
            'Depreciation of ${formatAmount(data['asset']['depreciationAmount'])} recorded for ${asset.name}',
            duration: const Duration(seconds: 3),
          );

          loadFixedAssets();
          loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to depreciate asset');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to depreciate asset');
      }
    } catch (e) {
      print('Error depreciating asset: $e');
      _showError('Error depreciating asset');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> runMonthlyDepreciation() async {
    try {
      isProcessing.value = true;

      final Map<String, dynamic> depData = {
        'depreciationDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final response = await _apiClient.post(
        '/api/fixed-assets/depreciate-all',
        body: depData,
      );

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          AppSnackbar.success(
            kSuccess,
            'Monthly Depreciation Complete',
            'Depreciation processed for ${data['processed']} assets',
            duration: const Duration(seconds: 3),
          );

          loadFixedAssets();
          loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to run depreciation');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to run depreciation');
      }
    } catch (e) {
      print('Error running monthly depreciation: $e');
      _showError('Error running monthly depreciation');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> disposeAsset({
    required String assetId,
    required DateTime disposalDate,
    required double disposalAmount,
    required String disposalReason,
  }) async {
    try {
      print("🔵 [disposeAsset] Start");
      print("➡️ Asset ID: $assetId");
      print("➡️ Disposal Date: $disposalDate");
      print("➡️ Disposal Amount: $disposalAmount");
      print("➡️ Disposal Reason: $disposalReason");

      isProcessing.value = true;

      final Map<String, dynamic> disposeData = {
        'assetId': assetId,
        'disposalDate': DateFormat('yyyy-MM-dd').format(disposalDate),
        'disposalAmount': disposalAmount,
        'disposalReason': disposalReason,
      };

      print("📦 Request Body: ${disposeData}");

      final response = await _apiClient.post(
        '/api/fixed-assets/dispose',
        body: disposeData,
      );

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.data}");

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          final gainLoss = data['asset']['gainLoss'];

          print("💰 Gain/Loss: $gainLoss");

          final message = gainLoss >= 0
              ? 'Asset disposed with gain of ${formatAmount(gainLoss)}'
              : 'Asset disposed with loss of ${formatAmount(gainLoss.abs())}';

          print("📢 Snackbar Message: $message");

          AppSnackbar.success(
            gainLoss >= 0 ? kSuccess : kWarning,
            'Asset Disposed',
            message,
            duration: const Duration(seconds: 3),
          );

          print("🔄 Refreshing data...");
          loadFixedAssets();
          loadSummary();
        } else {
          print("❌ API Success = false");
          _showError(responseData['message'] ?? 'Failed to dispose asset');
        }
      } else {
        print("❌ Non-200 response");
        _showError(response.data['message'] ?? 'Failed to dispose asset');
      }
    } catch (e, stackTrace) {
      print("🔥 Exception occurred: $e");
      print("🧵 StackTrace: $stackTrace");
      _showError('Error disposing asset');
    } finally {
      isProcessing.value = false;
      print("🔵 [disposeAsset] End");
    }
  }

  Future<void> deleteFixedAsset(String id, String name) async {
    try {
      isProcessing.value = true;

      final response = await _apiClient.delete('/api/fixed-assets/$id');

      if (response.success && response.statusCode == 200) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fixed asset $name deleted successfully',
          duration: const Duration(seconds: 2),
        );

        loadFixedAssets();
        loadSummary();
      } else {
        _showError(response.data['message'] ?? 'Failed to delete asset');
      }
    } catch (e) {
      print('Error deleting fixed asset: $e');
      _showError('Error deleting fixed asset');
    } finally {
      isProcessing.value = false;
    }
  }

  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadFixedAssets();
  }

  void filterAssets() {
    if (searchQuery.value.isNotEmpty) {
      _onSearchChanged();
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    assets.value = allAssets.value;
    _updateSummaryForFiltered(allAssets.value);
  }

  // ==================== EXPORT FUNCTIONS ====================

  void exportAssets() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(5.w),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            _pdfAssetsTable(),
            pw.SizedBox(height: 16),
            _pdfCategoryBreakdown(),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'fixed_assets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          const Color(0xFF2ECC71),
          'Success',
          'PDF exported successfully',
          duration: const Duration(seconds: 2),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          const Color(0xFF2ECC71),
          'Success',
          'PDF exported successfully',
          duration: const Duration(seconds: 2),
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
        'Fixed Assets Report',
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

      if (selectedFilter.value != 'All') {
        _excelSetCell(
          summarySheet,
          2,
          0,
          'Filter: ${selectedFilter.value}',
          fontSize: 10,
          fontColor: '1A237E',
        );
      }
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
        ['Total Assets', totalAssets.value.toString()],
        ['Total Cost', _formatAmountSimple(totalCost.value)],
        [
          'Total Accumulated Depreciation',
          _formatAmountSimple(totalDepreciation.value),
        ],
        ['Total Net Book Value', _formatAmountSimple(totalNetBookValue.value)],
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

      // Fixed Assets Sheet
      final assetsSheet = excel['Fixed Assets'];
      final headers = [
        'Asset Code',
        'Asset Name',
        'Category',
        'Status',
        'Purchase Date',
        'Purchase Cost',
        'Useful Life',
        'Salvage Value',
        'Depreciation Method',
        'Monthly Depreciation',
        'Accumulated Depreciation',
        'Net Book Value',
        'Location',
        'Supplier',
      ];

      for (int i = 0; i < headers.length; i++) {
        _excelSetCell(
          assetsSheet,
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
      for (final asset in assets) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(assetsSheet, row, 0, asset.assetCode, bgColor: bg);
        _excelSetCell(assetsSheet, row, 1, asset.name, bgColor: bg);
        _excelSetCell(assetsSheet, row, 2, asset.category, bgColor: bg);

        final statusColor = asset.status == 'Active'
            ? '2E7D32'
            : asset.status == 'Fully Depreciated'
            ? 'F57C00'
            : 'C62828';
        _excelSetCell(
          assetsSheet,
          row,
          3,
          asset.status,
          bgColor: bg,
          fontColor: statusColor,
        );

        _excelSetCell(
          assetsSheet,
          row,
          4,
          DateFormat('dd MMM yyyy').format(asset.purchaseDate),
          bgColor: bg,
        );
        _excelSetCell(
          assetsSheet,
          row,
          5,
          asset.purchaseCost,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(assetsSheet, row, 6, asset.usefulLife, bgColor: bg);
        _excelSetCell(assetsSheet, row, 7, asset.salvageValue, bgColor: bg);
        _excelSetCell(
          assetsSheet,
          row,
          8,
          asset.depreciationMethod,
          bgColor: bg,
        );
        _excelSetCell(
          assetsSheet,
          row,
          9,
          asset.currentDepreciation,
          bgColor: bg,
        );
        _excelSetCell(
          assetsSheet,
          row,
          10,
          asset.accumulatedDepreciation,
          bgColor: bg,
          fontColor: 'F57C00',
        );
        _excelSetCell(
          assetsSheet,
          row,
          11,
          asset.netBookValue,
          bgColor: bg,
          fontColor: '1A237E',
        );
        _excelSetCell(assetsSheet, row, 12, asset.location, bgColor: bg);
        _excelSetCell(assetsSheet, row, 13, asset.supplier, bgColor: bg);
        row++;
      }

      final colWidths = [
        12.0,
        25.0,
        15.0,
        12.0,
        12.0,
        15.0,
        10.0,
        12.0,
        15.0,
        15.0,
        18.0,
        15.0,
        15.0,
        20.0,
      ];
      for (int i = 0; i < colWidths.length; i++) {
        assetsSheet.setColumnWidth(i, colWidths[i]);
      }

      // Category Breakdown Sheet
      final categorySheet = excel['Category Breakdown'];
      final catHeaders = ['Category', 'Count', 'Total Cost', 'Net Book Value'];

      for (int i = 0; i < catHeaders.length; i++) {
        _excelSetCell(
          categorySheet,
          0,
          i,
          catHeaders[i],
          bold: true,
          bgColor: '1A237E',
          fontColor: 'FFFFFF',
          fontSize: 10,
        );
      }

      Map<String, int> categoryCount = {};
      Map<String, double> categoryCost = {};
      Map<String, double> categoryNBV = {};

      for (var asset in assets) {
        categoryCount[asset.category] =
            (categoryCount[asset.category] ?? 0) + 1;
        categoryCost[asset.category] =
            (categoryCost[asset.category] ?? 0) + asset.purchaseCost;
        categoryNBV[asset.category] =
            (categoryNBV[asset.category] ?? 0) + asset.netBookValue;
      }

      int catRow = 1;
      for (var category in categoryCount.keys) {
        final bg = catRow.isEven ? 'F5F5F5' : 'FFFFFF';
        _excelSetCell(categorySheet, catRow, 0, category, bgColor: bg);
        _excelSetCell(
          categorySheet,
          catRow,
          1,
          categoryCount[category]!,
          bgColor: bg,
        );
        _excelSetCell(
          categorySheet,
          catRow,
          2,
          categoryCost[category]!,
          bgColor: bg,
          fontColor: '2E7D32',
        );
        _excelSetCell(
          categorySheet,
          catRow,
          3,
          categoryNBV[category]!,
          bgColor: bg,
          fontColor: '1A237E',
        );
        catRow++;
      }

      categorySheet.setColumnWidth(0, 20);
      categorySheet.setColumnWidth(1, 10);
      categorySheet.setColumnWidth(2, 18);
      categorySheet.setColumnWidth(3, 18);

      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName =
          'fixed_assets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

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
          const Color(0xFF2ECC71),
          'Success',
          'Excel exported successfully',
          duration: const Duration(seconds: 2),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (Get.isDialogOpen ?? false) Get.back();

        AppSnackbar.success(
          const Color(0xFF2ECC71),
          'Success',
          'Excel exported successfully',
          duration: const Duration(seconds: 2),
        );

        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export Excel: $e');
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
                'Fixed Assets Report',
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
              if (selectedFilter.value != 'All')
                pw.Text(
                  'Filter: ${selectedFilter.value}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.indigo600,
                  ),
                ),
              if (searchQuery.value.isNotEmpty)
                pw.Text(
                  'Search: ${searchQuery.value}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.indigo600,
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
              'FIXED ASSETS',
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
                'Total Assets',
                totalAssets.value.toString(),
                PdfColors.indigo700,
              ),
              _pdfSummaryItem(
                'Total Cost',
                _formatAmountSimple(totalCost.value),
                PdfColors.green700,
              ),
              _pdfSummaryItem(
                'Total Depreciation',
                _formatAmountSimple(totalDepreciation.value),
                PdfColors.orange700,
              ),
              _pdfSummaryItem(
                'Net Book Value',
                _formatAmountSimple(totalNetBookValue.value),
                PdfColors.blue700,
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

  pw.Widget _pdfAssetsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Fixed Assets Details',
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
                flex: 2,
                child: pw.Text(
                  'Asset Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Category',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Status',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Cost',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Depreciation',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'NBV',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...assets
            .map(
              (asset) => pw.Container(
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
                        asset.assetCode,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        asset.name,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        asset.category,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        asset.status,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: asset.status == 'Active'
                              ? PdfColors.green700
                              : asset.status == 'Fully Depreciated'
                              ? PdfColors.orange700
                              : PdfColors.red700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.purchaseCost),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.accumulatedDepreciation),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.orange700,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.netBookValue),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.blue700,
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
                flex: 5,
                child: pw.Text(
                  'Total',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  _formatAmountSimple(totalCost.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  _formatAmountSimple(totalDepreciation.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  _formatAmountSimple(totalNetBookValue.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCategoryBreakdown() {
    Map<String, double> categoryCost = {};
    Map<String, double> categoryNBV = {};

    for (var asset in assets) {
      categoryCost[asset.category] =
          (categoryCost[asset.category] ?? 0) + asset.purchaseCost;
      categoryNBV[asset.category] =
          (categoryNBV[asset.category] ?? 0) + asset.netBookValue;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        pw.Text(
          'Category Breakdown',
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
                  'Category',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Count',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Total Cost',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Net Book Value',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...categoryCost.keys.map((category) {
          int count = assets.where((a) => a.category == category).length;
          return pw.Container(
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
                    category,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    count.toString(),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _formatAmountSimple(categoryCost[category]!),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _formatAmountSimple(categoryNBV[category]!),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
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

  void printAssets() {
    AppSnackbar.success(
      kPrimary,
      'Print',
      'Preparing fixed assets report for printing...',
      duration: const Duration(seconds: 2),
    );
  }

  void showAddAssetDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = 'Building';
    DateTime purchaseDate = DateTime.now();
    double purchaseCost = 0;
    int usefulLife = 5;
    double salvageValue = 0;
    String location = '';
    String? selectedSupplierId;
    DateTime? warrantyExpiry;
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
                  Text(
                    'Add Fixed Asset',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Asset Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              onChanged: (value) => name = value,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Name required'
                                  : null,
                            ),
                            SizedBox(height: 2.h),

                            Container(
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: category,
                                decoration: InputDecoration(
                                  labelText: 'Category *',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.5.h,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12.sp,
                                    color: kSubText,
                                  ),
                                ),
                                style: TextStyle(fontSize: 14.sp, color: kText),
                                dropdownColor: kCardBg,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Building',
                                    child: Text('Building'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Vehicle',
                                    child: Text('Vehicle'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'IT Equipment',
                                    child: Text('IT Equipment'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Furniture',
                                    child: Text('Furniture'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Machinery',
                                    child: Text('Machinery'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Equipment',
                                    child: Text('Equipment'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => category = value!),
                              ),
                            ),
                            SizedBox(height: 2.h),

                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: purchaseDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => purchaseDate = picked);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 5.w,
                                      color: kPrimary,
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Purchase Date *',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: kSubText,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(purchaseDate),
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: kText,
                                            ),
                                          ),
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
                                labelText: 'Purchase Cost *',
                                prefixText: CurrencyUtils.prefix,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  purchaseCost = double.tryParse(value) ?? 0,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Purchase cost required'
                                  : null,
                            ),
                            SizedBox(height: 2.h),

                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Useful Life (years) *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  usefulLife = int.tryParse(value) ?? 5,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Useful life required'
                                  : null,
                            ),
                            SizedBox(height: 2.h),

                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Salvage Value',
                                prefixText: CurrencyUtils.prefix,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              keyboardType: TextInputType.number,
                              onChanged: (value) =>
                                  salvageValue = double.tryParse(value) ?? 0,
                            ),
                            SizedBox(height: 2.h),

                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              onChanged: (value) => location = value,
                            ),
                            SizedBox(height: 2.h),

                            Container(
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedSupplierId,
                                decoration: InputDecoration(
                                  labelText: 'Supplier',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.5.h,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12.sp,
                                    color: kSubText,
                                  ),
                                ),
                                style: TextStyle(fontSize: 14.sp, color: kText),
                                dropdownColor: kCardBg,
                                hint: Text(
                                  'Select supplier',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: kSubText,
                                  ),
                                ),
                                items: vendors.map((vendor) {
                                  return DropdownMenuItem(
                                    value: vendor['_id'].toString(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vendor['name'],
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: kText,
                                          ),
                                        ),
                                        Text(
                                          vendor['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: kSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => selectedSupplierId = value),
                              ),
                            ),
                            SizedBox(height: 2.h),

                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      warrantyExpiry ??
                                      DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => warrantyExpiry = picked);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: 5.w,
                                      color: kPrimary,
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Warranty Expiry',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: kSubText,
                                            ),
                                          ),
                                          Text(
                                            warrantyExpiry != null
                                                ? DateFormat(
                                                    'dd MMM yyyy',
                                                  ).format(warrantyExpiry!)
                                                : 'Not set',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: kText,
                                            ),
                                          ),
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
                                labelText: 'Notes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelStyle: TextStyle(fontSize: 12.sp),
                                fillColor: kCardBg,
                                filled: true,
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              maxLines: 2,
                              onChanged: (value) => notes = value,
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
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: isProcessing.value
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      createFixedAsset(
                                        name: name,
                                        category: category,
                                        purchaseDate: purchaseDate,
                                        purchaseCost: purchaseCost,
                                        usefulLife: usefulLife,
                                        salvageValue: salvageValue,
                                        location: location,
                                        supplierId: selectedSupplierId,
                                        warrantyExpiry: warrantyExpiry,
                                        notes: notes,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isProcessing.value
                                ? SizedBox(
                                    width: 5.w,
                                    height: 5.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Add Asset',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
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

  void showEditAssetDialog(FixedAsset asset) {
  final formKey = GlobalKey<FormState>();
  String name = asset.name;
  String category = asset.category;
  DateTime purchaseDate = asset.purchaseDate;
  double purchaseCost = asset.purchaseCost;
  int usefulLife = asset.usefulLife;
  double salvageValue = asset.salvageValue;
  String location = asset.location;
  String? selectedSupplierId;
  DateTime? warrantyExpiry = asset.warrantyExpiry;
  String notes = asset.notes;

  // ✅ Find supplier if exists
  if (asset.supplier.isNotEmpty) {
    final vendor = vendors.firstWhere(
      (v) => v['name'] == asset.supplier,
      orElse: () => {},
    );
    if (vendor.isNotEmpty) {
      selectedSupplierId = vendor['_id'].toString();
    }
  }

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
                // ... (header)

                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // ... (other fields)

                          // ✅ Supplier Dropdown with "None" option
                          Container(
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedSupplierId,
                              decoration: InputDecoration(
                                labelText: 'Supplier (Optional)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.5.h,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 12.sp,
                                  color: kSubText,
                                ),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              dropdownColor: kCardBg,
                              hint: Text(
                                'Select supplier (optional)',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: kSubText,
                                ),
                              ),
                              items: [
                                // ✅ ADD "None" option
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text(
                                    'None',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                ...vendors.map((vendor) {
                                  return DropdownMenuItem(
                                    value: vendor['_id'].toString(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vendor['name'],
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: kText,
                                          ),
                                        ),
                                        Text(
                                          vendor['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: kSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  // ✅ If value is empty string, set to null
                                  selectedSupplierId = (value != null && value.isNotEmpty) ? value : null;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // ... (rest of the fields)
                        ],
                      ),
                    ),
                  ),
                ),
                // ... (buttons)
              ],
            );
          },
        ),
      ),
    ),
  );
}
  void showDisposeAssetDialog(FixedAsset asset) {
    final formKey = GlobalKey<FormState>();
    DateTime disposalDate = DateTime.now();
    double disposalAmount = asset.netBookValue;
    String disposalReason = '';

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
                  Text(
                    'Dispose Asset',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    asset.name,
                    style: TextStyle(fontSize: 12.sp, color: kSubText),
                  ),
                  Text(
                    'Net Book Value: ${formatAmount(asset.netBookValue)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: kDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: disposalDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => disposalDate = picked);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 5.w,
                                  color: kPrimary,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Disposal Date *',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: kSubText,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(disposalDate),
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: kText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),

                        TextFormField(
                          initialValue: disposalAmount.toString(),
                          decoration: InputDecoration(
                            labelText: 'Disposal Amount *',
                            prefixText: CurrencyUtils.prefix,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: TextStyle(fontSize: 12.sp),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              disposalAmount = double.tryParse(value) ?? 0,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Amount required'
                              : null,
                        ),
                        SizedBox(height: 2.h),

                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Disposal Reason',
                            hintText: 'e.g., Sold, Scrapped, Donated',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: TextStyle(fontSize: 12.sp),
                            fillColor: kCardBg,
                            filled: true,
                          ),
                          style: TextStyle(fontSize: 14.sp, color: kText),
                          onChanged: (value) => disposalReason = value,
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
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: isProcessing.value
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      Get.back();
                                      disposeAsset(
                                        assetId: asset.id,
                                        disposalDate: disposalDate,
                                        disposalAmount: disposalAmount,
                                        disposalReason: disposalReason,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDanger,
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isProcessing.value
                                ? SizedBox(
                                    width: 5.w,
                                    height: 5.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Dispose Asset',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
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

  void showAssetDetails(FixedAsset asset) {
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
                    color: getAssetCategoryColor(
                      asset.category,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getAssetIcon(asset.category),
                    size: 7.w,
                    color: getAssetCategoryColor(asset.category),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      Text(
                        '${asset.assetCode} • ${asset.category}',
                        style: TextStyle(fontSize: 12.sp, color: kSubText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: asset.status == 'Active'
                        ? kSuccess.withOpacity(0.1)
                        : asset.status == 'Fully Depreciated'
                        ? kWarning.withOpacity(0.1)
                        : kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    asset.status,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: asset.status == 'Active'
                          ? kSuccess
                          : asset.status == 'Fully Depreciated'
                          ? kWarning
                          : kDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              'Purchase Date',
              DateFormat('dd MMM yyyy').format(asset.purchaseDate),
            ),
            _buildDetailRow('Purchase Cost', formatAmount(asset.purchaseCost)),
            _buildDetailRow('Useful Life', '${asset.usefulLife} years'),
            _buildDetailRow('Salvage Value', formatAmount(asset.salvageValue)),
            _buildDetailRow('Depreciation Method', asset.depreciationMethod),
            _buildDetailRow(
              'Monthly Depreciation',
              formatAmount(asset.currentDepreciation),
            ),
            _buildDetailRow(
              'Accumulated Depreciation',
              formatAmount(asset.accumulatedDepreciation),
            ),
            _buildDetailRow('Net Book Value', formatAmount(asset.netBookValue)),
            _buildDetailRow('Location', asset.location),
            _buildDetailRow('Supplier', asset.supplier),
            if (asset.warrantyExpiry != null)
              _buildDetailRow(
                'Warranty Expiry',
                DateFormat('dd MMM yyyy').format(asset.warrantyExpiry!),
              ),
            if (asset.disposedDate != null) ...[
              _buildDetailRow(
                'Disposal Date',
                DateFormat('dd MMM yyyy').format(asset.disposedDate!),
              ),
              _buildDetailRow(
                'Disposal Amount',
                formatAmount(asset.disposalAmount ?? 0),
              ),
            ],
            if (asset.notes.isNotEmpty) _buildDetailRow('Notes', asset.notes),
            _buildDetailRow(
              'Last Depreciation',
              asset.lastDepreciationDate != null
                  ? DateFormat(
                      'dd MMM yyyy',
                    ).format(asset.lastDepreciationDate!)
                  : 'N/A',
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                if (asset.status == 'Active')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        depreciateAsset(asset);
                      },
                      icon: Icon(Icons.calculate, size: 4.5.w),
                      label: Text(
                        'Depreciate',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                if (asset.status == 'Active') SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      showEditAssetDialog(asset);
                    },
                    icon: Icon(Icons.edit, size: 4.5.w),
                    label: Text('Edit', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                if (asset.status != 'Disposed') SizedBox(width: 3.w),
                if (asset.status != 'Disposed')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        showDisposeAssetDialog(asset);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        size: 4.5.w,
                        color: Colors.white,
                      ),
                      label: Text('Dispose', style: TextStyle(fontSize: 12.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDanger,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: kText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getAssetCategoryColor(String category) {
    switch (category) {
      case 'Building':
        return const Color(0xFF9B59B6);
      case 'Vehicle':
        return const Color(0xFF3498DB);
      case 'IT Equipment':
        return const Color(0xFF2ECC71);
      case 'Furniture':
        return const Color(0xFFE67E22);
      case 'Machinery':
        return const Color(0xFFE74C3C);
      default:
        return kPrimary;
    }
  }

  IconData getAssetIcon(String category) {
    switch (category) {
      case 'Building':
        return Icons.business;
      case 'Vehicle':
        return Icons.directions_car;
      case 'IT Equipment':
        return Icons.computer;
      case 'Furniture':
        return Icons.chair;
      case 'Machinery':
        return Icons.settings;
      default:
        return Icons.inventory;
    }
  }

  void _showError(String message) {
    AppSnackbar.error(kWarning, 'Error', message);
  }
}
