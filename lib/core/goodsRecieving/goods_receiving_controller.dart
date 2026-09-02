// lib/core/warehouse/goods_receiving/controller/goods_receiving_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/goodsRecieving/goods_receiving_model.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
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

  final List<String> filters = [
    'all',
    'Draft',
    'Partially Received',
    'Fully Received',
  ];

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
  final RxList<PurchaseOrderForReceiving> orderSearchResults =
      <PurchaseOrderForReceiving>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<PurchaseOrderForReceiving?> selectedOrder =
      Rx<PurchaseOrderForReceiving?>(null);
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
    selectedReceivingDate.value = DateTime.now();
    receivingDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedReceivingDate.value!);
    fetchGRNs();
  }

  @override
  void onClose() {
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
    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/purchase/goods-receiving?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        grns.value = list
            .map(
              (e) => GoodsReceivingModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = GoodsReceivingStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
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
        }
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to load goods receivings',
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void applyLocalFilters() {
    final list = grns.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          item.status != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.grnNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.purchaseOrderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredGrns.value = filtered;
  }

  void filterGRNs(String filter) {
    selectedFilter.value = filter;
    statusFilter.value = filter;
    fetchGRNs(resetPage: true);
  }

  void searchGRNs(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchGRNs(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreGRNs() async {
    if (!hasMore.value || isLoadingMore.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/purchase/goods-receiving?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newGRNs = list
            .map(
              (e) => GoodsReceivingModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        grns.addAll(newGRNs);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      } else {}
    } catch (e) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshGRNs() {
    return fetchGRNs(resetPage: true);
  }

  void applyFilters() {
    fetchGRNs(resetPage: true);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    _resetWizard();
    showCreateWizard.value = true;
    searchOrders('');
  }

  void closeCreateWizard() {
    showCreateWizard.value = false;
    _resetWizard();
  }

  void _resetWizard() {
    wizardStep.value = 0;
    selectedOrder.value = null;
    orderSearchResults.clear();
    lineDrafts.clear();
    orderSearchController.clear();
    receivedByController.clear();
    notesController.clear();
    selectedReceivingDate.value = DateTime.now();
    receivingDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedReceivingDate.value!);
  }

  // ─── ORDER SEARCH ─────────────────────────────────────────────

  Future<void> searchOrders(String query) async {

    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/purchase/goods-receiving/available-orders?search=$encoded&limit=20',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map(
              (e) => PurchaseOrderForReceiving.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      } else {
        orderSearchResults.clear();
      }
    } catch (e) {
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
    }
  }

  void selectOrderForReceiving(PurchaseOrderForReceiving order) {
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
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any((line) => line.receivingQuantity > 0);
    return canGo;
  }

  void nextStep() {
    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select a purchase order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar(
        'Validation',
        'Enter receiving quantity for at least one item',
      );
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
    }
  }

  void previousStep() {
    if (wizardStep.value > 0) {
      wizardStep.value--;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE GRN
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createGRN() async {

    final order = selectedOrder.value;
    if (order == null) {
      return false;
    }

    final receivingDate = selectedReceivingDate.value;
    if (receivingDate == null) {
      Get.snackbar('Validation', 'Please select receiving date');
      return false;
    }

    final selectedItems = lineDrafts
        .where((line) => line.receivingQuantity > 0)
        .toList();
    if (selectedItems.isEmpty) {
      Get.snackbar(
        'Validation',
        'Enter receiving quantity for at least one item',
      );
      return false;
    }

    try {
      isSubmitting.value = true;

      final items = selectedItems
          .map(
            (line) => ({
              'purchaseOrderItemId': line.purchaseOrderItemId,
              'receivingQuantity': line.receivingQuantity,
              'notes': null,
            }),
          )
          .toList();

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
        if (Get.isRegistered<LocationController>() &&
            (Get.find<LocationController>().selectedLocationId?.isNotEmpty ??
                false))
          'locationId': Get.find<LocationController>().selectedLocationId,
      };

      final response = await _api.post(
        '/api/purchase/goods-receiving',
        body: payload,
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Goods receiving created successfully');
        closeCreateWizard();
        await fetchGRNs(resetPage: true);
        return true;
      }

      Get.snackbar(
        'Error',
        response.message ?? 'Failed to create goods receiving',
      );
      return false;
    } catch (e) {
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
    selectedGRN.value = grn;
  }

  Future<bool> confirmGRN(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/purchase/goods-receiving/$id/confirm',
        body: {},
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar(
          'Success',
          'Goods receiving confirmed and inventory updated',
        );
        await fetchGRNs();
        return true;
      }

      Get.snackbar(
        'Error',
        response.message ?? 'Failed to confirm goods receiving',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteGRN(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/purchase/goods-receiving/$id',
        requiresAuth: true,
      );

      if (response.success) {
        Get.snackbar('Success', 'Goods receiving deleted successfully');
        await fetchGRNs(resetPage: true);
        return true;
      }

      Get.snackbar(
        'Error',
        response.message ?? 'Failed to delete goods receiving',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<GoodsReceivingModel?> getGRNById(String id) async {

    try {
      final response = await _api.get(
        '/api/purchase/goods-receiving/$id',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final grn = GoodsReceivingModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        return grn;
      }
      return null;
    } catch (e) {
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
