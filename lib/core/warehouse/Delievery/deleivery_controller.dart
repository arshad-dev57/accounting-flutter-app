// lib/core/warehouse/delivery/controller/delivery_controller.dart

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_model.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
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
    fetchDeliveries();
  }

  @override
  void onClose() {
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
        '/api/deliveries?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        deliveries.value = list
            .map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // ✅ Apply local filters
        applyLocalFilters();

        if (response.data['kpi'] != null) {
          stats.value = DeliveryStats.fromJson(
            Map<String, dynamic>.from(response.data['kpi']),
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
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {

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

    filteredDeliveries.value = filtered;
  }

  void filterDeliveries(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchDeliveries(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchDeliveries(resetPage: true);
  }

  // ─── LOAD MORE (Infinite Scroll) ────────────────────────────

  Future<void> fetchMoreDeliveries() async {

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
        '/api/deliveries?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newDeliveries = list
            .map((e) => DeliveryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        deliveries.addAll(newDeliveries);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
      } else {
      }
    } catch (e) {
      debugPrint('Error: $e');  
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshDeliveries() {
    return fetchDeliveries(resetPage: true);
  }

  void applyFilters() {
    fetchDeliveries(resetPage: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      return;
    }
    currentPage.value = page;
    fetchDeliveries();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    _resetWizard();
    showCreateWizard.value = true;

    // Set default delivery date to tomorrow
    selectedDate.value = DateTime.now().add(const Duration(days: 1));
    deliveryDateController.text = DateFormat(
      'dd MMM yyyy',
    ).format(selectedDate.value!);
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
    deliveryDateController.clear();
    deliveryPersonController.clear();
    trackingNumberController.clear();
    notesController.clear();
    selectedDate.value = null;
  }

  Future<void> searchOrders(String query) async {

    if (query.trim().length < 2) {
      orderSearchResults.clear();
      return;
    }

    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      final response = await _api.get(
        '/api/deliveries/available-orders?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => OrderForDelivery.fromJson(Map<String, dynamic>.from(e)))
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

  void selectOrderForDelivery(OrderForDelivery order) {

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
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any(
      (l) => l.selected.value && l.deliveryQuantity.value > 0,
    );
    return canGo;
  }

  void nextStep() {

    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select an order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar('Validation', 'Select at least one item to deliver');
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
  // CREATE / CONFIRM / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createDelivery() async {

    final order = selectedOrder.value;
    if (order == null) {
      return false;
    }

    final selectedItems = lineDrafts
        .where((l) => l.selected.value && l.deliveryQuantity.value > 0)
        .toList();


    if (selectedItems.isEmpty) {
      Get.snackbar('Validation', 'Select at least one item to deliver');
      return false;
    }

    final deliveryDate = selectedDate.value;
    if (deliveryDate == null) {
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
        if (Get.isRegistered<LocationController>() &&
            (Get.find<LocationController>().selectedLocationId?.isNotEmpty ??
                false))
          'locationId': Get.find<LocationController>().selectedLocationId,
      };


      final response = await _api.post(
        '/api/deliveries',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Delivery created successfully');
        closeCreateWizard();
        await fetchDeliveries(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> confirmDelivery(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/deliveries/$id/confirm',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Delivery confirmed and stock updated');
        await fetchDeliveries();
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteDelivery(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/deliveries/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Delivery deleted successfully');
        await fetchDeliveries(resetPage: true);
        return true;
      }

      Get.snackbar('Error', response.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── SELECT DELIVERY ──────────────────────────────────────────

  void selectDelivery(DeliveryModel item) {
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
