import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';

class BillingInvoice {
  final String id;
  final String invoiceNumber;
  final String plan;
  final String status;
  final double amount;
  final String currency;
  final String? productTier;
  final String? type;
  final DateTime? createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paidByName;

  BillingInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.plan,
    required this.status,
    required this.amount,
    this.currency = 'USD',
    this.productTier,
    this.type,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.paidByName,
  });

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    return BillingInvoice(
      id: '${json['id'] ?? ''}',
      invoiceNumber: '${json['invoiceNumber'] ?? '—'}',
      plan: '${json['plan'] ?? '—'}',
      status: '${json['status'] ?? '—'}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: '${json['currency'] ?? 'USD'}',
      productTier: json['productTier']?.toString(),
      type: json['type']?.toString(),
      createdAt: _date(json['createdAt']),
      startDate: _date(json['startDate']),
      endDate: _date(json['endDate']),
      paidByName: (json['paidBy'] as Map?)?['name']?.toString(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String get tierLabel {
    if (productTier == tierPos) return 'POS';
    if (productTier == tierErpPos) return 'ERP + POS';
    return productTier ?? '—';
  }

  String get typeLabel {
    if (type == 'upgrade') return 'Upgrade';
    if (type == 'trial') return 'Trial';
    return 'Subscription';
  }
}

class BillingStats {
  final double currentAmount;
  final double totalPaid;
  final double paidThisMonth;
  final int invoiceCount;

  const BillingStats({
    this.currentAmount = 0,
    this.totalPaid = 0,
    this.paidThisMonth = 0,
    this.invoiceCount = 0,
  });

  factory BillingStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BillingStats();
    return BillingStats(
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      paidThisMonth: (json['paidThisMonth'] as num?)?.toDouble() ?? 0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlyBillingStat {
  final String month;
  final String label;
  final double total;
  final int count;

  MonthlyBillingStat({
    required this.month,
    required this.label,
    required this.total,
    required this.count,
  });

  factory MonthlyBillingStat.fromJson(Map<String, dynamic> json) {
    return MonthlyBillingStat(
      month: '${json['month'] ?? ''}',
      label: '${json['label'] ?? json['month'] ?? ''}',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CompanyBilling {
  final String companyName;
  final SubscriptionCapacity capacity;
  final BillingStats stats;
  final List<MonthlyBillingStat> monthlyStats;
  final List<BillingInvoice> invoices;
  final int subscriptionDaysRemaining;
  final int trialDaysRemaining;
  final DateTime? subscriptionEndDate;
  final DateTime? trialEndDate;

  CompanyBilling({
    required this.companyName,
    required this.capacity,
    required this.stats,
    required this.monthlyStats,
    required this.invoices,
    this.subscriptionDaysRemaining = 0,
    this.trialDaysRemaining = 0,
    this.subscriptionEndDate,
    this.trialEndDate,
  });

  factory CompanyBilling.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    return CompanyBilling(
      companyName: (json['company'] as Map?)?['name']?.toString() ?? 'Company',
      capacity: SubscriptionCapacity.fromJson(
        json['capacity'] as Map<String, dynamic>? ?? {},
      ),
      stats: BillingStats.fromJson(json['stats'] as Map<String, dynamic>?),
      monthlyStats: ((json['monthlyStats'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => MonthlyBillingStat.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      invoices: ((json['invoices'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => BillingInvoice.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subscriptionDaysRemaining: (sub['subscriptionDaysRemaining'] as num?)?.toInt() ?? 0,
      trialDaysRemaining: (sub['trialDaysRemaining'] as num?)?.toInt() ?? 0,
      subscriptionEndDate: BillingInvoice._date(sub['endDate']),
      trialEndDate: BillingInvoice._date(sub['trialEndDate']),
    );
  }
}
