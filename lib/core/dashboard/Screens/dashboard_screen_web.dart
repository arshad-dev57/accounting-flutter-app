import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
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
import 'package:LedgerPro_app/core/settings/screens/currency_screen.dart';
import 'package:LedgerPro_app/core/companyprofile/controller/profile_controller.dart';
import 'package:LedgerPro_app/core/companyprofile/screen/company_profile_screen.dart';
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
import 'package:fl_chart/fl_chart.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPageBg = Color(0xFFF5F6FA);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardBorder = Color(0xFFE8EAF0);
const _kTextPrimary = Color(0xFF1A1D2E);
const _kTextSecondary = Color(0xFF8B90A7);
const _kBlue = Color.fromARGB(255, 74, 173, 215);
const _kBlueDark = Color.fromARGB(255, 74, 173, 215);
const _kGreen = Color(0xFF2DC653);
const _kOrange = Color(0xFFF4A228);
const _kRed = Color(0xFFEF4444);
const _kPurple = Color(0xFF9B59B6);

class _SidebarSection {
  final String icon;
  final String label;
  final List<_SidebarItem>? children;
  final VoidCallback? onTap;
  final String routeName;
  const _SidebarSection({
    required this.icon,
    required this.label,
    this.children,
    this.onTap,
    this.routeName = '',
  });
}

class _SidebarItem {
  final String icon;
  final String label;
  final String routeName;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.routeName,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class WebDashboardScreen extends StatefulWidget {
  const WebDashboardScreen({super.key});
  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  bool _sidebarCollapsed = false;
  late final DashboardController _ctrl;
  late final SubscriptionController _subCtrl;
  late final ProfileController _profileCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(DashboardController());
    _subCtrl = Get.find<SubscriptionController>();
    _profileCtrl = Get.put(ProfileController());
    _ctrl.currentScreen.value = _DashboardBody(
      ctrl: _ctrl,
      subCtrl: _subCtrl,
      profileCtrl: _profileCtrl,
      onNavigate: _changeScreen,
    );
    _ctrl.currentRoute.value = 'dashboard';
  }

  void _changeScreen(Widget screen, {String route = 'dashboard'}) {
    _ctrl.navigateTo(screen, route: route);
  }

