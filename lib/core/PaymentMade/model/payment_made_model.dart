class PaymentMade {
  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final String vendorId;
  final String vendorName;
  final String billId;
  final String billNumber;
  final double billAmount;
  final double amount;
  final String paymentMethod;
  final String reference;
  final String bankAccountId;
  final String bankAccountName;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMade({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.vendorId,
    required this.vendorName,
    required this.billId,
    required this.billNumber,
    required this.billAmount,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.bankAccountId,
    required this.bankAccountName,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMade.fromJson(Map<String, dynamic> json) {
    return PaymentMade(
      id: json['_id'],
      paymentNumber: json['paymentNumber'],
      paymentDate: DateTime.parse(json['paymentDate']),
      vendorId: json['vendorId']['_id'] ?? json['vendorId'],
      vendorName: json['vendorName'],
      billId: json['billId']['_id'] ?? json['billId'],
      billNumber: json['billNumber'],
      billAmount: json['billAmount'].toDouble(),
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      reference: json['reference'] ?? '',
      bankAccountId: json['bankAccountId'] ?? '',
      bankAccountName: json['bankAccountName'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class VendorForPayment {
  final String id;
  final String name;
  final String email;
  final String phone;

  VendorForPayment({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory VendorForPayment.fromJson(Map<String, dynamic> json) {
    return VendorForPayment(
      id: json['_id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class BillForPayment {
  final String id;
  final String billNumber;
  final double totalAmount;
  final double paidAmount;
  final double outstanding;
  final DateTime dueDate;
  final String status;

  BillForPayment({
    required this.id,
    required this.billNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstanding,
    required this.dueDate,
    required this.status,
  });

  factory BillForPayment.fromJson(Map<String, dynamic> json) {
    return BillForPayment(
      id: json['id'],
      billNumber: json['billNumber'],
      totalAmount: json['totalAmount'].toDouble(),
      paidAmount: json['paidAmount'].toDouble(),
      outstanding: json['outstanding'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
    );
  }
}