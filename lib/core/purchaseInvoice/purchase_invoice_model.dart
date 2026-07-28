// lib/core/warehouse/purchase_invoice/model/purchase_invoice_model.dart

import 'package:intl/intl.dart';

class PurchaseInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final String? supplierEmail;
  final String? supplierPhone;
  final String? supplierInvoiceNo;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? goodsReceivingId;
  final String? grnNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String paymentTerms;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final String invoiceStatus;
  final String paymentStatus;
  final String? notes;
  final DateTime? postedAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? accountsPayableId;
  final String? journalEntryId;
  final String? inventoryAccountId;
  final String? apAccountId;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseInvoiceItemModel> items;
  final JournalEntry? journalEntry;
  final AccountsPayable? accountsPayable;

  PurchaseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierEmail,
    this.supplierPhone,
    this.supplierInvoiceNo,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.goodsReceivingId,
    this.grnNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.paymentTerms,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.invoiceStatus,
    required this.paymentStatus,
    this.notes,
    this.postedAt,
    this.paidAt,
    this.cancelledAt,
    this.accountsPayableId,
    this.journalEntryId,
    this.inventoryAccountId,
    this.apAccountId,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.journalEntry,
    this.accountsPayable,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────
  bool get isDraft => invoiceStatus == 'Draft';
  bool get isPosted => invoiceStatus == 'Posted';
  bool get isPartiallyPaid => invoiceStatus == 'Partially Paid';
  bool get isPaid => invoiceStatus == 'Paid';
  bool get isCancelled => invoiceStatus == 'Cancelled';
  
  bool get isUnpaid => paymentStatus == 'Unpaid';
  bool get isPartial => paymentStatus == 'Partial';
  bool get isFullyPaid => paymentStatus == 'Paid';
  
  bool get canPost => isDraft && !isCancelled;
  bool get canEdit => isDraft && !isCancelled;
  bool get canCancel => (isDraft || isPosted) && !isCancelled && paidAmount == 0;
  bool get canDelete => isDraft && !isCancelled;
  
  bool get isOverdue {
    if (isPaid || isCancelled) return false;
    return DateTime.now().isAfter(dueDate) && outstanding > 0;
  }

  double get outstandingBalance => grandTotal - paidAmount;
  double get paidPercentage => grandTotal > 0 ? (paidAmount / grandTotal) * 100 : 0;
  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // ─── STATUS COLOR ────────────────────────────────────────
  String get statusColor {
    switch (invoiceStatus) {
      case 'Draft':
        return '#FFA726'; // Orange
      case 'Posted':
        return '#42A5F5'; // Blue
      case 'Partially Paid':
        return '#AB47BC'; // Purple
      case 'Paid':
        return '#66BB6A'; // Green
      case 'Cancelled':
        return '#EF5350'; // Red
      default:
        return '#78909C';
    }
  }

  String get paymentStatusColor {
    switch (paymentStatus) {
      case 'Paid':
        return '#66BB6A'; // Green
      case 'Partial':
        return '#FFA726'; // Orange
      default:
        return '#EF5350'; // Red
    }
  }

  // ─── JSON ──────────────────────────────────────────────────
  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json) {
    List<PurchaseInvoiceItemModel> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => PurchaseInvoiceItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    JournalEntry? journalEntry;
    if (json['journalEntry'] != null && json['journalEntry'] is Map<String, dynamic>) {
      journalEntry = JournalEntry.fromJson(json['journalEntry'] as Map<String, dynamic>);
    }

    AccountsPayable? accountsPayable;
    if (json['accountsPayable'] != null && json['accountsPayable'] is Map<String, dynamic>) {
      accountsPayable = AccountsPayable.fromJson(json['accountsPayable'] as Map<String, dynamic>);
    }

    return PurchaseInvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      supplierEmail: json['supplierEmail'],
      supplierPhone: json['supplierPhone'],
      supplierInvoiceNo: json['supplierInvoiceNo'],
      purchaseOrderId: json['purchaseOrderId'],
      purchaseOrderNumber: json['purchaseOrderNumber'],
      goodsReceivingId: json['goodsReceivingId'],
      grnNumber: json['grnNumber'],
      invoiceDate: json['invoiceDate'] != null 
          ? DateTime.parse(json['invoiceDate']) 
          : DateTime.now(),
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      paymentTerms: json['paymentTerms'] ?? 'Net 30',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      invoiceStatus: json['invoiceStatus'] ?? 'Draft',
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      notes: json['notes'],
      postedAt: json['postedAt'] != null ? DateTime.parse(json['postedAt']) : null,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      accountsPayableId: json['accountsPayableId'],
      journalEntryId: json['journalEntryId'],
      inventoryAccountId: json['inventoryAccountId'],
      apAccountId: json['apAccountId'],
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
      journalEntry: journalEntry,
      accountsPayable: accountsPayable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierEmail': supplierEmail,
      'supplierPhone': supplierPhone,
      'supplierInvoiceNo': supplierInvoiceNo,
      'purchaseOrderId': purchaseOrderId,
      'purchaseOrderNumber': purchaseOrderNumber,
      'goodsReceivingId': goodsReceivingId,
      'grnNumber': grnNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paymentTerms': paymentTerms,
      'subtotal': subtotal,
      'discountTotal': discountTotal,
      'taxTotal': taxTotal,
      'grandTotal': grandTotal,
      'paidAmount': paidAmount,
      'outstanding': outstanding,
      'invoiceStatus': invoiceStatus,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'postedAt': postedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'accountsPayableId': accountsPayableId,
      'journalEntryId': journalEntryId,
      'inventoryAccountId': inventoryAccountId,
      'apAccountId': apAccountId,
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
  String toString() => 'PurchaseInvoiceModel(invoiceNumber: $invoiceNumber, status: $invoiceStatus)';
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceItemModel {
  final String id;
  final String invoiceId;
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

  PurchaseInvoiceItemModel({
    required this.id,
    required this.invoiceId,
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

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItemModel(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
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
      'invoiceId': invoiceId,
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
// JOURNAL ENTRY MODEL
// ═══════════════════════════════════════════════════════════════

class JournalEntry {
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
  final List<JournalLine> lines;

  JournalEntry({
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

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    List<JournalLine> lineList = [];
    if (json['lines'] != null && json['lines'] is List) {
      lineList = (json['lines'] as List)
          .map((e) => JournalLine.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return JournalEntry(
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

class JournalLine {
  final String id;
  final String journalId;
  final String accountId;
  final String accountName;
  final String accountCode;
  final bool isReconciled;
  final double debit;
  final double credit;

  JournalLine({
    required this.id,
    required this.journalId,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.isReconciled,
    required this.debit,
    required this.credit,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) {
    return JournalLine(
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
// ACCOUNTS PAYABLE MODEL
// ═══════════════════════════════════════════════════════════════

class AccountsPayable {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String supplierId;
  final String supplierName;
  final double amount;
  final double paidAmount;
  final double outstanding;
  final DateTime dueDate;
  final String status;
  final String? notes;
  final String? accountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PaymentMade>? payments;

  AccountsPayable({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paidAmount,
    required this.outstanding,
    required this.dueDate,
    required this.status,
    this.notes,
    this.accountId,
    required this.createdAt,
    required this.updatedAt,
    this.payments,
  });

  bool get isCurrent => status == 'Current';
  bool get isOverdue => status == 'Overdue';
  bool get isPaid => status == 'Paid';
  bool get isWrittenOff => status == 'WrittenOff';

  factory AccountsPayable.fromJson(Map<String, dynamic> json) {
    List<PaymentMade>? paymentList;
    if (json['payments'] != null && json['payments'] is List) {
      paymentList = (json['payments'] as List)
          .map((e) => PaymentMade.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AccountsPayable(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      status: json['status'] ?? 'Current',
      notes: json['notes'],
      accountId: json['accountId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      payments: paymentList,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT MADE MODEL
// ═══════════════════════════════════════════════════════════════

class PaymentMade {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String supplierId;
  final String supplierName;
  final String billId;
  final String billNumber;
  final double billAmount;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String? bankAccountId;
  final String bankAccountName;
  final String notes;
  final String status;
  final String createdBy;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMade({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.supplierId,
    required this.supplierName,
    required this.billId,
    required this.billNumber,
    required this.billAmount,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    this.bankAccountId,
    required this.bankAccountName,
    required this.notes,
    required this.status,
    required this.createdBy,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';
  bool get isFailed => status == 'Failed';
  bool get isCancelled => status == 'Cancelled';

  factory PaymentMade.fromJson(Map<String, dynamic> json) {
    return PaymentMade(
      id: json['id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : DateTime.now(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      billId: json['billId'] ?? '',
      billNumber: json['billNumber'] ?? '',
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      reference: json['reference'] ?? '',
      bankAccountId: json['bankAccountId'],
      bankAccountName: json['bankAccountName'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Pending',
      createdBy: json['createdBy'] ?? '',
      userId: json['userId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE REQUEST MODEL (For API)
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceRequest {
  final String? goodsReceivingId;
  final String? purchaseOrderId;
  final String? supplierInvoiceNo;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String? paymentTerms;
  final String? notes;

  PurchaseInvoiceRequest({
    this.goodsReceivingId,
    this.purchaseOrderId,
    this.supplierInvoiceNo,
    required this.invoiceDate,
    required this.dueDate,
    this.paymentTerms,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'goodsReceivingId': goodsReceivingId,
      'purchaseOrderId': purchaseOrderId,
      'supplierInvoiceNo': supplierInvoiceNo,
      'invoiceDate': invoiceDate.toIso8601String().split('T').first,
      'dueDate': dueDate.toIso8601String().split('T').first,
      'paymentTerms': paymentTerms,
      'notes': notes,
    };
  }
}