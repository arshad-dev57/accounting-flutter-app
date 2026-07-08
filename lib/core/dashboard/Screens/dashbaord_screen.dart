import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
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
import 'package:LedgerPro_app/core/Invoice/Screens/Invoice_Screen.dart';
import 'package:LedgerPro_app/core/PaymentMade/screens/payment_made_screen.dart';
import 'package:LedgerPro_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:LedgerPro_app/core/TrailBalance/Screen/trail_balance_screen.dart';
import 'package:LedgerPro_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:LedgerPro_app/core/Vendor&Supplier/screens/vendor_supplier_screen.dart';
import 'package:LedgerPro_app/core/balancesheet/screens/balance_sheet_screen.dart';
import 'package:LedgerPro_app/core/cashflowstatement/screen/cash_flow_statement_screen.dart';
import 'package:LedgerPro_app/core/changepassword/screen/change_password_screen.dart';
import 'package:LedgerPro_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:LedgerPro_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:LedgerPro_app/core/settings/screens/currency_screen.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashboard_screen_web.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/transaction_screen.dart';
import 'package:LedgerPro_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:LedgerPro_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:LedgerPro_app/core/loanBorrowing/screen/_loan_borrowing_screen.dart';
import 'package:LedgerPro_app/core/login/screen/login_screen.dart';
import 'package:LedgerPro_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/core/profitlossStatement/screens/profit_loss_statement_screen.dart';
import 'package:LedgerPro_app/core/warehouse/invoice/screen/warehouse_invoice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

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

    // For web, show the web dashboard screen
    if (isWeb) {
      return const WebDashboardScreen();
    }

    // For mobile/tablet, show the mobile dashboard
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomNav(context),
      drawer: _buildDrawer(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    const titles = ['Dashboard', 'Transactions', 'Invoices', 'More'];

    return AppBar(
      title: Text(
        titles[_currentTab],
        style: TextStyle(
          fontSize: isWeb ? 18 : 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: Iconify(
            Mdi.account_outline,
            color: Colors.white,
            size: isWeb ? 24 : 22,
          ),
          onPressed: () => Get.to(() => const ProfileScreen()),
        ),
        SizedBox(width: isWeb ? 8 : 4),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentTab) {
      case 0:
        return _buildDashboardContent(context);
      case 1:
        return const TransactionsScreen();
      case 2:
        return const WarehouseInvoiceScreen();
      default:
        return _buildDashboardContent(context);
    }
  }

  Widget _buildDashboardContent(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return RefreshIndicator(
      onRefresh: () async {
        // _controller.refreshData();
        await _subscriptionController.checkSubscriptionStatus();
      },
      child: Obx(() {
        if (_controller.isLoading.value && _controller.chartData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.discreteCircle(
                  color: kPrimary,
                  size: ResponsiveUtils.isWeb(context) ? 32 : 40,
                ),
                SizedBox(height: isWeb ? 20 : 16),
                Text(
                  'Loading dashboard...',
                  style: TextStyle(fontSize: isWeb ? 14 : 13, color: kSubText),
                ),
              ],
            ),
          );
        }

        if (_controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Iconify(
                  Mdi.alert_circle_outline,
                  size: isWeb ? 60 : 48,
                  color: kDanger,
                ),
                SizedBox(height: isWeb ? 20 : 16),
                Text(
                  _controller.errorMessage.value,
                  style: TextStyle(fontSize: isWeb ? 14 : 13, color: kDanger),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isWeb ? 20 : 16),
                ElevatedButton(
                  onPressed: () {
                    // _controller.refreshData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  child: Text(
                    'Retry',
                    style: TextStyle(fontSize: isWeb ? 14 : 13),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: isWeb ? 32 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeHeader(context),
              Transform.translate(
                offset: Offset(0, isWeb ? -20 : -16),
                child: _buildKPICards(context),
              ),
              SizedBox(height: isWeb ? 4 : 2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
                child: _buildChartTabs(context),
              ),
              SizedBox(height: isWeb ? 20 : 16),
              _buildRevenueExpenseChart(context),
              SizedBox(height: isWeb ? 20 : 16),
              _buildCashAndOutstanding(context),
              SizedBox(height: isWeb ? 20 : 16),
              _buildRecentTransactions(context),
              SizedBox(height: isWeb ? 20 : 16),
              _buildQuickActions(context),
              SizedBox(height: isWeb ? 12 : 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSimpleSubscriptionStatus(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(() {
      String statusText = '';
      String statusIcon = Mdi.check_circle;
      bool isExpired = false;

      if (_subscriptionController.isTrialActive.value) {
        statusText =
            '${_subscriptionController.trialDaysRemaining.value} days free trial remaining';
        statusIcon = Mdi.crown;
      } else if (_subscriptionController.hasActiveSubscription.value) {
        statusText =
            '${_subscriptionController.subscriptionPlan.value.toUpperCase()} plan · ${_subscriptionController.subscriptionDaysRemaining.value} days left';
        statusIcon = Mdi.crown;
      } else {
        statusText = 'Subscription expired · Renew to continue';
        statusIcon = Mdi.alert;
        isExpired = true;
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 12 : 8,
          vertical: isWeb ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isExpired
              ? Colors.red.withOpacity(0.18)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          border: Border.all(
            color: isExpired
                ? Colors.red.withOpacity(0.45)
                : Colors.white.withOpacity(0.30),
          ),
        ),
        child: Row(
          children: [
            Iconify(
              statusIcon,
              color: isExpired
                  ? Colors.redAccent.shade100
                  : Colors.white.withOpacity(0.95),
              size: isWeb ? 24 : 18,
            ),
            SizedBox(width: isWeb ? 12 : 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: isWeb ? 13 : 11,
                  fontWeight: FontWeight.w500,
                  color: isExpired
                      ? Colors.red.shade100
                      : Colors.white.withOpacity(0.92),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (isExpired)
              GestureDetector(
                onTap: () => Get.to(() => const SelectPlanScreen()),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 12 : 8,
                    vertical: isWeb ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Text(
                    'Renew',
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            if (_subscriptionController.isTrialActive.value)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 10 : 6,
                  vertical: isWeb ? 5 : 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: isWeb ? 11 : 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      margin: EdgeInsets.fromLTRB(isWeb ? 24 : 16, 0, isWeb ? 24 : 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimary,
            kPrimaryDark,
            Color.lerp(kPrimaryDark, const Color(0xFF0B8BC4), 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isWeb ? 24 : 20),
          bottomRight: Radius.circular(isWeb ? 24 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -8,
            child: IgnorePointer(
              child: Container(
                width: isWeb ? 200 : 140,
                height: isWeb ? 200 : 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: isWeb ? 120 : 88,
                height: isWeb ? 120 : 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleSubscriptionStatus(context),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isWeb ? 24 : 16,
                  isWeb ? 12 : 8,
                  isWeb ? 24 : 16,
                  isWeb ? 32 : 24,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 12 : 8,
                              vertical: isWeb ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Iconify(
                                  Mdi.chart_line,
                                  size: isWeb ? 20 : 14,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                SizedBox(width: isWeb ? 8 : 4),
                                Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: isWeb ? 14 : 12,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isWeb ? 16 : 12),
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: isWeb ? 15 : 13,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: isWeb ? 6 : 4),
                          Obx(
                            () => Text(
                              _controller.companyName.value,
                              style: TextStyle(
                                fontSize: isWeb ? 22 : 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: isWeb ? 12 : 8),
                          Text(
                            'Financial snapshot · ${DateFormat('EEEE').format(DateTime.now())}',
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isWeb ? 16 : 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 20 : 16,
                        vertical: isWeb ? 16 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: isWeb ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM',
                            ).format(DateTime.now()).toUpperCase(),
                            style: TextStyle(
                              fontSize: isWeb ? 15 : 13,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: isWeb ? 4 : 2),
                          Text(
                            DateFormat('yyyy').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
      child: SizedBox(
        height: isWeb ? 160 : (isTablet ? 150 : 140),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(width: isWeb ? 20 : 16),
          itemBuilder: (context, i) {
            switch (i) {
              case 0:
                return Obx(
                  () => _buildKPICard(
                    context,
                    'Total Revenue',
                    _controller.totalRevenueFormatted.value,
                    kSuccess,
                    Mdi.trending_up,
                    '${_controller.revenueChange.value.toStringAsFixed(1)}%',
                    'vs last month',
                    _controller.isRevenuePositive.value,
                  ),
                );
              case 1:
                return Obx(
                  () => _buildKPICard(
                    context,
                    'Total Expenses',
                    _controller.totalExpensesFormatted.value,
                    kDanger,
                    Mdi.trending_down,
                    '${_controller.expenseChange.value.toStringAsFixed(1)}%',
                    'vs last month',
                    !_controller.isExpensePositive.value,
                  ),
                );
              case 2:
                return Obx(
                  () => _buildKPICard(
                    context,
                    'Outstanding',
                    _controller.outstandingFormatted.value,
                    kWarning,
                    Mdi.lan_pending,
                    '${_controller.outstandingCount.value} invoices',
                    'due',
                    true,
                  ),
                );
              case 3:
                return Obx(
                  () => _buildKPICard(
                    context,
                    'Cash Balance',
                    _controller.cashBalanceFormatted.value,
                    kPrimary,
                    Mdi.wallet,
                    '${_controller.cashChange.value.toStringAsFixed(1)}%',
                    'vs last month',
                    _controller.isCashPositive.value,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String amount,
    Color color,
    String icon,
    String trend,
    String trendText,
    bool isPositive,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final showArrow = trendText == 'vs last month';

    return Container(
      width: isWeb ? 280 : (isTablet ? 260 : 220),
      padding: EdgeInsets.fromLTRB(
        isWeb ? 20 : 16,
        isWeb ? 16 : 14,
        isWeb ? 20 : 16,
        isWeb ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        border: Border.all(color: kBorder.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isWeb ? 4 : 3,
                height: isWeb ? 32 : 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 13,
                    color: kSubText,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                padding: EdgeInsets.all(isWeb ? 12 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.14), color.withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(isWeb ? 16 : 14),
                ),
                child: Iconify(icon, color: color, size: isWeb ? 28 : 24),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isWeb ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: kText,
              letterSpacing: -0.3,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showArrow) ...[
                Padding(
                  padding: EdgeInsets.only(top: isWeb ? 2 : 1),
                  child: Iconify(
                    isPositive ? Mdi.trending_up : Mdi.trending_down,
                    size: isWeb ? 18 : 16,
                    color: isPositive ? kSuccess : kDanger,
                  ),
                ),
                SizedBox(width: isWeb ? 6 : 4),
              ],
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isWeb ? 13 : 12,
                      color: kSubText,
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(
                        text: trend,
                        style: TextStyle(
                          color: showArrow
                              ? (isPositive ? kSuccess : kDanger)
                              : color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' · $trendText'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartTabs(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      padding: EdgeInsets.all(isWeb ? 8 : 6),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        border: Border.all(color: kBorder.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildChartTab(context, 'Revenue vs Expenses', 0)),
          SizedBox(width: isWeb ? 12 : 8),
          Expanded(child: _buildChartTab(context, 'Trends', 1)),
          SizedBox(width: isWeb ? 12 : 8),
          Expanded(child: _buildChartTab(context, 'Categories', 2)),
        ],
      ),
    );
  }

  Widget _buildChartTab(BuildContext context, String title, int index) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isSelected = _selectedChartIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedChartIndex = index),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: isWeb ? 12 : 10,
            horizontal: isWeb ? 8 : 6,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : kBg,
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isWeb ? 14 : 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : kSubText,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueExpenseChart(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final titles = [
      'Revenue vs expenses',
      'Monthly financial trends',
      'Expense breakdown',
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
        border: Border.all(color: kBorder.withOpacity(0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 24 : 20,
                vertical: isWeb ? 16 : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBg, kCardBg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(color: kBorder.withOpacity(0.6)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isWeb ? 16 : 12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
                    ),
                    child: Iconify(
                      Mdi.chart_line,
                      color: kPrimary,
                      size: isWeb ? 30 : 26,
                    ),
                  ),
                  SizedBox(width: isWeb ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_selectedChartIndex],
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: kText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: isWeb ? 4 : 2),
                        Text(
                          'Tap tabs above to switch view',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 13,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 16 : 12,
                      vertical: isWeb ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kPrimary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Iconify(
                          Mdi.calendar_month,
                          size: isWeb ? 18 : 16,
                          color: kPrimary,
                        ),
                        SizedBox(width: isWeb ? 6 : 4),
                        Text(
                          DateFormat('yyyy').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 13,
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWeb ? 24 : 20,
                isWeb ? 20 : 16,
                isWeb ? 24 : 20,
                isWeb ? 24 : 20,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: isWeb ? 300 : 240,
                    child: _selectedChartIndex == 0
                        ? _buildDynamicBarChart(context)
                        : _selectedChartIndex == 1
                        ? _buildDynamicLineChart(context)
                        : _buildDynamicPieChart(context),
                  ),
                  if (_selectedChartIndex != 2) ...[
                    SizedBox(height: isWeb ? 16 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(context, 'Revenue', kPrimary),
                        SizedBox(width: isWeb ? 40 : 32),
                        _buildLegend(context, 'Expenses', kDanger),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBarChart(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    if (_controller.chartData.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: TextStyle(fontSize: isWeb ? 14 : 13, color: kSubText),
        ),
      );
    }
    double maxValue = 0;
    for (var data in _controller.chartData) {
      final revenue = (data['revenue'] ?? 0).toDouble();
      final expenses = (data['expenses'] ?? 0).toDouble();
      if (revenue > maxValue) maxValue = revenue;
      if (expenses > maxValue) maxValue = expenses;
    }
    maxValue = maxValue * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toStringAsFixed(0),
                TextStyle(
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _controller.chartData.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: isWeb ? 16 : 12),
                    child: Text(
                      _controller.getMonthName(index),
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 10,
                        color: kSubText,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: isWeb ? 40 : 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: EdgeInsets.only(right: isWeb ? 24 : 20),
                  child: Text(
                    _formatCompactNumber(value, context),
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 10,
                      color: kSubText,
                    ),
                  ),
                );
              },
              reservedSize: isWeb ? 60 : 50,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: kBorder, strokeWidth: 0.5),
        ),
        barGroups: List.generate(
          _controller.chartData.length,
          (index) => BarChartGroupData(
            x: index,
            barsSpace: isWeb ? 16 : 12,
            barRods: [
              BarChartRodData(
                toY: _controller.getMonthlyRevenue(index),
                color: kPrimary,
                width: isWeb ? 24 : 18,
                borderRadius: BorderRadius.circular(isWeb ? 8 : 6),
              ),
              BarChartRodData(
                toY: _controller.getMonthlyExpenses(index),
                color: kDanger,
                width: isWeb ? 24 : 18,
                borderRadius: BorderRadius.circular(isWeb ? 8 : 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicLineChart(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    if (_controller.chartData.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: TextStyle(fontSize: isWeb ? 14 : 13, color: kSubText),
        ),
      );
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: kBorder, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _controller.chartData.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: isWeb ? 16 : 12),
                    child: Text(
                      _controller.getMonthName(index),
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 10,
                        color: kSubText,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: isWeb ? 40 : 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: EdgeInsets.only(right: isWeb ? 24 : 20),
                  child: Text(
                    _formatCompactNumber(value, context),
                    style: TextStyle(
                      fontSize: isWeb ? 12 : 10,
                      color: kSubText,
                    ),
                  ),
                );
              },
              reservedSize: isWeb ? 60 : 50,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              _controller.chartData.length,
              (index) => FlSpot(
                index.toDouble(),
                _controller.getMonthlyRevenue(index),
              ),
            ),
            isCurved: true,
            color: kPrimary,
            barWidth: isWeb ? 4 : 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: kPrimary.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: List.generate(
              _controller.chartData.length,
              (index) => FlSpot(
                index.toDouble(),
                _controller.getMonthlyExpenses(index),
              ),
            ),
            isCurved: true,
            color: kDanger,
            barWidth: isWeb ? 4 : 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: kDanger.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPieChart(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    if (_controller.expenseCategories.isEmpty) {
      return Center(
        child: Text(
          'No expense data available',
          style: TextStyle(fontSize: isWeb ? 14 : 13, color: kSubText),
        ),
      );
    }
    final total = _controller.expenseCategories.fold(
      0.0,
      (sum, cat) => sum + (cat['amount'] ?? 0).toDouble(),
    );

    return PieChart(
      PieChartData(
        sections: _controller.expenseCategories.asMap().entries.map((entry) {
          final category = entry.value;
          final amount = (category['amount'] ?? 0).toDouble();
          final percentage = total > 0
              ? (amount / total * 100).toStringAsFixed(1)
              : '0';
          final color = _getCategoryColor(category['name'] ?? '');
          return PieChartSectionData(
            value: amount,
            title: '${category['name']}\n$percentage%',
            radius: isWeb ? 80 : 60,
            titleStyle: TextStyle(
              fontSize: isWeb ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            color: color,
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: isWeb ? 40 : 30,
      ),
    );
  }

  String _formatCompactNumber(double value, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rent':
        return kPrimary;
      case 'Salary':
        return kSuccess;
      case 'Utilities':
        return kWarning;
      case 'Supplies':
        return kDanger;
      case 'Marketing':
        return kPrimaryDark;
      default:
        return kPrimary;
    }
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isWeb ? 16 : 14,
          height: isWeb ? 16 : 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isWeb ? 4 : 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: isWeb ? 10 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 14 : 13,
            color: kSubText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCashAndOutstanding(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isWeb ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimary.withOpacity(0.09), kCardBg],
                      ),
                      border: Border.all(color: kBorder.withOpacity(0.7)),
                    ),
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Iconify(
                                Mdi.piggy_bank_outline,
                                size: isWeb ? 24 : 20,
                                color: kPrimary,
                              ),
                              SizedBox(width: isWeb ? 12 : 8),
                              Text(
                                'Cash balance',
                                style: TextStyle(
                                  fontSize: isWeb ? 14 : 13,
                                  color: kSubText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWeb ? 16 : 12),
                          Text(
                            _controller.cashBalanceFormatted.value,
                            style: TextStyle(
                              fontSize: isWeb ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isWeb ? 12 : 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 16 : 12,
                              vertical: isWeb ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kSuccess.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Iconify(
                                  _controller.isCashPositive.value
                                      ? Mdi.trending_up
                                      : Mdi.trending_down,
                                  size: isWeb ? 18 : 16,
                                  color: _controller.isCashPositive.value
                                      ? kSuccess
                                      : kDanger,
                                ),
                                SizedBox(width: isWeb ? 6 : 4),
                                Text(
                                  '${_controller.cashChange.value.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: isWeb ? 15 : 13,
                                    color: _controller.isCashPositive.value
                                        ? kSuccess
                                        : kDanger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: isWeb ? 6 : 4),
                                Text(
                                  'vs last month',
                                  style: TextStyle(
                                    fontSize: isWeb ? 13 : 12,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kBorder.withOpacity(0),
                        kBorder,
                        kBorder.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(isWeb ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [kWarning.withOpacity(0.08), kCardBg],
                      ),
                      border: Border.all(color: kBorder.withOpacity(0.7)),
                    ),
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Outstanding',
                                style: TextStyle(
                                  fontSize: isWeb ? 14 : 13,
                                  color: kSubText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: isWeb ? 12 : 8),
                              Iconify(
                                Mdi.receipt_outline,
                                size: isWeb ? 24 : 20,
                                color: kWarning,
                              ),
                            ],
                          ),
                          SizedBox(height: isWeb ? 16 : 12),
                          Text(
                            _controller.outstandingFormatted.value,
                            style: TextStyle(
                              fontSize: isWeb ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: kWarning,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isWeb ? 12 : 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _currentTab = 2),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWeb ? 12 : 8,
                                vertical: isWeb ? 6 : 4,
                              ),
                              foregroundColor: kPrimary,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Iconify(
                              Mdi.arrow_right,
                              size: isWeb ? 20 : 18,
                            ),
                            label: Text(
                              'View invoices',
                              style: TextStyle(
                                fontSize: isWeb ? 14 : 13,
                                fontWeight: FontWeight.w700,
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
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Obx(() {
      if (_controller.recentTransactions.isEmpty) {
        return const SizedBox.shrink();
      }
      final recent = _controller.recentTransactions.take(4).toList();
      return Container(
        margin: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: kBorder.withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWeb ? 24 : 20,
                isWeb ? 20 : 16,
                isWeb ? 20 : 16,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isWeb ? 16 : 12),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                    ),
                    child: Iconify(
                      Mdi.receipt,
                      color: kPrimary,
                      size: isWeb ? 28 : 24,
                    ),
                  ),
                  SizedBox(width: isWeb ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent activity',
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: kText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Latest cash movements',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 13,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentTab = 1),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: kPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isWeb ? 16 : 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16),
              child: Column(
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
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(() {
      if (_controller.quickActions.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kCardBg, kPrimary.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: kBorder.withOpacity(0.9)),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.06),
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
                Text(
                  'Shortcuts',
                  style: TextStyle(
                    fontSize: isWeb ? 18 : 16,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Expanded(
                  child: Container(height: 1, color: kBorder.withOpacity(0.8)),
                ),
              ],
            ),
            SizedBox(height: isWeb ? 8 : 6),
            Text(
              'Common tasks',
              style: TextStyle(fontSize: isWeb ? 14 : 13, color: kSubText),
            ),
            SizedBox(height: isWeb ? 20 : 16),
            Row(
              children: _controller.quickActions.map((action) {
                final label = action['label'] ?? '';
                final iconName = action['icon'] ?? 'circle';
                final colorHex = action['color'] ?? '#3498DB';
                final color = _controller.getColorFromHex(colorHex);
                return _buildQuickActionButton(
                  context,
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
                        Get.to(CustomersScreen());
                        break;
                      default:
                        AppSnackbar.success(
                          kPrimary,
                          label,
                          '$label module coming soon',
                        );
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
    BuildContext context,
    String label,
    String icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          child: Ink(
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
              border: Border.all(color: color.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isWeb ? 20 : 16,
                horizontal: isWeb ? 8 : 6,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isWeb ? 16 : 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Iconify(icon, color: color, size: isWeb ? 32 : 28),
                  ),
                  SizedBox(height: isWeb ? 12 : 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 13,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildDrawer(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Drawer(
      width: isWeb ? 320 : 280,
      child: Column(
        children: [
          _buildEnhancedDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              addAutomaticKeepAlives: false,
              children: [
                // Navigation Label
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NAVIGATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                _buildExpandableSection(
                  context,
                  'LedgerPro Core',
                  Mdi.account_circle,
                  [
                    'Chart of Accounts',
                    'Journal Entries',
                    'General Ledger',
                    'Trial Balance',
                    'Bank Accounts',
                    'Income',
                    'Expense',
                  ],
                ),
                _buildExpandableSection(
                  context,
                  'Receivables & Payables',
                  Mdi.swap_horizontal,
                  [
                    'Accounts Receivable',
                    'Accounts Payable',
                    'Customers',
                    'bills',
                    'Payments Received',
                    'Payments Made',
                    'Credit Notes',
                  ],
                ),
                _buildExpandableSection(
                  context,
                  'Assets & Liabilities',
                  Mdi.business,
                  ['Fixed Assets', 'Loans & Borrowings', 'Capital / Equity'],
                ),
                _buildExpandableSection(
                  context,
                  'Financial Reports',
                  Mdi.chart_line,
                  [
                    'Profit & Loss Statement',
                    'Balance Sheet',
                    'Cash Flow Statement',
                    'Aged Receivables',
                  ],
                ),
                Divider(height: 1, thickness: 1, color: kBorder),
                _buildExpandableSection(context, 'Settings', Mdi.cog, [
                  'Currency',
                ]),
                _buildExpandableSection(context, 'My Account', Mdi.account, [
                  'My Profile',
                  'Change Password',
                ]),
                _buildExpandableSection(
                  context,
                  'Help & Support',
                  Mdi.help_circle,
                  ['User Guide', 'Contact Support', 'Report an Issue'],
                ),
                _buildExpandableSection(context, 'Feedback', Mdi.feedback, [
                  'Feedback',
                ]),
                _buildExpandableSection(context, 'Subscription', Mdi.crown, [
                  'subscription',
                ]),
                _buildExpandableSection(context, 'About', Mdi.information, [
                  'About App',
                  'Terms of Service',
                  'Privacy Policy',
                ]),
                Divider(height: 1, thickness: 1, color: kBorder),
                _buildLogoutButton(context),
                SizedBox(height: isWeb ? 20 : 16),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: isWeb ? 13 : 12,
                        color: kSubText,
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

  Widget _buildEnhancedDrawerHeader(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, kPrimaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button - same style as warehouse sidebar
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _HoverableIconButton(
                onTap: () => _navigateToDashboardSelection(context),
                icon: Icons.arrow_back_rounded,
                size: 18,
                bgColor: Colors.white.withOpacity(0.15),
                hoverColor: Colors.white.withOpacity(0.25),
                iconColor: Colors.white,
                hoverIconColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Company Info
          Row(
            children: [
              CircleAvatar(
                radius: isWeb ? 32 : 28,
                backgroundColor: Colors.white,
                child: Iconify(
                  Mdi.business,
                  size: isWeb ? 32 : 28,
                  color: kPrimary,
                ),
              ),
              SizedBox(width: isWeb ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        _controller.companyName.value.isEmpty
                            ? 'Company'
                            : _controller.companyName.value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 16 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Obx(
                      () => Text(
                        _controller.userEmail.value.isEmpty
                            ? 'Your Business Name'
                            : _controller.userEmail.value,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isWeb ? 14 : 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 16 : 12),

          // Plan Status
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 16 : 12,
              vertical: isWeb ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            ),
            child: Row(
              children: [
                Iconify(
                  Mdi.shield_account,
                  size: isWeb ? 20 : 18,
                  color: Colors.white70,
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Text(
                  'Plan',
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 13,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    _subscriptionController.hasActiveSubscription.value
                        ? 'Premium Plan'
                        : _subscriptionController.isTrialActive.value
                        ? 'Trial Active'
                        : 'Expired',
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  void _navigateToDashboardSelection(BuildContext context) {
    Get.offAllNamed('/dashboard');
  }

  Widget _buildLogoutButton(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(),
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
                  color: kDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                ),
                child: Iconify(
                  Mdi.logout,
                  size: isWeb ? 22 : 20,
                  color: kDanger,
                ),
              ),
              SizedBox(width: isWeb ? 20 : 16),
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 15,
                    fontWeight: FontWeight.w700,
                    color: kDanger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                IconButton(
                  icon: Iconify(Mdi.close, size: 22),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(color: kBorder),
            SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: kPrimary.withOpacity(0.1),
                child: Iconify(Mdi.account, size: 48, color: kPrimary),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Ahmed Khan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            Text(
              'ahmed@zolatech.com',
              style: TextStyle(fontSize: 14, color: kSubText),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 13,
                  color: kSuccess,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _showEditProfileDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                'Edit Profile',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              AppSnackbar.success(
                kSuccess,
                'Success',
                'Profile updated successfully',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
            onPressed: () {
              SharedPreferences.getInstance().then((prefs) => prefs.clear());
              Get.offAll(() => const LoginScreen());
              AppSnackbar.success(
                kSuccess,
                'Success',
                'Logged out successfully',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    String icon,
    List<String> items,
  ) {
    return ExpandableSection(
      context: context,
      title: title,
      iconName: icon,
      items: items,
    );
  }
}

// ============================================================
// ExpandableSection — Corrected Version
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
          Get.back();
          _navigateToScreen(item);
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
        Get.to(() => const CustomersScreen());
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
        AppSnackbar.success(kPrimary, item, '$item module coming soon');
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

class _HoverableIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final Color bgColor;
  final Color hoverColor;
  final Color iconColor;
  final Color hoverIconColor;

  const _HoverableIconButton({
    required this.onTap,
    required this.icon,
    required this.size,
    required this.bgColor,
    required this.hoverColor,
    required this.iconColor,
    required this.hoverIconColor,
  });

  @override
  State<_HoverableIconButton> createState() => _HoverableIconButtonState();
}

class _HoverableIconButtonState extends State<_HoverableIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              widget.icon,
              key: ValueKey(widget.icon),
              size: widget.size,
              color: _isHovered ? widget.hoverIconColor : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
