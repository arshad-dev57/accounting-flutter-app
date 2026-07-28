// lib/core/purchasedashboard/purchase_dashboard_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/Notifications/screens/notification_screen.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_controller.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_dashboard_model.dart';
import 'package:LedgerPro_app/core/purchasedashboard/purchase_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

const _kPageBg        = Color(0xFFF3F5FA);
const _kCardBg        = Color(0xFFFFFFFF);
const _kCardBorder    = Color(0xFFE9EBF2);
const _kTextPrimary   = Color(0xFF14162B);
const _kTextSecondary = Color(0xFF8A8FA6);
const _kBlue          = Color(0xFF4361EE);
const _kGreen         = Color(0xFF2DC653);
const _kOrange        = Color(0xFFF4A228);
const _kRed           = Color(0xFFEF4444);
const _kPurple        = Color(0xFF9B59B6);
const _kTeal          = Color(0xFF00B4D8);

class PurchaseDashboardScreen extends StatefulWidget {
  const PurchaseDashboardScreen({super.key});

  @override
  State<PurchaseDashboardScreen> createState() => _PurchaseDashboardScreenState();
}

class _PurchaseDashboardScreenState extends State<PurchaseDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PurchaseController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PurchaseController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,
      drawer: const PurchaseDrawer(currentRoute: '/warehouse/purchase'),
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kCardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kCardBorder),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _kTextPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 15, color: Colors.black),
          ),
          const SizedBox(width: 8),
          const Text(
            'Purchase',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: _kTextSecondary),
          onPressed: () {
            Get.to(() => NotificationScreen());
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.dashboard.value == null) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
        );
      }

      final isTablet = MediaQuery.of(context).size.width >= 600;

      return RefreshIndicator(
        color: kPrimary,
        backgroundColor: _kCardBg,
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(),
              const SizedBox(height: 14),
              _buildPeriodFilter(),
              const SizedBox(height: 18),
              _buildKpiGrid(isTablet),
              const SizedBox(height: 18),
              _PurchaseSpendChart(controller: controller),
              const SizedBox(height: 14),
              _PurchaseOrderStatusChart(controller: controller),
              const SizedBox(height: 14),
              _buildBottomSection(isTablet),
            ],
          ),
        ),
      );
    });
  }

  // ─── Greeting Header ───────────────────────────────────────────────────────
  Widget _buildGreetingHeader() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt  = Get.find<CurrencyController>().formatAmount;

      final totalOrders = data?.orders.total ?? 0;
      final totalSpend  = data?.invoices.totalSpend ?? 0.0;
      final outstanding = data?.invoices.outstanding ?? 0.0;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3949AB).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Purchase Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: controller.refreshDashboard,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 17, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 14),
            Row(
              children: [
                _headerStat('Orders', '$totalOrders', Icons.receipt_long_outlined, _kGreen),
                _headerDivider(),
                _headerStat('Total Spend', fmt(totalSpend), Icons.payments_outlined, const Color(0xFFEF9A9A)),
                _headerDivider(),
                _headerStat('Outstanding', fmt(outstanding), Icons.schedule_rounded, _kOrange),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _headerStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _headerDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.15),
      );

  // ─── Period Filter ──────────────────────────────────────────────────────────
  Widget _buildPeriodFilter() {
    const periods = [
      ('today', 'Today'),
      ('week',  'This Week'),
      ('month', 'This Month'),
      ('year',  'This Year'),
    ];

    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...periods.map((p) {
              final isSelected = controller.period.value == p.$1;
              return GestureDetector(
                onTap: () => controller.setPeriod(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3949AB) : _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3949AB) : _kCardBorder,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF3949AB).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _kTextSecondary,
                    ),
                  ),
                ),
              );
            }),
            // Custom range picker
            GestureDetector(
              onTap: _pickCustomDateRange,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: controller.period.value == 'custom' ? const Color(0xFF3949AB) : _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.period.value == 'custom' ? const Color(0xFF3949AB) : _kCardBorder,
                    width: 1.5,
                  ),
                  boxShadow: controller.period.value == 'custom'
                      ? [BoxShadow(color: const Color(0xFF3949AB).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 13,
                      color: controller.period.value == 'custom' ? Colors.white : _kTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      controller.period.value == 'custom'
                          ? controller.getPeriodLabel()
                          : 'Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.period.value == 'custom' ? Colors.white : _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: controller.customStart.value ?? now.subtract(const Duration(days: 30)),
        end:   controller.customEnd.value   ?? now,
      ),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3949AB),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.setPeriod('custom', start: picked.start, end: picked.end);
    }
  }

  // ─── KPI Grid ──────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt  = Get.find<CurrencyController>().formatAmount;

      final kpis = [
        _KpiData(
          label: 'TOTAL ORDERS',
          value: '${data?.orders.total ?? 0}',
          icon:  Icons.receipt_long_outlined,
          accent: _kBlue,
          sparkData: const [10, 14, 12, 18, 16, 22, 28],
          trend: '+12%',
          trendUp: true,
        ),
        _KpiData(
          label: 'TOTAL SPEND',
          value: fmt(data?.invoices.totalSpend ?? 0),
          icon:  Icons.payments_outlined,
          accent: _kPurple,
          sparkData: const [40, 55, 48, 60, 58, 72, 80],
          trend: '+8.3%',
          trendUp: true,
        ),
        _KpiData(
          label: 'AMOUNT PAID',
          value: fmt(data?.invoices.paidAmount ?? 0),
          icon:  Icons.check_circle_outline_rounded,
          accent: _kGreen,
          sparkData: const [20, 30, 28, 38, 35, 45, 50],
          trend: '+5.2%',
          trendUp: true,
        ),
        _KpiData(
          label: 'OUTSTANDING',
          value: fmt(data?.invoices.outstanding ?? 0),
          icon:  Icons.schedule_rounded,
          accent: _kOrange,
          sparkData: const [15, 20, 18, 25, 22, 28, 18],
          trend: '-10%',
          trendUp: false,
        ),
        _KpiData(
          label: 'APPROVED',
          value: '${data?.orders.approved ?? 0}',
          icon:  Icons.thumb_up_outlined,
          accent: _kTeal,
          sparkData: const [5, 8, 6, 10, 9, 12, 14],
          trend: '+7%',
          trendUp: true,
        ),
        _KpiData(
          label: 'RETURNS',
          value: '${data?.returns.total ?? 0}',
          icon:  Icons.assignment_return_outlined,
          accent: _kRed,
          sparkData: const [3, 2, 4, 1, 3, 2, 1],
          trend: '-5%',
          trendUp: false,
        ),
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kpis.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isTablet ? 1.15 : 0.95,
        ),
        itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
      );
    });
  }

  // ─── Bottom Section ─────────────────────────────────────────────────────────
  Widget _buildBottomSection(bool isTablet) {
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _PurchaseHealthPanel(controller: controller)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _RecentActivitiesPanel(controller: controller)),
        ],
      );
    }
    return Column(
      children: [
        _PurchaseHealthPanel(controller: controller),
        const SizedBox(height: 12),
        _RecentActivitiesPanel(controller: controller),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// KPI DATA & CARD
// ════════════════════════════════════════════════════════════════════════════

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final List<double> sparkData;
  final String trend;
  final bool trendUp;
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.sparkData,
    required this.trend,
    required this.trendUp,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, size: 16, color: data.accent),
              ),
              _TrendBadge(trend: data.trend, up: data.trendUp),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kTextPrimary, letterSpacing: -0.4),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kTextSecondary, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRect(
            child: SizedBox(
              height: 32,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  clipData: const FlClipData.all(),
                  minX: 0,
                  maxX: (data.sparkData.length - 1).toDouble(),
                  minY: data.sparkData.reduce((a, b) => a < b ? a : b) * 0.85,
                  maxY: data.sparkData.reduce((a, b) => a > b ? a : b) * 1.15,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.sparkData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: data.accent,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [data.accent.withValues(alpha: 0.20), data.accent.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool up;
  const _TrendBadge({required this.trend, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 9, color: color),
          const SizedBox(width: 2),
          Text(trend, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SPEND TREND CHART  (mirrors StockTrendChart)
// ════════════════════════════════════════════════════════════════════════════

class _PurchaseSpendChart extends StatelessWidget {
  final PurchaseController controller;
  const _PurchaseSpendChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trend = controller.spendTrend;

      final List<double> invoiceData = [];
      final List<double> orderData   = [];
      final List<String> labels      = [];

      if (trend.isNotEmpty) {
        for (final p in trend) {
          invoiceData.add(p.invoiceAmount);
          orderData.add(p.orderValue);
          labels.add(p.label.isNotEmpty ? p.label : p.date.split('-').last);
        }
      } else {
        invoiceData.addAll([0.0, 0, 0, 0, 0, 0, 0]);
        orderData.addAll([0.0, 0, 0, 0, 0, 0, 0]);
        labels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
      }

      return _ChartCard(
        title: 'Spend Trend',
        subtitle: controller.getPeriodLabel(),
        legend: const [
          _LegendDot(color: _kPurple, label: 'Invoiced'),
          _LegendDot(color: _kBlue,   label: 'Ordered'),
        ],
        child: SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (_) => FlLine(color: _kCardBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 20,
                    getTitlesWidget: (v, _) {
                      final lbl = v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString();
                      return Text(lbl, style: const TextStyle(fontSize: 9, color: _kTextSecondary));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: labels.length > 6 ? (labels.length / 4).ceilToDouble() : 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i], style: const TextStyle(fontSize: 9, color: _kTextSecondary)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _kTextPrimary,
                  tooltipBorder: const BorderSide(color: _kCardBorder),
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(color: s.barIndex == 0 ? _kPurple : _kBlue, fontSize: 11, fontWeight: FontWeight.w700),
                  )).toList(),
                ),
              ),
              minX: 0,
              maxX: (labels.length - 1).toDouble(),
              minY: 0,
              maxY: _maxY(invoiceData, orderData),
              lineBarsData: [
                _buildLine(invoiceData, _kPurple),
                _buildLine(orderData,   _kBlue),
              ],
            ),
          ),
        ),
      );
    });
  }

  LineChartBarData _buildLine(List<double> data, Color color) => LineChartBarData(
    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
    isCurved: true,
    color: color,
    barWidth: 2.5,
    isStrokeCapRound: true,
    dotData: FlDotData(
      show: true,
      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
    ),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
      ),
    ),
  );

  double _maxY(List<double> a, List<double> b) {
    final maxA = a.isEmpty ? 0.0 : a.reduce((x, y) => x > y ? x : y);
    final maxB = b.isEmpty ? 0.0 : b.reduce((x, y) => x > y ? x : y);
    final m    = maxA > maxB ? maxA : maxB;
    return m > 0 ? m * 1.2 : 100;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ORDER STATUS PIE CHART  (mirrors CategoryDistributionChart)
// ════════════════════════════════════════════════════════════════════════════

class _PurchaseOrderStatusChart extends StatelessWidget {
  final PurchaseController controller;
  const _PurchaseOrderStatusChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final statuses = controller.orderStatuses.where((s) => s.count > 0).toList();

      return _ChartCard(
        title: 'Orders by Status',
        subtitle: 'Purchase order breakdown',
        child: SizedBox(
          height: 190,
          child: statuses.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: statuses.asMap().entries.map((entry) {
                            Color color;
                            try {
                              color = Color(int.parse(entry.value.color.replaceAll('#', '0xFF')));
                            } catch (_) {
                              color = _kBlue;
                            }
                            return PieChartSectionData(
                              color: color,
                              value: entry.value.count.toDouble(),
                              title: '${entry.value.count}',
                              radius: 35,
                              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statuses.take(6).map((s) {
                          Color color;
                          try {
                            color = Color(int.parse(s.color.replaceAll('#', '0xFF')));
                          } catch (_) {
                            color = _kBlue;
                          }
                          final name = s.status.isNotEmpty
                              ? s.status[0].toUpperCase() + s.status.substring(1)
                              : 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 11, color: _kTextSecondary, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 32, color: _kTextSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      const Text('No order data available', style: TextStyle(fontSize: 12, color: _kTextSecondary)),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PURCHASE HEALTH PANEL  (mirrors StockHealthPanel)
// ════════════════════════════════════════════════════════════════════════════

class _PurchaseHealthPanel extends StatelessWidget {
  final PurchaseController controller;
  const _PurchaseHealthPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt  = Get.find<CurrencyController>().formatAmount;

      final items = [
        _HealthItem('Approved Orders', data?.orders.approved ?? 0, Icons.thumb_up_outlined,           _kGreen),
        _HealthItem('Draft Orders',    data?.orders.draft    ?? 0, Icons.edit_outlined,                _kBlue),
        _HealthItem('Sent Orders',     data?.orders.sent     ?? 0, Icons.send_outlined,                _kTeal),
        _HealthItem('Returns',         data?.returns.total   ?? 0, Icons.assignment_return_outlined,   _kOrange),
        _HealthItem('Cancelled',       data?.orders.cancelled ?? 0, Icons.cancel_outlined,             _kRed),
      ];

      final total = items.fold<int>(0, (s, i) => s + i.count);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _SectionTitle('Purchase Health', subtitle: 'Order status summary')),
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 10, color: _kBlue),
                        const SizedBox(width: 3),
                        Text('$total orders', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kBlue)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: items.where((i) => i.count > 0).map((item) {
                    return Expanded(flex: item.count, child: Container(height: 6, color: item.color));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...items.map((item) => _HealthRow(item: item)),
          ],
        ),
      );
    });
  }
}

class _HealthItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _HealthItem(this.label, this.count, this.icon, this.color);
}

class _HealthRow extends StatelessWidget {
  final _HealthItem item;
  const _HealthRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAlert = item.count > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isAlert
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [item.color.withValues(alpha: 0.08), item.color.withValues(alpha: 0.02)],
              )
            : null,
        color: isAlert ? null : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isAlert ? item.color.withValues(alpha: 0.25) : _kCardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isAlert ? item.color.withValues(alpha: 0.12) : _kCardBorder,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(item.icon, size: 13, color: isAlert ? item.color : _kTextSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAlert ? FontWeight.w600 : FontWeight.w400,
                color: isAlert ? _kTextPrimary : _kTextSecondary,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isAlert ? item.color.withValues(alpha: 0.15) : _kCardBorder,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.count}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isAlert ? item.color : _kTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RECENT ACTIVITIES PANEL  (mirrors RecentActivitiesPanel)
// ════════════════════════════════════════════════════════════════════════════

class _RecentActivitiesPanel extends StatelessWidget {
  final PurchaseController controller;
  const _RecentActivitiesPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final shown = controller.activities.length > 6
          ? controller.activities.sublist(0, 6)
          : controller.activities.toList();

      return Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SectionTitle('Recent Activity', subtitle: 'Latest purchase events'),
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 34, color: _kTextSecondary.withValues(alpha: 0.35)),
                      const SizedBox(height: 8),
                      const Text('No recent activity', style: TextStyle(fontSize: 12, color: _kTextSecondary)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shown.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _kCardBorder, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _ActivityTile(activity: shown[i]),
              ),
            const SizedBox(height: 6),
          ],
        ),
      );
    });
  }
}

