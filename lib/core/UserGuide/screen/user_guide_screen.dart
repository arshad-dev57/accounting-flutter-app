import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kPrimary = Color(0xFF014582);
const Color _kPrimaryLight = Color(0xFF0FA3E0);
const Color _kBg = Color(0xFFF0F4F8);
const Color _kCard = Colors.white;
const Color _kText = Color(0xFF1A1A2E);
const Color _kSub = Color(0xFF7A8FA6);
const Color _kBorder = Color(0xFFDDE4EE);
const Color _kGreen = Color(0xFF2ECC71);
const Color _kOrange = Color(0xFFF39C12);
const Color _kPurple = Color(0xFF7C3AED);
const Color _kTeal = Color(0xFF1ABC9C);

// ═══════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════

class _Section {
  final String emoji;
  final String title;
  final Color color;
  final IconData icon;
  final List<_Step> steps;
  const _Section({
    required this.emoji,
    required this.title,
    required this.color,
    required this.icon,
    required this.steps,
  });
}

class _Step {
  final String title;
  final String where;
  final String how;
  final String effect;
  final IconData icon;
  final String? webTip;
  const _Step({
    required this.title,
    required this.where,
    required this.how,
    required this.effect,
    required this.icon,
    this.webTip,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// GUIDE DATA
// ═══════════════════════════════════════════════════════════════════════

final List<_Section> _sections = [
  _Section(
    emoji: '🚀',
    title: 'Getting Started',
    color: _kPrimary,
    icon: Icons.rocket_launch,
    steps: [
      _Step(
        icon: Icons.person_add,
        title: 'Register & Login',
        where: 'App → Register / Login screen',
        how:
            'Enter your email and set a password. OTP will be sent to your email for verification. After OTP entry you land on the dashboard.',
        effect:
            'Your account + company profile is created. All your data is tied to this account.',
        webTip: 'Web: app.bisonstechs.com → Sign up → same OTP flow.',
      ),
      _Step(
        icon: Icons.business,
        title: 'Set Up Company Profile',
        where: 'App → Settings → Company Profile',
        how:
            'Enter company name, address, phone, logo. Save — this appears on all your invoices and reports.',
        effect:
            'All invoices, reports and PDF exports will carry your company branding.',
        webTip: 'Web: Settings → Company Profile → same fields.',
      ),
      _Step(
        icon: Icons.calendar_today,
        title: 'Create Fiscal Year',
        where: 'App → Settings → Fiscal Year',
        how:
            'Tap "+" → set Start Date & End Date (e.g. Jan 1 – Dec 31). Mark as current. All accounting is filtered by this year.',
        effect:
            'Reports, P&L, Balance Sheet all use this date range. You can create multiple years and switch between them.',
        webTip: 'Web: Settings → Fiscal Year → New Fiscal Year.',
      ),
      _Step(
        icon: Icons.account_balance_wallet,
        title: 'Set Up Chart of Accounts',
        where: 'App → Accounting → Chart of Accounts',
        how:
            'Add accounts under Assets (Cash, Bank, Receivable), Liabilities (Payable, Loans), Equity, Income, Expenses. Each account has a type and optional code.',
        effect:
            'Every transaction is posted to these accounts. Correct setup = accurate reports.',
        webTip: 'Web: Accounting → Chart of Accounts → Add Account.',
      ),
      _Step(
        icon: Icons.currency_exchange,
        title: 'Set Currency',
        where: 'App → Settings → Currency',
        how:
            'Choose your base currency (PKR, USD, etc.). This is shown on all amounts.',
        effect: 'All invoices, reports, and POS receipts display in this currency.',
      ),
    ],
  ),
  _Section(
    emoji: '💰',
    title: 'Accounting & Finance',
    color: _kGreen,
    icon: Icons.account_balance,
    steps: [
      _Step(
        icon: Icons.add_circle,
        title: 'Record Income',
        where: 'App → Income',
        how:
            'Tap "+" → select income account, enter amount, date, description. Save.',
        effect:
            'Increases your income account balance. Appears in P&L as revenue. Dashboard totals update.',
        webTip: 'Web: Income → Add Income → same form.',
      ),
      _Step(
        icon: Icons.remove_circle,
        title: 'Record Expense',
        where: 'App → Expenses',
        how:
            'Tap "+" → select expense category, amount, date, payment method. Save.',
        effect:
            'Reduces cash/bank. Increases expense account. P&L shows as cost. Dashboard net profit updates.',
        webTip: 'Web: Expenses → Add Expense.',
      ),
      _Step(
        icon: Icons.receipt_long,
        title: 'Journal Entries',
        where: 'App → Accounting → Journal Entries (Web)',
        how:
            'Used for advanced double-entry postings. Debit one account, credit another. Both must balance.',
        effect:
            'Direct impact on Trial Balance and Balance Sheet. Use for corrections, opening balances, or custom entries.',
        webTip:
            'Web: Accounting → Journal Entries → New Entry. Mobile shows read-only view.',
      ),
      _Step(
        icon: Icons.assessment,
        title: 'Financial Reports',
        where: 'App → Reports',
        how:
            'Select report type → choose fiscal year / date range → tap Generate.\n\n• Profit & Loss — Revenue vs Expenses → Net Profit\n• Balance Sheet — Assets = Liabilities + Equity\n• Trial Balance — All account balances\n• Cash Flow — Cash in vs Cash out\n• Accounts Receivable — Who owes you\n• Accounts Payable — What you owe',
        effect:
            'Downloadable PDF. Accurate only when all transactions are posted correctly.',
        webTip: 'Web: Reports → same options + more filters.',
      ),
    ],
  ),
  _Section(
    emoji: '🧾',
    title: 'Sales & Invoicing',
    color: _kPrimaryLight,
    icon: Icons.request_quote,
    steps: [
      _Step(
        icon: Icons.person,
        title: 'Add a Customer',
        where: 'App → Contacts → Customers → "+"',
        how:
            'Enter name, phone, email, address. Save. Customer is now available when creating invoices.',
        effect:
            'Linked to all invoices/payments for that customer. Accounts Receivable tracks their balance.',
        webTip: 'Web: Contacts → Customers → Add Customer.',
      ),
      _Step(
        icon: Icons.receipt,
        title: 'Create Sales Invoice',
        where: 'App → Sales → Invoices → "+"',
        how:
            'Select customer → add line items (product/service, qty, price) → apply tax if needed → set due date → Save or Send.',
        effect:
            'Creates receivable (money owed to you). Appears in Accounts Receivable report. Revenue increases.',
        webTip: 'Web: Sales → Invoices → New Invoice. More formatting options available.',
      ),
      _Step(
        icon: Icons.payments,
        title: 'Record Payment Received',
        where: 'App → Sales → Payments / or open Invoice → Record Payment',
        how:
            'Select invoice → enter amount received, date, payment method (Cash/Bank). Save.',
        effect:
            'Invoice marked as Paid. Cash/Bank increases. Receivable decreases. Revenue realized.',
        webTip: 'Web: Sales → Payments → Receive Payment.',
      ),
      _Step(
        icon: Icons.description,
        title: 'Create Quotation',
        where: 'App → Warehouse → Quotations → "+" (or Web: Sales → Quotations)',
        how:
            'Select customer → add products → set validity date → Save. Convert to Sales Order when approved.',
        effect:
            'No accounting impact until converted to order/invoice. Acts as a price proposal.',
      ),
      _Step(
        icon: Icons.swap_horiz,
        title: 'Sales Return / Credit Note',
        where: 'App → Sales → Credits / Returns',
        how:
            'Select original invoice → enter returned items → Save.',
        effect:
            'Reduces receivable / revenue. If already paid, creates credit balance for customer.',
        webTip: 'Web: Sales → Credit Notes.',
      ),
    ],
  ),
  _Section(
    emoji: '🛒',
    title: 'Purchases',
    color: _kOrange,
    icon: Icons.shopping_cart,
    steps: [
      _Step(
        icon: Icons.store,
        title: 'Add a Supplier',
        where: 'App → Contacts → Suppliers → "+"',
        how: 'Enter supplier name, phone, email, address. Save.',
        effect:
            'Available when creating purchase orders/bills. Accounts Payable tracks what you owe them.',
        webTip: 'Web: Contacts → Suppliers → Add Supplier.',
      ),
      _Step(
        icon: Icons.add_shopping_cart,
        title: 'Create Purchase Order',
        where: 'App → Purchases → Purchase Orders → "+"',
        how:
            'Select supplier → add products (name, qty, price) → set expected delivery → Save.',
        effect:
            'No immediate accounting impact. Used to track what you ordered. Converts to bill when goods arrive.',
        webTip: 'Web: Purchases → Purchase Orders → New PO.',
      ),
      _Step(
        icon: Icons.inventory,
        title: 'Receive Goods (Goods Receiving)',
        where: 'App → Purchases → Goods Receiving → "+"',
        how:
            'Select PO → enter actually received quantities → Save.',
        effect:
            'Inventory increases immediately. Creates pending bill to pay supplier.',
      ),
      _Step(
        icon: Icons.receipt,
        title: 'Create Purchase Bill',
        where: 'App → Purchases → Invoices (Bills) → "+"',
        how:
            'Select supplier → add items purchased → set due date → Save.',
        effect:
            'Increases Accounts Payable (what you owe). Expense or inventory account increases.',
        webTip: 'Web: Purchases → Bills → New Bill.',
      ),
      _Step(
        icon: Icons.payment,
        title: 'Make Supplier Payment',
        where: 'App → Purchases → Payments → "+"',
        how:
            'Select bill → enter amount paid, date, bank/cash account. Save.',
        effect:
            'Bill marked Paid. Cash/Bank decreases. Payable decreases. Net cash flow updates.',
        webTip: 'Web: Purchases → Payments → Make Payment.',
      ),
      _Step(
        icon: Icons.keyboard_return,
        title: 'Purchase Return',
        where: 'App → Purchases → Returns',
        how: 'Select original bill/PO → enter returned items → Save.',
        effect:
            'Decreases payable and inventory. If already paid, creates credit with supplier.',
      ),
    ],
  ),
  _Section(
    emoji: '📦',
    title: 'Warehouse & Inventory',
    color: _kTeal,
    icon: Icons.warehouse,
    steps: [
      _Step(
        icon: Icons.category,
        title: 'Create Product Categories',
        where: 'App → Warehouse → Categories → "+"',
        how: 'Add category name (e.g. Electronics, Clothing). Save.',
        effect: 'Organize products. Filter reports and inventory by category.',
        webTip: 'Web: Warehouse → Categories.',
      ),
      _Step(
        icon: Icons.inventory_2,
        title: 'Add Products',
        where: 'App → Warehouse → Products → "+"',
        how:
            'Enter product name, SKU, category, unit, cost price, selling price, reorder level. Save.',
        effect:
            'Product available for sales invoices, purchase orders, POS. Inventory tracked from first stock-in.',
        webTip: 'Web: Warehouse → Products → New Product.',
      ),
      _Step(
        icon: Icons.add_box,
        title: 'Stock In (Manual)',
        where: 'App → Warehouse → Stock In → "+"',
        how:
            'Select product → enter quantity, cost price, location, date. Save.',
        effect:
            'Inventory quantity increases. Average cost recalculated. Shown in stock summary.',
        webTip: 'Web: Warehouse → Stock In.',
      ),
      _Step(
        icon: Icons.location_on,
        title: 'Set Up Locations',
        where: 'App → Settings → Locations (or Warehouse → Locations)',
        how:
            'Add warehouses or shop locations. Each location tracks its own inventory separately.',
        effect:
            'Multi-location stock tracking. Transfer stock between locations. Reports filter per location.',
        webTip: 'Web: Settings → Locations.',
      ),
      _Step(
        icon: Icons.local_shipping,
        title: 'Delivery (Sales Order Fulfillment)',
        where: 'App → Warehouse → Deliveries',
        how:
            'Select confirmed sales order → create delivery note → enter qty to deliver → Save.',
        effect:
            'Inventory decreases. Order status moves to Delivered. Customer can be sent delivery note.',
        webTip: 'Web: Warehouse → Deliveries.',
      ),
      _Step(
        icon: Icons.warning_amber,
        title: 'Low Stock Alerts',
        where: 'App → Warehouse → Reports → Low Stock',
        how:
            'Auto-calculated when product quantity falls below reorder level you set.',
        effect:
            'Alert visible on report. Helps you reorder before stockout.',
      ),
      _Step(
        icon: Icons.date_range,
        title: 'Expiry Tracking',
        where: 'App → Warehouse → Reports → Expiry Report',
        how:
            'Products with expiry dates show here. Set expiry date when doing Stock In.',
        effect:
            'Avoid selling expired goods. Plan promotions before expiry.',
      ),
    ],
  ),
  _Section(
    emoji: '🖥️',
    title: 'POS (Point of Sale)',
    color: _kPurple,
    icon: Icons.point_of_sale,
    steps: [
      _Step(
        icon: Icons.computer,
        title: 'POS is Desktop Only',
        where: 'Download → BisonsTechs Desktop App (Windows / Mac)',
        how:
            'Install the desktop app on your PC. Login with same credentials. Open a shift before making sales.',
        effect:
            'POS sales sync to cloud. Accounting (revenue, inventory) updates in real time.',
        webTip:
            'Web app: bisonstechs.com → download desktop app from the website.',
      ),
      _Step(
        icon: Icons.lock_open,
        title: 'Open a Shift',
        where: 'Desktop POS → Open Shift',
        how:
            'Enter opening cash amount → Open Shift. You must open a shift before any sale.',
        effect:
            'Tracks all cash in/out for that shift. Close shift generates shift report.',
      ),
      _Step(
        icon: Icons.shopping_bag,
        title: 'Make a Sale (POS)',
        where: 'Desktop POS → New Sale',
        how:
            'Scan barcode or search product → add to cart → enter qty if needed → select payment method (Cash/Card) → Complete Sale.',
        effect:
            'Revenue increases. Inventory decreases. Receipt generated. Cash drawer opens if connected.',
      ),
      _Step(
        icon: Icons.lock,
        title: 'Close Shift',
        where: 'Desktop POS → Close Shift',
        how:
            'Count cash → enter closing cash → Close. System calculates expected vs actual cash.',
        effect:
            'Shift report generated. All shift sales posted to accounting. Discrepancy flagged if cash is off.',
      ),
      _Step(
        icon: Icons.undo,
        title: 'POS Returns',
        where: 'Desktop POS → Returns',
        how: 'Find original sale → select items to return → process refund.',
        effect: 'Revenue reverses. Inventory restocked. Cash refund issued.',
      ),
      _Step(
        icon: Icons.pause_circle,
        title: 'Hold & Resume Sale',
        where: 'Desktop POS → Hold Sale button',
        how: 'Tap Hold → serve another customer → Resume from held sales list.',
        effect: 'Cart saved temporarily. No accounting impact until completed.',
      ),
    ],
  ),
  _Section(
    emoji: '👥',
    title: 'Users & Permissions',
    color: Color(0xFFE67E22),
    icon: Icons.manage_accounts,
    steps: [
      _Step(
        icon: Icons.person_add_alt,
        title: 'Invite Team Members',
        where: 'App → Settings → Users → "+"  (Admin only)',
        how:
            'Enter name, email, role (Admin / Manager / Cashier / Staff). Send invite.',
        effect:
            'New user gets email with login credentials. They can only do what their role allows.',
        webTip: 'Web: Settings → Users & Permissions → Invite User.',
      ),
      _Step(
        icon: Icons.admin_panel_settings,
        title: 'Manage Permissions',
        where: 'App → Settings → Users → tap user → Edit Permissions',
        how:
            'Toggle per-module access (can create, edit, delete, view). Save.',
        effect:
            'User immediately gets or loses access to that module. Prevents unauthorized changes.',
        webTip: 'Web: Settings → Users → Advanced Permissions panel.',
      ),
    ],
  ),
  _Section(
    emoji: '📊',
    title: 'Reports & Analytics',
    color: Color(0xFF8E44AD),
    icon: Icons.bar_chart,
    steps: [
      _Step(
        icon: Icons.trending_up,
        title: 'Profit & Loss (P&L)',
        where: 'App → Reports → Profit & Loss',
        how:
            'Select fiscal year / custom date range → Generate. Shows Revenue – Expenses = Net Profit.',
        effect:
            'Know if your business is profitable. Filter by month to spot seasonal trends.',
        webTip: 'Web: Accounting Reports → P&L → export to PDF or Excel.',
      ),
      _Step(
        icon: Icons.account_balance,
        title: 'Balance Sheet',
        where: 'App → Reports → Balance Sheet',
        how: 'Select date → Generate. Assets must = Liabilities + Equity.',
        effect:
            'See overall financial health. Detect if accounts are out of balance.',
        webTip: 'Web: Accounting Reports → Balance Sheet.',
      ),
      _Step(
        icon: Icons.waterfall_chart,
        title: 'Cash Flow',
        where: 'App → Reports → Cash Flow',
        how: 'Select date range → Generate.',
        effect:
            'See money coming in vs going out. Identify cash shortfalls before they happen.',
      ),
      _Step(
        icon: Icons.table_chart,
        title: 'Trial Balance',
        where: 'App → Reports → Trial Balance',
        how: 'Select date → Generate. All accounts listed with debit/credit totals.',
        effect:
            'Verify books are balanced. Used by accountants for audit preparation.',
      ),
      _Step(
        icon: Icons.people,
        title: 'Accounts Receivable Aging',
        where: 'App → Reports → Accounts Receivable',
        how: 'Shows outstanding invoices grouped by overdue days (0–30, 31–60, 60+).',
        effect:
            'Follow up with customers who owe you money. Reduce bad debt.',
        webTip: 'Web: Sales → Receivables Report.',
      ),
      _Step(
        icon: Icons.inventory,
        title: 'Inventory Valuation',
        where: 'App → Warehouse → Reports → Inventory Valuation',
        how: 'Shows current stock quantity × average cost per product.',
        effect: 'Know the total value of your stock at any time.',
        webTip: 'Web: Warehouse → Inventory Valuation.',
      ),
    ],
  ),
  _Section(
    emoji: '⚙️',
    title: 'Settings & Taxes',
    color: _kSub,
    icon: Icons.settings,
    steps: [
      _Step(
        icon: Icons.percent,
        title: 'Set Up Taxes',
        where: 'App → Settings → Tax',
        how:
            'Add tax name (e.g. GST, VAT), rate (%). Set as default if applicable.',
        effect:
            'Tax auto-applies to invoices. Tax amount shown separately. Tax reports available.',
        webTip: 'Web: Settings → Tax Configuration.',
      ),
      _Step(
        icon: Icons.picture_as_pdf,
        title: 'PDF Report Branding',
        where: 'App → Settings → PDF Settings',
        how:
            'Upload logo, set footer text, choose color theme. Save.',
        effect: 'All exported invoices and reports carry your custom branding.',
      ),
      _Step(
        icon: Icons.notifications,
        title: 'Notifications',
        where: 'App → Notifications (bell icon)',
        how:
            'Admin can send alerts from bisonstechs-admin portal. App receives them live.',
        effect:
            'Stay informed about important updates, subscription changes, or admin messages.',
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  int _expanded = -1;
  int _expandedStep = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildIntro()),
          SliverToBoxAdapter(child: _buildWebBanner()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildSectionCard(i),
                childCount: _sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: _kPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'User Guide',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => showSearch(
            context: context,
            delegate: _GuideSearchDelegate(),
          ),
        ),
      ],
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, Color(0xFF0D8BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'BisonsTechs ERP',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete Business Management Guide',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _chip(Icons.store, 'POS'),
              _chip(Icons.account_balance, 'Accounting'),
              _chip(Icons.shopping_cart, 'Purchases'),
              _chip(Icons.request_quote, 'Sales'),
              _chip(Icons.warehouse, 'Inventory'),
              _chip(Icons.bar_chart, 'Reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Intro ────────────────────────────────────────────────────────────
  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.waving_hand, color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tap any section below to expand step-by-step instructions. Each step shows where to go, what to do, and what happens in your accounts.',
                style: TextStyle(fontSize: 13, color: _kSub, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Web Banner ───────────────────────────────────────────────────────
  Widget _buildWebBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InkWell(
        onTap: () => _launchUrl('https://app.bisonstechs.com'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0FA3E0), _kPrimary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.language, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Web App Available',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text('app.bisonstechs.com',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Card ─────────────────────────────────────────────────────
  Widget _buildSectionCard(int i) {
    final s = _sections[i];
    final isOpen = _expanded == i;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOpen ? s.color.withValues(alpha: 0.4) : _kBorder),
        boxShadow: [
          BoxShadow(
            color: s.color.withValues(alpha: isOpen ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expanded = isOpen ? -1 : i;
              _expandedStep = -1;
            }),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, color: s.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.emoji}  ${s.title}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.steps.length} steps',
                          style: TextStyle(fontSize: 11, color: _kSub),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: s.color,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Divider(height: 1, color: s.color.withValues(alpha: 0.2)),
            ...List.generate(s.steps.length, (j) => _buildStep(s, j, i)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ── Step Row ─────────────────────────────────────────────────────────
  Widget _buildStep(_Section s, int j, int sIdx) {
    final step = s.steps[j];
    final key = sIdx * 100 + j;
    final isOpen = _expandedStep == key;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expandedStep = isOpen ? -1 : key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(step.icon, color: s.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.remove : Icons.add,
                  color: s.color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.place, 'Where', step.where, s.color),
                const SizedBox(height: 10),
                _infoRow(Icons.touch_app, 'How', step.how, s.color),
                const SizedBox(height: 10),
                _infoRow(Icons.bolt, 'Effect on accounts', step.effect, s.color),
                if (step.webTip != null) ...[
                  const SizedBox(height: 10),
                  _infoRow(Icons.language, 'Web App', step.webTip!, _kPrimaryLight),
                ],
              ],
            ),
          ),
        Divider(height: 1, indent: 16, endIndent: 16, color: _kBorder),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontSize: 12, color: _kText, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SEARCH DELEGATE
// ═══════════════════════════════════════════════════════════════════════

class _GuideSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search guide…';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: _kPrimary),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  List<_Step> _results() {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final res = <_Step>[];
    for (final s in _sections) {
      for (final step in s.steps) {
        if (step.title.toLowerCase().contains(q) ||
            step.where.toLowerCase().contains(q) ||
            step.how.toLowerCase().contains(q) ||
            step.effect.toLowerCase().contains(q)) {
          res.add(step);
        }
      }
    }
    return res;
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final res = _results();
    if (res.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: _kSub)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: res.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final step = res[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              const SizedBox(height: 4),
              Text('📍 ${step.where}',
                  style: const TextStyle(fontSize: 12, color: _kSub)),
              const SizedBox(height: 4),
              Text('⚡ ${step.effect}',
                  style: const TextStyle(fontSize: 12, color: _kSub),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}
