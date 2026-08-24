import 'dart:io';

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
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
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/contactsupport/contact_support_screen.dart';
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
import 'package:BisonsTechs_app/core/settings/screens/pdf_report_settings_screen.dart';
import 'package:BisonsTechs_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:BisonsTechs_app/widgets/reload_when_visible.dart';
import 'package:BisonsTechs_app/core/AccountPayable/controller/account_payable_controller.dart';
import 'package:BisonsTechs_app/core/AccountRecievables/controllers/account_recievables_controller.dart';
import 'package:BisonsTechs_app/core/BankAccounts/controllers/bankaccount_controller.dart';
import 'package:BisonsTechs_app/core/Bills/controller/bills_controller.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/controller/equity_controller.dart';
import 'package:BisonsTechs_app/core/CreditNote/controllers/creditnote_controller.dart';
import 'package:BisonsTechs_app/core/Expense/controller/expense_controller.dart';
import 'package:BisonsTechs_app/core/FixedAssets/controllers/fixed_asset_controller.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Controller/general_ledger_controller.dart';
import 'package:BisonsTechs_app/core/Income/controller/income_controller.dart';
import 'package:BisonsTechs_app/core/PaymentMade/controller/paymentmade_controller.dart';
import 'package:BisonsTechs_app/core/TrailBalance/controller/trail_balance_controller.dart';
import 'package:BisonsTechs_app/core/accountingReports/accounting_report_controller.dart';
import 'package:BisonsTechs_app/core/balancesheet/controller/balance_sheet_controller.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/controller/cashflow_controller.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/controller/chart_of_account_controller.dart';
import 'package:BisonsTechs_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:BisonsTechs_app/core/loanBorrowing/controller/loan_controller.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/controller/payment_recieved_controller.dart';
import 'package:BisonsTechs_app/core/profitlossStatement/controllers/profit_and_loss_controller.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/widgets/fiscal_year_select.dart';
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

const _kHeroBg = Color(0xFFE6EEF5);
const _kHeroBgEnd = Color(0xFFD6E4F0);
const _kHeroBorder = Color(0xFFB8CFE0);
const _kHeroIcon = Color(0xFFC5D8E8);
const _kChipBg = Color(0xFFF0F2F8);
const _kAppBarBg = Color(0xFFF7F9FC);

// ─── TOP-LEVEL STATELESS WIDGETS ─────────────────────────────────────────────
// Drawer ko top-level StatelessWidget banaya — har build pe recreate nahi hoga

