import 'package:get/get.dart';

class ReturnModel {
  final String id;
  final String returnNumber;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final List<ReturnItemModel> items;
  final double subtotal;
  final double refundAmount;
  final double restockingFee;
  final double shippingCost;
  final double totalRefund;
  final String returnStatus;
  final String returnType;
  final String returnMethod;
  final String reason;
  final String? notes;
  final String? rejectionReason;
  final DateTime returnDate;

  ReturnModel({
    required this.id,
    required this.returnNumber,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.refundAmount,
    required this.restockingFee,
    required this.shippingCost,
    required this.totalRefund,
    required this.returnStatus,
    required this.returnType,
    required this.returnMethod,
    required this.reason,
    this.notes,
    this.rejectionReason,
    required this.returnDate,
  });

  int get totalReturnQty =>
      items.fold(0, (sum, item) => sum + item.returnQuantity);

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    return ReturnModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      returnNumber: json['returnNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      items: (json['items'] as List?)
              ?.map((e) => ReturnItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      subtotal: _toDouble(json['subtotal']),
      refundAmount: _toDouble(json['refundAmount']),
      restockingFee: _toDouble(json['restockingFee']),
      shippingCost: _toDouble(json['shippingCost']),
      totalRefund: _toDouble(json['totalRefund']),
      returnStatus: json['returnStatus']?.toString() ?? 'Pending',
      returnType: json['returnType']?.toString() ?? 'Return',
      returnMethod: json['returnMethod']?.toString() ?? 'Original Payment',
      reason: json['reason']?.toString() ?? '',
      notes: json['notes']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      returnDate: _parseDate(json['returnDate'] ?? json['createdAt']),
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

class ReturnItemModel {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final int returnQuantity;
  final String condition;
  final double refundAmount;
  final String reason;

  ReturnItemModel({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.returnQuantity,
    required this.condition,
    required this.refundAmount,
    required this.reason,
  });

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: ReturnModel._toDouble(json['unitPrice']),
      returnQuantity: (json['returnQuantity'] as num?)?.toInt() ?? 0,
      condition: json['condition']?.toString() ?? 'New',
      refundAmount: ReturnModel._toDouble(json['refundAmount']),
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': unitPrice * quantity,
        'returnQuantity': returnQuantity,
        'condition': condition,
        'refundAmount': refundAmount,
        'reason': reason,
      };
}

class ReturnLineDraft {
  final String productId;
  final String productName;
  final String sku;
  final int orderQuantity;
  final double unitPrice;
  final RxInt returnQuantity;
  final RxString condition;
  final RxBool selected;

  ReturnLineDraft({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.orderQuantity,
    required this.unitPrice,
  })  : returnQuantity = 1.obs,
        condition = 'New'.obs,
        selected = false.obs;

  double get refundAmount => unitPrice * returnQuantity.value;

  Map<String, dynamic> toPayload(String fallbackReason) => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': orderQuantity,
        'unitPrice': unitPrice,
        'totalPrice': unitPrice * orderQuantity,
        'returnQuantity': returnQuantity.value,
        'condition': condition.value,
        'refundAmount': refundAmount,
        'reason': fallbackReason,
      };
}

class ReturnStats {
  final int total;
  final double totalRefund;
  final int pending;
  final int approved;
  final int rejected;
  final int completed;

  ReturnStats({
    required this.total,
    required this.totalRefund,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.completed,
  });

  factory ReturnStats.fromJson(Map<String, dynamic> json) {
    return ReturnStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalRefund: ReturnModel._toDouble(json['totalRefund']),
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }
}
