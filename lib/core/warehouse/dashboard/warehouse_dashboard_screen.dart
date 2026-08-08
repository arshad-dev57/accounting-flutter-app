import 'dart:io';
import 'dart:convert';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/Notifications/screens/notification_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/dashboard/warehouse_dashboard_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/widgets/drawer_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFEEEFF4);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF8A8FA8);
const _kTextMuted = Color(0xFFB0B4C8);
const _kAppBarBg = Color(0xFFF7F9FC);
const _kChipBg = Color(0xFFF0F2F8);

// Semantic colours
const _kGreen = Color(0xFF22A869);
const _kGreenBg = Color(0xFFEAF7F1);
const _kOrange = Color(0xFFF59E0B);
const _kOrangeBg = Color(0xFFFFF8E7);
const _kRed = Color(0xFFEF4444);
const _kRedBg = Color(0xFFFEF2F2);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F0FF);

// Hero (light tint of kPrimary #014582)
const _kHeroBg = Color(0xFFE6EEF5);
const _kHeroBgEnd = Color(0xFFD6E4F0);
const _kHeroBorder = Color(0xFFB8CFE0);
const _kHeroIcon = Color(0xFFC5D8E8);
const _kPrimaryBg = Color(0xFFE6EEF5);

// ─── Root widget ──────────────────────────────────────────────────────────
class WarehouseDashboard extends StatefulWidget {
  const WarehouseDashboard({super.key});

  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WarehouseDashboardController _controller;

  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];
  
  String _businessLogo = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.put(WarehouseDashboardController());
    _loadBusinessLogo();
  }
  
  Future<void> _loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails = userData['businessDetails'] as Map<String, dynamic>?;
        
        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            setState(() {
              _businessLogo = logo;
            });
            print('✅ [WarehouseDashboard] Business logo loaded: $logo');
          }
        }
      }
    } catch (e) {
      print('❌ [WarehouseDashboard] Error loading business logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,
      drawer: const WarehouseDrawer(),
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return _buildShimmer();
        }
        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: _controller.refreshDashboard,
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
                _buildStockOverview(),
                const SizedBox(height: 16),
                _buildStockTrendCard(),
                const SizedBox(height: 16),
                _buildCategoryDistributionCard(),
                const SizedBox(height: 16),
                _buildStockHealthCard(),
                const SizedBox(height: 16),
                _buildRecentActivities(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kAppBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: _kCardBorder),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: _kTextPrimary, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _businessLogo.isNotEmpty
              ? Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _businessLogo.startsWith('http')
                        ? Image.network(
                            _businessLogo,
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
                                  Icons.warehouse_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(_businessLogo),
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
                                  Icons.warehouse_rounded,
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
                    Icons.warehouse_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(width: 8),
          const Text(
            'Inventory',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
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

  // ─── Shimmer Loading ──────────────────────────────────────────────────────
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
                    width: 80.0 + i * 10,
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
            _shimmerBox(height: 180, radius: 16),
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
    return _HeroCardWrapper(controller: _controller, selectedPeriod: _selectedPeriod);
  }

  // ─── Period Chips ─────────────────────────────────────────────────────────
  Widget _buildPeriodChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length + 1, // +1 for custom
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i < _periods.length) {
            final period = _periods[i];
            final isActive = period == _selectedPeriod;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _controller.applyPeriodFilter(
                  period.toLowerCase().replaceAll(' ', '_'),
                );
              },
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
          }
          // Custom date button
          final isActive = _selectedPeriod == 'Custom';
          return GestureDetector(
            onTap: () => _pickCustomDateRange(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? kPrimary : _kChipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 13,
                    color: isActive ? Colors.white : _kTextSub,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _kTextSub,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedPeriod = 'Custom');
      _controller.applyPeriodFilter(
        'custom',
        start: picked.start,
        end: picked.end,
      );
    }
  }

  // ─── KPI Grid ─────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(bool isTablet) {
    return Obx(() {
      final kpis = [
        _KpiItem(
          label: 'Total Products',
          value: '${_controller.totalProducts.value}',
          icon: Icons.inventory_2_outlined,
          iconBg: _kPrimaryBg,
          iconColor: kPrimary,
          trend: '+12%',
          trendUp: true,
        ),
        _KpiItem(
          label: 'Stock Value',
          value: _controller.formatCurrency(_controller.totalStockValue.value),
          icon: Icons.account_balance_wallet_outlined,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: '+8.3%',
          trendUp: true,
        ),
        _KpiItem(
          label: 'Low Stock',
          value: '${_controller.lowStockCount.value}',
          icon: Icons.warning_amber_rounded,
          iconBg: _kOrangeBg,
          iconColor: _kOrange,
          trend: _controller.lowStockCount.value > 0 ? 'Alert' : 'Clear',
          trendUp: _controller.lowStockCount.value == 0,
        ),
        _KpiItem(
          label: "Today's Movements",
          value:
              '${_controller.todayStockIn.value + _controller.todayStockOut.value}',
          icon: Icons.sync_alt_rounded,
          iconBg: _kPurpleBg,
          iconColor: _kPurple,
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
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isTablet ? 1.2 : 1.55,
        ),
        itemBuilder: (_, i) => _KpiCard(item: kpis[i]),
      );
    });
  }

  // ─── Stock Overview (bar-based, mirrors Financial Overview) ───────────────
  Widget _buildStockOverview() {
    return Obx(() {
      final bars = [
        _BarItem(
          'Total Products',
          '${_controller.totalProducts.value}',
          _controller.totalProducts.value.toDouble(),
          kPrimary,
          _kPrimaryBg,
          'All active inventory items',
        ),
        _BarItem(
          'In Stock',
          '${_controller.totalProducts.value - _controller.outOfStockCount.value}',
          (_controller.totalProducts.value - _controller.outOfStockCount.value)
              .toDouble(),
          _kGreen,
          _kGreenBg,
          'Items with available quantity',
        ),
        _BarItem(
          'Low Stock',
          '${_controller.lowStockCount.value}',
          _controller.lowStockCount.value.toDouble(),
          _kOrange,
          _kOrangeBg,
          'Below minimum threshold',
        ),
        _BarItem(
          'Out of Stock',
          '${_controller.outOfStockCount.value}',
          _controller.outOfStockCount.value.toDouble(),
          _kRed,
          _kRedBg,
          'Zero quantity items',
        ),
        _BarItem(
          'Overstock',
          '${_controller.overstockCount.value}',
          _controller.overstockCount.value.toDouble(),
          _kPurple,
          _kPurpleBg,
          'Above maximum threshold',
        ),
        _BarItem(
          'Expiring Soon',
          '${_controller.expiringCount.value}',
          _controller.expiringCount.value.toDouble(),
          _kRed,
          _kRedBg,
          'Expiry within 30 days',
        ),
      ];

      final maxVal = bars.fold<double>(
        0,
        (a, b) => b.rawValue > a ? b.rawValue : a,
      );

      return _SectionCard(
        title: 'Stock overview',
        trailing: Text(
          _selectedPeriod,
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

  // ─── Stock Trend Chart ────────────────────────────────────────────────────
  Widget _buildStockTrendCard() {
    final chartData = _controller.stockMovementChart;

    final List<double> inData = [];
    final List<double> outData = [];
    final List<String> labels = [];

    if (chartData.isNotEmpty) {
      for (final item in chartData) {
        inData.add((item['stockIn'] ?? 0).toDouble());
        outData.add((item['stockOut'] ?? 0).toDouble());
        labels.add(item['label'] ?? '');
      }
    } else {
      inData.addAll(List.filled(7, 0));
      outData.addAll(List.filled(7, 0));
      labels.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
    }

    final maxA = inData.isEmpty ? 0.0 : inData.reduce((a, b) => a > b ? a : b);
    final maxB = outData.isEmpty
        ? 0.0
        : outData.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxA > maxB ? maxA : maxB) * 1.2).clamp(
      10.0,
      double.infinity,
    );

    return _SectionCard(
      title: 'Stock movement trend',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(_kGreen, 'In'),
          const SizedBox(width: 12),
          _legendDot(_kRed, 'Out'),
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
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: _kTextSub),
                  ),
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
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => _kTextPrimary,
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        s.y.toStringAsFixed(0),
                        TextStyle(
                          color: s.barIndex == 0 ? _kGreen : _kRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            minX: 0,
            maxX: (labels.length - 1).toDouble().clamp(1, 100),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              _buildTrendLine(inData, _kGreen),
              _buildTrendLine(outData, _kRed),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildTrendLine(List<double> data, Color color) {
    return LineChartBarData(
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
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  // ─── Category Distribution ────────────────────────────────────────────────
  Widget _buildCategoryDistributionCard() {
    final categories = _controller.categoryDistribution;
    final hasData =
        categories.isNotEmpty &&
        categories.any((c) => (c['productCount'] ?? 0) > 0);

    const palette = [
      kPrimary,
      _kPurple,
      _kOrange,
      _kGreen,
      _kRed,
      Color(0xFF0891B2),
      Color(0xFFEC4899),
    ];

    return _SectionCard(
      title: 'Category distribution',
      trailing: Text(
        hasData ? '${categories.length} categories' : 'No data',
        style: const TextStyle(fontSize: 12, color: _kTextSub),
      ),
      child: SizedBox(
        height: 180,
        child: hasData
            ? Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 38,
                        sections: categories
                            .take(7)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                              final value = (entry.value['productCount'] ?? 0)
                                  .toDouble();
                              final color = palette[entry.key % palette.length];
                              return PieChartSectionData(
                                color: color,
                                value: value,
                                title: '${value.toInt()}',
                                radius: 34,
                                titleStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.take(6).toList().asMap().entries.map(
                        (entry) {
                          final c = entry.value;
                          final color = palette[entry.key % palette.length];
                          final name =
                              c['categoryName']?.toString() ?? 'Unknown';
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
                                  '${c['productCount'] ?? 0}',
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
                      ).toList(),
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
                      color: _kTextMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No category data available',
                      style: TextStyle(fontSize: 12, color: _kTextSub),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Stock Health ─────────────────────────────────────────────────────────
  Widget _buildStockHealthCard() {
    return Obx(() {
      final items = [
        _HealthEntry(
          'Low Stock',
          _controller.lowStockCount.value,
          Icons.warning_amber_rounded,
          _kOrange,
        ),
        _HealthEntry(
          'Out of Stock',
          _controller.outOfStockCount.value,
          Icons.block,
          _kRed,
        ),
        _HealthEntry(
          'Expiring Soon',
          _controller.expiringCount.value,
          Icons.event_outlined,
          _kRed,
        ),
        _HealthEntry(
          'Overstock',
          _controller.overstockCount.value,
          Icons.inventory_rounded,
          _kPurple,
        ),
      ];

      final total = items.fold<int>(0, (s, i) => s + i.count);

      return _SectionCard(
        title: 'Stock health',
        trailing: total > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kRedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRed.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 10,
                      color: _kRed,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$total alerts',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        child: Column(
          children: [
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: items.where((i) => i.count > 0).map((item) {
                    return Expanded(
                      flex: item.count,
                      child: Container(height: 5, color: item.color),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...items.map((item) => _buildHealthRow(item)),
          ],
        ),
      );
    });
  }

  Widget _buildHealthRow(_HealthEntry item) {
    final isAlert = item.count > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? null : const Color(0xFFF8F9FC),
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
              color: isAlert ? item.color : _kTextSub,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAlert ? FontWeight.w600 : FontWeight.w400,
                color: isAlert ? _kTextPrimary : _kTextSub,
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
                  color: isAlert ? item.color : _kTextSub,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = _controller.recentActivities;
    final shown = activities.length > 6 ? activities.sublist(0, 6) : activities;

    return _SectionCard(
      title: 'Recent activity',
      trailing: const Text(
        'Latest warehouse events',
        style: TextStyle(fontSize: 12, color: _kTextSub),
      ),
      child: shown.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 32,
                      color: _kTextMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No recent activity',
                      style: TextStyle(fontSize: 12, color: _kTextSub),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: shown.asMap().entries.map((e) {
                final activity = e.value;
                final isLast = e.key == shown.length - 1;
                return Column(
                  children: [
                    _buildActivityTile(activity),
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
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final user = (activity['user'] ?? 'U') as String;
    final initial = user.isNotEmpty ? user[0].toUpperCase() : 'U';
    final timeAgo = _timeAgo(activity['createdAt']);
    final action = activity['action'] ?? '';
    final details = activity['details'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (details.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details.toString(),
                    style: const TextStyle(fontSize: 11, color: _kTextMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeAgo,
            style: const TextStyle(fontSize: 11, color: _kTextMuted),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    final date = raw is DateTime ? raw : DateTime.tryParse(raw.toString());
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return DateFormat('dd/MM').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ─── Hero Card Wrapper ─────────────────────────────────────────────────────
class _HeroCardWrapper extends StatefulWidget {
  final WarehouseDashboardController controller;
  final String selectedPeriod;
  
  const _HeroCardWrapper({required this.controller, required this.selectedPeriod});

  @override
  State<_HeroCardWrapper> createState() => _HeroCardWrapperState();
}

class _HeroCardWrapperState extends State<_HeroCardWrapper> {
  String _businessLogo = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessLogo();
  }

  Future<void> _loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails = userData['businessDetails'] as Map<String, dynamic>?;
        
        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            setState(() {
              _businessLogo = logo;
            });
          }
        }
      }
    } catch (e) {
      print('❌ [_HeroCardWrapper] Error loading business logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
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
        child: Stack(
          children: [
            // Business logo background
            if (_businessLogo.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: _businessLogo.startsWith('http')
                      ? Image.network(
                          _businessLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        )
                      : Image.file(
                          File(_businessLogo),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                ),
              ),
            // Card content
            Column(
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
                                  Icons.inventory_2_rounded,
                                  size: 14,
                                  color: kPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stock Overview · ${widget.selectedPeriod}',
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
                            widget.controller.formatCurrency(
                              widget.controller.totalStockValue.value,
                            ),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.controller.totalProducts.value} products · ${widget.controller.lowStockCount.value} low stock',
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
                              color: widget.controller.lowStockCount.value > 0
                                  ? _kOrangeBg
                                  : _kGreenBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.controller.lowStockCount.value > 0
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 10,
                                  color: widget.controller.lowStockCount.value > 0
                                      ? _kOrange
                                      : _kGreen,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.controller.lowStockCount.value > 0
                                      ? '${widget.controller.lowStockCount.value} items need restocking'
                                      : 'All stock levels healthy',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: widget.controller.lowStockCount.value > 0
                                        ? _kOrange
                                        : _kGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.controller.refreshDashboard(),
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
                    _heroStatHero(
                      'Stock In Today',
                      '${widget.controller.todayStockIn.value}',
                      Icons.arrow_downward_rounded,
                      _kGreen,
                      _kGreenBg,
                    ),
                    _heroDividerHero(),
                    _heroStatHero(
                      'Stock Out Today',
                      '${widget.controller.todayStockOut.value}',
                      Icons.arrow_upward_rounded,
                      _kRed,
                      _kRedBg,
                    ),
                    _heroDividerHero(),
                    _heroStatHero(
                      'Low Stock',
                      '${widget.controller.lowStockCount.value}',
                      Icons.warning_amber_rounded,
                      _kOrange,
                      _kOrangeBg,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Functions for _HeroCardWrapperState ───────────────────────────
  Widget _heroStatHero(
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

  Widget _heroDividerHero() =>
      Container(width: 0.5, height: 44, color: _kCardBorder);
}

// ─── Section Card ──────────────────────────────────────────────────────────
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

// ─── KPI Classes ──────────────────────────────────────────────────────────
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

// ─── Bar Item ──────────────────────────────────────────────────────────────
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

// ─── Health Entry ──────────────────────────────────────────────────────────
class _HealthEntry {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _HealthEntry(this.label, this.count, this.icon, this.color);
}