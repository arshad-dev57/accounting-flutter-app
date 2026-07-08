class RefundModel {
  final String id;
  final String refundNumber;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final double amount;
  final String refundStatus;
  final String refundMethod;
  final String reason;
  final String? notes;
  final String? referenceNumber;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final DateTime refundDate;
  final DateTime? processedAt;
  final DateTime? completedAt;

  RefundModel({
    required this.id,
    required this.refundNumber,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.amount,
    required this.refundStatus,
    required this.refundMethod,
    required this.reason,
    this.notes,
    this.referenceNumber,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    required this.refundDate,
    this.processedAt,
    this.completedAt,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      refundNumber: json['refundNumber']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      amount: _toDouble(json['amount']),
      refundStatus: json['refundStatus']?.toString() ?? 'Pending',
      refundMethod: json['refundMethod']?.toString() ?? 'Original Payment',
      reason: json['reason']?.toString() ?? '',
      notes: json['notes']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      refundDate: _parseDate(json['refundDate'] ?? json['createdAt']),
      processedAt: json['processedAt'] != null ? _parseDate(json['processedAt']) : null,
      completedAt: json['completedAt'] != null ? _parseDate(json['completedAt']) : null,
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

class RefundStats {
  final int total;
  final double totalAmount;
  final int pending;
  final int processing;
  final int completed;
  final int failed;

  RefundStats({
    required this.total,
    required this.totalAmount,
    required this.pending,
    required this.processing,
    required this.completed,
    required this.failed,
  });

  factory RefundStats.fromJson(Map<String, dynamic> json) {
    return RefundStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalAmount: RefundModel._toDouble(json['totalAmount']),
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      processing: (json['processing'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}
