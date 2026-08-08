// lib/core/warehouse/goods_receiving/model/goods_receiving_model.dart

import 'package:intl/intl.dart';

class GoodsReceivingModel {
  final String id;
  final String grnNumber;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final String supplierId;
  final String supplierName;
  final DateTime receivingDate;
  final String status;
  final String? receivedBy;
  final String? notes;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoodsReceivingItemModel> items;

  GoodsReceivingModel({
    required this.id,
    required this.grnNumber,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.supplierId,
    required this.supplierName,
    required this.receivingDate,
    required this.status,
    this.receivedBy,
    this.notes,
    this.confirmedBy,
    this.confirmedAt,
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
  bool get isPartiallyReceived => status == 'Partially Received';
  bool get isFullyReceived => status == 'Fully Received';
  
  bool get canConfirm => isDraft && confirmedAt == null;
  bool get canEdit => isDraft && confirmedAt == null;
  bool get canDelete => isDraft && confirmedAt == null;
  bool get isConfirmed => confirmedAt != null;

  // ─── CALCULATIONS ──────────────────────────────────────
  int get totalItems => items.length;
  int get totalReceivedQty => items.fold(0, (sum, item) => sum + item.receivingQuantity);
  int get totalOrderedQty => items.fold(0, (sum, item) => sum + item.orderedQuantity);
  
  double get receivingProgress {
    if (totalOrderedQty == 0) return 0;
    return totalReceivedQty / totalOrderedQty;
  }

  // ─── STATUS COLOR ────────────────────────────────────────
  String get statusColor {
    switch (status) {
      case 'Draft':
        return '#FFA726'; // Orange
      case 'Partially Received':
        return '#42A5F5'; // Blue
      case 'Fully Received':
        return '#66BB6A'; // Green
      default:
        return '#78909C';
    }
  }

  // ─── JSON ──────────────────────────────────────────────────
  factory GoodsReceivingModel.fromJson(Map<String, dynamic> json) {
    List<GoodsReceivingItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => GoodsReceivingItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return GoodsReceivingModel(
      id: json['id'] ?? '',
      grnNumber: json['grnNumber'] ?? '',
      purchaseOrderId: json['purchaseOrderId'] ?? '',
      purchaseOrderNumber: json['purchaseOrderNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      receivingDate: json['receivingDate'] != null 
          ? DateTime.parse(json['receivingDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      receivedBy: json['receivedBy'],
      notes: json['notes'],
      confirmedBy: json['confirmedBy'],
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt']) 
          : null,
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
      'grnNumber': grnNumber,
      'purchaseOrderId': purchaseOrderId,
      'purchaseOrderNumber': purchaseOrderNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'receivingDate': receivingDate.toIso8601String(),
      'status': status,
      'receivedBy': receivedBy,
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
  String toString() => 'GoodsReceivingModel(grnNumber: $grnNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// GOODS RECEIVING ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class GoodsReceivingItemModel {
  final String id;
  final String goodsReceivingId;
  final String purchaseOrderItemId;
  final String productId;
  final String productName;
  final String sku;
  final int orderedQuantity;
  final int previouslyReceivedQty;
  final int remainingQuantity;
  final int receivingQuantity;
  final String unit;
  final String? notes;

  GoodsReceivingItemModel({
    required this.id,
    required this.goodsReceivingId,
    required this.purchaseOrderItemId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.orderedQuantity,
    required this.previouslyReceivedQty,
    required this.remainingQuantity,
    required this.receivingQuantity,
    required this.unit,
    this.notes,
  });

  bool get isFullyReceived => remainingQuantity == 0;
  bool get isPartiallyReceived => receivingQuantity > 0 && remainingQuantity > 0;
  bool get hasRemaining => remainingQuantity > 0;

  factory GoodsReceivingItemModel.fromJson(Map<String, dynamic> json) {
    return GoodsReceivingItemModel(
      id: json['id'] ?? '',
      goodsReceivingId: json['goodsReceivingId'] ?? '',
      purchaseOrderItemId: json['purchaseOrderItemId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      orderedQuantity: (json['orderedQuantity'] as num?)?.toInt() ?? 0,
      previouslyReceivedQty: (json['previouslyReceivedQty'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
      receivingQuantity: (json['receivingQuantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'Pcs',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goodsReceivingId': goodsReceivingId,
      'purchaseOrderItemId': purchaseOrderItemId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'orderedQuantity': orderedQuantity,
      'previouslyReceivedQty': previouslyReceivedQty,
      'remainingQuantity': remainingQuantity,
      'receivingQuantity': receivingQuantity,
      'unit': unit,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// GOODS RECEIVING REQUEST MODEL (For API)
// ═══════════════════════════════════════════════════════════════

class GoodsReceivingRequest {
  final String purchaseOrderId;
  final DateTime receivingDate;
  final String? receivedBy;
  final String? notes;
  final List<GoodsReceivingItemRequest> items;
  final String? status;

  GoodsReceivingRequest({
    required this.purchaseOrderId,
    required this.receivingDate,
    this.receivedBy,
    this.notes,
    required this.items,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderId': purchaseOrderId,
      'receivingDate': receivingDate.toIso8601String().split('T').first,
      'receivedBy': receivedBy,
      'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
      'status': status,
    };
  }
}

class GoodsReceivingItemRequest {
  final String purchaseOrderItemId;
  final int receivingQuantity;
  final String? notes;

  GoodsReceivingItemRequest({
    required this.purchaseOrderItemId,
    required this.receivingQuantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderItemId': purchaseOrderItemId,
      'receivingQuantity': receivingQuantity,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// GOODS RECEIVING STATS MODEL
// ═══════════════════════════════════════════════════════════════

class GoodsReceivingStats {
  final int todayCount;
  final int monthCount;
  final int draftCount;
  final int partiallyReceivedCount;
  final int fullyReceivedCount;
  final int totalCount;

  GoodsReceivingStats({
    required this.todayCount,
    required this.monthCount,
    required this.draftCount,
    required this.partiallyReceivedCount,
    required this.fullyReceivedCount,
    required this.totalCount,
  });

  factory GoodsReceivingStats.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final month = json['month'] as Map<String, dynamic>? ?? {};
    final status = json['status'] as Map<String, dynamic>? ?? {};
    
    return GoodsReceivingStats(
      todayCount: (today['count'] as num?)?.toInt() ?? 0,
      monthCount: (month['count'] as num?)?.toInt() ?? 0,
      draftCount: (status['draft'] as num?)?.toInt() ?? 0,
      partiallyReceivedCount: (status['partiallyReceived'] as num?)?.toInt() ?? 0,
      fullyReceivedCount: (status['fullyReceived'] as num?)?.toInt() ?? 0,
      totalCount: (status['total'] as num?)?.toInt() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE ORDER FOR RECEIVING (Available Orders)
// ═══════════════════════════════════════════════════════════════

class PurchaseOrderForReceiving {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String supplierName;
  final DateTime orderDate;
  final String status;
  final List<PurchaseOrderItemForReceiving> remainingItems;

  PurchaseOrderForReceiving({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    required this.status,
    required this.remainingItems,
  });

  bool get hasRemainingItems => remainingItems.isNotEmpty;
  int get totalRemainingItems => remainingItems.length;

  factory PurchaseOrderForReceiving.fromJson(Map<String, dynamic> json) {
    List<PurchaseOrderItemForReceiving> remainingItems = [];
    
    // Check if remainingItems is provided directly
    if (json['remainingItems'] != null && json['remainingItems'] is List) {
      remainingItems = (json['remainingItems'] as List)
          .map((e) => PurchaseOrderItemForReceiving.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      // Fallback to items with calculated remaining
      remainingItems = (json['items'] as List)
          .map((e) => PurchaseOrderItemForReceiving.fromJson(e as Map<String, dynamic>))
          .where((item) => item.remainingQuantity > 0)
          .toList();
    }

    return PurchaseOrderForReceiving(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      orderDate: json['orderDate'] != null 
          ? DateTime.parse(json['orderDate']) 
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      remainingItems: remainingItems,
    );
  }
}

class PurchaseOrderItemForReceiving {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final int alreadyReceived;
  final int remainingQuantity;
  final String unit;

  PurchaseOrderItemForReceiving({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.alreadyReceived,
    required this.remainingQuantity,
    this.unit = 'Pcs',
  });

  bool get hasRemaining => remainingQuantity > 0;

  factory PurchaseOrderItemForReceiving.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemForReceiving(
      id: json['id'] ?? json['purchaseOrderItemId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      alreadyReceived: (json['alreadyReceived'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'Pcs',
    );
  }
}