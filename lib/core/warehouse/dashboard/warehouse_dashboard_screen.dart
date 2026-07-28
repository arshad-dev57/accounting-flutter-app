// lib/core/warehouse/dashboard/warehouse_dashboard.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/Notifications/screens/notification_screen.dart';
import 'package:LedgerPro_app/core/warehouse/dashboard/warehouse_dashboard_controller.dart';
import 'package:LedgerPro_app/core/warehouse/widgets/drawer_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

const _kPageBg = Color(0xFFF3F5FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFE9EBF2);
const _kTextPrimary = Color(0xFF14162B);
const _kTextSecondary = Color(0xFF8A8FA6);
const _kBlue = Color(0xFF4361EE);
const _kGreen = Color(0xFF2DC653);
const _kOrange = Color(0xFFF4A228);
const _kRed = Color(0xFFEF4444);
const _kPurple = Color(0xFF9B59B6);

class WarehouseDashboard extends StatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WarehouseDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WarehouseDashboardController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,
      drawer: const WarehouseDrawer(),
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildContent()),
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
            child: const Icon(
              Icons.warehouse_rounded,
              size: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Inventory',
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
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: _kTextSecondary,
          ),
          onPressed: () {
            Get.to(() =>  NotificationScreen());
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContent() {
    final route = Get.currentRoute;

    switch (route) {
      case '/warehouse/dashboard':
        return const DashboardContentScreen();
      case '/warehouse/products':
        // Navigate to Products Screen - you can import and return the screen here
        return const Center(child: Text('Products Screen'));
      case '/warehouse/categories':
        return const Center(child: Text('Categories Screen'));
      case '/warehouse/suppliers':
        return const Center(child: Text('Suppliers Screen'));
      case '/warehouse/customers':
        return const Center(child: Text('Customers Screen'));
      case '/warehouse/invoices':
        return const Center(child: Text('Invoices Screen'));
      case '/warehouse/stock':
        return const Center(child: Text('Stock Movement Screen'));
      case '/warehouse/inventory':
        return const Center(child: Text('Inventory Valuation Screen'));
      case '/warehouse/reports':
        return const Center(child: Text('Reports Screen'));
      default:
        return const DashboardContentScreen();
    }
  }
}

class DashboardContentScreen extends StatelessWidget {
  const DashboardContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WarehouseDashboardController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      return RefreshIndicator(
        color: kPrimary,
        backgroundColor: _kCardBg,
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(controller),
              const SizedBox(height: 14),
              _buildPeriodFilter(controller),
              const SizedBox(height: 18),
              _buildKpiGrid(controller, isTablet),
              const SizedBox(height: 18),
              _StockTrendChart(controller: controller),
              const SizedBox(height: 14),
              _CategoryDistributionChart(controller: controller),
              const SizedBox(height: 14),
              _buildBottomSection(controller, isTablet),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGreetingHeader(WarehouseDashboardController controller) {
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
            color: const Color(0xFF3949AB).withOpacity(0.35),
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
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      controller.getCurrentDate(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => controller.refreshDashboard(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 14),
          Row(
            children: [
              _headerStat(
                'Stock In Today',
                '${controller.todayStockIn.value}',
                Icons.arrow_downward_rounded,
                _kGreen,
              ),
              _headerDivider(),
              _headerStat(
                'Stock Out Today',
                '${controller.todayStockOut.value}',
                Icons.arrow_upward_rounded,
                const Color(0xFFEF9A9A),
              ),
              _headerDivider(),
              _headerStat(
                'Low Stock',
                '${controller.lowStockCount.value}',
                Icons.warning_amber_rounded,
                _kOrange,
              ),
            ],
          ),
        ],
      ),
    );
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
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // ─── Period Filter Bar ─────────────────────────────────────────────────
  Widget _buildPeriodFilter(WarehouseDashboardController controller) {
    const periods = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('year', 'This Year'),
    ];

    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...periods.map((p) {
              final isSelected = controller.selectedPeriod.value == p.$1;
              return GestureDetector(
                onTap: () => controller.applyPeriodFilter(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3949AB) : _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3949AB)
                          : _kCardBorder,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3949AB).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
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
            // Custom date picker
            GestureDetector(
              onTap: () => _pickCustomDateRange(controller),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: controller.selectedPeriod.value == 'custom'
                      ? const Color(0xFF3949AB)
                      : _kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.selectedPeriod.value == 'custom'
                        ? const Color(0xFF3949AB)
                        : _kCardBorder,
                    width: 1.5,
                  ),
                  boxShadow: controller.selectedPeriod.value == 'custom'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3949AB).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 13,
                      color: controller.selectedPeriod.value == 'custom'
                          ? Colors.white
                          : _kTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      controller.selectedPeriod.value == 'custom'
                          ? controller.getPeriodLabel()
                          : 'Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.selectedPeriod.value == 'custom'
                            ? Colors.white
                            : _kTextSecondary,
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

