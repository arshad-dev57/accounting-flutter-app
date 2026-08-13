import 'dart:io';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/widgets/fiscal_year_select.dart';
import 'package:BisonsTechs_app/core/Notifications/screens/notification_screen.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_controller.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_dashboard_model.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// ─── White theme palette (identical to DashboardScreen) ───────────────────
const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFEEEFF4);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF8A8FA8);
const _kTextMuted = Color(0xFFB0B4C8);
const _kAppBarBg = Color(0xFFF7F9FC);
const _kChipBg = Color(0xFFF0F2F8);

// Semantic colours — same as DashboardScreen
const _kPrimaryBg = Color(0xFFE6EEF5);
const _kGreen = Color(0xFF22A869);
const _kGreenBg = Color(0xFFEAF7F1);
const _kOrange = Color(0xFFF59E0B);
const _kOrangeBg = Color(0xFFFFF8E7);
const _kRed = Color(0xFFEF4444);
const _kRedBg = Color(0xFFFEF2F2);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F0FF);
const _kTeal = Color(0xFF0891B2);
const _kTealBg = Color(0xFFECFAFF);

// Hero card — same gradient tint as DashboardScreen hero
const _kHeroBg = Color(0xFFE6EEF5);
const _kHeroBgEnd = Color(0xFFD6E4F0);
const _kHeroBorder = Color(0xFFB8CFE0);
const _kHeroIcon = Color(0xFFC5D8E8);

