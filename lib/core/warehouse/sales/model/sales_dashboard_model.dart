class SalesDashboardModel {
  final SalesOrdersSummary orders;
  final SalesPosSummary pos;
  final SalesInvoicesSummary invoices;
  final Map<String, dynamic> returns;
  final Map<String, dynamic> refunds;
  final Map<String, dynamic> credits;
  final SalesComparisonData comparison;
  final List<RecentActivity> recentActivity;
  final List<TopSellingProduct> topProducts;
  final List<TopCustomer> topCustomers;
  final SalesRevenueBreakdown revenueBreakdown;

  SalesDashboardModel({
    required this.orders,
    required this.pos,
    required this.invoices,
    this.returns = const {},
    this.refunds = const {},
    this.credits = const {},
    required this.comparison,
    this.recentActivity = const [],
    this.topProducts = const [],
    this.topCustomers = const [],
    required this.revenueBreakdown,
  });

  factory SalesDashboardModel.fromJson(Map<String, dynamic> json) {
    return SalesDashboardModel(
      orders: SalesOrdersSummary.fromJson(Map<String, dynamic>.from(json['orders'] ?? {})),
      pos: SalesPosSummary.fromJson(Map<String, dynamic>.from(json['pos'] ?? {})),
      invoices: SalesInvoicesSummary.fromJson(Map<String, dynamic>.from(json['invoices'] ?? {})),
      returns: Map<String, dynamic>.from(json['returns'] ?? {}),
      refunds: Map<String, dynamic>.from(json['refunds'] ?? {}),
      credits: Map<String, dynamic>.from(json['credits'] ?? {}),
      comparison: SalesComparisonData.fromJson(Map<String, dynamic>.from(json['comparison'] ?? {})),
      recentActivity: (json['recentActivity'] as List?)
              ?.map((e) => RecentActivity.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      topProducts: (json['topProducts'] as List?)
              ?.map((e) => TopSellingProduct.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      topCustomers: (json['topCustomers'] as List?)
              ?.map((e) => TopCustomer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      revenueBreakdown: SalesRevenueBreakdown.fromJson(Map<String, dynamic>.from(json['revenueBreakdown'] ?? {})),
    );
  }

  double get creditAmount {
    final v = credits['creditAmount'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  double get creditRemaining {
    final v = credits['remainingAmount'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int get creditCount {
    final v = credits['total'];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class SalesOrdersSummary {
  final int count;
  final double revenue;
  final List<OrderStatusBreakdown> byStatus;
  final List<SalesTrendPoint> trend;
  final int todayCount;
  final double todayRevenue;
  final int pendingCount;
  final String revenueGrowth;

  SalesOrdersSummary({
    required this.count,
    required this.revenue,
    required this.byStatus,
    required this.trend,
    this.todayCount = 0,
    this.todayRevenue = 0,
    this.pendingCount = 0,
    this.revenueGrowth = '+0%',
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
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      todayRevenue: _toDouble(json['todayRevenue']),
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      revenueGrowth: json['revenueGrowth']?.toString() ?? '+0%',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class SalesPosSummary {
  final int count;
  final double revenue;
  final double discountTotal;
  final double taxTotal;
  final double paidAmount;
  final int todayCount;
  final double todayRevenue;
  final List<SalesTrendPoint> trend;
  final String revenueGrowth;

  SalesPosSummary({
    this.count = 0,
    this.revenue = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.paidAmount = 0,
    this.todayCount = 0,
    this.todayRevenue = 0,
    this.trend = const [],
    this.revenueGrowth = '+0%',
  });

  factory SalesPosSummary.fromJson(Map<String, dynamic> json) {
    return SalesPosSummary(
      count: (json['count'] as num?)?.toInt() ?? 0,
      revenue: SalesOrdersSummary._toDouble(json['revenue']),
      discountTotal: SalesOrdersSummary._toDouble(json['discountTotal']),
      taxTotal: SalesOrdersSummary._toDouble(json['taxTotal']),
      paidAmount: SalesOrdersSummary._toDouble(json['paidAmount']),
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      todayRevenue: SalesOrdersSummary._toDouble(json['todayRevenue']),
      trend: (json['trend'] as List?)
              ?.map((e) => SalesTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      revenueGrowth: json['revenueGrowth']?.toString() ?? '+0%',
    );
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
  final String grandTotalGrowth;
  final String paidAmountGrowth;
  final String outstandingGrowth;

  SalesInvoicesSummary({
    required this.stats,
    required this.trend,
    this.grandTotalGrowth = '+0%',
    this.paidAmountGrowth = '+0%',
    this.outstandingGrowth = '+0%',
  });

  factory SalesInvoicesSummary.fromJson(Map<String, dynamic> json) {
    return SalesInvoicesSummary(
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      trend: (json['trend'] as List?)
              ?.map((e) => SalesTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      grandTotalGrowth: json['grandTotalGrowth']?.toString() ?? '+0%',
      paidAmountGrowth: json['paidAmountGrowth']?.toString() ?? '+0%',
      outstandingGrowth: json['outstandingGrowth']?.toString() ?? '+0%',
    );
  }

  double get grandTotal {
    final fromGrand = SalesOrdersSummary._toDouble(stats['grandTotal']);
    if (fromGrand > 0) return fromGrand;
    // sales_dashboard_controller getInvoiceStats returns `revenue`, not grandTotal
    return SalesOrdersSummary._toDouble(stats['revenue']);
  }
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
    final revenue = SalesOrdersSummary._toDouble(json['revenue']);
    final orderRevenue = SalesOrdersSummary._toDouble(json['orderRevenue']);
    return SalesTrendPoint(
      date: json['date']?.toString() ?? '',
      revenue: revenue,
      collected: SalesOrdersSummary._toDouble(json['collected']),
      orderRevenue: orderRevenue > 0 ? orderRevenue : revenue,
      count: (json['count'] as num?)?.toInt() ?? (json['sales'] as num?)?.toInt() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? (json['sales'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesComparisonData {
  final SalesPeriodComparison today;
  final SalesPeriodComparison week;
  final SalesPeriodComparison month;
  final SalesPeriodComparison year;

  SalesComparisonData({
    required this.today,
    required this.week,
    required this.month,
    required this.year,
  });

  factory SalesComparisonData.fromJson(Map<String, dynamic> json) {
    return SalesComparisonData(
      today: SalesPeriodComparison.fromJson(Map<String, dynamic>.from(json['today'] ?? {})),
      week: SalesPeriodComparison.fromJson(Map<String, dynamic>.from(json['week'] ?? {})),
      month: SalesPeriodComparison.fromJson(Map<String, dynamic>.from(json['month'] ?? {})),
      year: SalesPeriodComparison.fromJson(Map<String, dynamic>.from(json['year'] ?? {})),
    );
  }
}

class SalesPeriodComparison {
  final double currentSales;
  final double priorSales;
  final double currentReturns;
  final double priorReturns;
  final double salesChangePercent;
  final double returnsChangePercent;

  SalesPeriodComparison({
    required this.currentSales,
    required this.priorSales,
    required this.currentReturns,
    required this.priorReturns,
    required this.salesChangePercent,
    required this.returnsChangePercent,
  });

  factory SalesPeriodComparison.fromJson(Map<String, dynamic> json) {
    return SalesPeriodComparison(
      currentSales: SalesOrdersSummary._toDouble(json['currentSales']),
      priorSales: SalesOrdersSummary._toDouble(json['priorSales']),
      currentReturns: SalesOrdersSummary._toDouble(json['currentReturns']),
      priorReturns: SalesOrdersSummary._toDouble(json['priorReturns']),
      salesChangePercent: SalesOrdersSummary._toDouble(json['salesChangePercent']),
      returnsChangePercent: SalesOrdersSummary._toDouble(json['returnsChangePercent']),
    );
  }
}

class RecentActivity {
  final String id;
  final String type;
  final String description;
  final double amount;
  final DateTime date;
  final String status;
  final String timestamp;

  RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    this.timestamp = '',
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: SalesOrdersSummary._toDouble(json['amount']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class TopSellingProduct {
  final String id;
  final String name;
  final String sku;
  final int quantitySold;
  final double revenue;
  final double discountAmount;

  TopSellingProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantitySold,
    required this.revenue,
    required this.discountAmount,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantitySold: (json['quantitySold'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      revenue: SalesOrdersSummary._toDouble(json['revenue']),
      discountAmount: SalesOrdersSummary._toDouble(json['discountAmount']),
    );
  }
}

class TopCustomer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int orderCount;
  final double totalSpent;
  final double totalDiscount;

  TopCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.orderCount,
    required this.totalSpent,
    required this.totalDiscount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      totalSpent: SalesOrdersSummary._toDouble(json['totalSpent']),
      totalDiscount: SalesOrdersSummary._toDouble(json['totalDiscount']),
    );
  }
}

class SalesRevenueBreakdown {
  final double grossRevenue;
  final double lineItemDiscounts;
  final double orderLevelDiscounts;
  final double netRevenue;
  final double taxAmount;
  final double shippingAmount;
  final List<RevenueBreakdownItem> items;

  SalesRevenueBreakdown({
    required this.grossRevenue,
    required this.lineItemDiscounts,
    required this.orderLevelDiscounts,
    required this.netRevenue,
    required this.taxAmount,
    required this.shippingAmount,
    this.items = const [],
  });

  factory SalesRevenueBreakdown.fromJson(Map<String, dynamic> json) {
    return SalesRevenueBreakdown(
      grossRevenue: SalesOrdersSummary._toDouble(json['grossRevenue']),
      lineItemDiscounts: SalesOrdersSummary._toDouble(json['lineItemDiscounts']),
      orderLevelDiscounts: SalesOrdersSummary._toDouble(json['orderLevelDiscounts']),
      netRevenue: SalesOrdersSummary._toDouble(json['netRevenue']),
      taxAmount: SalesOrdersSummary._toDouble(json['taxAmount']),
      shippingAmount: SalesOrdersSummary._toDouble(json['shippingAmount']),
      items: (json['items'] as List?)
              ?.map((e) => RevenueBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

class RevenueBreakdownItem {
  final String category;
  final double amount;
  final double percentage;

  RevenueBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory RevenueBreakdownItem.fromJson(Map<String, dynamic> json) {
    return RevenueBreakdownItem(
      category: json['category']?.toString() ?? '',
      amount: SalesOrdersSummary._toDouble(json['amount']),
      percentage: SalesOrdersSummary._toDouble(json['percentage']),
    );
  }
}
