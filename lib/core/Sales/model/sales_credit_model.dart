class SalesCredit {
  final String id;
  final String creditNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String originalInvoiceId;
  final String? salesInvoiceId;
  final String invoiceSource;
  final String originalInvoiceNumber;
  final double originalInvoiceAmount;
  final double amount;
  final String reason;
  final String reasonType;
  final List<SalesCreditItem> items;
  final String status;
  final double appliedAmount;
  final double remainingAmount;
  final DateTime? expiryDate;
  final String notes;
  final List<Map<String, dynamic>> appliedToInvoices;

  SalesCredit({
    required this.id,
    required this.creditNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.originalInvoiceId,
    this.salesInvoiceId,
    this.invoiceSource = 'warehouse',
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
    this.appliedToInvoices = const [],
  });

  bool get canApply =>
      remainingAmount > 0 &&
      !['Applied', 'Expired', 'Voided', 'Cancelled'].contains(status);

  factory SalesCredit.fromJson(Map<String, dynamic> json) {
    final originalId = json['originalInvoiceId'] is Map
        ? json['originalInvoiceId']['id']?.toString() ?? ''
        : json['originalInvoiceId']?.toString() ?? '';
    final salesId = json['salesInvoiceId'] is Map
        ? json['salesInvoiceId']['id']?.toString()
        : json['salesInvoiceId']?.toString();

    return SalesCredit(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      creditNumber:
          json['creditNumber']?.toString() ??
          json['creditNoteNumber']?.toString() ??
          '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      customerId: json['customerId'] is Map
          ? json['customerId']['id']?.toString() ?? ''
          : json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      originalInvoiceId: originalId.isNotEmpty
          ? originalId
          : (salesId ?? ''),
      salesInvoiceId: salesId,
      invoiceSource: json['invoiceSource']?.toString() ?? 'warehouse',
      originalInvoiceNumber: json['originalInvoiceNumber']?.toString() ?? '',
      originalInvoiceAmount: _d(json['originalInvoiceAmount']),
      amount: _d(json['amount']),
      reason: json['reason']?.toString() ?? '',
      reasonType: json['reasonType']?.toString() ?? '',
      items: (json['items'] as List?)
              ?.map((e) => SalesCreditItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'Issued',
      appliedAmount: _d(json['appliedAmount']),
      remainingAmount: _d(json['remainingAmount']),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      notes: json['notes']?.toString() ?? '',
      appliedToInvoices: (json['appliedToInvoices'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class SalesCreditItem {
  final String? productId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;

  SalesCreditItem({
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory SalesCreditItem.fromJson(Map<String, dynamic> json) {
    return SalesCreditItem(
      productId: json['productId']?.toString(),
      description:
          json['description']?.toString() ??
          json['productName']?.toString() ??
          '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: SalesCredit._d(json['unitPrice']),
      amount: SalesCredit._d(json['amount'] ?? json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (productId != null) 'productId': productId,
        'productName': description,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'amount': amount,
      };
}

class SalesCreditInvoice {
  final String id;
  final String invoiceNumber;
  final double amount;
  final double paidAmount;
  final double outstanding;
  final double totalCredited;
  final double eligibleCredit;
  final DateTime date;
  final String status;
  final String? invoiceStatus;
  final String invoiceSource;
  final List<SalesCreditLineItem> items;

  SalesCreditInvoice({
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
    this.invoiceSource = 'warehouse',
    this.items = const [],
  });

  factory SalesCreditInvoice.fromJson(Map<String, dynamic> json) {
    final grandTotal = SalesCredit._d(json['amount'] ?? json['grandTotal']);
    final paid = SalesCredit._d(json['paidAmount']);
    final credited = SalesCredit._d(json['totalCredited']);
    final eligible = SalesCredit._d(
      json['eligibleCredit'] ?? (grandTotal - credited),
    );

    return SalesCreditInvoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      amount: grandTotal,
      paidAmount: paid,
      outstanding: SalesCredit._d(json['outstanding'] ?? (grandTotal - paid)),
      totalCredited: credited,
      eligibleCredit: eligible,
      date: DateTime.tryParse(
            json['date']?.toString() ?? json['invoiceDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? json['paymentStatus']?.toString() ?? '',
      invoiceStatus: json['invoiceStatus']?.toString(),
      invoiceSource: json['invoiceSource']?.toString() ?? 'warehouse',
      items: (json['items'] as List?)
              ?.map(
                (e) => SalesCreditLineItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
    );
  }
}

class SalesCreditLineItem {
  final String id;
  final String? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  int returnQty;

  SalesCreditLineItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.returnQty = 0,
  });

  factory SalesCreditLineItem.fromJson(Map<String, dynamic> json) {
    return SalesCreditLineItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: SalesCredit._d(json['unitPrice']),
      totalPrice: SalesCredit._d(json['totalPrice']),
    );
  }

  double get lineCredit => returnQty * unitPrice;
}

class SalesCreditSummary {
  final int total;
  final double totalAmount;
  final double remainingAmount;
  final double appliedAmount;

  SalesCreditSummary({
    this.total = 0,
    this.totalAmount = 0,
    this.remainingAmount = 0,
    this.appliedAmount = 0,
  });

  factory SalesCreditSummary.fromJson(Map<String, dynamic> json) {
    return SalesCreditSummary(
      total: (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          0,
      totalAmount: SalesCredit._d(json['totalAmount'] ?? json['amount']),
      remainingAmount: SalesCredit._d(json['remainingAmount']),
      appliedAmount: SalesCredit._d(json['appliedAmount']),
    );
  }
}
