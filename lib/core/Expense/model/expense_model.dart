// core/Expense/model/expense_model.dart - UPDATED

class Expense {
  final String id;
  final String expenseNumber;
  final DateTime date;
  final String expenseType;
  final String? vendorId;
  final String vendorName;
  final List<Map<String, dynamic>> items;
  final double amount;
  final bool hasItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String description;
  final String reference;
  final String paymentMethod;
  final String? bankAccountId;
  final Map<String, dynamic>? bankAccount;
  final String status;
  final String createdBy;
  final String? postedBy;
  final DateTime? postedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ NEW: Expense Account field
  final Map<String, dynamic>? expenseAccount;
  final String? expenseAccountId;

  Expense({
    required this.id,
    required this.expenseNumber,
    required this.date,
    required this.expenseType,
    this.vendorId,
    this.vendorName = '',
    this.items = const [],
    this.amount = 0,
    this.hasItems = false,
    this.subtotal = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.description = '',
    this.reference = '',
    this.paymentMethod = 'Cash',
    this.bankAccountId,
    this.bankAccount,
    this.status = 'Draft',
    this.createdBy = '',
    this.postedBy,
    this.postedAt,
    required this.createdAt,
    required this.updatedAt,
    this.expenseAccount,      
    this.expenseAccountId,    // ✅ NEW
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      expenseNumber: json['expenseNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      expenseType: json['expenseType'] ?? '',
      vendorId: json['vendorId'],
      vendorName: json['vendorName'] ?? '',
      items: json['items'] != null ? List<Map<String, dynamic>>.from(json['items']) : [],
      amount: (json['amount'] ?? 0).toDouble(),
      hasItems: json['hasItems'] ?? false,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['taxRate'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      bankAccountId: json['bankAccountId'],
      bankAccount: json['bankAccount'] != null ? Map<String, dynamic>.from(json['bankAccount']) : null,
      status: json['status'] ?? 'Draft',
      createdBy: json['createdBy'] ?? '',
      postedBy: json['postedBy'],
      postedAt: json['postedAt'] != null ? DateTime.parse(json['postedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      expenseAccount: json['expenseAccount'] != null ? Map<String, dynamic>.from(json['expenseAccount']) : null,  // ✅ NEW
      expenseAccountId: json['expenseAccountId'],  // ✅ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseNumber': expenseNumber,
      'date': date.toIso8601String(),
      'expenseType': expenseType,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items,
      'amount': amount,
      'hasItems': hasItems,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'description': description,
      'reference': reference,
      'paymentMethod': paymentMethod,
      'bankAccountId': bankAccountId,
      'bankAccount': bankAccount,
      'status': status,
      'createdBy': createdBy,
      'postedBy': postedBy,
      'postedAt': postedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expenseAccount': expenseAccount,  // ✅ NEW
      'expenseAccountId': expenseAccountId,  // ✅ NEW
    };
  }

  Expense copyWith({
    String? id,
    String? expenseNumber,
    DateTime? date,
    String? expenseType,
    String? vendorId,
    String? vendorName,
    List<Map<String, dynamic>>? items,
    double? amount,
    bool? hasItems,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    String? description,
    String? reference,
    String? paymentMethod,
    String? bankAccountId,
    Map<String, dynamic>? bankAccount,
    String? status,
    String? createdBy,
    String? postedBy,
    DateTime? postedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? expenseAccount,  // ✅ NEW
    String? expenseAccountId,  // ✅ NEW
  }) {
    return Expense(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      date: date ?? this.date,
      expenseType: expenseType ?? this.expenseType,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      amount: amount ?? this.amount,
      hasItems: hasItems ?? this.hasItems,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccount: bankAccount ?? this.bankAccount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      postedBy: postedBy ?? this.postedBy,
      postedAt: postedAt ?? this.postedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseAccount: expenseAccount ?? this.expenseAccount,  // ✅ NEW
      expenseAccountId: expenseAccountId ?? this.expenseAccountId,  // ✅ NEW
    );
  }
}