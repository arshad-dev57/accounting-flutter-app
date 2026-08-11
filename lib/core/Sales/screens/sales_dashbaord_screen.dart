import 'dart:io';

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/Notifications/screens/notification_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/sales/controller/sales_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/sales/model/sales_dashboard_model.dart';
import 'package:BisonsTechs_app/widgets/sales_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFEEEFF4);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF8A8FA8);
const _kTextMuted = Color(0xFFB0B4C8);
const _kAppBarBg = Color(0xFFF7F9FC);
const _kChipBg = Color(0xFFF0F2F8);

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

class SalesDashboardScreen extends GetView<SalesController> {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SalesController());
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: _buildAppBar(isMobile),
      drawer: isMobile
          ? const SalesDrawer(currentRoute: '/warehouse/sales')
          : null,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer();
        }
        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: controller.fetchDashboard,
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
                if (PermissionService.to.isAdmin ||
                    PermissionService.to.hasSubPageAccess('sales', 'credits')) ...[
                  const SizedBox(height: 16),
                  _buildCreditsStrip(),
                ],
                const SizedBox(height: 16),
                _buildFinancialOverview(),
                const SizedBox(height: 16),
                _buildRevenueTrendCard(),
                const SizedBox(height: 16),
                _buildOrderStatusCard(),
                const SizedBox(height: 16),
                _buildComparisonCards(isTablet),
                const SizedBox(height: 16),
                _buildTopProductsAndCustomers(isTablet),
                const SizedBox(height: 16),
                _buildRecentActivity(),
                const SizedBox(height: 16),
                _buildRevenueBreakdown(),
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
      title: Obx(() {
        final logo = controller.businessLogo.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
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
                                    Icons.trending_up_rounded,
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
                                    Icons.trending_up_rounded,
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
                      Icons.trending_up_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
            const SizedBox(width: 8),
            const Text(
              'Sales',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: _kTextSub,
            size: 22,
          ),
          onPressed: () => Get.to(() => const NotificationScreen()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Shimmer ──────────────────────────────────────────────────────────────
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
            _shimmerBox(height: 220, radius: 16),
            const SizedBox(height: 16),
            _shimmerBox(height: 220, radius: 16),
            const SizedBox(height: 16),
            _shimmerBox(height: 200, radius: 16),
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

  // ─── Hero Card ────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;
      final logo = controller.businessLogo.value;
      final hasLogo = logo.isNotEmpty;

      final todayOrders = data?.orders.todayCount ?? 0;
      final todayRevenue = data?.orders.todayRevenue ?? 0.0;
      final pending = data?.orders.pendingCount ?? 0;
      final totalRevenue = data?.orders.revenue ?? 0.0;

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
                                      Icons.trending_up_rounded,
                                      size: 14,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sales Revenue · ${controller.selectedTimePeriodLabel.value}',
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
                                fmt(totalRevenue),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _kTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Today: ${fmt(todayRevenue)}  ·  Pending: $pending orders',
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
                                  color: _kGreenBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 10,
                                      color: _kGreen,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$todayOrders order${todayOrders == 1 ? '' : 's'} today',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.fetchDashboard,
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
                          'Revenue',
                          fmt(totalRevenue),
                          Icons.trending_up_rounded,
                          _kGreen,
                          _kGreenBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Collected',
                          fmt(data?.invoices.paidAmount ?? 0),
                          Icons.payments_outlined,
                          kPrimary,
                          _kPrimaryBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Outstanding',
                          fmt(data?.invoices.outstanding ?? 0),
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

  // ─── Period Chips ─────────────────────────────────────────────────────────
  Widget _buildPeriodChips() {
    return Obx(() {
      final selected = controller.selectedTimePeriodLabel.value;
      return SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: SalesController.timePeriodLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final period = SalesController.timePeriodLabels[i];
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

  // ─── KPI Grid ─────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final kpis = [
        _KpiItem(
          label: 'POS Revenue',
          value: fmt(data?.pos.revenue ?? 0),
          icon: Icons.point_of_sale_outlined,
          iconBg: _kOrangeBg,
          iconColor: _kOrange,
          trend: '${data?.pos.todayCount ?? 0} today',
          trendUp: true,
        ),
        _KpiItem(
          label: 'Order Revenue',
          value: fmt(data?.orders.revenue ?? 0),
          icon: Icons.shopping_cart_outlined,
          iconBg: _kPrimaryBg,
          iconColor: kPrimary,
          trend: data?.orders.revenueGrowth ?? '0%',
          trendUp: (data?.orders.revenueGrowth ?? '').startsWith('+'),
        ),
        _KpiItem(
          label: 'Invoice Total',
          value: fmt(data?.invoices.grandTotal ?? 0),
          icon: Icons.receipt_long_outlined,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: data?.invoices.grandTotalGrowth ?? '0%',
          trendUp: (data?.invoices.grandTotalGrowth ?? '').startsWith('+'),
        ),
        _KpiItem(
          label: 'Collected',
          value: fmt(data?.invoices.paidAmount ?? 0),
          icon: Icons.payments_outlined,
          iconBg: _kTealBg,
          iconColor: _kTeal,
          trend: data?.invoices.paidAmountGrowth ?? '0%',
          trendUp: (data?.invoices.paidAmountGrowth ?? '').startsWith('+'),
        ),
      ];

      // 5th KPI for credits when present — keep 4-col grid; strip below shows detail
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

  Widget _buildCreditsStrip() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;
      final amount = data?.creditAmount ?? 0;
      final remaining = data?.creditRemaining ?? 0;
      final count = data?.creditCount ?? 0;

      return GestureDetector(
        onTap: () => Get.toNamed('/sales/credits'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPurpleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: _kPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Credits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'Credit notes · posts to AR & GL'
                          : '$count notes · ${fmt(amount)} issued',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(remaining),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kPurple,
                    ),
                  ),
                  const Text(
                    'Unapplied',
                    style: TextStyle(
                      fontSize: 10,
                      color: _kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _kTextMuted),
            ],
          ),
        ),
      );
    });
  }

  // ─── Financial Overview bars ───────────────────────────────────────────────
  Widget _buildFinancialOverview() {
    return Obx(() {
      final data = controller.dashboard.value;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final revenue = data?.orders.revenue ?? 0.0;
      final posRevenue = data?.pos.revenue ?? 0.0;
      final invoiceTotal = data?.invoices.grandTotal ?? 0.0;
      final collected = data?.invoices.paidAmount ?? 0.0;
      final outstanding = data?.invoices.outstanding ?? 0.0;
      final credits = data?.creditAmount ?? 0.0;
      final todayPos = data?.pos.todayRevenue ?? 0.0;
      final posCount = (data?.pos.count ?? 0).toDouble();

      final maxVal = [
        posRevenue,
        revenue,
        invoiceTotal,
        collected,
        outstanding,
        credits,
        todayPos,
        posCount,
      ].fold<double>(0, (a, b) => b > a ? b : a);

      final bars = [
        _BarItem(
          'POS Revenue',
          fmt(posRevenue),
          posRevenue,
          _kOrange,
          _kOrangeBg,
          '${data?.pos.count ?? 0} completed POS sales',
        ),
        _BarItem(
          'Order Revenue',
          fmt(revenue),
          revenue,
          kPrimary,
          _kPrimaryBg,
          'Sales orders revenue',
        ),
        _BarItem(
          'Invoice Total',
          fmt(invoiceTotal),
          invoiceTotal,
          _kGreen,
          _kGreenBg,
          'All invoices generated',
        ),
        _BarItem(
          'Collected',
          fmt(collected),
          collected,
          _kTeal,
          _kTealBg,
          'Paid invoices amount',
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
          'Sales Credits',
          fmt(credits),
          credits,
          _kPurple,
          _kPurpleBg,
          'Credit notes issued (AR / GL)',
        ),
        _BarItem(
          'POS Today',
          fmt(todayPos),
          todayPos,
          _kTeal,
          _kTealBg,
          '${data?.pos.todayCount ?? 0} sales today',
        ),
        _BarItem(
          'POS Sales',
          '${data?.pos.count ?? 0}',
          posCount,
          _kRed,
          _kRedBg,
          'POS transactions in period',
        ),
      ];

      return _SectionCard(
        title: 'Sales overview',
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

  // ─── Revenue Trend Chart ──────────────────────────────────────────────────
  Widget _buildRevenueTrendCard() {
    return Obx(() {
      final data = controller.dashboard.value;
      final invoiceTrend = data?.invoices.trend ?? [];
      final orderTrend = data?.orders.trend ?? [];
      final posTrend = data?.pos.trend ?? [];

      final allDates = <String>{};
      for (final p in invoiceTrend) allDates.add(p.date);
      for (final p in orderTrend) allDates.add(p.date);
      for (final p in posTrend) allDates.add(p.date);
      final sorted = allDates.toList()..sort();

      final invoiceSpots = <FlSpot>[];
      final orderSpots = <FlSpot>[];
      final posSpots = <FlSpot>[];
      for (var i = 0; i < sorted.length; i++) {
        final d = sorted[i];
        final inv = invoiceTrend.firstWhere(
          (p) => p.date == d,
          orElse: () => SalesTrendPoint(date: d),
        );
        final ord = orderTrend.firstWhere(
          (p) => p.date == d,
          orElse: () => SalesTrendPoint(date: d),
        );
        final pos = posTrend.firstWhere(
          (p) => p.date == d,
          orElse: () => SalesTrendPoint(date: d),
        );
        invoiceSpots.add(FlSpot(i.toDouble(), inv.revenue));
        orderSpots.add(FlSpot(i.toDouble(), ord.orderRevenue));
        posSpots.add(FlSpot(i.toDouble(), pos.revenue));
      }

      final maxY = [
        ...invoiceSpots.map((s) => s.y),
        ...orderSpots.map((s) => s.y),
        ...posSpots.map((s) => s.y),
      ].fold<double>(0, (a, b) => b > a ? b : a);

      // Fallback empty data
      if (sorted.isEmpty) {
        for (var i = 0; i < 7; i++) {
          invoiceSpots.add(FlSpot(i.toDouble(), 0));
          orderSpots.add(FlSpot(i.toDouble(), 0));
          posSpots.add(FlSpot(i.toDouble(), 0));
          sorted.add('--');
        }
      }

      return _SectionCard(
        title: 'Revenue trend',
        trailing: Row(
          children: [
            _legendDot(_kOrange, 'POS'),
            const SizedBox(width: 12),
            _legendDot(_kTeal, 'Invoices'),
            const SizedBox(width: 12),
            _legendDot(kPrimary, 'Orders'),
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
                    interval: sorted.length > 6
                        ? (sorted.length / 4).ceilToDouble()
                        : 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= sorted.length) return const SizedBox();
                      final parts = sorted[i].split('-');
                      final lbl = parts.length >= 3
                          ? '${parts[2]}/${parts[1]}'
                          : sorted[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          lbl,
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
              maxX: (sorted.length - 1).toDouble(),
              minY: 0,
              maxY: maxY > 0 ? maxY * 1.2 : 100,
              lineBarsData: [
                _buildLine(posSpots, _kOrange),
                _buildLine(invoiceSpots, _kTeal),
                _buildLine(orderSpots, kPrimary),
              ],
            ),
          ),
        ),
      );
    });
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
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

  Widget _legendDot(Color color, String label) => Row(
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

  // ─── Order Status Bar Chart ───────────────────────────────────────────────
  Widget _buildOrderStatusCard() {
    return Obx(() {
      final data = controller.dashboard.value;
      final items = (data?.orders.byStatus ?? [])
          .where((s) => s.count > 0)
          .toList();

      final accent = [kPrimary, _kGreen, _kOrange, _kPurple, _kRed, _kTeal];

      return _SectionCard(
        title: 'Orders by status',
        trailing: Text(
          '${items.fold(0, (s, e) => s + e.count)} total',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: items.isEmpty
            ? const _EmptyPlaceholder(label: 'No orders for this period')
            : SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        items
                            .map((e) => e.count.toDouble())
                            .reduce((a, b) => a > b ? a : b) *
                        1.25,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: _kCardBorder, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: _kTextSub,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= items.length)
                              return const SizedBox.shrink();
                            final s = items[i].status;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                s.length > 8 ? s.substring(0, 7) : s,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _kTextSub,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(items.length, (i) {
                      final color = accent[i % accent.length];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: items[i].count.toDouble(),
                            color: color,
                            width: 20,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
      );
    });
  }

  // ─── Comparison Cards ────────────────────────────────────────────────────
  Widget _buildComparisonCards(bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final comparison = data?.comparison;
      final fmt = Get.find<CurrencyController>().formatAmount;

      final cards = [
        _ComparisonData(
          'Today',
          'vs Yesterday',
          fmt(comparison?.today.currentSales ?? 0),
          fmt(comparison?.today.currentReturns ?? 0),
          comparison?.today.salesChangePercent ?? 0,
          comparison?.today.returnsChangePercent ?? 0,
        ),
        _ComparisonData(
          'This Week',
          'vs Last Week',
          fmt(comparison?.week.currentSales ?? 0),
          fmt(comparison?.week.currentReturns ?? 0),
          comparison?.week.salesChangePercent ?? 0,
          comparison?.week.returnsChangePercent ?? 0,
        ),
        _ComparisonData(
          'This Month',
          'vs Last Month',
          fmt(comparison?.month.currentSales ?? 0),
          fmt(comparison?.month.currentReturns ?? 0),
          comparison?.month.salesChangePercent ?? 0,
          comparison?.month.returnsChangePercent ?? 0,
        ),
        _ComparisonData(
          'This Year',
          'vs Last Year',
          fmt(comparison?.year.currentSales ?? 0),
          fmt(comparison?.year.currentReturns ?? 0),
          comparison?.year.salesChangePercent ?? 0,
          comparison?.year.returnsChangePercent ?? 0,
        ),
      ];

      if (isTablet) {
        return Row(
          children: cards
              .asMap()
              .entries
              .map(
                (e) => [
                  if (e.key > 0) const SizedBox(width: 10),
                  Expanded(child: _ComparisonCard(data: e.value)),
                ],
              )
              .expand((w) => w)
              .toList(),
        );
      }

      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _ComparisonCard(data: cards[0])),
              const SizedBox(width: 10),
              Expanded(child: _ComparisonCard(data: cards[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ComparisonCard(data: cards[2])),
              const SizedBox(width: 10),
              Expanded(child: _ComparisonCard(data: cards[3])),
            ],
          ),
        ],
      );
    });
  }

  // ─── Top Products & Customers ─────────────────────────────────────────────
  Widget _buildTopProductsAndCustomers(bool isTablet) {
    return Obx(() {
      final data = controller.dashboard.value;
      final topProducts = data?.topProducts ?? [];
      final topCustomers = data?.topCustomers ?? [];
      final fmt = Get.find<CurrencyController>().formatAmount;

      final productsCard = _SectionCard(
        title: 'Top products',
        trailing: Text(
          '${topProducts.length} items',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: topProducts.isEmpty
            ? const _EmptyPlaceholder(label: 'No products')
            : Column(
                children: topProducts.take(5).toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final product = e.value;
                  final isLast = idx == topProducts.take(5).length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _kPrimaryBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${product.quantitySold} sold',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              fmt(product.revenue),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
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
                }).toList(),
              ),
      );

      final customersCard = _SectionCard(
        title: 'Top customers',
        trailing: Text(
          '${topCustomers.length} total',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: topCustomers.isEmpty
            ? const _EmptyPlaceholder(label: 'No customers')
            : Column(
                children: topCustomers.take(5).toList().asMap().entries.map((
                  e,
                ) {
                  final idx = e.key;
                  final customer = e.value;
                  final isLast = idx == topCustomers.take(5).length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _kGreenBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _kGreen,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${customer.orderCount} orders',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              fmt(customer.totalSpent),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
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
                }).toList(),
              ),
      );

      if (isTablet) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: productsCard),
            const SizedBox(width: 12),
            Expanded(child: customersCard),
          ],
        );
      }

      return Column(
        children: [productsCard, const SizedBox(height: 12), customersCard],
      );
    });
  }

  // ─── Recent Activity ──────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Obx(() {
      final data = controller.dashboard.value;
      final activities = (data?.recentActivity ?? []).take(5).toList();

      if (activities.isEmpty) return const SizedBox.shrink();

      return _SectionCard(
        title: 'Recent activity',
        child: Column(
          children: activities.asMap().entries.map((e) {
            final idx = e.key;
            final activity = e.value;
            final isLast = idx == activities.length - 1;

            Color color;
            IconData icon;
            Color bg;
            switch (activity.type.toLowerCase()) {
              case 'invoice':
                color = _kTeal;
                icon = Icons.receipt_long_outlined;
                bg = _kTealBg;
                break;
              case 'payment':
                color = _kGreen;
                icon = Icons.payments_outlined;
                bg = _kGreenBg;
                break;
              case 'return':
                color = _kOrange;
                icon = Icons.assignment_return_outlined;
                bg = _kOrangeBg;
                break;
              default:
                color = kPrimary;
                icon = Icons.shopping_cart_outlined;
                bg = _kPrimaryBg;
            }

            final fmt = Get.find<CurrencyController>().formatAmount;

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
                              activity.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.timestamp,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (activity.amount != null)
                            Text(
                              fmt(activity.amount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
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

  // ─── Revenue Breakdown ────────────────────────────────────────────────────
  Widget _buildRevenueBreakdown() {
    return Obx(() {
      final data = controller.dashboard.value;
      final items = data?.revenueBreakdown?.items ?? [];

      if (items.isEmpty) return const SizedBox.shrink();

      final accent = [kPrimary, _kGreen, _kOrange, _kPurple, _kTeal, _kRed];

      return _SectionCard(
        title: 'Revenue breakdown',
        child: Column(
          children: items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final color = accent[idx % accent.length];
            final fmt = Get.find<CurrencyController>().formatAmount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.circle, size: 8, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
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
                                color: _kTextSub,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  fmt(item.amount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (item.percentage / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: _kCardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        'New Order',
        Icons.add_shopping_cart_outlined,
        kPrimary,
        _kPrimaryBg,
        () => Get.toNamed('/sales/orders'),
      ),
      _QuickAction(
        'New Invoice',
        Icons.receipt_long_outlined,
        _kGreen,
        _kGreenBg,
        () => Get.toNamed('/sales-invoices'),
      ),
      _QuickAction(
        'Reports',
        Icons.assessment_outlined,
        _kPurple,
        _kPurpleBg,
        () => Get.toNamed('/sales/reports'),
      ),
      _QuickAction(
        'Customers',
        Icons.people_outline_rounded,
        _kOrange,
        _kOrangeBg,
        () => Get.toNamed('/sales/warehouse-customers'),
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

// ─── Section Card (identical to DashboardScreen) ──────────────────────────
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
  final String label, value, trend;
  final IconData icon;
  final Color iconBg, iconColor;
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
  final String label, value, source;
  final double rawValue;
  final Color color, bgColor;
  const _BarItem(
    this.label,
    this.value,
    this.rawValue,
    this.color,
    this.bgColor, [
    this.source = '',
  ]);
}

// ─── Comparison Card ──────────────────────────────────────────────────────
class _ComparisonData {
  final String period, subLabel, sales, returns;
  final double salesChange, returnsChange;
  const _ComparisonData(
    this.period,
    this.subLabel,
    this.sales,
    this.returns,
    this.salesChange,
    this.returnsChange,
  );
}

class _ComparisonCard extends StatelessWidget {
  final _ComparisonData data;
  const _ComparisonCard({required this.data});

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
        children: [
          Text(
            data.period,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          Text(
            data.subLabel,
            style: const TextStyle(fontSize: 9, color: _kTextMuted),
          ),
          const SizedBox(height: 10),
          Container(height: 0.5, color: _kCardBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales',
                      style: TextStyle(fontSize: 9, color: _kTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.sales,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _ChangeBadge(percent: data.salesChange),
                  ],
                ),
              ),
              Container(width: 0.5, height: 44, color: _kCardBorder),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Returns',
                      style: TextStyle(fontSize: 9, color: _kTextMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.returns,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _ChangeBadge(percent: data.returnsChange),
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
    final up = percent >= 0;
    final color = up ? _kGreen : _kRed;
    final bg = up ? _kGreenBg : _kRedBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
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

// ─── Quick Action model ────────────────────────────────────────────────────
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.bg, this.onTap);
}

// ─── Empty placeholder ─────────────────────────────────────────────────────
class _EmptyPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 32, color: _kTextMuted),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: _kTextSub)),
          ],
        ),
      ),
    );
  }
}