  String _getTitleForScreen(Widget? screen) {
    if (screen is _DashboardBody) return 'Dashboard';
    if (screen is IncomeScreen) return 'Income';
    if (screen is ExpenseScreen) return 'Expense';
    if (screen is ProfitLossStatementScreen) return 'Profit & Loss Statement';
    if (screen is BalanceSheetScreen) return 'Balance Sheet';
    if (screen is CashFlowStatementScreen) return 'Cash Flow Statement';
    if (screen is AgedReceivablesScreen) return 'Aged Receivables';
    if (screen is ChartOfAccountsScreen) return 'Chart of Accounts';
    if (screen is JournalEntriesScreen) return 'Journal Entries';
    if (screen is GeneralLedgerScreen) return 'General Ledger';
    if (screen is TrialBalanceScreen) return 'Trial Balance';
    if (screen is BankAccountsScreen) return 'Bank Accounts';
    if (screen is AccountsReceivableScreen) return 'Accounts Receivable';
    if (screen is AccountsPayableScreen) return 'Accounts Payable';
    if (screen is CustomersScreen) return 'Customers';
    if (screen is BillsScreen) return 'Bills';
    if (screen is VendorsScreen) return 'Vendors / Suppliers';
    if (screen is PaymentsReceivedScreen) return 'Payments Received';
    if (screen is PaymentsMadeScreen) return 'Payments Made';
    if (screen is CreditNotesScreen) return 'Credit Notes';
    if (screen is FixedAssetsScreen) return 'Fixed Assets';
    if (screen is LoansBorrowingsScreen) return 'Loans & Borrowings';
    if (screen is CapitalEquityScreen) return 'Capital / Equity';
    if (screen is TermsOfServiceScreen) return 'Terms of Service';
    if (screen is PrivacyPolicyScreen) return 'Privacy Policy';
    if (screen is AboutAppScreen) return 'About App';
    if (screen is ChangePasswordScreen) return 'Change Password';
    if (screen is ProfileScreen) return 'My Profile';
    if (screen is SelectPlanScreen) return 'Subscription';
    if (screen is CurrencyScreen) return 'Currency Settings';
    if (screen is UserGuideScreen) return 'User Guide';
    if (screen is ContactScreen) return 'Contact Support';
    if (screen is ReportIssueScreen) return 'Report an Issue';
    if (screen is FeedbackScreen) return 'Feedback';
    return 'LedgerPro';
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kCardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.logout_rounded, color: _kRed, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to sign out of LedgerPro?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextSecondary,
                        side: const BorderSide(color: _kCardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Get.offAll(() => const LoginScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Row(
        children: [
          _WebSidebar(
            collapsed: _sidebarCollapsed,
            ctrl: _ctrl,
            subCtrl: _subCtrl,
            profileCtrl: _profileCtrl,
            onToggle: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onLogout: _showLogoutDialog,
            onChangeScreen: _changeScreen,
          ),
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => _TopBar(
                    ctrl: _ctrl,
                    profileCtrl: _profileCtrl,
                    title: _getTitleForScreen(_ctrl.currentScreen.value),
                    onLogout: _showLogoutDialog,
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => _ctrl.currentScreen.value ?? const SizedBox.shrink(),
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

// ══════════════════════════════════════════════════════════════════════════════
class _WebSidebar extends StatelessWidget {
  final bool collapsed;
  final DashboardController ctrl;
  final SubscriptionController subCtrl;
  final ProfileController profileCtrl;
  final VoidCallback onToggle;
  final VoidCallback onLogout;
  final Function(Widget, {String route}) onChangeScreen;

  _WebSidebar({
    required this.collapsed,
    required this.ctrl,
    required this.subCtrl,
    required this.profileCtrl,
    required this.onToggle,
    required this.onLogout,
    required this.onChangeScreen,
  });

  final List<_SidebarSection> _sections = const [
    _SidebarSection(
      icon: Mdi.view_dashboard,
      label: 'Dashboard',
      routeName: 'dashboard',
    ),
    _SidebarSection(
      icon: Mdi.account_circle,
      label: 'LedgerPro Core',
      children: [
        _SidebarItem(
          icon: Mdi.chart_tree,
          label: 'Chart of Accounts',
          routeName: 'chart_of_accounts',
        ),
        _SidebarItem(
          icon: Mdi.book_open_page_variant,
          label: 'Journal Entries',
          routeName: 'journal_entries',
        ),
        _SidebarItem(
          icon: Mdi.book_open_blank_variant,
          label: 'General Ledger',
          routeName: 'general_ledger',
        ),
        _SidebarItem(
          icon: Mdi.scale_balance,
          label: 'Trial Balance',
          routeName: 'trial_balance',
        ),
        _SidebarItem(
          icon: Mdi.bank,
          label: 'Bank Accounts',
          routeName: 'bank_accounts',
        ),
        _SidebarItem(
          icon: Mdi.trending_up,
          label: 'Income',
          routeName: 'income',
        ),
        _SidebarItem(
          icon: Mdi.trending_down,
          label: 'Expense',
          routeName: 'expense',
        ),
      ],
    ),
    _SidebarSection(
      icon: Mdi.swap_horizontal,
      label: 'Receivables & Payables',
      children: [
        _SidebarItem(
          icon: Mdi.cash_plus,
          label: 'Accounts Receivable',
          routeName: 'accounts_receivable',
        ),
        _SidebarItem(
          icon: Mdi.cash_minus,
          label: 'Accounts Payable',
          routeName: 'accounts_payable',
        ),
        _SidebarItem(
          icon: Mdi.account_group,
          label: 'Customers',
          routeName: 'customers',
        ),
        _SidebarItem(
          icon: Mdi.file_document_outline,
          label: 'Bills',
          routeName: 'bills',
        ),
        _SidebarItem(
          icon: Mdi.truck_delivery_outline,
          label: 'Vendors / Suppliers',
          routeName: 'vendors',
        ),
        _SidebarItem(
          icon: Mdi.credit_card_outline,
          label: 'Payments Received',
          routeName: 'payments_received',
        ),
        _SidebarItem(
          icon: Mdi.cash_check,
          label: 'Payments Made',
          routeName: 'payments_made',
        ),
        _SidebarItem(
          icon: Mdi.file_undo_outline,
          label: 'Credit Notes',
          routeName: 'credit_notes',
        ),
      ],
    ),
    _SidebarSection(
      icon: Mdi.business,
      label: 'Assets & Liabilities',
      children: [
        _SidebarItem(
          icon: Mdi.office_building_outline,
          label: 'Fixed Assets',
          routeName: 'fixed_assets',
        ),
        _SidebarItem(
          icon: Mdi.hand_coin_outline,
          label: 'Loans & Borrowings',
          routeName: 'loans',
        ),
        _SidebarItem(
          icon: Mdi.chart_donut,
          label: 'Capital / Equity',
          routeName: 'capital_equity',
        ),
      ],
    ),
    _SidebarSection(
      icon: Mdi.chart_line,
      label: 'Financial Reports',
      children: [
        _SidebarItem(
          icon: Mdi.chart_line,
          label: 'Profit & Loss',
          routeName: 'profit_loss',
        ),
        _SidebarItem(
          icon: Mdi.clipboard_list_outline,
          label: 'Balance Sheet',
          routeName: 'balance_sheet',
        ),
        _SidebarItem(
          icon: Mdi.cash,
          label: 'Cash Flow Statement',
          routeName: 'cash_flow',
        ),
        _SidebarItem(
          icon: Mdi.account_clock,
          label: 'Aged Receivables',
          routeName: 'aged_receivables',
        ),
      ],
    ),
    _SidebarSection(
      icon: Mdi.cog,
      label: 'Settings',
      children: [
        _SidebarItem(
          icon: Mdi.currency_usd,
          label: 'Currency',
          routeName: 'currency',
        ),
      ],
    ),
    _SidebarSection(
      icon: Mdi.crown,
      label: 'Subscription',
      routeName: 'subscription',
    ),
    _SidebarSection(
      icon: Mdi.message_draw,
      label: 'Feedback',
      routeName: 'feedback',
    ),
    _SidebarSection(
      icon: Mdi.information,
      label: 'About',
      children: [
        _SidebarItem(
          icon: Mdi.information_outline,
          label: 'About App',
          routeName: 'about_app',
        ),
        _SidebarItem(
          icon: Mdi.file_sign,
          label: 'Terms of Service',
          routeName: 'terms',
        ),
        _SidebarItem(
          icon: Mdi.shield_lock_outline,
          label: 'Privacy Policy',
          routeName: 'privacy',
        ),
      ],
    ),
  ];

  final Map<int, RxBool> _expandedStates = {};

  bool _isExpanded(int index) {
    if (!_expandedStates.containsKey(index)) {
      _expandedStates[index] = false.obs;
    }
    return _expandedStates[index]!.value;
  }

  void _toggleExpanded(int index) {
    if (!_expandedStates.containsKey(index)) {
      _expandedStates[index] = false.obs;
    }
    _expandedStates[index]!.toggle();
  }

  Widget _getScreenForRoute(String routeName) {
    switch (routeName) {
      case 'dashboard':
        return _DashboardBody(
          ctrl: ctrl,
          subCtrl: subCtrl,
          profileCtrl: profileCtrl,
          onNavigate: onChangeScreen,
        );
      case 'chart_of_accounts':
        return const ChartOfAccountsScreen();
      case 'journal_entries':
        return const JournalEntriesScreen();
      case 'general_ledger':
        return const GeneralLedgerScreen();
      case 'trial_balance':
        return const TrialBalanceScreen();
      case 'bank_accounts':
        return const BankAccountsScreen();
      case 'income':
        return const IncomeScreen();
      case 'expense':
        return const ExpenseScreen();
      case 'accounts_receivable':
        return const AccountsReceivableScreen();
      case 'accounts_payable':
        return const AccountsPayableScreen();
      case 'customers':
        return const CustomersScreen();
      case 'bills':
        return const BillsScreen();
      case 'vendors':
        return const VendorsScreen();
      case 'payments_received':
        return const PaymentsReceivedScreen();
      case 'payments_made':
        return const PaymentsMadeScreen();
      case 'credit_notes':
        return const CreditNotesScreen();
      case 'fixed_assets':
        return const FixedAssetsScreen();
      case 'loans':
        return const LoansBorrowingsScreen();
      case 'capital_equity':
        return const CapitalEquityScreen();
      case 'profit_loss':
        return const ProfitLossStatementScreen();
      case 'balance_sheet':
        return const BalanceSheetScreen();
      case 'cash_flow':
        return const CashFlowStatementScreen();
      case 'aged_receivables':
        return const AgedReceivablesScreen();
      case 'currency':
        return const CurrencyScreen();
      case 'subscription':
        return const SelectPlanScreen();
      case 'feedback':
        return const FeedbackScreen();
      case 'about_app':
        return const AboutAppScreen();
      case 'terms':
        return const TermsOfServiceScreen();
      case 'privacy':
        return const PrivacyPolicyScreen();
      default:
        return _DashboardBody(
          ctrl: ctrl,
          subCtrl: subCtrl,
          profileCtrl: profileCtrl,
          onNavigate: onChangeScreen,
        );
    }
  }

  void _onItemTap(String routeName) {
    onChangeScreen(_getScreenForRoute(routeName), route: routeName);
  }

  // ─── Navigate to Dashboard Selection ─────────────────────────────

  void _navigateToDashboardSelection() {
    Get.offAllNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 68.0 : 256.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(right: BorderSide(color: _kCardBorder)),
      ),
      child: Column(
        children: [
          _buildLogoArea(),
          const SizedBox(height: 8),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Row(
                children: [
                  Text(
                    'NAVIGATION',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary.withOpacity(0.55),
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 10),
              itemCount: _sections.length,
              itemBuilder: (_, i) => _buildSectionTile(i),
            ),
          ),
          _buildUserCard(),
        ],
      ),
    );
  }

  Widget _buildLogoArea() {
    return Container(
      height: collapsed ? 80 : 80,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kCardBorder)),
      ),
      child: collapsed
          // ── Collapsed: Back button top, logo below ────────────────────
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Back Button - Top
                GestureDetector(
                  onTap: _navigateToDashboardSelection,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _kPageBg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _kCardBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _kTextSecondary,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBlue, _kBlueDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Back Button - Top Left Only (No Collapse Button)
                Row(
                  children: [
                    GestureDetector(
                      onTap: _navigateToDashboardSelection,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _kPageBg,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: _kCardBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: _kTextSecondary,
                          size: 15,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                // Logo + Text Row
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBlue, _kBlueDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: _kBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LedgerPro',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTile(int i) {
    final section = _sections[i];
    final isDirect = section.children == null;

    if (isDirect) {
      return Obx(
        () => _DirectNavTile(
          icon: section.icon,
          label: section.label,
          collapsed: collapsed,
          isActive: ctrl.isActive(section.routeName),
          onTap: () => _onItemTap(section.routeName),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => _ExpandableHeader(
            icon: section.icon,
            label: section.label,
            isOpen: _isExpanded(i),
            collapsed: collapsed,
            onToggle: () => _toggleExpanded(i),
          ),
        ),
        Obx(
          () => (!collapsed && _isExpanded(i))
              ? Column(
                  children: section.children!
                      .map(
                        (item) => Obx(
                          () => _SubItemTile(
                            icon: item.icon,
                            label: item.label,
                            isActive: ctrl.isActive(item.routeName),
                            onTap: () => _onItemTap(item.routeName),
                          ),
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: EdgeInsets.all(collapsed ? 8 : 10),
      padding: EdgeInsets.all(collapsed ? 8 : 12),
      decoration: BoxDecoration(
        color: _kPageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      child: collapsed
          ? GestureDetector(
              onTap: onLogout,
              child: const Center(
                child: Icon(Icons.logout_rounded, color: _kRed, size: 17),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBlue, _kBlueDark],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          profileCtrl.organizationName.value.isEmpty
                              ? 'Company'
                              : profileCtrl.organizationName.value,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Obx(
                        () => Text(
                          subCtrl.hasActiveSubscription.value
                              ? 'Premium'
                              : subCtrl.isTrialActive.value
                              ? 'Trial Active'
                              : 'Expired',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _kBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: _kRed,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Direct Nav Tile ─────────────────────────────────────────────────────────
class _DirectNavTile extends StatefulWidget {
  final String icon, label;
  final bool collapsed, isActive;
  final VoidCallback onTap;
  const _DirectNavTile({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.isActive,
    required this.onTap,
  });
  @override
  State<_DirectNavTile> createState() => _DirectNavTileState();
}

class _DirectNavTileState extends State<_DirectNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? _kBlue
        : _hovered
        ? _kTextPrimary
        : _kTextSecondary;
    final bgColor = widget.isActive
        ? _kBlue.withOpacity(0.08)
        : _hovered
        ? _kPageBg
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: widget.collapsed
              ? Tooltip(
                  message: widget.label,
                  preferBelow: false,
                  child: Center(
                    child: Iconify(widget.icon, color: color, size: 19),
                  ),
                )
              : Row(
                  children: [
                    if (widget.isActive)
                      Container(
                        width: 3,
                        height: 18,
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          color: _kBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    Iconify(widget.icon, color: color, size: 17),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Expandable Header ────────────────────────────────────────────────────────
class _ExpandableHeader extends StatefulWidget {
  final String icon, label;
  final bool isOpen, collapsed;
  final VoidCallback onToggle;
  const _ExpandableHeader({
    required this.icon,
    required this.label,
    required this.isOpen,
    required this.collapsed,
    required this.onToggle,
  });
  @override
  State<_ExpandableHeader> createState() => _ExpandableHeaderState();
}

class _ExpandableHeaderState extends State<_ExpandableHeader> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isOpen
        ? _kBlue
        : _hovered
        ? _kTextPrimary
        : _kTextSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _hovered ? _kPageBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: widget.collapsed
              ? Tooltip(
                  message: widget.label,
                  preferBelow: false,
                  child: Center(
                    child: Iconify(widget.icon, color: color, size: 19),
                  ),
                )
              : Row(
                  children: [
                    const SizedBox(width: 12),
                    Iconify(widget.icon, color: color, size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: widget.isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _kTextSecondary,
                        size: 17,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Sub Item Tile ────────────────────────────────────────────────────────────
class _SubItemTile extends StatefulWidget {
  final String icon, label;
  final bool isActive;
  final VoidCallback onTap;
  const _SubItemTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  State<_SubItemTile> createState() => _SubItemTileState();
}

class _SubItemTileState extends State<_SubItemTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? _kBlue
        : _hovered
        ? _kTextPrimary
        : _kTextSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 1, left: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? _kBlue.withOpacity(0.07)
                : _hovered
                ? _kPageBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? _kBlue
                      : _kTextSecondary.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Iconify(widget.icon, color: color, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE DROPDOWN
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileDropdown extends StatefulWidget {
  final ProfileController profileCtrl;
  final VoidCallback onLogout;
  const _ProfileDropdown({required this.profileCtrl, required this.onLogout});
  @override
  State<_ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<_ProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _closeDropdown() {
    _animCtrl.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() => _isOpen = false);
    });
  }

  void _openDropdown() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        layerLink: _layerLink,
        fadeAnim: _fadeAnim,
        slideAnim: _slideAnim,
        profileCtrl: widget.profileCtrl,
        onLogout: widget.onLogout,
        onClose: _closeDropdown,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  void _toggle() => _isOpen ? _closeDropdown() : _openDropdown();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlue, _kBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: (_isHovered || _isOpen)
                  ? [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final ProfileController profileCtrl;
  final VoidCallback onLogout, onClose;
  const _DropdownOverlay({
    required this.layerLink,
    required this.fadeAnim,
    required this.slideAnim,
    required this.profileCtrl,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: _ProfileDropdownCard(
                  profileCtrl: profileCtrl,
                  onClose: onClose,
                  onLogout: onLogout,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDropdownCard extends StatefulWidget {
  final ProfileController profileCtrl;
  final VoidCallback onClose, onLogout;
  const _ProfileDropdownCard({
    required this.profileCtrl,
    required this.onClose,
    required this.onLogout,
  });
  @override
  State<_ProfileDropdownCard> createState() => _ProfileDropdownCardState();
}

class _ProfileDropdownCardState extends State<_ProfileDropdownCard> {
  bool _isEditing = false;
  late final TextEditingController _orgCtrl,
      _personCtrl,
      _addressCtrl,
      _emailCtrl,
      _phoneCtrl,
      _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profileCtrl;
    _orgCtrl = TextEditingController(text: p.organizationName.value);
    _personCtrl = TextEditingController(text: p.personName.value);
    _addressCtrl = TextEditingController(text: p.address.value);
    _emailCtrl = TextEditingController(text: p.email.value);
    _phoneCtrl = TextEditingController(text: p.contactNo.value);
    _websiteCtrl = TextEditingController(text: p.websiteLink.value);
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _personCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    final p = widget.profileCtrl;
    _orgCtrl.text = p.organizationName.value;
    _personCtrl.text = p.personName.value;
    _addressCtrl.text = p.address.value;
    _emailCtrl.text = p.email.value;
    _phoneCtrl.text = p.contactNo.value;
    _websiteCtrl.text = p.websiteLink.value;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() => setState(() => _isEditing = false);

  Future<void> _saveEdit() async {
    final p = widget.profileCtrl;
    p.orgNameController.text = _orgCtrl.text;
    p.personNameController.text = _personCtrl.text;
    p.addressController.text = _addressCtrl.text;
    p.emailController.text = _emailCtrl.text;
    p.contactNoController.text = _phoneCtrl.text;
    p.websiteController.text = _websiteCtrl.text;
    if (p.validateForm()) await p.saveProfile();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 540),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isEditing ? _buildEditBody() : _buildViewBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profileCtrl.organizationName.value.isEmpty
                        ? 'Your Organization'
                        : widget.profileCtrl.organizationName.value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.profileCtrl.personName.value.isEmpty
                        ? 'Account Owner'
                        : widget.profileCtrl.personName.value,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.72),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _isEditing ? _cancelEdit : _startEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEditing ? 'Cancel' : 'Edit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBody() {
    return SingleChildScrollView(
      key: const ValueKey('view'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Organization', [
            _InfoRow(
              icon: Mdi.domain,
              label: 'Name',
              value: widget.profileCtrl.organizationName.value,
            ),
            _InfoRow(
              icon: Mdi.account,
              label: 'Contact',
              value: widget.profileCtrl.personName.value,
            ),
            _InfoRow(
              icon: Mdi.map_marker,
              label: 'Address',
              value: widget.profileCtrl.address.value,
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoSection('Contact', [
            _InfoRow(
              icon: Mdi.email,
              label: 'Email',
              value: widget.profileCtrl.email.value,
            ),
            _InfoRow(
              icon: Mdi.phone,
              label: 'Phone',
              value: widget.profileCtrl.contactNo.value,
            ),
            _InfoRow(
              icon: Mdi.web,
              label: 'Web',
              value: widget.profileCtrl.websiteLink.value,
            ),
          ]),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {
              widget.onClose();
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded, size: 13),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: _kRed,
              backgroundColor: _kRed.withOpacity(0.07),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<_InfoRow> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kPageBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kCardBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Iconify(e.value.icon, size: 14, color: _kBlue),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Text(
                            e.value.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.value.value.isEmpty ? '—' : e.value.value,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: e.value.value.isEmpty
                                  ? _kTextSecondary.withOpacity(0.35)
                                  : _kTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: _kCardBorder,
                      indent: 12,
                      endIndent: 12,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditBody() {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditSection('Organization', [
            _EditField(
              icon: Mdi.domain,
              label: 'Organization Name',
              ctrl: _orgCtrl,
              hint: 'Enter name',
            ),
            _EditField(
              icon: Mdi.account,
              label: 'Contact Person',
              ctrl: _personCtrl,
              hint: 'Enter person name',
            ),
            _EditField(
              icon: Mdi.map_marker,
              label: 'Address',
              ctrl: _addressCtrl,
              hint: 'Enter address',
              maxLines: 2,
            ),
          ]),
          const SizedBox(height: 12),
          _buildEditSection('Contact', [
            _EditField(
              icon: Mdi.email,
              label: 'Email',
              ctrl: _emailCtrl,
              hint: 'Enter email',
              keyboard: TextInputType.emailAddress,
            ),
            _EditField(
              icon: Mdi.phone,
              label: 'Phone',
              ctrl: _phoneCtrl,
              hint: 'Enter phone',
              keyboard: TextInputType.phone,
            ),
            _EditField(
              icon: Mdi.web,
              label: 'Website',
              ctrl: _websiteCtrl,
              hint: 'Enter website',
              keyboard: TextInputType.url,
            ),
          ]),
          const SizedBox(height: 16),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.profileCtrl.isSaving.value ? null : _saveEdit,
                icon: widget.profileCtrl.isSaving.value
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 15),
                label: Text(
                  widget.profileCtrl.isSaving.value
                      ? 'Saving…'
                      : 'Save Changes',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(String title, List<_EditField> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...fields.asMap().entries.map(
          (e) => Padding(
            padding: EdgeInsets.only(
              bottom: e.key < fields.length - 1 ? 10 : 0,
            ),
            child: _buildEditField(e.value),
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(_EditField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Iconify(f.icon, size: 12, color: _kBlue),
            const SizedBox(width: 5),
            Text(
              f.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: f.ctrl,
          maxLines: f.maxLines,
          keyboardType: f.keyboard,
          style: const TextStyle(fontSize: 12.5, color: _kTextPrimary),
          decoration: InputDecoration(
            hintText: f.hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: _kTextSecondary.withOpacity(0.4),
            ),
            filled: true,
            fillColor: _kPageBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBlue, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final String icon, label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _EditField {
  final String icon, label, hint;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType keyboard;
  const _EditField({
    required this.icon,
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String title;
  final DashboardController ctrl;
  final ProfileController profileCtrl;
  final VoidCallback onLogout;
  const _TopBar({
    required this.title,
    required this.ctrl,
    required this.profileCtrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(bottom: BorderSide(color: _kCardBorder)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 11.5, color: _kTextSecondary),
              ),
            ],
          ),
          const Spacer(),
          _ProfileDropdown(profileCtrl: profileCtrl, onLogout: onLogout),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD BODY
// ══════════════════════════════════════════════════════════════════════════════
class _DashboardBody extends StatefulWidget {
  final DashboardController ctrl;
  final SubscriptionController subCtrl;
  final ProfileController profileCtrl;
  final Function(Widget, {String route}) onNavigate;
  const _DashboardBody({
    required this.ctrl,
    required this.subCtrl,
    required this.profileCtrl,
    required this.onNavigate,
  });
  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  int _chartTab = 0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = widget.ctrl;

      if (ctrl.isLoading.value && ctrl.chartData.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.discreteCircle(color: _kBlue, size: 30),
              const SizedBox(height: 14),
              const Text(
                'Loading workspace...',
                style: TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
            ],
          ),
        );
      }

      if (ctrl.hasError.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: _kRed,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                ctrl.errorMessage.value,
                style: const TextStyle(fontSize: 13, color: _kTextSecondary),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: ctrl.refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          ctrl.refreshData();
          await widget.subCtrl.checkSubscriptionStatus();
        },
        color: _kBlue,
        backgroundColor: _kCardBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubscriptionBanner(subCtrl: widget.subCtrl),
              _buildHeader(ctrl),
              const SizedBox(height: 18),
              _KPIRow(ctrl: ctrl),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _ChartCard(
                      ctrl: ctrl,
                      chartTab: _chartTab,
                      onTabChange: (t) => setState(() => _chartTab = t),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _QuickActionsCard(
                      ctrl: ctrl,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(DashboardController ctrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  'Welcome back${widget.profileCtrl.personName.value.isEmpty ? '' : ', ${widget.profileCtrl.personName.value.split(' ').first}'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Here's your financial overview for today.",
                style: TextStyle(fontSize: 12.5, color: _kTextSecondary),
              ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onTap: ctrl.refreshData,
        ),
      ],
    );
  }
}

// ─── Header Button ────────────────────────────────────────────────────────────
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: _kTextSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Banner ──────────────────────────────────────────────────────
class _SubscriptionBanner extends StatelessWidget {
  final SubscriptionController subCtrl;
  const _SubscriptionBanner({required this.subCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subCtrl.hasActiveSubscription.value || subCtrl.isTrialActive.value)
        return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRed.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _kRed, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Subscription expired. Renew to access all features.',
                style: TextStyle(fontSize: 12.5, color: _kTextPrimary),
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const SelectPlanScreen()),
              style: TextButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Renew'),
            ),
          ],
        ),
      );
    });
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
class _KPIRow extends StatelessWidget {
  final DashboardController ctrl;
  const _KPIRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _KPICard(
              label: 'TOTAL REVENUE',
              value: ctrl.totalRevenueFormatted.value,
              trend: '+${ctrl.revenueChange.value.toStringAsFixed(1)}%',
              trendUp: true,
              icon: Icons.trending_up_rounded,
              accent: _kGreen,
              sparkData: const [30, 45, 38, 55, 48, 65, 72],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(
            () => _KPICard(
              label: 'TOTAL EXPENSES',
              value: ctrl.totalExpensesFormatted.value,
              trend: '−${ctrl.expenseChange.value.toStringAsFixed(1)}%',
              trendUp: false,
              icon: Icons.trending_down_rounded,
              accent: _kRed,
              sparkData: const [55, 48, 60, 52, 58, 45, 50],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(
            () => _KPICard(
              label: 'OUTSTANDING',
              value: ctrl.outstandingFormatted.value,
              trend: '${ctrl.outstandingCount.value} invoices',
              trendUp: null,
              icon: Icons.receipt_long_rounded,
              accent: _kOrange,
              sparkData: const [12, 18, 15, 22, 19, 25, 20],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(
            () => _KPICard(
              label: 'CASH BALANCE',
              value: ctrl.cashBalanceFormatted.value,
              trend: '+${ctrl.cashChange.value.toStringAsFixed(1)}%',
              trendUp: true,
              icon: Icons.account_balance_wallet_rounded,
              accent: _kBlue,
              sparkData: const [40, 55, 48, 60, 58, 72, 80],
            ),
          ),
        ),
      ],
    );
  }
}

class _KPICard extends StatefulWidget {
  final String label, value, trend;
  final bool? trendUp;
  final IconData icon;
  final Color accent;
  final List<double> sparkData;
  const _KPICard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.icon,
    required this.accent,
    required this.sparkData,
  });
  @override
  State<_KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<_KPICard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final trendColor = widget.trendUp == null
        ? _kTextSecondary
        : widget.trendUp!
        ? _kGreen
        : _kRed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? widget.accent.withOpacity(0.4) : _kCardBorder,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 15, color: widget.accent),
                ),
                // Trend badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.trendUp != null)
                        Icon(
                          widget.trendUp!
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 9,
                          color: trendColor,
                        ),
                      if (widget.trendUp != null) const SizedBox(width: 2),
                      Text(
                        widget.trend,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            // Sparkline
            ClipRect(
              child: SizedBox(
                height: 34,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    clipData: const FlClipData.all(),
                    minX: 0,
                    maxX: (widget.sparkData.length - 1).toDouble(),
                    minY:
                        widget.sparkData.reduce((a, b) => a < b ? a : b) * 0.85,
                    maxY:
                        widget.sparkData.reduce((a, b) => a > b ? a : b) * 1.15,
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.sparkData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: widget.accent,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.accent.withOpacity(0.18),
                              widget.accent.withOpacity(0.0),
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
      ),
    );
  }
}

// ─── Chart Card ───────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final DashboardController ctrl;
  final int chartTab;
  final ValueChanged<int> onTabChange;
  const _ChartCard({
    required this.ctrl,
    required this.chartTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _DashSectionTitle(
                'Financial Overview',
                subtitle: 'Revenue & expense trends',
              ),
              Row(
                children: [
                  if (chartTab != 2) ...[
                    _LegendDot(color: _kBlue, label: 'Revenue'),
                    const SizedBox(width: 14),
                    _LegendDot(color: _kRed, label: 'Expenses'),
                    const SizedBox(width: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _kPageBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kCardBorder),
                    ),
                    child: Row(
                      children: [
                        _ChartTabPill('Bar', 0, chartTab, onTabChange),
                        _ChartTabPill('Line', 1, chartTab, onTabChange),
                        _ChartTabPill('Pie', 2, chartTab, onTabChange),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (ctrl.chartData.isEmpty) {
              return const SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 240,
              child: chartTab == 0
                  ? _BarChartWidget(ctrl: ctrl)
                  : chartTab == 1
                  ? _LineChartWidget(ctrl: ctrl)
                  : _PieChartWidget(ctrl: ctrl),
            );
          }),
        ],
      ),
    );
  }
}

class _ChartTabPill extends StatelessWidget {
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _ChartTabPill(this.label, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _kTextSecondary,
          ),
        ),
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DashSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _DashSectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 10.5, color: _kTextSecondary),
          ),
      ],
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final DashboardController ctrl;
  const _BarChartWidget({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    double maxV = 0;
    for (var d in ctrl.chartData) {
      final r = (d['revenue'] ?? 0).toDouble();
      final e = (d['expenses'] ?? 0).toDouble();
      if (r > maxV) maxV = r;
      if (e > maxV) maxV = e;
    }
    maxV *= 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _kTextPrimary,
            tooltipBorder: const BorderSide(color: _kCardBorder),
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              CurrencyUtils.format(rod.toY),
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < 0 || i >= ctrl.chartData.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    ctrl.getMonthName(i),
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: _kTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) => Text(
                _fmtNum(val),
                style: const TextStyle(fontSize: 9.5, color: _kTextSecondary),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _kCardBorder, strokeWidth: 1),
        ),
        barGroups: List.generate(
          ctrl.chartData.length,
          (i) => BarChartGroupData(
            x: i,
            barsSpace: 5,
            barRods: [
              BarChartRodData(
                toY: ctrl.getMonthlyRevenue(i),
                color: _kBlue,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxV,
                  color: _kBlue.withOpacity(0.05),
                ),
              ),
              BarChartRodData(
                toY: ctrl.getMonthlyExpenses(i),
                color: _kRed.withOpacity(0.75),
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxV,
                  color: _kRed.withOpacity(0.04),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────────────────────
class _LineChartWidget extends StatelessWidget {
  final DashboardController ctrl;
  const _LineChartWidget({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _kCardBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < 0 || i >= ctrl.chartData.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    ctrl.getMonthName(i),
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: _kTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) => Text(
                _fmtNum(val),
                style: const TextStyle(fontSize: 9.5, color: _kTextSecondary),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _kTextPrimary,
            tooltipBorder: const BorderSide(color: _kCardBorder),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    CurrencyUtils.format(s.y),
                    TextStyle(
                      color: s.barIndex == 0 ? _kBlue : _kRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              ctrl.chartData.length,
              (i) => FlSpot(i.toDouble(), ctrl.getMonthlyRevenue(i)),
            ),
            isCurved: true,
            color: _kBlue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: _kBlue,
                strokeWidth: 2,
                strokeColor: _kCardBg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [_kBlue.withOpacity(0.14), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: List.generate(
              ctrl.chartData.length,
              (i) => FlSpot(i.toDouble(), ctrl.getMonthlyExpenses(i)),
            ),
            isCurved: true,
            color: _kRed,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: _kRed,
                strokeWidth: 2,
                strokeColor: _kCardBg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [_kRed.withOpacity(0.07), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pie Chart ────────────────────────────────────────────────────────────────
class _PieChartWidget extends StatelessWidget {
  final DashboardController ctrl;
  const _PieChartWidget({required this.ctrl});

  static const _colors = [
    _kBlue,
    _kGreen,
    _kOrange,
    _kRed,
    _kPurple,
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    if (ctrl.expenseCategories.isEmpty) {
      return const Center(
        child: Text(
          'No expense data',
          style: TextStyle(color: _kTextSecondary),
        ),
      );
    }
    final total = ctrl.expenseCategories.fold(
      0.0,
      (s, c) => s + (c['amount'] ?? 0).toDouble(),
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: ctrl.expenseCategories.asMap().entries.map((e) {
                final amt = (e.value['amount'] ?? 0).toDouble();
                final pct = total > 0
                    ? (amt / total * 100).toStringAsFixed(1)
                    : '0';
                return PieChartSectionData(
                  value: amt,
                  title: '$pct%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  color: _colors[e.key % _colors.length],
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 38,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ctrl.expenseCategories
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _colors[e.key % _colors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            e.value['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _kTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions Card ───────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final DashboardController ctrl;
  final Function(Widget, {String route}) onNavigate;
  const _QuickActionsCard({required this.ctrl, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashSectionTitle('Quick Actions', subtitle: 'Common tasks'),
          const SizedBox(height: 16),
          _QuickAction(
            icon: Icons.add_circle_outline_rounded,
            accent: _kGreen,
            label: 'Add Income',
            sub: 'Record a payment',
            onTap: () => onNavigate(const IncomeScreen(), route: 'income'),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.remove_circle_outline_rounded,
            accent: _kRed,
            label: 'Add Expense',
            sub: 'Log an expense',
            onTap: () => onNavigate(const ExpenseScreen(), route: 'expense'),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.receipt_long_rounded,
            accent: _kBlue,
            label: 'New Invoice',
            sub: 'Create invoice',
            onTap: () => onNavigate(const WarehouseInvoiceScreen(), route: 'Invoice'),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.people_alt_rounded,
            accent: _kOrange,
            label: 'Customers',
            sub: 'Manage customers',
            onTap: () =>
                onNavigate(const CustomersScreen(), route: 'customers'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String label, sub;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.accent,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _hovered ? widget.accent.withOpacity(0.06) : _kPageBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.accent.withOpacity(0.25) : _kCardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimary,
                      ),
                    ),
                    Text(
                      widget.sub,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _hovered
                    ? widget.accent
                    : _kTextSecondary.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtNum(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
