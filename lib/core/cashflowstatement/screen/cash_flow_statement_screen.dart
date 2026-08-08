// screens/cash_flow_statement_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/controller/cashflow_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CashFlowStatementScreen extends StatelessWidget {
  const CashFlowStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fiscalYearController = Get.isRegistered<FiscalYearController>()
        ? Get.find<FiscalYearController>()
        : Get.put(FiscalYearController());
    final controller = Get.put(CashFlowController());

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
              if (controller.hasError.value) {
                return _buildErrorState(controller);
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFiscalYearSelector(
                        fiscalYearController,
                        controller,
                      ),
                      const SizedBox(height: 10),
                      _buildPeriodSelector(controller, context),
                      const SizedBox(height: 10),
                      _buildSummaryCards(controller),
                      const SizedBox(height: 14),
                      // Operating Activities
                      _buildActivitiesSection(
                        title: 'Operating Activities',
                        icon: Icons.business_center,
                        color: kPrimary,
                        items: controller.operatingItems,
                        netValue: controller.cashFlowFromOperations.value,
                        netLabel: 'Net Cash from Operating',
                        controller: controller,
                      ),
                      const SizedBox(height: 12),
                      // Investing Activities
                      _buildActivitiesSection(
                        title: 'Investing Activities',
                        icon: Icons.trending_down,
                        color: kWarning,
                        items: controller.investingItems,
                        netValue: controller.cashFlowFromInvesting.value,
                        netLabel: 'Net Cash from Investing',
                        controller: controller,
                      ),
                      const SizedBox(height: 12),
                      // Financing Activities
                      _buildActivitiesSection(
                        title: 'Financing Activities',
                        icon: Icons.account_balance,
                        color: kSuccess,
                        items: controller.financingItems,
                        netValue: controller.cashFlowFromFinancing.value,
                        netLabel: 'Net Cash from Financing',
                        controller: controller,
                      ),
                      const SizedBox(height: 14),
                      // Net Cash Flow
                      _buildNetCashFlowCard(controller),
                      const SizedBox(height: 12),
                      // Reconciliation
                      _buildReconciliationCard(controller),
                      const SizedBox(height: 16),
                      // Action Buttons
                      _buildActionButtons(controller, context),
                      const SizedBox(height: 24),
                    ],
                  ),
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
    CashFlowController controller,
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cash Flow',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            controller.periodText.value,
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
                  GestureDetector(
                    onTap: () => controller.loadCashFlowData(),
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.exportToExcel(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
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
    CashFlowController controller,
  ) {
    return Obx(
      () => Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
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
            style: const TextStyle(fontSize: 12, color: Colors.black87),
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
                      child: Text(year.name, overflow: TextOverflow.ellipsis),
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
              }
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PERIOD SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPeriodSelector(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedPeriod.value,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: kText),
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    dropdownColor: kCardBg,
                    items: controller.periodOptions
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        if (value == 'Custom Range') {
                          _selectDateRange(controller, context);
                        } else {
                          controller.changePeriod(value);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.selectedDateRange.value != null) {
              final range = controller.selectedDateRange.value!;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('dd MMM').format(range.start)} – ${DateFormat('dd MMM yyyy').format(range.end)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => controller.clearDateRange(),
                        child: Icon(Icons.close, size: 14, color: kPrimary),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(CashFlowController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Opening',
              amount: controller.formatAmount(
                controller.openingCashBalance.value,
              ),
              color: kPrimary,
              icon: Icons.account_balance,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Net Flow',
              amount: controller.formatAmount(controller.netCashFlow.value),
              color: controller.netCashFlow.value >= 0 ? kSuccess : kDanger,
              icon: controller.netCashFlow.value >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
              bgColor: controller.netCashFlow.value >= 0
                  ? kSuccess.withOpacity(0.08)
                  : kDanger.withOpacity(0.08),
              borderColor: controller.netCashFlow.value >= 0
                  ? kSuccess.withOpacity(0.2)
                  : kDanger.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Closing',
              amount: controller.formatAmount(
                controller.closingCashBalance.value,
              ),
              color: kSuccess,
              icon: Icons.account_balance_wallet,
              bgColor: kSuccess.withOpacity(0.08),
              borderColor: kSuccess.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIVITIES SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActivitiesSection({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required double netValue,
    required String netLabel,
    required CashFlowController controller,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cash Flow from $title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text('No data', style: TextStyle(fontSize: 12, color: kSubText)),
          ],
        ),
      );
    }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cash Flow from $title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: items.map((item) {
                final isPositive = item.amount >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        controller.formatAmount(item.amount.abs()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? kSuccess : kDanger,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Net Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  netLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    controller.formatAmount(netValue),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: netValue >= 0 ? kSuccess : kDanger,
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

  // ═══════════════════════════════════════════════════════════════
  // NET CASH FLOW CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNetCashFlowCard(CashFlowController controller) {
    return Obx(() {
      final net = controller.netCashFlow.value;
      final color = net >= 0 ? kSuccess : kDanger;
      final isPositive = net >= 0;

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
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Net Cash Flow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  controller.formatAmount(net.abs()),
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
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPositive ? 'Positive Cash Flow' : 'Negative Cash Flow',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RECONCILIATION CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReconciliationCard(CashFlowController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 16,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Cash Balance Reconciliation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildReconciliationRow(
              'Opening Cash Balance',
              controller.formatAmount(controller.openingCashBalance.value),
            ),
            _buildReconciliationRow(
              'Add: Net Cash Flow',
              controller.formatAmount(controller.netCashFlow.value),
              isAdd: true,
              color: controller.netCashFlow.value >= 0 ? kSuccess : kDanger,
            ),
            Divider(color: Colors.grey.withOpacity(0.15), height: 16),
            _buildReconciliationRow(
              'Closing Cash Balance',
              controller.formatAmount(controller.closingCashBalance.value),
              isBold: true,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationRow(
    String label,
    String amount, {
    bool isAdd = false,
    bool isBold = false,
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isAdd ? '   + $label' : label,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: kText,
            ),
          ),
          isTotal
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                )
              : Text(
                  amount,
                  style: TextStyle(
                    fontSize: isBold ? 13 : 12,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: color ?? kText,
                  ),
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButtons(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.exportToExcel(),
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
            label: Text('PDF', style: TextStyle(fontSize: 12, color: kDanger)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kDanger),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.printReport(),
            icon: Icon(Icons.print_outlined, size: 16, color: Colors.white),
            label: Text(
              'Print',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildErrorState(CashFlowController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: kDanger),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: TextStyle(fontSize: 16, color: kSubText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.retryLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  void _selectDateRange(
    CashFlowController controller,
    BuildContext context,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );
    if (picked != null) {
      controller.setDateRange(picked);
    }
  }
}
