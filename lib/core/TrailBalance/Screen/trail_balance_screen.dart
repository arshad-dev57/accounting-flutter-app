import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/widgets/expandable_stat_card.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/TrailBalance/controller/trail_balance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TrialBalanceScreen extends StatelessWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ FiscalYearController must be initialized FIRST because
    // TrialBalanceController's field initializer calls Get.find<FiscalYearController>()
    final fiscalYearController = Get.isRegistered<FiscalYearController>()
        ? Get.find<FiscalYearController>()
        : Get.put(FiscalYearController());
    final controller = Get.put(TrialBalanceController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller, fiscalYearController),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.trialBalanceData.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildSummaryCards(controller),
                    const SizedBox(height: 8),
                    Expanded(child: _buildListView(controller, context)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(
    BuildContext context,
    TrialBalanceController controller,
    FiscalYearController fiscalYearController,
  ) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trial Balance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalAccounts.value} accounts',
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
                  _headerIconBtn(
                    Icons.refresh_rounded,
                    controller.fetchTrialBalance,
                  ),
                  const SizedBox(width: 6),
                  _headerIconBtn(
                    Icons.download_outlined,
                    () => _showExportOptions(controller, context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _whiteField(
                          height: 36,
                          child: Obx(
                            () => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      size: 14,
                                      color: kPrimary,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Fiscal Year',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                value: fiscalYearController
                                    .selectedFiscalYear
                                    .value
                                    ?.id,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                isExpanded: true,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                items: fiscalYearController.fiscalYears.map((
                                  year,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: year.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          year.isOpen
                                              ? Icons.lock_open
                                              : Icons.lock,
                                          size: 13,
                                          color: year.isOpen
                                              ? kSuccess
                                              : kDanger,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            year.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  final selectedYear = fiscalYearController
                                      .fiscalYears
                                      .firstWhere((y) => y.id == value);
                                  fiscalYearController.selectFiscalYear(
                                    selectedYear,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _selectDateRange(controller, context),
                          child: _whiteField(
                            height: 36,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 14,
                                    color: kPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Obx(
                                      () => Text(
                                        controller.selectedDateRange.value !=
                                                null
                                            ? '${DateFormat('dd/MM').format(controller.selectedDateRange.value!.start)}-${DateFormat('dd/MM').format(controller.selectedDateRange.value!.end)}'
                                            : 'Date',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              controller
                                                      .selectedDateRange
                                                      .value !=
                                                  null
                                              ? Colors.black87
                                              : Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _whiteField(
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Zero',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Obx(
                                () => Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: controller.showZeroBalance.value,
                                    onChanged: controller.toggleZeroBalance,
                                    activeColor: kPrimary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _whiteField(
                    height: 36,
                    child: TextField(
                      onChanged: controller.searchAccounts,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search accounts...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: kPrimary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
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
                                alignment: Alignment.center,
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
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _whiteField({required double height, required Widget child}) {
    return Container(
      height: height,
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
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY KPIs — compact horizontal strip
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(TrialBalanceController controller) {
    return Obx(() {
      final isBalanced = controller.isBalanced.value;
      final diff = controller.difference.value;
      final balanceColor = isBalanced ? kSuccess : kWarning;

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _summaryChip(
                'Debit',
                _formatAmount(controller.totalDebit.value),
                kSuccess,
                Icons.arrow_circle_up_rounded,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                'Credit',
                _formatAmount(controller.totalCredit.value),
                kDanger,
                Icons.arrow_circle_down_rounded,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                isBalanced ? 'Balanced' : 'Difference',
                isBalanced ? 'OK' : _formatAmount(diff.abs()),
                balanceColor,
                isBalanced
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                width: 140,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _summaryChip(
    String label,
    String amount,
    Color accentColor,
    IconData icon, {
    double width = 132,
  }) {
    return ExpandableStatWrap(
      title: label,
      value: amount,
      color: accentColor,
      icon: icon,
      child: Container(
        width: width,
        height: 52,
        padding: const EdgeInsets.fromLTRB(10, 6, 22, 6),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: accentColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        height: 1.1,
                      ),
                      maxLines: 1,
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

  // ═══════════════════════════════════════════════════════════════
  // LIST VIEW WITH LAZY LOADING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildListView(
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
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No accounts found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final account = data[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAccountCard(account, controller, context),
          );
        },
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL ACCOUNT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAccountCard(
    TrialBalanceAccount account,
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final netBalance = account.debitBalance - account.creditBalance;
    final accountColor = _getAccountTypeColor(account.accountType);
    final accountIcon = _getAccountIcon(account.accountType);
    final isZeroBalance =
        account.debitBalance == 0 && account.creditBalance == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isZeroBalance
              ? Colors.grey.withOpacity(0.15)
              : accountColor.withOpacity(0.2),
          width: isZeroBalance ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (!isZeroBalance)
            BoxShadow(
              color: accountColor.withOpacity(0.06),
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
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accountColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(accountIcon, size: 20, color: accountColor),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _badge(account.accountCode, accountColor),
                              _badge(account.accountType, Colors.grey.shade500),
                              if (isZeroBalance)
                                _badge('Zero', Colors.grey.shade400),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Net balance pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: netBalance >= 0
                            ? kSuccess.withOpacity(0.1)
                            : kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: netBalance >= 0
                              ? kSuccess.withOpacity(0.2)
                              : kDanger.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            netBalance >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 10,
                            color: netBalance >= 0 ? kSuccess : kDanger,
                          ),
                          const SizedBox(height: 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              _formatAmount(netBalance.abs()),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: netBalance >= 0 ? kSuccess : kDanger,
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
                const SizedBox(height: 12),
                // Debit / Credit row
                Row(
                  children: [
                    Expanded(
                      child: _amountBox(
                        label: 'DEBIT',
                        value: account.debitBalance > 0
                            ? _formatAmount(account.debitBalance)
                            : '—',
                        color: kSuccess,
                        hasValue: account.debitBalance > 0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _amountBox(
                        label: 'CREDIT',
                        value: account.creditBalance > 0
                            ? _formatAmount(account.creditBalance)
                            : '—',
                        color: kDanger,
                        hasValue: account.creditBalance > 0,
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
    required bool hasValue,
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
              color: hasValue ? color : Colors.grey.shade400,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS & HELPERS
  // ═══════════════════════════════════════════════════════════════

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: kCardBg,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Export Trial Balance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.black),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.totalAccounts.value} accounts will be exported',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _exportOptionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    subtitle: 'Formatted report',
                    color: const Color(0xFFE53935),
                    bgColor: const Color(0xFFFFEBEE),
                    onTap: () {
                      Navigator.pop(ctx);
                      controller.exportToPdf();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _exportOptionCard(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    subtitle: 'Spreadsheet',
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () {
                      Navigator.pop(ctx);
                      controller.exportToExcel();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _exportOptionCard(
              icon: Icons.print_outlined,
              label: 'Print',
              subtitle: 'Physical copy',
              color: kPrimary,
              bgColor: kPrimary.withOpacity(0.08),
              onTap: () {
                Navigator.pop(ctx);
                controller.printTrialBalance();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOptionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDetails(
    TrialBalanceAccount account,
    TrialBalanceController controller,
    BuildContext context,
  ) {
    final netBalance = account.debitBalance - account.creditBalance;
    final accountColor = _getAccountTypeColor(account.accountType);
    final accountIcon = _getAccountIcon(account.accountType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.55,
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
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accountColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              accountIcon,
                              size: 26,
                              color: accountColor,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accountColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        account.accountCode,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: accountColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${account.accountType}',
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
                      Row(
                        children: [
                          _miniKpi(
                            'Debit',
                            _formatAmount(account.debitBalance),
                            kSuccess,
                            Icons.trending_up,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Credit',
                            _formatAmount(account.creditBalance),
                            kDanger,
                            Icons.trending_down,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Net',
                            _formatAmount(netBalance.abs()),
                            netBalance >= 0 ? kSuccess : kDanger,
                            Icons.balance,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      _detailRow('Account Type', account.accountType),
                      _detailRow('Account Code', account.accountCode),
                      _detailRow(
                        'Balance Type',
                        netBalance >= 0 ? 'Debit Balance' : 'Credit Balance',
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimary,
                                  side: const BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
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
                                  // TODO: Navigate to account details
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'View Details',
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
                      const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kText,
            ),
          ),
        ],
      ),
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
        return Colors.grey.shade600;
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
