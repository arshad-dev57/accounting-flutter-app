// lib/core/warehouse/goods_receiving/controller/goods_receiving_controller.dart

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/goodsRecieving/goods_receiving_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class GoodsReceivingController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<GoodsReceivingModel> grns = <GoodsReceivingModel>[].obs;
  final RxList<GoodsReceivingModel> filteredGrns = <GoodsReceivingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<GoodsReceivingModel?> selectedGRN = Rx<GoodsReceivingModel?>(null);

  // ─── PAGINATION ──────────────────────────────────────────────
  final RxInt currentPage = 1.obs;
  final RxInt pageLimit = 10.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNext = false.obs;
  final RxBool hasPrev = false.obs;
  final RxBool hasMore = false.obs;
  final RxBool isLoadingMore = false.obs;

  // ─── FILTERS ──────────────────────────────────────────────────
  final RxString searchFilter = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = ['all', 'Draft', 'Partially Received', 'Fully Received'];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<GoodsReceivingStats> stats = GoodsReceivingStats(
    todayCount: 0,
    monthCount: 0,
    draftCount: 0,
    partiallyReceivedCount: 0,
    fullyReceivedCount: 0,
    totalCount: 0,
  ).obs;

  // ─── CREATE WIZARD STATE ─────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<PurchaseOrderForReceiving> orderSearchResults = <PurchaseOrderForReceiving>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<PurchaseOrderForReceiving?> selectedOrder = Rx<PurchaseOrderForReceiving?>(null);
  final RxList<GRNLineDraft> lineDrafts = <GRNLineDraft>[].obs;

  // ─── CONTROLLERS ─────────────────────────────────────────────
  final orderSearchController = TextEditingController();
  final receivingDateController = TextEditingController();
  final receivedByController = TextEditingController();
  final notesController = TextEditingController();

  // ─── SELECTED DATES ──────────────────────────────────────────
  final Rx<DateTime?> selectedReceivingDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🟢 [GoodsReceivingController] onInit called');
    selectedReceivingDate.value = DateTime.now();
    receivingDateController.text = DateFormat('dd MMM yyyy').format(selectedReceivingDate.value!);
    fetchGRNs();
  }

  @override
  void onClose() {
    print('🟢 [GoodsReceivingController] onClose called - disposing controllers');
    orderSearchController.dispose();
    receivingDateController.dispose();
    receivedByController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  int get totalReceivingQuantity {
    return lineDrafts.fold(0, (sum, line) => sum + line.receivingQuantity);
  }

  bool get canConfirmReceiving {
    return lineDrafts.any((line) => line.receivingQuantity > 0) && 
           selectedOrder.value != null;
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH GRNS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchGRNs({bool resetPage = false}) async {
    print('🔵 [GoodsReceivingController] fetchGRNs called');
    print('🔵 [GoodsReceivingController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}');
    print('🔵 [GoodsReceivingController] Reset Page: $resetPage');
    
    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print('🔵 [GoodsReceivingController] Search filter: ${searchFilter.value}');
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print('🔵 [GoodsReceivingController] Status filter: ${statusFilter.value}');
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [GoodsReceivingController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [GoodsReceivingController] To date: ${params['toDate']}');
      }

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🔵 [GoodsReceivingController] API Request: GET /api/purchase/goods-receiving?$query');

      final response = await _api.get('/api/purchase/goods-receiving?$query', requiresAuth: true);

      print('🔵 [GoodsReceivingController] Response Status: ${response.statusCode}');
      print('🔵 [GoodsReceivingController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [GoodsReceivingController] Data length: ${list.length}');
        
        grns.value = list
            .map((e) => GoodsReceivingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = GoodsReceivingStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
          print('🔵 [GoodsReceivingController] Stats: ${stats.value}');
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
          pageLimit.value = (pagination['limit'] as num?)?.toInt() ?? 10;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
          hasNext.value = pagination['hasNext'] == true;
          hasPrev.value = pagination['hasPrev'] == true;
          hasMore.value = pagination['hasNext'] == true;
          
          print('✅ [GoodsReceivingController] GRNs fetched successfully: ${grns.length} GRNs');
          print('✅ [GoodsReceivingController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}');
        }
      } else {
        print('❌ [GoodsReceivingController] Failed to fetch GRNs');
        print('❌ [GoodsReceivingController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load goods receivings');
      }
    } catch (e) {
      print('❌ [GoodsReceivingController] fetchGRNs error: $e');
      print('❌ [GoodsReceivingController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print('🔵 [GoodsReceivingController] fetchGRNs completed, isLoading: ${isLoading.value}');
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [GoodsReceivingController] applyLocalFilters called');
    print('🟣 [GoodsReceivingController] Selected filter: ${selectedFilter.value}');
    print('🟣 [GoodsReceivingController] Search filter: ${searchFilter.value}');
    
    final list = grns.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' && item.status != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches = item.grnNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.purchaseOrderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
    
    print('🟣 [GoodsReceivingController] Filtered GRNs: ${filtered.length} out of ${list.length}');
    filteredGrns.value = filtered;
  }

  void filterGRNs(String filter) {
    print('🟣 [GoodsReceivingController] filterGRNs called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchGRNs(String query) {
    print('🟣 [GoodsReceivingController] searchGRNs called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [GoodsReceivingController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchGRNs(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreGRNs() async {
    print('🟡 [GoodsReceivingController] fetchMoreGRNs called');
    print('🟡 [GoodsReceivingController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}');
    
    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [GoodsReceivingController] Skipping load more');
      return;
    }
    
    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [GoodsReceivingController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🟡 [GoodsReceivingController] API Request: GET /api/purchase/goods-receiving?$query');

      final response = await _api.get('/api/purchase/goods-receiving?$query', requiresAuth: true);

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newGRNs = list
            .map((e) => GoodsReceivingModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        print('🟡 [GoodsReceivingController] Loaded ${newGRNs.length} more GRNs');
        grns.addAll(newGRNs);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print('🟡 [GoodsReceivingController] Total GRNs now: ${grns.length}, hasMore: ${hasMore.value}');
      } else {
        print('❌ [GoodsReceivingController] Failed to load more GRNs');
      }
    } catch (e) {
      print('❌ [GoodsReceivingController] fetchMoreGRNs error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [GoodsReceivingController] fetchMoreGRNs completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshGRNs() {
    print('🟢 [GoodsReceivingController] refreshGRNs called');
    return fetchGRNs(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [GoodsReceivingController] applyFilters called');
    fetchGRNs(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [GoodsReceivingController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    print('🟢 [GoodsReceivingController] showCreateWizard: ${showCreateWizard.value}');
  }

  void closeCreateWizard() {
    print('🟢 [GoodsReceivingController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print('🟢 [GoodsReceivingController] showCreateWizard: ${showCreateWizard.value}');
  }

  void _resetWizard() {
    print('🟢 [GoodsReceivingController] _resetWizard called');
    wizardStep.value = 0;
    selectedOrder.value = null;
    orderSearchResults.clear();
    lineDrafts.clear();
    orderSearchController.clear();
    receivedByController.clear();
    notesController.clear();
    selectedReceivingDate.value = DateTime.now();
    receivingDateController.text = DateFormat('dd MMM yyyy').format(selectedReceivingDate.value!);
    print('✅ [GoodsReceivingController] Wizard reset complete');
  }

  // ─── ORDER SEARCH ─────────────────────────────────────────────

  Future<void> searchOrders(String query) async {
    print('🔵 [GoodsReceivingController] searchOrders called with: "$query"');
    
    if (query.trim().length < 2) {
      print('🔵 [GoodsReceivingController] Query too short, clearing results');
      orderSearchResults.clear();
      return;
    }
    
    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print('🔵 [GoodsReceivingController] API Request: GET /api/purchase/goods-receiving/available-orders?search=$encoded&limit=10');
      
      final response = await _api.get(
        '/api/purchase/goods-receiving/available-orders?search=$encoded&limit=10',
        requiresAuth: true,
      );
      
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => PurchaseOrderForReceiving.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print('🔵 [GoodsReceivingController] Found ${orderSearchResults.length} orders for query: $query');
      } else {
        print('❌ [GoodsReceivingController] No orders found');
        orderSearchResults.clear();
      }
    } catch (e) {
      print('❌ [GoodsReceivingController] searchOrders error: $e');
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
      print('🔵 [GoodsReceivingController] searchOrders completed');
    }
  }

  void selectOrderForReceiving(PurchaseOrderForReceiving order) {
    print('🔵 [GoodsReceivingController] selectOrderForReceiving called');
    print('🔵 [GoodsReceivingController] Selected order: ${order.orderNumber} - ${order.supplierName}');
    
    selectedOrder.value = order;
    orderSearchResults.clear();
    orderSearchController.text = order.orderNumber ?? '';
    
    // Create line drafts from order items
    lineDrafts.value = order.remainingItems.map((item) {
      return GRNLineDraft(
        purchaseOrderItemId: item.id,
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        orderedQuantity: item.quantity,
        remainingQuantity: item.remainingQuantity,
        alreadyReceived: item.alreadyReceived,
        receivingQuantity: 0,
        unit: item.unit,
      );
    }).toList();
    
    print('🔵 [GoodsReceivingController] Created ${lineDrafts.length} line drafts for order');
  }

  // ─── DATE SELECTION ──────────────────────────────────────────

  void selectReceivingDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedReceivingDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      selectedReceivingDate.value = date;
      receivingDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  // ─── WIZARD NAVIGATION ──────────────────────────────────────

  bool canGoToStep2() {
    final canGo = selectedOrder.value != null;
    print('🔵 [GoodsReceivingController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any((line) => line.receivingQuantity > 0);
    print('🔵 [GoodsReceivingController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print('🟡 [GoodsReceivingController] nextStep called, current step: ${wizardStep.value}');
    
    if (wizardStep.value == 0 && !canGoToStep2()) {
      print('❌ [GoodsReceivingController] Cannot go to step 2 - no order selected');
      Get.snackbar('Validation', 'Select a purchase order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print('❌ [GoodsReceivingController] Cannot go to step 3 - no items selected');
      Get.snackbar('Validation', 'Enter receiving quantity for at least one item');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print('🟡 [GoodsReceivingController] Step changed to: ${wizardStep.value}');
    }
  }

  void previousStep() {
    print('🟡 [GoodsReceivingController] previousStep called, current step: ${wizardStep.value}');
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print('🟡 [GoodsReceivingController] Step changed to: ${wizardStep.value}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE GRN
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createGRN() async {
    print('🔵 [GoodsReceivingController] createGRN called');
    
    final order = selectedOrder.value;
    if (order == null) {
      print('❌ [GoodsReceivingController] No order selected');
      return false;
    }

    final receivingDate = selectedReceivingDate.value;
    if (receivingDate == null) {
      print('❌ [GoodsReceivingController] No receiving date selected');
      Get.snackbar('Validation', 'Please select receiving date');
      return false;
    }

    final selectedItems = lineDrafts.where((line) => line.receivingQuantity > 0).toList();
    if (selectedItems.isEmpty) {
      print('❌ [GoodsReceivingController] No items selected for receiving');
      Get.snackbar('Validation', 'Enter receiving quantity for at least one item');
      return false;
    }

    try {
      isSubmitting.value = true;
      
      final items = selectedItems.map((line) => ({
        'purchaseOrderItemId': line.purchaseOrderItemId,
        'receivingQuantity': line.receivingQuantity,
        'notes': null,
      })).toList();

      final payload = {
        'purchaseOrderId': order.id,
        'receivingDate': receivingDate.toIso8601String().split('T').first,
        'receivedBy': receivedByController.text.trim().isEmpty 
            ? null 
            : receivedByController.text.trim(),
        'notes': notesController.text.trim().isEmpty 
            ? null 
            : notesController.text.trim(),
        'items': items,
        'status': 'Draft',
      };

      print('🔵 [GoodsReceivingController] Submitting GRN payload');
      print('🔵 [GoodsReceivingController] Order: ${order.orderNumber}, Items: ${items.length}');

      final response = await _api.post(
        '/api/purchase/goods-receiving',
        body: payload,
        requiresAuth: true,
      );

      print('🔵 [GoodsReceivingController] Response Status: ${response.statusCode}');
      print('🔵 [GoodsReceivingController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [GoodsReceivingController] GRN created successfully!');
        Get.snackbar('Success', 'Goods receiving created successfully');
        closeCreateWizard();
        await fetchGRNs(resetPage: true);
        return true;
      }
      
      print('❌ [GoodsReceivingController] Failed to create GRN: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to create goods receiving');
      return false;
    } catch (e) {
      print('❌ [GoodsReceivingController] createGRN error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GRN ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void selectGRN(GoodsReceivingModel grn) {
    print('🔵 [GoodsReceivingController] selectGRN called for: ${grn.grnNumber}');
    selectedGRN.value = grn;
  }

  Future<bool> confirmGRN(String id) async {
    print('🟣 [GoodsReceivingController] confirmGRN called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/goods-receiving/$id/confirm',
        body: {},
        requiresAuth: true,
      );

      print('🟣 [GoodsReceivingController] Response Status: ${response.statusCode}');
      print('🟣 [GoodsReceivingController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [GoodsReceivingController] GRN confirmed and inventory updated');
        Get.snackbar('Success', 'Goods receiving confirmed and inventory updated');
        await fetchGRNs();
        return true;
      }
      
      print('❌ [GoodsReceivingController] Failed to confirm GRN: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to confirm goods receiving');
      return false;
    } catch (e) {
      print('❌ [GoodsReceivingController] confirmGRN error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteGRN(String id) async {
    print('🔵 [GoodsReceivingController] deleteGRN called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/goods-receiving/$id',
        requiresAuth: true,
      );

      print('🔵 [GoodsReceivingController] Response Status: ${response.statusCode}');
      print('🔵 [GoodsReceivingController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [GoodsReceivingController] GRN deleted successfully');
        Get.snackbar('Success', 'Goods receiving deleted successfully');
        await fetchGRNs(resetPage: true);
        return true;
      }
      
      print('❌ [GoodsReceivingController] Failed to delete GRN: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to delete goods receiving');
      return false;
    } catch (e) {
      print('❌ [GoodsReceivingController] deleteGRN error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<GoodsReceivingModel?> getGRNById(String id) async {
    print('🔵 [GoodsReceivingController] getGRNById called for ID: $id');
    
    try {
      final response = await _api.get(
        '/api/purchase/goods-receiving/$id',
        requiresAuth: true,
      );

      print('🔵 [GoodsReceivingController] Response Status: ${response.statusCode}');
      print('🔵 [GoodsReceivingController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final grn = GoodsReceivingModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print('✅ [GoodsReceivingController] GRN found: ${grn.grnNumber}');
        return grn;
      }
      print('❌ [GoodsReceivingController] GRN not found');
      return null;
    } catch (e) {
      print('❌ [GoodsReceivingController] getGRNById error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: GET STATUS COLOR
  // ═══════════════════════════════════════════════════════════════

  Color getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Partially Received':
        return Colors.blue;
      case 'Fully Received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'Draft':
        return 'Draft';
      case 'Partially Received':
        return 'Partial';
      case 'Fully Received':
        return 'Fully Received';
      default:
        return status;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: FORMAT CURRENCY
  // ═══════════════════════════════════════════════════════════════

  String formatCurrency(double amount) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(amount);
  }
}

// ═══════════════════════════════════════════════════════════════
// GRN LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class GRNLineDraft {
  String purchaseOrderItemId;
  String productId;
  String productName;
  String sku;
  int orderedQuantity;
  int remainingQuantity;
  int alreadyReceived;
  int receivingQuantity;
  String unit;

  GRNLineDraft({
    required this.purchaseOrderItemId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.orderedQuantity,
    required this.remainingQuantity,
    required this.alreadyReceived,
    required this.receivingQuantity,
    required this.unit,
  });

  bool get isFullyReceived => remainingQuantity == 0;
  bool get hasRemaining => remainingQuantity > 0;

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderItemId': purchaseOrderItemId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'orderedQuantity': orderedQuantity,
      'remainingQuantity': remainingQuantity,
      'alreadyReceived': alreadyReceived,
      'receivingQuantity': receivingQuantity,
      'unit': unit,
    };
  }
}