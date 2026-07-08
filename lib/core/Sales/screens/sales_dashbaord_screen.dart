// lib/core/warehouse/sales/screen/sales_dashboard_screen.dart - COMPLETE

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/login/screen/login_screen.dart';
import 'package:LedgerPro_app/core/warehouse/order/screen/Sales_order_screen.dart';
import 'package:LedgerPro_app/core/warehouse/refunds/screen/sales_refund_screen.dart';
import 'package:LedgerPro_app/core/warehouse/returns/screen/sales_return_screen.dart';
import 'package:LedgerPro_app/core/warehouse/sales/controller/sales_controller.dart';
import 'package:LedgerPro_app/core/warehouse/sales/model/sales_dashboard_model.dart';
import 'package:LedgerPro_app/widgets/sales_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesController());
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: kBg,
      drawer: isMobile ? const SalesDrawer(currentRoute: '/warehouse/sales') : null,
      appBar: AppBar(
        title: const Text(
          'Sales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: controller.fetchDashboard,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 36,
            ),
          );
        }

        final data = controller.dashboard.value;
        return RefreshIndicator(
          onRefresh: controller.fetchDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGreetingHeader(controller),
                const SizedBox(height: 16),
                _periodChips(controller),
                const SizedBox(height: 16),
                if (data != null) ...[
                  _kpiGrid(context, data, isTablet),
                  const SizedBox(height: 16),
                  _revenueChart(context, data),
                  const SizedBox(height: 16),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _orderStatusChart(data)),
                        const SizedBox(width: 16),
                        Expanded(child: _quickLinks(context)),
                      ],
                    )
                  else ...[
                    _orderStatusChart(data),
                    const SizedBox(height: 16),
                    _quickLinks(context),
                  ],
                  const SizedBox(height: 16),
                  _flowCard(context),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Greeting Header ──────────────────────────────────────────

  Widget _buildGreetingHeader(SalesController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, kPrimary.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => controller.fetchDashboard(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Period Chips ─────────────────────────────────────────────

  Widget _periodChips(SalesController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() => Row(
            children: SalesController.periods.map((p) {
              final selected = controller.period.value == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    p[0].toUpperCase() + p.substring(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: selected,
                  onSelected: (_) => controller.setPeriod(p),
                  selectedColor: kPrimary.withOpacity(0.25),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? kPrimary : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }

  // ─── KPI Grid ──────────────────────────────────────────────────

  Widget _kpiGrid(BuildContext context, SalesDashboardModel data, bool isTablet) {
    final fmt = Get.find<CurrencyController>().formatAmount;
    final cards = [
      _kpi('Order Revenue', fmt(data.orders.revenue), Icons.shopping_cart_outlined, Colors.indigo),
      _kpi('Invoice Total', fmt(data.invoices.grandTotal), Icons.receipt_long, Colors.teal),
      _kpi('Collected', fmt(data.invoices.paidAmount), Icons.payments_outlined, Colors.green),
      _kpi('Outstanding', fmt(data.invoices.outstanding), Icons.schedule, Colors.orange),
      _kpi('Orders', '${data.orders.count}', Icons.list_alt, Colors.blue),
      _kpi('Invoices', '${data.invoices.total}', Icons.description_outlined, Colors.purple),
    ];

    return GridView.count(
      crossAxisCount: isTablet ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isTablet ? 2.2 : 1.6,
      children: cards,
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: kSubText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ─── Revenue Chart ─────────────────────────────────────────────

  Widget _revenueChart(BuildContext context, SalesDashboardModel data) {
    final invoiceTrend = data.invoices.trend;
    final orderTrend = data.orders.trend;
    if (invoiceTrend.isEmpty && orderTrend.isEmpty) {
      return _chartCard(
        'Revenue Trend',
        const Center(child: Text('No data for this period', style: TextStyle(color: Colors.grey))),
      );
    }

    final allDates = <String>{};
    for (final p in invoiceTrend) {
      allDates.add(p.date);
    }
    for (final p in orderTrend) {
      allDates.add(p.date);
    }
    final sorted = allDates.toList()..sort();

    final invoiceSpots = <FlSpot>[];
    final orderSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      final inv = invoiceTrend.firstWhere((p) => p.date == d, orElse: () => SalesTrendPoint(date: d));
      final ord = orderTrend.firstWhere((p) => p.date == d, orElse: () => SalesTrendPoint(date: d));
      invoiceSpots.add(FlSpot(i.toDouble(), inv.revenue));
      orderSpots.add(FlSpot(i.toDouble(), ord.orderRevenue));
    }

    final maxY = [
      ...invoiceSpots.map((s) => s.y),
      ...orderSpots.map((s) => s.y),
    ].fold<double>(0, (a, b) => b > a ? b : a);

    return _chartCard(
      'Revenue Trend',
      SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY <= 0 ? 100 : maxY * 1.15,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, _) => Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: sorted.length > 6 ? (sorted.length / 4).ceilToDouble() : 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                    final parts = sorted[i].split('-');
                    return Text(
                      '${parts[2]}/${parts[1]}',
                      style: const TextStyle(fontSize: 9),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: invoiceSpots,
                isCurved: true,
                color: Colors.teal,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: orderSpots,
                isCurved: true,
                color: Colors.indigo,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
      legend: ['Invoices (teal)', 'Orders (indigo)'],
    );
  }

  // ─── Order Status Chart ────────────────────────────────────────

  Widget _orderStatusChart(SalesDashboardModel data) {
    final items = data.orders.byStatus.where((s) => s.count > 0).toList();
    if (items.isEmpty) {
      return _chartCard(
        'Orders by Status',
        const Center(child: Text('No orders', style: TextStyle(color: Colors.grey))),
      );
    }

    final colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green, Colors.red];
    return _chartCard(
      'Orders by Status',
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: items.map((e) => e.count.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2 + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= items.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        items[i].status.length > 8 ? items[i].status.substring(0, 7) : items[i].status,
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.grey.shade800,
                tooltipBorder: BorderSide(color: Colors.grey.shade300),
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${items[group.x].status}\n${rod.toY.toInt()} orders',
                  TextStyle(
                    color: colors[group.x % colors.length],
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            barGroups: List.generate(items.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].count.toDouble(),
                    color: colors[i % colors.length],
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── Quick Links ──────────────────────────────────────────────

  Widget _quickLinks(BuildContext context) {
    final links = [
      ('Orders', Icons.shopping_cart, Colors.indigo, () {
        Get.to(() => const SalesOrdersScreen(), transition: Transition.rightToLeft);
      }),
      ('Invoices', Icons.receipt_long, Colors.teal, () {
        Get.snackbar('Info', 'Invoices screen coming soon');
      }),
      ('Sales Return', Icons.assignment_return, Colors.orange, () {
        Get.to(() => const SalesReturnScreen(), transition: Transition.rightToLeft);
      }),
      ('Refunds', Icons.replay, Colors.red, () {
        Get.to(() => const SalesRefundsScreen(), transition: Transition.rightToLeft);
      }),
    ];

    return _chartCard(
      'Quick Actions',
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
        children: links.map((l) {
          return InkWell(
            onTap: l.$4,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: l.$3.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: l.$3.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(l.$2, color: l.$3, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    l.$1,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: l.$3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Flow Card ─────────────────────────────────────────────────

  Widget _flowCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Flow',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            'Products → Stock → Orders → Invoice → Payment\nReturns & refunds adjust stock and revenue.',
            style: TextStyle(fontSize: 12, color: kSubText, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: TextStyle(fontSize: 10, color: kSubText),
          ),
        ],
      ),
    );
  }

  // ─── Chart Card ────────────────────────────────────────────────

  Widget _chartCard(String title, Widget child, {List<String>? legend}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if (legend != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: legend.map((l) => Text(l, style: TextStyle(fontSize: 10, color: kSubText))).toList(),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}