class _AppBarLogo extends StatelessWidget {
  final DashboardController controller;
  final bool isMobile;
  const _AppBarLogo({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    // Sirf logo value observe karo — baaki sab constant hai
    return Obx(() {
      final logo = controller.businessLogo.value;
      if (logo.isEmpty) {
        return Image.asset(
          'assets/logo.png',
          height: isMobile ? 32 : 36,
          fit: BoxFit.contain,
        );
      }
      return Row(
        children: [
          _LogoAvatar(logo: logo, size: 30),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isMobile ? 'Bisons' : 'BisonsTechs',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      );
    });
  }
}

// Logo widget — reusable, no rebuild triggers
class _LogoAvatar extends StatelessWidget {
  final String logo;
  final double size;
  const _LogoAvatar({required this.logo, required this.size});

  @override
  Widget build(BuildContext context) {
    if (logo.isEmpty) {
      return Image.asset(
        'assets/logo.png',
        width: size * 2.8,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.27),
        child: logo.startsWith('http')
            ? Image.network(
                logo,
                fit: BoxFit.cover,
                width: size,
                height: size,
                cacheWidth: (size * 2).toInt(),
                cacheHeight: (size * 2).toInt(),
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/logo.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              )
            : Image.file(
                File(logo),
                fit: BoxFit.cover,
                width: size,
                height: size,
                cacheWidth: (size * 2).toInt(),
                cacheHeight: (size * 2).toInt(),
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/logo.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}

// ─── CACHED DRAWER ────────────────────────────────────────────────────────────
// Top-level widget — Flutter tree mein stable position, rebuild nahi hoga
class _AppDrawer extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 272,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _DrawerHeader(onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              // addAutomaticKeepAlives false — drawer items lightweight rahenge
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              children: const [
                _SectionLabel('CORE'),
                _NavSection(
                  title: 'Accounting Core',
                  icon: Mdi.account_circle,
                  module: 'accounting',
                  permissions: [
                    'chart-of-accounts',
                    'journal-entries',
                    'general-ledger',
                    'trial-balance',
                    'bank-accounts',
                    'income',
                    'expenses',
                    'chart-of-accounts',
                  ],
                  items: [
                    ('Chart of Accounts', Mdi.chart_tree, 'chart_of_accounts'),
                    ('Journal Entries', Mdi.book_open_page_variant, 'journal_entries'),
                    ('General Ledger', Mdi.book_open_blank_variant, 'general_ledger'),
                    ('Trial Balance', Mdi.scale_balance, 'trial_balance'),
                    ('Bank Accounts', Mdi.bank, 'bank_accounts'),
                    ('Income', Mdi.trending_up, 'income'),
                    ('Expense', Mdi.trending_down, 'expense'),
                    ('Tax Compliance', Mdi.percent, 'tax_compliance'),
                  ],
                ),
                SizedBox(height: 4),
                _SectionLabel('RECEIVABLES & PAYABLES'),
                _NavSection(
                  title: 'Receivables & Payables',
                  icon: Mdi.swap_horizontal,
                  module: 'accounting',
                  permissions: [
                    'accounts-receivable',
                    'accounts-payable',
                    'customers',
                  ],
                  items: [
                    ('Accounts Receivable', Mdi.cash_plus, 'accounts_receivable'),
                    ('Accounts Payable', Mdi.cash_minus, 'accounts_payable'),
                    ('Customers', Mdi.account_group, 'customers'),
                  ],
                ),
                SizedBox(height: 4),
                _SectionLabel('ASSETS & LIABILITIES'),
                _NavSection(
                  title: 'Assets & Liabilities',
                  icon: Mdi.business,
                  module: 'accounting',
                  permissions: [
                    'fixed-assets',
                    'loans-borrowings',
                    'capital-equity',
                  ],
                  items: [
                    ('Fixed Assets', Mdi.office_building_outline, 'fixed_assets'),
                    ('Loans & Borrowings', Mdi.hand_coin_outline, 'loans'),
                    ('Capital / Equity', Mdi.chart_donut, 'capital_equity'),
                  ],
                ),
                SizedBox(height: 4),
                _SectionLabel('FINANCIAL REPORTS'),
                _NavSection(
                  title: 'Financial Reports',
                  icon: Mdi.chart_line,
                  module: 'accounting',
                  permissions: [
                    'journal-entries',
                    'profit-loss',
                    'balance-sheet',
                    'cash-flow',
                    'aged-receivables',
                  ],
                  items: [
                    ('Accounting Reports', Mdi.file_chart, 'accounting_reports'),
                    ('Profit & Loss', Mdi.chart_line, 'profit_loss'),
                    ('Balance Sheet', Mdi.clipboard_list_outline, 'balance_sheet'),
                    ('Cash Flow Statement', Mdi.cash, 'cash_flow'),
                    ('Aged Receivables', Mdi.account_clock, 'aged_receivables'),
                  ],
                ),
                SizedBox(height: 4),
                _SectionLabel('SETTINGS'),
                _NavSection(
                  title: 'Settings',
                  icon: Mdi.cog,
                  module: 'accounting',
                  permissions: ['currency'],
                  items: [
                    ('Fiscal Years', Mdi.calendar_range, 'fiscal_years'),
                    ('Currency', Mdi.currency_usd, 'currency'),
                    ('PDF Reports', Mdi.file_pdf_box, 'pdf_report'),
                  ],
                ),
                _NavSection(
                  title: 'My Account',
                  icon: Mdi.account,
                  items: [
                    ('My Profile', Mdi.account_circle_outline, '__profile'),
                    ('Change Password', Mdi.lock_reset, '__changepassword'),
                  ],
                ),
                SizedBox(height: 4),
                _SectionLabel('SUPPORT'),
                _SubscriptionNavSection(),
                _NavSection(
                  title: 'Help & Support',
                  icon: Mdi.help_circle,
                  items: [
                    ('User Guide', Mdi.book_information_variant, '__userguide'),
                    ('Contact Support', Mdi.headset, '__contact'),
                    ('Report an Issue', Mdi.bug_outline, '__reportissue'),
                  ],
                ),
                _NavSection(
                  title: 'Feedback',
                  icon: Mdi.feedback,
                  items: [('Feedback', Mdi.feedback, 'feedback')],
                ),
                _NavSection(
                  title: 'About',
                  icon: Mdi.information,
                  items: [
                    ('About App', Mdi.information_outline, 'about_app'),
                    ('Terms of Service', Mdi.file_sign, 'terms'),
                    ('Privacy Policy', Mdi.shield_lock_outline, 'privacy'),
                  ],
                ),
              ],
            ),
          ),
          _DrawerFooter(onLogout: onLogout),
        ],
      ),
    );
  }
}

