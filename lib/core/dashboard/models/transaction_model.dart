// lib/models/transaction_model.dart

class Transaction {
  final String id;
  final String transactionNumber;
  final String type;      // income, expense, receivable, payable, adjustment, financing, investment
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String reference;
  final String? customerName;
  final String? vendorName;
  final String? source;    // income, expense, invoice, bill, payment_received, etc.
  final String? icon;
  final String? color;
  final String? dueDate;
  final double? outstanding;
  final double? appliedAmount;
  final double? remainingAmount;

  Transaction({
    required this.id,
    required this.transactionNumber,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.reference,
    this.customerName,
    this.vendorName,
    this.source,
    this.icon,
    this.color,
    this.dueDate,
    this.outstanding,
    this.appliedAmount,
    this.remainingAmount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: _safeString(json['id'] ?? json['_id']),
      transactionNumber: _safeString(json['transactionNumber']),
      type: _safeString(json['type']),
      title: _safeString(json['title']),
      description: _safeString(json['description']),
      amount: _safeDouble(json['amount']),
      date: _safeDateTime(json['date']),
      category: _safeString(json['category']),
      paymentMethod: _safeString(json['paymentMethod']),
      reference: _safeString(json['reference']),
      customerName: json['customerName'] != null ? _safeString(json['customerName']) : null,
      vendorName: json['vendorName'] != null ? _safeString(json['vendorName']) : null,
      source: json['source'] != null ? _safeString(json['source']) : null,
      icon: json['icon'] != null ? _safeString(json['icon']) : null,
      color: json['color'] != null ? _safeString(json['color']) : null,
      dueDate: json['dueDate'] != null ? _safeString(json['dueDate']) : null,
      outstanding: _safeNullableDouble(json['outstanding']),
      appliedAmount: _safeNullableDouble(json['appliedAmount']),
      remainingAmount: _safeNullableDouble(json['remainingAmount']),
    );
  }

  // Helper methods for safe conversion
  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _safeNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}