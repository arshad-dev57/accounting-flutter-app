import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/TrailBalance/controller/trail_balance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TrialBalanceScreen extends StatelessWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrialBalanceController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    TrialBalanceController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
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
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileTrialBalanceList(controller, context)),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    TrialBalanceController controller,
  ) {
    return AppBar(
      title: const Text(
        'Trial Balance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
          onPressed: () => _selectDateRange(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.white),
          onPressed: () => _showExportOptions(controller, context),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final List<String> filterOptions = [
      'All',
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kCardBg,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDateRange(controller, context),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Icon(Icons.date_range, size: 18, color: kPrimary),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Obx(
                                  () => Text(
                                    controller.selectedDateRange.value != null
                                        ? '${DateFormat('dd/MM/yy').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd/MM/yy').format(controller.selectedDateRange.value!.end)}'
                                        : 'Select Date Range',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          controller.selectedDateRange.value !=
                                              null
                                          ? kPrimary
                                          : Colors.black45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedFilter.value,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        items: filterOptions.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) controller.changeFilter(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18, color: kPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Show Zero Balance Accounts',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
                Obx(
                  () => Switch(
                    value: controller.showZeroBalance.value,
                    onChanged: (value) => controller.toggleZeroBalance(value),
                    activeColor: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryCards(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildMobileSummaryCard(
                'Total Debit',
                _formatAmount(controller.totalDebit.value),
                kSuccess,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileSummaryCard(
                'Total Credit',
                _formatAmount(controller.totalCredit.value),
                kDanger,
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileSummaryCard(
                'Difference',
                _formatAmount(controller.difference.value),
                controller.isBalanced.value ? kSuccess : kWarning,
                Icons.balance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTrialBalanceList(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final data = controller.trialBalanceData;
      if (data.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: Colors.black45.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No accounts found',
                style: TextStyle(fontSize: 16, color: Colors.black45),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final account = data[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileAccountCard(account, controller, context),
          );
        },
      );
    });
  }

  Widget _buildMobileAccountCard(
    TrialBalanceAccount account,
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final netBalance = account.debitBalance - account.creditBalance;
    return Card(
      color: kCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAccountDetails(account, controller, context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getAccountTypeColor(
                        account.accountType,
                      ).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getAccountIcon(account.accountType),
                      size: 22,
                      color: _getAccountTypeColor(account.accountType),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getAccountTypeColor(
                                  account.accountType,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                account.accountCode,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getAccountTypeColor(
                                    account.accountType,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                account.accountType,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debit',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.debitBalance > 0
                                ? _formatAmount(account.debitBalance)
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: account.debitBalance > 0
                                  ? kSuccess
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Credit',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.creditBalance > 0
                                ? _formatAmount(account.creditBalance)
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: account.creditBalance > 0
                                  ? kDanger
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Balance',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    Flexible(
                      child: Text(
                        _formatAmount(netBalance.abs()),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: netBalance >= 0 ? kSuccess : kDanger,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // ─────────────────────────────────────────
  // WEB LAYOUT — Professional
  // ─────────────────────────────────────────
  Widget _buildWebLayout(
    BuildContext context,
    TrialBalanceController controller,
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
                  child: LoadingAnimationWidget.discreteCircle(
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
                    child: _buildWebTrialBalanceTable(controller, context),
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
    TrialBalanceController controller,
  ) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Trial Balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Date Range Picker
          Container(
            width: 260,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: () => _selectDateRange(controller, context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 16,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Obx(
                              () => Text(
                                controller.selectedDateRange.value != null
                                    ? '${DateFormat('dd MMM yyyy').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(controller.selectedDateRange.value!.end)}'
                                    : 'Select Date Range',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Export button
          _webHeaderBtn(
            Icons.download_outlined,
            'Export',
            () => _showExportOptions(controller, context),
          ),
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
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiStrip(TrialBalanceController controller) {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: [
                    _buildWebKpiTile(
                      'Total Debit',
                      _formatAmount(controller.totalDebit.value),
                      kSuccess,
                      Icons.trending_up,
                    ),
                    _buildWebKpiDivider(),
                    _buildWebKpiTile(
                      'Total Credit',
                      _formatAmount(controller.totalCredit.value),
                      kDanger,
                      Icons.trending_down,
                    ),
                    _buildWebKpiDivider(),
                    _buildWebKpiTile(
                      'Difference',
                      _formatAmount(controller.difference.value),
                      controller.isBalanced.value ? kSuccess : kWarning,
                      Icons.balance,
                    ),
                    _buildWebKpiDivider(),
                    _buildWebKpiTile(
                      'Status',
                      controller.isBalanced.value ? 'Balanced' : 'Unbalanced',
                      controller.isBalanced.value ? kSuccess : kWarning,
                      controller.isBalanced.value
                          ? Icons.check_circle
                          : Icons.warning,
                    ),
                  ],
                ),
              ),
            );
          }
          return Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildWebKpiTile(
                    'Total Debit',
                    _formatAmount(controller.totalDebit.value),
                    kSuccess,
                    Icons.trending_up,
                  ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: _buildWebKpiTile(
                    'Total Credit',
                    _formatAmount(controller.totalCredit.value),
                    kDanger,
                    Icons.trending_down,
                  ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: _buildWebKpiTile(
                    'Difference',
                    _formatAmount(controller.difference.value),
                    controller.isBalanced.value ? kSuccess : kWarning,
                    Icons.balance,
                  ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: _buildWebKpiTile(
                    'Status',
                    controller.isBalanced.value ? 'Balanced' : 'Unbalanced',
                    controller.isBalanced.value ? kSuccess : kWarning,
                    controller.isBalanced.value
                        ? Icons.check_circle
                        : Icons.warning,
                  ),
                ),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    const filterOptions = [
      'All',
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

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
          // Filter tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: filterOptions.map((filter) {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: InkWell(
                        onTap: () => controller.changeFilter(filter),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: kPrimary.withOpacity(0.3))
                                : null,
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? kPrimary : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Zero Balance Toggle
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 13,
                  color: Colors.black45,
                ),
                const SizedBox(width: 6),
                Text(
                  'Zero Balances',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(width: 6),
                Obx(
                  () => Switch(
                    value: controller.showZeroBalance.value,
                    onChanged: (value) => controller.toggleZeroBalance(value),
                    activeColor: kPrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTrialBalanceTable(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final data = controller.trialBalanceData;

      if (data.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 48,
                color: Colors.black45.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No accounts found',
                style: TextStyle(fontSize: 15, color: Colors.black45),
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
                Expanded(flex: 4, child: _tableHeaderCell('Account')),
                Expanded(flex: 2, child: _tableHeaderCell('Type')),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Debit', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Credit', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell(
                    'Net Balance',
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final account = data[index];
                return _buildWebTableRow(account, controller, context);
              },
            ),
          ),
          _buildWebTableFooter(data),
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
        fontWeight: FontWeight.w600,
        color: Colors.black45,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWebTableRow(
    TrialBalanceAccount account,
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final netBalance = account.debitBalance - account.creditBalance;
    final accountType = account.accountType;
    final accountColor = _getAccountTypeColor(accountType);
    final accountIcon = _getAccountIcon(accountType);

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(accountIcon, size: 20, color: accountColor),
              ),
              const SizedBox(width: 12),
              // Account Name + Code
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      account.accountName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      account.accountCode,
                      style: TextStyle(fontSize: 10, color: accountColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Type badge
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accountColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.accountType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: accountColor,
                    ),
                  ),
                ),
              ),
              // Debit
              Expanded(
                flex: 2,
                child: Text(
                  account.debitBalance > 0
                      ? _formatAmount(account.debitBalance)
                      : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: account.debitBalance > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: account.debitBalance > 0 ? kSuccess : Colors.black45,
                  ),
                ),
              ),
              // Credit
              Expanded(
                flex: 2,
                child: Text(
                  account.creditBalance > 0
                      ? _formatAmount(account.creditBalance)
                      : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: account.creditBalance > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: account.creditBalance > 0 ? kDanger : Colors.black45,
                  ),
                ),
              ),
              // Net Balance
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: netBalance >= 0
                        ? kSuccess.withOpacity(0.08)
                        : kDanger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatAmount(netBalance.abs()),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: netBalance >= 0 ? kSuccess : kDanger,
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

  Widget _buildWebTableFooter(List<TrialBalanceAccount> data) {
    final totalDebit = data.fold(0.0, (s, a) => s + a.debitBalance);
    final totalCredit = data.fold(0.0, (s, a) => s + a.creditBalance);
    final diff = totalDebit - totalCredit;
    final balanced = diff.abs() < 0.01;

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
          const Expanded(
            flex: 4,
            child: Text(
              'TOTAL',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalDebit),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: kSuccess,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalCredit),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: kDanger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: balanced
                    ? kSuccess.withOpacity(0.1)
                    : kWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    balanced ? Icons.check_circle : Icons.warning_rounded,
                    size: 14,
                    color: balanced ? kSuccess : kWarning,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      balanced ? 'Balanced' : _formatAmount(diff.abs()),
                      style: TextStyle(
                        color: balanced ? kSuccess : kWarning,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SHARED DIALOGS & HELPERS
  // ─────────────────────────────────────────
  void _selectDateRange(
    TrialBalanceController controller,
    BuildContext context,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );
    if (picked != null) controller.setDateRange(picked);
  }

  void _showExportOptions(
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 20),
        ),
        child: Container(
          width: isWeb ? 380 : double.infinity,
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Export Trial Balance',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _exportOptionTile(
                icon: Icons.picture_as_pdf,
                label: 'Export as PDF',
                color: const Color(0xFFE53935),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.exportTrialBalance();
                },
                isWeb: isWeb,
              ),
              _exportOptionTile(
                icon: Icons.table_chart,
                label: 'Export as Excel',
                color: const Color(0xFF2E7D32),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.exportTrialBalance();
                },
                isWeb: isWeb,
              ),
              _exportOptionTile(
                icon: Icons.print,
                label: 'Print',
                color: kPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  controller.printTrialBalance();
                },
                isWeb: isWeb,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isWeb,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: isWeb ? 14 : 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black45),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showAccountDetails(
    TrialBalanceAccount account,
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final netBalance = account.debitBalance - account.creditBalance;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 20),
        ),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getAccountTypeColor(
                        account.accountType,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAccountIcon(account.accountType),
                      size: 26,
                      color: _getAccountTypeColor(account.accountType),
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
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${account.accountCode} • ${account.accountType}',
                          style: TextStyle(
                            fontSize: isWeb ? 12 : 13,
                            color: Colors.black45,
                          ),
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
                padding: EdgeInsets.all(isWeb ? 16 : 14),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Debit Balance',
                      _formatAmount(account.debitBalance),
                      kSuccess,
                      isWeb,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Credit Balance',
                      _formatAmount(account.creditBalance),
                      kDanger,
                      isWeb,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Net Balance',
                      _formatAmount(netBalance.abs()),
                      netBalance >= 0 ? kSuccess : kDanger,
                      isWeb,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isWeb ? 13 : 14,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isWeb ? 15 : 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case 'Assets':
        return kSuccess;
      case 'Liabilities':
        return kDanger;
      case 'Equity':
        return const Color(0xFF9B59B6);
      case 'Income':
        return kPrimary;
      case 'Expenses':
        return kWarning;
      default:
        return Colors.black45;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'Assets':
        return Icons.account_balance;
      case 'Liabilities':
        return Icons.payment;
      case 'Equity':
        return Icons.account_balance_wallet;
      case 'Income':
        return Icons.trending_up;
      case 'Expenses':
        return Icons.trending_down;
      default:
        return Icons.account_balance;
    }
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
