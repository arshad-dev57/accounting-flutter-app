// equity_model.dart mein fromChartOfAccountsJson method add karo:

class EquityAccount {
  final String id;
  final String accountName;
  final String accountCode;
  final String accountType;
  final double openingBalance;
  final double currentBalance;
  final double additions;
  final double withdrawals;
  final DateTime lastUpdated;
  final String notes;

  EquityAccount({
    required this.id,
    required this.accountName,
    required this.accountCode,
    required this.accountType,
    required this.openingBalance,
    required this.currentBalance,
    required this.additions,
    required this.withdrawals,
    required this.lastUpdated,
    required this.notes,
  });

  // Chart of Accounts se data convert karne ke liye
  factory EquityAccount.fromChartOfAccountsJson(Map<String, dynamic> json) {
    return EquityAccount(
      id: json['_id'] ?? '',
      accountName: json['name'] ?? '',
      accountCode: json['code'] ?? '',
      accountType: _mapAccountType(json['type'] ?? 'Equity'),
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? json['openingBalance'] ?? 0).toDouble(),
      additions: 0,  // Chart of Accounts se nahi aata, separate transactions se calculate karna hoga
      withdrawals: 0, // Chart of Accounts se nahi aata
      lastUpdated: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      notes: json['description'] ?? '',
    );
  }
  
  static String _mapAccountType(String type) {
    // Equity ke andar subtypes
    if (type == 'Equity') {
      return 'Capital'; // Default
    }
    return type;
  }
}

class OwnerTransaction {
  final String id;
  final DateTime date;
  final String type;
  final String accountName;
  final double amount;
  final String description;
  final String reference;
  final String status;

  OwnerTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.reference,
    required this.status,
  });

  factory OwnerTransaction.fromJson(Map<String, dynamic> json) {
    return OwnerTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? '',
      accountName: json['accountName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? 'Posted',
    );
  }
}