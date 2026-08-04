import 'package:LedgerPro_app/Services/permission_service.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/About/about_app_screen.dart';
import 'package:LedgerPro_app/core/About/privacypolicy_screen.dart';
import 'package:LedgerPro_app/core/About/termsofservice_screen.dart';
import 'package:LedgerPro_app/core/AccountPayable/screen/Account_payable_screen.dart';
import 'package:LedgerPro_app/core/AccountRecievables/screens/account_recievables_screen.dart';
import 'package:LedgerPro_app/core/AgedRecievables/screens/aged_recievables_screen.dart';
import 'package:LedgerPro_app/core/BankAccounts/screens/bank_acccounts_screen.dart';
import 'package:LedgerPro_app/core/Bills/Screen/bill_Screen.dart';
import 'package:LedgerPro_app/core/CapitalEquity/screens/capital_equity_screen.dart';
import 'package:LedgerPro_app/core/Contact/Screens/Contact_Screen.dart';
import 'package:LedgerPro_app/core/CreditNote/screens/credit_notes_screen.dart';
import 'package:LedgerPro_app/core/Customers/Screens/customers_screen.dart';
import 'package:LedgerPro_app/core/Expense/screen/expense_screen.dart';
import 'package:LedgerPro_app/core/Feedback/feedback_screen.dart';
import 'package:LedgerPro_app/core/FixedAssets/Screens/fixed_assets_screen.dart';
import 'package:LedgerPro_app/core/GeneralLedger/Screen/general_ledger_screen.dart';
import 'package:LedgerPro_app/core/Income/Screen/income_screen.dart';
import 'package:LedgerPro_app/core/Notifications/screens/notification_screen.dart';
import 'package:LedgerPro_app/core/PaymentMade/screens/payment_made_screen.dart';
import 'package:LedgerPro_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:LedgerPro_app/core/TrailBalance/Screen/trail_balance_screen.dart';
import 'package:LedgerPro_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:LedgerPro_app/core/balancesheet/screens/balance_sheet_screen.dart';
import 'package:LedgerPro_app/core/cashflowstatement/screen/cash_flow_statement_screen.dart';
import 'package:LedgerPro_app/core/changepassword/screen/change_password_screen.dart';
import 'package:LedgerPro_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:LedgerPro_app/core/settings/screens/currency_screen.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashboard_screen_web.dart';
import 'package:LedgerPro_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:LedgerPro_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:LedgerPro_app/core/loanBorrowing/screen/_loan_borrowing_screen.dart';
import 'package:LedgerPro_app/core/login/screen/login_screen.dart';
import 'package:LedgerPro_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/core/profitlossStatement/screens/profit_loss_statement_screen.dart';
import 'package:LedgerPro_app/core/warehousecustomer/warehouse_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

