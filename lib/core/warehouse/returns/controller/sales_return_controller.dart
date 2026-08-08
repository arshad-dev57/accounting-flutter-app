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
    print('🟢 [SalesReturnController] onInit called');
    print('🟢 [SalesReturnController] Fetching returns...');
    fetchReturns();
  }

  @override
  void onClose() {
    print('🟢 [SalesReturnController] onClose called - disposing controllers');
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
    print('🔵 [SalesReturnController] fetchReturns called');
    print(
      '🔵 [SalesReturnController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );
    print('🔵 [SalesReturnController] Reset Page: $resetPage');

    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print(
          '🔵 [SalesReturnController] Search filter: ${searchFilter.value}',
        );
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print(
          '🔵 [SalesReturnController] Status filter: ${statusFilter.value}',
        );
      }
      if (typeFilter.value != 'all') {
        params['type'] = typeFilter.value;
        print('🔵 [SalesReturnController] Type filter: ${typeFilter.value}');
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesReturnController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesReturnController] To date: ${params['toDate']}');
      }

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      print(
        '🔵 [SalesReturnController] API Request: GET /api/warehouse/returns?$query',
      );

      final response = await _api.get(
        '/api/warehouse/returns?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [SalesReturnController] Data length: ${list.length}');

        returns.value = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // ✅ Apply local filters
        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = ReturnStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
          print('🔵 [SalesReturnController] Stats: ${stats.value}');
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
            '✅ [SalesReturnController] Returns fetched successfully: ${returns.length} returns',
          );
          print(
            '✅ [SalesReturnController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
          );
        }
      } else {
        print('❌ [SalesReturnController] Failed to fetch returns');
        print('❌ [SalesReturnController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load returns');
      }
    } catch (e) {
      print('❌ [SalesReturnController] fetchReturns error: $e');
      print('❌ [SalesReturnController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print(
        '🔵 [SalesReturnController] fetchReturns completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [SalesReturnController] applyLocalFilters called');
    print(
      '🟣 [SalesReturnController] Selected filter: ${selectedFilter.value}',
    );
    print('🟣 [SalesReturnController] Search filter: ${searchFilter.value}');

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

    print(
      '🟣 [SalesReturnController] Filtered returns: ${filtered.length} out of ${list.length}',
    );
    filteredReturns.value = filtered;
  }

  void filterReturns(String filter) {
    print('🟣 [SalesReturnController] filterReturns called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchReturns(String query) {
    print('🟣 [SalesReturnController] searchReturns called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [SalesReturnController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchReturns(resetPage: true);
  }

  // ─── LOAD MORE (Infinite Scroll) ────────────────────────────

  Future<void> fetchMoreReturns() async {
    print('🟡 [SalesReturnController] fetchMoreReturns called');
    print(
      '🟡 [SalesReturnController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print(
        '🟡 [SalesReturnController] Skipping load more - hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
      );
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [SalesReturnController] Loading page: ${currentPage.value}');

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
      print(
        '🟡 [SalesReturnController] API Request: GET /api/warehouse/returns?$query (Page ${currentPage.value})',
      );

      final response = await _api.get(
        '/api/warehouse/returns?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newReturns = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        print(
          '🟡 [SalesReturnController] Loaded ${newReturns.length} more returns',
        );
        returns.addAll(newReturns);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print(
          '🟡 [SalesReturnController] Total returns now: ${returns.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [SalesReturnController] Failed to load more returns');
      }
    } catch (e) {
      print('❌ [SalesReturnController] fetchMoreReturns error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [SalesReturnController] fetchMoreReturns completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshReturns() {
    print('🟢 [SalesReturnController] refreshReturns called');
    return fetchReturns(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [SalesReturnController] applyFilters called');
    fetchReturns(resetPage: true);
  }

  void goToPage(int page) {
    print('🟣 [SalesReturnController] goToPage called: $page');
    if (page < 1 || page > totalPages.value) {
      print(
        '🟣 [SalesReturnController] Invalid page: $page, totalPages: ${totalPages.value}',
      );
      return;
    }
    currentPage.value = page;
    fetchReturns();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE WIZARD
  // ═══════════════════════════════════════════════════════════════

  void openCreateWizard() {
    print('🟢 [SalesReturnController] openCreateWizard called');
    _resetWizard();
    showCreateWizard.value = true;
    print(
      '🟢 [SalesReturnController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void closeCreateWizard() {
    print('🟢 [SalesReturnController] closeCreateWizard called');
    showCreateWizard.value = false;
    _resetWizard();
    print(
      '🟢 [SalesReturnController] showCreateWizard: ${showCreateWizard.value}',
    );
  }

  void _resetWizard() {
    print('🟢 [SalesReturnController] _resetWizard called');
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
    print('✅ [SalesReturnController] Wizard reset complete');
  }

  Future<void> searchOrders(String query) async {
    print('🔵 [SalesReturnController] searchOrders called with: $query');

    if (query.trim().length < 2) {
      print('🔵 [SalesReturnController] Query too short, clearing results');
      orderSearchResults.clear();
      return;
    }

    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      print(
        '🔵 [SalesReturnController] API Request: GET /api/warehouse/order?search=$encoded&limit=10',
      );

      final response = await _api.get(
        '/api/warehouse/order?search=$encoded&limit=10',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        orderSearchResults.value = list
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print(
          '🔵 [SalesReturnController] Found ${orderSearchResults.length} orders for query: $query',
        );
      } else {
        print('❌ [SalesReturnController] No orders found for query: $query');
        orderSearchResults.clear();
      }
    } catch (e) {
      print('❌ [SalesReturnController] searchOrders error: $e');
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
      print('🔵 [SalesReturnController] searchOrders completed');
    }
  }

  void selectOrderForReturn(OrderModel order) {
    print('🔵 [SalesReturnController] selectOrderForReturn called');
    print(
      '🔵 [SalesReturnController] Selected order: ${order.orderNumber} - ${order.customerName}',
    );

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

    print(
      '🔵 [SalesReturnController] Created ${lineDrafts.length} line drafts for order',
    );
  }

  bool canGoToStep2() {
    final canGo = selectedOrder.value != null;
    print('🔵 [SalesReturnController] canGoToStep2: $canGo');
    return canGo;
  }

  bool canGoToStep3() {
    final canGo = lineDrafts.any(
      (l) => l.selected.value && l.returnQuantity > 0,
    );
    print('🔵 [SalesReturnController] canGoToStep3: $canGo');
    return canGo;
  }

  void nextStep() {
    print(
      '🟡 [SalesReturnController] nextStep called, current step: ${wizardStep.value}',
    );

    if (wizardStep.value == 0 && !canGoToStep2()) {
      print(
        '❌ [SalesReturnController] Cannot go to step 2 - no order selected',
      );
      Get.snackbar('Validation', 'Select an order first');
      return;
    }
    if (wizardStep.value == 1 && !canGoToStep3()) {
      print(
        '❌ [SalesReturnController] Cannot go to step 3 - no items selected',
      );
      Get.snackbar('Validation', 'Select at least one item to return');
      return;
    }
    if (wizardStep.value < 2) {
      wizardStep.value++;
      print('🟡 [SalesReturnController] Step changed to: ${wizardStep.value}');
    }
  }

  void previousStep() {
    print(
      '🟡 [SalesReturnController] previousStep called, current step: ${wizardStep.value}',
    );
    if (wizardStep.value > 0) {
      wizardStep.value--;
      print('🟡 [SalesReturnController] Step changed to: ${wizardStep.value}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createReturn() async {
    print('🔵 [SalesReturnController] createReturn called');

    final order = selectedOrder.value;
    if (order == null) {
      print('❌ [SalesReturnController] No order selected');
      return false;
    }

    final selectedItems = lineDrafts
        .where((l) => l.selected.value && l.returnQuantity > 0)
        .toList();
    print('🔵 [SalesReturnController] Selected items: ${selectedItems.length}');

    if (selectedItems.isEmpty) {
      print('❌ [SalesReturnController] No items selected');
      Get.snackbar('Validation', 'Select at least one item');
      return false;
    }
    if (reasonController.text.trim().isEmpty) {
      print('❌ [SalesReturnController] No reason provided');
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

      print('🔵 [SalesReturnController] Submitting return payload:');
      print(
        '🔵 [SalesReturnController] ${payload.toString().substring(0, payload.toString().length > 500 ? 500 : payload.toString().length)}...',
      );

      final response = await _api.post(
        '/api/warehouse/returns',
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return request created successfully!');
        Get.snackbar('Success', 'Return request created');
        closeCreateWizard();
        await fetchReturns(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to create return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to create return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] createReturn error: $e');
      print('❌ [SalesReturnController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
      print('🔵 [SalesReturnController] createReturn completed');
    }
  }

  void selectReturn(ReturnModel item) {
    print(
      '🔵 [SalesReturnController] selectReturn called for: ${item.returnNumber}',
    );
    selectedReturn.value = item;
  }

  Future<bool> updateReturn(String id, Map<String, dynamic> data) async {
    print('🔵 [SalesReturnController] updateReturn called for ID: $id');
    print('🔵 [SalesReturnController] Update data: $data');

    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/warehouse/returns/$id',
        body: data,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return updated successfully');
        Get.snackbar('Success', 'Return updated successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to update return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to update return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] updateReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteReturn(String id) async {
    print('🔵 [SalesReturnController] deleteReturn called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/warehouse/returns/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return deleted successfully');
        Get.snackbar('Success', 'Return deleted successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to delete return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to delete return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] deleteReturn error: $e');
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
    print('🟣 [SalesReturnController] approveReturn called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/approve',
        body: {},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return approved successfully');
        Get.snackbar('Success', 'Return approved');
        await fetchReturns();
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to approve return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to approve return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] approveReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> rejectReturn(String id, String reason) async {
    print('🟣 [SalesReturnController] rejectReturn called for ID: $id');
    print('🟣 [SalesReturnController] Reason: $reason');

    if (reason.trim().isEmpty) {
      print('❌ [SalesReturnController] No rejection reason provided');
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

      print(
        '🟣 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return rejected successfully');
        Get.snackbar('Success', 'Return rejected');
        await fetchReturns();
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to reject return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to reject return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] rejectReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> completeReturn(String id) async {
    print('🟣 [SalesReturnController] completeReturn called for ID: $id');

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/complete',
        body: {},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return completed successfully');
        Get.snackbar('Success', 'Return completed');
        await fetchReturns();
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to complete return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to complete return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] completeReturn error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelReturn(String id, {String? reason}) async {
    print('🟣 [SalesReturnController] cancelReturn called for ID: $id');
    print('🟣 [SalesReturnController] Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return cancelled successfully');
        Get.snackbar('Success', 'Return cancelled');
        await fetchReturns();
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to cancel return: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to cancel return');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] cancelReturn error: $e');
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
    print('🔵 [SalesReturnController] getReturnById called for ID: $id');

    try {
      final response = await _api.get(
        '/api/warehouse/returns/$id',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final returnData = ReturnModel.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print(
          '✅ [SalesReturnController] Return found: ${returnData.returnNumber}',
        );
        return returnData;
      }
      print('❌ [SalesReturnController] Return not found');
      return null;
    } catch (e) {
      print('❌ [SalesReturnController] getReturnById error: $e');
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
    print('🔵 [SalesReturnController] fetchReturnStats called');
    print(
      '🔵 [SalesReturnController] Start date: $startDate, End date: $endDate',
    );

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

      print(
        '🔵 [SalesReturnController] API Request: GET /api/warehouse/returns/stats?$query',
      );

      final response = await _api.get(
        '/api/warehouse/returns/stats?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        stats.value = ReturnStats.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
        print('✅ [SalesReturnController] Stats updated: ${stats.value}');
      } else {
        print('❌ [SalesReturnController] Failed to fetch stats');
      }
    } catch (e) {
      print('❌ [SalesReturnController] fetchReturnStats error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW: BULK UPDATE RETURNS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> bulkUpdateReturns(
    List<String> ids,
    Map<String, dynamic> data,
  ) async {
    print('🔵 [SalesReturnController] bulkUpdateReturns called');
    print('🔵 [SalesReturnController] IDs: $ids');
    print('🔵 [SalesReturnController] Data: $data');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/warehouse/returns/bulk',
        body: {'ids': ids, 'data': data},
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print(
          '✅ [SalesReturnController] ${ids.length} returns updated successfully',
        );
        Get.snackbar('Success', '${ids.length} returns updated successfully');
        await fetchReturns(resetPage: true);
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to update returns: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to update returns');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] bulkUpdateReturns error: $e');
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
    print(
      '🔵 [SalesReturnController] getReturnsByOrder called for order: $orderId',
    );

    try {
      final response = await _api.get(
        '/api/warehouse/returns/order/$orderId',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final returnsList = list
            .map((e) => ReturnModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print(
          '✅ [SalesReturnController] Found ${returnsList.length} returns for order',
        );
        return returnsList;
      }
      print('❌ [SalesReturnController] No returns found for order');
      return [];
    } catch (e) {
      print('❌ [SalesReturnController] getReturnsByOrder error: $e');
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
    print('🔵 [SalesReturnController] exportReturns called');
    print(
      '🔵 [SalesReturnController] Format: $format, Start: $startDate, End: $endDate',
    );

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

      print(
        '🔵 [SalesReturnController] API Request: GET /api/warehouse/returns/export?$query',
      );

      final response = await _api.get(
        '/api/warehouse/returns/export?$query',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        print(
          '✅ [SalesReturnController] Export URL: ${response.data?['url'] ?? response.data?['data']}',
        );
        return response.data?['url'] ?? response.data?['data'];
      }
      print('❌ [SalesReturnController] Failed to export returns');
      return null;
    } catch (e) {
      print('❌ [SalesReturnController] exportReturns error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getReturnSummary() async {
    print('🔵 [SalesReturnController] getReturnSummary called');

    try {
      final response = await _api.get(
        '/api/warehouse/returns/summary',
        requiresAuth: true,
      );

      print(
        '🔵 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesReturnController] Response Success: ${response.success}');

      if (response.success && response.data != null) {
        final summary = Map<String, dynamic>.from(response.data['data']);
        print('✅ [SalesReturnController] Summary: $summary');
        return summary;
      }
      print('❌ [SalesReturnController] Failed to fetch summary');
      return {};
    } catch (e) {
      print('❌ [SalesReturnController] getReturnSummary error: $e');
      return {};
    }
  }

  Future<bool> updateReturnStatus(String id, String status) async {
    print('🟣 [SalesReturnController] updateReturnStatus called');
    print('🟣 [SalesReturnController] ID: $id, New Status: $status');

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/returns/$id/status',
        body: {'status': status},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesReturnController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesReturnController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesReturnController] Return status updated to $status');
        Get.snackbar('Success', 'Return status updated to $status');
        await fetchReturns();
        return true;
      }

      print(
        '❌ [SalesReturnController] Failed to update status: ${response.message}',
      );
      Get.snackbar('Error', response.message ?? 'Failed to update status');
      return false;
    } catch (e) {
      print('❌ [SalesReturnController] updateReturnStatus error: $e');
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