class _SubscriptionNavSection extends StatelessWidget {
  const _SubscriptionNavSection();

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.to.isAdmin) return const SizedBox.shrink();
    return const _NavSection(
      title: 'Subscription',
      icon: Mdi.crown,
      items: [
        ('Subscription Plans', Mdi.crown, 'subscription'),
      ],
    );
  }
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAware, ReloadWhenVisible {
  @override
  void reloadOnOpen() {
    if (!Get.isRegistered<DashboardController>()) return;
    final c = Get.find<DashboardController>();
    if (c.isLoading.value || c.isRefreshing.value) return;
    // First load is onInit — do not fire a second overview call on open.
    if (!c.hasLoadedOnce.value) return;
    c.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) => const _AccountingDashboardView();
}

class _AccountingDashboardView extends GetView<DashboardController> {
  const _AccountingDashboardView();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: _buildAppBar(isMobile),
      // Drawer ab top-level const widget — animation ke waqt rebuild nahi hoga
      drawer: _AppDrawer(
        onBack: () => _navigateToDashboardSelection(context),
        onLogout: _showLogoutDialog,
      ),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value && !controller.hasLoadedOnce.value) {
              return _buildShimmer();
            }
            return RefreshIndicator(
              color: kPrimary,
              backgroundColor: _kCardBg,
              onRefresh: () async {
                await controller.loadDashboardData();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroCard(),
                    const SizedBox(height: 14),
                    const _PeriodChips(),
                    const SizedBox(height: 16),
                    _KpiGrid(isTablet: isTablet),
                    const SizedBox(height: 16),
                    const _CapitalCard(),
                    const SizedBox(height: 16),
                    const _FinancialOverview(),
                    const SizedBox(height: 16),
                    const _RevenueTrendCard(),
                    const SizedBox(height: 16),
                    const _ExpenseCategoriesCard(),
                    const SizedBox(height: 16),
                    const _RecentTransactions(),
                  ],
                ),
              ),
            );
          }),
          // Refresh indicator — sirf ye rebuild hoga jab isRefreshing change ho
          Obx(() {
            if (!controller.isRefreshing.value) return const SizedBox.shrink();
            return const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: kPrimary,
                backgroundColor: Color(0xFFE6EEF5),
              ),
            );
          }),
        ],
      ),
    );
  }

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
                icon: const Icon(Icons.menu_rounded, color: _kTextPrimary, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null,
      titleSpacing: isMobile ? 0 : NavigationToolbar.kMiddleSpacing,
      // AppBar title: Obx sirf logo observe karta hai — text constant hai
      title: _AppBarLogo(controller: controller, isMobile: isMobile),
      actions: [
        FiscalYearSelect(compact: true, showManageLink: !isMobile),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: _kTextSub, size: 22),
          onPressed: () => Get.to(() => const NotificationScreen()),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

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
                  child: _shimmerBox(height: 34, width: 80 + (i * 10).toDouble(), radius: 20),
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

  void _navigateToDashboardSelection(BuildContext context) {
    Get.offAllNamed('/dashboard');
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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

// ─── SECTION CARD ─────────────────────────────────────────────────────────────
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

// ─── HERO CARD ────────────────────────────────────────────────────────────────
// Separate StatelessWidget — controller se directly observe karta hai
class _HeroCard extends GetView<DashboardController> {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logo = controller.businessLogo.value;
      final hasLogo = logo.isNotEmpty;
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
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            )
                          : Image.file(
                              File(logo),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                                      Icons.account_balance_wallet_rounded,
                                      size: 14,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Net Profit · ${controller.periodLabel}',
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
                                controller.netProfitFormatted.value,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: controller.netProfit.value >= 0 ? _kTextPrimary : _kRed,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${controller.totalRevenueFormatted.value} − ${controller.totalExpensesFormatted.value}',
                                style: const TextStyle(fontSize: 11, color: _kTextSub, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: controller.netProfit.value >= 0 ? _kGreenBg : _kRedBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      controller.netProfit.value >= 0
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 10,
                                      color: controller.netProfit.value >= 0 ? _kGreen : _kRed,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      controller.netProfit.value >= 0
                                          ? '${controller.profitMargin.value.abs().toStringAsFixed(1)}% margin'
                                          : 'Expenses exceed revenue',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: controller.netProfit.value >= 0 ? _kGreen : _kRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.refreshData(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kHeroIcon,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kHeroBorder),
                            ),
                            child: const Icon(Icons.refresh_rounded, size: 16, color: _kTextSub),
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
                          controller.totalRevenueFormatted.value,
                          Icons.trending_up_rounded,
                          _kGreen,
                          _kGreenBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Bank Balance',
                          controller.totalBankBalanceFormatted.value,
                          Icons.account_balance_rounded,
                          kPrimary,
                          _kPrimaryBg,
                        ),
                        _heroDivider(),
                        _heroStat(
                          'Payables',
                          controller.payablesFormatted.value,
                          Icons.receipt_long_rounded,
                          _kRed,
                          _kRedBg,
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

  Widget _heroStat(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: _kTextMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(width: 0.5, height: 44, color: _kCardBorder);
}

// ─── PERIOD CHIPS ─────────────────────────────────────────────────────────────
class _PeriodChips extends GetView<DashboardController> {
  const _PeriodChips();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedTimePeriod.value;
      return SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: DashboardController.timePeriodLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final period = DashboardController.timePeriodLabels[i];
            final isActive = period == selected;
            final label = period == 'Custom' && isActive ? controller.periodLabel : period;
            return GestureDetector(
              onTap: () async {
                if (period == 'Custom') {
                  await _pickCustomDateRange(context);
                  return;
                }
                await controller.loadDashboardData(timePeriod: period);
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

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = controller.customStartDate.value ?? DateTime(now.year, now.month, 1);
    final initialEnd = controller.customEndDate.value ?? DateTime(now.year, now.month, now.day);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
    await controller.loadDashboardData(
      timePeriod: 'Custom',
      customStart: range.start,
      customEnd: range.end,
    );
  }
}

// ─── KPI GRID ─────────────────────────────────────────────────────────────────
class _KpiGrid extends GetView<DashboardController> {
  final bool isTablet;
  const _KpiGrid({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final kpis = [
        _KpiItem(
          label: 'Revenue',
          value: controller.totalRevenueFormatted.value,
          icon: Icons.trending_up_rounded,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: controller.formatTrend(controller.revenueChange.value),
          trendUp: controller.isRevenuePositive.value,
        ),
        _KpiItem(
          label: 'Expenses',
          value: controller.totalExpensesFormatted.value,
          icon: Icons.trending_down_rounded,
          iconBg: _kRedBg,
          iconColor: _kRed,
          trend: controller.formatTrend(controller.expenseChange.value),
          trendUp: controller.isExpensePositive.value,
        ),
        _KpiItem(
          label: 'Bank Balance',
          value: controller.totalBankBalanceFormatted.value,
          icon: Icons.account_balance_rounded,
          iconBg: _kPrimaryBg,
          iconColor: kPrimary,
          trend: controller.bankAccountsCount.value > 0
              ? '${controller.bankAccountsCount.value} accounts'
              : 'No accounts',
          trendUp: controller.isCashPositive.value,
        ),
        _KpiItem(
          label: 'Cash',
          value: controller.totalCashBalanceFormatted.value,
          icon: Icons.payments_outlined,
          iconBg: _kGreenBg,
          iconColor: _kGreen,
          trend: 'Cash in Hand',
          trendUp: controller.totalCashBalance.value >= 0,
        ),
        _KpiItem(
          label: 'Receivables',
          value: controller.outstandingFormatted.value,
          icon: Icons.hourglass_empty_rounded,
          iconBg: _kOrangeBg,
          iconColor: _kOrange,
          trend: controller.outstandingCount.value > 0
              ? '${controller.outstandingCount.value} open'
              : 'Clear',
          trendUp: controller.outstanding.value <= 0,
        ),
      ];

      final crossCount = isTablet ? 4 : 2;
      const spacing = 10.0;

      return LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: kpis.map((item) {
              return SizedBox(
                width: itemWidth,
                child: AspectRatio(
                  aspectRatio: isTablet ? 1.2 : 1.55,
                  child: _KpiCard(item: item),
                ),
              );
            }).toList(),
          );
        },
      );
    });
  }
}

