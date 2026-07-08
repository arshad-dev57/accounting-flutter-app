import 'dart:async';

import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/customer_model.dart';
import 'package:get/get.dart';

class OrderCustomerController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxList<WarehouseCustomer> customers = <WarehouseCustomer>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;

  final RxInt page = 1.obs;
  final RxInt total = 0.obs;
  final RxBool hasNext = false.obs;

  Timer? _debounce;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void resetAndLoad() {
    searchQuery.value = '';
    page.value = 1;
    customers.clear();
    loadCustomers();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      page.value = 1;
      customers.clear();
      if (value.trim().length >= 2) {
        searchCustomers(value.trim());
      } else {
        loadCustomers();
      }
    });
  }

  Future<void> loadCustomers({bool append = false}) async {
    if (append) {
      if (!hasNext.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final response = await _api.get(
        '/api/warehouse/customers',
        queryParameters: {
          'page': append ? page.value + 1 : 1,
          'limit': 20,
        },
        requiresAuth: true,
      );

      if (response.success && response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final list = (payload['data'] as List? ?? [])
            .map((e) => WarehouseCustomer.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};

        if (append) {
          customers.addAll(list);
          page.value = (pagination['page'] as num?)?.toInt() ?? page.value + 1;
        } else {
          customers.value = list;
          page.value = (pagination['page'] as num?)?.toInt() ?? 1;
        }

        total.value = (pagination['total'] as num?)?.toInt() ?? customers.length;
        hasNext.value = pagination['hasNext'] == true;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> searchCustomers(String query, {bool append = false}) async {
    if (append) {
      if (!hasNext.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final response = await _api.get(
        '/api/warehouse/customers/search',
        queryParameters: {
          'q': query,
          'limit': 20,
        },
        requiresAuth: true,
      );

      if (response.success && response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final list = (payload['data'] as List? ?? [])
            .map((e) => WarehouseCustomer.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (append) {
          customers.addAll(list);
        } else {
          customers.value = list;
        }

        total.value = list.length;
        hasNext.value = false;
        page.value = 1;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (!append) customers.clear();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (searchQuery.value.trim().length >= 2) return;
    page.value++;
    await loadCustomers(append: true);
  }
}