const _kPageBg = Color(0xFFF3F5FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFE9EBF2);
const _kTextPrimary = Color(0xFF14162B);
const _kTextSecondary = Color(0xFF8A8FA6);
const _kBlue = Color(0xFF4361EE);
const _kGreen = Color(0xFF2DC653);
const _kOrange = Color(0xFFF4A228);
const _kRed = Color(0xFFEF4444);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  int _selectedChartIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final DashboardController _controller;
  late final SubscriptionController _subscriptionController;

  // Time period selection
  String _selectedTimePeriod = 'This Month';

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
        title: const Text('⚠️ Subscription Expired'),
        content: Text(
          _subscriptionController.trialDaysRemaining.value > 0
              ? 'Your free trial has ended. Please subscribe to continue using the app.'
              : 'Your subscription has expired. Please renew to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => const SelectPlanScreen());
            },
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isWeb) {
      return const WebDashboardScreen();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,
      appBar: _buildAppBar(isMobile),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.chartData.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 36,
            ),
          );
        }

        return RefreshIndicator(
          color: kPrimary,
          backgroundColor: _kCardBg,
          onRefresh: () async {
            await _subscriptionController.checkSubscriptionStatus();
            _controller.loadDashboardData();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 14),
                _buildTimePeriodSelector(context),
                const SizedBox(height: 18),
                _kpiGrid(context, isTablet),
                const SizedBox(height: 18),
                _SectionPadding(
                  child: isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRevenueExpenseChart(context)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCashAndOutstanding(context)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildRevenueExpenseChart(context),
                            const SizedBox(height: 12),
                            _buildCashAndOutstanding(context),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                _SectionPadding(
                  child: _buildRecentTransactions(context),
                ),
                const SizedBox(height: 14),
                _SectionPadding(
                  child: _buildQuickActions(context),
                ),
              ],
            ),
          ),
        );
      }),
      drawer: _buildDrawer(context),
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
              Icons.account_balance_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Accounting',
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
            Get.to(() => const NotificationScreen());
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Greeting Header ──────────────────────────────────────────────────────
  Widget _buildGreetingHeader() {
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
                  Icons.account_balance_rounded,
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
                      'Accounting Overview',
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
                onTap: () => _controller.loadDashboardData(),
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
                'Total Sales',
                _controller.totalSalesFormatted.value,
                Icons.trending_up_rounded,
                _kGreen,
              ),
              _headerDivider(),
              _headerStat(
                'Net Profit',
                _controller.netProfitFormatted.value,
                Icons.account_balance_wallet_rounded,
                _controller.netProfit.value >= 0 ? _kGreen : _kRed,
              ),
              _headerDivider(),
              _headerStat(
                'Outstanding',
                _controller.outstandingFormatted.value,
                Icons.pending_actions_rounded,
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
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
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

  // ─── KPI Grid ──────────────────────────────────────────────────
  Widget _kpiGrid(BuildContext context, bool isTablet) {
    final kpis = [
      _KpiData(
        label: 'TOTAL SALES',
        value: _controller.totalSalesFormatted.value,
        icon: Icons.trending_up_rounded,
        accent: _kGreen,
        sparkData: _generateSparkData(_controller.totalSales.value),
        trend: '+12.5%',
        trendUp: true,
      ),
      _KpiData(
        label: 'NET PROFIT',
        value: _controller.netProfitFormatted.value,
        icon: Icons.account_balance_wallet_rounded,
        accent: _controller.netProfit.value >= 0 ? _kGreen : _kRed,
        sparkData: _generateSparkData(_controller.netProfit.value),
        trend: _controller.profitMargin.value.toStringAsFixed(1) + '%',
        trendUp: _controller.netProfit.value >= 0,
      ),
      _KpiData(
        label: 'BANK BALANCE',
        value: _controller.totalBankBalanceFormatted.value,
        icon: Icons.account_balance_wallet_rounded,
        accent: _kBlue,
        sparkData: _generateSparkData(_controller.totalBankBalance.value),
        trend: '+8.2%',
        trendUp: true,
      ),
      _KpiData(
        label: 'OUTSTANDING',
        value: _controller.outstandingFormatted.value,
        icon: Icons.pending_actions_rounded,
        accent: _kOrange,
        sparkData: _generateSparkData(_controller.outstanding.value),
        trend: '-3.1%',
        trendUp: false,
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

  List<double> _generateSparkData(double value) {
    final baseValue = value.isNaN ? 0.0 : value;
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

  // ─── Time Period Selector ──────────────────────────────────────────────────────
  Widget _buildTimePeriodSelector(BuildContext context) {
    final timePeriods = [
      'Today',
      'Last Week',
      'This Month',
      'Last Month',
      'This Quarter',
      'This Year',
      'Custom',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 45,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: _kBlue),
              const SizedBox(width: 8),
              const Text('Select Time Period'),
            ],
          ),
          value: _selectedTimePeriod,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          isExpanded: true,
          isDense: false,
          underline: const SizedBox(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
          items: timePeriods.map((period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: _kBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      period,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTimePeriod = value;
              });
              _controller.loadDashboardData(timePeriod: value);
            }
          },
          dropdownColor: _kCardBg,
          elevation: 8,
          menuMaxHeight: 250,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRevenueExpenseChart(BuildContext context) {
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Revenue, Expenses & Profit',
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 11,
                        color: _kBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() => _buildFinancialSummaryBars()),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryBars() {
    return Column(
      children: [
        _buildSummaryBar(
          'Total Sales',
          _controller.totalSalesFormatted.value,
          _kGreen,
          Icons.trending_up_rounded,
        ),
        const SizedBox(height: 10),
        _buildSummaryBar(
          'Total Purchases',
          _controller.totalPurchasesFormatted.value,
          _kOrange,
          Icons.shopping_cart_rounded,
        ),
        const SizedBox(height: 10),
        _buildSummaryBar(
          'Total Expenses',
          _controller.totalExpensesFormatted.value,
          _kRed,
          Icons.trending_down_rounded,
        ),
        const SizedBox(height: 10),
        _buildSummaryBar(
          'Net Profit',
          _controller.netProfitFormatted.value,
          _controller.netProfit.value >= 0 ? _kGreen : _kRed,
          Icons.account_balance_wallet_rounded,
        ),
      ],
    );
  }

  Widget _buildSummaryBar(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashAndOutstanding(BuildContext context) {
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
          const Text(
            'Cash & Outstanding',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => Column(
            children: [
              _buildCashCard(
                'Bank Balance',
                _controller.totalBankBalanceFormatted.value,
                _kBlue,
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 10),
              _buildCashCard(
                'Cash Balance',
                _controller.totalCashBalanceFormatted.value,
                _kGreen,
                Icons.payments_rounded,
              ),
              const SizedBox(height: 10),
              _buildCashCard(
                'Outstanding',
                _controller.outstandingFormatted.value,
                _kOrange,
                Icons.pending_actions_rounded,
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildCashCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Obx(() {
      if (_controller.recentTransactions.isEmpty) {
        return const SizedBox.shrink();
      }
      final recent = _controller.recentTransactions.take(4).toList();
      final isWeb = ResponsiveUtils.isWeb(context);
      
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Latest transactions',
                      style: TextStyle(
                        fontSize: 11,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentTab = 1),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: recent.asMap().entries.map((e) {
                final transaction = e.value;
                final isLast = e.key == recent.length - 1;
                final date = transaction['date'] is DateTime
                    ? transaction['date']
                    : DateTime.parse(transaction['date']);
                final type = transaction['type'];
                final amount = (transaction['amount'] ?? 0).toDouble();
                final title = transaction['title'] ?? '';
                final iconName = transaction['icon'] ?? 'circle';
                final amountColor = type == 'income' ? kSuccess : kDanger;

                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _currentTab = 1),
                        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 12 : 8,
                            vertical: isWeb ? 12 : 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isWeb ? 60 : 48,
                                height: isWeb ? 60 : 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      amountColor.withOpacity(0.18),
                                      amountColor.withOpacity(0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    isWeb ? 20 : 16,
                                  ),
                                  border: Border.all(
                                    color: amountColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Iconify(
                                  _getTransactionIcon(iconName),
                                  color: amountColor,
                                  size: isWeb ? 28 : 24,
                                ),
                              ),
                              SizedBox(width: isWeb ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: isWeb ? 16 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: kText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isWeb ? 4 : 2),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(date),
                                      style: TextStyle(
                                        fontSize: isWeb ? 14 : 13,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${type == 'income' ? '+' : '-'} ${CurrencyUtils.format(amount)}',
                                    style: TextStyle(
                                      fontSize: isWeb ? 16 : 15,
                                      fontWeight: FontWeight.w800,
                                      color: amountColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: isWeb ? 4 : 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isWeb ? 12 : 8,
                                      vertical: isWeb ? 4 : 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: amountColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      type == 'income' ? 'Income' : 'Expense',
                                      style: TextStyle(
                                        fontSize: isWeb ? 13 : 12,
                                        color: amountColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: EdgeInsets.only(left: isWeb ? 80 : 64),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: kBorder.withOpacity(0.7),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: isWeb ? 12 : 8),
          ],
        ),
      );
    });
  }

  String _getTransactionIcon(String iconName) {
    switch (iconName) {
      case 'income':
        return Mdi.cash;
      case 'expense':
        return Mdi.cash_minus;
      case 'invoice':
        return Mdi.receipt;
      case 'payment':
        return Mdi.credit_card;
      default:
        return Mdi.circle;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Obx(() {
      if (_controller.quickActions.isEmpty) return const SizedBox.shrink();
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
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _controller.quickActions.map((action) {
                final label = action['label'] ?? '';
                final iconName = action['icon'] ?? 'circle';
                final colorHex = action['color'] ?? '#3498DB';
                final color = _controller.getColorFromHex(colorHex);
                return _buildQuickActionButton(
                  label,
                  _getQuickActionIcon(iconName),
                  color,
                  () {
                    switch (label) {
                      case 'Income':
                        Get.to(() => const IncomeScreen());
                        break;
                      case 'Expense':
                        Get.to(() => const ExpenseScreen());
                        break;
                      case 'Invoice':
                        setState(() => _currentTab = 2);
                        break;
                      case 'Customer':
                        Get.to(() => const CustomersScreen());
                        break;
                      default:
                        Get.snackbar('Coming Soon', '$label module coming soon');
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  String _getQuickActionIcon(String iconName) {
    switch (iconName) {
      case 'income':
        return Mdi.cash;
      case 'expense':
        return Mdi.cash_minus;
      case 'invoice':
        return Mdi.receipt;
      case 'customer':
        return Mdi.account;
      default:
        return Mdi.circle;
    }
  }

  Widget _buildQuickActionButton(
    String label,
    String icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Iconify(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Bottom Navigation with proper menu handling
  Widget _buildBottomNav(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    final items = [
      {
        'icon': Mdi.view_dashboard_outline,
        'activeIcon': Mdi.view_dashboard,
        'label': 'Dashboard',
      },
      {
        'icon': Mdi.swap_horizontal,
        'activeIcon': Mdi.swap_horizontal,
        'label': 'Transactions',
      },
      {
        'icon': Mdi.receipt_outline,
        'activeIcon': Mdi.receipt,
        'label': 'Invoices',
      },
      {'icon': Mdi.menu, 'activeIcon': Mdi.menu, 'label': 'Menu'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isWeb ? 28 : 24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isWeb ? 12 : 10,
            horizontal: isWeb ? 8 : 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = (i == 3) ? false : _currentTab == i;

              return InkWell(
                onTap: () {
                  if (i == 3) {
                    _scaffoldKey.currentState?.openDrawer();
                    return;
                  }
                  setState(() => _currentTab = i);
                },
                borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 12 : 8,
                    vertical: isWeb ? 6 : 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(
                          isActive ? (isWeb ? 12 : 8) : (isWeb ? 8 : 6),
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? kPrimary.withOpacity(0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Iconify(
                          isActive
                              ? item['activeIcon'] as String
                              : item['icon'] as String,
                          color: isActive ? kPrimary : kSubText,
                          size: isActive
                              ? (isWeb ? 28 : 26)
                              : (isWeb ? 24 : 22),
                        ),
                      ),
                      SizedBox(height: isWeb ? 6 : 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 12,
                          color: isActive ? kPrimary : kSubText,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Drawer with proper navigation
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
                  title: 'LedgerPro Core',
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
                    ('Journal Entries', Mdi.book_open_page_variant, 'journal_entries'),
                    ('General Ledger', Mdi.book_open_blank_variant, 'general_ledger'),
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
                  ],
                  items: const [
                    ('Accounts Receivable', Mdi.cash_plus, 'accounts_receivable'),
                    ('Accounts Payable', Mdi.cash_minus, 'accounts_payable'),
                    ('Customers', Mdi.account_group, 'customers'),
                    ('Bills', Mdi.file_document_outline, 'bills'),
                    ('Payments Received', Mdi.credit_card_outline, 'payments_received'),
                    ('Payments Made', Mdi.cash_check, 'payments_made'),
                    ('Credit Notes', Mdi.file_undo_outline, 'credit_notes'),
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
                    ('Fixed Assets', Mdi.office_building_outline, 'fixed_assets'),
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
                    ('Balance Sheet', Mdi.clipboard_list_outline, 'balance_sheet'),
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
                  permissions: const [
                    'currency',
                  ],
                  items: const [
                    ('Currency', Mdi.currency_usd, 'currency'),
                  ],
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
                  items: const [
                    ('Feedback', Mdi.feedback, 'feedback'),
                  ],
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
          _DrawerFooter(onLogout: () => _showLogoutDialog()),
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
        title: Text(
          'Logout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final permissionService = PermissionService.to;
              await permissionService.clearUserData();
              SharedPreferences.getInstance().then((prefs) => prefs.clear());
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ FIXED: ExpandableSection with proper navigation
// ============================================================
class ExpandableSection extends StatefulWidget {
  final BuildContext context;
  final String title;
  final String iconName;
  final List<String> items;

  const ExpandableSection({
    super.key,
    required this.context,
    required this.title,
    required this.iconName,
    required this.items,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 24 : 20,
                vertical: isWeb ? 16 : 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: isWeb ? 40 : 32,
                    height: isWeb ? 40 : 32,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                    ),
                    child: Iconify(
                      widget.iconName,
                      size: isWeb ? 24 : 20,
                      color: kPrimary,
                    ),
                  ),
                  SizedBox(width: isWeb ? 20 : 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 15,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                  ),
                  Iconify(
                    _isExpanded ? Mdi.chevron_up : Mdi.chevron_down,
                    size: isWeb ? 24 : 20,
                    color: kSubText,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            color: kBg.withOpacity(0.3),
            child: Column(
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildMenuItem(context, item),
                    if (index < widget.items.length - 1)
                      Divider(
                        height: 1,
                        indent: isWeb ? 80 : 64,
                        endIndent: isWeb ? 24 : 20,
                        color: kBorder.withOpacity(0.5),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String item) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 100), () {
            _navigateToScreen(item);
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 60 : 48,
            vertical: isWeb ? 14 : 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWeb ? 28 : 24,
                height: isWeb ? 28 : 24,
                child: Iconify(
                  _getIconForMenuItem(item),
                  size: isWeb ? 20 : 18,
                  color: kSubText,
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 14,
                    color: kText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(String item) {
    switch (item) {
      case 'Terms of Service':
        Get.to(() => const TermsOfServiceScreen());
        break;
      case 'Privacy Policy':
        Get.to(() => PrivacyPolicyScreen());
        break;
      case 'About App':
        Get.to(() => const AboutAppScreen());
        break;
      case 'Change Password':
        Get.to(() => ChangePasswordScreen());
        break;
      case 'My Profile':
        Get.to(() => ProfileScreen());
        break;
      case 'Currency':
        Get.to(() => const CurrencyScreen());
        break;
      case 'Income':
        Get.to(() => const IncomeScreen());
        break;
      case 'Expense':
        Get.to(() => const ExpenseScreen());
        break;
      case 'Profit & Loss Statement':
        Get.to(() => const ProfitLossStatementScreen());
        break;
      case 'Balance Sheet':
        Get.to(() => const BalanceSheetScreen());
        break;
      case 'Cash Flow Statement':
        Get.to(() => const CashFlowStatementScreen());
        break;
      case 'Aged Receivables':
        Get.to(() => const AgedReceivablesScreen());
        break;
      case 'Chart of Accounts':
        Get.to(() => const ChartOfAccountsScreen());
        break;
      case 'Journal Entries':
        Get.to(() => const JournalEntriesScreen());
        break;
      case 'General Ledger':
        Get.to(() => const GeneralLedgerScreen());
        break;
      case 'Trial Balance':
        Get.to(() => const TrialBalanceScreen());
        break;
      case 'Bank Accounts':
        Get.to(() => const BankAccountsScreen());
        break;
      case 'Accounts Receivable':
        Get.to(() => const AccountsReceivableScreen());
        break;
      case 'Accounts Payable':
        Get.to(() => const AccountsPayableScreen());
        break;
      case 'Customers':
        Get.to(() => const WarehouseCustomerScreen());
        break;
      case 'bills':
        Get.to(() => const BillsScreen());
        break;
      case 'Payments Received':
        Get.to(() => const PaymentsReceivedScreen());
        break;
      case 'Payments Made':
        Get.to(() => const PaymentsMadeScreen());
        break;
      case 'Credit Notes':
        Get.to(() => const CreditNotesScreen());
        break;
      case 'Fixed Assets':
        Get.to(() => const FixedAssetsScreen());
        break;
      case 'Loans & Borrowings':
        Get.to(() => const LoansBorrowingsScreen());
        break;
      case 'Capital / Equity':
        Get.to(() => const CapitalEquityScreen());
        break;
      case 'Contact Support':
        Get.to(() => const ContactScreen());
        break;
      case 'Report an Issue':
        Get.to(() => const ReportIssueScreen());
        break;
      case 'subscription':
        Get.to(() => const SelectPlanScreen());
        break;
      case 'User Guide':
        Get.to(() => const UserGuideScreen());
        break;
      case 'Feedback':
        Get.to(() => const FeedbackScreen());
        break;
      default:
        Get.snackbar('Coming Soon', '$item module coming soon');
    }
  }

  String _getIconForMenuItem(String item) {
    switch (item) {
      case 'Feedback':
        return Mdi.feedback;
      case 'Chart of Accounts':
        return Mdi.chart_tree;
      case 'Journal Entries':
        return Mdi.book_open_page_variant;
      case 'General Ledger':
        return Mdi.book_open_blank_variant;
      case 'Trial Balance':
        return Mdi.scale_balance;
      case 'Bank Accounts':
        return Mdi.bank;
      case 'Accounts Receivable':
        return Mdi.cash_plus;
      case 'Accounts Payable':
        return Mdi.cash_minus;
      case 'Income':
        return Mdi.trending_up;
      case 'Expense':
        return Mdi.trending_down;
      case 'bills':
        return Mdi.file_document_outline;
      case 'Profit & Loss Statement':
        return Mdi.chart_line;
      case 'Balance Sheet':
        return Mdi.clipboard_list_outline;
      case 'Cash Flow Statement':
        return Mdi.cash;
      case 'Aged Receivables':
        return Mdi.account_clock;
      case 'Customers':
        return Mdi.account_group;
      case 'Payments Received':
        return Mdi.credit_card_outline;
      case 'Payments Made':
        return Mdi.cash_check;
      case 'Credit Notes':
        return Mdi.file_undo_outline;
      case 'Fixed Assets':
        return Mdi.office_building_outline;
      case 'Loans & Borrowings':
        return Mdi.hand_coin_outline;
      case 'Capital / Equity':
        return Mdi.chart_donut;
      case 'subscription':
        return Mdi.crown;
      case 'Currency':
        return Mdi.currency_usd;
      case 'My Profile':
        return Mdi.account_circle_outline;
      case 'Change Password':
        return Mdi.lock_reset;
      case 'User Guide':
        return Mdi.book_information_variant;
      case 'Contact Support':
        return Mdi.headset;
      case 'Report an Issue':
        return Mdi.bug_outline;
      case 'About App':
        return Mdi.information_outline;
      case 'Terms of Service':
        return Mdi.file_sign;
      case 'Privacy Policy':
        return Mdi.shield_lock_outline;
      default:
        return Mdi.circle_outline;
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DrawerHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final subscriptionController = Get.find<SubscriptionController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: kPrimary),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 14),
          // Company avatar + name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.account_balance_rounded, color: Colors.black87, size: 22),
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
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Accounting Dashboard',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Iconify(Mdi.shield_account, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  'Current Plan',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const Spacer(),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: subscriptionController.hasActiveSubscription.value
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subscriptionController.hasActiveSubscription.value
                          ? 'Premium'
                          : subscriptionController.isTrialActive.value
                              ? 'Trial'
                              : 'Free',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
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

// ══════════════════════════════════════════════════════════════════
// KPI Card
// ══════════════════════════════════════════════════════════════════

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
                  minY: data.sparkData.isEmpty ? 0 : data.sparkData.reduce((a, b) => a < b ? a : b).toDouble() * 0.85,
                  maxY: data.sparkData.isEmpty ? 1 : data.sparkData.reduce((a, b) => a > b ? a : b).toDouble() * 1.15,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.sparkData.isEmpty
                          ? [const FlSpot(0, 0)]
                          : data.sparkData
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
                        color: data.accent.withOpacity(0.15),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: up ? _kGreen.withOpacity(0.10) : _kRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: up ? _kGreen : _kRed,
          ),
          const SizedBox(width: 2),
          Text(
            trend,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: up ? _kGreen : _kRed,
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Nav Section
// ══════════════════════════════════════════════════════════════════

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
    if (widget.module == null || widget.permissions == null) {
      return widget.items;
    }

    final isAdmin = _permissionService.isAdmin;
    if (isAdmin) return widget.items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final permission = widget.permissions![i];
      
      if (_permissionService.hasSubPageAccess(widget.module!, permission)) {
        filtered.add(item);
      }
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    
    // Hide entire section if no items are visible
    if (filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Iconify(widget.icon, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: filteredItems.map((item) {
              return _NavItem(
                label: item.$1,
                icon: item.$2,
                routeKey: item.$3,
              );
            }).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Nav Item
// ══════════════════════════════════════════════════════════════════

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
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 14,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Iconify(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:  TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
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
          Get.snackbar('Coming Soon', '$label coming soon');
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
          Get.snackbar('Coming Soon', '$label coming soon');
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// Drawer Footer
// ══════════════════════════════════════════════════════════════════

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
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User card
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
                    gradient: const LinearGradient(colors: [kPrimary, kPrimaryDark]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 17),
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
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
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Active', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Logout button
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Iconify(Mdi.logout, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red.shade400),
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

// ProfileScreen placeholder - Add this if not exists
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kPrimary,
      ),
      body: const Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}