// ─── KPI CARD ─────────────────────────────────────────────────────────────────
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
                      item.trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary, letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(item.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kTextSub)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CAPITAL CARD ─────────────────────────────────────────────────────────────
class _CapitalCard extends GetView<DashboardController> {
  const _CapitalCard();

  double _asChartDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final up = controller.isCapitalIncrease.value;
      final rows = controller.capitalChart;
      final labels = <String>[];
      final openingSpots = <FlSpot>[];
      final capitalSpots = <FlSpot>[];

      if (rows.isEmpty) {
        labels.addAll(['Start', 'Now']);
        openingSpots.addAll([
          FlSpot(0, controller.openingCapital.value),
          FlSpot(1, controller.openingCapital.value),
        ]);
        capitalSpots.addAll([
          FlSpot(0, controller.openingCapital.value),
          FlSpot(1, controller.openingCapital.value + controller.periodEarnings.value),
        ]);
      } else {
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          final month = row['month']?.toString() ?? row['label']?.toString() ?? '';
          if (month.contains(' ') && !RegExp(r'\d{4}').hasMatch(month)) {
            labels.add(month);
          } else if (month.length > 3) {
            labels.add(month.substring(0, 3));
          } else {
            labels.add(month);
          }
          openingSpots.add(FlSpot(i.toDouble(), _asChartDouble(row['opening'])));
          capitalSpots.add(FlSpot(i.toDouble(), _asChartDouble(row['capital'])));
        }
      }

      final ys = [...openingSpots.map((s) => s.y), ...capitalSpots.map((s) => s.y)];
      final rawMin = ys.fold<double>(0, (a, b) => b < a ? b : a);
      final rawMax = ys.fold<double>(0, (a, b) => b > a ? b : a);
      final minY = rawMin >= 0 ? 0.0 : rawMin * 1.2;
      final span = (rawMax - minY).abs();
      final maxY = span < 1 ? (rawMax.abs() < 1 ? 1.0 : rawMax * 1.2) : rawMax * 1.12;

      return _SectionCard(
        title: 'Capital & earnings',
        trailing: Text(controller.periodLabel, style: const TextStyle(fontSize: 11, color: _kTextSub)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _capitalStat(
                    'Your capital', controller.openingCapitalFormatted.value,
                    kPrimary, _kPrimaryBg, Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _capitalStat(
                    up ? 'Earned this period' : 'Decreased this period',
                    controller.periodEarningsFormatted.value,
                    up ? _kGreen : _kRed, up ? _kGreenBg : _kRedBg,
                    up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _capitalStat(
                    'Equity now', controller.currentEquityFormatted.value,
                    _kPurple, _kPurpleBg, Icons.pie_chart_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              up
                  ? 'This period earned ${controller.periodEarningsFormatted.value} on your capital.'
                  : 'This period reduced capital by ${CurrencyUtils.format(controller.periodEarnings.value.abs())}.',
              style: TextStyle(fontSize: 11, color: up ? _kGreen : _kRed, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _legendDot(kPrimary, 'Your capital'),
                const SizedBox(width: 12),
                _legendDot(_kPurple, 'Equity now'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY <= minY ? minY + 1 : maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(color: _kCardBorder, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) {
                            final lbl = v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString();
                            return Text(lbl, style: const TextStyle(fontSize: 9, color: _kTextSub));
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
                              child: Text(labels[i], style: const TextStyle(fontSize: 9, color: _kTextSub)),
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
                        getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                          CurrencyUtils.format(s.y),
                          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        )).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: openingSpots,
                        isCurved: false,
                        color: kPrimary,
                        barWidth: 2,
                        dashArray: const [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: capitalSpots,
                        isCurved: true,
                        color: _kPurple,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: capitalSpots.length <= 8,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: _kPurple, strokeWidth: 0),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_kPurple.withOpacity(0.16), _kPurple.withOpacity(0.0)],
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
    });
  }

  Widget _capitalStat(String label, String value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─── FINANCIAL OVERVIEW ───────────────────────────────────────────────────────
class _FinancialOverview extends GetView<DashboardController> {
  const _FinancialOverview();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final maxVal = [
        controller.totalRevenue.value,
        controller.totalSales.value,
        controller.totalPurchases.value,
        controller.totalExpenses.value,
        controller.totalBankBalance.value,
        controller.totalCashBalance.value,
        controller.outstanding.value,
        controller.payables.value,
        controller.netProfit.value.abs(),
      ].fold<double>(0, (a, b) => b > a ? b : a);

      final bars = [
        _BarItem('Revenue', controller.totalRevenueFormatted.value, controller.totalRevenue.value, _kGreen, _kGreenBg, 'Sales + Income − Credit Notes'),
        _BarItem('Sales', controller.totalSalesFormatted.value, controller.totalSales.value, kPrimary, _kPrimaryBg,
          controller.salesCount.value > 0 ? '${controller.salesCount.value} invoice(s) · Paid amount' : 'Warehouse Invoices Paid (Sales)'),
        _BarItem('Purchases', controller.totalPurchasesFormatted.value, controller.totalPurchases.value, _kOrange, _kOrangeBg, 'Purchase invoices (period)'),
        _BarItem('Expenses', controller.totalExpensesFormatted.value, controller.totalExpenses.value, _kRed, _kRedBg, 'Expense screen Posted (period)'),
        _BarItem('Bank Balance', controller.totalBankBalanceFormatted.value, controller.totalBankBalance.value, kPrimary, _kPrimaryBg, 'Bank Accounts'),
        _BarItem('Cash', controller.totalCashBalanceFormatted.value, controller.totalCashBalance.value, _kGreen, _kGreenBg, 'Cash in Hand (Chart of Accounts)'),
        _BarItem('Receivables', controller.outstandingFormatted.value, controller.outstanding.value, _kOrange, _kOrangeBg, 'Sales invoices outstanding'),
        _BarItem('Payables', controller.payablesFormatted.value, controller.payables.value, _kOrange, _kOrangeBg, 'Bills + Purchase invoices'),
        _BarItem('Net Profit', controller.netProfitFormatted.value, controller.netProfit.value.abs(),
          controller.netProfit.value >= 0 ? _kGreen : _kRed,
          controller.netProfit.value >= 0 ? _kGreenBg : _kRedBg, 'Revenue − Expenses'),
      ];

      return _SectionCard(
        title: 'Financial overview',
        trailing: Text(controller.periodLabel, style: const TextStyle(fontSize: 12, color: _kTextSub)),
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
            width: 32, height: 32,
            decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(8)),
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
                          Text(item.label, style: const TextStyle(fontSize: 11, color: _kTextSub, fontWeight: FontWeight.w500)),
                          if (item.source.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(item.source, style: const TextStyle(fontSize: 9, color: _kTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    Text(item.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction, minHeight: 5,
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
}

// ─── REVENUE TREND CARD ───────────────────────────────────────────────────────
class _RevenueTrendCard extends GetView<DashboardController> {
  const _RevenueTrendCard();

  double _asChartDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.chartData;
      final List<double> revenueData = [];
      final List<double> expenseData = [];
      final List<String> labels = [];

      if (rows.isNotEmpty) {
        for (final row in rows) {
          revenueData.add(_asChartDouble(row['revenue']));
          expenseData.add(_asChartDouble(row['expenses']));
          final month = row['month']?.toString() ?? '';
          if (month.contains(' ') && !RegExp(r'\d{4}').hasMatch(month)) {
            labels.add(month);
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

      final maxA = revenueData.isEmpty ? 0.0 : revenueData.reduce((a, b) => a > b ? a : b);
      final maxB = expenseData.isEmpty ? 0.0 : expenseData.reduce((a, b) => a > b ? a : b);
      final maxY = (maxA > maxB ? maxA : maxB) * 1.2;

      return _SectionCard(
        title: 'Revenue trend',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.periodLabel, style: const TextStyle(fontSize: 11, color: _kTextSub)),
            const SizedBox(width: 10),
            _legendDot(_kGreen, 'Revenue'),
            const SizedBox(width: 12),
            _legendDot(_kRed, 'Expenses'),
          ],
        ),
        child: SizedBox(
          height: 190,
          child: RepaintBoundary(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: _kCardBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) {
                        final lbl = v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString();
                        return Text(lbl, style: const TextStyle(fontSize: 9, color: _kTextSub));
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
                          child: Text(labels[i], style: const TextStyle(fontSize: 9, color: _kTextSub)),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        ),
      );
    });
  }

  LineChartBarData _buildTrendLine(List<double> data, Color color) {
    return LineChartBarData(
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
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

// ─── EXPENSE CATEGORIES CARD ──────────────────────────────────────────────────
class _ExpenseCategoriesCard extends GetView<DashboardController> {
  const _ExpenseCategoriesCard();

  double _asChartDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = controller.expenseCategories.where((c) => _asChartDouble(c['amount']) > 0).toList();
      const palette = [kPrimary, _kPurple, _kOrange, _kGreen, _kRed, Color(0xFF0891B2), Color(0xFFEC4899)];
      final total = cats.fold<double>(0, (s, c) => s + _asChartDouble(c['amount']));

      return _SectionCard(
        title: 'Expenses by category',
        trailing: Text(
          cats.isEmpty ? 'No data · ${controller.periodLabel}' : '${cats.length} types · ${controller.periodLabel}',
          style: const TextStyle(fontSize: 12, color: _kTextSub),
        ),
        child: SizedBox(
          height: 180,
          child: cats.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: RepaintBoundary(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 38,
                            sections: cats.take(7).toList().asMap().entries.map((entry) {
                              final amount = _asChartDouble(entry.value['amount']);
                              final color = palette[entry.key % palette.length];
                              return PieChartSectionData(
                                color: color,
                                value: amount,
                                title: total > 0 ? '${((amount / total) * 100).round()}%' : '',
                                radius: 34,
                                titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cats.take(6).toList().asMap().entries.map((entry) {
                          final c = entry.value;
                          final color = palette[entry.key % palette.length];
                          final name = c['name']?.toString() ?? 'Other';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 11, color: _kTextSub), overflow: TextOverflow.ellipsis),
                                ),
                                Text(
                                  _asChartDouble(c['percentage']).toStringAsFixed(0),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kTextPrimary),
                                ),
                                const Text('%', style: TextStyle(fontSize: 10, color: _kTextSub)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              : const Center(child: Text('No expense categories yet', style: TextStyle(fontSize: 13, color: _kTextSub))),
        ),
      );
    });
  }
}

// ─── RECENT TRANSACTIONS ──────────────────────────────────────────────────────
class _RecentTransactions extends GetView<DashboardController> {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recentTransactions.isEmpty) return const SizedBox.shrink();
      final recent = controller.recentTransactions.take(4).toList();

      return _SectionCard(
        title: 'Recent activity',
        child: Column(
          children: recent.asMap().entries.map((e) {
            final tx = e.value;
            final isLast = e.key == recent.length - 1;
            final date = tx['date'] is DateTime ? tx['date'] : DateTime.parse(tx['date']);
            final type = tx['type'] as String? ?? '';
            final source = tx['source'] as String? ?? '';
            final amount = (tx['amount'] ?? 0).toDouble();
            final title = tx['title'] ?? '';
            final isPayment = type == 'payment' || source == 'payment_received';
            final isIncome = type == 'income' || isPayment;
            final isPurchase = type == 'purchase' || source == 'bill';
            final amtColor = isIncome ? _kGreen : _kRed;
            final iconBg = isPayment ? _kPrimaryBg : (isIncome ? _kGreenBg : (isPurchase ? _kOrangeBg : _kRedBg));
            final typeLabel = isPayment ? 'Payment' : (isIncome ? 'Income' : (isPurchase ? 'Purchase' : 'Expense'));
            final typeColor = isPayment ? kPrimary : (isIncome ? _kGreen : (isPurchase ? _kOrange : _kRed));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 18, color: amtColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 11, color: _kTextMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'} ${CurrencyUtils.format(amount)}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: amtColor),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(typeLabel, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, thickness: 0.5, color: _kCardBorder),
              ],
            );
          }).toList(),
        ),
      );
    });
  }
}

// ─── LEGEND DOT (shared helper) ───────────────────────────────────────────────
Widget _legendDot(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: _kTextSub)),
    ],
  );
}

