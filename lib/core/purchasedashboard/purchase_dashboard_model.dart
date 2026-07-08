// lib/core/warehouse/purchase/model/purchase_dashboard_model.dart

class PurchaseDashboardModel {
  final PurchaseOrderSummary orders;

  PurchaseDashboardModel({
    required this.orders,
  });

  factory PurchaseDashboardModel.fromJson(Map<String, dynamic> json) {
    return PurchaseDashboardModel(
      orders: PurchaseOrderSummary.fromJson(json['orders'] ?? {}),
    );
  }
}

class PurchaseOrderSummary {
  final int count;
  final double totalValue;
  final int approvedCount;
  final double approvedValue;
  final int draftCount;
  final int sentCount;
  final int cancelledCount;
  final List<PurchaseTrendPoint> trend;

  PurchaseOrderSummary({
    required this.count,
    required this.totalValue,
    required this.approvedCount,
    required this.approvedValue,
    required this.draftCount,
    required this.sentCount,
    required this.cancelledCount,
    required this.trend,
  });

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) {
    final trendList = (json['trend'] as List? ?? [])
        .map((e) => PurchaseTrendPoint.fromJson(e))
        .toList();

    return PurchaseOrderSummary(
      count: json['count'] ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      approvedCount: json['approvedCount'] ?? 0,
      approvedValue: (json['approvedValue'] as num?)?.toDouble() ?? 0,
      draftCount: json['draftCount'] ?? 0,
      sentCount: json['sentCount'] ?? 0,
      cancelledCount: json['cancelledCount'] ?? 0,
      trend: trendList,
    );
  }
}

class PurchaseTrendPoint {
  final String date;
  final double value;

  PurchaseTrendPoint({
    required this.date,
    required this.value,
  });

  factory PurchaseTrendPoint.fromJson(Map<String, dynamic> json) {
    return PurchaseTrendPoint(
      date: json['date'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}