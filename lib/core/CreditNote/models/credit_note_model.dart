class CreditNote {
  final String id;
  final String creditNoteNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String originalInvoiceId;
  final String originalInvoiceNumber;
  final double originalInvoiceAmount;
  final double amount;
  final String reason;
  final String reasonType;
  final List<CreditNoteItem> items;
  final String status;
  final double appliedAmount;
  final double remainingAmount;
  final DateTime? expiryDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditNote({
    required this.id,
    required this.creditNoteNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.originalInvoiceId,
    required this.originalInvoiceNumber,
    required this.originalInvoiceAmount,
    required this.amount,
    required this.reason,
    required this.reasonType,
    required this.items,
    required this.status,
    required this.appliedAmount,
    required this.remainingAmount,
    this.expiryDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['_id'] ?? json['id'] ?? '',
      creditNoteNumber: json['creditNoteNumber'] ?? json['creditNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      customerId: json['customerId'] is Map
          ? json['customerId']['_id']
          : json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      originalInvoiceId: json['originalInvoiceId'] is Map
          ? json['originalInvoiceId']['_id']
          : json['originalInvoiceId'] ?? '',
      originalInvoiceNumber: json['originalInvoiceNumber'] ?? '',
      originalInvoiceAmount: (json['originalInvoiceAmount'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      reasonType: json['reasonType'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CreditNoteItem.fromJson(item))
              .toList() ??
          [],
      status: json['status'] ?? 'Issued',
      appliedAmount: (json['appliedAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class CreditNoteItem {
  final String? productId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;
  final double? taxRate;
  final double? discount;

  CreditNoteItem({
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.taxRate,
    this.discount,
  });

  factory CreditNoteItem.fromJson(Map<String, dynamic> json) {
    return CreditNoteItem(
      productId: json['productId']?.toString(),
      description: json['description'] ?? json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      amount: (json['amount'] ?? json['totalPrice'] ?? 0).toDouble(),
      taxRate: json['taxRate'] != null ? (json['taxRate'] as num).toDouble() : null,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (productId != null) 'productId': productId,
        'productName': description,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'amount': amount,
        if (taxRate != null) 'taxRate': taxRate,
        if (discount != null) 'discount': discount,
      };
}

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class InvoiceLineItemForCredit {
  final String id;
  final String? productId;
  final String productName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double totalPrice;

  InvoiceLineItemForCredit({
    required this.id,
    this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.discount,
    required this.totalPrice,
  });

  factory InvoiceLineItemForCredit.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItemForCredit(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName'] ?? '',
      sku: json['sku']?.toString(),
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }
}

class InvoiceForCreditNote {
  final String id;
  final String invoiceNumber;
  final double amount;           // invoice total (grandTotal)
  final double paidAmount;
  final double outstanding;
  final double totalCredited;
  final double eligibleCredit;   // amount - totalCredited
  final DateTime date;
  final String status;
  final String? invoiceStatus;
  final List<InvoiceLineItemForCredit> items;
  final List<Map<String, dynamic>> creditNotes;

  InvoiceForCreditNote({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.paidAmount,
    required this.outstanding,
    required this.totalCredited,
    required this.eligibleCredit,
    required this.date,
    required this.status,
    this.invoiceStatus,
    required this.items,
    this.creditNotes = const [],
  });

  /// Net balance after payments and credits (can be negative = credit balance)
  double get netOutstanding => amount - paidAmount - totalCredited;

  String get displayStatus {
    if (netOutstanding < 0) return 'Credit Balance';
    if (netOutstanding == 0 && (paidAmount > 0 || totalCredited > 0)) return 'Paid';
    return status;
  }

  factory InvoiceForCreditNote.fromJson(Map<String, dynamic> json) {
    final grandTotal = (json['amount'] ?? json['grandTotal'] ?? 0).toDouble();
    final paid = (json['paidAmount'] ?? 0).toDouble();
    final credited = (json['totalCredited'] ?? 0).toDouble();
    final eligible = (json['eligibleCredit'] ?? (grandTotal - credited)).toDouble();

    return InvoiceForCreditNote(
      id: json['id'] ?? json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      amount: grandTotal,
      paidAmount: paid,
      outstanding: (json['outstanding'] ?? (grandTotal - paid)).toDouble(),
      totalCredited: credited,
      eligibleCredit: eligible,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : json['invoiceDate'] != null
              ? DateTime.parse(json['invoiceDate'])
              : DateTime.now(),
      status: json['status'] ?? json['paymentStatus'] ?? '',
      invoiceStatus: json['invoiceStatus']?.toString(),
      items: (json['items'] as List?)
              ?.map((i) => InvoiceLineItemForCredit.fromJson(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      creditNotes: (json['creditNotes'] as List?)
              ?.map((c) => Map<String, dynamic>.from(c))
              .toList() ??
          [],
    );
  }
}