// ─── BAR ITEM MODEL ───────────────────────────────────────────────────────────
class _BarItem {
  final String label;
  final String value;
  final double rawValue;
  final Color color;
  final Color bgColor;
  final String source;

  const _BarItem(this.label, this.value, this.rawValue, this.color, this.bgColor, [this.source = '']);
}

// ─── DRAWER HEADER ────────────────────────────────────────────────────────────
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
              child: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Logo: Obx sirf logo observe karta hai
              Obx(() {
                final logo = controller.businessLogo.value;
                return _LogoAvatar(logo: logo, size: 40);
              }),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company name: apna Obx
                    Obx(() => Text(
                      controller.companyName.value.isEmpty ? 'Company' : controller.companyName.value,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    )),
                    const Text('Accounting Dashboard', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          if (PermissionService.to.isAdmin) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: Colors.white60),
                  const SizedBox(width: 6),
                  const Text('Current plan', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  const Spacer(),
                  // Subscription badge: apna Obx
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kTextMuted, letterSpacing: 1.0),
      ),
    );
  }
}

// ─── NAV SECTION ──────────────────────────────────────────────────────────────
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
  late final List<(String, String, String)> _filteredItems;

  @override
  void initState() {
    super.initState();
    // Permission filter ek baar initState mein — har build pe nahi
    _filteredItems = _computeFilteredItems();
  }

  List<(String, String, String)> _computeFilteredItems() {
    if (widget.module == null || widget.permissions == null) return widget.items;
    final permissionService = PermissionService.to;
    if (permissionService.isAdmin) return widget.items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      if (i < widget.permissions!.length &&
          permissionService.hasSubPageAccess(widget.module!, widget.permissions![i])) {
        filtered.add(widget.items[i]);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Header tap — sirf setState, koi Obx nahi
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Iconify(widget.icon, size: 18, color: _expanded ? kPrimary : Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _expanded ? kPrimary : Colors.black87),
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _expanded ? kPrimary : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Column(
            // addAutomaticKeepAlives: false — nav items lightweight
            children: _filteredItems.map((item) => _NavItem(label: item.$1, icon: item.$2, routeKey: item.$3)).toList(),
          ),
      ],
    );
  }
}