class PurchaseDashboardScreen extends GetView<PurchaseController> {
  const PurchaseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PurchaseController());
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = !isMobile;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: _buildAppBar(isMobile),
      drawer: PurchaseDrawer(currentRoute: '/warehouse/purchase'),
      body: Obx(() {
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return _buildShimmer();
        }
        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 14),
                _buildPeriodChips(),
                const SizedBox(height: 16),
                _buildKpiGrid(isTablet),
                const SizedBox(height: 16),
                _buildFinancialOverview(),
                const SizedBox(height: 16),
                _buildSpendTrendCard(),
                const SizedBox(height: 16),
                _buildOrderStatusCard(),
                const SizedBox(height: 16),
                _buildPurchaseHealth(),
                const SizedBox(height: 16),
                _buildRecentActivity(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── AppBar (identical structure to DashboardScreen) ─────────────────────
  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: _kAppBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: _kCardBorder),
      ),
      leading: isMobile
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: _kTextPrimary,
                  size: 22,
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      titleSpacing: isMobile ? 0 : NavigationToolbar.kMiddleSpacing,
      title: Obx(() {
        final logo = controller.businessLogo.value;
        return Row(
          children: [
            logo.isNotEmpty
                ? Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: logo.startsWith('http')
                          ? Image.network(
                              logo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(logo),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                    ),
                  )
                : Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Purchase',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        );
      }),
      actions: [
        FiscalYearSelect(
          compact: true,
          showManageLink: !isMobile,
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: _kTextSub,
            size: 22,
          ),
          onPressed: () => Get.to(() => const NotificationScreen()),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Shimmer (identical pattern to DashboardScreen) ──────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEFF4),
      highlightColor: const Color(0xFFF8F9FC),
      period: const Duration(milliseconds: 1200),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(height: 180, radius: 18),
            const SizedBox(height: 14),
            Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _shimmerBox(
                    height: 34,
                    width: 80 + (i * 10).toDouble(),
                    radius: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (_, __) => _shimmerBox(radius: 14),
            ),
            const SizedBox(height: 16),
            _shimmerBox(height: 200, radius: 16),
            const SizedBox(height: 16),
            _shimmerBox(height: 220, radius: 16),
            const SizedBox(height: 16),
            _shimmerBox(height: 100, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({double? height, double? width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─── Hero Card (same structure as DashboardScreen hero) ──────────────────
  Widget _buildHeroCard() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;
      final logo = controller.businessLogo.value;
      final hasLogo = logo.isNotEmpty;

      final totalSpend = data?.invoices.totalSpend ?? 0.0;
      final outstanding = data?.invoices.outstanding ?? 0.0;
      final paidAmount = data?.invoices.paidAmount ?? 0.0;
      final totalOrders = data?.orders.total ?? 0;

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kHeroBg, _kHeroBgEnd],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kHeroBorder),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              if (hasLogo)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.07,
                      child: logo.startsWith('http')
                          ? Image.network(
                              logo,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            )
                          : Image.file(
                              File(logo),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _kPrimaryBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 14,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total Spend · ${controller.selectedTimePeriodLabel.value}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _kTextSub,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                fmt(totalSpend),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _kTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${fmt(paidAmount)} paid · ${fmt(outstanding)} outstanding',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTextSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _kPrimaryBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 10,
                                      color: kPrimary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$totalOrders purchase order${totalOrders == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ],
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
                              color: _kHeroIcon,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kHeroBorder),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: _kTextSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 0.5, color: _kCardBorder),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _heroStat(
                          'Orders',
                          '$totalOrders',
                          Icons.receipt_long_outlined,
                          kPrimary,
                          _kPrimaryBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Paid',
                          fmt(paidAmount),
                          Icons.check_circle_outline_rounded,
                          _kGreen,
                          _kGreenBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Outstanding',
                          fmt(outstanding),
                          Icons.schedule_rounded,
                          _kOrange,
                          _kOrangeBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _heroStat(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: _kTextMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() =>
      Container(width: 0.5, height: 44, color: _kCardBorder);

  // ─── Period Chips (identical to DashboardScreen) ──────────────────────────
  Widget _buildPeriodChips() {
    return Obx(() {
      final selected = controller.selectedTimePeriodLabel.value;
      return SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: PurchaseController.timePeriodLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final period = PurchaseController.timePeriodLabels[i];
            final isActive = period == selected;
            return GestureDetector(
              onTap: () => controller.selectTimePeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? kPrimary : _kChipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _kTextSub,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ─── KPI Grid (same card style as DashboardScreen _KpiCard) ──────────────
  Widget _buildKpiGrid(bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final kpis = [
        _KpiItem(
          label: 'Total Spend',
          value: fmt(data?.invoices.totalSpend ?? 0),
          icon: Icons.payments_outlined,
          iconBg: _kPrimaryBg,
          iconColor: kPrimary,
          trend: '${data?.orders.total ?? 0} orders',
          trendUp: true,
        ),
        _KpiItem(
          label: 'Amount Paid',
          value: fmt(data?.invoices.paidAmount ?? 0),
          icon: Icons.check_circle_outline_rounded,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: 'Settled',
          trendUp: true,
        ),
        _KpiItem(
          label: 'Outstanding',
          value: fmt(data?.invoices.outstanding ?? 0),
          icon: Icons.schedule_rounded,
          iconBg: _kOrangeBg,
          iconColor: _kOrange,
          trend: (data?.invoices.outstanding ?? 0) > 0 ? 'Pending' : 'Clear',
          trendUp: (data?.invoices.outstanding ?? 0) <= 0,
        ),
        _KpiItem(
          label: 'Returns',
          value: '${data?.returns.total ?? 0}',
          icon: Icons.assignment_return_outlined,
          iconBg: _kRedBg,
          iconColor: _kRed,
          trend: (data?.returns.total ?? 0) > 0 ? 'Active' : 'None',
          trendUp: (data?.returns.total ?? 0) == 0,
        ),
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kpis.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isTablet ? 1.2 : 1.55,
        ),
        itemBuilder: (_, i) => _KpiCard(item: kpis[i]),
      );
    });
  }

  // ─── Financial Overview bars (same as DashboardScreen _buildFinancialOverview)
  Widget _buildFinancialOverview() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final totalSpend = data?.invoices.totalSpend ?? 0.0;
      final paidAmount = data?.invoices.paidAmount ?? 0.0;
      final outstanding = data?.invoices.outstanding ?? 0.0;
      final returnsVal = (data?.returns.total ?? 0).toDouble();
      final approved = (data?.orders.approved ?? 0).toDouble();
      final totalOrders = (data?.orders.total ?? 0).toDouble();

      final maxVal = [
        totalSpend,
        paidAmount,
        outstanding,
        returnsVal,
        approved,
        totalOrders,
      ].fold<double>(0, (a, b) => b > a ? b : a);

      final bars = [
        _BarItem(
          'Total Spend',
          fmt(totalSpend),
          totalSpend,
          kPrimary,
          _kPrimaryBg,
          'Purchase invoices total',
        ),
        _BarItem(
          'Amount Paid',
          fmt(paidAmount),
          paidAmount,
          _kGreen,
          _kGreenBg,
          'Settled invoices',
        ),
        _BarItem(
          'Outstanding',
          fmt(outstanding),
          outstanding,
          _kOrange,
          _kOrangeBg,
          'Unpaid invoices',
        ),
        _BarItem(
          'Total Orders',
          '$totalOrders',
          totalOrders,
          _kPurple,
          _kPurpleBg,
          'All purchase orders',
        ),
        _BarItem(
          'Approved',
          '$approved',
          approved,
          _kTeal,
          _kTealBg,
          'Approved orders',
        ),
        _BarItem(
          'Returns',
          '$returnsVal',
          returnsVal,
          _kRed,
          _kRedBg,
          'Returned orders',
        ),
      ];

      return _SectionCard(
        title: 'Purchase overview',
        trailing: Text(
          controller.selectedTimePeriodLabel.value,
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: Column(children: bars.map((b) => _buildBar(b, maxVal)).toList()),
      );
    });
  }

  Widget _buildBar(_BarItem item, double maxVal) {
    final fraction = (maxVal > 0 && item.rawValue > 0)
        ? (item.rawValue / maxVal).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.circle, size: 8, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kTextSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.source.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              item.source,
                              style: const TextStyle(
                                fontSize: 9,
                                color: _kTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 5,
                    backgroundColor: _kCardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Spend Trend Chart (wrapped in SectionCard matching dashboard style) ──
  Widget _buildSpendTrendCard() {
    return Obx(() {
      final trend = controller.spendTrend;

      final List<double> invoiceData = [];
      final List<double> orderData = [];
      final List<String> labels = [];

      if (trend.isNotEmpty) {
        for (final p in trend) {
          invoiceData.add(p.invoiceAmount);
          orderData.add(p.orderValue);
          labels.add(p.label.isNotEmpty ? p.label : p.date.split('-').last);
        }
      } else {
        invoiceData.addAll([0, 0, 0, 0, 0, 0, 0]);
        orderData.addAll([0, 0, 0, 0, 0, 0, 0]);
        labels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
      }

      final maxA = invoiceData.isEmpty
          ? 0.0
          : invoiceData.reduce((a, b) => a > b ? a : b);
      final maxB = orderData.isEmpty
          ? 0.0
          : orderData.reduce((a, b) => a > b ? a : b);
      final maxY = (maxA > maxB ? maxA : maxB) * 1.2;

      return _SectionCard(
        title: 'Spend trend',
        trailing: Row(
          children: [
            _legendDot(_kPurple, 'Invoiced'),
            const SizedBox(width: 12),
            _legendDot(kPrimary, 'Ordered'),
          ],
        ),
        child: SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: _kCardBorder, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final lbl = v >= 1000
                          ? '${(v / 1000).toStringAsFixed(0)}k'
                          : v.toInt().toString();
                      return Text(
                        lbl,
                        style: const TextStyle(fontSize: 9, color: _kTextSub),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: labels.length > 6
                        ? (labels.length / 4).ceilToDouble()
                        : 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          labels[i],
                          style: const TextStyle(fontSize: 9, color: _kTextSub),
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
              minX: 0,
              maxX: (labels.length - 1).toDouble(),
              minY: 0,
              maxY: maxY > 0 ? maxY : 100,
              lineBarsData: [
                _buildLine(invoiceData, _kPurple),
                _buildLine(orderData, kPrimary),
              ],
            ),
          ),
        ),
      );
    });
  }

  LineChartBarData _buildLine(List<double> data, Color color) =>
      LineChartBarData(
        spots: data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) =>
              FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
          ),
        ),
      );

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _kTextSub)),
      ],
    );
  }

  // ─── Order Status Pie Chart ───────────────────────────────────────────────
  Widget _buildOrderStatusCard() {
    return Obx(() {
      final statuses = controller.orderStatuses
          .where((s) => s.count > 0)
          .toList();

      return _SectionCard(
        title: 'Orders by status',
        trailing: Text(
          '${statuses.fold(0, (s, e) => s + e.count)} total',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: SizedBox(
          height: 180,
          child: statuses.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections: statuses.asMap().entries.map((entry) {
                            Color color;
                            try {
                              color = Color(
                                int.parse(
                                  entry.value.color.replaceAll('#', '0xFF'),
                                ),
                              );
                            } catch (_) {
                              color = kPrimary;
                            }
                            return PieChartSectionData(
                              color: color,
                              value: entry.value.count.toDouble(),
                              title: '${entry.value.count}',
                              radius: 34,
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
                        children: statuses.take(6).map((s) {
                          Color color;
                          try {
                            color = Color(
                              int.parse(s.color.replaceAll('#', '0xFF')),
                            );
                          } catch (_) {
                            color = kPrimary;
                          }
                          final name = s.status.isNotEmpty
                              ? s.status[0].toUpperCase() +
                                    s.status.substring(1)
                              : 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _kTextSub,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${s.count}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
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
                      const Icon(
                        Icons.pie_chart_outline,
                        size: 32,
                        color: _kTextMuted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No order data available',
                        style: TextStyle(fontSize: 12, color: _kTextSub),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  // ─── Purchase Health (bar rows, same style as _buildKpiSources) ──────────
  Widget _buildPurchaseHealth() {
    return Obx(() {
      final data = controller.dashboard.value;

      final items = [
        (
          'Approved Orders',
          data?.orders.approved ?? 0,
          Icons.thumb_up_outlined,
          _kGreen,
          _kGreenBg,
        ),
        (
          'Received Orders',
          data?.orders.received ?? 0,
          Icons.inventory_2_outlined,
          _kTeal,
          _kTealBg,
        ),
        (
          'Returns',
          data?.returns.total ?? 0,
          Icons.assignment_return_outlined,
          _kOrange,
          _kOrangeBg,
        ),
        (
          'Cancelled',
          data?.orders.cancelled ?? 0,
          Icons.cancel_outlined,
          _kRed,
          _kRedBg,
        ),
      ];

      final total = items.fold<int>(0, (s, i) => s + i.$2);

      return _SectionCard(
        title: 'Purchase health',
        trailing: total > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total orders',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              )
            : null,
        child: Column(
          children: [
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: items
                      .where((i) => i.$2 > 0)
                      .map(
                        (item) => Expanded(
                          flex: item.$2,
                          child: Container(height: 5, color: item.$4),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item = e.value;
              final hasCount = item.$2 > 0;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: hasCount ? item.$5 : _kCardBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.$3,
                            size: 14,
                            color: hasCount ? item.$4 : _kTextMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hasCount
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: hasCount ? _kTextPrimary : _kTextSub,
                            ),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: hasCount ? item.$5 : _kCardBorder,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.$2}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: hasCount ? item.$4 : _kTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: _kCardBorder,
                    ),
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  // ─── Recent Activity (same transaction tile style as DashboardScreen) ─────
  Widget _buildRecentActivity() {
    return Obx(() {
      final shown = controller.activities.length > 5
          ? controller.activities.sublist(0, 5)
          : controller.activities.toList();

      if (shown.isEmpty) return const SizedBox.shrink();

      return _SectionCard(
        title: 'Recent activity',
        child: Column(
          children: shown.asMap().entries.map((e) {
            final activity = e.value;
            final isLast = e.key == shown.length - 1;

            Color color;
            IconData icon;
            switch (activity.type) {
              case 'invoice':
                color = _kPurple;
                icon = Icons.description_outlined;
                break;
              case 'return':
                color = _kOrange;
                icon = Icons.assignment_return_outlined;
                break;
              case 'payment':
                color = _kGreen;
                icon = Icons.payments_outlined;
                break;
              default:
                color = kPrimary;
                icon = Icons.receipt_long_outlined;
            }

            final date = DateTime.tryParse(activity.createdAt);
            final diff = date != null
                ? DateTime.now().difference(date)
                : Duration.zero;
            String timeAgo;
            if (date == null) {
              timeAgo = '';
            } else if (diff.inDays > 7) {
              timeAgo = '${date.day}/${date.month}';
            } else if (diff.inDays > 0) {
              timeAgo = '${diff.inDays}d ago';
            } else if (diff.inHours > 0) {
              timeAgo = '${diff.inHours}h ago';
            } else if (diff.inMinutes > 0) {
              timeAgo = '${diff.inMinutes}m ago';
            } else {
              timeAgo = 'Just now';
            }

            final bg = activity.type == 'invoice'
                ? _kPurpleBg
                : activity.type == 'return'
                ? _kOrangeBg
                : activity.type == 'payment'
                ? _kGreenBg
                : _kPrimaryBg;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.action,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (activity.details.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                activity.details,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              activity.type[0].toUpperCase() +
                                  activity.type.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 0.5, color: _kCardBorder),
              ],
            );
          }).toList(),
        ),
      );
    });
  }

  // ─── Quick Actions (same 4-icon row as DashboardScreen) ──────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        'New Order',
        Icons.add_circle_outline_rounded,
        kPrimary,
        _kPrimaryBg,
        () => Get.toNamed('/purchase-order'),
      ),
      _QuickAction(
        'Receive',
        Icons.inventory_2_outlined,
        _kGreen,
        _kGreenBg,
        () => Get.toNamed('/purchase/goods-receiving'),
      ),
      _QuickAction(
        'Invoice',
        Icons.receipt_long_outlined,
        _kPurple,
        _kPurpleBg,
        () => Get.toNamed('/purchase/invoices'),
      ),
      _QuickAction(
        'Reports',
        Icons.assessment_outlined,
        _kOrange,
        _kOrangeBg,
        () => Get.toNamed('/purchase/reports'),
      ),
    ];

    return _SectionCard(
      title: 'Quick actions',
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: a.onTap,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: a.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(a.icon, size: 22, color: a.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
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
}

// ─── Section Card wrapper (identical to DashboardScreen) ──────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── KPI Card (identical to DashboardScreen _KpiCard) ─────────────────────
class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String trend;
  final bool trendUp;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.trend,
    required this.trendUp,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 17, color: item.iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.trendUp ? _kGreenBg : _kRedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.trendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 9,
                      color: item.trendUp ? _kGreen : _kRed,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.trend,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: item.trendUp ? _kGreen : _kRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _kTextSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bar Item model ────────────────────────────────────────────────────────
class _BarItem {
  final String label;
  final String value;
  final double rawValue;
  final Color color;
  final Color bgColor;
  final String source;

  const _BarItem(
    this.label,
    this.value,
    this.rawValue,
    this.color,
    this.bgColor, [
    this.source = '',
  ]);
}

// ─── Quick Action model ────────────────────────────────────────────────────
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.color, this.bg, this.onTap);
}
