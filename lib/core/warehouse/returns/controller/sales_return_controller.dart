// lib/core/warehouse/returns/controller/return_controller.dart - COMPLETE WITH DEBUG LOGS

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
import 'package:BisonsTechs_app/core/warehouse/returns/model/return_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesReturnController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<ReturnModel> returns = <ReturnModel>[].obs;
  final RxList<ReturnModel> filteredReturns = <ReturnModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateWizard = false.obs;
  final Rx<ReturnModel?> selectedReturn = Rx<ReturnModel?>(null);

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
  final RxString typeFilter = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = [
    'all',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
    'Cancelled',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<ReturnStats> stats = ReturnStats(
    total: 0,
    totalRefund: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    completed: 0,
  ).obs;

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const statusOptions = [
    'all',
    'Pending',
    'Approved',
    'Rejected',
    'Completed',
    'Cancelled',
  ];
  static const typeOptions = [
    'all',
    'Return',
    'Exchange',
    'Warranty',
    'Damaged',
  ];
  static const methodOptions = [
    'Original Payment',
    'Bank Transfer',
    'Cash',
    'Store Credit',
    'Cheque',
  ];
  static const conditionOptions = [
    'New',
    'Opened',
    'Damaged',
    'Defective',
    'Used',
  ];

  // ─── WIZARD STATE ─────────────────────────────────────────────
  final RxInt wizardStep = 0.obs;
  final RxList<OrderModel> orderSearchResults = <OrderModel>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);
  final RxList<ReturnLineDraft> lineDrafts = <ReturnLineDraft>[].obs;
  final orderSearchController = TextEditingController();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  final restockingFeeController = TextEditingController(text: '0');
  final shippingCostController = TextEditingController(text: '0');
  final rejectionReasonController = TextEditingController();
  final RxString returnType = 'Return'.obs;
  final RxString returnMethod = 'Original Payment'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReturns();
  }

  @override
  void onClose() {
    orderSearchController.dispose();
    reasonController.dispose();
    notesController.dispose();
    restockingFeeController.dispose();
    shippingCostController.dispose();
    rejectionReasonController.dispose();
    super.onClose();
  }

  // ─── GETTERS ──────────────────────────────────────────────────

  double get selectedSubtotal => lineDrafts
      .where((l) => l.selected.value)
      .fold(0.0, (sum, l) => sum + l.refundAmount);

  double get restockingFee =>
      double.tryParse(restockingFeeController.text.trim()) ?? 0;

  double get shippingCost =>
      double.tryParse(shippingCostController.text.trim()) ?? 0;

  double get totalRefundAmount =>
      (selectedSubtotal - restockingFee - shippingCost).clamp(
        0,
        double.infinity,
      );

  // ═══════════════════════════════════════════════════════════════
  // FETCH RETURNS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchReturns({bool resetPage = false}) async {

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
      if (typeFilter.value != 'all') {
        params['type'] = typeFilter.value;
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
        '/api/warehouse/returns?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        returns.value = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // ✅ Apply local filters
        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = ReturnStats.fromJson(
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

    final list = returns.toList();
    final filtered = list.where((item) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          item.returnStatus != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            item.returnNumber.toLowerCase().contains(query) ||
            item.customerName.toLowerCase().contains(query) ||
            item.orderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredReturns.value = filtered;
  }

  void filterReturns(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchReturns(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchReturns(resetPage: true);
  }

  // ─── LOAD MORE (Infinite Scroll) ────────────────────────────

  Future<void> fetchMoreReturns() async {

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
      if (typeFilter.value != 'all') params['type'] = typeFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/warehouse/returns?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newReturns = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        returns.addAll(newReturns);
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

  Future<void> refreshReturns() {
    return fetchReturns(resetPage: true);
  }

  void applyFilters() {
    fetchReturns(resetPage: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      return;
    }
    currentPage.value = page;
    fetchReturns();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    _resetWizard();
    showCreateWizard.value = true;
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
    reasonController.clear();
    notesController.clear();
    restockingFeeController.text = '0';
    shippingCostController.text = '0';
    returnType.value = 'Return';
    returnMethod.value = 'Original Payment';
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
        '/api/warehouse/order?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
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

  void selectOrderForReturn(OrderModel order) {

    selectedOrder.value = order;
    orderSearchResults.clear();
    orderSearchController.text = order.orderNumber;
    lineDrafts.value = order.items.map((item) {
      return ReturnLineDraft(
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        orderQuantity: item.quantity,
        unitPrice: item.unitPrice,
      );
    }).toList();

  }

  bool canGoToStep2() {
    final canGo = selectedOrder.value != null;
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any(
      (l) => l.selected.value && l.returnQuantity > 0,
    );
    return canGo;
  }

  void nextStep() {

    if (wizardStep.value == 0 && !canGoToStep2()) {
      Get.snackbar('Validation', 'Select an order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      Get.snackbar('Validation', 'Select at least one item to return');
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
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createReturn() async {

    final order = selectedOrder.value;
    if (order == null) {
      return false;
    }

    final selectedItems = lineDrafts
        .where((l) => l.selected.value && l.returnQuantity > 0)
        .toList();

    if (selectedItems.isEmpty) {
      Get.snackbar('Validation', 'Select at least one item');
      return false;
    }
    if (reasonController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Return reason is required');
      return false;
    }

    try {
      isSubmitting.value = true;
      final reason = reasonController.text.trim();
      final payload = {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'customerName': order.customerName,
        'customerEmail': order.customerEmail,
        'customerPhone': order.customerPhone,
        'items': selectedItems.map((l) => l.toPayload(reason)).toList(),
        'returnType': returnType.value,
        'returnMethod': returnMethod.value,
        'reason': reason,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'restockingFee': restockingFee,
        'shippingCost': shippingCost,
      };


      final response = await _api.post(
        '/api/warehouse/returns',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return request created');
        closeCreateWizard();
        await fetchReturns(resetPage: true);
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

  void selectReturn(ReturnModel item) {
    selectedReturn.value = item;
  }

  Future<bool> updateReturn(String id, Map<String, dynamic> data) async {

    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/warehouse/returns/$id',
        body: data,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return updated successfully');
        await fetchReturns(resetPage: true);
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

  Future<bool> deleteReturn(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/warehouse/returns/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return deleted successfully');
        await fetchReturns(resetPage: true);
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

  // ═══════════════════════════════════════════════════════════════
  // APPROVE / REJECT / COMPLETE / CANCEL
  // ═══════════════════════════════════════════════════════════════

  Future<bool> approveReturn(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/approve',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return approved');
        await fetchReturns();
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

  Future<bool> rejectReturn(String id, String reason) async {

    if (reason.trim().isEmpty) {
      Get.snackbar('Validation', 'Rejection reason is required');
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/reject',
        body: {'rejectionReason': reason.trim()},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return rejected');
        await fetchReturns();
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

  Future<bool> completeReturn(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/complete',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return completed');
        await fetchReturns();
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

  Future<bool> cancelReturn(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return cancelled');
        await fetchReturns();
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

  // ═══════════════════════════════════════════════════════════════
  // NEW: GET RETURN BY ID
  // ═══════════════════════════════════════════════════════════════

  Future<ReturnModel?> getReturnById(String id) async {

    try {
      final response = await _api.get(
        '/api/warehouse/returns/$id',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final returnData = ReturnModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        return returnData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW: GET RETURN STATS WITH DATE RANGE
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchReturnStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {

    try {
      final params = <String, String>{};
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String().split('T').first;
      }
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');


      final response = await _api.get(
        '/api/warehouse/returns/stats?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        stats.value = ReturnStats.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
      } else {
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW: BULK UPDATE RETURNS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> bulkUpdateReturns(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/warehouse/returns/bulk',
        body: {'ids': ids, 'data': data},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', '${ids.length} returns updated successfully');
        await fetchReturns(resetPage: true);
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

  // ═══════════════════════════════════════════════════════════════
  // NEW: GET RETURNS BY ORDER
  // ═══════════════════════════════════════════════════════════════

  Future<List<ReturnModel>> getReturnsByOrder(String orderId) async {

    try {
      final response = await _api.get(
        '/api/warehouse/returns/order/$orderId',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final returnsList = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return returnsList;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW: EXPORT RETURNS
  // ═══════════════════════════════════════════════════════════════

  Future<String?> exportReturns({
    String? format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {

    try {
      final params = <String, String>{};
      if (format != null) params['format'] = format;
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String().split('T').first;
      }
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');


      final response = await _api.get(
        '/api/warehouse/returns/export?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        return response.data?['url'] ?? response.data?['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getReturnSummary() async {

    try {
      final response = await _api.get(
        '/api/warehouse/returns/summary',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final summary = Map<String, dynamic>.from(response.data['data']);
        return summary;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> updateReturnStatus(String id, String status) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/status',
        body: {'status': status},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Return status updated to $status');
        await fetchReturns();
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

  // ═══════════════════════════════════════════════════════════════
  // HELPER: GET STATUS COLOR
  // ═══════════════════════════════════════════════════════════════

  Color getStatusColor(String status) {
    switch (status) {
      case 'Approved':
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
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