class _ActivityTile extends StatelessWidget {
  final PurchaseActivity activity;
  const _ActivityTile({required this.activity});

  static const _typeColors = {
    'order':   _kBlue,
    'invoice': _kPurple,
    'return':  _kOrange,
  };
  static const _typeIcons = {
    'order':   Icons.receipt_long_outlined,
    'invoice': Icons.description_outlined,
    'return':  Icons.assignment_return_outlined,
  };

  String _timeAgo(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7)     return '${date.day}/${date.month}';
    if (diff.inDays > 0)     return '${diff.inDays}d ago';
    if (diff.inHours > 0)    return '${diff.inHours}h ago';
    if (diff.inMinutes > 0)  return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[activity.type] ?? _kBlue;
    final icon  = _typeIcons[activity.type]  ?? Icons.receipt_long_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.6), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Icon(icon, size: 15, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.details.isNotEmpty)
                  Text(
                    activity.details,
                    style: const TextStyle(fontSize: 10, color: _kTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo(activity.createdAt), style: const TextStyle(fontSize: 10, color: _kTextSecondary)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS  (identical structure to warehouse dashboard)
// ════════════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<_LegendDot>? legend;

  const _ChartCard({required this.title, this.subtitle, required this.child, this.legend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title, subtitle: subtitle),
              if (legend != null)
                Row(children: legend!.map((l) => Padding(padding: const EdgeInsets.only(left: 12), child: l)).toList()),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: _kTextSecondary)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary)),
        if (subtitle != null)
          Text(subtitle!, style: const TextStyle(fontSize: 10, color: _kTextSecondary)),
      ],
    );
  }
}