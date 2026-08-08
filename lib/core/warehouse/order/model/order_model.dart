class OrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerCompany;
  final String? customerType;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double taxTotal;
  final double shippingCost;
  final double discountTotal;
  final double grandTotal;
  final int totalItems;
  final String orderStatus;
  final String paymentStatus;
  final String? paymentMethod;
  final String orderType;
  final String priority;
  final String? source;
  final String? salesPerson;
  final String? shippingMethod;
  final String? shippingCarrier;
  final String? couponCode;
  final String? customerNotes;
  final String? internalNotes;
  final List<String> tags;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveryDate;
  final DateTime? updatedAt;
  final UserInfo? creator;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerCompany,
    this.customerType,
    this.shippingAddress,
    this.billingAddress,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    required this.shippingCost,
    required this.discountTotal,
    required this.grandTotal,
    required this.totalItems,
    required this.orderStatus,
    required this.paymentStatus,
    this.paymentMethod,
    this.orderType = 'Standard',
    this.priority = 'Medium',
    this.source,
    this.salesPerson,
    this.shippingMethod,
    this.shippingCarrier,
    this.couponCode,
    this.customerNotes,
    this.internalNotes,
    this.tags = const [],
    required this.orderDate,
    this.expectedDeliveryDate,
    this.deliveryDate,
    this.updatedAt,
    this.creator,
  });

  String get status => orderStatus;
  double get total => grandTotal;
  double get discount => discountTotal;
  DateTime get createdAt => orderDate;
  String? get notes => customerNotes;

  String get shippingAddressText {
    return _formatAddress(shippingAddress);
  }

  String get billingAddressText {
    return _formatAddress(billingAddress);
  }

  static String _formatAddress(Map<String, dynamic>? address) {
    if (address == null || address.isEmpty) return '';
    final full = address['fullAddress']?.toString();
    if (full != null && full.isNotEmpty) return full;
    return [
      address['street'],
      address['city'],
      address['state'],
      address['postalCode'],
      address['country'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: _readId(json['id'] ?? json['_id']),
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      customerCompany: json['customerCompany']?.toString(),
      customerType: json['customerType']?.toString(),
      shippingAddress: _readMap(json['shippingAddress']),
      billingAddress: _readMap(json['billingAddress']),
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      subtotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['taxTotal']),
      shippingCost: _toDouble(json['shippingCost']),
      discountTotal: _toDouble(json['discountTotal'] ?? json['discount']),
      grandTotal: _toDouble(json['grandTotal'] ?? json['total']),
      totalItems: (json['totalItems'] as num?)?.toInt() ??
          ((json['items'] as List?)?.fold<int>(
                0,
                (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
              ) ??
              0),
      orderStatus: json['orderStatus']?.toString() ??
          json['status']?.toString() ??
          'Pending',
      paymentStatus: _normalizePaymentStatus(
        json['paymentStatus']?.toString() ?? 'Pending',
      ),
      paymentMethod: json['paymentMethod']?.toString(),
      orderType: json['orderType']?.toString() ?? 'Standard',
      priority: json['priority']?.toString() ?? 'Medium',
      source: json['source']?.toString(),
      salesPerson: json['salesPerson']?.toString(),
      shippingMethod: json['shippingMethod']?.toString(),
      shippingCarrier: json['shippingCarrier']?.toString(),
      couponCode: json['couponCode']?.toString(),
      customerNotes: json['customerNotes']?.toString() ?? json['notes']?.toString(),
      internalNotes: json['internalNotes']?.toString(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      orderDate: _parseDate(json['orderDate'] ?? json['createdAt']),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? _parseDate(json['expectedDeliveryDate'])
          : null,
      deliveryDate:
          json['deliveryDate'] != null ? _parseDate(json['deliveryDate']) : null,
      updatedAt:
          json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
      creator: json['creator'] != null
          ? UserInfo.fromJson(Map<String, dynamic>.from(json['creator']))
          : json['createdBy'] is Map
              ? UserInfo.fromJson(Map<String, dynamic>.from(json['createdBy']))
              : null,
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _normalizePaymentStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'paid') return 'Paid';
    if (s == 'partial' || s == 'partially paid') return 'Partial';
    if (s == 'refunded') return 'Refunded';
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    if (s == 'unpaid' || s == 'pending') return 'Pending';
    return status.isEmpty ? 'Pending' : status;
  }

  static String _readId(dynamic value) => value?.toString() ?? '';

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double weight;
  final String weightUnit;
  final String? dimensions;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.weight = 0,
    this.weightUnit = 'KG',
    this.dimensions,
  });

  String get productSku => sku;
  double get price => unitPrice;
  double get total => totalPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? json['productSku']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: OrderModel._toDouble(json['unitPrice'] ?? json['price']),
      totalPrice: OrderModel._toDouble(json['totalPrice'] ?? json['total']),
      weight: OrderModel._toDouble(json['weight']),
      weightUnit: json['weightUnit']?.toString() ?? 'KG',
      dimensions: json['dimensions']?.toString(),
    );
  }
}

class UserInfo {
  final String id;
  final String name;
  final String? email;

  UserInfo({required this.id, required this.name, this.email});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final combinedName = '$firstName $lastName'.trim();

    return UserInfo(
      id: OrderModel._readId(json['id'] ?? json['_id']),
      name: combinedName.isNotEmpty
          ? combinedName
          : json['name']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }
}

class OrderAddress {
  String street;
  String city;
  String state;
  String postalCode;
  String country;

  OrderAddress({
    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'Pakistan',
  });

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };

  factory OrderAddress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return OrderAddress();
    return OrderAddress(
      street: map['street']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? '',
      country: map['country']?.toString() ?? 'Pakistan',
    );
  }
}

class CreateOrderLineItem {
  final String productId;
  final String productName;
  final String sku;
  int quantity;
  final double unitPrice;
  double totalPrice;
  final double weight;
  final String weightUnit;
  final String dimensions;

  CreateOrderLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.weight = 0,
    this.weightUnit = 'KG',
    this.dimensions = '',
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'weight': weight,
        'weightUnit': weightUnit,
        'dimensions': dimensions,
        'taxRate': 0,
        'taxAmount': 0,
        'discount': 0,
        'notes': '',
      };
}
