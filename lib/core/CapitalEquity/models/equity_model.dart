// equity_model.dart mein fromChartOfAccountsJson method add karo:

// Helper function to derive accountType from account name
String _deriveAccountType(String name) {
  final n = name.toLowerCase();
  if (n.contains('drawing')) return 'Drawings';
  if (n.contains('retained') ||
      n.contains('retention') ||
      n.contains('current year'))
    return 'Retained Earnings';
  if (n.contains('reserve')) return 'Reserves';
  if (n.contains('share')) return 'Share Capital';
  return 'Capital';
}

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
    final String name = json['name'] ?? '';
    final String accountType =
        json['subType'] ?? json['accountType'] ?? _deriveAccountType(name);

    return EquityAccount(
      id: json['id'] ?? json['_id'] ?? '',
      accountName: name,
      accountCode: json['code'] ?? json['accountCode'] ?? '',
      accountType: accountType,
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? json['openingBalance'] ?? 0)
          .toDouble(),
      additions:
          0, // Chart of Accounts se nahi aata, separate transactions se calculate karna hoga
      withdrawals: 0, // Chart of Accounts se nahi aata
      lastUpdated: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['description'] ?? json['notes'] ?? '',
    );
  }

  // Equity API endpoint se data convert karne ke liye
  factory EquityAccount.fromJson(Map<String, dynamic> json) {
    return EquityAccount(
      id: json['id'] ?? '',
      accountName: json['accountName'] ?? '',
      accountCode: json['accountCode'] ?? '',
      accountType: json['accountType'] ?? 'Capital',
      openingBalance: (json['openingBalance'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      additions: (json['additions'] ?? 0).toDouble(),
      withdrawals: (json['withdrawals'] ?? 0).toDouble(),
      lastUpdated: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
    );
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

  OwnerTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.reference,
  });

  factory OwnerTransaction.fromJson(Map<String, dynamic> json) {
    return OwnerTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      accountName: json['accountName'] ?? '',
      type: json['type'] ?? 'Additional Capital',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
    );
  }
}
