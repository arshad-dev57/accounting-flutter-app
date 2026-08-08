// lib/core/warehouse/sales_order/controller/sales_order_controller.dart - COMPLETE WITH DEBUG LOGS

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/customer_model.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
import 'package:BisonsTechs_app/core/warehouse/products/controller/product_controller.dart';
import 'package:BisonsTechs_app/core/warehousesettings/warehouse_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesOrderController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();
  final ProductsController _productsController = Get.put(ProductsController());

  // ─── List state ───────────────────────────────────────────────
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<OrderModel?> selectedOrder = Rx<OrderModel?>(null);
  final RxBool showDetailModal = false.obs;

  final RxInt currentPage = 1.obs;
  final RxInt pageLimit = 10.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNext = false.obs;
  final RxBool hasPrev = false.obs;
  final RxBool hasMore = false.obs;
  final RxBool isLoadingMore = false.obs;

  final RxString searchFilter = ''.obs;
  final RxString selectedFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString paymentStatusFilter = 'all'.obs;
  final RxString orderTypeFilter = 'all'.obs;
  final RxString priorityFilter = 'all'.obs;

  // ─── Filters List ─────────────────────────────────────────────
  final List<String> filters = [
    'all',
    'Draft',
    'Pending',
    'Processing',
    'Packed',
    'Shipped',
    'In Transit',
    'Delivered',
    'Cancelled',
    'Returned',
    'On Hold',
  ];

  static const statusOptions = [
    'all',
    'Draft',
    'Pending',
    'Processing',
    'Packed',
    'Shipped',
    'In Transit',
    'Delivered',
    'Cancelled',
    'Returned',
    'On Hold',
  ];

  static const paymentOptions = [
    'all',
    'Pending',
    'Paid',
    'Partial',
    'Refunded',
    'Cancelled',
  ];

  static const typeOptions = [
    'all',
    'Standard',
    'Bulk',
    'Wholesale',
    'Express',
    'Pre-Order',
    'Backorder',
  ];

  static const priorityOptions = ['all', 'Low', 'Medium', 'High', 'Urgent'];

  static const paymentStatusCreateOptions = [
    'Pending',
    'Paid',
    'Partial',
    'Refunded',
    'Cancelled',
  ];

  static const countryOptions = [
    'Pakistan',
    'China',
    'United States',
    'United Kingdom',
    'UAE',
    'Turkey',
  ];

  // ─── Settings dropdown options ────────────────────────────────
  final RxList<String> orderTypes = <String>[
    'Standard',
    'Bulk',
    'Wholesale',
    'Express',
    'Pre-Order',
    'Backorder',
  ].obs;
  final RxList<String> priorities = <String>[
    'Low',
    'Medium',
    'High',
    'Urgent',
  ].obs;
  final RxList<String> sources = <String>[
    'Web',
    'Mobile',
    'In-Store',
    'Phone',
    'WhatsApp',
    'Email',
    'B2B Portal',
  ].obs;
  final RxList<String> shippingMethods = <String>[
    'Standard',
    'Express',
    'Same Day',
    'Next Day',
    'Pickup',
    'Freight',
  ].obs;
  final RxList<String> paymentMethods = <String>[
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'Cheque',
    'Online',
    'COD',
  ].obs;
  final RxList<String> customerTypes = <String>[
    'Individual',
    'Business',
    'Wholesale',
    'Distributor',
    'Retailer',
    'Manufacturer',
  ].obs;

  final RxMap<String, List<SettingItem>> settingsItemsByCategory =
      <String, List<SettingItem>>{}.obs;

  // ─── Create form state ───────────────────────────────────────
  final RxList<CreateOrderLineItem> createItems = <CreateOrderLineItem>[].obs;
  final Rx<WarehouseCustomer?> selectedCustomer = Rx<WarehouseCustomer?>(null);
  final RxString customerName = ''.obs;
  final RxString customerEmail = ''.obs;
  final RxString customerPhone = ''.obs;
  final RxString customerType = 'Individual'.obs;
  final RxString customerCompany = ''.obs;
  final RxString customerTaxId = ''.obs;

  final Rx<OrderAddress> shippingAddress = OrderAddress().obs;
  final Rx<OrderAddress> billingAddress = OrderAddress().obs;
  final RxBool sameAsShipping = true.obs;

  final RxString orderType = 'Standard'.obs;
  final RxString priority = 'Medium'.obs;
  final RxString source = 'Web'.obs;
  final RxString salesPerson = ''.obs;
  final Rx<DateTime?> expectedDeliveryDate = Rx<DateTime?>(null);

  final RxString shippingMethod = 'Standard'.obs;
  final RxString shippingCarrier = ''.obs;
  final RxDouble shippingCost = 0.0.obs;

  final RxString paymentMethod = 'Cash'.obs;
  final RxString paymentStatus = 'Pending'.obs;

  final RxString couponCode = ''.obs;
  final RxString discountType = 'Percentage'.obs;
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble discountPercentage = 0.0.obs;

  final RxString customerNotes = ''.obs;
  final RxString internalNotes = ''.obs;
  final RxString orderNotes = ''.obs;
  final RxString tagsInput = ''.obs;

  final RxBool isSubmitting = false.obs;
  final RxString formError = ''.obs;

  // Product selection state for create form
  final Rx<Map<String, dynamic>?> selectedProduct = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxInt quantity = 1.obs;
  final TextEditingController qtyController = TextEditingController(text: '1');

  @override
  void onInit() {
    super.onInit();
    print('🟢 [SalesOrderController] onInit called');
    print('🟢 [SalesOrderController] Fetching settings and orders...');
    fetchSettings();
    fetchOrders();
  }

  @override
  void onClose() {
    qtyController.dispose();
    super.onClose();
  }

  // ─── Product selection for create form ─────────────────────
  void selectProduct(Map<String, dynamic> product) {
    selectedProduct.value = product;
  }

  void clearProductSelection() {
    selectedProduct.value = null;
    quantity.value = 1;
    qtyController.text = '1';
  }

  void updateQuantity(int qty) {
    quantity.value = qty;
    qtyController.text = qty.toString();
  }

  // ─── List API ────────────────────────────────────────────────
  Future<void> fetchOrders() async {
    print('🔵 [SalesOrderController] fetchOrders called');
    print(
      '🔵 [SalesOrderController] Current Page: ${currentPage.value}, Limit: ${pageLimit.value}',
    );

    isLoading.value = true;
    try {
      final params = <String, dynamic>{
        'page': currentPage.value,
        'limit': pageLimit.value,
        'sortBy': 'orderDate',
        'sortOrder': 'desc',
        'orderType': 'Sales Order',
      };

      if (searchFilter.value.trim().isNotEmpty) {
        params['search'] = searchFilter.value.trim();
        print('🔵 [SalesOrderController] Search filter: ${searchFilter.value}');
      }
      if (statusFilter.value != 'all') {
        params['status'] = statusFilter.value;
        print('🔵 [SalesOrderController] Status filter: ${statusFilter.value}');
      }
      if (paymentStatusFilter.value != 'all') {
        params['paymentStatus'] = paymentStatusFilter.value;
        print(
          '🔵 [SalesOrderController] Payment status filter: ${paymentStatusFilter.value}',
        );
      }
      if (priorityFilter.value != 'all') {
        params['priority'] = priorityFilter.value;
        print(
          '🔵 [SalesOrderController] Priority filter: ${priorityFilter.value}',
        );
      }

      print('🔵 [SalesOrderController] API Request: GET /api/orders/sales');
      print('🔵 [SalesOrderController] Params: $params');

      final response = await _api.get(
        '/api/orders/sales',
        queryParameters: params,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesOrderController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesOrderController] Response Success: ${response.success}');

      if (response.success && response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final data = payload['data'] as List? ?? [];
        final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};

        print('🔵 [SalesOrderController] Data length: ${data.length}');
        print('🔵 [SalesOrderController] Pagination: $pagination');

        orders.value = data
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
        pageLimit.value = (pagination['limit'] as num?)?.toInt() ?? 10;
        totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
        totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
        hasNext.value = pagination['hasNext'] == true;
        hasPrev.value = pagination['hasPrev'] == true;
        hasMore.value = pagination['hasNext'] == true;

        print(
          '✅ [SalesOrderController] Orders fetched successfully: ${orders.length} orders',
        );
        print(
          '✅ [SalesOrderController] Total records: ${totalRecords.value}, Total pages: ${totalPages.value}',
        );
      } else {
        print('❌ [SalesOrderController] Failed to fetch orders');
        print('❌ [SalesOrderController] Response data: ${response.data}');
      }
    } catch (e) {
      print('❌ [SalesOrderController] fetchOrders error: $e');
      print('❌ [SalesOrderController] Stack trace: ${StackTrace.current}');
    } finally {
      isLoading.value = false;
      print(
        '🔵 [SalesOrderController] fetchOrders completed, isLoading: ${isLoading.value}',
      );
    }
  }

  // ─── Load More (Infinite Scroll) ─────────────────────────────
  Future<void> fetchMoreOrders() async {
    print('🟡 [SalesOrderController] fetchMoreOrders called');
    print(
      '🟡 [SalesOrderController] hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
    );

    if (!hasMore.value || isLoadingMore.value) {
      print(
        '🟡 [SalesOrderController] Skipping load more - hasMore: ${hasMore.value}, isLoadingMore: ${isLoadingMore.value}',
      );
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage.value += 1;
      print('🟡 [SalesOrderController] Loading page: ${currentPage.value}');

      final params = <String, dynamic>{
        'page': currentPage.value,
        'limit': pageLimit.value,
        'sortBy': 'orderDate',
        'sortOrder': 'desc',
        'orderType': 'Sales Order',
      };

      if (searchFilter.value.trim().isNotEmpty) {
        params['search'] = searchFilter.value.trim();
      }
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;
      if (paymentStatusFilter.value != 'all') {
        params['paymentStatus'] = paymentStatusFilter.value;
      }
      if (priorityFilter.value != 'all') {
        params['priority'] = priorityFilter.value;
      }

      print(
        '🟡 [SalesOrderController] API Request: GET /api/orders/sales (Page ${currentPage.value})',
      );

      final response = await _api.get(
        '/api/orders/sales',
        queryParameters: params,
        requiresAuth: true,
      );

      if (response.success && response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final data = payload['data'] as List? ?? [];
        final newOrders = data
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        print(
          '🟡 [SalesOrderController] Loaded ${newOrders.length} more orders',
        );
        orders.addAll(newOrders);
        applyLocalFilters();

        final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};
        hasMore.value = pagination['hasNext'] == true;
        totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
        totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;

        print(
          '🟡 [SalesOrderController] Total orders now: ${orders.length}, hasMore: ${hasMore.value}',
        );
      } else {
        print('❌ [SalesOrderController] Failed to load more orders');
      }
    } catch (e) {
      print('❌ [SalesOrderController] fetchMoreOrders error: $e');
    } finally {
      isLoadingMore.value = false;
      print('🟡 [SalesOrderController] fetchMoreOrders completed');
    }
  }

  // ─── Local Filters ────────────────────────────────────────────
  void applyLocalFilters() {
    print('🟣 [SalesOrderController] applyLocalFilters called');
    print('🟣 [SalesOrderController] Selected filter: ${selectedFilter.value}');
    print('🟣 [SalesOrderController] Search filter: ${searchFilter.value}');

    final list = orders.toList();
    final filtered = list.where((order) {
      // Status filter
      if (selectedFilter.value != 'all' &&
          order.orderStatus != selectedFilter.value) {
        return false;
      }
      // Search filter
      if (searchFilter.value.isNotEmpty) {
        final query = searchFilter.value.toLowerCase();
        final matches =
            order.orderNumber.toLowerCase().contains(query) ||
            order.customerName.toLowerCase().contains(query) ||
            order.customerEmail?.toLowerCase().contains(query) == true;
        if (!matches) return false;
      }
      return true;
    }).toList();

    print(
      '🟣 [SalesOrderController] Filtered orders: ${filtered.length} out of ${list.length}',
    );
    orders.value = filtered;
  }

  void filterOrders(String filter) {
    print('🟣 [SalesOrderController] filterOrders called with: $filter');
    selectedFilter.value = filter;
    applyLocalFilters();
  }

  void searchOrders(String query) {
    print('🟣 [SalesOrderController] searchOrders called with: $query');
    searchFilter.value = query;
    applyLocalFilters();
  }

  void clearSearch() {
    print('🟣 [SalesOrderController] clearSearch called');
    searchFilter.value = '';
    applyLocalFilters();
    fetchOrders();
  }

  void refreshOrders() {
    print('🟢 [SalesOrderController] refreshOrders called');
    fetchOrders();
  }

  void updateFilter(String key, String value) {
    print(
      '🟣 [SalesOrderController] updateFilter called - key: $key, value: $value',
    );
    switch (key) {
      case 'search':
        searchFilter.value = value;
        break;
      case 'status':
        statusFilter.value = value;
        break;
      case 'paymentStatus':
        paymentStatusFilter.value = value;
        break;
      case 'orderType':
        orderTypeFilter.value = value;
        break;
      case 'priority':
        priorityFilter.value = value;
        break;
    }
    currentPage.value = 1;
    fetchOrders();
  }

  void goToPage(int page) {
    print('🟣 [SalesOrderController] goToPage called: $page');
    if (page < 1 || page > totalPages.value) {
      print(
        '🟣 [SalesOrderController] Invalid page: $page, totalPages: ${totalPages.value}',
      );
      return;
    }
    currentPage.value = page;
    fetchOrders();
  }

  void openCreateForm() {
    print('🟢 [SalesOrderController] openCreateForm called');
    resetCreateForm();
    showCreateForm.value = true;
    print('🟢 [SalesOrderController] showCreateForm: ${showCreateForm.value}');
  }

  void closeCreateForm() {
    print('🟢 [SalesOrderController] closeCreateForm called');
    showCreateForm.value = false;
    print('🟢 [SalesOrderController] showCreateForm: ${showCreateForm.value}');
  }

  void openOrderDetail(OrderModel order) {
    print(
      '🟢 [SalesOrderController] openOrderDetail called for order: ${order.orderNumber}',
    );
    selectedOrder.value = order;
    showDetailModal.value = true;
    print(
      '🟢 [SalesOrderController] showDetailModal: ${showDetailModal.value}',
    );
  }

  void closeOrderDetail() {
    print('🟢 [SalesOrderController] closeOrderDetail called');
    showDetailModal.value = false;
    selectedOrder.value = null;
    print(
      '🟢 [SalesOrderController] showDetailModal: ${showDetailModal.value}',
    );
  }

  // ─── Settings ────────────────────────────────────────────────
  Future<void> fetchSettings() async {
    print('🟠 [SalesOrderController] fetchSettings called');
    const categories = {
      'orderType': 'orderTypes',
      'priority': 'priorities',
      'orderSource': 'sources',
      'shippingMethod': 'shippingMethods',
      'paymentMethod': 'paymentMethods',
      'customerType': 'customerTypes',
    };

    for (final entry in categories.entries) {
      print(
        '🟠 [SalesOrderController] Loading settings for category: ${entry.key}',
      );
      await _loadSettingsCategory(entry.key, entry.value);
    }
    print('🟠 [SalesOrderController] All settings loaded');
  }

  Future<void> _loadSettingsCategory(String category, String targetKey) async {
    print(
      '🟠 [SalesOrderController] _loadSettingsCategory: $category -> $targetKey',
    );
    try {
      final response = await _api.get(
        '/api/settings',
        queryParameters: {'category': category},
        requiresAuth: true,
      );

      print(
        '🟠 [SalesOrderController] Settings response for $category: ${response.statusCode}',
      );

      if (response.success && response.data is Map) {
        final payload = response.data as Map<String, dynamic>;
        final list = _extractSettingsList(payload);
        settingsItemsByCategory[category] = list;

        final names = list
            .map((e) => e.name)
            .where((n) => n.isNotEmpty)
            .toList();
        print('🟠 [SalesOrderController] Settings for $category: $names');

        if (names.isNotEmpty) {
          switch (targetKey) {
            case 'orderTypes':
              orderTypes.value = names;
              print('🟠 [SalesOrderController] Updated orderTypes: $names');
              break;
            case 'priorities':
              priorities.value = names;
              print('🟠 [SalesOrderController] Updated priorities: $names');
              break;
            case 'sources':
              sources.value = names;
              print('🟠 [SalesOrderController] Updated sources: $names');
              break;
            case 'shippingMethods':
              shippingMethods.value = names;
              print(
                '🟠 [SalesOrderController] Updated shippingMethods: $names',
              );
              break;
            case 'paymentMethods':
              paymentMethods.value = names;
              print('🟠 [SalesOrderController] Updated paymentMethods: $names');
              break;
            case 'customerTypes':
              customerTypes.value = names;
              print('🟠 [SalesOrderController] Updated customerTypes: $names');
              break;
          }
        }
      } else {
        print('❌ [SalesOrderController] Failed to load settings for $category');
      }
    } catch (e) {
      print('❌ [SalesOrderController] loadSettings $category error: $e');
    }
  }

  List<SettingItem> _extractSettingsList(Map<String, dynamic> payload) {
    print('🟠 [SalesOrderController] _extractSettingsList called');
    dynamic raw = payload['data'];
    if (raw is List) {
      print('🟠 [SalesOrderController] Raw is List, length: ${raw.length}');
      return raw
          .map((e) => SettingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      print(
        '🟠 [SalesOrderController] Raw is Map with data list, length: ${(raw['data'] as List).length}',
      );
      return (raw['data'] as List)
          .map((e) => SettingItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    print('🟠 [SalesOrderController] No settings found in payload');
    return [];
  }

  Future<void> refreshSettingsCategory(String category) async {
    print('🟠 [SalesOrderController] refreshSettingsCategory: $category');
    const map = {
      'orderType': 'orderTypes',
      'priority': 'priorities',
      'orderSource': 'sources',
      'shippingMethod': 'shippingMethods',
      'paymentMethod': 'paymentMethods',
      'customerType': 'customerTypes',
    };
    final target = map[category];
    if (target != null) {
      await _loadSettingsCategory(category, target);
    }
  }

  Future<bool> addSetting(String category, String name) async {
    print('🟠 [SalesOrderController] addSetting called: $category -> $name');
    final response = await _api.post(
      '/api/settings',
      body: {'category': category, 'name': name.trim()},
      requiresAuth: true,
    );
    if (response.success) {
      print('✅ [SalesOrderController] Setting added successfully: $name');
      await refreshSettingsCategory(category);
      return true;
    }
    print('❌ [SalesOrderController] Failed to add setting: $name');
    return false;
  }

  Future<bool> deleteSetting(String category, String name) async {
    print('🟠 [SalesOrderController] deleteSetting called: $category -> $name');
    final items = settingsItemsByCategory[category] ?? [];
    final item = items.firstWhereOrNull((e) => e.name == name);
    if (item == null || item.id.isEmpty) {
      print('❌ [SalesOrderController] Setting not found: $name');
      return false;
    }

    final response = await _api.delete(
      '/api/settings/${item.id}',
      requiresAuth: true,
    );
    if (response.success) {
      print('✅ [SalesOrderController] Setting deleted successfully: $name');
      await refreshSettingsCategory(category);
      return true;
    }
    print('❌ [SalesOrderController] Failed to delete setting: $name');
    return false;
  }

  List<String> optionsForCategory(String category) {
    print('🟠 [SalesOrderController] optionsForCategory: $category');
    switch (category) {
      case 'orderType':
        return orderTypes;
      case 'priority':
        return priorities;
      case 'orderSource':
        return sources;
      case 'shippingMethod':
        return shippingMethods;
      case 'paymentMethod':
        return paymentMethods;
      case 'customerType':
        return customerTypes;
      default:
        return [];
    }
  }

  // ─── Create form helpers ─────────────────────────────────────
  void resetCreateForm() {
    print('🔵 [SalesOrderController] resetCreateForm called');
    createItems.clear();
    selectedCustomer.value = null;
    customerName.value = '';
    customerEmail.value = '';
    customerPhone.value = '';
    customerType.value = customerTypes.first;
    customerCompany.value = '';
    customerTaxId.value = '';
    shippingAddress.value = OrderAddress();
    billingAddress.value = OrderAddress();
    sameAsShipping.value = true;
    orderType.value = orderTypes.contains('Standard')
        ? 'Standard'
        : orderTypes.first;
    priority.value = priorities.contains('Medium')
        ? 'Medium'
        : priorities.first;
    source.value = sources.contains('Web') ? 'Web' : sources.first;
    salesPerson.value = '';
    expectedDeliveryDate.value = null;
    shippingMethod.value = shippingMethods.contains('Standard')
        ? 'Standard'
        : shippingMethods.first;
    shippingCarrier.value = '';
    shippingCost.value = 0;
    paymentMethod.value = paymentMethods.contains('Cash')
        ? 'Cash'
        : paymentMethods.first;
    paymentStatus.value = 'Pending';
    couponCode.value = '';
    discountType.value = 'Percentage';
    discountAmount.value = 0;
    discountPercentage.value = 0;
    customerNotes.value = '';
    internalNotes.value = '';
    orderNotes.value = '';
    tagsInput.value = '';
    formError.value = '';
    clearProductSelection();
    print('✅ [SalesOrderController] Create form reset complete');
  }

  void applyCustomer(WarehouseCustomer? customer) {
    print(
      '🔵 [SalesOrderController] applyCustomer called with: ${customer?.name ?? 'null'}',
    );
    selectedCustomer.value = customer;
    if (customer == null) {
      customerName.value = '';
      customerEmail.value = '';
      customerPhone.value = '';
      customerType.value = customerTypes.first;
      customerCompany.value = '';
      customerTaxId.value = '';
      print('🔵 [SalesOrderController] Customer removed');
      return;
    }

    customerName.value = customer.name;
    customerEmail.value = customer.email ?? '';
    customerPhone.value = customer.phone ?? '';
    customerType.value = customer.customerType;
    customerCompany.value = customer.company ?? '';
    customerTaxId.value = customer.taxId ?? '';

    print(
      '🔵 [SalesOrderController] Customer applied: ${customer.name}, Email: ${customer.email}, Phone: ${customer.phone}',
    );

    final addr = customer.primaryAddress;
    if (addr != null) {
      shippingAddress.value = OrderAddress.fromMap(addr);
      if (sameAsShipping.value) {
        billingAddress.value = OrderAddress.fromMap(addr);
      }
      print(
        '🔵 [SalesOrderController] Address applied: ${addr['street']}, ${addr['city']}',
      );
    }
  }

  void toggleSameAsShipping(bool value) {
    print('🔵 [SalesOrderController] toggleSameAsShipping: $value');
    sameAsShipping.value = value;
    if (value) {
      billingAddress.value = OrderAddress(
        street: shippingAddress.value.street,
        city: shippingAddress.value.city,
        state: shippingAddress.value.state,
        postalCode: shippingAddress.value.postalCode,
        country: shippingAddress.value.country,
      );
      print(
        '🔵 [SalesOrderController] Billing address set to shipping address',
      );
    }
  }

  void addProductToOrder(Map<String, dynamic> product, int quantity) {
    print(
      '🔵 [SalesOrderController] addProductToOrder called: ${product['name']}, quantity: $quantity',
    );

    final stock = (product['currentStock'] as num?)?.toInt() ?? 0;
    if (quantity <= 0) {
      formError.value = 'Quantity must be greater than 0';
      print('❌ [SalesOrderController] Quantity must be greater than 0');
      return;
    }
    if (quantity > stock) {
      formError.value = 'Insufficient stock. Available: $stock';
      print(
        '❌ [SalesOrderController] Insufficient stock. Available: $stock, Requested: $quantity',
      );
      return;
    }

    final productId = (product['id'] ?? product['_id']).toString();
    final unitPrice =
        (product['sellingPrice'] ?? product['price'] as num?)?.toDouble() ?? 0;

    print(
      '🔵 [SalesOrderController] Product ID: $productId, Unit Price: $unitPrice',
    );

    final existingIndex = createItems.indexWhere(
      (item) => item.productId == productId,
    );
    if (existingIndex >= 0) {
      final item = createItems[existingIndex];
      item.quantity += quantity;
      item.totalPrice = item.unitPrice * item.quantity;
      createItems.refresh();
      print(
        '🔵 [SalesOrderController] Updated existing item: ${item.productName}, New quantity: ${item.quantity}',
      );
    } else {
      final dimensions = product['dimensions'];
      String dimensionText = '';
      if (dimensions is Map) {
        dimensionText =
            '${dimensions['length']}x${dimensions['width']}x${dimensions['height']} ${dimensions['unit'] ?? ''}';
      }

      createItems.add(
        CreateOrderLineItem(
          productId: productId,
          productName: product['name']?.toString() ?? '',
          sku: product['sku']?.toString() ?? '',
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: unitPrice * quantity,
          weight: (product['weight'] as num?)?.toDouble() ?? 0,
          weightUnit: product['weightUnit']?.toString() ?? 'KG',
          dimensions: dimensionText,
        ),
      );
      print(
        '🔵 [SalesOrderController] Added new item: ${product['name']}, Quantity: $quantity',
      );
    }
    formError.value = '';
    print(
      '🔵 [SalesOrderController] Total items in order: ${createItems.length}',
    );
  }

  void removeCreateItem(int index) {
    print('🔵 [SalesOrderController] removeCreateItem called: index $index');
    if (index < 0 || index >= createItems.length) {
      print('❌ [SalesOrderController] Invalid index: $index');
      return;
    }
    final item = createItems[index];
    print('🔵 [SalesOrderController] Removing item: ${item.productName}');
    createItems.removeAt(index);
    print('🔵 [SalesOrderController] Remaining items: ${createItems.length}');
  }

  void updateCreateItemQuantity(int index, int quantity) {
    print(
      '🔵 [SalesOrderController] updateCreateItemQuantity: index $index, quantity $quantity',
    );
    if (index < 0 || index >= createItems.length || quantity < 1) {
      print(
        '❌ [SalesOrderController] Invalid index or quantity: $index, $quantity',
      );
      return;
    }
    final item = createItems[index];
    item.quantity = quantity;
    item.totalPrice = item.unitPrice * quantity;
    createItems.refresh();
    print(
      '🔵 [SalesOrderController] Updated item: ${item.productName}, New quantity: ${item.quantity}',
    );
  }

  double get subtotal {
    final total = createItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    print('🔵 [SalesOrderController] Subtotal calculated: $total');
    return total;
  }

  double get calculatedDiscount {
    if (discountType.value == 'Percentage' && discountPercentage.value > 0) {
      final discount = (subtotal * discountPercentage.value) / 100;
      print(
        '🔵 [SalesOrderController] Percentage discount: $discount% of $subtotal = $discount',
      );
      return discount;
    }
    print('🔵 [SalesOrderController] Fixed discount: ${discountAmount.value}');
    return discountAmount.value;
  }

  double get grandTotal {
    final total = subtotal + shippingCost.value - calculatedDiscount;
    print(
      '🔵 [SalesOrderController] Grand Total: $total (Subtotal: $subtotal + Shipping: ${shippingCost.value} - Discount: $calculatedDiscount)',
    );
    return total;
  }

  double get totalWeight {
    final weight = createItems.fold(
      0.0,
      (sum, item) => sum + (item.weight * item.quantity),
    );
    print('🔵 [SalesOrderController] Total Weight: $weight');
    return weight;
  }

  int get totalItemsCount {
    final count = createItems.fold(0, (sum, item) => sum + item.quantity);
    print('🔵 [SalesOrderController] Total Items Count: $count');
    return count;
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    print('🔵 [SalesOrderController] searchProducts called with: $query');
    _productsController.searchQuery.value = query;
    await _productsController.fetchProducts();
    final products = _productsController.products
        .map(
          (item) => {
            'id': item['id'] ?? item['_id'],
            'name': item['name'],
            'sku': item['sku'],
            'sellingPrice': item['sellingPrice'] ?? item['price'] ?? 0,
            'currentStock': item['currentStock'] ?? 0,
            'weight': item['weight'] ?? 0,
            'weightUnit': item['weightUnit'] ?? 'KG',
            'dimensions': item['dimensions'],
            'minimumStock': item['minimumStock'] ?? 0,
          },
        )
        .toList();
    print(
      '🔵 [SalesOrderController] Found ${products.length} products for query: $query',
    );
    return products;
  }

  Future<bool> submitCreateOrder() async {
    print('🔵 [SalesOrderController] submitCreateOrder called');
    print('🔵 [SalesOrderController] Customer: ${customerName.value}');
    print('🔵 [SalesOrderController] Items count: ${createItems.length}');
    print(
      '🔵 [SalesOrderController] Subtotal: $subtotal, Grand Total: $grandTotal',
    );

    if (customerName.value.trim().isEmpty) {
      formError.value = 'Customer name is required';
      print('❌ [SalesOrderController] Customer name is required');
      return false;
    }
    if (createItems.isEmpty) {
      formError.value = 'Order must have at least one item';
      print('❌ [SalesOrderController] Order must have at least one item');
      return false;
    }

    isSubmitting.value = true;
    formError.value = '';

    try {
      final payload = {
        'customerName': customerName.value.trim(),
        'customerEmail': customerEmail.value.trim(),
        'customerPhone': customerPhone.value.trim(),
        'customerType': customerType.value,
        'customerCompany': customerCompany.value.trim(),
        'customerTaxId': customerTaxId.value.trim(),
        'shippingAddress': shippingAddress.value.toJson(),
        'billingAddress': sameAsShipping.value
            ? shippingAddress.value.toJson()
            : billingAddress.value.toJson(),
        'items': createItems.map((e) => e.toJson()).toList(),
        'orderType': 'Sales Order',
        'priority': priority.value,
        'source': source.value,
        'salesPerson': salesPerson.value.trim(),
        'expectedDeliveryDate': expectedDeliveryDate.value?.toIso8601String(),
        'shippingMethod': shippingMethod.value,
        'shippingCarrier': shippingCarrier.value.trim(),
        'shippingCost': shippingCost.value,
        'paymentMethod': paymentMethod.value,
        'paymentStatus': paymentStatus.value,
        'couponCode': couponCode.value.trim(),
        'discountTotal': calculatedDiscount,
        'customerNotes': customerNotes.value.trim(),
        'internalNotes': internalNotes.value.trim(),
        'orderNotes': orderNotes.value.trim(),
        'tags': tagsInput.value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'subtotal': subtotal,
        'taxTotal': 0,
        'grandTotal': grandTotal,
        'totalWeight': totalWeight,
        'totalItems': totalItemsCount,
        'orderStatus': 'Pending',
        'orderDate': DateTime.now().toIso8601String(),
      };

      print('🔵 [SalesOrderController] Submitting order payload:');
      print(
        '🔵 [SalesOrderController] ${payload.toString().substring(0, payload.toString().length > 500 ? 500 : payload.toString().length)}...',
      );

      final response = await _api.post(
        '/api/orders/sales',
        body: payload,
        requiresAuth: true,
      );

      print(
        '🔵 [SalesOrderController] Response Status: ${response.statusCode}',
      );
      print('🔵 [SalesOrderController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesOrderController] Order created successfully!');
        showCreateForm.value = false;
        await fetchOrders();
        return true;
      }

      final message = response.data is Map
          ? (response.data['message']?.toString() ?? 'Failed to create order')
          : 'Failed to create order';
      formError.value = message;
      print('❌ [SalesOrderController] Failed to create order: $message');
      return false;
    } catch (e) {
      formError.value = e.toString();
      print('❌ [SalesOrderController] submitCreateOrder error: $e');
      print('❌ [SalesOrderController] Stack trace: ${StackTrace.current}');
      return false;
    } finally {
      isSubmitting.value = false;
      print('🔵 [SalesOrderController] submitCreateOrder completed');
    }
  }

  // ─── Update Order Status ──────────────────────────────────────
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    print('🟣 [SalesOrderController] updateOrderStatus called');
    print(
      '🟣 [SalesOrderController] Order ID: $orderId, Status: $status, Notes: $notes',
    );

    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/orders/${orderId}/status',
        body: {'status': status, 'notes': notes},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesOrderController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesOrderController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesOrderController] Order status updated successfully');
        await fetchOrders();
        return true;
      }
      print('❌ [SalesOrderController] Failed to update order status');
      return false;
    } catch (e) {
      print('❌ [SalesOrderController] updateOrderStatus error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Cancel Order ─────────────────────────────────────────────
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    print('🟣 [SalesOrderController] cancelOrder called');
    print('🟣 [SalesOrderController] Order ID: $orderId, Reason: $reason');

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/orders/${orderId}/cancel',
        body: {'reason': reason ?? 'Cancelled by user'},
        requiresAuth: true,
      );

      print(
        '🟣 [SalesOrderController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesOrderController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesOrderController] Order cancelled successfully');
        await fetchOrders();
        return true;
      }
      print('❌ [SalesOrderController] Failed to cancel order');
      return false;
    } catch (e) {
      print('❌ [SalesOrderController] cancelOrder error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Delete Order ─────────────────────────────────────────────
  Future<bool> deleteOrder(String orderId) async {
    print('🟣 [SalesOrderController] deleteOrder called');
    print('🟣 [SalesOrderController] Order ID: $orderId');

    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/orders/${orderId}',
        requiresAuth: true,
      );

      print(
        '🟣 [SalesOrderController] Response Status: ${response.statusCode}',
      );
      print('🟣 [SalesOrderController] Response Success: ${response.success}');

      if (response.success) {
        print('✅ [SalesOrderController] Order deleted successfully');
        await fetchOrders();
        return true;
      }
      print('❌ [SalesOrderController] Failed to delete order');
      return false;
    } catch (e) {
      print('❌ [SalesOrderController] deleteOrder error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── UI helpers ──────────────────────────────────────────────
  Color getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.grey;
      case 'Pending':
        return const Color(0xFFF39C12);
      case 'Processing':
        return const Color(0xFF3498DB);
      case 'Packed':
        return const Color(0xFF9B59B6);
      case 'Shipped':
        return const Color(0xFF6366F1);
      case 'In Transit':
        return const Color(0xFF1ABC9C);
      case 'Delivered':
        return const Color(0xFF2ECC71);
      case 'Cancelled':
        return const Color(0xFFE74C3C);
      case 'Returned':
        return const Color(0xFFE67E22);
      case 'On Hold':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }

  Color getPaymentColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFF39C12);
      case 'Paid':
        return const Color(0xFF2ECC71);
      case 'Partial':
        return const Color(0xFF3498DB);
      case 'Refunded':
        return const Color(0xFFE67E22);
      case 'Cancelled':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  Color getPriorityColor(String value) {
    switch (value) {
      case 'Low':
        return Colors.grey;
      case 'Medium':
        return const Color(0xFF3498DB);
      case 'High':
        return const Color(0xFFE67E22);
      case 'Urgent':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String formatCurrency(double value) {
    return Get.find<CurrencyController>().formatAmount(value);
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int itemCount(OrderModel order) {
    if (order.totalItems > 0) return order.totalItems;
    return order.items.fold(0, (sum, item) => sum + item.quantity);
  }
}
