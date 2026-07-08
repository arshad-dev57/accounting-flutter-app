import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/warehouse/Stock_in/model/stock_movement_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();
  
  final RxList<StockMovementModel> movements = <StockMovementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxString activeTab = 'in'.obs;
  final RxString typeFilter = 'all'.obs;
  final RxString searchFilter = ''.obs;

  final RxInt currentPage = 1.obs;
  final RxInt pageLimit = 10.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNext = false.obs;
  final RxBool hasPrev = false.obs;

  final RxInt totalInCount = 0.obs;
  final RxInt totalOutCount = 0.obs;
  final RxInt todayCount = 0.obs;

  static const typeFilters = ['all', 'in', 'out'];

  @override
  void onInit() {
    super.onInit();
    fetchMovements();
    fetchTodaySummary();
  }

  Future<void> fetchMovements({bool resetPage = false}) async {
    if (resetPage) currentPage.value = 1;
    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
      };
      if (typeFilter.value != 'all') params['type'] = typeFilter.value;
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;

      final response = await _api.get(
        '/api/warehouse/stock/movements',
        queryParameters: params,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        movements.value = list
            .map((e) => StockMovementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (response.data['summary'] != null) {
          final summary = Map<String, dynamic>.from(response.data['summary']);
          totalInCount.value = (summary['totalIn'] as num?)?.toInt() ?? 0;
          totalOutCount.value = (summary['totalOut'] as num?)?.toInt() ?? 0;
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
          hasNext.value = currentPage.value < totalPages.value;
          hasPrev.value = currentPage.value > 1;
        }
      } else {
        Get.snackbar('Error', response.message.isNotEmpty ? response.message : 'Failed to load movements');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTodaySummary() async {
    try {
      final response = await _api.get(
        '/api/warehouse/stock/movements/today',
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final summary = response.data['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          totalInCount.value = (summary['totalIn'] as num?)?.toInt() ?? totalInCount.value;
          totalOutCount.value = (summary['totalOut'] as num?)?.toInt() ?? totalOutCount.value;
          todayCount.value = (summary['total'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
  }

  Future<void> refreshMovements() async {
    await fetchMovements(resetPage: true);
    await fetchTodaySummary();
  }

  void setActiveTab(String tab) => activeTab.value = tab;

  void applyTypeFilter(String type) {
    typeFilter.value = type;
    fetchMovements(resetPage: true);
  }

  void searchMovements(String query) {
    searchFilter.value = query;
    fetchMovements(resetPage: true);
  }

  void clearSearch() {
    searchFilter.value = '';
    fetchMovements(resetPage: true);
  }

  void applySearch(String query) {
    searchFilter.value = query;
    fetchMovements(resetPage: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) return;
    currentPage.value = page;
    fetchMovements();
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: {'search': query.trim(), 'limit': 10},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return {
            'id': (map['id'] ?? map['_id'])?.toString() ?? '',
            'name': map['name']?.toString() ?? '',
            'sku': map['sku']?.toString() ?? '',
            'currentStock': (map['currentStock'] as num?)?.toInt() ?? 0,
            'stockUnit': map['stockUnit']?.toString() ?? 'pcs',
            'categoryName': map['categoryName']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchSuppliers() async {
    try {
      final response = await _api.get(
        '/api/warehouse/supplier',
        queryParameters: {'limit': 100},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return {
            'id': (map['id'] ?? map['_id'])?.toString() ?? '',
            'name': map['name']?.toString() ?? '',
            'companyName': map['companyName']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addStock({
    required String productId,
    required String stockType,
    required int quantity,
    int? boxCount,
    int? piecesPerBox,
    String? supplierId,
    String? supplierName,
    String? reference,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final body = <String, dynamic>{
        'productId': productId,
        'stockType': stockType,
        'quantity': quantity,
        'supplierName': supplierName ?? 'Walk-in',
        'reference': reference ?? '',
        'notes': notes ?? '',
      };
      if (supplierId != null && supplierId.isNotEmpty) body['supplierId'] = supplierId;
      if (stockType == 'box') {
        body['boxCount'] = boxCount;
        body['piecesPerBox'] = piecesPerBox;
      }

      final response = await _api.post(
        '/api/warehouse/stock/in',
        body: body,
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Stock added successfully');
        await refreshMovements();
        return true;
      }
      Get.snackbar('Error', response.message.isNotEmpty ? response.message : 'Failed to add stock');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> removeStock({
    required String productId,
    required int quantity,
    required String reason,
    String? customerName,
    String? reference,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/warehouse/stock/out',
        body: {
          'productId': productId,
          'quantity': quantity,
          'reason': reason,
          'customerName': customerName ?? 'Walk-in Customer',
          'reference': reference ?? '',
          'notes': notes ?? '',
        },
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Stock out confirmed');
        await refreshMovements();
        return true;
      }
      Get.snackbar('Error', response.message.isNotEmpty ? response.message : 'Failed to remove stock');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Color getTypeColor(String type) =>
      type == 'stock_in' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  IconData getTypeIcon(String type) =>
      type == 'stock_in' ? Icons.arrow_downward : Icons.arrow_upward;

  String getTypeLabel(String type) => type == 'stock_in' ? 'Stock In' : 'Stock Out';

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
