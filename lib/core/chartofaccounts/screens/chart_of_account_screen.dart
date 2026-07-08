// screens/chart_of_accounts_screen.dart - MOBILE & TABLET ONLY

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/chartofaccounts/controller/chart_of_account_controller.dart';
import 'package:LedgerPro_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChartOfAccountsScreen extends StatelessWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChartOfAccountController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.accounts.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildSummaryCards(controller, context),
            _buildAccountTypeFilter(controller, context),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!controller.isLoadingMore.value &&
                      scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    controller.loadMoreData();
                  }
                  return false;
                },
                child: _buildAccountsList(controller, context),
              ),
            ),
            Obx(() => controller.isLoadingMore.value
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 30),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, controller),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ChartOfAccountController controller) {
    return AppBar(
      title: const Text(
        'Chart of Accounts',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => _showSearchDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilterDialog(context, controller),
        ),
        Obx(() => controller.hasIncorrectCashAccounts.value
            ? IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                onPressed: () => _showFixCashAccountsDialog(context, controller),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  // ─── Summary Cards ──────────────────────────────────────────────
  Widget _buildSummaryCards(ChartOfAccountController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildSummaryCard('Assets', controller.totalAssets.value, const Color(0xFF2ECC71), Icons.account_balance, context),
            const SizedBox(width: 10),
            _buildSummaryCard('Liabilities', controller.totalLiabilities.value, const Color(0xFFE74C3C), Icons.payment, context),
            const SizedBox(width: 10),
            _buildSummaryCard('Equity', controller.totalEquity.value, const Color(0xFF3498DB), Icons.account_balance_wallet, context),
            const SizedBox(width: 10),
            _buildSummaryCard('Income', controller.totalIncome.value, const Color(0xFF2ECC71), Icons.trending_up, context),
            const SizedBox(width: 10),
            _buildSummaryCard('Expenses', controller.totalExpenses.value, const Color(0xFFE74C3C), Icons.trending_down, context),
          ],
        )),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, BuildContext context) {
    return Container(
      width: 130,
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          Text(_formatAmount(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ─── Account Type Filter ────────────────────────────────────────
  Widget _buildAccountTypeFilter(ChartOfAccountController controller, BuildContext context) {
    const accountTypes = ['All', 'Assets', 'Liabilities', 'Equity', 'Income', 'Expenses'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: accountTypes.map((type) {
            final isSelected = controller.selectedFilter.value == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (_) => controller.changeFilter(type),
                backgroundColor: kBg,
                selectedColor: kPrimary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? kPrimary : kSubText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  // ─── Accounts List ──────────────────────────────────────────────
  Widget _buildAccountsList(ChartOfAccountController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.accounts;
      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No accounts found', style: TextStyle(fontSize: 16, color: kSubText)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showAddAccountDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Add Account', style: TextStyle(fontSize: 13, color: Colors.white)),
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
    });
  }

  // ─── Account Card ──────────────────────────────────────────────
  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> account, ChartOfAccountController controller) {
    final isDebit = account['balanceType'] == 'Debit';
    final isIncorrect = controller.isIncorrectCashAccount(account);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountDetails(context, account, controller),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (account['typeColor'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(account['typeIcon'] as IconData, color: account['typeColor'] as Color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(account['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          if (isIncorrect) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${account['code']} • ${account['type']}', style: TextStyle(fontSize: 12, color: kSubText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatAmount(account['balance']),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                            color: isDebit ? kSuccess : kDanger)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDebit ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(account['balanceType'],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: isDebit ? kSuccess : kDanger)),
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
  void _showFixCashAccountsDialog(BuildContext context, ChartOfAccountController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('Fix Cash Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Fix All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Account Details ──────────────────────────────────────────────
  void _showAccountDetails(BuildContext context, Map<String, dynamic> account, ChartOfAccountController controller) {
    final isDebit = account['balanceType'] == 'Debit';
    final isIncorrect = controller.isIncorrectCashAccount(account);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: (account['typeColor'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(account['typeIcon'] as IconData, color: account['typeColor'] as Color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(account['name'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
                          if (isIncorrect) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          ],
                        ],
                      ),
                      Text('${account['code']} • ${account['type']}',
                          style: TextStyle(fontSize: 13, color: kSubText)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDebit ? kSuccess.withOpacity(0.1) : kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _formatAmount(account['balance']),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDebit ? kSuccess : kDanger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            const SizedBox(height: 14),
            _buildDetailRow('Balance Type', account['balanceType'], context),
            _buildDetailRow('Parent Account', account['parentAccount'] ?? 'N/A', context),
            _buildDetailRow('Tax Code', account['taxCode'] ?? 'N/A', context),
            _buildDetailRow('Description', account['description'] ?? 'No description', context),
            _buildDetailRow('Status', account['isActive'] ? 'Active' : 'Inactive', context),
            if (isIncorrect) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ This is a cash/bank account but type is "${account['type']}". It should be "Assets".',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
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
                    controller.fixAccountType(account['id'], 'Assets');
                  },
                  icon: const Icon(Icons.account_balance, size: 16),
                  label: const Text('Fix Account Type'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { Navigator.pop(context); _showEditAccountDialog(context, account, controller); },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); Get.to(() => const JournalEntriesScreen()); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('View Ledger'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Account Dialog ──────────────────────────────────────────
  void _showAddAccountDialog(BuildContext context, ChartOfAccountController controller) {
    final formKey = GlobalKey<FormState>();
    String accountCode = '';
    String accountName = '';
    String accountType = 'Assets';
    String parentAccount = '';
    String description = '';
    String taxCode = 'N/A';
    double openingBalance = 0.0;
    String? typeError;

    // Define parent account mapping
    final Map<String, List<String>> parentAccountMapping = {
      'Assets': ['Current Assets', 'Fixed Assets'],
      'Liabilities': ['Current Liabilities', 'Long Term Liabilities'],
      'Equity': ['Capital / Equity'],
      'Income': ['Operating Income'],
      'Expenses': ['Operating Expenses'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get parent accounts for selected type
          final parentAccounts = parentAccountMapping[accountType] ?? [];
          // Reset parent account if current selection is not in the list
          if (parentAccount.isNotEmpty && !parentAccounts.contains(parentAccount)) {
            parentAccount = '';
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Add New Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: 16, color: Colors.grey.withOpacity(0.2)),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _formField('Account Code *', 'e.g., 1010', (v) => accountCode = v,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _formField('Account Name *', 'e.g., Cash in Hand', (v) {
                              accountName = v;
                              final nameLower = v.toLowerCase();
                              final isCashOrBank = nameLower.contains('cash') || 
                                                  nameLower.contains('bank') || 
                                                  nameLower.contains('money');
                              if (isCashOrBank && accountType != 'Assets') {
                                setState(() {
                                  typeError = 'Cash/Bank accounts must be of type "Assets"';
                                });
                              } else {
                                setState(() {
                                  typeError = null;
                                });
                              }
                            }, validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Account Type *',
                              value: accountType,
                              items: const ['Assets', 'Liabilities', 'Equity', 'Income', 'Expenses'],
                              onChanged: (v) {
                                setState(() {
                                  accountType = v!;
                                  // Reset parent account when type changes
                                  parentAccount = '';
                                  final nameLower = accountName.toLowerCase();
                                  final isCashOrBank = nameLower.contains('cash') || 
                                                      nameLower.contains('bank') || 
                                                      nameLower.contains('money');
                                  if (isCashOrBank && accountType != 'Assets') {
                                    typeError = 'Cash/Bank accounts must be of type "Assets"';
                                  } else {
                                    typeError = null;
                                  }
                                });
                              },
                            ),
                            if (typeError != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        typeError!,
                                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Parent Account',
                              value: parentAccount.isEmpty ? null : parentAccount,
                              items: parentAccounts,
                              onChanged: (v) => setState(() => parentAccount = v!),
                            ),
                            const SizedBox(height: 12),
                            _formField('Opening Balance', '0.00', (v) => openingBalance = double.tryParse(v) ?? 0.0,
                                keyboardType: TextInputType.number, prefixText: CurrencyUtils.prefix),
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Tax Code',
                              value: taxCode,
                              items: const ['N/A', 'GST-13%', 'GST-5%', 'WHT-10%'],
                              onChanged: (v) => setState(() => taxCode = v!),
                              displayLabels: const ['N/A - No Tax', 'GST 13% (Standard)', 'GST 5% (Reduced)', 'WHT 10%'],
                            ),
                            const SizedBox(height: 12),
                            _formField('Description', 'Account description', (v) => description = v, maxLines: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: 14, color: kSubText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (typeError != null) {
                              AppSnackbar.error(Colors.red, 'Error', typeError!);
                              return;
                            }
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              await controller.createAccount({
                                'code': accountCode,
                                'name': accountName,
                                'type': accountType,
                                'parentAccount': parentAccount,
                                'openingBalance': openingBalance,
                                'description': description,
                                'taxCode': taxCode,
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: Text('Save Account', style: TextStyle(fontSize: 14, color: Colors.white)),
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

  // ─── Edit Account Dialog ──────────────────────────────────────────
  void _showEditAccountDialog(BuildContext context, Map<String, dynamic> account, ChartOfAccountController controller) {
    final formKey = GlobalKey<FormState>();
    String accountCode = account['code'];
    String accountName = account['name'];
    String accountType = account['type'];
    String parentAccount = account['parentAccount'] ?? '';
    String description = account['description'] ?? '';
    String taxCode = account['taxCode'] ?? 'N/A';
    double openingBalance = account['balance'];
    String? typeError;

    // Define parent account mapping
    final Map<String, List<String>> parentAccountMapping = {
      'Assets': ['Current Assets', 'Fixed Assets'],
      'Liabilities': ['Current Liabilities', 'Long Term Liabilities'],
      'Equity': ['Capital / Equity'],
      'Income': ['Operating Income'],
      'Expenses': ['Operating Expenses'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get parent accounts for selected type
          final parentAccounts = parentAccountMapping[accountType] ?? [];
          // Reset parent account if current selection is not in the list
          if (parentAccount.isNotEmpty && !parentAccounts.contains(parentAccount)) {
            parentAccount = '';
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Edit Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: 16, color: Colors.grey.withOpacity(0.2)),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _formField('Account Code *', 'e.g., 1010', (v) => accountCode = v,
                                initialValue: accountCode,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _formField('Account Name *', 'e.g., Cash in Hand', (v) {
                              accountName = v;
                              final nameLower = v.toLowerCase();
                              final isCashOrBank = nameLower.contains('cash') || 
                                                  nameLower.contains('bank') || 
                                                  nameLower.contains('money');
                              if (isCashOrBank && accountType != 'Assets') {
                                setState(() {
                                  typeError = 'Cash/Bank accounts must be of type "Assets"';
                                });
                              } else {
                                setState(() {
                                  typeError = null;
                                });
                              }
                            }, initialValue: accountName,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Account Type *',
                              value: accountType,
                              items: const ['Assets', 'Liabilities', 'Equity', 'Income', 'Expenses'],
                              onChanged: (v) {
                                setState(() {
                                  accountType = v!;
                                  // Reset parent account when type changes
                                  parentAccount = '';
                                  final nameLower = accountName.toLowerCase();
                                  final isCashOrBank = nameLower.contains('cash') || 
                                                      nameLower.contains('bank') || 
                                                      nameLower.contains('money');
                                  if (isCashOrBank && accountType != 'Assets') {
                                    typeError = 'Cash/Bank accounts must be of type "Assets"';
                                  } else {
                                    typeError = null;
                                  }
                                });
                              },
                            ),
                            if (typeError != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        typeError!,
                                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Parent Account',
                              value: parentAccount.isEmpty ? null : parentAccount,
                              items: parentAccounts,
                              onChanged: (v) => setState(() => parentAccount = v!),
                            ),
                            const SizedBox(height: 12),
                            _formField('Opening Balance', '0.00', (v) => openingBalance = double.tryParse(v) ?? 0.0,
                                initialValue: openingBalance.toString(), keyboardType: TextInputType.number, prefixText: CurrencyUtils.prefix),
                            const SizedBox(height: 12),
                            _dropdownField<String>(
                              label: 'Tax Code',
                              value: taxCode,
                              items: const ['N/A', 'GST-13%', 'GST-5%', 'WHT-10%'],
                              onChanged: (v) => setState(() => taxCode = v!),
                              displayLabels: const ['N/A - No Tax', 'GST 13% (Standard)', 'GST 5% (Reduced)', 'WHT 10%'],
                            ),
                            const SizedBox(height: 12),
                            _formField('Description', 'Account description', (v) => description = v,
                                initialValue: description, maxLines: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: 14, color: kSubText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (typeError != null) {
                              AppSnackbar.error(Colors.red, 'Error', typeError!);
                              return;
                            }
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              await controller.updateAccount(account['id'], {
                                'code': accountCode,
                                'name': accountName,
                                'type': accountType,
                                'parentAccount': parentAccount,
                                'openingBalance': openingBalance,
                                'description': description,
                                'taxCode': taxCode,
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: Text('Update Account', style: TextStyle(fontSize: 14, color: Colors.white)),
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

  // ─── Search Dialog ──────────────────────────────────────────────
  void _showSearchDialog(BuildContext context, ChartOfAccountController controller) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Search Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter account name or code',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onSubmitted: (value) { controller.searchAccounts(value); Navigator.pop(context); },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () { controller.searchAccounts(searchController.text); Navigator.pop(context); },
            child: const Text('Search', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ─── Filter Dialog ──────────────────────────────────────────────
  void _showFilterDialog(BuildContext context, ChartOfAccountController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Filter Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
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
            child: Text(label, style: TextStyle(fontSize: 13, color: kSubText, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Form Field ──────────────────────────────────────────────────
  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String? initialValue,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
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
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  // ─── Dropdown Field ──────────────────────────────────────────────
  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    List<String>? displayLabels,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: items.asMap().entries.map((e) => DropdownMenuItem<T>(
        value: e.value,
        child: Text(displayLabels != null ? displayLabels[e.key] : '${e.value}'),
      )).toList(),
      onChanged: onChanged,
    );
  }

  // ─── Format Amount ──────────────────────────────────────────────
  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}