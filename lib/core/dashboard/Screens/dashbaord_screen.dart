import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart'; 
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/AccountPayable/screen/Account_payable_screen.dart';
import 'package:BisonsTechs_app/core/AccountRecievables/screens/account_recievables_screen.dart';
import 'package:BisonsTechs_app/core/AgedRecievables/screens/aged_recievables_screen.dart';
import 'package:BisonsTechs_app/core/BankAccounts/screens/bank_acccounts_screen.dart';
import 'package:BisonsTechs_app/core/Bills/Screen/bill_Screen.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/screens/capital_equity_screen.dart';
import 'package:BisonsTechs_app/core/Contact/Screens/Contact_Screen.dart';
import 'package:BisonsTechs_app/core/CreditNote/screens/credit_notes_screen.dart';
import 'package:BisonsTechs_app/core/Customers/Screens/customers_screen.dart';
import 'package:BisonsTechs_app/core/Expense/screen/expense_screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/FixedAssets/Screens/fixed_assets_screen.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Screen/general_ledger_screen.dart';
import 'package:BisonsTechs_app/core/Income/Screen/income_screen.dart';
import 'package:BisonsTechs_app/core/Notifications/screens/notification_screen.dart';
import 'package:BisonsTechs_app/core/PaymentMade/screens/payment_made_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/TrailBalance/Screen/trail_balance_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/balancesheet/screens/balance_sheet_screen.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/screen/cash_flow_statement_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:BisonsTechs_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:BisonsTechs_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:BisonsTechs_app/core/loanBorrowing/screen/_loan_borrowing_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/profitlossStatement/screens/profit_loss_statement_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/screen/warehouse_invoice_screen.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:shimmer/shimmer.dart';

const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFEEEFF4);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSub = Color(0xFF8A8FA8);
const _kTextMuted = Color(0xFFB0B4C8);

const _kPrimaryBg = Color(0xFFE6EEF5);
const _kGreen = Color(0xFF22A869);
const _kGreenBg = Color(0xFFEAF7F1);
const _kOrange = Color(0xFFF59E0B);
const _kOrangeBg = Color(0xFFFFF8E7);
const _kRed = Color(0xFFEF4444);
const _kRedBg = Color(0xFFFEF2F2);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F0FF);

