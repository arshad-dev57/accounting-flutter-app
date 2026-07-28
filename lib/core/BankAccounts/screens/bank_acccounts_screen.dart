  import 'package:LedgerPro_app/Utils/currency_utils.dart';
  import 'package:LedgerPro_app/Utils/colors.dart';
  import 'package:LedgerPro_app/Utils/responsive_utils.dart';
  import 'package:LedgerPro_app/Utils/toast_utils.dart';
  import 'package:LedgerPro_app/core/BankAccounts/controllers/bankaccount_controller.dart';
  import 'package:LedgerPro_app/core/GeneralLedger/Screen/general_ledger_screen.dart';
  import 'package:LedgerPro_app/core/Transfer/screen/transfer_screen.dart';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:intl/intl.dart';
  import 'package:loading_animation_widget/loading_animation_widget.dart';

  class BankAccountsScreen extends StatelessWidget {
    const BankAccountsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final controller = Get.put(BankAccountController());

      if (ResponsiveUtils.isMobile(context)) {
        return _buildMobileLayout(context, controller);
      }
      return _buildWebLayout(context, controller);
    }

    // ═══════════════════════════════════════════════════════════════
    // MOBILE LAYOUT
    // ═══════════════════════════════════════════════════════════════

    Widget _buildMobileLayout(
      BuildContext context,
      BankAccountController controller,
    ) {
      return Scaffold(
        backgroundColor: kBgLight,
        body: Column(
          children: [
            _buildMobileTopHeader(context, controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                      color: kPrimary,
                      size: 40,
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildMobileSummaryCards(controller),
                    Expanded(child: _buildMobileBankAccountsList(controller, context)),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    }

    // ── Mobile Top Header (matches TrialBalance style) ──
    Widget _buildMobileTopHeader(
      BuildContext context,
      BankAccountController controller,
    ) {
      return Container(
        color: kPrimary,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash & Bank Ledgers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Obx(
                            () => Text(
                              '${controller.bankAccounts.length} accounts',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black.withOpacity(0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.fetchBankAccounts,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showAddAccountDialog(context, controller, context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.exportAccounts(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.download_outlined,
                          size: 18,
                          color: Colors.black.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search + Filter row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
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
                          onChanged: (value) => controller.searchAccounts(value),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search accounts...',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      child: DropdownButtonHideUnderline(
                        child: Obx(
                          () => DropdownButton<String>(
                            value: controller.selectedFilter.value,
                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            underline: const SizedBox.shrink(),
                            items: ['All', 'Active', 'Inactive'].map((f) {
                              return DropdownMenuItem(value: f, child: Text(f));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) controller.changeFilter(v);
                            },
                          ),
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
    }

    // ── Mobile Summary Cards (matches TrialBalance layout) ──
    Widget _buildMobileSummaryCards(BankAccountController controller) {
      return Obx(
        () => Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            children: [
              // Top row: Total Balance + Active
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      label: 'Total Balance',
                      value: _formatCompactAmount(controller.totalBalance.value),
                      icon: Icons.account_balance_rounded,
                      accentColor: kSuccess,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      label: 'Active Accounts',
                      value: controller.activeCount.value.toString(),
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom: PKR + USD full width row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      label: '${CurrencyUtils.code} Balance',
                      value: _formatCompactAmount(controller.total$.value),
                      icon: Icons.currency_exchange_rounded,
                      accentColor: const Color(0xFF9B59B6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      label: 'USD Balance',
                      value: _formatCompactAmount(controller.totalUSD.value),
                      icon: Icons.attach_money_rounded,
                      accentColor: kWarning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildSummaryTile({
      required String label,
      required String value,
      required IconData icon,
      required Color accentColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.18), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: kSubText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Mobile Accounts List ──
    Widget _buildMobileBankAccountsList(
      BankAccountController controller,
      BuildContext context,
    ) {
      return Obx(() {
        final accounts = controller.bankAccounts;
        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance,
                  size: 64,
                  color: kSubText.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No bank accounts found',
                  style: TextStyle(fontSize: 16, color: kSubText),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      _showAddAccountDialog(Get.context!, controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add Account',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMobileAccountCard(account, controller, context),
            );
          },
        );
      });
    }

    // ── Mobile Account Card (matches TrialBalance account card) ──
    Widget _buildMobileAccountCard(
      BankAccount account,
      BankAccountController controller,
      BuildContext context,
    ) {
      final isActive = account.status == 'Active';
      final balancePositive = account.currentBalance >= 0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: account.color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: account.color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAccountDetails(account, controller, context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: account.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: account.color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 20,
                          color: account.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.accountName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kText,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${account.bankName} • ${account.accountNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: kSubText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                _badge(
                                  account.status,
                                  isActive ? kSuccess : kDanger,
                                ),
                                _badge(account.accountType, kSubText),
                                _badge(account.currency, kSubText),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Balance pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: balancePositive
                              ? kSuccess.withOpacity(0.1)
                              : kDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: balancePositive
                                ? kSuccess.withOpacity(0.2)
                                : kDanger.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Balance',
                              style: TextStyle(
                                fontSize: 8,
                                color: kSubText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                _formatCompactAmount(account.currentBalance),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: balancePositive ? kSuccess : kDanger,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Opening vs Current balance boxes
                  Row(
                    children: [
                      Expanded(
                        child: _amountBox(
                          label: 'OPENING',
                          value: _formatCompactAmount(account.openingBalance),
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _amountBox(
                          label: 'CURRENT',
                          value: _formatCompactAmount(account.currentBalance),
                          color: balancePositive ? kSuccess : kDanger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.to(() => const GeneralLedgerScreen()),
                          icon: Icon(Icons.history, size: 14, color: kSubText),
                          label: Text(
                            'History',
                            style: TextStyle(
                              fontSize: 12,
                              color: kText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Get.to(() => const TransferScreen()),
                          icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                          label: const Text(
                            'Transfer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: account.color,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // WEB LAYOUT
    // ═══════════════════════════════════════════════════════════════

    Widget _buildWebLayout(
      BuildContext context,
      BankAccountController controller,
    ) {
      return Scaffold(
        backgroundColor: kBg,
        body: Column(
          children: [
            _buildWebTopBar(context, controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: kPrimary,
                      size: 40,
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildWebKpiStrip(controller),
                    _buildWebToolbar(controller, context),
                    Expanded(
                      child: _buildWebBankAccountsTable(controller, context),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    }

    Widget _buildWebTopBar(
      BuildContext context,
      BankAccountController controller,
    ) {
      return Container(
        height: 56,
        color: kPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Text(
              'Cash & Bank Ledgers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 240,
              height: 34,
              child: TextField(
                onChanged: (value) => controller.searchAccounts(value),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Search accounts...',
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.45),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 130,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: Obx(
                  () => DropdownButton<String>(
                    value: controller.selectedFilter.value,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    dropdownColor: kCardBg,
                    items: ['All', 'Active', 'Inactive'].map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f, style: const TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) controller.changeFilter(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _webHeaderBtn(
              Icons.add,
              'Add Account',
              () => _showAddAccountDialog(Get.context!, controller, context),
            ),
            const SizedBox(width: 8),
            _webHeaderBtn(
              Icons.download_outlined,
              'Export',
              () => controller.exportAccounts(),
            ),
          ],
        ),
      );
    }

    Widget _webHeaderBtn(IconData icon, String label, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: Colors.black.withOpacity(0.65)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildWebKpiStrip(BankAccountController controller) {
      return Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tiles = [
              _buildWebKpiTile(
                'Total Balance',
                _formatCompactAmount(controller.totalBalance.value),
                kSuccess,
                Icons.account_balance_rounded,
              ),
              _buildWebKpiTile(
                '${CurrencyUtils.code} Balance',
                _formatCompactAmount(controller.total$.value),
                const Color(0xFF9B59B6),
                Icons.currency_exchange_rounded,
              ),
              _buildWebKpiTile(
                'USD Balance',
                _formatCompactAmount(controller.totalUSD.value),
                kWarning,
                Icons.attach_money_rounded,
              ),
              _buildWebKpiTile(
                'Active Accounts',
                controller.activeCount.value.toString(),
                kPrimary,
                Icons.account_balance_wallet_rounded,
              ),
            ];

            if (constraints.maxWidth < 1000) {
              return Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < tiles.length; i++) ...[
                        tiles[i],
                        if (i < tiles.length - 1) _kpiDivider(),
                      ],
                    ],
                  ),
                ),
              );
            }
            return Obx(
              () => Row(
                children: [
                  for (int i = 0; i < tiles.length; i++) ...[
                    Expanded(child: tiles[i]),
                    if (i < tiles.length - 1) _kpiDivider(),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    Widget _buildWebKpiTile(
      String label,
      String value,
      Color color,
      IconData icon,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _kpiDivider() =>
        Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

    Widget _buildWebToolbar(
      BankAccountController controller,
      BuildContext context,
    ) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kBg,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
            top: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            const Text(
              'Bank Accounts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.bankAccounts.length} accounts',
                  style: TextStyle(
                    fontSize: 11,
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildWebBankAccountsTable(
      BankAccountController controller,
      BuildContext context,
    ) {
      return Obx(() {
        final accounts = controller.bankAccounts;

        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance,
                  size: 56,
                  color: kSubText.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No bank accounts found',
                  style: TextStyle(fontSize: 15, color: kSubText),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      _showAddAccountDialog(Get.context!, controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '+ Add Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Table Header
            Container(
              height: 36,
              color: kBg,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const SizedBox(width: 52),
                  Expanded(flex: 3, child: _tableHeaderCell('Account')),
                  Expanded(flex: 2, child: _tableHeaderCell('Bank')),
                  Expanded(flex: 1, child: _tableHeaderCell('Type')),
                  Expanded(flex: 1, child: _tableHeaderCell('Currency')),
                  Expanded(
                    flex: 2,
                    child: _tableHeaderCell('Opening Balance', align: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: _tableHeaderCell('Current Balance', align: TextAlign.right),
                  ),
                  Expanded(
                    flex: 1,
                    child: _tableHeaderCell('Status', align: TextAlign.center),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey.withOpacity(0.15)),
            Expanded(
              child: ListView.separated(
                itemCount: accounts.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  return _buildWebTableRow(accounts[index], controller, context);
                },
              ),
            ),
            _buildWebTableFooter(accounts),
          ],
        );
      });
    }

    Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
      return Text(
        text.toUpperCase(),
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: kSubText,
          letterSpacing: 0.5,
        ),
      );
    }

    Widget _buildWebTableRow(
      BankAccount account,
      BankAccountController controller,
      BuildContext context,
    ) {
      final balancePositive = account.currentBalance >= 0;
      final isActive = account.status == 'Active';

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountDetails(account, controller, context),
          hoverColor: kPrimary.withOpacity(0.03),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: account.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: account.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    size: 18,
                    color: account.color,
                  ),
                ),
                const SizedBox(width: 12),
                // Account Name + Number
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account.accountName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        account.accountNumber,
                        style: TextStyle(fontSize: 10, color: kSubText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Bank
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account.bankName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (account.branchCode.isNotEmpty)
                        Text(
                          account.branchCode,
                          style: TextStyle(fontSize: 10, color: kSubText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Type badge
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      account.accountType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Currency
                Expanded(
                  flex: 1,
                  child: Text(
                    account.currency,
                    style: TextStyle(fontSize: 12, color: kSubText),
                  ),
                ),
                // Opening Balance
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatAmount(account.openingBalance),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: kSubText),
                  ),
                ),
                // Current Balance
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: balancePositive
                          ? kSuccess.withOpacity(0.08)
                          : kDanger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: balancePositive
                            ? kSuccess.withOpacity(0.15)
                            : kDanger.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      _formatAmount(account.currentBalance),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: balancePositive ? kSuccess : kDanger,
                      ),
                    ),
                  ),
                ),
                // Status
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? kSuccess.withOpacity(0.1)
                            : kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? kSuccess.withOpacity(0.2)
                              : kDanger.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isActive ? kSuccess : kDanger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? kSuccess : kDanger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _webIconBtn(
                        Icons.history,
                        kSubText,
                        () => Get.to(() => const GeneralLedgerScreen()),
                      ),
                      const SizedBox(width: 4),
                      _webIconBtn(
                        Icons.swap_horiz,
                        account.color,
                        () => Get.to(() => const TransferScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
    }

    Widget _buildWebTableFooter(List<BankAccount> accounts) {
      final totalOpening = accounts.fold(0.0, (s, a) => s + a.openingBalance);
      final totalCurrent = accounts.fold(0.0, (s, a) => s + a.currentBalance);
      final activeCount = accounts.where((a) => a.status == 'Active').length;

      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.04),
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 52),
            const Expanded(
              flex: 3,
              child: Text(
                'TOTAL',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Expanded(flex: 2, child: SizedBox()),
            const Expanded(flex: 1, child: SizedBox()),
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(
              flex: 2,
              child: Text(
                _formatAmount(totalOpening),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: kSuccess.withOpacity(0.2)),
                ),
                child: Text(
                  _formatAmount(totalCurrent),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: kSuccess,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$activeCount Active',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: kSuccess,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // SHARED DIALOGS
    // ═══════════════════════════════════════════════════════════════

    void _showAddAccountDialog(
      BuildContext context,
      BankAccountController controller,
      BuildContext ctx,
    ) {
      final isWeb = ResponsiveUtils.isWeb(ctx);
      final formKey = GlobalKey<FormState>();
      String accountName = '';
      String accountNumber = '';
      String bankName = '';
      String branchCode = '';
      String accountType = 'Current';
      String currency = '\$';
      double openingBalance = 0;
      bool isSaving = false;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                width: isWeb ? 480 : double.infinity,
                constraints: BoxConstraints(
                  maxHeight: isWeb ? 650 : MediaQuery.of(context).size.height * 0.88,
                  maxWidth: 500,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Bank Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create a new bank account',
                                  style: TextStyle(fontSize: 12, color: kSubText),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              if (isWeb)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _formField(
                                        'Account Name *',
                                        'e.g., HBL Current',
                                        (v) => accountName = v,
                                        validator: (v) =>
                                            v?.isEmpty == true ? 'Required' : null,
                                        isWeb: isWeb,
                                        enabled: !isSaving,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _formField(
                                        'Account Number *',
                                        'e.g., 1234-5678',
                                        (v) => accountNumber = v,
                                        validator: (v) =>
                                            v?.isEmpty == true ? 'Required' : null,
                                        isWeb: isWeb,
                                        enabled: !isSaving,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _formField(
                                  'Account Name *',
                                  'e.g., HBL Current',
                                  (v) => accountName = v,
                                  validator: (v) =>
                                      v?.isEmpty == true ? 'Required' : null,
                                  isWeb: isWeb,
                                  enabled: !isSaving,
                                ),
                                const SizedBox(height: 16),
                                _formField(
                                  'Account Number *',
                                  'e.g., 1234-5678',
                                  (v) => accountNumber = v,
                                  validator: (v) =>
                                      v?.isEmpty == true ? 'Required' : null,
                                  isWeb: isWeb,
                                  enabled: !isSaving,
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (isWeb)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _formField(
                                        'Bank Name *',
                                        'e.g., Habib Bank',
                                        (v) => bankName = v,
                                        validator: (v) =>
                                            v?.isEmpty == true ? 'Required' : null,
                                        isWeb: isWeb,
                                        enabled: !isSaving,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _formField(
                                        'Branch Code',
                                        'e.g., 0123',
                                        (v) => branchCode = v,
                                        isWeb: isWeb,
                                        enabled: !isSaving,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _formField(
                                  'Bank Name *',
                                  'e.g., Habib Bank',
                                  (v) => bankName = v,
                                  validator: (v) =>
                                      v?.isEmpty == true ? 'Required' : null,
                                  isWeb: isWeb,
                                  enabled: !isSaving,
                                ),
                                const SizedBox(height: 16),
                                _formField(
                                  'Branch Code',
                                  'e.g., 0123',
                                  (v) => branchCode = v,
                                  isWeb: isWeb,
                                  enabled: !isSaving,
                                ),
                              ],
                              const SizedBox(height: 16),
                              _dropdownField(
                                label: 'Account Type',
                                value: accountType,
                                items: const ['Current', 'Savings', 'Business', 'Islamic'],
                                onChanged: (v) => setState(() => accountType = v!),
                                isWeb: isWeb,
                                enabled: !isSaving,
                              ),
                              const SizedBox(height: 16),
                              _formField(
                                'Opening Balance',
                                '0.00',
                                (v) => openingBalance = double.tryParse(v) ?? 0,
                                keyboardType: TextInputType.number,
                                prefixText: CurrencyUtils.prefix,
                                isWeb: isWeb,
                                enabled: !isSaving,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
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
                                      if (formKey.currentState!.validate()) {
                                        setState(() => isSaving = true);
                                        final success = await controller.createBankAccount({
                                          'accountName': accountName,
                                          'accountNumber': accountNumber,
                                          'bankName': bankName,
                                          'branchCode': branchCode,
                                          'accountType': accountType,
                                          'openingBalance': openingBalance,
                                        });
                                        if (success) {
                                          Navigator.pop(context);
                                        } else {
                                          setState(() => isSaving = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Adding...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Add Account',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
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

    void _showAccountDetails(
      BankAccount account,
      BankAccountController controller,
      BuildContext context,
    ) {
      final isWeb = ResponsiveUtils.isWeb(context);

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: isWeb ? 420 : double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: account.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: account.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 24,
                        color: account.color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.accountName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          Text(
                            account.accountNumber,
                            style: TextStyle(fontSize: 12, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Bank Name', account.bankName),
                      const SizedBox(height: 10),
                      _detailRow(
                        'Branch Code',
                        account.branchCode.isEmpty ? '—' : account.branchCode,
                      ),
                      const SizedBox(height: 10),
                      _detailRow('Account Type', account.accountType),
                      const SizedBox(height: 10),
                      _detailRow('Currency', account.currency),
                      const SizedBox(height: 10),
                      _detailRow(
                        'Opening Balance',
                        _formatAmount(account.openingBalance),
                      ),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _detailRow(
                        'Current Balance',
                        _formatAmount(account.currentBalance),
                        valueColor: account.currentBalance >= 0 ? kSuccess : kDanger,
                      ),
                      const SizedBox(height: 10),
                      _detailRow(
                        'Status',
                        account.status,
                        valueColor: account.status == 'Active' ? kSuccess : kDanger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Get.to(() => const GeneralLedgerScreen());
                    },
                    icon: const Icon(Icons.history, size: 18, color: Colors.black),
                    label: const Text(
                      'View Ledger',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // SHARED HELPERS
    // ═══════════════════════════════════════════════════════════════

    Widget _badge(String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    Widget _amountBox({
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    Widget _detailRow(String label, String value, {Color? valueColor}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
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
      required bool isWeb,
      bool enabled = true,
    }) {
      return TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
          labelStyle: TextStyle(fontSize: 12, color: kSubText),
        ),
        style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        enabled: enabled,
      );
    }

    Widget _dropdownField<T extends String>({
      required String label,
      required T value,
      required List<T> items,
      required void Function(T?) onChanged,
      required bool isWeb,
      bool enabled = true,
    }) {
      return DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
          labelStyle: TextStyle(fontSize: 12, color: kSubText),
        ),
        style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: enabled ? onChanged : null,
      );
    }

    String _formatCompactAmount(double amount) => CurrencyUtils.formatCompact(amount);
    String _formatAmount(double amount) => CurrencyUtils.format(amount);
  }