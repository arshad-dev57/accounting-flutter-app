// lib/core/purchasedashboard/purchase_dashboard_model.dart

class PurchaseDashboardModel {
  final PurchaseOrderSummary orders;
  final PurchaseInvoiceSummary invoices;
  final PurchaseReturnSummary returns;
  final PurchasePaymentSummary payments;
  final List<PurchaseSpendPoint> spendTrend;
  final List<PurchaseOrderStatus> orderStatuses;
  final List<PurchaseSupplier> topSuppliers;
  final List<PurchaseActivity> activities;

  PurchaseDashboardModel({
    required this.orders,
    required this.invoices,
    required this.returns,
    required this.payments,
    this.spendTrend   = const [],
    this.orderStatuses = const [],
    this.topSuppliers  = const [],
    this.activities    = const [],
  });

  factory PurchaseDashboardModel.fromMetrics(Map<String, dynamic> json) {
    final o = Map<String, dynamic>.from(json['orders']   ?? {});
    final i = Map<String, dynamic>.from(json['invoices'] ?? {});
    final r = Map<String, dynamic>.from(json['returns']  ?? {});
    final p = Map<String, dynamic>.from(json['payments'] ?? {});

    return PurchaseDashboardModel(
      orders: PurchaseOrderSummary(
        total:         (o['total']         as num?)?.toInt()    ?? 0,
        approved:      (o['approved']      as num?)?.toInt()    ?? 0,
        approvedValue: (o['approvedValue'] as num?)?.toDouble() ?? 0,
        draft:         (o['draft']         as num?)?.toInt()    ?? 0,
        sent:          (o['sent']          as num?)?.toInt()    ?? 0,
        received:      (o['received']      as num?)?.toInt()    ?? 0,
        cancelled:     (o['cancelled']     as num?)?.toInt()    ?? 0,
      ),
      invoices: PurchaseInvoiceSummary(
        total:      (i['total']      as num?)?.toInt()    ?? 0,
        paid:       (i['paid']       as num?)?.toInt()    ?? 0,
        paidAmount: (i['paidAmount'] as num?)?.toDouble() ?? 0,
        outstanding:(i['outstanding'] as num?)?.toDouble() ?? 0,
        totalSpend: (i['totalSpend'] as num?)?.toDouble() ?? 0,
      ),
      returns:  PurchaseReturnSummary(total: (r['total'] as num?)?.toInt() ?? 0),
      payments: PurchasePaymentSummary(totalPaid: (p['totalPaid'] as num?)?.toDouble() ?? 0),
    );
  }
}

// ─── Order Summary ─────────────────────────────────────────────────────────

class PurchaseOrderSummary {
  final int total;
  final int approved;
  final double approvedValue;
  final int draft;
  final int sent;
  final int received;
  final int cancelled;

  const PurchaseOrderSummary({
    required this.total,
    required this.approved,
    required this.approvedValue,
    required this.draft,
    required this.sent,
    required this.received,
    required this.cancelled,
  });
}

// ─── Invoice Summary ───────────────────────────────────────────────────────

class PurchaseInvoiceSummary {
  final int total;
  final int paid;
  final double paidAmount;
  final double outstanding;
  final double totalSpend;

  const PurchaseInvoiceSummary({
    required this.total,
    required this.paid,
    required this.paidAmount,
    required this.outstanding,
    required this.totalSpend,
  });
}

// ─── Return & Payment Summaries ────────────────────────────────────────────

class PurchaseReturnSummary {
  final int total;
  const PurchaseReturnSummary({required this.total});
}

class PurchasePaymentSummary {
  final double totalPaid;
  const PurchasePaymentSummary({required this.totalPaid});
}

// ─── Spend Trend ───────────────────────────────────────────────────────────

class PurchaseSpendPoint {
  final String date;
  final String label;
  final double invoiceAmount;
  final double paidAmount;
  final double orderValue;

  const PurchaseSpendPoint({
    required this.date,
    required this.label,
    this.invoiceAmount = 0,
    this.paidAmount    = 0,
    this.orderValue    = 0,
  });

  factory PurchaseSpendPoint.fromJson(Map<String, dynamic> j) {
    return PurchaseSpendPoint(
      date:          j['date']          as String? ?? '',
      label:         j['label']         as String? ?? '',
      invoiceAmount: (j['invoiceAmount'] as num?)?.toDouble() ?? 0,
      paidAmount:    (j['paidAmount']   as num?)?.toDouble() ?? 0,
      orderValue:    (j['orderValue']   as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Order Status ──────────────────────────────────────────────────────────

class PurchaseOrderStatus {
  final String status;
  final int count;
  final double value;
  final String color;

  const PurchaseOrderStatus({
    required this.status,
    required this.count,
    required this.value,
    required this.color,
  });

  factory PurchaseOrderStatus.fromJson(Map<String, dynamic> j) {
    return PurchaseOrderStatus(
      status: j['status'] as String? ?? '',
      count:  (j['count'] as num?)?.toInt()    ?? 0,
      value:  (j['value'] as num?)?.toDouble() ?? 0,
      color:  j['color']  as String? ?? '#4361EE',
    );
  }
}

// ─── Top Supplier ──────────────────────────────────────────────────────────

class PurchaseSupplier {
  final String supplierName;
  final int totalOrders;
  final double totalValue;
  final String color;

  const PurchaseSupplier({
    required this.supplierName,
    required this.totalOrders,
    required this.totalValue,
    required this.color,
  });

  factory PurchaseSupplier.fromJson(Map<String, dynamic> j) {
    return PurchaseSupplier(
      supplierName: j['supplierName'] as String? ?? 'Unknown',
      totalOrders:  (j['totalOrders'] as num?)?.toInt()    ?? 0,
      totalValue:   (j['totalValue']  as num?)?.toDouble() ?? 0,
      color:        j['color']        as String? ?? '#4361EE',
    );
  }
}

// ─── Activity ──────────────────────────────────────────────────────────────

class PurchaseActivity {
  final String id;
  final String type;
  final String action;
  final String details;
  final double amount;
  final String createdAt;

  const PurchaseActivity({
    required this.id,
    required this.type,
    required this.action,
    required this.details,
    required this.amount,
    required this.createdAt,
  });

  factory PurchaseActivity.fromJson(Map<String, dynamic> j) {
    return PurchaseActivity(
      id:        j['id']        as String? ?? '',
      type:      j['type']      as String? ?? '',
      action:    j['action']    as String? ?? '',
      details:   j['details']   as String? ?? '',
      amount:    (j['amount']   as num?)?.toDouble() ?? 0,
      createdAt: j['createdAt'] as String? ?? '',
    );
  }
}