// lib/core/warehouse/customer/model/customer_model.dart

import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════
// CUSTOMER MODEL
// ═══════════════════════════════════════════════════════════════

class CustomerModel {
  final String id;
  final String customerNumber;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String customerType;
  final String? taxId;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String status;
  final int loyaltyPoints;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastOrderDate;
  final double outstandingBalance;
  final String? notes;
  final List<String> tags;
  final Map<String, dynamic>? preferences;
  final String createdBy;
  final String? updatedBy;
  final bool isActive;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? recentOrders;

  CustomerModel({
    required this.id,
    required this.customerNumber,
    required this.name,
    this.email,
    this.phone,
    this.company,
    required this.customerType,
    this.taxId,
    this.address,
    this.shippingAddress,
    this.billingAddress,
    required this.status,
    required this.loyaltyPoints,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    this.lastOrderDate,
    required this.outstandingBalance,
    this.notes,
    required this.tags,
    this.preferences,
    required this.createdBy,
    this.updatedBy,
    required this.isActive,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.recentOrders,
  });

  // ─── STATUS HELPERS ──────────────────────────────────────────
  bool get isActiveCustomer => status == 'Active';
  bool get isInactive => status == 'Inactive';
  bool get isBlocked => status == 'Blocked';

  bool get canEdit => isActive && !isDeleted;
  bool get canDelete => totalOrders == 0 && !isDeleted;

  // ─── TYPE HELPERS ────────────────────────────────────────────
  bool get isIndividual => customerType == 'Individual';
  bool get isBusiness => customerType == 'Business';
  bool get isWholesale => customerType == 'Wholesale';
  bool get isRetail => customerType == 'Retail';

  // ─── CALCULATIONS ────────────────────────────────────────────
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String get displayName {
    if (company != null && company!.isNotEmpty) {
      return '$name ($company)';
    }
    return name;
  }

  String get contactInfo {
    if (email != null && phone != null) {
      return '$email • $phone';
    } else if (email != null) {
      return email!;
    } else if (phone != null) {
      return phone!;
    }
    return 'No contact info';
  }

