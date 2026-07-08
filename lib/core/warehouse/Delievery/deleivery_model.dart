// lib/core/warehouse/delivery/model/delivery_model.dart

import 'package:intl/intl.dart';

class DeliveryModel {
  final String id;
  final String deliveryNumber;
  final String salesOrderId;
  final String salesOrderNumber;
  final String customerId;
  final String customerName;
  final DateTime deliveryDate;
  final String deliveryStatus;
  final String? deliveryPerson;
  final String? trackingNumber;
  final String? notes;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DeliveryItemModel> items;

  DeliveryModel({
    required this.id,
    required this.deliveryNumber,
    required this.salesOrderId,
    required this.salesOrderNumber,
    required this.customerId,
    required this.customerName,
    required this.deliveryDate,
    required this.deliveryStatus,
    this.deliveryPerson,
    this.trackingNumber,
    this.notes,
    this.confirmedBy,
    this.confirmedAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────
  bool get isPending => deliveryStatus == 'Pending';
  bool get isPartiallyDelivered => deliveryStatus == 'Partially Delivered';
  bool get isDelivered => deliveryStatus == 'Delivered';
  bool get isConfirmed => confirmedAt != null;
  bool get canConfirm => !isConfirmed && (isPending || isPartiallyDelivered);
  bool get canEdit => !isConfirmed && !isDelivered;

  // ─── DELIVERY PROGRESS ──────────────────────────────────
  int get totalItems => items.length;
  int get deliveredItems => items.where((i) => i.deliveredQuantity > 0).length;
  int get totalDeliveredQty => items.fold(0, (sum, i) => sum + i.deliveredQuantity);
  int get totalOrderedQty => items.fold(0, (sum, i) => sum + i.orderedQuantity);
  double get deliveryProgress => totalOrderedQty > 0 
      ? totalDeliveredQty / totalOrderedQty 
      : 0;

  // ─── JSON ──────────────────────────────────────────────────
  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] ?? '',
      deliveryNumber: json['deliveryNumber'] ?? '',
      salesOrderId: json['salesOrderId'] ?? '',
      salesOrderNumber: json['salesOrderNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      deliveryDate: json['deliveryDate'] != null 
          ? DateTime.parse(json['deliveryDate']) 
          : DateTime.now(),
      deliveryStatus: json['deliveryStatus'] ?? 'Pending',
      deliveryPerson: json['deliveryPerson'],
      trackingNumber: json['trackingNumber'],
      notes: json['notes'],
      confirmedBy: json['confirmedBy'],
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt']) 
          : null,
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((e) => DeliveryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveryNumber': deliveryNumber,
      'salesOrderId': salesOrderId,
      'salesOrderNumber': salesOrderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'deliveryDate': deliveryDate.toIso8601String(),
      'deliveryStatus': deliveryStatus,
      'deliveryPerson': deliveryPerson,
      'trackingNumber': trackingNumber,
      'notes': notes,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'DeliveryModel(deliveryNumber: $deliveryNumber, status: $deliveryStatus)';
}

// ═══════════════════════════════════════════════════════════════
// DELIVERY ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class DeliveryItemModel {
  final String id;
  final String deliveryId;
  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final int orderedQuantity;
  final int deliveredQuantity;
  final int remainingQuantity;
  final String? notes;

  DeliveryItemModel({
    required this.id,
    required this.deliveryId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.orderedQuantity,
    required this.deliveredQuantity,
    required this.remainingQuantity,
    this.notes,
  });

  bool get isFullyDelivered => remainingQuantity == 0;
  bool get isPartiallyDelivered => deliveredQuantity > 0 && remainingQuantity > 0;
  bool get hasRemaining => remainingQuantity > 0;

  factory DeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryItemModel(
      id: json['id'] ?? '',
      deliveryId: json['deliveryId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      unit: json['unit'] ?? 'Pcs',
      orderedQuantity: (json['orderedQuantity'] as num?)?.toInt() ?? 0,
      deliveredQuantity: (json['deliveredQuantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveryId': deliveryId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'unit': unit,
      'orderedQuantity': orderedQuantity,
      'deliveredQuantity': deliveredQuantity,
      'remainingQuantity': remainingQuantity,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// DELIVERY STATS
// ═══════════════════════════════════════════════════════════════

class DeliveryStats {
  final int total;
  final int pending;
  final int partiallyDelivered;
  final int delivered;

  DeliveryStats({
    required this.total,
    required this.pending,
    required this.partiallyDelivered,
    required this.delivered,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      partiallyDelivered: (json['partiallyDelivered'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'partiallyDelivered': partiallyDelivered,
      'delivered': delivered,
    };
  }

  @override
  String toString() => 'DeliveryStats(total: $total, pending: $pending, partiallyDelivered: $partiallyDelivered, delivered: $delivered)';
}

// ═══════════════════════════════════════════════════════════════
// ORDER FOR DELIVERY (Available Orders)
// ═══════════════════════════════════════════════════════════════

class OrderForDelivery {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime orderDate;
  final String orderStatus;
  final List<OrderItemForDelivery> items;

  OrderForDelivery({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.orderDate,
    required this.orderStatus,
    required this.items,
  });

  bool get hasRemainingItems => items.any((i) => i.remainingQuantity > 0);

  factory OrderForDelivery.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((e) => OrderItemForDelivery.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    
    // Get remaining items from the API response
    final remainingItems = (json['remainingItems'] as List? ?? [])
        .map((e) => OrderItemForDelivery.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    
    // If remainingItems is provided, use it; otherwise filter items with remaining > 0
    final effectiveItems = remainingItems.isNotEmpty 
        ? remainingItems 
        : items.where((i) => i.remainingQuantity > 0).toList();

    return OrderForDelivery(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      orderDate: json['orderDate'] != null 
          ? DateTime.parse(json['orderDate']) 
          : DateTime.now(),
      orderStatus: json['orderStatus'] ?? 'Pending',
      items: effectiveItems,
    );
  }
}

class OrderItemForDelivery {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final int deliveredQuantity;
  final int remainingQuantity;
  final String unit;

  OrderItemForDelivery({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.deliveredQuantity,
    required this.remainingQuantity,
    this.unit = 'Pcs',
  });

  bool get hasRemaining => remainingQuantity > 0;

  factory OrderItemForDelivery.fromJson(Map<String, dynamic> json) {
    return OrderItemForDelivery(
      productId: json['productId'] ?? json['id'] ?? '',
      productName: json['productName'] ?? json['name'] ?? '',
      sku: json['sku'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      deliveredQuantity: (json['deliveredQuantity'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'Pcs',
    );
  }
}