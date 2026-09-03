// lib/core/warehouse/refunds/controller/refund_controller.dart - FIXED ORDER SEARCH ENDPOINT

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/model/refund_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesRefundController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── MAIN STATE ──────────────────────────────────────────────
  final RxList<RefundModel> refunds = <RefundModel>[].obs;
  final RxList<RefundModel> filteredRefunds = <RefundModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<RefundModel?> selectedRefund = Rx<RefundModel?>(null);

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
  final RxString methodFilter = 'all'.obs;
  final Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  final Rx<DateTime?> toDate = Rx<DateTime?>(null);

  final List<String> filters = [
    'all',
    'Pending',
    'Processing',
    'Completed',
    'Failed',
    'Cancelled',
  ];

  // ─── STATS ────────────────────────────────────────────────────
  final Rx<RefundStats> stats = RefundStats(
    total: 0,
    totalAmount: 0,
    pending: 0,
    processing: 0,
    completed: 0,
    failed: 0,
  ).obs;

  // ─── CONSTANTS ────────────────────────────────────────────────
  static const statusOptions = [
    'all',
    'Pending',
    'Processing',
    'Completed',
    'Failed',
    'Cancelled',
  ];
  static const methodOptions = [
    'all',
    'Original Payment',
    'Bank Transfer',
    'Cash',
    'Store Credit',
    'Cheque',
  ];

  // ─── CREATE FORM ─────────────────────────────────────────────
  final RxList<OrderModel> orderSearchResults = <OrderModel>[].obs;
  final RxBool isSearchingOrders = false.obs;
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  final referenceController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountHolderController = TextEditingController();
  final orderSearchController = TextEditingController();
  final RxString refundMethod = 'Original Payment'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRefunds();
  }

  @override
  void onClose() {
    amountController.dispose();
    reasonController.dispose();
    notesController.dispose();
    referenceController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    accountHolderController.dispose();
    orderSearchController.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH REFUNDS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchRefunds({bool resetPage = false}) async {

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
      if (methodFilter.value != 'all') {
        params['method'] = methodFilter.value;
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
        '/api/sales/refunds?$query',
        requiresAuth: true,
      );


      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];

        refunds.value = list
            .map((e) => RefundModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = RefundStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
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

    final list = refunds.toList();
    final filtered = list.where((refund) {
      if (selectedFilter.value != 'all' &&
          refund.refundStatus != selectedFilter.value) {
        return false;
      }
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            refund.refundNumber.toLowerCase().contains(query) ||
            refund.customerName.toLowerCase().contains(query) ||
            refund.orderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();

    filteredRefunds.value = filtered;
  }

  void filterRefunds(String filter) {
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchRefunds(String query) {
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    searchFilter.value = '';
    applyLocalFilters();
    fetchRefunds(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreRefunds() async {

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
      if (methodFilter.value != 'all') params['method'] = methodFilter.value;

      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _api.get(
        '/api/sales/refunds?$query',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newRefunds = list
            .map((e) => RefundModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        refunds.addAll(newRefunds);
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

  Future<void> refreshRefunds() {
    return fetchRefunds(resetPage: true);
  }

  void applyFilters() {
    fetchRefunds(resetPage: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      return;
    }
    currentPage.value = page;
    fetchRefunds();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE FORM
  // ═══════════════════════════════════════════════════════════════

  void openCreateForm() {
    _resetCreateForm();
    showCreateForm.value = true;
  }

  void closeCreateForm() {
    showCreateForm.value = false;
    _resetCreateForm();
  }

  void _resetCreateForm() {
    selectedOrder.value = null;
    orderSearchResults.clear();
    orderSearchController.clear();
    amountController.clear();
    reasonController.clear();
    notesController.clear();
    referenceController.clear();
    bankNameController.clear();
    accountNumberController.clear();
    accountHolderController.clear();
    refundMethod.value = 'Original Payment';
  }

  // ═══════════════════════════════════════════════════════════════
  // ORDER SEARCH - FIXED ENDPOINT
  // ═══════════════════════════════════════════════════════════════

  Future<void> searchOrders(String query) async {

    if (query.trim().length < 2) {
      orderSearchResults.clear();
      return;
    }

    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());

      // ✅ FIX: Use the correct endpoint - /api/orders/sales with search parameter
      // This will hit the getSalesOrders endpoint which has search support
      final apiUrl = '/api/orders/sales?search=$encoded&limit=10';


      final response = await _api.get(apiUrl, requiresAuth: true);


      if (response.success && response.data != null) {

        // Get data from response
        List<dynamic> list = [];
        if (response.data['data'] is List) {
          list = response.data['data'] as List;
        } else if (response.data is List) {
          list = response.data as List;
        } else {
        }

        if (list.isNotEmpty) {

          orderSearchResults.value = list
              .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

        } else {
          orderSearchResults.clear();
        }
      } else {
        orderSearchResults.clear();
      }
    } catch (e) {
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
    }
  }

  void selectOrderForRefund(OrderModel order) {

    selectedOrder.value = order;
    amountController.text = order.grandTotal.toStringAsFixed(2);
    orderSearchResults.clear();
    orderSearchController.text = order.orderNumber;

  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createRefund() async {

    final order = selectedOrder.value;
    if (order == null) {
      Get.snackbar('Validation', 'Please select an order');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('Validation', 'Enter a valid refund amount');
      return false;
    }

    if (reasonController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Refund reason is required');
      return false;
    }

    if (refundMethod.value == 'Bank Transfer') {
      if (bankNameController.text.trim().isEmpty ||
          accountNumberController.text.trim().isEmpty ||
          accountHolderController.text.trim().isEmpty) {
        Get.snackbar(
          'Validation',
          'Bank details are required for bank transfer',
        );
        return false;
      }
    }

    try {
      isSubmitting.value = true;
      final payload = {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'customerName': order.customerName,
        'customerEmail': order.customerEmail,
        'customerPhone': order.customerPhone,
        'amount': amount,
        'refundMethod': refundMethod.value,
        'reason': reasonController.text.trim(),
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'referenceNumber': referenceController.text.trim().isEmpty
            ? null
            : referenceController.text.trim(),
        'bankName': bankNameController.text.trim().isEmpty
            ? null
            : bankNameController.text.trim(),
        'accountNumber': accountNumberController.text.trim().isEmpty
            ? null
            : accountNumberController.text.trim(),
        'accountHolderName': accountHolderController.text.trim().isEmpty
            ? null
            : accountHolderController.text.trim(),
      };


      final response = await _api.post(
        '/api/sales/refunds',
        body: payload,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund created successfully');
        closeCreateForm();
        await fetchRefunds(resetPage: true);
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

  void selectRefund(RefundModel refund) {
    selectedRefund.value = refund;
  }

  Future<bool> updateRefund(String id, Map<String, dynamic> data) async {

    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/sales/refunds/$id',
        body: data,
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund updated successfully');
        await fetchRefunds(resetPage: true);
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

  Future<bool> deleteRefund(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/sales/refunds/$id',
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund deleted successfully');
        await fetchRefunds(resetPage: true);
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

  Future<bool> processRefund(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/process',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund is now processing');
        await fetchRefunds();
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

  Future<bool> completeRefund(String id) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/complete',
        body: {},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund completed');
        await fetchRefunds();
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

  Future<bool> cancelRefund(String id, {String? reason}) async {

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );


      if (response.success) {
        Get.snackbar('Success', 'Refund cancelled');
        await fetchRefunds();
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
      case 'Completed':
        return Colors.green;
      case 'Processing':
        return Colors.blue;
      case 'Failed':
      case 'Cancelled':
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