  // ─── JSON ────────────────────────────────────────────────────
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    List<String> tagsList = [];
    if (json['tags'] != null && json['tags'] is List) {
      tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    List<dynamic>? recentOrdersList;
    if (json['recentOrders'] != null && json['recentOrders'] is List) {
      recentOrdersList = json['recentOrders'] as List;
    }

    return CustomerModel(
      id: json['id'] ?? '',
      customerNumber: json['customerNumber'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      customerType: json['customerType'] ?? 'Individual',
      taxId: json['taxId'],
      address: json['address'] is Map
          ? Map<String, dynamic>.from(json['address'])
          : null,
      shippingAddress: json['shippingAddress'] is Map
          ? Map<String, dynamic>.from(json['shippingAddress'])
          : null,
      billingAddress: json['billingAddress'] is Map
          ? Map<String, dynamic>.from(json['billingAddress'])
          : null,
      status: json['status'] ?? 'Active',
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      lastOrderDate: json['lastOrderDate'] != null
          ? DateTime.parse(json['lastOrderDate'])
          : null,
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      tags: tagsList,
      preferences: json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
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
      recentOrders: recentOrdersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerNumber': customerNumber,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'customerType': customerType,
      'taxId': taxId,
      'address': address,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,
      'status': status,
      'loyaltyPoints': loyaltyPoints,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'averageOrderValue': averageOrderValue,
      'lastOrderDate': lastOrderDate?.toIso8601String(),
      'outstandingBalance': outstandingBalance,
      'notes': notes,
      'tags': tags,
      'preferences': preferences,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'CustomerModel(name: $name, number: $customerNumber)';
}

// ═══════════════════════════════════════════════════════════════
// CUSTOMER REQUEST MODELS
// ═══════════════════════════════════════════════════════════════

class CreateCustomerRequest {
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String customerType;
  final String? taxId;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String status;
  final int loyaltyPoints;
  final String? notes;
  final List<String> tags;
  final Map<String, dynamic>? preferences;

  CreateCustomerRequest({
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.customerType = 'Individual',
    this.taxId,
    this.address,
    this.shippingAddress,
    this.billingAddress,
    this.status = 'Active',
    this.loyaltyPoints = 0,
    this.notes,
    this.tags = const [],
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'customerType': customerType,
      'taxId': taxId,
      'address': address ?? {},
      'shippingAddress': shippingAddress ?? {},
      'billingAddress': billingAddress ?? {},
      'status': status,
      'loyaltyPoints': loyaltyPoints,
      'notes': notes ?? '',
      'tags': tags,
      'preferences': preferences ?? {},
    };
  }
}

class UpdateCustomerRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? company;
  final String? customerType;
  final String? taxId;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String? status;
  final int? loyaltyPoints;
  final String? notes;
  final List<String>? tags;
  final Map<String, dynamic>? preferences;

  UpdateCustomerRequest({
    this.name,
    this.email,
    this.phone,
    this.company,
    this.customerType,
    this.taxId,
    this.address,
    this.shippingAddress,
    this.billingAddress,
    this.status,
    this.loyaltyPoints,
    this.notes,
    this.tags,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (company != null) map['company'] = company;
    if (customerType != null) map['customerType'] = customerType;
    if (taxId != null) map['taxId'] = taxId;
    if (address != null) map['address'] = address;
    if (shippingAddress != null) map['shippingAddress'] = shippingAddress;
    if (billingAddress != null) map['billingAddress'] = billingAddress;
    if (status != null) map['status'] = status;
    if (loyaltyPoints != null) map['loyaltyPoints'] = loyaltyPoints;
    if (notes != null) map['notes'] = notes;
    if (tags != null) map['tags'] = tags;
    if (preferences != null) map['preferences'] = preferences;
    return map;
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOMER STATS MODEL
// ═══════════════════════════════════════════════════════════════

class CustomerStats {
  final int totalCustomers;
  final int activeCount;
  final int inactiveCount;
  final int newThisMonth;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> typeDistribution;
  final List<CustomerModel> topCustomers;

  CustomerStats({
    required this.totalCustomers,
    required this.activeCount,
    required this.inactiveCount,
    required this.newThisMonth,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.typeDistribution,
    required this.topCustomers,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    List<CustomerModel> topCustomersList = [];
    if (json['topCustomers'] != null && json['topCustomers'] is List) {
      topCustomersList = (json['topCustomers'] as List)
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CustomerStats(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      inactiveCount: (json['inactiveCount'] as num?)?.toInt() ?? 0,
      newThisMonth: (json['newThisMonth'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0,
      typeDistribution: json['typeDistribution'] is Map
          ? Map<String, int>.from(json['typeDistribution'])
          : {},
      topCustomers: topCustomersList,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOMER ORDER MODEL
// ═══════════════════════════════════════════════════════════════

class CustomerOrderSummary {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final double grandTotal;
  final String orderStatus;
  final String paymentStatus;
  final List<CustomerOrderItem> items;

  CustomerOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.grandTotal,
    required this.orderStatus,
    required this.paymentStatus,
    required this.items,
  });

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) {
    List<CustomerOrderItem> itemList = [];
    if (json['items'] != null && json['items'] is List) {
      itemList = (json['items'] as List)
          .map((e) => CustomerOrderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return CustomerOrderSummary(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      orderStatus: json['orderStatus'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      items: itemList,
    );
  }
}

class CustomerOrderItem {
  final String productName;
  final int quantity;
  final double totalPrice;

  CustomerOrderItem({
    required this.productName,
    required this.quantity,
    required this.totalPrice,
  });

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    return CustomerOrderItem(
      productName: json['productName'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
