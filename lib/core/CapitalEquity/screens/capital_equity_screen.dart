import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/CapitalEquity/controller/equity_controller.dart';
import 'package:LedgerPro_app/core/CapitalEquity/models/equity_model.dart';
import 'package:LedgerPro_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CapitalEquityScreen extends StatelessWidget {
  const CapitalEquityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EquityController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, EquityController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.equityAccounts.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileTabSection(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.equityAccounts.isEmpty) {
            AppSnackbar.error(
              Colors.yellow,
              'No Equity Account',
              'Please add an Equity account from Chart of Accounts first',
              duration: const Duration(seconds: 3),
            );
            Get.to(() => const ChartOfAccountsScreen());
          } else {
            controller.showAddTransactionDialog();
          }
        },
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, EquityController controller) {
    return AppBar(
      title: const Text(
        'Capital & Equity',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showMobileSearch(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.calculate_outlined, color: Colors.black87),
          onPressed: () => controller.calculateEquity(),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportEquity(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(EquityController controller, BuildContext context) {
    final filters = ['All', 'Capital', 'Retained Earnings', 'Drawings', 'Reserves'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: filters.map((f) {
            final isSelected = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (_) => controller.applyFilter(isSelected ? 'All' : f),
                backgroundColor: kBg,
                selectedColor: kPrimary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? kPrimary : kSubText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildMobileSummaryCards(EquityController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildMobileSummaryCard('Total Equity', controller.formatAmount(controller.totalEquity.value), kPrimary, Icons.account_balance_wallet),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Capital', controller.formatAmount(controller.totalCapital.value), kPrimary, Icons.account_balance),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Retained', controller.formatAmount(controller.totalRetainedEarnings.value), kSuccess, Icons.trending_up),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Reserves', controller.formatAmount(controller.totalReserves.value), kWarning, Icons.savings),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Drawings', controller.formatAmount(controller.totalDrawings.value), kDanger, Icons.remove_circle_outline),
          ],
        )),
      ),
    );
  }

  Widget _buildMobileSummaryCard(String title, String value, Color color, IconData icon) {
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
            Flexible(child: Text(title, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMobileTabSection(EquityController controller, BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: kCardBg,
            child: TabBar(
              tabs: const [
                Tab(text: 'Equity Accounts'),
                Tab(text: 'Transactions'),
              ],
              labelColor: kPrimary,
              unselectedLabelColor: kSubText,
              indicatorColor: kPrimary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMobileEquityAccountsList(controller, context),
                _buildMobileTransactionHistory(controller, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEquityAccountsList(EquityController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.equityAccounts;
      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_outlined, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No equity accounts found', style: TextStyle(fontSize: 16, color: kSubText)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: accounts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileEquityCard(accounts[index], controller, context),
        ),
      );
    });
  }

  Widget _buildMobileEquityCard(EquityAccount account, EquityController controller, BuildContext context) {
    final typeColor = _getTypeColor(account.accountType);
    final typeIcon = _getTypeIcon(account.accountType);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.showAccountDetails(account),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(typeIcon, size: 20, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(account.accountName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          const SizedBox(height: 2),
                          Text(account.accountCode,
                              style: TextStyle(fontSize: 11, color: kSubText)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(account.accountType,
                                style: TextStyle(fontSize: 8, color: typeColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Balance', style: TextStyle(fontSize: 9, color: kSubText)),
                        Text(controller.formatAmount(account.currentBalance),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: typeColor)),
                        Text('+${controller.formatAmount(account.additions)}',
                            style: TextStyle(fontSize: 10, color: kSuccess, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.showAccountDetails(account),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text('Details', style: TextStyle(fontSize: 11, color: kText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (account.accountType == 'Capital')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.showAddCapitalDialog(account),
                          icon: const Icon(Icons.add_circle, size: 14, color: Colors.black87),
                          label: const Text('Add Capital', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      )
                    else if (account.accountType == 'Drawings')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.showRecordDrawingsDialog(account),
                          icon: const Icon(Icons.remove_circle, size: 14, color: Colors.white),
                          label: const Text('Record', style: TextStyle(fontSize: 11, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.showTransactionHistory(account),
                          icon: const Icon(Icons.history, size: 14),
                          label: const Text('History', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
        ),
      ),
    );
  }

  Widget _buildMobileTransactionHistory(EquityController controller, BuildContext context) {
    return Obx(() {
      final txns = controller.transactions;
      if (txns.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No transactions found', style: TextStyle(fontSize: 16, color: kSubText)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: txns.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTransactionCard(txns[index], controller),
        ),
      );
    });
  }

  Widget _buildTransactionCard(OwnerTransaction transaction, EquityController controller) {
    final typeColor = transaction.type == 'Additional Capital'
        ? kSuccess
        : transaction.type == 'Retained Earnings'
            ? kPrimary
            : transaction.type == 'Reserve Transfer'
                ? kWarning
                : kDanger;
    final typeIcon = transaction.type == 'Additional Capital'
        ? Icons.add_circle
        : transaction.type == 'Retained Earnings'
            ? Icons.trending_up
            : transaction.type == 'Reserve Transfer'
                ? Icons.swap_horiz
                : Icons.remove_circle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(typeIcon, size: 18, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(transaction.type, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(transaction.status, style: TextStyle(fontSize: 8, color: kSuccess, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(transaction.accountName, style: TextStyle(fontSize: 11, color: kSubText), overflow: TextOverflow.ellipsis),
                if (transaction.description.isNotEmpty)
                  Text(transaction.description, style: TextStyle(fontSize: 10, color: kSubText), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(controller.formatAmount(transaction.amount),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: typeColor)),
              const SizedBox(height: 2),
              Text(DateFormat('dd MMM yyyy').format(transaction.date),
                  style: TextStyle(fontSize: 9, color: kSubText)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, EquityController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.equityAccounts.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebTabSection(controller, context)),
                  _buildWebPaginationBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, EquityController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Capital & Equity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search account name, code…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black45),
                filled: true,
                fillColor: Colors.white.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => controller.calculateEquity(),
            icon: const Icon(Icons.calculate_outlined, size: 15, color: Colors.black87),
            label: const Text('Recalculate', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.exportEquity(),
            icon: const Icon(Icons.download_outlined, size: 15, color: Colors.black87),
            label: const Text('Export', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.printEquity(),
            icon: const Icon(Icons.print_outlined, size: 15, color: Colors.black87),
            label: const Text('Print', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.equityAccounts.isEmpty) {
                AppSnackbar.error(Colors.yellow, 'No Equity Account',
                    'Please add an Equity account from Chart of Accounts first',
                    duration: const Duration(seconds: 3));
                Get.to(() => const ChartOfAccountsScreen());
              } else {
                controller.showAddTransactionDialog();
              }
            },
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text('Add Transaction', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiStrip(EquityController controller) {
    return Obx(() => Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          _buildWebKpiTile('Total Equity', controller.formatAmount(controller.totalEquity.value), kPrimary, Icons.account_balance_wallet),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Capital', controller.formatAmount(controller.totalCapital.value), kPrimary, Icons.account_balance),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Retained Earnings', controller.formatAmount(controller.totalRetainedEarnings.value), kSuccess, Icons.trending_up),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Reserves', controller.formatAmount(controller.totalReserves.value), kWarning, Icons.savings),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Drawings', controller.formatAmount(controller.totalDrawings.value), kDanger, Icons.remove_circle_outline),
        ],
      ),
    ));
  }

  Widget _buildWebKpiTile(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
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
                Text(label, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(EquityController controller, BuildContext context) {
    final filters = ['All', 'Capital', 'Retained Earnings', 'Drawings', 'Reserves'];
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
      child: Obx(() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => controller.applyFilter(f),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? kPrimary : kSubText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )),
    );
  }

  // ==================== WEB TAB SECTION ====================

  Widget _buildWebTabSection(EquityController controller, BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: kCardBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Equity Accounts'),
                    Tab(text: 'Transaction History'),
                  ],
                  labelColor: kPrimary,
                  unselectedLabelColor: kSubText,
                  indicatorColor: kPrimary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.1)),
          Expanded(
            child: TabBarView(
              children: [
                _buildWebEquityAccountsTable(controller, context),
                _buildWebTransactionHistory(controller, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebEquityAccountsTable(EquityController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.equityAccounts;

      if (accounts.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_outlined, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No equity accounts found', style: TextStyle(fontSize: 15, color: kSubText)),
              const SizedBox(height: 8),
              Text('Add equity accounts from Chart of Accounts', style: TextStyle(fontSize: 12, color: kSubText)),
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
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _tableHeaderCell('Code')),
                Expanded(flex: 3, child: _tableHeaderCell('Account Name')),
                Expanded(flex: 2, child: _tableHeaderCell('Type')),
                Expanded(flex: 2, child: _tableHeaderCell('Opening', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Additions', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Withdrawals', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Balance', align: TextAlign.right)),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebAccountRow(accounts[index], controller, context),
            ),
          ),
          if (accounts.isNotEmpty) _buildWebAccountsFooter(accounts, controller),
        ],
      );
    });
  }

  Widget _buildWebAccountRow(EquityAccount account, EquityController controller, BuildContext context) {
    final typeColor = _getTypeColor(account.accountType);
    final typeIcon = _getTypeIcon(account.accountType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.showAccountDetails(account),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(typeIcon, size: 14, color: typeColor),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(account.accountCode,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(account.accountName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                  child: Text(account.accountType,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: typeColor),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(controller.formatAmount(account.openingBalance),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, color: kSubText)),
              ),
              Expanded(
                flex: 2,
                child: Text(controller.formatAmount(account.additions),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSuccess)),
              ),
              Expanded(
                flex: 2,
                child: Text(controller.formatAmount(account.withdrawals),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDanger)),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(controller.formatAmount(account.currentBalance),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor)),
                  ),
                ),
              ),
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(Icons.remove_red_eye_outlined, kSubText,
                        () => controller.showAccountDetails(account)),
                    const SizedBox(width: 4),
                    if (account.accountType == 'Capital')
                      _webIconBtn(Icons.add_circle_outline, kSuccess,
                          () => controller.showAddCapitalDialog(account))
                    else if (account.accountType == 'Drawings')
                      _webIconBtn(Icons.remove_circle_outline, kDanger,
                          () => controller.showRecordDrawingsDialog(account))
                    else
                      _webIconBtn(Icons.history, kPrimary,
                          () => controller.showTransactionHistory(account)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebAccountsFooter(List<EquityAccount> accounts, EquityController controller) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(controller.formatAmount(accounts.fold(0.0, (s, a) => s + a.openingBalance)),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(controller.formatAmount(accounts.fold(0.0, (s, a) => s + a.additions)),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSuccess)),
          ),
          Expanded(
            flex: 2,
            child: Text(controller.formatAmount(accounts.fold(0.0, (s, a) => s + a.withdrawals)),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDanger)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(controller.formatAmount(accounts.fold(0.0, (s, a) => s + a.currentBalance)),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kPrimary)),
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  Widget _buildWebTransactionHistory(EquityController controller, BuildContext context) {
    return Obx(() {
      final txns = controller.transactions;
      if (txns.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No transactions found', style: TextStyle(fontSize: 15, color: kSubText)),
            ],
          ),
        );
      }
      return Column(
        children: [
          // Header
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 3, child: _tableHeaderCell('Type')),
                Expanded(flex: 3, child: _tableHeaderCell('Account')),
                Expanded(flex: 4, child: _tableHeaderCell('Description')),
                Expanded(flex: 2, child: _tableHeaderCell('Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Reference')),
                Expanded(flex: 2, child: _tableHeaderCell('Amount', align: TextAlign.right)),
                Expanded(flex: 1, child: _tableHeaderCell('Status', align: TextAlign.center)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: txns.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTransactionRow(txns[index], controller),
            ),
          ),
          _buildWebTransactionFooter(txns, controller),
        ],
      );
    });
  }

  Widget _buildWebTransactionRow(OwnerTransaction transaction, EquityController controller) {
    final typeColor = transaction.type == 'Additional Capital'
        ? kSuccess
        : transaction.type == 'Retained Earnings'
            ? kPrimary
            : transaction.type == 'Reserve Transfer'
                ? kWarning
                : kDanger;
    final typeIcon = transaction.type == 'Additional Capital'
        ? Icons.add_circle
        : transaction.type == 'Retained Earnings'
            ? Icons.trending_up
            : transaction.type == 'Reserve Transfer'
                ? Icons.swap_horiz
                : Icons.remove_circle;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(typeIcon, size: 14, color: typeColor),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                child: Text(transaction.type,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(transaction.accountName,
                style: TextStyle(fontSize: 12, color: kSubText),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 4,
            child: Text(transaction.description,
                style: TextStyle(fontSize: 12, color: kSubText),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(DateFormat('dd MMM yyyy').format(transaction.date),
                style: TextStyle(fontSize: 12, color: kSubText)),
          ),
          Expanded(
            flex: 2,
            child: Text(transaction.reference,
                style: TextStyle(fontSize: 12, color: kSubText),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(controller.formatAmount(transaction.amount),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor)),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                child: Text('OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSuccess)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTransactionFooter(List<OwnerTransaction> txns, EquityController controller) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(flex: 3, child: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
          )),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 4, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(controller.formatAmount(txns.fold(0.0, (s, t) => s + t.amount)),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kPrimary)),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  // ==================== WEB PAGINATION BAR ====================

  Widget _buildWebPaginationBar(EquityController controller) {
    return Obx(() => Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${controller.equityAccounts.length} accounts • ${controller.transactions.length} transactions',
            style: TextStyle(fontSize: 13, color: kSubText),
          ),
          Row(
            children: [
              _paginationBtn(Icons.chevron_left, 'Previous', false, null),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Page 1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary)),
              ),
              const SizedBox(width: 12),
              _paginationBtn(Icons.chevron_right, 'Next', false, null),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _paginationBtn(IconData icon, String label, bool enabled, VoidCallback? onTap) {
    final color = enabled ? kPrimary : Colors.grey;
    final isNext = label == 'Next';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? kPrimary : Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (!isNext) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              if (isNext) ...[const SizedBox(width: 4), Icon(icon, size: 18, color: color)],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SHARED HELPERS ====================

  Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 15, color: color)),
    );
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.5),
    );
  }

  void _showMobileSearch(BuildContext context, EquityController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Search Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Account name or code…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => controller.searchController.text = v,
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(onPressed: () { controller.searchController.clear(); Navigator.pop(ctx); }, child: const Text('Clear')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  Color _getTypeColor(String accountType) {
    switch (accountType) {
      case 'Capital': return kPrimary;
      case 'Retained Earnings': return kSuccess;
      case 'Reserves': return kWarning;
      default: return kDanger; // Drawings
    }
  }

  IconData _getTypeIcon(String accountType) {
    switch (accountType) {
      case 'Capital': return Icons.account_balance;
      case 'Retained Earnings': return Icons.trending_up;
      case 'Reserves': return Icons.savings;
      default: return Icons.remove_circle_outline; // Drawings
    }
  }
}
