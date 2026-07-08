// lib/core/warehouse/sales_payment/model/sales_payment_model.dart

import 'package:intl/intl.dart';

class SalesPaymentModel {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String customerId;
  final String customerName;
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
  final List<InvoicePaymentModel> invoicePayments;
  final JournalEntryModel? journalEntry;

  SalesPaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.customerId,
    required this.customerName,
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
  factory SalesPaymentModel.fromJson(Map<String, dynamic> json) {
    // Safely handle invoicePayments list
    List<InvoicePaymentModel> invoicePaymentList = [];
    if (json['invoicePayments'] != null && json['invoicePayments'] is List) {
      invoicePaymentList = (json['invoicePayments'] as List)
          .map((e) => InvoicePaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Safely handle journalEntry
    JournalEntryModel? journalEntry;
    if (json['journalEntry'] != null && json['journalEntry'] is Map<String, dynamic>) {
      journalEntry = JournalEntryModel.fromJson(json['journalEntry'] as Map<String, dynamic>);
    }

    return SalesPaymentModel(
      id: json['id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : DateTime.now(),
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
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
      'customerId': customerId,
      'customerName': customerName,
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
  String toString() => 'SalesPaymentModel(paymentNumber: $paymentNumber, status: $status)';
}

// ═══════════════════════════════════════════════════════════════
// INVOICE PAYMENT MODEL
// ═══════════════════════════════════════════════════════════════

class InvoicePaymentModel {
  final String id;
  final String paymentId;
  final String invoiceId;
  final String invoiceNumber;
  final double amountPaid;
  final SalesInvoiceSummary? invoice;

  InvoicePaymentModel({
    required this.id,
    required this.paymentId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amountPaid,
    this.invoice,
  });

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    SalesInvoiceSummary? invoice;
    if (json['invoice'] != null && json['invoice'] is Map<String, dynamic>) {
      invoice = SalesInvoiceSummary.fromJson(json['invoice'] as Map<String, dynamic>);
    }

    return InvoicePaymentModel(
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
// SALES INVOICE SUMMARY MODEL
// ═══════════════════════════════════════════════════════════════

class SalesInvoiceSummary {
  final String id;
  final String invoiceNumber;
  final double grandTotal;
  final double outstanding;

  SalesInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.grandTotal,
    required this.outstanding,
  });

  factory SalesInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceSummary(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOURNAL ENTRY MODEL
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

class PaymentRequest {
  final String customerId;
  final String customerName;
  final double amount;
  final String paymentMethod;
  final String? bankAccountId;
  final String? bankAccountName;
  final String? reference;
  final String? notes;
  final List<InvoicePaymentRequest> invoicePayments;

  PaymentRequest({
    required this.customerId,
    required this.customerName,
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
      'customerId': customerId,
      'customerName': customerName,
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

class InvoicePaymentRequest {
  final String invoiceId;
  final String invoiceNumber;
  final double amountPaid;

  InvoicePaymentRequest({
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