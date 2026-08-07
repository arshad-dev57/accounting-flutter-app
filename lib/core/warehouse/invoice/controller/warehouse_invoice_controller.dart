import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WarehouseInvoiceStats {
  final int total;
  final int unpaid;
  final int partial;
  final int paid;
  final int overdue;
  final int cancelled;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final double taxTotal;

  WarehouseInvoiceStats({
    required this.total,
    required this.unpaid,
    required this.partial,
    required this.paid,
    required this.overdue,
    required this.cancelled,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.taxTotal,
  });

  factory WarehouseInvoiceStats.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceStats(
      total: json['total']?.toInt() ?? 0,
      unpaid: json['unpaid']?.toInt() ?? 0,
      partial: json['partial']?.toInt() ?? 0,
      paid: json['paid']?.toInt() ?? 0,
      overdue: json['overdue']?.toInt() ?? 0,
      cancelled: json['cancelled']?.toInt() ?? 0,
      grandTotal: _toDouble(json['grandTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      outstanding: _toDouble(json['outstanding']),
      taxTotal: _toDouble(json['taxTotal']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class WarehouseInvoiceItemModel {
  final String productName;
  final String? sku;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double totalPrice;
  final String? productId;

  WarehouseInvoiceItemModel({
    required this.productName,
    this.sku,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.discount,
    required this.totalPrice,
    this.productId,
  });

  factory WarehouseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceItemModel(
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: _toDouble(json['unitPrice']),
      taxRate: _toDouble(json['taxRate']),
      taxAmount: _toDouble(json['taxAmount']),
      discount: _toDouble(json['discount']),
      totalPrice: _toDouble(json['totalPrice']),
      productId: json['productId']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class WarehouseInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? orderId;
  final String? orderNumber;
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final List<WarehouseInvoiceItemModel> items;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final double paidAmount;
  final double creditIssued;
  final double netOutstanding;
  final String invoiceStatus;
  final String paymentStatus;
  final String? notes;
  final DateTime invoiceDate;
  final DateTime dueDate;

  /// sales | purchase
  final String invoiceType;

  WarehouseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.orderId,
    this.orderNumber,
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.paidAmount,
    this.creditIssued = 0,
    this.netOutstanding = 0,
    required this.invoiceStatus,
    required this.paymentStatus,
    this.notes,
    required this.invoiceDate,
    required this.dueDate,
    this.invoiceType = 'sales',
  });

  double get outstanding {
    if (netOutstanding != 0 || creditIssued > 0) return netOutstanding;
    return grandTotal - paidAmount;
  }

  String get displayStatus {
    if (netOutstanding < 0) return 'Credit Balance';
    if (netOutstanding == 0 && (paidAmount > 0 || creditIssued > 0))
      return 'Paid';
    return paymentStatus;
  }

  bool get isPurchase => invoiceType == 'purchase';
  bool get isSales => !isPurchase;

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && paymentStatus != 'Paid';
  bool get isPaid => invoiceStatus == 'Paid' || paymentStatus == 'Paid';
  bool get isUnpaid => invoiceStatus == 'Unpaid' || paymentStatus == 'Unpaid';
  bool get isPartial =>
      invoiceStatus == 'Partial' || paymentStatus == 'Partial';
  bool get isCancelled => invoiceStatus == 'Cancelled';

  factory WarehouseInvoiceModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      customerId: json['customerId']?.toString(),
      customerName:
          json['customerName']?.toString() ??
          json['partyName']?.toString() ??
          json['supplierName']?.toString() ??
          '',
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      items:
          (json['items'] as List?)
              ?.map(
                (e) => WarehouseInvoiceItemModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      subtotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['taxTotal']),
      discountTotal: _toDouble(json['discountTotal']),
      grandTotal: _toDouble(json['grandTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      creditIssued: _toDouble(json['creditIssued']),
      netOutstanding: _toDouble(json['netOutstanding']),
      invoiceStatus: json['invoiceStatus']?.toString() ?? 'Unpaid',
      paymentStatus: json['paymentStatus']?.toString() ?? 'Unpaid',
      notes: json['notes']?.toString(),
      invoiceDate: _parseDate(json['invoiceDate'] ?? json['createdAt']),
      dueDate: _parseDate(json['dueDate']),
      invoiceType: (json['invoiceType']?.toString() ?? 'sales').toLowerCase(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

class TrendPoint {
  final String date;
  final double revenue;
  final double collected;
  final int count;

  TrendPoint({
    required this.date,
    this.revenue = 0,
    this.collected = 0,
    this.count = 0,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date']?.toString() ?? '',
      revenue: _toDouble(json['revenue']),
      collected: _toDouble(json['collected']),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ─────────────────────── INVOICE DRAFT MODELS ───────────────────────

class InvoiceLineDraft {
  String description;
  int quantity;
  double unitPrice;
  double taxRate;
  String? sku;
  String? productId;

  InvoiceLineDraft({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.sku,
    this.productId,
  });

  double get amount => quantity * unitPrice;
  double get taxAmount => amount * (taxRate / 100);
  double get lineTotal => amount + taxAmount;

  Map<String, dynamic> toPayload() => {
    'productId': productId,
    'productName': description.split(' (').first,
    'sku': sku,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'taxRate': taxRate,
  };

  factory InvoiceLineDraft.fromProduct(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Product';
    final sku = product['sku']?.toString() ?? '';
    return InvoiceLineDraft(
      productId: product['id']?.toString(),
      sku: sku,
      description: sku.isNotEmpty ? '$name ($sku)' : name,
      quantity: 1,
      unitPrice: _toDouble(product['sellingPrice'] ?? product['price']),
      taxRate: _toDouble(product['taxRate']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class InvoiceDraft {
  String? customerId;
  String? customerName;
  DateTime issueDate;
  DateTime dueDate;
  double discount;
  String notes;
  List<InvoiceLineDraft> lines;
  String? sourceOrderId;
  String? sourceOrderNumber;

  InvoiceDraft({
    this.customerId,
    this.customerName,
    required this.issueDate,
    required this.dueDate,
    this.discount = 0,
    this.notes = '',
    List<InvoiceLineDraft>? lines,
    this.sourceOrderId,
    this.sourceOrderNumber,
  }) : lines = lines ?? [];

  double get subtotal => lines.fold(0.0, (s, l) => s + l.amount);
  double get taxTotal => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get grandTotal =>
      (subtotal + taxTotal - discount).clamp(0, double.infinity);

  Map<String, dynamic> toPayload() {
    var noteText = notes;
    if (sourceOrderNumber != null && sourceOrderNumber!.isNotEmpty) {
      noteText = [
        if (notes.isNotEmpty) notes,
        'Warehouse order: $sourceOrderNumber',
      ].join('\n');
    }
    return {
      'customerId': customerId,
      'customerName': customerName ?? '',
      'invoiceDate': issueDate.toIso8601String().split('T').first,
      'dueDate': dueDate.toIso8601String().split('T').first,
      'discountTotal': discount,
      'notes': noteText,
      'orderId': sourceOrderId,
      'orderNumber': sourceOrderNumber,
      'invoiceStatus': 'Unpaid', // ✅ NO DRAFT - Always Unpaid
      'items': lines.map((l) => l.toPayload()).toList(),
    };
  }
}

class WarehouseInvoiceController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxList<WarehouseInvoiceModel> invoices = <WarehouseInvoiceModel>[].obs;
  final RxList<Map<String, dynamic>> customers = <Map<String, dynamic>>[].obs;
  final RxList<OrderModel> billableOrders = <OrderModel>[].obs;
  final RxList<TrendPoint> trend = <TrendPoint>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final Rx<WarehouseInvoiceModel?> selectedInvoice = Rx<WarehouseInvoiceModel?>(
    null,
  );

  final RxString statusFilter = 'all'.obs;
  final RxString paymentFilter = 'all'.obs;
  final RxString searchFilter = ''.obs;

  /// all | sales | purchase
  final RxString invoiceTypeFilter = 'all'.obs;

  final RxInt currentPage = 1.obs;
  final RxInt pageLimit = 10.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNext = false.obs;
  final RxBool hasPrev = false.obs;

  // ✅ FIXED: No Draft, No Sent
  final Rx<WarehouseInvoiceStats> stats = WarehouseInvoiceStats(
    total: 0,
    unpaid: 0,
    partial: 0,
    paid: 0,
    overdue: 0,
    cancelled: 0,
    grandTotal: 0,
    paidAmount: 0,
    outstanding: 0,
    taxTotal: 0,
  ).obs;

  // ✅ FIXED: Only valid statuses
  static const statusFilters = [
    'all',
    'Unpaid',
    'Partial',
    'Paid',
    'Overdue',
    'Cancelled',
  ];
  static const paymentFilters = ['all', 'Unpaid', 'Partial', 'Paid'];
  static const invoiceTypeFilters = ['all', 'sales', 'purchase'];

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await _api.get(
        '/api/warehouse/customers',
        queryParameters: {'limit': 100},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        customers.value = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
      }
    } catch (_) {}
  }

  Future<void> fetchInvoices({bool resetPage = false}) async {
    if (resetPage) currentPage.value = 1;

    try {
      isLoading.value = true;
      final params = <String, String>{
        'page': currentPage.value.toString(),
        'limit': pageLimit.value.toString(),
        'invoiceType': invoiceTypeFilter.value,
      };
      if (statusFilter.value != 'all') params['status'] = statusFilter.value;
      if (paymentFilter.value != 'all')
        params['paymentStatus'] = paymentFilter.value;
      if (searchFilter.value.isNotEmpty) params['search'] = searchFilter.value;

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 REQUEST: /api/warehouse/invoices');
      print('📤 PARAMS: $params');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _api.get(
        '/api/warehouse/invoices',
        queryParameters: params,
        requiresAuth: true,
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📥 RESPONSE:');
      print('📥 Success: ${response.success}');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Full Response Data:');
      print(response.data);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.success && response.data != null) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔍 DATA KEYS: ${response.data?.keys}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        final list = response.data['data'] as List? ?? [];
        print('LIST LENGTH: ${list.length}');
        print('FIRST ITEM: ${list.isNotEmpty ? list.first : 'empty'}');

        invoices.value = list
            .map(
              (e) =>
                  WarehouseInvoiceModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        if (response.data['stats'] != null) {
          stats.value = WarehouseInvoiceStats.fromJson(
            Map<String, dynamic>.from(response.data['stats']),
          );
        }
        if (response.data['trend'] != null) {
          trend.value = (response.data['trend'] as List)
              .map((e) => TrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        final pagination = response.data['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          currentPage.value = (pagination['page'] as num?)?.toInt() ?? 1;
          totalRecords.value = (pagination['total'] as num?)?.toInt() ?? 0;
          totalPages.value = (pagination['pages'] as num?)?.toInt() ?? 1;
          hasNext.value = pagination['hasNext'] == true;
          hasPrev.value = pagination['hasPrev'] == true;
        }
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERROR: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshInvoices() => fetchInvoices(resetPage: true);

  void applyStatusFilter(String v) {
    statusFilter.value = v;
    fetchInvoices(resetPage: true);
  }

  void applyInvoiceTypeFilter(String v) {
    invoiceTypeFilter.value = v;
    fetchInvoices(resetPage: true);
  }

  void applyPaymentFilter(String v) {
    paymentFilter.value = v;
    fetchInvoices(resetPage: true);
  }

  void applySearch(String v) {
    searchFilter.value = v;
    fetchInvoices(resetPage: true);
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) return;
    currentPage.value = page;
    fetchInvoices();
  }

  void openCreateForm() => showCreateForm.value = true;
  void closeCreateForm() => showCreateForm.value = false;

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final params = <String, dynamic>{'limit': 15};
      if (query.trim().isNotEmpty) params['search'] = query.trim();
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: params,
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
            'sellingPrice': map['sellingPrice'] ?? map['price'] ?? 0,
            'taxRate': map['taxRate'] ?? 0,
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> fetchBillableOrders() async {
    try {
      final response = await _api.get(
        '/api/warehouse/order',
        queryParameters: {'limit': 30, 'sortOrder': 'desc'},
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        billableOrders.value = list
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .where(
              (o) => o.orderStatus != 'Cancelled' && o.orderStatus != 'Draft',
            )
            .toList();
      }
    } catch (_) {
      billableOrders.clear();
    }
  }

  String? matchCustomerId(OrderModel order) {
    final email = order.customerEmail?.trim().toLowerCase();
    final name = order.customerName.trim().toLowerCase();
    for (final c in customers) {
      final cEmail = c['email']?.toString().trim().toLowerCase();
      final cName = c['name']?.toString().trim().toLowerCase();
      if (email != null && email.isNotEmpty && cEmail == email) {
        return (c['id'] ?? c['_id'])?.toString();
      }
      if (cName == name) return (c['id'] ?? c['_id'])?.toString();
    }
    return null;
  }

  InvoiceDraft draftFromOrder(OrderModel order) {
    final taxRate = order.subtotal > 0
        ? (order.taxTotal / order.subtotal) * 100
        : 0.0;
    final lines = order.items.map((item) {
      return InvoiceLineDraft(
        productId: item.productId,
        sku: item.sku,
        description: item.sku.isNotEmpty
            ? '${item.productName} (${item.sku})'
            : item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxRate: taxRate,
      );
    }).toList();

    return InvoiceDraft(
      customerId: matchCustomerId(order),
      customerName: order.customerName,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      discount: order.discountTotal,
      notes: order.customerNotes ?? '',
      lines: lines,
      sourceOrderId: order.id,
      sourceOrderNumber: order.orderNumber,
    );
  }

  void _resolveCustomerName(InvoiceDraft draft) {
    if (draft.customerId == null) return;
    for (final c in customers) {
      final id = (c['id'] ?? c['_id'])?.toString();
      if (id == draft.customerId) {
        draft.customerName = c['name']?.toString() ?? draft.customerName;
        return;
      }
    }
  }

  Future<bool> createInvoice(InvoiceDraft draft) async {
    _resolveCustomerName(draft);
    if (draft.customerName == null || draft.customerName!.trim().isEmpty) {
      Get.snackbar('Validation', 'Customer is required');
      return false;
    }
    if (draft.lines.isEmpty) {
      Get.snackbar('Validation', 'Add at least one line item');
      return false;
    }

    try {
      isSubmitting.value = true;
      final payload = draft.toPayload();
      final response = await _api.post(
        '/api/warehouse/invoices',
        body: payload,
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Warehouse invoice created');
        closeCreateForm();
        await fetchInvoices(resetPage: true);
        return true;
      }
      Get.snackbar(
        'Error',
        response.message.isNotEmpty
            ? response.message
            : 'Failed to create invoice',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> createFromOrder(String orderId) async {
    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/warehouse/invoices/from-order/$orderId',
        body: {},
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Invoice created from order');
        await fetchInvoices(resetPage: true);
        return true;
      }
      Get.snackbar(
        'Error',
        response.message.isNotEmpty ? response.message : 'Failed',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> recordPayment(String id, double amount) async {
    try {
      isSubmitting.value = true;
      final response = await _api.patch(
        '/api/warehouse/invoices/$id/payment',
        body: {'amount': amount},
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Payment recorded');
        await fetchInvoices();
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

  Future<bool> deleteInvoice(WarehouseInvoiceModel invoice) async {
    try {
      isSubmitting.value = true;
      final response = await _api.delete(
        '/api/warehouse/invoices/${invoice.id}',
        requiresAuth: true,
      );
      if (response.success) {
        Get.snackbar('Success', 'Invoice deleted');
        await fetchInvoices();
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

  Color statusColor(WarehouseInvoiceModel invoice) {
    if (invoice.isOverdue) return Colors.red;
    switch (invoice.paymentStatus) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerId;
  final String orderStatus;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final String? customerNotes;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerId,
    required this.orderStatus,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    this.customerNotes,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      customerId: json['customerId']?.toString(),
      orderStatus: json['orderStatus']?.toString() ?? '',
      subtotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['taxTotal']),
      discountTotal: _toDouble(json['discountTotal']),
      customerNotes: json['customerNotes']?.toString(),
      items:
          (json['items'] as List?)
              ?.map(
                (e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: _toDouble(json['unitPrice']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
