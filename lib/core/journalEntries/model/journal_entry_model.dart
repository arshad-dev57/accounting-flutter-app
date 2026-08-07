// models/journal_entry_model.dart

class JournalEntry {
  final String id;
  final String entryNumber;
  final DateTime date;
  final String description;
  final String reference;
  final List<JournalLine> lines;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String? postedBy;
  final DateTime? postedAt;
  final List<BalanceUpdate>? balanceUpdates;

  JournalEntry({
    required this.id,
    required this.entryNumber,
    required this.date,
    required this.description,
    required this.reference,
    required this.lines,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.postedBy,
    this.postedAt,
    this.balanceUpdates,
  });

  double get totalDebit => lines.fold(0, (sum, line) => sum + line.debit);
  double get totalCredit => lines.fold(0, (sum, line) => sum + line.credit);

  /// Journal entries must balance — Dr total equals Cr total
  double get entryAmount => totalDebit > 0 ? totalDebit : totalCredit;

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  // ✅ FIXED: Safe fromJson with null handling
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    // ✅ SAFE: Handle null lines
    final linesList = json['lines'] as List? ?? [];
    
    return JournalEntry(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      entryNumber: json['entryNumber']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString()) 
          : DateTime.now(),
      description: json['description']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      lines: linesList
          .map((e) => JournalLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status']?.toString() ?? 'Posted',
      createdBy: json['createdBy'] is Map
          ? '${json['createdBy']['firstName'] ?? ''} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      postedBy: json['postedBy'] is Map
          ? '${json['postedBy']['firstName'] ?? ''} ${json['postedBy']['lastName'] ?? ''}'.trim()
          : json['postedBy']?.toString(),
      postedAt: json['postedAt'] != null 
          ? DateTime.parse(json['postedAt'].toString()) 
          : null,
      balanceUpdates: json['balanceUpdates'] != null
          ? (json['balanceUpdates'] as List)
              .map((e) => BalanceUpdate.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class JournalLine {
  final String accountId;
  final String accountName;
  final String accountCode;
  final double debit;
  final double credit;
  final String? accountType;
  final double? oldBalance;
  final double? newBalance;

  JournalLine({
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.debit,
    required this.credit,
    this.accountType,
    this.oldBalance,
    this.newBalance,
  });

  // ✅ FIXED: Safe fromJson with null handling
  factory JournalLine.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    return JournalLine(
      accountId: json['accountId']?.toString() ??
          account?['id']?.toString() ??
          '',
      accountName: json['accountName']?.toString() ??
          account?['name']?.toString() ??
          '',
      accountCode: json['accountCode']?.toString() ??
          account?['code']?.toString() ??
          '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      accountType: json['accountType']?.toString() ??
          account?['type']?.toString(),
      oldBalance: (json['oldBalance'] as num?)?.toDouble(),
      newBalance: (json['newBalance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'debit': debit,
      'credit': credit,
    };
  }
}

// ✅ FIXED: BalanceUpdate with null handling
class BalanceUpdate {
  final String account;
  final String accountType;
  final double oldBalance;
  final double debit;
  final double credit;
  final double change;
  final double newBalance;

  BalanceUpdate({
    required this.account,
    required this.accountType,
    required this.oldBalance,
    required this.debit,
    required this.credit,
    required this.change,
    required this.newBalance,
  });

  factory BalanceUpdate.fromJson(Map<String, dynamic> json) {
    return BalanceUpdate(
      account: json['account']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      oldBalance: (json['oldBalance'] as num?)?.toDouble() ?? 0.0,
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      newBalance: (json['newBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}