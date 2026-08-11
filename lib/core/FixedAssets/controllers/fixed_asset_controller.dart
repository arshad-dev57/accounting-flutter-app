// core/FixedAssets/controllers/fixed_asset_controller.dart
// COMPLETE CONTROLLER WITH LAZY LOADING, PAGINATION & ALL DIALOGS

import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'dart:io';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:BisonsTechs_app/core/FixedAssets/models/fixed_asset_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class FixedAssetController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  var allAssets = <FixedAsset>[].obs;
  var assets = <FixedAsset>[].obs;
  var vendors = <Map<String, dynamic>>[].obs;
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
  var assetSaved = false.obs;
  var assetUpdated = false.obs;
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

  // Text editing controller & Scroll controller
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    loadFixedAssets(resetPage: true);
    loadVendors();
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
    loadFixedAssets(resetPage: true);
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  String _formatAmountSimple(double amount) => CurrencyUtils.format(amount);

  // ─── LOAD FIXED ASSETS WITH PAGINATION ──────────────────────────
  Future<void> loadFixedAssets({bool resetPage = true}) async {
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

          if (resetPage) {
            allAssets.value = newAssets;
            assets.value = newAssets;
          } else {
            allAssets.addAll(newAssets);
            assets.addAll(newAssets);
          }

          // Parse pagination info
          if (responseData['pagination'] != null) {
            final pagination = responseData['pagination'];
            totalPages.value =
                pagination['pages'] ?? pagination['totalPages'] ?? 1;
            totalItems.value =
                pagination['total'] ??
                pagination['totalItems'] ??
                newAssets.length;
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
            totalItems.value = assets.length;
            totalPages.value = (totalItems.value / itemsPerPage.value).ceil();
            hasNextPage.value =
                (currentPage.value * itemsPerPage.value) < totalItems.value;
            hasPrevPage.value = currentPage.value > 1;
            serverSupportsPagination.value = false;
          }

          _updateSummaryForFiltered(assets.value);
          assets.refresh();
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
      isLoadingMore.value = false;
    }
  }

  // ─── LOAD MORE DATA (LAZY LOADING) ──────────────────────────────
  Future<void> loadMoreData() async {
    if (hasNextPage.value && !isLoadingMore.value && !isLoading.value) {
      currentPage.value++;
      await loadFixedAssets(resetPage: false);
    }
  }

  // ─── LOAD VENDORS ──────────────────────────────────────────────
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

  Future<void> loadBankAccounts() async {
    try {
      final response = await _apiClient.get('/api/bank-accounts');
      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        final list = responseData['data'] ?? responseData;
        if (list is List) {
          bankAccounts.value = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((a) => (a['status'] ?? 'Active') == 'Active')
              .toList();
        }
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    }
  }

  // ─── LOAD SUMMARY ──────────────────────────────────────────────
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

  // ─── SEARCH ──────────────────────────────────────────────────────
  void searchAssets(String query) {
    searchQuery.value = query;
    loadFixedAssets(resetPage: true);
  }

  // ─── FILTER ──────────────────────────────────────────────────────
  void applyFilter(String filter) {
    selectedFilter.value = filter;
    loadFixedAssets(resetPage: true);
  }

  // ─── CREATE FIXED ASSET ──────────────────────────────────────────
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
    String acquisitionType = 'purchase',
    String paymentMethod = 'Cash',
    String? bankAccountId,
    double openingAccumulatedDepreciation = 0,
  }) async {
    try {
      isProcessing.value = true;
      assetSaved.value = false; // reset

      if (acquisitionType == 'purchase' &&
          paymentMethod == 'Bank' &&
          (bankAccountId == null || bankAccountId.isEmpty)) {
        _showError('Please select a bank account');
        return;
      }
      if (acquisitionType == 'purchase' &&
          paymentMethod == 'Credit' &&
          (supplierId == null || supplierId.isEmpty || supplierId == 'null')) {
        _showError('Supplier is required for credit purchases');
        return;
      }

      final Map<String, dynamic> assetData = {
        'name': name,
        'category': category,
        'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
        'purchaseCost': purchaseCost,
        'usefulLife': usefulLife,
        'salvageValue': salvageValue,
        'location': location,
        'notes': notes ?? '',
        'acquisitionType': acquisitionType,
        'paymentMethod':
            acquisitionType == 'opening_balance' ? 'Opening Balance' : paymentMethod,
        'openingAccumulatedDepreciation':
            acquisitionType == 'opening_balance' ? openingAccumulatedDepreciation : 0,
      };

      if (supplierId != null && supplierId.isNotEmpty && supplierId != 'null') {
        assetData['supplierId'] = supplierId;
      }

      if (paymentMethod == 'Bank' &&
          bankAccountId != null &&
          bankAccountId.isNotEmpty) {
        assetData['bankAccountId'] = bankAccountId;
      }

      if (warrantyExpiry != null) {
        assetData['warrantyExpiry'] = DateFormat(
          'yyyy-MM-dd',
        ).format(warrantyExpiry);
      }

      final response = await _apiClient.post(
        '/api/fixed-assets',
        body: assetData,
      );

      if (response.success &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        final responseData = response.data;
        if (responseData['success'] == true || responseData['data'] != null) {
          await loadFixedAssets(resetPage: true);
          await loadSummary();
          assetSaved.value = true; // ✅ signal dialog ko
          AppSnackbar.success(
            kSuccess,
            'Success',
            'Fixed asset added successfully',
            duration: const Duration(seconds: 3),
          );
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

  // ─── UPDATE FIXED ASSET ──────────────────────────────────────────
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
      assetUpdated.value = false; // reset

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

      if (supplierId != null && supplierId.isNotEmpty && supplierId != 'null') {
        assetData['supplierId'] = supplierId;
      }

      if (warrantyExpiry != null) {
        assetData['warrantyExpiry'] = DateFormat(
          'yyyy-MM-dd',
        ).format(warrantyExpiry);
      }

      final response = await _apiClient.put(
        '/api/fixed-assets/$id',
        body: assetData,
      );

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          await loadFixedAssets(resetPage: true);
          await loadSummary();
          assetUpdated.value = true; // ✅ signal dialog ko
          AppSnackbar.success(
            kSuccess,
            'Success ✅',
            'Fixed asset updated successfully',
            duration: const Duration(seconds: 3),
          );
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

  // ─── DEPRECIATE ASSET ────────────────────────────────────────────
  Future<void> depreciateAsset(FixedAsset asset) async {
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
                  'Processing depreciation...',
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

      final Map<String, dynamic> depData = {
        'assetId': asset.id,
        'depreciationDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final response = await _apiClient.post(
        '/api/fixed-assets/depreciate',
        body: depData,
      );

      // Close loading dialog
      Get.back();

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
          await loadFixedAssets(resetPage: true);
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to depreciate asset');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to depreciate asset');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error depreciating asset: $e');
      _showError('Error depreciating asset');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── RUN MONTHLY DEPRECIATION ──────────────────────────────────
  Future<void> runMonthlyDepreciation() async {
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
                  'Running monthly depreciation...',
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

      final Map<String, dynamic> depData = {
        'depreciationDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final response = await _apiClient.post(
        '/api/fixed-assets/depreciate-all',
        body: depData,
      );

      // Close loading dialog
      Get.back();

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
          await loadFixedAssets(resetPage: true);
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to run depreciation');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to run depreciation');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error running monthly depreciation: $e');
      _showError('Error running monthly depreciation');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── DISPOSE ASSET ──────────────────────────────────────────────
  Future<void> disposeAsset({
    required String assetId,
    required DateTime disposalDate,
    required double disposalAmount,
    required String disposalReason,
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
                  'Disposing asset...',
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

      final Map<String, dynamic> disposeData = {
        'assetId': assetId,
        'disposalDate': DateFormat('yyyy-MM-dd').format(disposalDate),
        'disposalAmount': disposalAmount,
        'disposalReason': disposalReason,
      };

      final response = await _apiClient.post(
        '/api/fixed-assets/dispose',
        body: disposeData,
      );

      // Close loading dialog
      Get.back();

      if (response.success && response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          final gainLoss = data['asset']['gainLoss'];

          final message = gainLoss >= 0
              ? 'Asset disposed with gain of ${formatAmount(gainLoss)}'
              : 'Asset disposed with loss of ${formatAmount(gainLoss.abs())}';

          AppSnackbar.success(
            gainLoss >= 0 ? kSuccess : kWarning,
            'Asset Disposed',
            message,
            duration: const Duration(seconds: 3),
          );
          await loadFixedAssets(resetPage: true);
          await loadSummary();
        } else {
          _showError(responseData['message'] ?? 'Failed to dispose asset');
        }
      } else {
        _showError(response.data['message'] ?? 'Failed to dispose asset');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error disposing asset: $e');
      _showError('Error disposing asset');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── DELETE FIXED ASSET ──────────────────────────────────────────
  Future<void> deleteFixedAsset(String id, String name) async {
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
                  'Deleting asset...',
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

      final response = await _apiClient.delete('/api/fixed-assets/$id');

      // Close loading dialog
      Get.back();

      if (response.success && response.statusCode == 200) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fixed asset $name deleted successfully',
          duration: const Duration(seconds: 2),
        );
        await loadFixedAssets(resetPage: true);
        await loadSummary();
      } else {
        _showError(response.data['message'] ?? 'Failed to delete asset');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Error deleting fixed asset: $e');
      _showError('Error deleting fixed asset');
    } finally {
      isProcessing.value = false;
    }
  }

  // ─── EXPORT FUNCTIONS ────────────────────────────────────────────
  void exportAssets() {
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
                  'Export Assets',
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
              '${assets.length} assets will be exported',
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
            reportTitle: 'Fixed Assets Report',
          ),
          footer: (ctx) => branding.buildFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(branding.accent),
            pw.SizedBox(height: 16),
            _pdfAssetsTable(),
            pw.SizedBox(height: 16),
            _pdfCategoryBreakdown(),
            branding.buildSignatureBlock(),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName =
          'fixed_assets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'PDF exported successfully');
      await OpenFile.open(file.path);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
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
        _excelSetCell(assetsSheet, row, 3, asset.status, bgColor: bg);
        _excelSetCell(
          assetsSheet,
          row,
          4,
          DateFormat('dd MMM yyyy').format(asset.purchaseDate),
          bgColor: bg,
        );
        _excelSetCell(assetsSheet, row, 5, asset.purchaseCost, bgColor: bg);
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
        );
        _excelSetCell(assetsSheet, row, 11, asset.netBookValue, bgColor: bg);
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
        );
        _excelSetCell(
          categorySheet,
          catRow,
          3,
          categoryNBV[category]!,
          bgColor: bg,
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

      final dir = await getTemporaryDirectory();
      final fileName =
          'fixed_assets_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'Excel exported successfully');
      await OpenFile.open(file.path);
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

  // ─── PDF HELPERS ──────────────────────────────────────────────────


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
            'Total Assets',
            totalAssets.value.toString(),
            accent,
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
                flex: 1,
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
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        asset.name,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        asset.category,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        asset.status,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.purchaseCost),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.accumulatedDepreciation),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        _formatAmountSimple(asset.netBookValue),
                        textAlign: pw.TextAlign.right,
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
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  _formatAmountSimple(totalDepreciation.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  _formatAmountSimple(totalNetBookValue.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                  child: pw.Text(category, style: pw.TextStyle(fontSize: 10)),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    count.toString(),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _formatAmountSimple(categoryCost[category]!),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _formatAmountSimple(categoryNBV[category]!),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
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
    String acquisitionType = 'purchase'; // purchase | opening_balance
    String paymentMethod = 'Cash'; // Cash | Bank | Credit
    String? selectedBankAccountId;
    double openingAccumulatedDepreciation = 0;

    assetSaved.value = false; // reset before opening

    // ✅ listener jo dialog close karega
    final worker = ever(assetSaved, (bool saved) {
      if (saved) {
        if (Get.isDialogOpen ?? false) Get.back();
      }
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.92,
            maxWidth: 500,
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
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
                              'Add Fixed Asset',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add a new fixed asset',
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
                                worker.dispose(); // ✅ worker dispose
                                Get.back();
                              },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Asset Name *',
                              hint: 'e.g., Office Building',
                              onChanged: (v) => name = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Category *',
                              value: category,
                              items: const [
                                'Building',
                                'Vehicle',
                                'IT Equipment',
                                'Furniture',
                                'Machinery',
                                'Equipment',
                              ],
                              onChanged: (v) => setState(() => category = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Acquisition Type *',
                              value: acquisitionType == 'opening_balance'
                                  ? 'Opening Balance / Existing'
                                  : 'New Purchase',
                              items: const [
                                'New Purchase',
                                'Opening Balance / Existing',
                              ],
                              onChanged: (v) {
                                setState(() {
                                  acquisitionType =
                                      v == 'Opening Balance / Existing'
                                          ? 'opening_balance'
                                          : 'purchase';
                                  if (acquisitionType == 'opening_balance') {
                                    paymentMethod = 'Cash';
                                    selectedBankAccountId = null;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (acquisitionType == 'purchase') ...[
                              _buildDropdownField(
                                label: 'Payment Method *',
                                value: paymentMethod,
                                items: const ['Cash', 'Bank', 'Credit'],
                                onChanged: (v) {
                                  setState(() {
                                    paymentMethod = v!;
                                    if (paymentMethod != 'Bank') {
                                      selectedBankAccountId = null;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (paymentMethod == 'Bank') ...[
                                _buildBankAccountDropdownField(
                                  selectedBankAccountId,
                                  (v) => setState(
                                    () => selectedBankAccountId = v,
                                  ),
                                  bankAccounts.toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                            if (acquisitionType == 'opening_balance') ...[
                              _buildTextField(
                                label: 'Opening Accumulated Depreciation',
                                hint: '0.00',
                                prefixText: CurrencyUtils.prefix,
                                onChanged: (v) =>
                                    openingAccumulatedDepreciation =
                                        double.tryParse(v) ?? 0,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildDatePickerField(
                              acquisitionType == 'opening_balance'
                                  ? 'Acquisition Date *'
                                  : 'Purchase Date *',
                              purchaseDate,
                              (d) => setState(() => purchaseDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Purchase Cost *',
                              hint: '0.00',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  purchaseCost = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Useful Life (years) *',
                              hint: '5',
                              onChanged: (v) =>
                                  usefulLife = int.tryParse(v) ?? 5,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Salvage Value',
                              hint: '0.00',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) =>
                                  salvageValue = double.tryParse(v) ?? 0,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Location',
                              hint: 'e.g., Main Office',
                              onChanged: (v) => location = v,
                            ),
                            const SizedBox(height: 16),
                            _buildSupplierDropdownField(
                              selectedSupplierId,
                              (v) => setState(() => selectedSupplierId = v),
                              vendors.toList(),
                            ),
                            if (paymentMethod == 'Credit')
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Supplier is required for credit purchases',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              'Warranty Expiry',
                              warrantyExpiry ??
                                  DateTime.now().add(const Duration(days: 365)),
                              (d) => setState(() => warrantyExpiry = d),
                              context,
                              optional: true,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing.value
                              ? null
                              : () {
                                  worker.dispose(); // ✅ worker dispose
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
                                        acquisitionType: acquisitionType,
                                        paymentMethod: paymentMethod,
                                        bankAccountId: selectedBankAccountId,
                                        openingAccumulatedDepreciation:
                                            openingAccumulatedDepreciation,
                                      );
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
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Add Asset',
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
                ],
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) => worker.dispose()); // ✅ dialog close hone par bhi dispose
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

    if (asset.supplier.isNotEmpty) {
      final vendor = vendors.firstWhere(
        (v) => v['name'] == asset.supplier,
        orElse: () => {},
      );
      if (vendor.isNotEmpty) {
        selectedSupplierId = vendor['_id'].toString();
      }
    }

    assetUpdated.value = false; // reset before opening

    // ✅ listener jo dialog close karega
    final worker = ever(assetUpdated, (bool updated) {
      if (updated) {
        if (Get.isDialogOpen ?? false) Get.back();
      }
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.92,
            maxWidth: 500,
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
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
                              'Edit Fixed Asset',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              asset.assetCode,
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Asset Name *',
                              hint: 'e.g., Office Building',
                              initialValue: name,
                              onChanged: (v) => name = v,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Category *',
                              value: category,
                              items: const [
                                'Building',
                                'Vehicle',
                                'IT Equipment',
                                'Furniture',
                                'Machinery',
                                'Equipment',
                              ],
                              onChanged: (v) => setState(() => category = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              'Purchase Date *',
                              purchaseDate,
                              (d) => setState(() => purchaseDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Purchase Cost *',
                              hint: '0.00',
                              prefixText: CurrencyUtils.prefix,
                              initialValue: purchaseCost.toString(),
                              onChanged: (v) =>
                                  purchaseCost = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Useful Life (years) *',
                              hint: '5',
                              initialValue: usefulLife.toString(),
                              onChanged: (v) =>
                                  usefulLife = int.tryParse(v) ?? 5,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Salvage Value',
                              hint: '0.00',
                              prefixText: CurrencyUtils.prefix,
                              initialValue: salvageValue.toString(),
                              onChanged: (v) =>
                                  salvageValue = double.tryParse(v) ?? 0,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Location',
                              hint: 'e.g., Main Office',
                              initialValue: location,
                              onChanged: (v) => location = v,
                            ),
                            const SizedBox(height: 16),
                            _buildSupplierDropdownField(
                              selectedSupplierId,
                              (v) => setState(() => selectedSupplierId = v),
                              vendors.toList(),
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              'Warranty Expiry',
                              warrantyExpiry ??
                                  DateTime.now().add(const Duration(days: 365)),
                              (d) => setState(() => warrantyExpiry = d),
                              context,
                              optional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Notes',
                              hint: 'Additional notes',
                              initialValue: notes,
                              onChanged: (v) => notes = v,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                                      updateFixedAsset(
                                        id: asset.id,
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
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Update Asset',
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
                ],
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) => worker.dispose()); // ✅ dialog close hone par bhi dispose
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
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: 420,
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kDanger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
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
                              'Dispose Asset',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              asset.name,
                              style: TextStyle(fontSize: 12, color: kSubText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: isProcessing.value ? null : () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
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
                              ),
                              child: Column(
                                children: [
                                  _detailRow('Asset', asset.name),
                                  _detailRow('Code', asset.assetCode),
                                  _detailRow(
                                    'Net Book Value',
                                    formatAmount(asset.netBookValue),
                                    valueColor: kDanger,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildDatePickerField(
                              'Disposal Date *',
                              disposalDate,
                              (d) => setState(() => disposalDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Disposal Amount *',
                              hint: asset.netBookValue.toString(),
                              prefixText: CurrencyUtils.prefix,
                              initialValue: disposalAmount.toString(),
                              onChanged: (v) =>
                                  disposalAmount = double.tryParse(v) ?? 0,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Disposal Reason',
                              hint: 'e.g., Sold, Scrapped, Donated',
                              onChanged: (v) => disposalReason = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                                    'Dispose Asset',
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
                ],
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void showAssetDetails(FixedAsset asset) {
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
                              color: getAssetCategoryColor(
                                asset.category,
                              ).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              getAssetIcon(asset.category),
                              size: 26,
                              color: getAssetCategoryColor(asset.category),
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
                                        asset.name,
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
                                        color: asset.status == 'Active'
                                            ? kSuccess.withOpacity(0.08)
                                            : asset.status ==
                                                  'Fully Depreciated'
                                            ? kWarning.withOpacity(0.08)
                                            : kDanger.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        asset.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: asset.status == 'Active'
                                              ? kSuccess
                                              : asset.status ==
                                                    'Fully Depreciated'
                                              ? kWarning
                                              : kDanger,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${asset.assetCode}',
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
                            'Cost',
                            formatAmount(asset.purchaseCost),
                            kPrimary,
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Depreciation',
                            formatAmount(asset.accumulatedDepreciation),
                            kWarning,
                            Icons.trending_down,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'NBV',
                            formatAmount(asset.netBookValue),
                            kSuccess,
                            Icons.account_balance,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow(
                        'Purchase Date',
                        DateFormat('dd MMM yyyy').format(asset.purchaseDate),
                      ),
                      _detailRow('Useful Life', '${asset.usefulLife} years'),
                      _detailRow(
                        'Salvage Value',
                        formatAmount(asset.salvageValue),
                      ),
                      _detailRow(
                        'Depreciation Method',
                        asset.depreciationMethod,
                      ),
                      _detailRow(
                        'Monthly Depreciation',
                        formatAmount(asset.currentDepreciation),
                      ),
                      _detailRow('Location', asset.location),
                      _detailRow('Supplier', asset.supplier),
                      if (asset.warrantyExpiry != null)
                        _detailRow(
                          'Warranty Expiry',
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(asset.warrantyExpiry!),
                        ),
                      if (asset.disposedDate != null) ...[
                        _detailRow(
                          'Disposal Date',
                          DateFormat('dd MMM yyyy').format(asset.disposedDate!),
                        ),
                        _detailRow(
                          'Disposal Amount',
                          formatAmount(asset.disposalAmount ?? 0),
                        ),
                      ],
                      if (asset.notes.isNotEmpty)
                        _detailRow('Notes', asset.notes),
                      _detailRow(
                        'Last Depreciation',
                        asset.lastDepreciationDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(asset.lastDepreciationDate!)
                            : 'N/A',
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Footer Buttons
                      Row(
                        children: [
                          if (asset.status == 'Active') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    depreciateAsset(asset);
                                  },
                                  icon: Icon(
                                    Icons.calculate,
                                    size: 16,
                                    color: kPrimary,
                                  ),
                                  label: Text(
                                    'Depreciate',
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
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showEditAssetDialog(asset);
                                },
                                icon: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: kPrimary,
                                ),
                                label: Text(
                                  'Edit',
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
                          if (asset.status != 'Disposed') ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showDisposeAssetDialog(asset);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Dispose',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kDanger,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildSupplierDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> suppliers,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Supplier (Optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      hint: Text(
        'Select supplier (optional)',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('None')),
        ...suppliers
            .map(
              (s) => DropdownMenuItem<String>(
                value: (s['_id'] ?? s['id']).toString(),
                child: Text(
                  s['name'] ?? 'Unknown',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ],
      onChanged: (v) => onChanged(v),
    );
  }

  Widget _buildBankAccountDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> accounts,
  ) {
    final items = accounts
        .map(
          (a) => DropdownMenuItem<String>(
            value: (a['id'] ?? a['_id']).toString(),
            child: Text(
              '${a['accountName'] ?? a['name'] ?? 'Account'}'
              '${a['bankName'] != null ? ' • ${a['bankName']}' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();

    final validIds = items.map((e) => e.value).whereType<String>().toSet();
    final value =
        selectedId != null && validIds.contains(selectedId) ? selectedId : null;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Bank Account *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      items: items.isEmpty
          ? const [
              DropdownMenuItem(
                value: null,
                child: Text('No bank accounts found'),
              ),
            ]
          : items,
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Bank account is required' : null,
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    void Function(DateTime) onChanged,
    BuildContext context, {
    bool optional = false,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
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
                      color: optional ? kSubText : kSubText,
                      fontWeight: optional ? FontWeight.w400 : FontWeight.w500,
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
