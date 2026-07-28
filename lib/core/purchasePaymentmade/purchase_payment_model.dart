// lib/core/warehouse/purchase_payment/model/purchase_payment_model.dart

import 'package:intl/intl.dart';

class PurchasePaymentModel {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String supplierId;
  final String supplierName;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String? bankAccountId;
  final String bankAccountName;
  final String notes;
  final String status;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseInvoicePaymentModel> invoicePayments;
  final JournalEntryModel? journalEntry;

  PurchasePaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    this.bankAccountId,
    required this.bankAccountName,
    required this.notes,
    required this.status,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.invoicePayments,
    this.journalEntry,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────
  bool get isCompleted => status == 'Completed';
  bool get isPending => status == 'Pending';
  bool get isFailed => status == 'Failed';
  bool get isCancelled => status == 'Cancelled';
  
  bool get canCancel => isCompleted && !isCancelled;
  bool get canDelete => isCancelled;

  // ─── PAYMENT METHOD HELPERS ─────────────────────────────
  bool get isCash => paymentMethod == 'Cash';
  bool get isBankTransfer => paymentMethod == 'Bank Transfer';
  bool get isCheque => paymentMethod == 'Cheque';
  bool get isCreditCard => paymentMethod == 'Credit Card';
  bool get isOnlinePayment => paymentMethod == 'Online Payment';

  // ─── CALCULATIONS ──────────────────────────────────────
  int get totalInvoices => invoicePayments.length;
  double get totalPaidAmount => invoicePayments.fold(0, (sum, inv) => sum + inv.amountPaid);

  // ─── JSON ──────────────────────────────────────────────────
  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    // Safely handle invoicePayments list
    List<PurchaseInvoicePaymentModel> invoicePaymentList = [];
    if (json['invoicePayments'] != null && json['invoicePayments'] is List) {
      invoicePaymentList = (json['invoicePayments'] as List)
          .map((e) => PurchaseInvoicePaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Safely handle journalEntry
    JournalEntryModel? journalEntry;
    if (json['journalEntry'] != null && json['journalEntry'] is Map<String, dynamic>) {
      journalEntry = JournalEntryModel.fromJson(json['journalEntry'] as Map<String, dynamic>);
    }

    return PurchasePaymentModel(
      id: json['id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : DateTime.now(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      reference: json['reference'] ?? '',
      bankAccountId: json['bankAccountId'],
      bankAccountName: json['bankAccountName'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'Completed',
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
      invoicePayments: invoicePaymentList,
      journalEntry: journalEntry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'notes': notes,
      'status': status,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'invoicePayments': invoicePayments.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'PurchasePaymentModel(paymentNumber: $paymentNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE PAYMENT MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoicePaymentModel {
  final String id;
  final String paymentId;
  final String invoiceId;
  final String invoiceNumber;
  final double amountPaid;
  final PurchaseInvoiceSummary? invoice;

  PurchaseInvoicePaymentModel({
    required this.id,
    required this.paymentId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amountPaid,
    this.invoice,
  });

  factory PurchaseInvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    PurchaseInvoiceSummary? invoice;
    if (json['invoice'] != null && json['invoice'] is Map<String, dynamic>) {
      invoice = PurchaseInvoiceSummary.fromJson(json['invoice'] as Map<String, dynamic>);
    }

    return PurchaseInvoicePaymentModel(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      invoice: invoice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'amountPaid': amountPaid,
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// PURCHASE INVOICE SUMMARY MODEL
// ═══════════════════════════════════════════════════════════════

class PurchaseInvoiceSummary {
  final String id;
  final String invoiceNumber;
  final double grandTotal;
  final double outstanding;
  final String? supplierInvoiceNo;

  PurchaseInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.grandTotal,
    required this.outstanding,
    this.supplierInvoiceNo,
  });

  factory PurchaseInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceSummary(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      supplierInvoiceNo: json['supplierInvoiceNo'],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNAL ENTRY MODEL (Shared with Sales)
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
// PAYMENT REQUEST MODEL (For API)
// ═══════════════════════════════════════════════════════════════

class PurchasePaymentRequest {
  final String supplierId;
  final String supplierName;
  final double amount;
  final String paymentMethod;
  final String? bankAccountId;
  final String? bankAccountName;
  final String? reference;
  final String? notes;
  final List<PurchaseInvoicePaymentRequest> invoicePayments;

  PurchasePaymentRequest({
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    this.bankAccountName,
    this.reference,
    this.notes,
    required this.invoicePayments,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'reference': reference ?? '',
      'notes': notes ?? '',
      'invoicePayments': invoicePayments.map((e) => e.toJson()).toList(),
    };
  }
}

class PurchaseInvoicePaymentRequest {
  final String invoiceId;
  final String invoiceNumber;
  final double amountPaid;

  PurchaseInvoicePaymentRequest({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amountPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'amountPaid': amountPaid,
    };
  }
}