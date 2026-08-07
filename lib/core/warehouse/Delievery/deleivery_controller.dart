// lib/core/warehouse/delivery/controller/delivery_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DeliveryController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<DeliveryModel> deliveries = <DeliveryModel>[].obs;
  final RxList<DeliveryModel> filteredDeliveries = <DeliveryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<DeliveryModel?> selectedDelivery = Rx<DeliveryModel?>(null);

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
    'Pending',
    'Partially Delivered',
    'Delivered',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<DeliveryStats> stats = DeliveryStats(
    total: 0,
    pending: 0,
    partiallyDelivered: 0,
    delivered: 0,
  ).obs;

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const statusOptions = [
    'all',
    'Pending',
    'Partially Delivered',
    'Delivered',
  ];

  // ─── WIZARD STATE ─────────────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<OrderForDelivery> orderSearchResults = <OrderForDelivery>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<OrderForDelivery?> selectedOrder = Rx<OrderForDelivery?>(null);
  final RxList<DeliveryLineDraft> lineDrafts = <DeliveryLineDraft>[].obs;

  final orderSearchController = TextEditingController();
  final deliveryDateController = TextEditingController();
  final deliveryPersonController = TextEditingController();
  final trackingNumberController = TextEditingController();
  final notesController = TextEditingController();

  // ─── DELIVERY DATE ────────────────────────────────────────────
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🟢 [DeliveryController] onInit called');
    fetchDeliveries();
  }

  @override
  void onClose() {
    print('🟢 [DeliveryController] onClose called - disposing controllers');
    orderSearchController.dispose();
    deliveryDateController.dispose();
    deliveryPersonController.dispose();
    trackingNumberController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  int get totalDeliveryQuantity {
    return lineDrafts
        .where((l) => l.selected.value)
        .fold(0, (sum, l) => sum + l.deliveryQuantity.value);
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH DELIVERIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchDeliveries({bool resetPage = false}) async {
    print('🔵 [DeliveryController] fetchDeliveries called');
    print(
      '🔵 [DeliveryController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [DeliveryController] Reset Page: $resetPage');

    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print('🔵 [DeliveryController] Search filter: ${searchFilter.value}');
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print('🔵 [DeliveryController] Status filter: ${statusFilter.value}');
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [DeliveryController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [DeliveryController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print('🔵 [DeliveryController] API Request: GET /api/deliveries?$query');

      final response = await _api.get(
        '/api/deliveries?$query',
        requiresAuth: true,
      );

      print('🔵 [DeliveryController] Response Status: ${response.statusCode}');
      print('🔵 [DeliveryController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [DeliveryController] Data length: ${list.length}');

        deliveries.value = list
            .map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // ✅ Apply local filters
        applyLocalFilters();

        if (response.data['kpi'] != null) {
          stats.value = DeliveryStats.fromJson(
            Map<String, dynamic>.from(response.data['kpi']),
          );
          print('🔵 [DeliveryController] Stats: ${stats.value}');
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

          print(
            '✅ [DeliveryController] Deliveries fetched successfully: ${deliveries.length} deliveries',
          );
          print(
            '✅ [DeliveryController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [DeliveryController] Failed to fetch deliveries');
        print('❌ [DeliveryController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load deliveries');
      }
    } catch (e) {
      print('❌ [DeliveryController] fetchDeliveries error: $e');
      print('❌ [DeliveryController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [DeliveryController] fetchDeliveries completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [DeliveryController] applyLocalFilters called');
    print('🟣 [DeliveryController] Selected filter: ${selectedFilter.value}');
    print('🟣 [DeliveryController] Search filter: ${searchFilter.value}');

    final list = deliveries.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          item.deliveryStatus != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.deliveryNumber.toLowerCase().contains(query) ||
            item.customerName.toLowerCase().contains(query) ||
            item.salesOrderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    print(
      '🟣 [DeliveryController] Filtered deliveries: ${filtered.length} out of ${list.length}',
    );
    filteredDeliveries.value = filtered;
  }

  void filterDeliveries(String filter) {
    print('🟣 [DeliveryController] filterDeliveries called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchDeliveries(String query) {
    print('🟣 [DeliveryController] searchDeliveries called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [DeliveryController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchDeliveries(resetPage: true);
  }

  // ─── LOAD MORE (Infinite Scroll) ────────────────────────────

  Future<void> fetchMoreDeliveries() async {
    print('🟡 [DeliveryController] fetchMoreDeliveries called');
    print(
      '🟡 [DeliveryController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print(
        '🟡 [DeliveryController] Skipping load more - hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
      );
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [DeliveryController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🟡 [DeliveryController] API Request: GET /api/deliveries?$query (Page ${currentPage.value})',
      );

      final response = await _api.get(
        '/api/deliveries?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newDeliveries = list
            .map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        print(
          '🟡 [DeliveryController] Loaded ${newDeliveries.length} more deliveries',
        );
        deliveries.addAll(newDeliveries);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print(
          '🟡 [DeliveryController] Total deliveries now: ${deliveries.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [DeliveryController] Failed to load more deliveries');
      }
    } catch (e) {
      print('❌ [DeliveryController] fetchMoreDeliveries error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [DeliveryController] fetchMoreDeliveries completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshDeliveries() {
    print('🟢 [DeliveryController] refreshDeliveries called');
    return fetchDeliveries(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [DeliveryController] applyFilters called');
    fetchDeliveries(resetPage: true);
  }

  void goToPage(int page) {
    print('🟣 [DeliveryController] goToPage called: $page');
    if (page < 1 || page > totalPages.value) {
      print(
        '🟣 [DeliveryController] Invalid page: $page, totalPages: ${totalPages.value}',
      );
      return;
    }
    currentPage.value = page;
    fetchDeliveries();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [DeliveryController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    print(
      '🟢 [DeliveryController] showCreateWizard: ${showCreateWizard.value}',
    );

    // Set default delivery date to tomorrow
    selectedDate.value = DateTime.now().add(const Duration(days: 1));
    deliveryDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedDate.value!);
  }

  void closeCreateWizard() {
    print('🟢 [DeliveryController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print(
      '🟢 [DeliveryController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void _resetWizard() {
    print('🟢 [DeliveryController] _resetWizard called');
    wizardStep.value = 0;
    selectedOrder.value = null;
    orderSearchResults.clear();
    lineDrafts.clear();
    orderSearchController.clear();
    deliveryDateController.clear();
    deliveryPersonController.clear();
    trackingNumberController.clear();
    notesController.clear();
    selectedDate.value = null;
    print('✅ [DeliveryController] Wizard reset complete');
  }

  Future<void> searchOrders(String query) async {
    print('🔵 [DeliveryController] searchOrders called with: $query');

    if (query.trim().length < 2) {
      print('🔵 [DeliveryController] Query too short, clearing results');
      orderSearchResults.clear();
      return;
    }

    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print(
        '🔵 [DeliveryController] API Request: GET /api/deliveries/available-orders?search=$encoded&limit=10',
      );

      final response = await _api.get(
        '/api/deliveries/available-orders?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => OrderForDelivery.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print(
          '🔵 [DeliveryController] Found ${orderSearchResults.length} orders for query: $query',
        );
      } else {
        print('❌ [DeliveryController] No orders found for query: $query');
        orderSearchResults.clear();
      }
    } catch (e) {
      print('❌ [DeliveryController] searchOrders error: $e');
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
      print('🔵 [DeliveryController] searchOrders completed');
    }
  }

  void selectOrderForDelivery(OrderForDelivery order) {
    print('🔵 [DeliveryController] selectOrderForDelivery called');
    print(
      '🔵 [DeliveryController] Selected order: ${order.orderNumber} - ${order.customerName}',
    );

    selectedOrder.value = order;
    orderSearchResults.clear();
    orderSearchController.text = order.orderNumber;
    lineDrafts.value = order.items.map((item) {
      return DeliveryLineDraft(
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        orderQuantity: item.quantity,
        remainingQuantity: item.remainingQuantity,
        unit: item.unit,
      );
    }).toList();

    print(
      '🔵 [DeliveryController] Created ${lineDrafts.length} line drafts for order',
    );
  }

  void selectDeliveryDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          selectedDate.value ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      selectedDate.value = date;
      deliveryDateController.text = DateFormat('dd MMM yyyy').format(date);
    }
  }

  bool canGoToStep2() {
    final canGo = selectedOrder.value != null;
    print('🔵 [DeliveryController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any(
      (l) => l.selected.value && l.deliveryQuantity.value > 0,
    );
    print('🔵 [DeliveryController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print(
      '🟡 [DeliveryController] nextStep called, current step: ${wizardStep.value}',
    );

    if (wizardStep.value == 0 && !canGoToStep2()) {
      print('❌ [DeliveryController] Cannot go to step 2 - no order selected');
      Get.snackbar('Validation', 'Select an order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print('❌ [DeliveryController] Cannot go to step 3 - no items selected');
      Get.snackbar('Validation', 'Select at least one item to deliver');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print('🟡 [DeliveryController] Step changed to: ${wizardStep.value}');
    }
  }

  void previousStep() {
    print(
      '🟡 [DeliveryController] previousStep called, current step: ${wizardStep.value}',
    );
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print('🟡 [DeliveryController] Step changed to: ${wizardStep.value}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / CONFIRM / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createDelivery() async {
    print('🔵 [DeliveryController] createDelivery called');

    final order = selectedOrder.value;
    if (order == null) {
      print('❌ [DeliveryController] No order selected');
      return false;
    }

    final selectedItems = lineDrafts
        .where((l) => l.selected.value && l.deliveryQuantity.value > 0)
        .toList();

    print('🔵 [DeliveryController] Selected items: ${selectedItems.length}');

    if (selectedItems.isEmpty) {
      print('❌ [DeliveryController] No items selected');
      Get.snackbar('Validation', 'Select at least one item to deliver');
      return false;
    }

    final deliveryDate = selectedDate.value;
    if (deliveryDate == null) {
      print('❌ [DeliveryController] No delivery date selected');
      Get.snackbar('Validation', 'Please select a delivery date');
      return false;
    }

    try {
      isSubmitting.value = true;
      final payload = {
        'salesOrderId': order.id,
        'deliveryDate': deliveryDate.toIso8601String().split('T').first,
        'items': selectedItems
            .map(
              (l) => {
                'productId': l.productId,
                'deliveredQuantity': l.deliveryQuantity.value,
                'notes': null,
              },
            )
            .toList(),
        'deliveryPerson': deliveryPersonController.text.trim().isEmpty
            ? null
            : deliveryPersonController.text.trim(),
        'trackingNumber': trackingNumberController.text.trim().isEmpty
            ? null
            : trackingNumberController.text.trim(),
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      };

      print('🔵 [DeliveryController] Submitting delivery payload:');
      print(
        '🔵 [DeliveryController] ${payload.toString().substring(0, payload.toString().length > 500 ? 500 : payload.toString().length)}...',
      );

      final response = await _api.post(
        '/api/deliveries',
        body: payload,
        requiresAuth: true,
      );

      print('🔵 [DeliveryController] Response Status: ${response.statusCode}');
      print('🔵 [DeliveryController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [DeliveryController] Delivery created successfully!');
        Get.snackbar('Success', 'Delivery created successfully');
        closeCreateWizard();
        await fetchDeliveries(resetPage: true);
        return true;
      }

      print(
        '❌ [DeliveryController] Failed to create delivery: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to create delivery');
      return false;
    } catch (e) {
      print('❌ [DeliveryController] createDelivery error: $e');
      print('❌ [DeliveryController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
      print('🔵 [DeliveryController] createDelivery completed');
    }
  }

  Future<bool> confirmDelivery(String id) async {
    print('🟣 [DeliveryController] confirmDelivery called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/deliveries/$id/confirm',
        body: {},
        requiresAuth: true,
      );

      print('🟣 [DeliveryController] Response Status: ${response.statusCode}');
      print('🟣 [DeliveryController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [DeliveryController] Delivery confirmed successfully');
        Get.snackbar('Success', 'Delivery confirmed and stock updated');
        await fetchDeliveries();
        return true;
      }

      print(
        '❌ [DeliveryController] Failed to confirm delivery: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to confirm delivery');
      return false;
    } catch (e) {
      print('❌ [DeliveryController] confirmDelivery error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteDelivery(String id) async {
    print('🔵 [DeliveryController] deleteDelivery called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/deliveries/$id',
        requiresAuth: true,
      );

      print('🔵 [DeliveryController] Response Status: ${response.statusCode}');
      print('🔵 [DeliveryController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [DeliveryController] Delivery deleted successfully');
        Get.snackbar('Success', 'Delivery deleted successfully');
        await fetchDeliveries(resetPage: true);
        return true;
      }

      print(
        '❌ [DeliveryController] Failed to delete delivery: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete delivery');
      return false;
    } catch (e) {
      print('❌ [DeliveryController] deleteDelivery error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── SELECT DELIVERY ──────────────────────────────────────────

  void selectDelivery(DeliveryModel item) {
    print(
      '🔵 [DeliveryController] selectDelivery called for: ${item.deliveryNumber}',
    );
    selectedDelivery.value = item;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: GET STATUS COLOR
  // ═══════════════════════════════════════════════════════════════

  Color getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Partially Delivered':
        return Colors.blue;
      default:
        return Colors.orange;
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
// DELIVERY LINE DRAFT
// ═══════════════════════════════════════════════════════════════

class DeliveryLineDraft {
  final String productId;
  final String productName;
  final String sku;
  final int orderQuantity;
  final int remainingQuantity;
  final String unit;
  final RxBool selected;
  final RxInt deliveryQuantity;

  DeliveryLineDraft({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.orderQuantity,
    required this.remainingQuantity,
    this.unit = 'Pcs',
  }) : selected = false.obs,
       deliveryQuantity = remainingQuantity > 0 ? remainingQuantity.obs : 0.obs;

  // Max delivery quantity cannot exceed remaining quantity
  void updateDeliveryQuantity(int value) {
    deliveryQuantity.value = value.clamp(0, remainingQuantity);
  }
}
