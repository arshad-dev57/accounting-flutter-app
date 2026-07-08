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
      creditNoteNumber: json['creditNoteNumber'] ?? '',
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
          .toList() ?? [],
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
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;

  CreditNoteItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory CreditNoteItem.fromJson(Map<String, dynamic> json) {
    return CreditNoteItem(
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
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

class InvoiceForCreditNote {
  final String id;
  final String invoiceNumber;
  final double amount;
  final double outstanding;
  final DateTime date;
  final String status;

  InvoiceForCreditNote({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.outstanding,
    required this.date,
    required this.status,
  });

  factory InvoiceForCreditNote.fromJson(Map<String, dynamic> json) {
    return InvoiceForCreditNote(
      id: json['id'] ?? json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: json['status'] ?? '',
    );
  }
}