// ─── NAV ITEM ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final String routeKey;

  const _NavItem({required this.label, required this.icon, required this.routeKey});

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
              width: 2, height: 14,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.35), borderRadius: BorderRadius.circular(2)),
            ),
            Iconify(icon, size: 16, color: kPrimary.withOpacity(0.75)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextPrimary), overflow: TextOverflow.ellipsis),
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
          Get.to(() => const ContactSupportScreen());
          break;
        case '__reportissue':
          Get.to(() => const ReportIssueScreen());
          break;
        default:
          Get.snackbar('Coming soon', '$label coming soon');
      }
    } else {
      switch (routeKey) {
        case 'tax_compliance':
          if (Get.isRegistered<TaxController>()) Get.find<TaxController>().loadAll();
          Get.to(() => const TaxComplianceScreen());
          break;
        case 'chart_of_accounts':
          openFresh<ChartOfAccountController>(const ChartOfAccountsScreen());
          break;
        case 'journal_entries':
          openFresh<JournalEntryController>(const JournalEntriesScreen());
          break;
        case 'general_ledger':
          openFresh<GeneralLedgerController>(const GeneralLedgerScreen());
          break;
        case 'trial_balance':
          openFresh<TrialBalanceController>(const TrialBalanceScreen());
          break;
        case 'bank_accounts':
          openFresh<BankAccountController>(const BankAccountsScreen());
          break;
        case 'income':
          openFresh<IncomeController>(const IncomeScreen());
          break;
        case 'expense':
          openFresh<ExpenseController>(const ExpenseScreen());
          break;
        case 'accounts_receivable':
          openFresh<AccountsReceivableController>(const AccountsReceivableScreen());
          break;
        case 'accounts_payable':
          openFresh<AccountsPayableController>(const AccountsPayableScreen());
          break;
        case 'customers':
          openFresh<WarehouseCustomerController>(const WarehouseCustomerScreen());
          break;
        case 'bills':
          openFresh<BillController>(const BillsScreen());
          break;
        case 'payments_received':
          openFresh<PaymentReceivedController>(const PaymentsReceivedScreen());
          break;
        case 'payments_made':
          openFresh<PaymentMadeController>(const PaymentsMadeScreen());
          break;
        case 'credit_notes':
          openFresh<CreditNoteController>(const CreditNotesScreen());
          break;
        case 'fixed_assets':
          openFresh<FixedAssetController>(const FixedAssetsScreen());
          break;
        case 'loans':
          openFresh<LoanController>(const LoansBorrowingsScreen());
          break;
        case 'capital_equity':
          openFresh<EquityController>(const CapitalEquityScreen());
          break;
        case 'accounting_reports':
          if (Get.isRegistered<AccountingReportController>()) {
            Get.delete<AccountingReportController>(force: true);
          }
          Get.toNamed('/accounting/reports');
          break;
        case 'profit_loss':
          openFresh<PLController>(const ProfitLossStatementScreen());
          break;
        case 'balance_sheet':
          openFresh<BalanceSheetController>(const BalanceSheetScreen());
          break;
        case 'cash_flow':
          openFresh<CashFlowController>(const CashFlowStatementScreen());
          break;
        case 'aged_receivables':
          Get.to(() => const AgedReceivablesScreen());
          break;
        case 'warehouse_invoices':
          openFresh<WarehouseInvoiceController>(const WarehouseInvoiceScreen());
          break;
        case 'currency':
          Get.to(() => const CurrencyScreen());
          break;
        case 'fiscal_years':
          Get.to(() => const FiscalYearListScreen());
          break;
        case 'pdf_report':
          openFresh<PdfReportSettingsController>(const PdfReportSettingsScreen());
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

// ─── DRAWER FOOTER ────────────────────────────────────────────────────────────
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        controller.companyName.value.isEmpty ? 'Company' : controller.companyName.value,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      )),
                      if (PermissionService.to.isAdmin)
                        Obx(() => Text(
                          subscriptionController.hasActiveSubscription.value
                              ? 'Premium Account'
                              : subscriptionController.isTrialActive.value
                              ? 'Trial Account'
                              : 'Free Account',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: _kGreenBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Active', style: TextStyle(fontSize: 9, color: _kGreen, fontWeight: FontWeight.w700)),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: _kRed, size: 16),
                  SizedBox(width: 8),
                  Text('Sign out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kRed)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
