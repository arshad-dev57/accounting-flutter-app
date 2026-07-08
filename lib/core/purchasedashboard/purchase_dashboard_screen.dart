// lib/core/warehouse/purchase/screen/purchase_dashboard_screen.dart - COMPLETE

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_controller.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_dashboard_model.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_drawer.dart';
import 'package:LedgerPro_app/core/warehouse/purchases/screen/purchase_order_screen.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseDashboardScreen extends StatelessWidget {
  const PurchaseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseController());
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: kBg,
      drawer: isMobile ? const PurchaseDrawer(currentRoute: '/warehouse/purchase') : null,
      appBar: AppBar(
        title: const Text(
          'Purchase',
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
                  _purchaseChart(context, data),
                  const SizedBox(height: 16),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _purchaseStatusChart(data)),
                        const SizedBox(width: 16),
                        Expanded(child: _quickLinks(context)),
                      ],
                    )
                  else ...[
                    _purchaseStatusChart(data),
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

  Widget _buildGreetingHeader(PurchaseController controller) {
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
                  'Purchase Overview',
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

  Widget _periodChips(PurchaseController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() => Row(
            children: PurchaseController.periods.map((p) {
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

  Widget _kpiGrid(BuildContext context, PurchaseDashboardModel data, bool isTablet) {
    final fmt = Get.find<CurrencyController>().formatAmount;
    final cards = [
      _kpi('Purchase Orders', '${data.orders.count}', Icons.receipt_long_outlined, Colors.indigo),
      _kpi('Total Value', fmt(data.orders.totalValue), Icons.attach_money, Colors.teal),
      _kpi('Approved Orders', '${data.orders.approvedCount}', Icons.check_circle_outline, Colors.green),
      _kpi('Approved Value', fmt(data.orders.approvedValue), Icons.verified, Colors.green.shade700),
      _kpi('Draft', '${data.orders.draftCount}', Icons.edit_outlined, Colors.orange),
      _kpi('Sent', '${data.orders.sentCount}', Icons.send_outlined, Colors.blue),
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

  // ─── Purchase Chart ────────────────────────────────────────────

  Widget _purchaseChart(BuildContext context, PurchaseDashboardModel data) {
    final trend = data.orders.trend;
    if (trend.isEmpty) {
      return _chartCard(
        'Purchase Trend',
        const Center(child: Text('No data for this period', style: TextStyle(color: Colors.grey))),
      );
    }

    final sorted = trend.map((p) => p.date).toList()..sort();

    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      final point = trend.firstWhere((p) => p.date == d, orElse: () => PurchaseTrendPoint(date: d, value: 0));
      spots.add(FlSpot(i.toDouble(), point.value));
    }

    final maxY = spots.fold<double>(0, (a, b) => b.y > a ? b.y : a);

    return _chartCard(
      'Purchase Trend',
      SizedBox(
        height: 200,
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
                spots: spots,
                isCurved: true,
                color: Colors.teal,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.teal.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Purchase Status Chart ─────────────────────────────────────

  Widget _purchaseStatusChart(PurchaseDashboardModel data) {
    final items = [
      PurchaseStatusItem(status: 'Draft', count: data.orders.draftCount, color: Colors.orange),
      PurchaseStatusItem(status: 'Sent', count: data.orders.sentCount, color: Colors.blue),
      PurchaseStatusItem(status: 'Approved', count: data.orders.approvedCount, color: Colors.green),
      PurchaseStatusItem(status: 'Cancelled', count: data.orders.cancelledCount, color: Colors.red),
    ].where((s) => s.count > 0).toList();

    if (items.isEmpty) {
      return _chartCard(
        'Purchase Orders by Status',
        const Center(child: Text('No purchase orders', style: TextStyle(color: Colors.grey))),
      );
    }

    return _chartCard(
      'Purchase Orders by Status',
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
                        items[i].status,
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
                    color: items[group.x].color,
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
                    color: items[i].color,
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
      ('Purchase Orders', Icons.receipt_long, Colors.indigo, () {
        Get.to(() => const PurchaseOrderScreen(), transition: Transition.rightToLeft);
      }),
      ('Suppliers', Icons.business, Colors.teal, () {
        Get.snackbar('Info', 'Suppliers screen coming soon');
      }),
      ('Goods Receiving', Icons.inventory, Colors.orange, () {
        Get.snackbar('Info', 'Goods Receiving screen coming soon');
      }),
      ('Purchase Returns', Icons.assignment_return, Colors.red, () {
        Get.snackbar('Info', 'Purchase Returns screen coming soon');
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
            'Purchase Flow',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            'Purchase Order → Goods Receiving → Purchase Invoice → Payment\nReturns adjust stock and accounts payable.',
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


class PurchaseStatusItem {
  final String status;
  final int count;
  final Color color;

  PurchaseStatusItem({
    required this.status,
    required this.count,
    required this.color,
  });
}