// lib/core/warehouse/purchase_order/model/purchase_order_model.dart

import 'package:intl/intl.dart';

class PurchaseOrderModel {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String supplierName;
  final String? supplierEmail;
  final String? supplierPhone;
  final String? supplierAddress;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String status;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double grandTotal;
  final String? notes;
  final String? termsConditions;
  final DateTime? sentAt;
  final DateTime? approvedAt;
  final DateTime? cancelledAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseOrderItemModel> items;

  PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierEmail,
    this.supplierPhone,
    this.supplierAddress,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.status,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.grandTotal,
    this.notes,
    this.termsConditions,
    this.sentAt,
    this.approvedAt,
    this.cancelledAt,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────
  bool get isDraft => status == 'Draft';
  bool get isSent => status == 'Sent';
  bool get isApproved => status == 'Approved';
  bool get isCancelled => status == 'Cancelled';
  
  bool get canEdit => isDraft || isSent;
  bool get canSend => isDraft && supplierEmail != null && supplierEmail!.isNotEmpty;
  bool get canApprove => isSent;
  bool get canCancel => isDraft || isSent || isApproved;
  bool get canDelete => isDraft || isCancelled;

  // ─── CALCULATIONS ──────────────────────────────────────
  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // ─── STATUS COLOR ────────────────────────────────────────
  String get statusColor {
    switch (status) {
      case 'Draft':
        return '#FFA726'; // Orange
      case 'Sent':
        return '#42A5F5'; // Blue
      case 'Approved':
        return '#66BB6A'; // Green
      case 'Cancelled':
        return '#EF5350'; // Red
      default:
        return '#78909C';
    }
  }

  // ─── JSON ──────────────────────────────────────────────────
  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    List<PurchaseOrderItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PurchaseOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      supplierEmail: json['supplierEmail'],
      supplierPhone: json['supplierPhone'],
      supplierAddress: json['supplierAddress'],
      orderDate: json['orderDate'] != null 
          ? DateTime.parse(json['orderDate']) 
          : DateTime.now(),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null 
          ? DateTime.parse(json['expectedDeliveryDate']) 
          : null,
      status: json['status'] ?? 'Draft',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      termsConditions: json['termsConditions'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      userId: json['userId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierEmail': supplierEmail,
      'supplierPhone': supplierPhone,
      'supplierAddress': supplierAddress,
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'grandTotal': grandTotal,
      'notes': notes,
      'termsConditions': termsConditions,
      'sentAt': sentAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
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
  String toString() => 'PurchaseOrderModel(orderNumber: $orderNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderItemModel {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;
  final String? notes;

  PurchaseOrderItemModel({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
    this.notes,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get calculatedTax => taxableAmount * (taxRate / 100);

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      id: json['id'] ?? '',
      purchaseOrderId: json['purchaseOrderId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseOrderId': purchaseOrderId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'lineTotal': lineTotal,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER REQUEST MODEL (For API)
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderRequest {
  final String supplierId;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final String? termsConditions;
  final List<PurchaseOrderItemRequest> items;

  PurchaseOrderRequest({
    required this.supplierId,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.notes,
    this.termsConditions,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'orderDate': orderDate.toIso8601String().split('T').first,
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String().split('T').first,
      'notes': notes,
      'termsConditions': termsConditions,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class PurchaseOrderItemRequest {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final String? notes;

  PurchaseOrderItemRequest({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.taxRate = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'taxRate': taxRate,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER STATS MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderStats {
  final int todayCount;
  final double todayAmount;
  final int monthCount;
  final double monthAmount;

  PurchaseOrderStats({
    required this.todayCount,
    required this.todayAmount,
    required this.monthCount,
    required this.monthAmount,
  });

  factory PurchaseOrderStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};
    
    return PurchaseOrderStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      todayAmount: (today['amount'] as num?)?.toDouble() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      monthAmount: (month['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER STATUS COUNTS MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderStatusCounts {
  final int draft;
  final int sent;
  final int approved;
  final int cancelled;
  final int total;

  PurchaseOrderStatusCounts({
    required this.draft,
    required this.sent,
    required this.approved,
    required this.cancelled,
    required this.total,
  });

  factory PurchaseOrderStatusCounts.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>? ?? {};
    
    return PurchaseOrderStatusCounts(
      draft: (status['draft'] as num?)?.toInt() ?? 0,
      sent: (status['sent'] as num?)?.toInt() ?? 0,
      approved: (status['approved'] as num?)?.toInt() ?? 0,
      cancelled: (status['cancelled'] as num?)?.toInt() ?? 0,
      total: (status['total'] as num?)?.toInt() ?? 0,
    );
  }
}