class WarehouseInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? orderId;
  final String? orderNumber;
  final String? customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final List<WarehouseInvoiceItemModel> items;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final double paidAmount;
  final double creditIssued;
  final double netOutstanding;
  final String invoiceStatus;
  final String paymentStatus;
  final String? notes;
  final DateTime invoiceDate;
  final DateTime dueDate;

  WarehouseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.orderId,
    this.orderNumber,
    this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.paidAmount,
    this.creditIssued = 0,
    this.netOutstanding = 0,
    required this.invoiceStatus,
    required this.paymentStatus,
    this.notes,
    required this.invoiceDate,
    required this.dueDate,
  });

  double get outstanding {
    if (netOutstanding != 0 || creditIssued > 0) return netOutstanding;
    return grandTotal - paidAmount;
  }

  String get displayStatus {
    if (netOutstanding < 0 || (creditIssued > 0 && netOutstanding < 0)) return 'Credit Balance';
    if (netOutstanding == 0 && (paidAmount > 0 || creditIssued > 0)) return 'Paid';
    return paymentStatus;
  }
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && paymentStatus != 'Paid';

  factory WarehouseInvoiceModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      items: (json['items'] as List?)
              ?.map((e) => WarehouseInvoiceItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      subtotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['taxTotal']),
      discountTotal: _toDouble(json['discountTotal']),
      grandTotal: _toDouble(json['grandTotal']),
      paidAmount: _toDouble(json['paidAmount']),
      creditIssued: _toDouble(json['creditIssued']),
      netOutstanding: _toDouble(json['netOutstanding']),
      invoiceStatus: json['invoiceStatus']?.toString() ?? 'Draft',
      paymentStatus: json['paymentStatus']?.toString() ?? 'Unpaid',
      notes: json['notes']?.toString(),
      invoiceDate: _parseDate(json['invoiceDate'] ?? json['createdAt']),
      dueDate: _parseDate(json['dueDate']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

class WarehouseInvoiceItemModel {
  final String productName;
  final String? sku;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double discount;
  final double totalPrice;
  final String? productId;

  WarehouseInvoiceItemModel({
    required this.productName,
    this.sku,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.discount,
    required this.totalPrice,
    this.productId,
  });

  factory WarehouseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceItemModel(
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: WarehouseInvoiceModel._toDouble(json['unitPrice']),
      taxRate: WarehouseInvoiceModel._toDouble(json['taxRate']),
      taxAmount: WarehouseInvoiceModel._toDouble(json['taxAmount']),
      discount: WarehouseInvoiceModel._toDouble(json['discount']),
      totalPrice: WarehouseInvoiceModel._toDouble(json['totalPrice']),
      productId: json['productId']?.toString(),
    );
  }
}

class WarehouseInvoiceStats {
  final int total;
  final int draft;
  final int sent;
  final int paid;
  final int partial;
  final int overdue;
  final double grandTotal;
  final double paidAmount;
  final double outstanding;
  final double taxTotal;

  WarehouseInvoiceStats({
    required this.total,
    required this.draft,
    required this.sent,
    required this.paid,
    required this.partial,
    required this.overdue,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstanding,
    required this.taxTotal,
  });

  factory WarehouseInvoiceStats.fromJson(Map<String, dynamic> json) {
    return WarehouseInvoiceStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      sent: (json['sent'] as num?)?.toInt() ?? 0,
      paid: (json['paid'] as num?)?.toInt() ?? 0,
      partial: (json['partial'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      grandTotal: WarehouseInvoiceModel._toDouble(json['grandTotal']),
      paidAmount: WarehouseInvoiceModel._toDouble(json['paidAmount']),
      outstanding: WarehouseInvoiceModel._toDouble(json['outstanding']),
      taxTotal: WarehouseInvoiceModel._toDouble(json['taxTotal']),
    );
  }
}

class TrendPoint {
  final String date;
  final double revenue;
  final double collected;
  final int count;

  TrendPoint({required this.date, this.revenue = 0, this.collected = 0, this.count = 0});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date']?.toString() ?? '',
      revenue: WarehouseInvoiceModel._toDouble(json['revenue']),
      collected: WarehouseInvoiceModel._toDouble(json['collected']),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
