class SalesDashboardModel {
  final SalesOrdersSummary orders;
  final SalesInvoicesSummary invoices;
  final Map<String, dynamic> returns;
  final Map<String, dynamic> refunds;

  SalesDashboardModel({
    required this.orders,
    required this.invoices,
    this.returns = const {},
    this.refunds = const {},
  });

  factory SalesDashboardModel.fromJson(Map<String, dynamic> json) {
    return SalesDashboardModel(
      orders: SalesOrdersSummary.fromJson(Map<String, dynamic>.from(json['orders'] ?? {})),
      invoices: SalesInvoicesSummary.fromJson(Map<String, dynamic>.from(json['invoices'] ?? {})),
      returns: Map<String, dynamic>.from(json['returns'] ?? {}),
      refunds: Map<String, dynamic>.from(json['refunds'] ?? {}),
    );
  }
}

class SalesOrdersSummary {
  final int count;
  final double revenue;
  final List<OrderStatusBreakdown> byStatus;
  final List<SalesTrendPoint> trend;

  SalesOrdersSummary({
    required this.count,
    required this.revenue,
    required this.byStatus,
    required this.trend,
  });

  factory SalesOrdersSummary.fromJson(Map<String, dynamic> json) {
    return SalesOrdersSummary(
      count: (json['count'] as num?)?.toInt() ?? 0,
      revenue: _toDouble(json['revenue']),
      byStatus: (json['byStatus'] as List?)
              ?.map((e) => OrderStatusBreakdown.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      trend: (json['trend'] as List?)
              ?.map((e) => SalesTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class OrderStatusBreakdown {
  final String status;
  final int count;
  final double revenue;

  OrderStatusBreakdown({required this.status, required this.count, required this.revenue});

  factory OrderStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return OrderStatusBreakdown(
      status: json['status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      revenue: SalesOrdersSummary._toDouble(json['revenue']),
    );
  }
}

class SalesInvoicesSummary {
  final Map<String, dynamic> stats;
  final List<SalesTrendPoint> trend;

  SalesInvoicesSummary({required this.stats, required this.trend});

  factory SalesInvoicesSummary.fromJson(Map<String, dynamic> json) {
    return SalesInvoicesSummary(
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      trend: (json['trend'] as List?)
              ?.map((e) => SalesTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  double get grandTotal => SalesOrdersSummary._toDouble(stats['grandTotal']);
  double get paidAmount => SalesOrdersSummary._toDouble(stats['paidAmount']);
  double get outstanding => SalesOrdersSummary._toDouble(stats['outstanding']);
  int get total => (stats['total'] as num?)?.toInt() ?? 0;
}

class SalesTrendPoint {
  final String date;
  final double revenue;
  final double collected;
  final double orderRevenue;
  final int count;
  final int orders;

  SalesTrendPoint({
    required this.date,
    this.revenue = 0,
    this.collected = 0,
    this.orderRevenue = 0,
    this.count = 0,
    this.orders = 0,
  });

  factory SalesTrendPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendPoint(
      date: json['date']?.toString() ?? '',
      revenue: SalesOrdersSummary._toDouble(json['revenue']),
      collected: SalesOrdersSummary._toDouble(json['collected']),
      orderRevenue: SalesOrdersSummary._toDouble(json['orderRevenue']),
      count: (json['count'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }
}
