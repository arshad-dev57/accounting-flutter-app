// lib/core/warehouse/sales/screen/sales_dashboard_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/Notifications/screens/notification_screen.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette (matching inventory dashboard)
// ─────────────────────────────────────────────────────────────────────────────
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

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesController());
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: _kPageBg,
      drawer: isMobile ? const SalesDrawer(currentRoute: '/warehouse/sales') : null,
      appBar: _buildAppBar(isMobile),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmerLoading(isTablet);
        }

        final data = controller.dashboard.value;
        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: controller.fetchDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data != null) ...[
                  _buildGreetingHeader(controller, data),
                  const SizedBox(height: 14),
                  _buildPeriodFilter(controller),
                  const SizedBox(height: 18),
                  _kpiGrid(context, data, isTablet),
                  const SizedBox(height: 18),
                  _SectionPadding(
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _RevenueChart(data: data)),
                              const SizedBox(width: 12),
                              Expanded(child: _OrderStatusChart(data: data)),
                            ],
                          )
                        : Column(
                            children: [
                              _RevenueChart(data: data),
                              const SizedBox(height: 12),
                              _OrderStatusChart(data: data),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SectionPadding(
                    child: _buildComparisonCardsHorizontal(controller, isTablet),
                  ),
                  const SizedBox(height: 14),
                  _SectionPadding(
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildReceivablesAndActivity(controller)),
                              const SizedBox(width: 12),
                              Expanded(child: _quickLinks(context)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildReceivablesAndActivity(controller),
                              const SizedBox(height: 12),
                              _quickLinks(context),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SectionPadding(
                    child: _buildTopProductsAndCustomers(controller, isTablet),
                  ),
                  const SizedBox(height: 14),
                  _SectionPadding(
                    child: _buildRevenueBreakdown(controller),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: _kCardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kCardBorder),
      ),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: _kTextPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
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
              Icons.trending_up_rounded,
              size: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Sales',
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

  // ─── Greeting Header ──────────────────────────────────────────────────────
  Widget _buildGreetingHeader(SalesController controller, SalesDashboardModel data) {
    final fmt = Get.find<CurrencyController>().formatAmount;
    
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
                  Icons.trending_up_rounded,
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
                      'Sales Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _getCurrentDate(),
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
                onTap: () => controller.fetchDashboard(),
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
                'Today Orders',
                '${data.orders.todayCount}',
                Icons.shopping_cart_rounded,
                _kBlue,
              ),
              _headerDivider(),
              _headerStat(
                'Today Revenue',
                fmt(data.orders.todayRevenue),
                Icons.attach_money_rounded,
                _kGreen,
              ),
              _headerDivider(),
              _headerStat(
                'Pending',
                '${data.orders.pendingCount}',
                Icons.pending_rounded,
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

  String _getCurrentDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMM d, yyyy').format(now);
  }

  // ─── Shimmer Loading ───────────────────────────────────────────────────
  Widget _buildShimmerLoading(bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            // Period filter
            Row(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 80,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // KPI Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isTablet ? 1.15 : 0.95,
              ),
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Charts row
            if (isTablet)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            // Comparison cards
            Row(
              children: List.generate(
                2,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 0 ? 12 : 0),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Bottom section
            if (isTablet)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─── Period Filter Bar ─────────────────────────────────────────────────
  Widget _buildPeriodFilter(SalesController controller) {
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
            // Custom date range button
            GestureDetector(
              onTap: () => _showDateRangePicker(controller),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 4),
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
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: controller.selectedPeriod.value == 'custom'
                          ? Colors.white
                          : _kTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.useCustomDateRange.value && 
                      controller.startDate.value != null && 
                      controller.endDate.value != null
                          ? '${_formatShortDate(controller.startDate.value!)} - ${_formatShortDate(controller.endDate.value!)}'
                          : 'Custom',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.selectedPeriod.value == 'custom'
                            ? Colors.white
                            : _kTextSecondary,
                      ),
                    ),
                    if (controller.useCustomDateRange.value) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => controller.clearCustomDateRange(),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  Future<void> _showDateRangePicker(SalesController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.startDate.value != null && controller.endDate.value != null
          ? DateTimeRange(start: controller.startDate.value!, end: controller.endDate.value!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3949AB),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setCustomDateRange(picked.start, picked.end);
    }
  }

  // ─── KPI Grid ──────────────────────────────────────────────────

  Widget _kpiGrid(BuildContext context, SalesDashboardModel data, bool isTablet) {
    final fmt = Get.find<CurrencyController>().formatAmount;
    
    final kpis = [
      _KpiData(
        label: 'ORDER REVENUE',
        value: fmt(data.orders.revenue),
        icon: Icons.shopping_cart_outlined,
        accent: _kBlue,
        sparkData: _generateSparkData(data.orders.revenue),
        trend: data.orders.revenueGrowth,
        trendUp: data.orders.revenueGrowth.startsWith('+'),
      ),
      _KpiData(
        label: 'INVOICE TOTAL',
        value: fmt(data.invoices.grandTotal),
        icon: Icons.receipt_long_outlined,
        accent: _kGreen,
        sparkData: _generateSparkData(data.invoices.grandTotal),
        trend: data.invoices.grandTotalGrowth,
        trendUp: data.invoices.grandTotalGrowth.startsWith('+'),
      ),
      _KpiData(
        label: 'COLLECTED',
        value: fmt(data.invoices.paidAmount),
        icon: Icons.payments_outlined,
        accent: const Color(0xFF2E7D32),
        sparkData: _generateSparkData(data.invoices.paidAmount),
        trend: data.invoices.paidAmountGrowth,
        trendUp: data.invoices.paidAmountGrowth.startsWith('+'),
      ),
      _KpiData(
        label: 'OUTSTANDING',
        value: fmt(data.invoices.outstanding),
        icon: Icons.pending_actions_outlined,
        accent: _kOrange,
        sparkData: _generateSparkData(data.invoices.outstanding),
        trend: data.invoices.outstandingGrowth,
        trendUp: data.invoices.outstandingGrowth.startsWith('+'),
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

  List<double> _generateSparkData(dynamic value) {
    // Generate mock sparkline data based on value
    final baseValue = value is num ? value.toDouble() : 0.0;
    return [
      (baseValue * 0.7).toDouble(),
      (baseValue * 0.85).toDouble(),
      (baseValue * 0.75).toDouble(),
      (baseValue * 0.9).toDouble(),
      (baseValue * 0.8).toDouble(),
      (baseValue * 0.95).toDouble(),
      baseValue,
    ];
  }
}


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
                  minY: data.sparkData.reduce((a, b) => a < b ? a : b).toDouble() * 0.85,
                  maxY: data.sparkData.reduce((a, b) => a > b ? a : b).toDouble() * 1.15,
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
// CHART CARD SHELL
// ════════════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<_LegendDot>? legend;
  final Widget child;

  const _ChartCard({
    required this.title,
    this.subtitle,
    this.legend,
    required this.child,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (legend != null)
                Row(
                  children: legend!,
                ),
            ],
          ),
          const SizedBox(height: 12),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _kTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPadding extends StatelessWidget {
  final Widget child;

  const _SectionPadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REVENUE CHART
// ════════════════════════════════════════════════════════════════════════════

class _RevenueChart extends StatelessWidget {
  final SalesDashboardModel data;

  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final invoiceTrend = data.invoices.trend;
    final orderTrend = data.orders.trend;
    if (invoiceTrend.isEmpty && orderTrend.isEmpty) {
      return _ChartCard(
        title: 'Revenue Trend',
        child: const _EmptyState(label: 'No data for this period'),
      );
    }

    final allDates = <String>{};
    for (final p in invoiceTrend) allDates.add(p.date);
    for (final p in orderTrend) allDates.add(p.date);
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

    return _ChartCard(
      title: 'Revenue Trend',
      legend: const [
        _LegendDot(color: Color(0xFF0097A7), label: 'Invoices'),
        _LegendDot(color: _kBlue, label: 'Orders'),
      ],
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (_) => FlLine(color: _kCardBorder, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: maxY > 0 ? maxY / 4 : 25,
                  getTitlesWidget: (v, _) => Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
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
                    if (i < 0 || i >= sorted.length) return const SizedBox();
                    final parts = sorted[i].split('-');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${parts[2]}/${parts[1]}',
                        style: const TextStyle(fontSize: 9, color: _kTextSecondary),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      color: s.barIndex == 0 ? const Color(0xFF0097A7) : _kBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
            minX: 0,
            maxX: (sorted.length - 1).toDouble(),
            minY: 0,
            maxY: maxY <= 0 ? 100 : maxY * 1.15,
            lineBarsData: [
              LineChartBarData(
                spots: invoiceSpots,
                isCurved: true,
                color: const Color(0xFF0097A7),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0097A7).withOpacity(0.20),
                      const Color(0xFF0097A7).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: orderSpots,
                isCurved: true,
                color: _kBlue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kBlue.withOpacity(0.20),
                      _kBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ORDER STATUS CHART
// ════════════════════════════════════════════════════════════════════════════

class _OrderStatusChart extends StatelessWidget {
  final SalesDashboardModel data;

  const _OrderStatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.orders.byStatus.where((s) => s.count > 0).toList();
    if (items.isEmpty) {
      return _ChartCard(
        title: 'Orders by Status',
        child: const _EmptyState(label: 'No orders'),
      );
    }

    final colors = [
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.green.shade400,
      Colors.red.shade400,
    ];

    return _ChartCard(
      title: 'Orders by Status',
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: items.map((e) => e.count.toDouble()).reduce((a, b) => a > b ? a : b).toDouble() * 1.2 + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: _kCardBorder, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: _kTextSecondary),
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
                        style: const TextStyle(fontSize: 9, color: _kTextSecondary),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _kTextPrimary,
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
                    width: 20,
                    borderRadius: BorderRadius.circular(6),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONTINUATION OF SALES DASHBOARD SCREEN METHODS
// ════════════════════════════════════════════════════════════════════════════

extension _SalesDashboardMethods on SalesDashboardScreen {
  Widget _buildComparisonCardsHorizontal(SalesController controller, bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final comparison = data?.comparison;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final cards = [
        _ComparisonCard(
          period: 'Today',
          subLabel: 'vs Yesterday',
          sales: fmt(comparison?.today.currentSales ?? 0),
          returns: fmt(comparison?.today.currentReturns ?? 0),
          salesChange: comparison?.today.salesChangePercent ?? 0,
          returnsChange: comparison?.today.returnsChangePercent ?? 0,
        ),
        _ComparisonCard(
          period: 'This Week',
          subLabel: 'vs Last Week',
          sales: fmt(comparison?.week.currentSales ?? 0),
          returns: fmt(comparison?.week.currentReturns ?? 0),
          salesChange: comparison?.week.salesChangePercent ?? 0,
          returnsChange: comparison?.week.returnsChangePercent ?? 0,
        ),
        _ComparisonCard(
          period: 'This Month',
          subLabel: 'vs Last Month',
          sales: fmt(comparison?.month.currentSales ?? 0),
          returns: fmt(comparison?.month.currentReturns ?? 0),
          salesChange: comparison?.month.salesChangePercent ?? 0,
          returnsChange: comparison?.month.returnsChangePercent ?? 0,
        ),
        _ComparisonCard(
          period: 'This Year',
          subLabel: 'vs Last Year',
          sales: fmt(comparison?.year.currentSales ?? 0),
          returns: fmt(comparison?.year.currentReturns ?? 0),
          salesChange: comparison?.year.salesChangePercent ?? 0,
          returnsChange: comparison?.year.returnsChangePercent ?? 0,
        ),
      ];

      if (isTablet) {
        return Row(
          children: cards
              .map((c) => Expanded(child: c))
              .expand((w) => [w, const SizedBox(width: 12)])
              .toList()
            ..removeLast(),
        );
      } else {
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ),
          ],
        );
      }
    });
  }

  // ─── Receivables & Activity ─────────────────────────────────────────

  Widget _buildReceivablesAndActivity(SalesController controller) {
    return Obx(() {
      final data = controller.dashboard.value;
      final recentActivity = data?.recentActivity ?? [];
      final fmt = Get.find<CurrencyController>().formatAmount;

      return _ChartCard(
        title: 'Recent Activity',
        child: recentActivity.isEmpty
            ? const _EmptyState(label: 'No recent activity')
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivity.take(5).length,
                separatorBuilder: (_, __) => Divider(
                  color: _kCardBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final activity = recentActivity[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kBlue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getActivityIcon(activity.type),
                            size: 18,
                            color: _kBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activity.timestamp,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          activity.amount != null ? fmt(activity.amount) : '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    });
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_cart_rounded;
      case 'invoice':
        return Icons.receipt_long_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'return':
        return Icons.assignment_return_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ─── Quick Links ─────────────────────────────────────────────────

  Widget _quickLinks(BuildContext context) {
    final links = [
      ('New Order', Icons.add_shopping_cart, '/sales/orders'),
      ('New Invoice', Icons.receipt, '/sales-invoices'),
      ('Customers', Icons.people, '/sales/warehouse-customers'),
      ('Reports', Icons.bar_chart, '/sales/reports'),
    ];

    return _ChartCard(
      title: 'Quick Actions',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return GestureDetector(
            onTap: () => Get.toNamed(link.$3),
            child: Container(
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlue.withOpacity(0.15)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(link.$2, size: 24, color: _kBlue),
                  const SizedBox(height: 8),
                  Text(
                    link.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Top Products & Customers ─────────────────────────────────────

  Widget _buildTopProductsAndCustomers(SalesController controller, bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final topProducts = data?.topProducts ?? [];
      final topCustomers = data?.topCustomers ?? [];
      final fmt = Get.find<CurrencyController>().formatAmount;

      if (isTablet) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Top Products',
                child: topProducts.isEmpty
                    ? const _EmptyState(label: 'No products')
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topProducts.take(5).length,
                        separatorBuilder: (_, __) => Divider(color: _kCardBorder, height: 1),
                        itemBuilder: (context, index) {
                          final product = topProducts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _kTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${product.quantitySold} sold',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  fmt(product.revenue),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChartCard(
                title: 'Top Customers',
                child: topCustomers.isEmpty
                    ? const _EmptyState(label: 'No customers')
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topCustomers.take(5).length,
                        separatorBuilder: (_, __) => Divider(color: _kCardBorder, height: 1),
                        itemBuilder: (context, index) {
                          final customer = topCustomers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _kGreen.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      customer.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _kGreen,
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
                                        customer.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _kTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${customer.orderCount} orders',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  fmt(customer.totalSpent),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _ChartCard(
              title: 'Top Products',
              child: topProducts.isEmpty
                  ? const _EmptyState(label: 'No products')
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topProducts.take(5).length,
                      separatorBuilder: (_, __) => Divider(color: _kCardBorder, height: 1),
                      itemBuilder: (context, index) {
                        final product = topProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${product.quantitySold} sold',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                fmt(product.revenue),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Top Customers',
              child: topCustomers.isEmpty
                  ? const _EmptyState(label: 'No customers')
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topCustomers.take(5).length,
                      separatorBuilder: (_, __) => Divider(color: _kCardBorder, height: 1),
                      itemBuilder: (context, index) {
                        final customer = topCustomers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _kGreen.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen,
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
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${customer.orderCount} orders',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                fmt(customer.totalSpent),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }
    });
  }

  // ─── Revenue Breakdown ───────────────────────────────────────────

  Widget _buildRevenueBreakdown(SalesController controller) {
    return Obx(() {
      final data = controller.dashboard.value;
      final breakdown = data?.revenueBreakdown;
      final fmt = Get.find<CurrencyController>().formatAmount;
      final items = breakdown?.items ?? [];

      return _ChartCard(
        title: 'Revenue Breakdown',
        child: items.isEmpty
            ? const _EmptyState(label: 'No revenue data')
            : Column(
                children: [
                  ...items.map((item) {
                    final percentage = item.percentage;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: _kCardBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(_kBlue),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt(item.amount),
                            style: TextStyle(
                              fontSize: 10,
                              color: _kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPARISON CARD
// ════════════════════════════════════════════════════════════════════════════

class _ComparisonCard extends StatelessWidget {
  final String period;
  final String subLabel;
  final String sales;
  final String returns;
  final double salesChange;
  final double returnsChange;

  const _ComparisonCard({
    required this.period,
    required this.subLabel,
    required this.sales,
    required this.returns,
    required this.salesChange,
    required this.returnsChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            period,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 10,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales',
                      style: TextStyle(
                        fontSize: 9,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sales,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _ChangeBadge(percent: salesChange),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: _kCardBorder,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Returns',
                      style: TextStyle(
                        fontSize: 9,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      returns,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _ChangeBadge(percent: returnsChange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final double percent;

  const _ChangeBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isPositive = percent >= 0;
    final color = isPositive ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}