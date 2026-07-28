// screens/profit_loss_statement_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:LedgerPro_app/core/profitlossStatement/controllers/profit_and_loss_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ProfitLossStatementScreen extends StatelessWidget {
  const ProfitLossStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PLController());
    final fiscalYearController = Get.put(FiscalYearController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller, fiscalYearController),
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
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Column(
                  children: [
                    _buildFiscalYearSelector(fiscalYearController, controller),
                    _buildPeriodBar(controller, context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildReportBody(controller, context),
                    ),
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
    PLController controller,
    FiscalYearController fiscalYearController,
  ) {
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
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profit & Loss',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Statement',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.loadReportData(),
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
                    onTap: () => controller.exportToPdf(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 18,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.exportToExcelFile(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        size: 18,
                        color: Colors.black.withOpacity(0.65),
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

  // ═══════════════════════════════════════════════════════════════
  // FISCAL YEAR SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFiscalYearSelector(
    FiscalYearController fiscalYearController,
    PLController controller,
  ) {
    return Obx(
      () => Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: kCardBg,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Row(
              children: [
                Icon(Icons.account_balance, size: 18, color: kPrimary),
                const SizedBox(width: 8),
                const Text('Select Fiscal Year'),
              ],
            ),
            value: fiscalYearController.selectedFiscalYear.value?.id,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            padding: EdgeInsets.zero,
            isExpanded: true,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            items: fiscalYearController.fiscalYears.map((year) {
              return DropdownMenuItem(
                value: year.id,
                child: Row(
                  children: [
                    Icon(
                      year.isOpen ? Icons.lock_open : Icons.lock,
                      size: 16,
                      color: year.isOpen ? kSuccess : kDanger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        year.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final selectedYear = fiscalYearController.fiscalYears
                    .firstWhere((y) => y.id == value);
                fiscalYearController.selectFiscalYear(selectedYear);
                controller.loadReportData();
              }
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PERIOD BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPeriodBar(PLController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: Row(
        children: [
          Expanded(
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.periodOptions
                    .where((p) => p != 'Custom Range')
                    .map((p) {
                  final isSelected = controller.selectedPeriod.value == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => controller.changePeriod(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _selectDateRange(controller, context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Range',
                    style: TextStyle(
                      fontSize: 11,
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════════════════════════════
  // REPORT BODY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReportBody(PLController controller, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      physics: const BouncingScrollPhysics(),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodTitleCard(controller),
          const SizedBox(height: 12),

          // Revenue Section
          _buildSection(
            title: 'Revenue',
            icon: Icons.trending_up,
            color: kSuccess,
            items: controller.revenueItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
            total: controller.totalRevenue.value,
            totalLabel: 'Total Revenue',
          ),
          const SizedBox(height: 12),

          // COGS
          if (controller.costOfGoodsSold.value > 0) ...[
            _buildSection(
              title: 'Cost of Goods Sold',
              icon: Icons.inventory_2_outlined,
              color: kWarning,
              items: [_SectionItem('COGS', controller.costOfGoodsSold.value)],
              total: controller.costOfGoodsSold.value,
              totalLabel: 'Total COGS',
            ),
            const SizedBox(height: 12),
          ],

          // Gross Profit
          _buildGrossProfitCard(controller),
          const SizedBox(height: 12),

          // Operating Expenses
          _buildSection(
            title: 'Operating Expenses',
            icon: Icons.receipt_long,
            color: kDanger,
            items: controller.expenseItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
            total: controller.operatingExpenses.value,
            totalLabel: 'Total Operating Expenses',
          ),
          const SizedBox(height: 12),

          // Other Income
          if (controller.otherIncomeItems.isNotEmpty) ...[
            _buildSection(
              title: 'Other Income',
              icon: Icons.add_circle_outline,
              color: kSuccess,
              items: controller.otherIncomeItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
              total: controller.otherIncomeItems.fold(0.0, (s, i) => s + i.amount),
              totalLabel: 'Total Other Income',
            ),
            const SizedBox(height: 12),
          ],

          // Other Expenses
          if (controller.otherExpenseItems.isNotEmpty) ...[
            _buildSection(
              title: 'Other Expenses',
              icon: Icons.remove_circle_outline,
              color: kDanger,
              items: controller.otherExpenseItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
              total: controller.otherExpenseItems.fold(0.0, (s, i) => s + i.amount),
              totalLabel: 'Total Other Expenses',
            ),
            const SizedBox(height: 12),
          ],

          // Net Profit / Loss
          _buildNetProfitCard(controller),
          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(controller),
          const SizedBox(height: 20),
        ],
      )),
    );
  }

  // ─── Period Title Card ──────────────────────────────────────────

  Widget _buildPeriodTitleCard(PLController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, size: 16, color: kPrimary),
              const SizedBox(width: 8),
              Text(
                'Profit & Loss Statement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.periodText.value,
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Builder ─────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_SectionItem> items,
    required double total,
    required String totalLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                ...items.map((item) => _buildReportRow(item.name, item.amount)),
                Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                _buildReportRow(totalLabel, total, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Gross Profit Card ──────────────────────────────────────────

  Widget _buildGrossProfitCard(PLController controller) {
    final isProfit = controller.grossProfit.value >= 0;
    final color = isProfit ? kSuccess : kDanger;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 15,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Gross Profit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildReportRow('Total Revenue', controller.totalRevenue.value),
                if (controller.costOfGoodsSold.value > 0)
                  _buildReportRow(
                    'Less: COGS',
                    controller.costOfGoodsSold.value,
                    isNegative: true,
                  ),
                Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                _buildReportRow(
                  'Gross Profit',
                  controller.grossProfit.value,
                  isBold: true,
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Net Profit Card ─────────────────────────────────────────────

  Widget _buildNetProfitCard(PLController controller) {
    final isProfit = controller.netProfit.value >= 0;
    final color = isProfit ? kSuccess : kDanger;
    final label = isProfit ? 'Net Profit' : 'Net Loss';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                controller.formatAmount(controller.netProfit.value.abs()),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    'Profit Margin: ${controller.netProfitMargin.value.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Report Row ──────────────────────────────────────────────────

  Widget _buildReportRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? (isNegative ? kDanger : kText),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isNegative ? '(${_formatAmount(amount)})' : _formatAmount(amount),
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isNegative ? kDanger : kText),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────

  Widget _buildActionButtons(PLController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.exportToExcelFile(),
            icon: Icon(Icons.table_chart, size: 16, color: kPrimary),
            label: Text(
              'Excel',
              style: TextStyle(fontSize: 12, color: kPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.exportToPdf(),
            icon: Icon(Icons.picture_as_pdf, size: 16, color: kDanger),
            label: Text(
              'PDF',
              style: TextStyle(fontSize: 12, color: kDanger),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kDanger),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
     
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  void _selectDateRange(PLController controller, BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );
    if (picked != null) controller.setDateRange(picked);
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}

// ─── Helper Model ──────────────────────────────────────────────────

class _SectionItem {
  final String name;
  final double amount;
  _SectionItem(this.name, this.amount);
}