// lib/core/warehouse/purchase_return/model/purchase_return_model.dart

import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════
// PURCHASE RETURN MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseReturnModel {
  final String id;
  final String returnNumber;
  final DateTime returnDate;
  final String supplierId;
  final String supplierName;
  final String purchaseInvoiceId;
  final String purchaseInvoiceNumber;
  final String returnReason;
  final String status;
  final String? notes;
  final int totalReturnQty;
  final double returnAmount;
  final double grandTotal;
  final String? journalEntryId;
  final String? apRecordId;
  final String createdBy;
  final String? updatedBy;
  final String? processedBy;
  final DateTime? processedAt;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseReturnItemModel> items;
  final JournalEntryModel? journalEntry;

  PurchaseReturnModel({
    required this.id,
    required this.returnNumber,
    required this.returnDate,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseInvoiceId,
    required this.purchaseInvoiceNumber,
    required this.returnReason,
    required this.status,
    this.notes,
    required this.totalReturnQty,
    required this.returnAmount,
    required this.grandTotal,
    this.journalEntryId,
    this.apRecordId,
    required this.createdBy,
    this.updatedBy,
    this.processedBy,
    this.processedAt,
    this.cancelledBy,
    this.cancelledAt,
    required this.isActive,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.journalEntry,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────────
  bool get isDraft => status == 'Draft';
  bool get isProcessed => status == 'Processed';
  bool get isCancelled => status == 'Cancelled';
  
  bool get canProcess => isDraft && !isDeleted;
  bool get canCancel => isDraft && !isDeleted;
  bool get canDelete => isCancelled && !isDeleted;
  bool get canPrint => isProcessed;

  // ─── CALCULATIONS ────────────────────────────────────────────
  int get totalItems => items.length;
  
  double get totalReturnValue {
    return items.fold(0, (sum, item) => sum + item.lineTotal);
  }

  // ─── JSON ────────────────────────────────────────────────────
  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    List<PurchaseReturnItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => PurchaseReturnItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    JournalEntryModel? journalEntry;
    if (json['journalEntry'] != null && json['journalEntry'] is Map<String, dynamic>) {
      journalEntry = JournalEntryModel.fromJson(json['journalEntry'] as Map<String, dynamic>);
    }

    return PurchaseReturnModel(
      id: json['id'] ?? '',
      returnNumber: json['returnNumber'] ?? '',
      returnDate: json['returnDate'] != null 
          ? DateTime.parse(json['returnDate']) 
          : DateTime.now(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      purchaseInvoiceId: json['purchaseInvoiceId'] ?? '',
      purchaseInvoiceNumber: json['purchaseInvoiceNumber'] ?? '',
      returnReason: json['returnReason'] ?? '',
      status: json['status'] ?? 'Draft',
      notes: json['notes'],
      totalReturnQty: (json['totalReturnQty'] as num?)?.toInt() ?? 0,
      returnAmount: (json['returnAmount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      journalEntryId: json['journalEntryId'],
      apRecordId: json['apRecordId'],
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'],
      processedBy: json['processedBy'],
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      cancelledBy: json['cancelledBy'],
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
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
      journalEntry: journalEntry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'returnNumber': returnNumber,
      'returnDate': returnDate.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseInvoiceId': purchaseInvoiceId,
      'purchaseInvoiceNumber': purchaseInvoiceNumber,
      'returnReason': returnReason,
      'status': status,
      'notes': notes,
      'totalReturnQty': totalReturnQty,
      'returnAmount': returnAmount,
      'grandTotal': grandTotal,
      'journalEntryId': journalEntryId,
      'apRecordId': apRecordId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'processedBy': processedBy,
      'processedAt': processedAt?.toIso8601String(),
      'cancelledBy': cancelledBy,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'isActive': isActive,
      'isDeleted': isDeleted,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'PurchaseReturnModel(returnNumber: $returnNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE RETURN ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseReturnItemModel {
  final String id;
  final String returnId;
  final String productId;
  final String productName;
  final String sku;
  final String purchaseInvoiceId;
  final String? purchaseInvoiceItemId;
  final int purchasedQuantity;
  final int previouslyReturned;
  final int availableQuantity;
  final int returnQuantity;
  final bool isBoxBased;
  final int? boxes;
  final int? quantityPerBox;
  final double unitPrice;
  final double lineTotal;
  final String returnReason;
  final String condition;
  final String? notes;
  final ProductSummary? product;

  PurchaseReturnItemModel({
    required this.id,
    required this.returnId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.purchaseInvoiceId,
    this.purchaseInvoiceItemId,
    required this.purchasedQuantity,
    required this.previouslyReturned,
    required this.availableQuantity,
    required this.returnQuantity,
    required this.isBoxBased,
    this.boxes,
    this.quantityPerBox,
    required this.unitPrice,
    required this.lineTotal,
    required this.returnReason,
    required this.condition,
    this.notes,
    this.product,
  });

  // ─── CALCULATED FIELDS ──────────────────────────────────────
  int get totalBoxes => boxes ?? 0;
  int get qtyPerBox => quantityPerBox ?? 0;
  int get calculatedReturnQty {
    if (isBoxBased && boxes != null && quantityPerBox != null) {
      return boxes! * quantityPerBox!;
    }
    return returnQuantity;
  }

  bool get canReturnMore => returnQuantity < availableQuantity;
  bool get isFullyReturned => returnQuantity >= availableQuantity;
  bool get hasPreviousReturns => previouslyReturned > 0;

  // ─── JSON ────────────────────────────────────────────────────
  factory PurchaseReturnItemModel.fromJson(Map<String, dynamic> json) {
    ProductSummary? product;
    if (json['product'] != null && json['product'] is Map<String, dynamic>) {
      product = ProductSummary.fromJson(json['product'] as Map<String, dynamic>);
    }

    return PurchaseReturnItemModel(
      id: json['id'] ?? '',
      returnId: json['returnId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      purchaseInvoiceId: json['purchaseInvoiceId'] ?? '',
      purchaseInvoiceItemId: json['purchaseInvoiceItemId'],
      purchasedQuantity: (json['purchasedQuantity'] as num?)?.toInt() ?? 0,
      previouslyReturned: (json['previouslyReturned'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      returnQuantity: (json['returnQuantity'] as num?)?.toInt() ?? 0,
      isBoxBased: json['isBoxBased'] ?? false,
      boxes: (json['boxes'] as num?)?.toInt(),
      quantityPerBox: (json['quantityPerBox'] as num?)?.toInt(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      returnReason: json['returnReason'] ?? '',
      condition: json['condition'] ?? 'Good',
      notes: json['notes'],
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'returnId': returnId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'purchaseInvoiceId': purchaseInvoiceId,
      'purchaseInvoiceItemId': purchaseInvoiceItemId,
      'purchasedQuantity': purchasedQuantity,
      'previouslyReturned': previouslyReturned,
      'availableQuantity': availableQuantity,
      'returnQuantity': returnQuantity,
      'isBoxBased': isBoxBased,
      'boxes': boxes,
      'quantityPerBox': quantityPerBox,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'returnReason': returnReason,
      'condition': condition,
      'notes': notes,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT SUMMARY MODEL
// ═══════════════════════════════════════════════════════════════

class ProductSummary {
  final String id;
  final String name;
  final String sku;
  final bool isBoxBased;
  final int boxQuantity;
  final String boxUnitName;
  final double costPrice;

  ProductSummary({
    required this.id,
    required this.name,
    required this.sku,
    required this.isBoxBased,
    required this.boxQuantity,
    required this.boxUnitName,
    required this.costPrice,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      isBoxBased: json['isBoxBased'] ?? false,
      boxQuantity: (json['boxQuantity'] as num?)?.toInt() ?? 0,
      boxUnitName: json['boxUnitName'] ?? 'Box',
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNAL ENTRY MODEL (Shared)
// ═══════════════════════════════════════════════════════════════

class JournalEntryModel {
  final String id;
  final String entryNumber;
  final DateTime date;
  final String description;
  final String reference;
  final String status;
  final String createdBy;
  final String? postedBy;
  final DateTime? postedAt;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JournalLineModel> lines;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.date,
    required this.description,
    required this.reference,
    required this.status,
    required this.createdBy,
    this.postedBy,
    this.postedAt,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
  });

  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    List<JournalLineModel> lineList = [];
    if (json['lines'] != null && json['lines'] is List) {
      lineList = (json['lines'] as List)
          .map((e) => JournalLineModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return JournalEntryModel(
      id: json['id'] ?? '',
      entryNumber: json['entryNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? 'Draft',
      createdBy: json['createdBy'] ?? '',
      postedBy: json['postedBy'],
      postedAt: json['postedAt'] != null ? DateTime.parse(json['postedAt']) : null,
      userId: json['userId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      lines: lineList,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNAL LINE MODEL
// ═══════════════════════════════════════════════════════════════

class JournalLineModel {
  final String id;
  final String journalId;
  final String accountId;
  final String accountName;
  final String accountCode;
  final bool isReconciled;
  final double debit;
  final double credit;

  JournalLineModel({
    required this.id,
    required this.journalId,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.isReconciled,
    required this.debit,
    required this.credit,
  });

  bool get isDebit => debit > 0;
  bool get isCredit => credit > 0;
  double get amount => debit + credit;

  factory JournalLineModel.fromJson(Map<String, dynamic> json) {
    return JournalLineModel(
      id: json['id'] ?? '',
      journalId: json['journalId'] ?? '',
      accountId: json['accountId'] ?? '',
      accountName: json['accountName'] ?? '',
      accountCode: json['accountCode'] ?? '',
      isReconciled: json['isReconciled'] ?? false,
      debit: (json['debit'] as num?)?.toDouble() ?? 0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REQUEST MODELS
// ═══════════════════════════════════════════════════════════════

class CreateReturnRequest {
  final String supplierId;
  final String supplierName;
  final String purchaseInvoiceId;
  final String purchaseInvoiceNumber;
  final String returnReason;
  final String? notes;
  final List<ReturnItemRequest> items;

  CreateReturnRequest({
    required this.supplierId,
    required this.supplierName,
    required this.purchaseInvoiceId,
    required this.purchaseInvoiceNumber,
    required this.returnReason,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseInvoiceId': purchaseInvoiceId,
      'purchaseInvoiceNumber': purchaseInvoiceNumber,
      'returnReason': returnReason,
      'notes': notes ?? '',
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class ReturnItemRequest {
  final String productId;
  final String productName;
  final String sku;
  final String purchaseInvoiceItemId;
  final int returnQuantity;
  final bool isBoxBased;
  final int? boxes;
  final int? quantityPerBox;
  final double unitPrice;
  final String returnReason;
  final String? notes;

  ReturnItemRequest({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.purchaseInvoiceItemId,
    required this.returnQuantity,
    required this.isBoxBased,
    this.boxes,
    this.quantityPerBox,
    required this.unitPrice,
    required this.returnReason,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'purchaseInvoiceItemId': purchaseInvoiceItemId,
      'returnQuantity': returnQuantity,
      'isBoxBased': isBoxBased,
      'boxes': boxes,
      'quantityPerBox': quantityPerBox,
      'unitPrice': unitPrice,
      'returnReason': returnReason,
      'notes': notes ?? '',
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// INVOICE FOR RETURN MODEL
// ═══════════════════════════════════════════════════════════════

class InvoiceForReturn {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String supplierId;
  final String supplierName;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final String invoiceStatus;
  final String paymentStatus;
  final List<InvoiceItemForReturn> items;

  InvoiceForReturn({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.supplierId,
    required this.supplierName,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.invoiceStatus,
    required this.paymentStatus,
    required this.items,
  });

  bool get isFullyPaid => paymentStatus == 'Paid';
  bool get isUnpaid => paymentStatus == 'Unpaid' || paymentStatus == 'Partial';

  factory InvoiceForReturn.fromJson(Map<String, dynamic> json) {
    List<InvoiceItemForReturn> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => InvoiceItemForReturn.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return InvoiceForReturn(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: json['invoiceDate'] != null ? DateTime.parse(json['invoiceDate']) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      invoiceStatus: json['invoiceStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      items: itemList,
    );
  }
}

class InvoiceItemForReturn {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final bool isBoxBased;
  final int boxQuantity;
  final String boxUnitName;
  final int availableReturnQty;
  final int previouslyReturned;

  InvoiceItemForReturn({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isBoxBased,
    required this.boxQuantity,
    required this.boxUnitName,
    required this.availableReturnQty,
    required this.previouslyReturned,
  });

  factory InvoiceItemForReturn.fromJson(Map<String, dynamic> json) {
    return InvoiceItemForReturn(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      sku: json['sku'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      isBoxBased: json['isBoxBased'] ?? false,
      boxQuantity: (json['boxQuantity'] as num?)?.toInt() ?? 0,
      boxUnitName: json['boxUnitName'] ?? 'Box',
      availableReturnQty: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      previouslyReturned: (json['previouslyReturned'] as num?)?.toInt() ?? 0,
    );
  }
}