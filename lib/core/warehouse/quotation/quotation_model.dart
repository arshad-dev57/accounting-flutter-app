// lib/core/warehouse/quotation/model/quotation_model.dart

import 'package:intl/intl.dart';

class QuotationModel {
  final String id;
  final String quotationNumber;
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerCompany;
  final DateTime quotationDate;
  final DateTime validUntil;
  final String? salesPerson;
  final String status;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double grandTotal;
  final String? notes;
  final String? termsConditions;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? convertedAt;
  final String? convertedOrderId;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuotationItemModel> items;
  final ConvertedOrder? convertedOrder;

  QuotationModel({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerCompany,
    required this.quotationDate,
    required this.validUntil,
    this.salesPerson,
    required this.status,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.grandTotal,
    this.notes,
    this.termsConditions,
    this.sentAt,
    this.acceptedAt,
    this.rejectedAt,
    this.convertedAt,
    this.convertedOrderId,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.convertedOrder,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────
  bool get isDraft => status == 'Draft';
  bool get isSent => status == 'Sent';
  bool get isAccepted => status == 'Accepted';
  bool get isRejected => status == 'Rejected';
  bool get isExpired => status == 'Expired';
  bool get isConverted => status == 'Converted';
  
  bool get canSend => isDraft;
  bool get canAccept => isSent;
  bool get canConvert => isAccepted;
  bool get canEdit => isDraft || isSent;
  bool get canDelete => !isConverted;

  // ─── CALCULATIONS ──────────────────────────────────────
  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  
  String get statusColor {
    switch (status) {
      case 'Draft':
        return '#FFA726'; // Orange
      case 'Sent':
        return '#42A5F5'; // Blue
      case 'Accepted':
        return '#66BB6A'; // Green
      case 'Rejected':
        return '#EF5350'; // Red
      case 'Expired':
        return '#78909C'; // Grey
      case 'Converted':
        return '#AB47BC'; // Purple
      default:
        return '#78909C';
    }
  }

  bool get isExpiringSoon {
    final daysUntilExpiry = validUntil.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  bool get isExpiredNow {
    return DateTime.now().isAfter(validUntil) && !isConverted;
  }

  // ─── JSON ──────────────────────────────────────────────────
  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      customerCompany: json['customerCompany'],
      quotationDate: json['quotationDate'] != null 
          ? DateTime.parse(json['quotationDate']) 
          : DateTime.now(),
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil']) 
          : DateTime.now().add(const Duration(days: 30)),
      salesPerson: json['salesPerson'],
      status: json['status'] ?? 'Draft',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
      totalTax: (json['totalTax'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      termsConditions: json['termsConditions'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
      convertedAt: json['convertedAt'] != null ? DateTime.parse(json['convertedAt']) : null,
      convertedOrderId: json['convertedOrderId'],
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
          .map((e) => QuotationItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      convertedOrder: json['convertedOrder'] != null 
          ? ConvertedOrder.fromJson(Map<String, dynamic>.from(json['convertedOrder']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerCompany': customerCompany,
      'quotationDate': quotationDate.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'salesPerson': salesPerson,
      'status': status,
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'grandTotal': grandTotal,
      'notes': notes,
      'termsConditions': termsConditions,
      'sentAt': sentAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'convertedAt': convertedAt?.toIso8601String(),
      'convertedOrderId': convertedOrderId,
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
  String toString() => 'QuotationModel(quotationNumber: $quotationNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// QUOTATION ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class QuotationItemModel {
  final String id;
  final String quotationId;
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

  QuotationItemModel({
    required this.id,
    required this.quotationId,
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

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) {
    return QuotationItemModel(
      id: json['id'] ?? '',
      quotationId: json['quotationId'] ?? '',
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
      'quotationId': quotationId,
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
// CONVERTED ORDER MODEL
// ═══════════════════════════════════════════════════════════════

class ConvertedOrder {
  final String id;
  final String orderNumber;
  final String orderStatus;
  final DateTime? createdAt;

  ConvertedOrder({
    required this.id,
    required this.orderNumber,
    required this.orderStatus,
    this.createdAt,
  });

  factory ConvertedOrder.fromJson(Map<String, dynamic> json) {
    return ConvertedOrder(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      orderStatus: json['orderStatus'] ?? 'Pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUOTATION STATS
// ═══════════════════════════════════════════════════════════════

class QuotationStats {
  final int total;
  final int draft;
  final int sent;
  final int accepted;
  final int rejected;
  final int expired;
  final int converted;
  final double totalValue;
  final double convertedValue;

  QuotationStats({
    required this.total,
    required this.draft,
    required this.sent,
    required this.accepted,
    required this.rejected,
    required this.expired,
    required this.converted,
    required this.totalValue,
    required this.convertedValue,
  });

  factory QuotationStats.fromJson(Map<String, dynamic> json) {
    return QuotationStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      converted: (json['converted'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      convertedValue: (json['convertedValue'] as num?)?.toDouble() ?? 0,
    );
  }
}