  Future<void> _pickCustomDateRange(
    WarehouseDashboardController controller,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start:
            controller.customStartDate.value ??
            now.subtract(const Duration(days: 30)),
        end: controller.customEndDate.value ?? now,
      ),
      builder: (context, child) => Theme(
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
      controller.applyPeriodFilter(
        'custom',
        start: picked.start,
        end: picked.end,
      );
    }
  }

  // ─── KPI Grid ──────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(WarehouseDashboardController controller, bool isTablet) {
    final kpis = [
      _KpiData(
        label: 'TOTAL PRODUCTS',
        value: '${controller.totalProducts.value}',
        icon: Icons.inventory_2_outlined,
        accent: _kBlue,
        sparkData: [
          3.0,
          5,
          4,
          7,
          6,
          8,
          controller.totalProducts.value.toDouble(),
        ],
        trend: '+12%',
        trendUp: true,
      ),
      _KpiData(
        label: 'STOCK VALUE',
        value: controller.formatCurrency(controller.totalStockValue.value),
        icon: Icons.account_balance_wallet_outlined,
        accent: _kGreen,
        sparkData: const [40, 55, 48, 60, 58, 72, 80],
        trend: '+8.3%',
        trendUp: true,
      ),
      _KpiData(
        label: 'LOW STOCK',
        value: '${controller.lowStockCount.value}',
        icon: Icons.warning_amber_rounded,
        accent: _kOrange,
        sparkData: const [5, 6, 4, 7, 5, 8, 3],
        trend: '-10%',
        trendUp: false,
      ),
      _KpiData(
        label: "TODAY'S MOVEMENTS",
        value:
            '${controller.todayStockIn.value + controller.todayStockOut.value}',
        icon: Icons.sync_alt_rounded,
        accent: _kPurple,
        sparkData: const [10, 15, 12, 20, 18, 25, 30],
        trend: '+15%',
        trendUp: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.15 : 0.95,
      ),
      itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
    );
  }

  // ─── Bottom Section ─────────────────────────────────────────────────────
  Widget _buildBottomSection(
    WarehouseDashboardController controller,
    bool isTablet,
  ) {
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _StockHealthPanel(controller: controller)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _RecentActivitiesPanel(controller: controller),
          ),
        ],
      );
    }

    return Column(
      children: [
        _StockHealthPanel(controller: controller),
        const SizedBox(height: 12),
        _RecentActivitiesPanel(controller: controller),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// KPI DATA CLASS
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

// ════════════════════════════════════════════════════════════════════════════
// KPI CARD
// ════════════════════════════════════════════════════════════════════════════

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: data.accent.withOpacity(0.10),
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
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
              letterSpacing: 0.5,
            ),
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
                      spots: data.sparkData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
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
                          colors: [
                            data.accent.withOpacity(0.20),
                            data.accent.withOpacity(0.0),
                          ],
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

// ════════════════════════════════════════════════════════════════════════════
// TREND BADGE
// ════════════════════════════════════════════════════════════════════════════

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool up;

  const _TrendBadge({required this.trend, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            trend,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STOCK TREND CHART
// ════════════════════════════════════════════════════════════════════════════

class _StockTrendChart extends StatelessWidget {
  final WarehouseDashboardController controller;
  const _StockTrendChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final chartData = controller.stockMovementChart;

    final List<double> inData = [];
    final List<double> outData = [];
    final List<String> labels = [];

    if (chartData.isNotEmpty) {
      for (var item in chartData) {
        inData.add((item['stockIn'] ?? 0).toDouble());
        outData.add((item['stockOut'] ?? 0).toDouble());
        labels.add(item['label'] ?? '');
      }
    } else {
      inData.addAll([0.0, 0, 0, 0, 0, 0, 0]);
      outData.addAll([0.0, 0, 0, 0, 0, 0, 0]);
      labels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    }

    return _ChartCard(
      title: 'Stock Movement',
      subtitle: controller.getPeriodLabel(),
      legend: const [
        _LegendDot(color: _kGreen, label: 'Stock In'),
        _LegendDot(color: _kBlue, label: 'Stock Out'),
      ],
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: _kCardBorder, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 20,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: _kTextSecondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[i],
                        style: const TextStyle(
                          fontSize: 9,
                          color: _kTextSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => _kTextPrimary,
                tooltipBorder: BorderSide(color: _kCardBorder),
                getTooltipItems: (spots) => spots.map((s) {
                  return LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      color: s.barIndex == 0 ? _kGreen : _kBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
            minX: 0,
            maxX: (labels.length - 1).toDouble(),
            minY: 0,
            maxY: _getMaxValue(inData, outData),
            lineBarsData: [
              LineChartBarData(
                spots: inData
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: _kGreen,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: _kGreen,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kGreen.withOpacity(0.15),
                      _kGreen.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: outData
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: _kBlue,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: _kBlue,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kBlue.withOpacity(0.10), _kBlue.withOpacity(0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxValue(List<double> inData, List<double> outData) {
    final maxIn = inData.isEmpty ? 0 : inData.reduce((a, b) => a > b ? a : b);
    final maxOut = outData.isEmpty
        ? 0
        : outData.reduce((a, b) => a > b ? a : b);
    final maxVal = maxIn > maxOut ? maxIn : maxOut;
    return maxVal > 0 ? maxVal * 1.2 : 50;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CATEGORY DISTRIBUTION CHART
// ════════════════════════════════════════════════════════════════════════════

class _CategoryDistributionChart extends StatelessWidget {
  final WarehouseDashboardController controller;
  const _CategoryDistributionChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final categories = controller.categoryDistribution;
    final hasData =
        categories.isNotEmpty &&
        categories.any((c) => (c['productCount'] ?? 0) > 0);

    return _ChartCard(
      title: 'Category Distribution',
      subtitle: 'Products per category',
      child: SizedBox(
        height: 190,
        child: hasData
            ? Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categories.map((c) {
                          final value = (c['productCount'] ?? 0).toDouble();
                          final colorStr = c['color'] as String? ?? '#2196F3';
                          Color color;
                          try {
                            color = Color(
                              int.parse(colorStr.replaceAll('#', '0xFF')),
                            );
                          } catch (_) {
                            color = _kBlue;
                          }
                          return PieChartSectionData(
                            color: color,
                            value: value,
                            title: '${value.toInt()}',
                            radius: 35,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      children: categories.take(5).map((c) {
                        final colorStr = c['color'] as String? ?? '#2196F3';
                        Color color;
                        try {
                          color = Color(
                            int.parse(colorStr.replaceAll('#', '0xFF')),
                          );
                        } catch (_) {
                          color = _kBlue;
                        }
                        final name = c['categoryName'] ?? 'Unknown';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _kTextSecondary,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                    Icon(
                      Icons.pie_chart_outline,
                      size: 32,
                      color: _kTextSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No category data available',
                      style: TextStyle(fontSize: 12, color: _kTextSecondary),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STOCK HEALTH PANEL
// ════════════════════════════════════════════════════════════════════════════

class _StockHealthPanel extends StatelessWidget {
  final WarehouseDashboardController controller;

  const _StockHealthPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HealthItem(
        'Low Stock',
        controller.lowStockCount.value,
        Icons.warning_amber_rounded,
        _kOrange,
      ),
      _HealthItem(
        'Out of Stock',
        controller.outOfStockCount.value,
        Icons.block,
        _kRed,
      ),
      _HealthItem(
        'Expiring Soon',
        controller.expiringCount.value,
        Icons.event_outlined,
        _kRed,
      ),
      _HealthItem(
        'Overstock',
        controller.overstockCount.value,
        Icons.inventory,
        _kPurple,
      ),
    ];

    final total = items.fold<int>(0, (s, i) => s + i.count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  'Stock Health',
                  subtitle: 'Alerts & warnings',
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRed.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 10,
                        color: _kRed,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$total alerts',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
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
                  return Expanded(
                    flex: item.count,
                    child: Container(height: 6, color: item.color),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...items.map((item) => _HealthRow(item: item)),
        ],
      ),
    );
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
                colors: [
                  item.color.withOpacity(0.08),
                  item.color.withOpacity(0.02),
                ],
              )
            : null,
        color: isAlert ? null : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert ? item.color.withOpacity(0.25) : _kCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isAlert ? item.color.withOpacity(0.12) : _kCardBorder,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              item.icon,
              size: 13,
              color: isAlert ? item.color : _kTextSecondary,
            ),
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
              color: isAlert ? item.color.withOpacity(0.15) : _kCardBorder,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.count}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isAlert ? item.color : _kTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RECENT ACTIVITIES PANEL
// ════════════════════════════════════════════════════════════════════════════

class _RecentActivitiesPanel extends StatelessWidget {
  final WarehouseDashboardController controller;

  const _RecentActivitiesPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final activities = controller.recentActivities;
    final shown = activities.length > 6 ? activities.sublist(0, 6) : activities;

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionTitle(
              'Recent Activity',
              subtitle: 'Latest warehouse events',
            ),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 34,
                      color: _kTextSecondary.withOpacity(0.35),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No recent activity',
                      style: TextStyle(fontSize: 12, color: _kTextSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: _kCardBorder,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, i) => _ActivityTile(activity: shown[i]),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACTIVITY TILE
// ════════════════════════════════════════════════════════════════════════════

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final user = (activity['user'] ?? 'U') as String;
    final initial = user.isNotEmpty ? user[0].toUpperCase() : 'U';
    final timeAgo = _timeAgo(activity['createdAt']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.6), kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['action'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((activity['details'] ?? '').toString().isNotEmpty)
                  Text(
                    activity['details'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _kTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeAgo,
            style: const TextStyle(fontSize: 10, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<_LegendDot>? legend;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title, subtitle: subtitle),
              if (legend != null)
                Row(
                  children: legend!
                      .map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: l,
                        ),
                      )
                      .toList(),
                ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: _kTextSecondary),
        ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 10, color: _kTextSecondary),
          ),
      ],
    );
  }
}
