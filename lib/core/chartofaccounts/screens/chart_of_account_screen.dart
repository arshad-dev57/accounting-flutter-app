import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/controller/chart_of_account_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_rate_field.dart';
import 'package:BisonsTechs_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _searchCtrl = TextEditingController();
  late final ChartOfAccountController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ChartOfAccountController>()
        ? Get.find<ChartOfAccountController>()
        : Get.put(ChartOfAccountController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.accounts.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (!controller.isLoadingMore.value &&
                        scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.loadMoreData();
                    }
                    return false;
                  },
                  child: _buildAccountsList(controller, context),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, controller),
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chart of Accounts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalItems.value} accounts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => controller.hasIncorrectCashAccounts.value
                        ? GestureDetector(
                            onTap: () =>
                                _showFixCashAccountsDialog(context, controller),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: controller.fetchAccounts,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() {});
                    v.isEmpty
                        ? controller.searchAccounts('')
                        : controller.searchAccounts(v);
                  },
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search accounts...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              controller.searchAccounts('');
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            // Filters
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children:
                      [
                        'All',
                        'Assets',
                        'Liabilities',
                        'Equity',
                        'Income',
                        'Expenses',
                      ].map((filter) {
                        final isSelected =
                            controller.selectedFilter.value == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => controller.changeFilter(filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                    ? kPrimary
                                    : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsList(
    ChartOfAccountController controller,
    BuildContext context,
  ) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final accounts = controller.accounts;
            if (accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64,
                      color: kSubText.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No accounts found',
                      style: TextStyle(fontSize: 16, color: kSubText),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _showAddAccountDialog(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Account',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = controller.mapAccountToUI(accounts[index]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAccountCard(context, account, controller),
                );
              },
            );
          }),
        ),
        Obx(
          () => controller.isLoadingMore.value
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: kPrimary,
                      size: 30,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Map<String, dynamic> account,
    ChartOfAccountController controller,
  ) {
    final isDebit = account['balanceType'] == 'Debit';
    final isIncorrect = controller.isIncorrectCashAccount(account);
    final typeColor = account['typeColor'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountDetails(context, account, controller),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    account['typeIcon'] as IconData,
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account['name'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isIncorrect)
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              account['code'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${account['type']}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(account['balance']),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDebit ? kSuccess : kDanger,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDebit
                            ? kSuccess.withOpacity(0.1)
                            : kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        account['balanceType'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDebit ? kSuccess : kDanger,
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
    );
  }

  // ─── Show Fix Cash Accounts Dialog ──────────────────────────────
  void _showFixCashAccountsDialog(
    BuildContext context,
    ChartOfAccountController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Fix Cash Accounts',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some cash/bank accounts have incorrect account types.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Cash and Bank accounts should be of type "Assets".',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              'Do you want to automatically fix all incorrect cash/bank accounts?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.fixCashAccounts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Fix All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAccountDetails(
    BuildContext context,
    Map<String, dynamic> account,
    ChartOfAccountController controller,
  ) {
    final isDebit = account['balanceType'] == 'Debit';
    final isIncorrect = controller.isIncorrectCashAccount(account);
    final typeColor = account['typeColor'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              account['typeIcon'] as IconData,
                              color: typeColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        account['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: kText,
                                        ),
                                      ),
                                    ),
                                    if (isIncorrect)
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        account['code'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${account['type']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // KPI Cards
                      Row(
                        children: [
                          _miniKpi(
                            'Balance',
                            _formatAmount(account['balance']),
                            isDebit ? kSuccess : kDanger,
                            isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Type',
                            account['balanceType'],
                            typeColor,
                            Icons.account_balance,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Status',
                            account['isActive'] ? 'Active' : 'Inactive',
                            account['isActive'] ? kSuccess : kSubText,
                            account['isActive']
                                ? Icons.check_circle
                                : Icons.cancel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      _detailRow(
                        'Parent Account',
                        account['parentAccount'] ?? 'N/A',
                      ),
                      _detailRow('Tax Code', account['taxCode'] ?? 'N/A'),
                      _detailRow(
                        'Description',
                        account['description'] ?? 'No description',
                      ),
                      if (isIncorrect) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ This is a cash/bank account but type is "${account['type']}". It should be "Assets".',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              controller.fixAccountType(
                                account['id'],
                                'Assets',
                              );
                            },
                            icon: const Icon(Icons.account_balance, size: 18),
                            label: const Text('Fix Account Type'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          const SizedBox(width: 10),

                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditAccountDialog(
                                    context,
                                    account,
                                    controller,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimary,
                                  side: const BorderSide(color: kPrimary),
                                  minimumSize: const Size.fromHeight(46),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Edit',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Get.to(() => const JournalEntriesScreen());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(46),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'View Ledger',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: TextStyle(fontSize: 10, color: kSubText)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ✅ PROFESSIONAL: Add Account Dialog ──────────────────────
  void _showAddAccountDialog(
    BuildContext context,
    ChartOfAccountController controller,
  ) {
    final formKey = GlobalKey<FormState>();
    String accountCode = '';
    String accountName = '';
    String accountType = 'Assets';
    String parentAccount = '';
    String description = '';
    String taxCode = 'N/A';
    double openingBalance = 0.0;
    String? typeError;

    bool isSaving = false;

    final Map<String, List<String>> parentAccountMapping = {
      'Assets': ['Current Assets', 'Fixed Assets'],
      'Liabilities': ['Current Liabilities', 'Long Term Liabilities'],
      'Equity': ['Capital / Equity'],
      'Income': ['Operating Income'],
      'Expenses': ['Operating Expenses'],
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final parentAccounts = parentAccountMapping[accountType] ?? [];
          if (parentAccount.isNotEmpty &&
              !parentAccounts.contains(parentAccount)) {
            parentAccount = '';
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add, color: kPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              Text(
                                'Create a new chart of account',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _proFormField(
                              'Account Code',
                              'e.g., 1010',
                              (v) => accountCode = v,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              enabled: !isSaving,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Account Name',
                              'e.g., Cash in Hand',
                              (v) {
                                accountName = v;
                                final nameLower = v.toLowerCase();
                                final isCashOrBank =
                                    nameLower.contains('cash') ||
                                    nameLower.contains('bank') ||
                                    nameLower.contains('money');
                                if (isCashOrBank && accountType != 'Assets') {
                                  setState(() {
                                    typeError =
                                        'Cash/Bank accounts must be of type "Assets"';
                                  });
                                } else {
                                  setState(() {
                                    typeError = null;
                                  });
                                }
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              enabled: !isSaving,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _proDropdownField<String>(
                              label: 'Account Type',
                              value: accountType,
                              items: const [
                                'Assets',
                                'Liabilities',
                                'Equity',
                                'Income',
                                'Expenses',
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (v) {
                                      setState(() {
                                        accountType = v!;
                                        parentAccount = '';
                                        final nameLower = accountName
                                            .toLowerCase();
                                        final isCashOrBank =
                                            nameLower.contains('cash') ||
                                            nameLower.contains('bank') ||
                                            nameLower.contains('money');
                                        if (isCashOrBank &&
                                            accountType != 'Assets') {
                                          typeError =
                                              'Cash/Bank accounts must be of type "Assets"';
                                        } else {
                                          typeError = null;
                                        }
                                      });
                                    },
                              isRequired: true,
                            ),
                            if (typeError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        typeError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _proDropdownField<String>(
                              label: 'Parent Account',
                              value: parentAccount.isEmpty
                                  ? null
                                  : parentAccount,
                              items: parentAccounts,
                              onChanged: isSaving
                                  ? null
                                  : (v) => setState(() => parentAccount = v!),
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Opening Balance',
                              '0.00',
                              (v) => openingBalance = double.tryParse(v) ?? 0.0,
                              keyboardType: TextInputType.number,
                              prefixText: CurrencyUtils.prefix,
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            TaxCodeField(
                              value: taxCode,
                              enabled: !isSaving,
                              onChanged: (v) => setState(() => taxCode = v),
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Description',
                              'Account description',
                              (v) => description = v,
                              maxLines: 3,
                              enabled: !isSaving,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isSaving
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: kText,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSaving ? Colors.grey : kText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (typeError != null) {
                                      AppSnackbar.error(
                                        Colors.red,
                                        'Error',
                                        typeError!,
                                      );
                                      return;
                                    }
                                    if (formKey.currentState!.validate()) {
                                      setState(() {
                                        isSaving = true;
                                      });

                                      await controller.createAccount({
                                        'code': accountCode,
                                        'name': accountName,
                                        'type': accountType,
                                        'parentAccount': parentAccount,
                                        'openingBalance': openingBalance,
                                        'description': description,
                                        'taxCode': taxCode,
                                      });

                                      Navigator.pop(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSaving
                                  ? Colors.grey
                                  : kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSaving) ...[
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isSaving ? 'Saving...' : 'Save Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSaving
                                        ? Colors.white70
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // ─── ✅ PROFESSIONAL: Edit Account Dialog ──────────────────────
  void _showEditAccountDialog(
    BuildContext context,
    Map<String, dynamic> account,
    ChartOfAccountController controller,
  ) {
    final formKey = GlobalKey<FormState>();
    String accountCode = account['code'];
    String accountName = account['name'];
    String accountType = account['type'];
    String parentAccount = account['parentAccount'] ?? '';
    String description = account['description'] ?? '';
    String taxCode = account['taxCode'] ?? 'N/A';
    double openingBalance = account['balance'];
    String? typeError;

    bool isSaving = false;

    final Map<String, List<String>> parentAccountMapping = {
      'Assets': ['Current Assets', 'Fixed Assets'],
      'Liabilities': ['Current Liabilities', 'Long Term Liabilities'],
      'Equity': ['Capital / Equity'],
      'Income': ['Operating Income'],
      'Expenses': ['Operating Expenses'],
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final parentAccounts = parentAccountMapping[accountType] ?? [];
          if (parentAccount.isNotEmpty &&
              !parentAccounts.contains(parentAccount)) {
            parentAccount = '';
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit, color: kPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              Text(
                                'Update account details',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _proFormField(
                              'Account Code',
                              'e.g., 1010',
                              (v) => accountCode = v,
                              initialValue: accountCode,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              enabled: !isSaving,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Account Name',
                              'e.g., Cash in Hand',
                              (v) {
                                accountName = v;
                                final nameLower = v.toLowerCase();
                                final isCashOrBank =
                                    nameLower.contains('cash') ||
                                    nameLower.contains('bank') ||
                                    nameLower.contains('money');
                                if (isCashOrBank && accountType != 'Assets') {
                                  setState(() {
                                    typeError =
                                        'Cash/Bank accounts must be of type "Assets"';
                                  });
                                } else {
                                  setState(() {
                                    typeError = null;
                                  });
                                }
                              },
                              initialValue: accountName,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              enabled: !isSaving,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _proDropdownField<String>(
                              label: 'Account Type',
                              value: accountType,
                              items: const [
                                'Assets',
                                'Liabilities',
                                'Equity',
                                'Income',
                                'Expenses',
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (v) {
                                      setState(() {
                                        accountType = v!;
                                        parentAccount = '';
                                        final nameLower = accountName
                                            .toLowerCase();
                                        final isCashOrBank =
                                            nameLower.contains('cash') ||
                                            nameLower.contains('bank') ||
                                            nameLower.contains('money');
                                        if (isCashOrBank &&
                                            accountType != 'Assets') {
                                          typeError =
                                              'Cash/Bank accounts must be of type "Assets"';
                                        } else {
                                          typeError = null;
                                        }
                                      });
                                    },
                              isRequired: true,
                            ),
                            if (typeError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        typeError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _proDropdownField<String>(
                              label: 'Parent Account',
                              value: parentAccount.isEmpty
                                  ? null
                                  : parentAccount,
                              items: parentAccounts,
                              onChanged: isSaving
                                  ? null
                                  : (v) => setState(() => parentAccount = v!),
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Opening Balance',
                              '0.00',
                              (v) => openingBalance = double.tryParse(v) ?? 0.0,
                              keyboardType: TextInputType.number,
                              prefixText: CurrencyUtils.prefix,
                              initialValue: openingBalance.toString(),
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            TaxCodeField(
                              value: taxCode,
                              enabled: !isSaving,
                              onChanged: (v) => setState(() => taxCode = v),
                            ),
                            const SizedBox(height: 16),
                            _proFormField(
                              'Description',
                              'Account description',
                              (v) => description = v,
                              initialValue: description,
                              maxLines: 3,
                              enabled: !isSaving,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isSaving
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: kText,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSaving ? Colors.grey : kText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (typeError != null) {
                                      AppSnackbar.error(
                                        Colors.red,
                                        'Error',
                                        typeError!,
                                      );
                                      return;
                                    }
                                    if (formKey.currentState!.validate()) {
                                      setState(() {
                                        isSaving = true;
                                      });

                                      await controller
                                          .updateAccount(account['id'], {
                                            'code': accountCode,
                                            'name': accountName,
                                            'type': accountType,
                                            'parentAccount': parentAccount,
                                            'openingBalance': openingBalance,
                                            'description': description,
                                            'taxCode': taxCode,
                                          });

                                      Navigator.pop(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSaving
                                  ? Colors.grey
                                  : kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSaving) ...[
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isSaving ? 'Updating...' : 'Update Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSaving
                                        ? Colors.white70
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // ─── Search Dialog ──────────────────────────────────────────────
  void _showSearchDialog(
    BuildContext context,
    ChartOfAccountController controller,
  ) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Accounts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter account name or code',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onSubmitted: (value) {
            controller.searchAccounts(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              controller.searchAccounts(searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ─── Filter Dialog ──────────────────────────────────────────────
  void _showFilterDialog(
    BuildContext context,
    ChartOfAccountController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Filter Accounts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter options coming soon...'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildFilterOption('Positive Balance', true),
                  _buildFilterOption('Zero Balance', false),
                  _buildFilterOption('Active Only', true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppSnackbar.success(Colors.green, 'Filter', 'Filter applied');
            },
            child: const Text('Apply', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, bool value) {
    return CheckboxListTile(
      value: value,
      title: Text(label, style: TextStyle(fontSize: 13, color: kText)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (v) {},
    );
  }

  // ─── Detail Row ──────────────────────────────────────────────────
  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Professional Form Field ──────────────────────────────────────
  Widget _proFormField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String? initialValue,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    bool enabled = true,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            isDense: true,
          ),
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  // ─── Professional Dropdown Field ───────────────────────────────────
  Widget _proDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
    List<String>? displayLabels,
    bool isRequired = false,
  }) {
    final isEnabled = onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: isEnabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            isDense: true,
          ),
          style: TextStyle(
            fontSize: 14,
            color: isEnabled ? Colors.black87 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items
              .asMap()
              .entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.value,
                  child: Text(
                    displayLabels != null ? displayLabels[e.key] : '${e.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String? initialValue,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
      ),
      style: TextStyle(
        fontSize: 13,
        color: enabled ? Colors.black87 : Colors.grey.shade600,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  // ─── Legacy Dropdown Field (kept for compatibility) ───────────────
  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
    List<String>? displayLabels,
  }) {
    final isEnabled = onChanged != null;
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        filled: true,
        fillColor: isEnabled ? Colors.white : Colors.grey.shade50,
      ),
      style: TextStyle(
        fontSize: 13,
        color: isEnabled ? Colors.black87 : Colors.grey.shade600,
      ),
      items: items
          .asMap()
          .entries
          .map(
            (e) => DropdownMenuItem<T>(
              value: e.value,
              child: Text(
                displayLabels != null ? displayLabels[e.key] : '${e.value}',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── Format Amount ──────────────────────────────────────────────
  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
