// lib/core/warehouse/refunds/controller/refund_controller.dart - FIXED ORDER SEARCH ENDPOINT

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:LedgerPro_app/core/warehouse/refunds/model/refund_model.dart';
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

  final List<String> filters = ['all', 'Pending', 'Processing', 'Completed', 'Failed', 'Cancelled'];

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
  static const statusOptions = ['all', 'Pending', 'Processing', 'Completed', 'Failed', 'Cancelled'];
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
    print('🟢 [SalesRefundController] onInit called');
    fetchRefunds();
  }

  @override
  void onClose() {
    print('🟢 [SalesRefundController] onClose called - disposing controllers');
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
    print('🔵 [SalesRefundController] fetchRefunds called');
    print('🔵 [SalesRefundController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}');
    print('🔵 [SalesRefundController] Reset Page: $resetPage');
    
    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
        print('🔵 [SalesRefundController] Search filter: ${searchFilter.value}');
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print('🔵 [SalesRefundController] Status filter: ${statusFilter.value}');
      }
      if (methodFilter.value != 'all') {
        params['method'] = methodFilter.value;
        print('🔵 [SalesRefundController] Method filter: ${methodFilter.value}');
      }
      if (fromDate.value != null) {
        params['fromDate'] = fromDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesRefundController] From date: ${params['fromDate']}');
      }
      if (toDate.value != null) {
        params['toDate'] = toDate.value!.toIso8601String().split('T').first;
        print('🔵 [SalesRefundController] To date: ${params['toDate']}');
      }

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🔵 [SalesRefundController] API Request: GET /api/sales/refunds?$query');

      final response = await _api.get('/api/sales/refunds?$query', requiresAuth: true);

      print('🔵 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🔵 [SalesRefundController] Response Success: ${response.success}');
      print('🔵 [SalesRefundController] Response Data: ${response.data}');

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        print('🔵 [SalesRefundController] Data length: ${list.length}');
        
        refunds.value = list
            .map((e) => RefundModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        applyLocalFilters();

        if (response.data['stats'] != null) {
          stats.value = RefundStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
          print('🔵 [SalesRefundController] Stats: ${stats.value}');
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
          hasNext.value = pagination['hasNext'] == true;
          hasPrev.value = pagination['hasPrev'] == true;
          hasMore.value = pagination['hasNext'] == true;
          
          print('✅ [SalesRefundController] Refunds fetched successfully: ${refunds.length} refunds');
          print('✅ [SalesRefundController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}');
        }
      } else {
        print('❌ [SalesRefundController] Failed to fetch refunds');
        print('❌ [SalesRefundController] Response data: ${response.data}');
        Get.snackbar('Error', response.message ?? 'Failed to load refunds');
      }
    } catch (e) {
      print('❌ [SalesRefundController] fetchRefunds error: $e');
      print('❌ [SalesRefundController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
      print('🔵 [SalesRefundController] fetchRefunds completed, isLoading: ${isLoading.value}');
    }
  }

  // ─── LOCAL FILTERS ──────────────────────────────────────────

  void applyLocalFilters() {
    print('🟣 [SalesRefundController] applyLocalFilters called');
    print('🟣 [SalesRefundController] Selected filter: ${selectedFilter.value}');
    print('🟣 [SalesRefundController] Search filter: ${searchFilter.value}');
    
    final list = refunds.toList();
    final filtered = list.where((refund) {
      if (selectedFilter.value != 'all' && refund.refundStatus != selectedFilter.value) {
        return false;
      }
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches = refund.refundNumber.toLowerCase().contains(query) ||
            refund.customerName.toLowerCase().contains(query) ||
            refund.orderNumber.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
    
    print('🟣 [SalesRefundController] Filtered refunds: ${filtered.length} out of ${list.length}');
    filteredRefunds.value = filtered;
  }

  void filterRefunds(String filter) {
    print('🟣 [SalesRefundController] filterRefunds called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchRefunds(String query) {
    print('🟣 [SalesRefundController] searchRefunds called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [SalesRefundController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchRefunds(resetPage: true);
  }

  // ─── LOAD MORE ────────────────────────────────────────────

  Future<void> fetchMoreRefunds() async {
    print('🟡 [SalesRefundController] fetchMoreRefunds called');
    print('🟡 [SalesRefundController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}');
    
    if (!hasMore.value || isLoadingMore.value) {
      print('🟡 [SalesRefundController] Skipping load more');
      return;
    }
    
    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [SalesRefundController] Loading page: ${currentPage.value}');

      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;
      if (methodFilter.value != 'all') params['method'] = methodFilter.value;

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      print('🟡 [SalesRefundController] API Request: GET /api/sales/refunds?$query');

      final response = await _api.get('/api/sales/refunds?$query', requiresAuth: true);

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        final newRefunds = list
            .map((e) => RefundModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        print('🟡 [SalesRefundController] Loaded ${newRefunds.length} more refunds');
        refunds.addAll(newRefunds);
        applyLocalFilters();

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          hasMore.value = pagination['hasNext'] == true;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        }
        print('🟡 [SalesRefundController] Total refunds now: ${refunds.length}, hasMore: ${hasMore.value}');
      } else {
        print('❌ [SalesRefundController] Failed to load more refunds');
      }
    } catch (e) {
      print('❌ [SalesRefundController] fetchMoreRefunds error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [SalesRefundController] fetchMoreRefunds completed');
    }
  }

  // ─── REFRESH ──────────────────────────────────────────────────

  Future<void> refreshRefunds() {
    print('🟢 [SalesRefundController] refreshRefunds called');
    return fetchRefunds(resetPage: true);
  }

  void applyFilters() {
    print('🟣 [SalesRefundController] applyFilters called');
    fetchRefunds(resetPage: true);
  }

  void goToPage(int page) {
    print('🟣 [SalesRefundController] goToPage called: $page');
    if (page < 1 || page > totalPages.value) {
      print('🟣 [SalesRefundController] Invalid page: $page, totalPages: ${totalPages.value}');
      return;
    }
    currentPage.value = page;
    fetchRefunds();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE FORM
  // ═══════════════════════════════════════════════════════════════

  void openCreateForm() {
    print('🟢 [SalesRefundController] openCreateForm called');
    _resetCreateForm();
    showCreateForm.value = true;
    print('🟢 [SalesRefundController] showCreateForm: ${showCreateForm.value}');
  }

  void closeCreateForm() {
    print('🟢 [SalesRefundController] closeCreateForm called');
    showCreateForm.value = false;
    _resetCreateForm();
    print('🟢 [SalesRefundController] showCreateForm: ${showCreateForm.value}');
  }

  void _resetCreateForm() {
    print('🟢 [SalesRefundController] _resetCreateForm called');
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
    print('✅ [SalesRefundController] Create form reset complete');
  }

  // ═══════════════════════════════════════════════════════════════
  // ORDER SEARCH - FIXED ENDPOINT
  // ═══════════════════════════════════════════════════════════════

  Future<void> searchOrders(String query) async {
    print('🔵 [SalesRefundController] searchOrders called with: "$query"');
    
    if (query.trim().length < 2) {
      print('🔵 [SalesRefundController] Query too short (${query.trim().length} chars), clearing results');
      orderSearchResults.clear();
      return;
    }
    
    try {
      isSearchingOrders.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      
      // ✅ FIX: Use the correct endpoint - /api/orders/sales with search parameter
      // This will hit the getSalesOrders endpoint which has search support
      final apiUrl = '/api/orders/sales?search=$encoded&limit=10';
      
      print('🔵 [SalesRefundController] API Request URL: $apiUrl');
      
      final response = await _api.get(
        apiUrl,
        requiresAuth: true,
      );

      print('🔵 [SalesRefundController] Response Status Code: ${response.statusCode}');
      print('🔵 [SalesRefundController] Response Success: ${response.success}');
      print('🔵 [SalesRefundController] Response Data: ${response.data}');
      print('🔵 [SalesRefundController] Response Message: ${response.message}');

      if (response.success && response.data != null) {
        print('🔵 [SalesRefundController] Response structure:');
        print('🔵 [SalesRefundController] Keys: ${response.data.keys}');
        
        // Get data from response
        List<dynamic> list = [];
        if (response.data['data'] is List) {
          list = response.data['data'] as List;
          print('🔵 [SalesRefundController] Found data in response.data["data"]');
        } else if (response.data is List) {
          list = response.data as List;
          print('🔵 [SalesRefundController] Response.data itself is a List');
        } else {
          print('🔵 [SalesRefundController] Could not find list data in response');
        }

        if (list.isNotEmpty) {
          print('🔵 [SalesRefundController] First item structure: ${list.first}');
          print('🔵 [SalesRefundController] List contains ${list.length} items');
          
          orderSearchResults.value = list
              .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          
          print('✅ [SalesRefundController] Successfully parsed ${orderSearchResults.length} orders');
          print('✅ [SalesRefundController] First order: ${orderSearchResults.isNotEmpty ? orderSearchResults.first.orderNumber : 'None'}');
        } else {
          print('🔵 [SalesRefundController] List is empty, no orders found');
          orderSearchResults.clear();
        }
      } else {
        print('❌ [SalesRefundController] API request failed or returned no data');
        print('❌ [SalesRefundController] Response success: ${response.success}');
        print('❌ [SalesRefundController] Response data: ${response.data}');
        print('❌ [SalesRefundController] Response message: ${response.message}');
        orderSearchResults.clear();
      }
    } catch (e) {
      print('❌ [SalesRefundController] searchOrders error: $e');
      print('❌ [SalesRefundController] Error type: ${e.runtimeType}');
      print('❌ [SalesRefundController] Stack trace: ${StackTrace.current}');
      orderSearchResults.clear();
    } finally {
      isSearchingOrders.value = false;
      print('🔵 [SalesRefundController] searchOrders completed');
    }
  }

  void selectOrderForRefund(OrderModel order) {
    print('🔵 [SalesRefundController] selectOrderForRefund called');
    print('🔵 [SalesRefundController] Selected order: ${order.orderNumber} - ${order.customerName}');
    print('🔵 [SalesRefundController] Order grand total: ${order.grandTotal}');
    
    selectedOrder.value = order;
    amountController.text = order.grandTotal.toStringAsFixed(2);
    orderSearchResults.clear();
    orderSearchController.text = order.orderNumber;
    
    print('✅ [SalesRefundController] Order selected successfully');
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createRefund() async {
    print('🔵 [SalesRefundController] createRefund called');
    
    final order = selectedOrder.value;
    if (order == null) {
      print('❌ [SalesRefundController] No order selected');
      Get.snackbar('Validation', 'Please select an order');
      return false;
    }
    
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      print('❌ [SalesRefundController] Invalid amount: ${amountController.text}');
      Get.snackbar('Validation', 'Enter a valid refund amount');
      return false;
    }
    
    if (reasonController.text.trim().isEmpty) {
      print('❌ [SalesRefundController] No reason provided');
      Get.snackbar('Validation', 'Refund reason is required');
      return false;
    }
    
    if (refundMethod.value == 'Bank Transfer') {
      if (bankNameController.text.trim().isEmpty ||
          accountNumberController.text.trim().isEmpty ||
          accountHolderController.text.trim().isEmpty) {
        print('❌ [SalesRefundController] Bank details incomplete');
        Get.snackbar('Validation', 'Bank details are required for bank transfer');
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
        'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
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

      print('🔵 [SalesRefundController] Submitting refund payload:');
      print('🔵 [SalesRefundController] ${payload.toString().substring(0, payload.toString().length > 500 ? 500 : payload.toString().length)}...');

      final response = await _api.post(
        '/api/sales/refunds',
        body: payload,
        requiresAuth: true,
      );

      print('🔵 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🔵 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund created successfully!');
        Get.snackbar('Success', 'Refund created successfully');
        closeCreateForm();
        await fetchRefunds(resetPage: true);
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to create refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to create refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] createRefund error: $e');
      print('❌ [SalesRefundController] Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
      print('🔵 [SalesRefundController] createRefund completed');
    }
  }

  void selectRefund(RefundModel refund) {
    print('🔵 [SalesRefundController] selectRefund called for: ${refund.refundNumber}');
    selectedRefund.value = refund;
  }

  Future<bool> updateRefund(String id, Map<String, dynamic> data) async {
    print('🔵 [SalesRefundController] updateRefund called for ID: $id');
    print('🔵 [SalesRefundController] Update data: $data');
    
    try {
      isSubmitting.value = true;
      final response = await _api.put(
        '/api/sales/refunds/$id',
        body: data,
        requiresAuth: true,
      );

      print('🔵 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🔵 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund updated successfully');
        Get.snackbar('Success', 'Refund updated successfully');
        await fetchRefunds(resetPage: true);
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to update refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to update refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] updateRefund error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteRefund(String id) async {
    print('🔵 [SalesRefundController] deleteRefund called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/sales/refunds/$id',
        requiresAuth: true,
      );

      print('🔵 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🔵 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund deleted successfully');
        Get.snackbar('Success', 'Refund deleted successfully');
        await fetchRefunds(resetPage: true);
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to delete refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to delete refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] deleteRefund error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> processRefund(String id) async {
    print('🟣 [SalesRefundController] processRefund called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/process',
        body: {},
        requiresAuth: true,
      );

      print('🟣 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🟣 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund is now processing');
        Get.snackbar('Success', 'Refund is now processing');
        await fetchRefunds();
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to process refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to process refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] processRefund error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> completeRefund(String id) async {
    print('🟣 [SalesRefundController] completeRefund called for ID: $id');
    
    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/complete',
        body: {},
        requiresAuth: true,
      );

      print('🟣 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🟣 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund completed');
        Get.snackbar('Success', 'Refund completed');
        await fetchRefunds();
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to complete refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to complete refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] completeRefund error: $e');
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelRefund(String id, {String? reason}) async {
    print('🟣 [SalesRefundController] cancelRefund called for ID: $id');
    print('🟣 [SalesRefundController] Reason: $reason');
    
    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/sales/refunds/$id/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print('🟣 [SalesRefundController] Response Status: ${response.statusCode}');
      print('🟣 [SalesRefundController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesRefundController] Refund cancelled');
        Get.snackbar('Success', 'Refund cancelled');
        await fetchRefunds();
        return true;
      }
      
      print('❌ [SalesRefundController] Failed to cancel refund: ${response.message}');
      Get.snackbar('Error', response.message ?? 'Failed to cancel refund');
      return false;
    } catch (e) {
      print('❌ [SalesRefundController] cancelRefund error: $e');
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