class Loan {
  final String id;
  final String loanNumber;
  final String loanType;
  final String lenderName;
  final double loanAmount;
  final DateTime disbursementDate;
  final double interestRate;
  final int tenureMonths;
  final double emiAmount;
  final double totalPaid;
  final double outstandingBalance;
  final DateTime? nextPaymentDate;
  final DateTime? lastPaymentDate;
  final String status;
  final String purpose;
  final String collateral;
  final String accountNumber;
  final String notes;
  final List<EMIPayment> payments;

  Loan({
    required this.id,
    required this.loanNumber,
    required this.loanType,
    required this.lenderName,
    required this.loanAmount,
    required this.disbursementDate,
    required this.interestRate,
    required this.tenureMonths,
    required this.emiAmount,
    required this.totalPaid,
    required this.outstandingBalance,
    this.nextPaymentDate,
    this.lastPaymentDate,
    required this.status,
    required this.purpose,
    required this.collateral,
    required this.accountNumber,
    required this.notes,
    required this.payments,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['_id'] ?? '',
      loanNumber: json['loanNumber'] ?? '',
      loanType: json['loanType'] ?? '',
      lenderName: json['lenderName'] ?? '',
      loanAmount: (json['loanAmount'] ?? 0).toDouble(),
      disbursementDate: json['disbursementDate'] != null ? DateTime.parse(json['disbursementDate']) : DateTime.now(),
      interestRate: (json['interestRate'] ?? 0).toDouble(),
      tenureMonths: json['tenureMonths'] ?? 0,
      emiAmount: (json['emiAmount'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      outstandingBalance: (json['outstandingBalance'] ?? 0).toDouble(),
      nextPaymentDate: json['nextPaymentDate'] != null ? DateTime.parse(json['nextPaymentDate']) : null,
      lastPaymentDate: json['lastPaymentDate'] != null ? DateTime.parse(json['lastPaymentDate']) : null,
      status: json['status'] ?? 'Active',
      purpose: json['purpose'] ?? '',
      collateral: json['collateral'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      notes: json['notes'] ?? '',
      payments: (json['payments'] as List? ?? []).map((p) => EMIPayment.fromJson(p)).toList(),
    );
  }
}

class EMIPayment {
  final DateTime date;
  final double amount;
  final String status;
  final String type;
  final String reference;
  final String notes;

  EMIPayment({
    required this.date,
    required this.amount,
    required this.status,
    this.type = 'EMI',
    this.reference = '',
    this.notes = '',
  });

  factory EMIPayment.fromJson(Map<String, dynamic> json) {
    return EMIPayment(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Paid',
      type: json['type'] ?? 'EMI',
      reference: json['reference'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}