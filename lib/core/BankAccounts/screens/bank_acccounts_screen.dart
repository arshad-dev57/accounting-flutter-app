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

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, BankAccountController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileBankAccountsList(controller, context)),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, BankAccountController controller) {
    return AppBar(
      title: const Text(
        'Cash & Bank Ledgers',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black45),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddAccountDialog(Get.context!, controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.white),
          onPressed: () => controller.exportAccounts(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(BankAccountController controller, BuildContext context) {
    final List<String> filterOptions = ['All', 'Active', 'Inactive'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kCardBg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                onChanged: (value) => controller.searchAccounts(value),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.black45),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.black45),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: Obx(() => DropdownButton<String>(
                  value: controller.selectedFilter.value,
                  icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.black45),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                  items: filterOptions.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.changeFilter(value);
                  },
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryCards(BankAccountController controller, BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMobileSummaryCard('Total Balance', _formatCompactAmount(controller.totalBalance.value), kSuccess, Icons.account_balance),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('${CurrencyUtils.code} Balance', _formatCompactAmount(controller.total$.value), kPrimary, Icons.account_balance_wallet),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('USD Balance', _formatCompactAmount(controller.totalUSD.value), kWarning, Icons.attach_money),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Active', controller.activeCount.value.toString(), kPrimary, Icons.account_balance_wallet, isNumber: true),
          ],
        ),
      ),
    ));
  }

  Widget _buildMobileSummaryCard(String title, String amount, Color color, IconData icon, {bool isNumber = false}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title, style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildMobileBankAccountsList(BankAccountController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.bankAccounts;
      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, size: 64, color: Colors.black45.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No bank accounts found', style: TextStyle(fontSize: 16, color: Colors.black45)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddAccountDialog(Get.context!, controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Bank Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
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

  Widget _buildMobileAccountCard(BankAccount account, BankAccountController controller, BuildContext context) {
    return Card(
      color: kCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [account.color, account.color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.accountName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${account.bankName} • ${account.accountNumber}', style: TextStyle(fontSize: 10, color: Colors.black45), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          _buildMobileStatusBadge(account.status),
                          _buildMobileInfoBadge(account.accountType),
                          _buildMobileInfoBadge(account.currency),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Balance', style: TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      _formatCompactAmount(account.currentBalance),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: account.currentBalance >= 0 ? kSuccess : kDanger),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => const GeneralLedgerScreen()),
                    icon: const Icon(Icons.history, size: 14, color: Colors.black45),
                    label: const Text('History', style: TextStyle(fontSize: 11, color: Colors.black87)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => const TransferScreen()),
                    icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                    label: const Text('Transfer', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: account.color,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStatusBadge(String status) {
    Color color = status == 'Active' ? kSuccess : kDanger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMobileInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.black45, fontWeight: FontWeight.w500)),
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT — Professional, matches other screens
  // ─────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, BankAccountController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final animationSize = constraints.maxWidth > 1200 ? 48 : constraints.maxWidth > 800 ? 40 : 32;
                      return Container(
                        width: animationSize + 40,
                        height: animationSize + 40,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: LoadingAnimationWidget.waveDots(color: kPrimary, size: animationSize.toDouble()),
                        ),
                      );
                    },
                  ),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebBankAccountsTable(controller, context)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, BankAccountController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Cash & Bank Ledgers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black45),
          ),
          const Spacer(),
          // Search
          SizedBox(
            width: 240,
            height: 34,
            child: TextField(
              onChanged: (value) => controller.searchAccounts(value),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 16, color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter dropdown
          Container(
            width: 130,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(() => DropdownButton<String>(
                value: controller.selectedFilter.value,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.black45),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Colors.black45),
                dropdownColor: kCardBg,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Active', child: Text('Active', style: TextStyle(color: Colors.black87))),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(color: Colors.black87))),
                ],
                onChanged: (value) {
                  if (value != null) controller.changeFilter(value);
                },
              )),
            ),
          ),
          const SizedBox(width: 12),
          // Add Account button
          _webHeaderBtn(Icons.add, 'Add Account', () => _showAddAccountDialog(Get.context!, controller, context)),
          const SizedBox(width: 8),
          // Export button
          _webHeaderBtn(Icons.download_outlined, 'Export', () => controller.exportAccounts()),
        ],
      ),
    );
  }

  Widget _webHeaderBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.black45),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black45)),
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
          if (constraints.maxWidth < 1000) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                children: [
                  _buildWebKpiTile('Total Balance', _formatCompactAmount(controller.totalBalance.value), kSuccess, Icons.account_balance),
                  _buildWebKpiDivider(),
                  _buildWebKpiTile('${CurrencyUtils.code} Balance', _formatCompactAmount(controller.total$.value), kPrimary, Icons.account_balance_wallet),
                  _buildWebKpiDivider(),
                  _buildWebKpiTile('USD Balance', _formatCompactAmount(controller.totalUSD.value), kWarning, Icons.attach_money),
                  _buildWebKpiDivider(),
                  _buildWebKpiTile('Active Accounts', controller.activeCount.value.toString(), kPrimary, Icons.account_balance_wallet),
                ],
              )),
            );
          }
          return Obx(() => Row(
            children: [
              Expanded(child: _buildWebKpiTile('Total Balance', _formatCompactAmount(controller.totalBalance.value), kSuccess, Icons.account_balance)),
              _buildWebKpiDivider(),
              Expanded(child: _buildWebKpiTile('${CurrencyUtils.code} Balance', _formatCompactAmount(controller.total$.value), kPrimary, Icons.account_balance_wallet)),
              _buildWebKpiDivider(),
              Expanded(child: _buildWebKpiTile('USD Balance', _formatCompactAmount(controller.totalUSD.value), kWarning, Icons.attach_money)),
              _buildWebKpiDivider(),
              Expanded(child: _buildWebKpiTile('Active Accounts', controller.activeCount.value.toString(), kPrimary, Icons.account_balance_wallet)),
            ],
          ));
        },
      ),
    );
  }

  Widget _buildWebKpiTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiDivider() => Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(BankAccountController controller, BuildContext context) {
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
            'Cash & Bank Ledgers',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${controller.bankAccounts.length} accounts',
              style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWebBankAccountsTable(BankAccountController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.bankAccounts;

      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, size: 48, color: Colors.black45.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No bank accounts found', style: TextStyle(fontSize: 15, color: Colors.black45)),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () => _showAddAccountDialog(Get.context!, controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child:  Text('+ Add Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,color: Colors.black45)),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(flex: 3, child: _tableHeaderCell('Account')),
                Expanded(flex: 2, child: _tableHeaderCell('Bank')),
                Expanded(flex: 1, child: _tableHeaderCell('Type')),
                Expanded(flex: 1, child: _tableHeaderCell('Currency')),
                Expanded(flex: 2, child: _tableHeaderCell('Opening Balance', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Current Balance', align: TextAlign.right)),
                Expanded(flex: 1, child: _tableHeaderCell('Status', align: TextAlign.center)),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _buildWebTableRow(account, controller, context);
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
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45, letterSpacing: 0.5),
    );
  }

  Widget _buildWebTableRow(BankAccount account, BankAccountController controller, BuildContext context) {
    final balancePositive = account.currentBalance >= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAccountDetails(account, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [account.color, account.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              // Account Name + Number
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(account.accountName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    Text(account.accountNumber,
                        style: TextStyle(fontSize: 10, color: Colors.black45),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              // Bank Name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(account.bankName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                    if (account.branchCode.isNotEmpty)
                      Text(account.branchCode,
                          style: TextStyle(fontSize: 10, color: Colors.black45),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              // Type
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(account.accountType,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kPrimary)),
                ),
              ),
              // Currency
              Expanded(
                flex: 1,
                child: Text(account.currency,
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
              ),
              // Opening Balance
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(account.openingBalance),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ),
              // Current Balance
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: balancePositive ? kSuccess.withOpacity(0.08) : kDanger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatAmount(account.currentBalance),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: account.status == 'Active' ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: account.status == 'Active' ? kSuccess : kDanger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          account.status == 'Active' ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: account.status == 'Active' ? kSuccess : kDanger,
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
                    _webIconBtn(Icons.history, Colors.black45, () => Get.to(() => const GeneralLedgerScreen())),
                    const SizedBox(width: 4),
                    _webIconBtn(Icons.swap_horiz, account.color, () => Get.to(() => const TransferScreen())),
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
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 28, height: 28,
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
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Container(width: 52),
          const Expanded(flex: 3, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87))),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 1, child: SizedBox()),
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(_formatAmount(totalOpening), textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatAmount(totalCurrent),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSuccess),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '$activeCount Active',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kSuccess),
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SHARED DIALOGS
  // ─────────────────────────────────────────
  void _showAddAccountDialog(BuildContext context, BankAccountController controller, BuildContext ctx) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    String accountName = '';
    String accountNumber = '';
    String bankName = '';
    String branchCode = '';
    String accountType = 'Current';
    String currency = '\$';
    double openingBalance = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 12 : 16)),
            child: Container(
              width: isWeb ? 480 : double.infinity,
              constraints: BoxConstraints(maxHeight: isWeb ? 650 : 550),
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Add Bank Account', style: TextStyle(fontSize: isWeb ? 16 : 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: isWeb ? 20 : 16, color: Colors.grey.withOpacity(0.2)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            if (isWeb)
                              Row(children: [
                                Expanded(child: _formField('Account Name *', 'e.g., HBL Current', (v) => accountName = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb)),
                                const SizedBox(width: 12),
                                Expanded(child: _formField('Account Number *', 'e.g., 1234-5678', (v) => accountNumber = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb)),
                              ])
                            else ...[
                              _formField('Account Name *', 'e.g., HBL Current', (v) => accountName = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb),
                              const SizedBox(height: 12),
                              _formField('Account Number *', 'e.g., 1234-5678', (v) => accountNumber = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb),
                            ],
                            const SizedBox(height: 12),
                            if (isWeb)
                              Row(children: [
                                Expanded(child: _formField('Bank Name *', 'e.g., Habib Bank', (v) => bankName = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb)),
                                const SizedBox(width: 12),
                                Expanded(child: _formField('Branch Code', 'e.g., 0123', (v) => branchCode = v, isWeb: isWeb)),
                              ])
                            else ...[
                              _formField('Bank Name *', 'e.g., Habib Bank', (v) => bankName = v, validator: (v) => v?.isEmpty == true ? 'Required' : null, isWeb: isWeb),
                              const SizedBox(height: 12),
                              _formField('Branch Code', 'e.g., 0123', (v) => branchCode = v, isWeb: isWeb),
                            ],
                            const SizedBox(height: 12),
                            if (isWeb)
                              Row(children: [
                                Expanded(child: _dropdownField(
                                  label: 'Account Type',
                                  value: accountType,
                                  items: const ['Current', 'Savings', 'Business', 'Islamic'],
                                  onChanged: (v) => setState(() => accountType = v!),
                                  isWeb: isWeb,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _dropdownField(
                                  label: 'Currency',
                                  value: currency,
                                  items: const ['\$', 'USD', 'EUR', 'GBP'],
                                  onChanged: (v) => setState(() => currency = v!),
                                  isWeb: isWeb,
                                )),
                              ])
                            else ...[
                              _dropdownField(
                                label: 'Account Type',
                                value: accountType,
                                items: const ['Current', 'Savings', 'Business', 'Islamic'],
                                onChanged: (v) => setState(() => accountType = v!),
                                isWeb: isWeb,
                              ),
                              const SizedBox(height: 12),
                              _dropdownField(
                                label: 'Currency',
                                value: currency,
                                items: const ['\$', 'USD', 'EUR', 'GBP'],
                                onChanged: (v) => setState(() => currency = v!),
                                isWeb: isWeb,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _formField('Opening Balance', '0.00', (v) => openingBalance = double.tryParse(v) ?? 0, keyboardType: TextInputType.number, prefixText: CurrencyUtils.prefix, isWeb: isWeb),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: isWeb ? 13 : 14, color: Colors.black45)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              controller.createBankAccount({
                                'accountName': accountName,
                                'accountNumber': accountNumber,
                                'bankName': bankName,
                                'branchCode': branchCode,
                                'accountType': accountType,
                                'currency': currency,
                                'openingBalance': openingBalance,
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: Text('Add Account', style: TextStyle(fontSize: isWeb ? 13 : 14, color: Colors.black45)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAccountDetails(BankAccount account, BankAccountController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 12 : 16)),
        child: Container(
          width: isWeb ? 420 : double.infinity,
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [account.color, account.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.accountName, style: TextStyle(fontSize: isWeb ? 16 : 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                        Text(account.accountNumber, style: TextStyle(fontSize: isWeb ? 12 : 13, color: Colors.black45)),
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
                padding: EdgeInsets.all(isWeb ? 16 : 14),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildDetailRow('Bank Name', account.bankName, isWeb),
                    const SizedBox(height: 10),
                    _buildDetailRow('Branch Code', account.branchCode.isEmpty ? '-' : account.branchCode, isWeb),
                    const SizedBox(height: 10),
                    _buildDetailRow('Account Type', account.accountType, isWeb),
                    const SizedBox(height: 10),
                    _buildDetailRow('Currency', account.currency, isWeb),
                    const SizedBox(height: 10),
                    _buildDetailRow('Opening Balance', _formatAmount(account.openingBalance), isWeb),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.withOpacity(0.2)),
                    const SizedBox(height: 10),
                    _buildDetailRow('Current Balance', _formatAmount(account.currentBalance), isWeb, valueColor: account.currentBalance >= 0 ? kSuccess : kDanger),
                    const SizedBox(height: 10),
                    _buildDetailRow('Status', account.status, isWeb, valueColor: account.status == 'Active' ? kSuccess : kDanger),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Get.to(() => const GeneralLedgerScreen());
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('View Ledger', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: account.color,
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 12 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
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

  Widget _buildDetailRow(String label, String value, bool isWeb, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isWeb ? 13 : 14, color: Colors.black45, fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
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
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black45),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: Colors.black87),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _dropdownField<T extends String>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required bool isWeb,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black45),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: Colors.black87),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  String _formatCompactAmount(double amount) => CurrencyUtils.formatCompact(amount);

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}