// Hero card — light tint of brand primary (#014582)
const _kHeroBg = Color(0xFFE6EEF5);
const _kHeroBgEnd = Color(0xFFD6E4F0);
const _kHeroBorder = Color(0xFFB8CFE0);
const _kHeroIcon = Color(0xFFC5D8E8);
const _kChipBg = Color(0xFFF0F2F8); // unselected chip background
const _kAppBarBg = Color(0xFFF7F9FC);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final DashboardController _controller;
  late final SubscriptionController _subscriptionController;

  final List<String> _timePeriods = [
    'Today',
    'Last Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(DashboardController());
    _subscriptionController = Get.find<SubscriptionController>();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkSubscriptionPeriodically();
    });
  }

  void _checkSubscriptionPeriodically() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkAndHandleExpiry();
    });
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) _checkSubscriptionPeriodically();
    });
  }

  Future<void> _checkAndHandleExpiry() async {
    await _subscriptionController.checkSubscriptionStatus();
    if (!_subscriptionController.hasActiveSubscription.value &&
        _subscriptionController.subscriptionStatus.value == 'expired') {
      _showExpiredDialog();
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Subscription expired'),
        content: Text(
          _subscriptionController.trialDaysRemaining.value > 0
              ? 'Your free trial has ended. Subscribe to continue.'
              : 'Your subscription has expired. Renew to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => const SelectPlanScreen());
            },
            child: const Text('Subscribe now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,
      appBar: _buildAppBar(isMobile),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.chartData.isEmpty) {
          return _buildShimmer();
        }
        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: () async {
            await _subscriptionController.checkSubscriptionStatus();
            _controller.loadDashboardData();
          },
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
                _buildRevenueTrendCard(),
                const SizedBox(height: 16),
                _buildExpenseCategoriesCard(),
                const SizedBox(height: 16),
                _buildKpiSources(),
                const SizedBox(height: 16),
                _buildRecentTransactions(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        );
      }),
      drawer: _buildDrawer(context),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'BisonsTechs',
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
            // Hero card shimmer
            _shimmerBox(height: 180, radius: 18),
            const SizedBox(height: 14),
            // Chips row
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
            // KPI 2x2 grid
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
            // Financial overview card
            _shimmerBox(height: 200, radius: 16),
            const SizedBox(height: 16),
            // Transactions card
            _shimmerBox(height: 220, radius: 16),
            const SizedBox(height: 16),
            // Quick actions card
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

  Widget _buildHeroCard() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: label + big value
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
                              Icons.account_balance_wallet_rounded,
                              size: 14,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(
                            () => Text(
                              'Net Profit · ${_controller.periodLabel}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kTextSub,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _controller.netProfitFormatted.value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _controller.netProfit.value >= 0
                              ? _kTextPrimary
                              : _kRed,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_controller.totalRevenueFormatted.value} − ${_controller.totalPurchasesFormatted.value} − ${_controller.totalExpensesFormatted.value}',
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
                          color: _controller.netProfit.value >= 0
                              ? _kGreenBg
                              : _kRedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _controller.netProfit.value >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 10,
                              color: _controller.netProfit.value >= 0
                                  ? _kGreen
                                  : _kRed,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _controller.netProfit.value >= 0
                                  ? '${_controller.profitMargin.value.abs().toStringAsFixed(1)}% margin'
                                  : 'Expenses exceed revenue',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _controller.netProfit.value >= 0
                                    ? _kGreen
                                    : _kRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh button
                GestureDetector(
                  onTap: () => _controller.refreshData(),
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
            // Bottom 3 stats — accounting balances (not Sales/Purchase ops)
            Row(
              children: [
                _heroStat(
                  'Revenue',
                  _controller.totalRevenueFormatted.value,
                  Icons.trending_up_rounded,
                  _kGreen,
                  _kGreenBg,
                ),
                _heroDivider(),
                _heroStat(
                  'Bank Balance',
                  _controller.totalBankBalanceFormatted.value,
                  Icons.account_balance_rounded,
                  kPrimary,
                  _kPrimaryBg,
                ),
                _heroDivider(),
                _heroStat(
                  'Payables',
                  _controller.payablesFormatted.value,
                  Icons.receipt_long_rounded,
                  _kRed,
                  _kRedBg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _heroDivider() {
    return Container(width: 0.5, height: 44, color: _kCardBorder);
  }

  // ─── Period Chips ─────────────────────────────────────────────────────────
  Widget _buildPeriodChips() {
    return Obx(() {
      final selected = _controller.selectedTimePeriod.value;
      return SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _timePeriods.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final period = _timePeriods[i];
            final isActive = period == selected;
            final label = period == 'Custom' && isActive
                ? _controller.periodLabel
                : period;
            return GestureDetector(
              onTap: () async {
                if (period == 'Custom') {
                  await _pickCustomDateRange();
                  return;
                }
                await _controller.loadDashboardData(timePeriod: period);
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
                  label,
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

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialStart =
        _controller.customStartDate.value ?? DateTime(now.year, now.month, 1);
    final initialEnd =
        _controller.customEndDate.value ??
        DateTime(now.year, now.month, now.day);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _kTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    await _controller.loadDashboardData(
      timePeriod: 'Custom',
      customStart: range.start,
      customEnd: range.end,
    );
  }

  // ─── KPI Grid ─────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(bool isTablet) {
    return Obx(() {
      final kpis = [
        _KpiItem(
          label: 'Revenue',
          value: _controller.totalRevenueFormatted.value,
          icon: Icons.trending_up_rounded,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: _controller.formatTrend(_controller.revenueChange.value),
          trendUp: _controller.isRevenuePositive.value,
        ),
        _KpiItem(
          label: 'Expenses',
          value: _controller.totalExpensesFormatted.value,
          icon: Icons.trending_down_rounded,
          iconBg: _kRedBg,
          iconColor: _kRed,
          trend: _controller.formatTrend(_controller.expenseChange.value),
          trendUp: _controller.isExpensePositive.value,
        ),
        _KpiItem(
          label: 'Bank Balance',
          value: _controller.totalBankBalanceFormatted.value,
          icon: Icons.account_balance_rounded,
          iconBg: _kPrimaryBg,
          iconColor: kPrimary,
          trend: _controller.bankAccountsCount.value > 0
              ? '${_controller.bankAccountsCount.value} accounts'
              : 'No accounts',
          trendUp: _controller.isCashPositive.value,
        ),
        _KpiItem(
          label: 'Receivables',
          value: _controller.outstandingFormatted.value,
          icon: Icons.hourglass_empty_rounded,
          iconBg: _kOrangeBg,
          iconColor: _kOrange,
          trend: _controller.outstandingCount.value > 0
              ? '${_controller.outstandingCount.value} open'
              : 'Clear',
          trendUp: _controller.outstanding.value <= 0,
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

  // ─── Financial Overview (bar-based) ──────────────────────────────────────
  Widget _buildFinancialOverview() {
    return Obx(() {
      final maxVal = [
        _controller.totalRevenue.value,
        _controller.totalSales.value,
        _controller.totalPurchases.value,
        _controller.totalExpenses.value,
        _controller.totalBankBalance.value,
        _controller.outstanding.value,
        _controller.payables.value,
        _controller.netProfit.value.abs(),
      ].fold<double>(0, (a, b) => b > a ? b : a);

      final bars = [
        _BarItem(
          'Revenue',
          _controller.totalRevenueFormatted.value,
          _controller.totalRevenue.value,
          _kGreen,
          _kGreenBg,
          'Sales + Income − Credit Notes',
        ),
        _BarItem(
          'Sales',
          _controller.totalSalesFormatted.value,
          _controller.totalSales.value,
          kPrimary,
          _kPrimaryBg,
          _controller.salesCount.value > 0
              ? '${_controller.salesCount.value} invoice(s) · Paid amount'
              : 'Warehouse Invoices Paid (Sales)',
        ),
        _BarItem(
          'Purchases',
          _controller.totalPurchasesFormatted.value,
          _controller.totalPurchases.value,
          _kOrange,
          _kOrangeBg,
          'Purchase invoices (period)',
        ),
        _BarItem(
          'Expenses',
          _controller.totalExpensesFormatted.value,
          _controller.totalExpenses.value,
          _kRed,
          _kRedBg,
          'Expense screen Posted (period)',
        ),
        _BarItem(
          'Bank Balance',
          _controller.totalBankBalanceFormatted.value,
          _controller.totalBankBalance.value,
          kPrimary,
          _kPrimaryBg,
          'Bank Accounts',
        ),
        _BarItem(
          'Receivables',
          _controller.outstandingFormatted.value,
          _controller.outstanding.value,
          _kOrange,
          _kOrangeBg,
          'Sales invoices outstanding',
        ),
        _BarItem(
          'Payables',
          _controller.payablesFormatted.value,
          _controller.payables.value,
          _kOrange,
          _kOrangeBg,
          'Bills + Purchase invoices',
        ),
        _BarItem(
          'Net Profit',
          _controller.netProfitFormatted.value,
          _controller.netProfit.value.abs(),
          _controller.netProfit.value >= 0 ? _kGreen : _kRed,
          _controller.netProfit.value >= 0 ? _kGreenBg : _kRedBg,
          'Revenue − Purchases − Expenses',
        ),
      ];

      return _SectionCard(
        title: 'Financial overview',
        trailing: Text(
          _controller.periodLabel,
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

  // ─── Revenue / Expenses trend (same chart style as Purchase dashboard) ───
  Widget _buildRevenueTrendCard() {
    return Obx(() {
      final rows = _controller.chartData;
      final List<double> revenueData = [];
      final List<double> expenseData = [];
      final List<String> labels = [];

      if (rows.isNotEmpty) {
        for (final row in rows) {
          revenueData.add(_asChartDouble(row['revenue']));
          expenseData.add(_asChartDouble(row['expenses']));
          final month = row['month']?.toString() ?? '';
          // Keep day for short ranges ("Aug 7"); month abbrev for "Aug 2026"
          if (month.contains(' ') && !RegExp(r'\d{4}').hasMatch(month)) {
            labels.add(month); // e.g. Aug 7
          } else if (month.length > 3) {
            labels.add(month.substring(0, 3));
          } else {
            labels.add(month);
          }
        }
      } else {
        revenueData.addAll(List.filled(6, 0));
        expenseData.addAll(List.filled(6, 0));
        labels.addAll(['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']);
      }

      final maxA = revenueData.isEmpty
          ? 0.0
          : revenueData.reduce((a, b) => a > b ? a : b);
      final maxB = expenseData.isEmpty
          ? 0.0
          : expenseData.reduce((a, b) => a > b ? a : b);
      final maxY = (maxA > maxB ? maxA : maxB) * 1.2;

      return _SectionCard(
        title: 'Revenue trend',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _controller.periodLabel,
              style: const TextStyle(fontSize: 11, color: _kTextSub),
            ),
            const SizedBox(width: 10),
            _legendDot(_kGreen, 'Revenue'),
            const SizedBox(width: 12),
            _legendDot(_kRed, 'Expenses'),
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
              maxX: (labels.length - 1).toDouble().clamp(1, 100),
              minY: 0,
              maxY: maxY > 0 ? maxY : 100,
              lineBarsData: [
                _buildTrendLine(revenueData, _kGreen),
                _buildTrendLine(expenseData, _kRed),
              ],
            ),
          ),
        ),
      );
    });
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

  // ─── Expense categories pie (same style as Purchase order-status chart) ──
  Widget _buildExpenseCategoriesCard() {
    return Obx(() {
      final cats = _controller.expenseCategories
          .where((c) => _asChartDouble(c['amount']) > 0)
          .toList();

      const palette = [
        kPrimary,
        _kPurple,
        _kOrange,
        _kGreen,
        _kRed,
        Color(0xFF0891B2),
        Color(0xFFEC4899),
      ];

      final total = cats.fold<double>(
        0,
        (s, c) => s + _asChartDouble(c['amount']),
      );

      return _SectionCard(
        title: 'Expenses by category',
        trailing: Text(
          cats.isEmpty
              ? 'No data · ${_controller.periodLabel}'
              : '${cats.length} types · ${_controller.periodLabel}',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: SizedBox(
          height: 180,
          child: cats.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections: cats.take(7).toList().asMap().entries.map((
                            entry,
                          ) {
                            final amount = _asChartDouble(
                              entry.value['amount'],
                            );
                            final color = palette[entry.key % palette.length];
                            return PieChartSectionData(
                              color: color,
                              value: amount,
                              title: total > 0
                                  ? '${((amount / total) * 100).round()}%'
                                  : '',
                              radius: 34,
                              titleStyle: const TextStyle(
                                fontSize: 9,
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
                        children: cats.take(6).toList().asMap().entries.map((
                          entry,
                        ) {
                          final c = entry.value;
                          final color = palette[entry.key % palette.length];
                          final name = c['name']?.toString() ?? 'Other';
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
                                  _asChartDouble(
                                    c['percentage'],
                                  ).toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const Text(
                                  '%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _kTextSub,
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
              : const Center(
                  child: Text(
                    'No expense categories yet',
                    style: TextStyle(fontSize: 13, color: _kTextSub),
                  ),
                ),
        ),
      );
    });
  }

  double _asChartDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Widget _buildKpiSources() {
    const sources = [
      ('Sales', 'Paid sales invoices in selected period'),
      ('Purchases', 'Purchase invoices in selected period'),
      ('Revenue', 'Sales invoiced + Income − Credit Notes (period)'),
      ('Expenses', 'Expense screen Posted in selected period'),
      ('Net Profit', 'Revenue − Purchases − Expenses (period)'),
      ('Bank Balance', 'Bank Accounts (active, current balance)'),
      ('Receivables', 'Sales invoices outstanding (current)'),
      ('Payables', 'Bills + Purchase invoices outstanding (current)'),
    ];

    return _SectionCard(
      title: 'Where numbers come from',
      child: Column(
        children: sources.asMap().entries.map((e) {
          final isLast = e.key == sources.length - 1;
          final (label, source) = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        source,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSub,
                          height: 1.35,
                        ),
                      ),
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
  }

  Widget _buildRecentTransactions() {
    return Obx(() {
      if (_controller.recentTransactions.isEmpty)
        return const SizedBox.shrink();

      final recent = _controller.recentTransactions.take(4).toList();

      return _SectionCard(
        title: 'Recent activity',

        child: Column(
          children: recent.asMap().entries.map((e) {
            final tx = e.value;
            final isLast = e.key == recent.length - 1;
            final date = tx['date'] is DateTime
                ? tx['date']
                : DateTime.parse(tx['date']);
            final type = tx['type'] as String? ?? '';
            final source = tx['source'] as String? ?? '';
            final amount = (tx['amount'] ?? 0).toDouble();
            final title = tx['title'] ?? '';
            final isPayment = type == 'payment' || source == 'payment_received';
            final isIncome = type == 'income' || isPayment;
            final isPurchase = type == 'purchase' || source == 'bill';
            final amtColor = isIncome ? _kGreen : _kRed;
            final iconBg = isPayment
                ? _kPrimaryBg
                : (isIncome ? _kGreenBg : (isPurchase ? _kOrangeBg : _kRedBg));
            final typeLabel = isPayment
                ? 'Payment'
                : (isIncome ? 'Income' : (isPurchase ? 'Purchase' : 'Expense'));
            final typeColor = isPayment
                ? kPrimary
                : (isIncome ? _kGreen : (isPurchase ? _kOrange : _kRed));

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
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 18,
                          color: amtColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
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
                              DateFormat('dd MMM yyyy').format(date),
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
                          Text(
                            '${isIncome ? '+' : '-'} ${CurrencyUtils.format(amount)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: amtColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: typeColor,
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
                  Divider(height: 1, thickness: 0.5, color: _kCardBorder),
              ],
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        'Income',
        Icons.add_circle_outline_rounded,
        _kGreen,
        _kGreenBg,
        () => Get.to(() => const IncomeScreen()),
      ),
      _QuickAction(
        'Expense',
        Icons.remove_circle_outline_rounded,
        _kRed,
        _kRedBg,
        () => Get.to(() => const ExpenseScreen()),
      ),
      _QuickAction(
        'Invoice',
        Icons.receipt_long_rounded,
        kPrimary,
        _kPrimaryBg,
        () => setState(() => _currentTab = 2),
      ),
      _QuickAction(
        'Customer',
        Icons.people_outline_rounded,
        _kOrange,
        _kOrangeBg,
        () => Get.to(() => const CustomersScreen()),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 272,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _DrawerHeader(onBack: () => _navigateToDashboardSelection(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                _SectionLabel('CORE'),
                _NavSection(
                  title: 'BisonsTechs Core',
                  icon: Mdi.account_circle,
                  module: 'accounting',
                  permissions: const [
                    'chart-of-accounts',
                    'journal-entries',
                    'general-ledger',
                    'trial-balance',
                    'bank-accounts',
                    'income',
                    'expenses',
                  ],
                  items: const [
                    ('Chart of Accounts', Mdi.chart_tree, 'chart_of_accounts'),
                    (
                      'Journal Entries',
                      Mdi.book_open_page_variant,
                      'journal_entries',
                    ),
                    (
                      'General Ledger',
                      Mdi.book_open_blank_variant,
                      'general_ledger',
                    ),
                    ('Trial Balance', Mdi.scale_balance, 'trial_balance'),
                    ('Bank Accounts', Mdi.bank, 'bank_accounts'),
                    ('Income', Mdi.trending_up, 'income'),
                    ('Expense', Mdi.trending_down, 'expense'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('RECEIVABLES & PAYABLES'),
                _NavSection(
                  title: 'Receivables & Payables',
                  icon: Mdi.swap_horizontal,
                  module: 'accounting',
                  permissions: const [
                    'accounts-receivable',
                    'accounts-payable',
                    'customers',
                    'bills',
                    'payments-received',
                    'payments-made',
                    'credit-notes',
                    'warehouse-invoices',
                  ],
                  items: const [
                    (
                      'Accounts Receivable',
                      Mdi.cash_plus,
                      'accounts_receivable',
                    ),
                    ('Accounts Payable', Mdi.cash_minus, 'accounts_payable'),
                    ('Customers', Mdi.account_group, 'customers'),
                    ('Bills', Mdi.file_document_outline, 'bills'),
                    (
                      'Payments Received',
                      Mdi.credit_card_outline,
                      'payments_received',
                    ),
                    ('Payments Made', Mdi.cash_check, 'payments_made'),
                    ('Credit Notes', Mdi.file_undo_outline, 'credit_notes'),
                    (
                      'Warehouse Invoices',
                      Mdi.receipt_text_outline,
                      'warehouse_invoices',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('ASSETS & LIABILITIES'),
                _NavSection(
                  title: 'Assets & Liabilities',
                  icon: Mdi.business,
                  module: 'accounting',
                  permissions: const [
                    'fixed-assets',
                    'loans-borrowings',
                    'capital-equity',
                  ],
                  items: const [
                    (
                      'Fixed Assets',
                      Mdi.office_building_outline,
                      'fixed_assets',
                    ),
                    ('Loans & Borrowings', Mdi.hand_coin_outline, 'loans'),
                    ('Capital / Equity', Mdi.chart_donut, 'capital_equity'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('FINANCIAL REPORTS'),
                _NavSection(
                  title: 'Financial Reports',
                  icon: Mdi.chart_line,
                  module: 'accounting',
                  permissions: const [
                    'profit-loss',
                    'balance-sheet',
                    'cash-flow',
                    'aged-receivables',
                  ],
                  items: const [
                    ('Profit & Loss', Mdi.chart_line, 'profit_loss'),
                    (
                      'Balance Sheet',
                      Mdi.clipboard_list_outline,
                      'balance_sheet',
                    ),
                    ('Cash Flow Statement', Mdi.cash, 'cash_flow'),
                    ('Aged Receivables', Mdi.account_clock, 'aged_receivables'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('SETTINGS'),
                _NavSection(
                  title: 'Settings',
                  icon: Mdi.cog,
                  module: 'accounting',
                  permissions: const ['currency'],
                  items: const [('Currency', Mdi.currency_usd, 'currency')],
                ),
                _NavSection(
                  title: 'My Account',
                  icon: Mdi.account,
                  items: const [
                    ('My Profile', Mdi.account_circle_outline, '__profile'),
                    ('Change Password', Mdi.lock_reset, '__changepassword'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('SUPPORT'),
                _NavSection(
                  title: 'Subscription',
                  icon: Mdi.crown,
                  items: const [
                    ('Subscription Plans', Mdi.crown, 'subscription'),
                  ],
                ),
                _NavSection(
                  title: 'Help & Support',
                  icon: Mdi.help_circle,
                  items: const [
                    ('User Guide', Mdi.book_information_variant, '__userguide'),
                    ('Contact Support', Mdi.headset, '__contact'),
                    ('Report an Issue', Mdi.bug_outline, '__reportissue'),
                  ],
                ),
                _NavSection(
                  title: 'Feedback',
                  icon: Mdi.feedback,
                  items: const [('Feedback', Mdi.feedback, 'feedback')],
                ),
                _NavSection(
                  title: 'About',
                  icon: Mdi.information,
                  items: const [
                    ('About App', Mdi.information_outline, 'about_app'),
                    ('Terms of Service', Mdi.file_sign, 'terms'),
                    ('Privacy Policy', Mdi.shield_lock_outline, 'privacy'),
                  ],
                ),
              ],
            ),
          ),
          _DrawerFooter(onLogout: _showLogoutDialog),
        ],
      ),
    );
  }

  void _navigateToDashboardSelection(BuildContext context) {
    Get.offAllNamed('/dashboard');
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final permissionService = PermissionService.to;
              await permissionService.clearUserData();
              SharedPreferences.getInstance().then((p) => p.clear());
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

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

// ─── Bar item model ───────────────────────────────────────────────────────
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

// ─── Quick action model ───────────────────────────────────────────────────
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.color, this.bg, this.onTap);
}

// ─── Drawer Header ────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _DrawerHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final subscriptionController = Get.find<SubscriptionController>();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: kPrimary),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.companyName.value.isEmpty
                            ? 'Company'
                            : controller.companyName.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'Accounting Dashboard',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Colors.white60,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Current plan',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
                const Spacer(),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: subscriptionController.hasActiveSubscription.value
                          ? Colors.green.shade500
                          : Colors.orange.shade500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subscriptionController.hasActiveSubscription.value
                          ? 'Premium'
                          : subscriptionController.isTrialActive.value
                          ? 'Trial'
                          : 'Free',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kTextMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Nav Section ──────────────────────────────────────────────────────────
class _NavSection extends StatefulWidget {
  final String title;
  final String icon;
  final List<(String, String, String)> items;
  final String? module;
  final List<String>? permissions;

  const _NavSection({
    required this.title,
    required this.icon,
    required this.items,
    this.module,
    this.permissions,
  });

  @override
  State<_NavSection> createState() => _NavSectionState();
}

class _NavSectionState extends State<_NavSection> {
  bool _expanded = false;
  final PermissionService _permissionService = PermissionService.to;

  List<(String, String, String)> get _filteredItems {
    if (widget.module == null || widget.permissions == null)
      return widget.items;
    if (_permissionService.isAdmin) return widget.items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      if (_permissionService.hasSubPageAccess(
        widget.module!,
        widget.permissions![i],
      )) {
        filtered.add(widget.items[i]);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    if (filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Iconify(
                  widget.icon,
                  size: 18,
                  color: _expanded ? kPrimary : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _expanded ? kPrimary : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _expanded ? kPrimary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: filteredItems
                .map(
                  (item) => _NavItem(
                    label: item.$1,
                    icon: item.$2,
                    routeKey: item.$3,
                  ),
                )
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final String routeKey;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.routeKey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigate(context, routeKey, label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 14,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Iconify(icon, size: 16, color: kPrimary.withOpacity(0.75)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String routeKey, String label) {
    Navigator.pop(context);
    if (routeKey.startsWith('__')) {
      switch (routeKey) {
        case '__profile':
          Get.to(() => const ProfileScreen());
          break;
        case '__changepassword':
          Get.to(() => const ChangePasswordScreen());
          break;
        case '__userguide':
          Get.to(() => const UserGuideScreen());
          break;
        case '__contact':
          Get.to(() => const ContactScreen());
          break;
        case '__reportissue':
          Get.to(() => const ReportIssueScreen());
          break;
        default:
          Get.snackbar('Coming soon', '$label coming soon');
      }
    } else {
      switch (routeKey) {
        case 'chart_of_accounts':
          Get.to(() => const ChartOfAccountsScreen());
          break;
        case 'journal_entries':
          Get.to(() => const JournalEntriesScreen());
          break;
        case 'general_ledger':
          Get.to(() => const GeneralLedgerScreen());
          break;
        case 'trial_balance':
          Get.to(() => const TrialBalanceScreen());
          break;
        case 'bank_accounts':
          Get.to(() => const BankAccountsScreen());
          break;
        case 'income':
          Get.to(() => const IncomeScreen());
          break;
        case 'expense':
          Get.to(() => const ExpenseScreen());
          break;
        case 'accounts_receivable':
          Get.to(() => const AccountsReceivableScreen());
          break;
        case 'accounts_payable':
          Get.to(() => const AccountsPayableScreen());
          break;
        case 'customers':
          Get.to(() => const WarehouseCustomerScreen());
          break;
        case 'bills':
          Get.to(() => const BillsScreen());
          break;
        case 'payments_received':
          Get.to(() => const PaymentsReceivedScreen());
          break;
        case 'payments_made':
          Get.to(() => const PaymentsMadeScreen());
          break;
        case 'credit_notes':
          Get.to(() => const CreditNotesScreen());
          break;
        case 'fixed_assets':
          Get.to(() => const FixedAssetsScreen());
          break;
        case 'loans':
          Get.to(() => const LoansBorrowingsScreen());
          break;
        case 'capital_equity':
          Get.to(() => const CapitalEquityScreen());
          break;
        case 'profit_loss':
          Get.to(() => const ProfitLossStatementScreen());
          break;
        case 'balance_sheet':
          Get.to(() => const BalanceSheetScreen());
          break;
        case 'cash_flow':
          Get.to(() => const CashFlowStatementScreen());
          break;
        case 'aged_receivables':
          Get.to(() => const AgedReceivablesScreen());
          break;
        case 'warehouse_invoices':
          Get.to(() => const WarehouseInvoiceScreen());
          break;
        case 'currency':
          Get.to(() => const CurrencyScreen());
          break;
        case 'subscription':
          Get.to(() => const SelectPlanScreen());
          break;
        case 'feedback':
          Get.to(() => const FeedbackScreen());
          break;
        case 'about_app':
          Get.to(() => const AboutAppScreen());
          break;
        case 'terms':
          Get.to(() => const TermsOfServiceScreen());
          break;
        case 'privacy':
          Get.to(() => const PrivacyPolicyScreen());
          break;
        default:
          Get.snackbar('Coming soon', '$label coming soon');
      }
    }
  }
}

// ─── Drawer Footer ────────────────────────────────────────────────────────
class _DrawerFooter extends StatelessWidget {
  final VoidCallback onLogout;
  const _DrawerFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final subscriptionController = Get.find<SubscriptionController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          controller.companyName.value.isEmpty
                              ? 'Company'
                              : controller.companyName.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Obx(
                        () => Text(
                          subscriptionController.hasActiveSubscription.value
                              ? 'Premium Account'
                              : subscriptionController.isTrialActive.value
                              ? 'Trial Account'
                              : 'Free Account',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: _kGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 9,
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _kRedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRed.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: _kRed, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: kPrimary),
      body: const Center(child: Text('Profile Screen')),
    );
  }
}
