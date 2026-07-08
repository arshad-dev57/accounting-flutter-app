import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/cashflowstatement/controller/cashflow_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sizer/sizer.dart';

class CashFlowStatementScreen extends StatelessWidget {
  const CashFlowStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CashFlowController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(
    BuildContext context,
    CashFlowController controller,
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
        if (controller.hasError.value) {
          return _buildErrorState(context, controller, isMobile: true);
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobilePeriodSelector(controller, context),
              _buildMobileSummaryCards(controller, context),
              _buildMobileActivitiesSection(
                title: 'Operating Activities',
                icon: Icons.business_center,
                color: kPrimary,
                items: controller.operatingItems,
                netValue: controller.cashFlowFromOperations.value,
                netLabel: 'Net Cash from Operating',
                controller: controller,
              ),
              _buildMobileActivitiesSection(
                title: 'Investing Activities',
                icon: Icons.trending_down,
                color: kWarning,
                items: controller.investingItems,
                netValue: controller.cashFlowFromInvesting.value,
                netLabel: 'Net Cash from Investing',
                controller: controller,
              ),
              _buildMobileActivitiesSection(
                title: 'Financing Activities',
                icon: Icons.account_balance,
                color: kSuccess,
                items: controller.financingItems,
                netValue: controller.cashFlowFromFinancing.value,
                netLabel: 'Net Cash from Financing',
                controller: controller,
              ),
              _buildMobileNetCashFlow(controller),
              _buildMobileReconciliation(controller),
              _buildMobileActionButtons(controller, context),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    CashFlowController controller,
  ) {
    return AppBar(
      title: const Text(
        'Cash Flow Statement',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportToExcel(),
        ),
        IconButton(
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            color: Colors.black87,
          ),
          onPressed: () => _generateAndPrintPDF(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Colors.black87),
          onPressed: () => controller.printReport(),
        ),
      ],
    );
  }

  // ---- Mobile Period Selector ----

  Widget _buildMobilePeriodSelector(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kCardBg,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedPeriod.value,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: kText),
                    isExpanded: true,
                    style: TextStyle(fontSize: 13, color: kText),
                    dropdownColor: kCardBg,
                    items: controller.periodOptions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          ),
                        )
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
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${DateFormat('dd MMM').format(range.start)} – ${DateFormat('dd MMM yyyy').format(range.end)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.clearDateRange(),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
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

  // ---- Mobile Summary Cards ----

  Widget _buildMobileSummaryCards(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMobileSummaryCard(
                'Opening Balance',
                controller.formatAmount(controller.openingCashBalance.value),
                kPrimary,
                Icons.account_balance,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Net Cash Flow',
                controller.formatAmount(controller.netCashFlow.value),
                controller.netCashFlow.value >= 0 ? kSuccess : kDanger,
                controller.netCashFlow.value >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Closing Balance',
                controller.formatAmount(controller.closingCashBalance.value),
                kSuccess,
                Icons.account_balance_wallet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---- Mobile Activities Section ----

  Widget _buildMobileActivitiesSection({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required double netValue,
    required String netLabel,
    required CashFlowController controller,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cash Flow from $title',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) =>
                _buildMobileCashFlowRow(controller, item.name, item.amount),
          ),
          Divider(color: Colors.grey.withOpacity(0.15), height: 16),
          _buildMobileCashFlowRow(controller, netLabel, netValue, isBold: true),
        ],
      ),
    );
  }

  Widget _buildMobileCashFlowRow(
    CashFlowController controller,
    String label,
    double amount, {
    bool isBold = false,
  }) {
    final color = amount >= 0 ? kSuccess : kDanger;
    final display =
        (amount < 0 ? '-' : '') + controller.formatAmount(amount.abs());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 12 : 11,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            display,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mobile Net Cash Flow ----

  Widget _buildMobileNetCashFlow(CashFlowController controller) {
    return Obx(() {
      final net = controller.netCashFlow.value;
      final color = net >= 0 ? kSuccess : kDanger;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Net Increase / Decrease in Cash',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                Text(
                  (net < 0 ? '-' : '') + controller.formatAmount(net.abs()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  net >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  net >= 0 ? 'Positive Cash Flow' : 'Negative Cash Flow',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ---- Mobile Reconciliation ----

  Widget _buildMobileReconciliation(CashFlowController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
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
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Balance Reconciliation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 10),
            _buildMobileReconciliationRow(
              'Opening Cash Balance',
              controller.formatAmount(controller.openingCashBalance.value),
            ),
            _buildMobileReconciliationRow(
              'Add: Net Cash Flow',
              controller.formatAmount(controller.netCashFlow.value),
              isAdd: true,
            ),
            Divider(color: Colors.grey.withOpacity(0.15), height: 16),
            _buildMobileReconciliationRow(
              'Closing Cash Balance',
              controller.formatAmount(controller.closingCashBalance.value),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileReconciliationRow(
    String label,
    String amount, {
    bool isAdd = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              isAdd ? '   + $label' : label,
              style: TextStyle(
                fontSize: isBold ? 12 : 11,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: kText,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mobile Action Buttons ----

  Widget _buildMobileActionButtons(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _generateAndPrintPDF(controller, context),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Save as PDF', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.printReport(),
              icon: const Icon(Icons.print, size: 16, color: Colors.white),
              label: const Text(
                'Print Report',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, CashFlowController controller) {
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
                    size: 32,
                  ),
                );
              }
              if (controller.hasError.value) {
                return _buildErrorState(context, controller, isMobile: false);
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebPeriodToolbar(controller, context),
                  Expanded(child: _buildWebScrollBody(controller, context)),
                  _buildWebFooterBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---- Web Top Bar ----

  Widget _buildWebTopBar(BuildContext context, CashFlowController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Cash Flow Statement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Expanded(child: SizedBox()),
          _webTopBarBtn(
            Icons.download_outlined,
            'Export',
            () => controller.exportToExcel(),
          ),
          const SizedBox(width: 8),
          _webTopBarBtn(
            Icons.picture_as_pdf_outlined,
            'Save PDF',
            () => _generateAndPrintPDF(controller, context),
          ),
          const SizedBox(width: 8),
          _webTopBarBtn(
            Icons.print_outlined,
            'Print',
            () => controller.printReport(),
          ),
        ],
      ),
    );
  }

  Widget _webTopBarBtn(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: Colors.black87),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }

  // ---- Web KPI Strip ----
  // ---- Web KPI Strip ----  (REPLACE this entire method)

  Widget _buildWebKpiStrip(CashFlowController controller) {
    return Obx(
      () => Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: IntrinsicHeight(
          // ← key fix: height auto-sizes to tallest child
          child: Row(
            children: [
              _buildWebKpiTile(
                'Opening Balance',
                controller.formatAmount(controller.openingCashBalance.value),
                kPrimary,
                Icons.account_balance,
              ),
              _buildWebKpiDivider(),
              _buildWebKpiTile(
                'Net Cash Flow',
                controller.formatAmount(controller.netCashFlow.value),
                controller.netCashFlow.value >= 0 ? kSuccess : kDanger,
                controller.netCashFlow.value >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
              _buildWebKpiDivider(),
              _buildWebKpiTile(
                'Closing Balance',
                controller.formatAmount(controller.closingCashBalance.value),
                kSuccess,
                Icons.account_balance_wallet,
              ),
              _buildWebKpiDivider(),
              _buildWebKpiTile(
                'Operating',
                controller.formatAmount(
                  controller.cashFlowFromOperations.value,
                ),
                kPrimary,
                Icons.business_center,
              ),
              _buildWebKpiDivider(),
              _buildWebKpiTile(
                'Investing',
                controller.formatAmount(controller.cashFlowFromInvesting.value),
                kWarning,
                Icons.trending_down,
              ),
              _buildWebKpiDivider(),
              _buildWebKpiTile(
                'Financing',
                controller.formatAmount(controller.cashFlowFromFinancing.value),
                kSuccess,
                Icons.account_balance,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Web KPI Tile ---- (REPLACE this entire method)

  Widget _buildWebKpiTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ), // ← reduced from 14→12
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32, // ← 34→32
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color), // ← 16→15
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  // ---- Web Period Toolbar ----

  Widget _buildWebPeriodToolbar(
    CashFlowController controller,
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
          SizedBox(
            width: 200,
            height: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kBorder),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedPeriod.value,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: kText),
                    isExpanded: true,
                    style: TextStyle(fontSize: 12, color: kText),
                    dropdownColor: kCardBg,
                    items: controller.periodOptions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p, overflow: TextOverflow.ellipsis),
                          ),
                        )
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
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('dd MMM yyyy').format(range.start)} – ${DateFormat('dd MMM yyyy').format(range.end)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.clearDateRange(),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: kPrimary,
                        ),
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

  // ---- Web Scroll Body ----

  Widget _buildWebScrollBody(
    CashFlowController controller,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column — the three activities
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildWebActivitiesCard(
                  title: 'Cash Flow from Operating Activities',
                  icon: Icons.business_center,
                  color: kPrimary,
                  items: controller.operatingItems,
                  netValue: controller.cashFlowFromOperations.value,
                  netLabel: 'Net Cash from Operating Activities',
                  controller: controller,
                ),
                const SizedBox(height: 16),
                _buildWebActivitiesCard(
                  title: 'Cash Flow from Investing Activities',
                  icon: Icons.trending_down,
                  color: kWarning,
                  items: controller.investingItems,
                  netValue: controller.cashFlowFromInvesting.value,
                  netLabel: 'Net Cash from Investing Activities',
                  controller: controller,
                ),
                const SizedBox(height: 16),
                _buildWebActivitiesCard(
                  title: 'Cash Flow from Financing Activities',
                  icon: Icons.account_balance,
                  color: kSuccess,
                  items: controller.financingItems,
                  netValue: controller.cashFlowFromFinancing.value,
                  netLabel: 'Net Cash from Financing Activities',
                  controller: controller,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right column — summary + reconciliation + actions
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildWebNetCashFlowCard(controller),
                const SizedBox(height: 16),
                _buildWebReconciliationCard(controller),
                const SizedBox(height: 16),
                _buildWebActionButtons(controller, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebActivitiesCard({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
    required double netValue,
    required String netLabel,
    required CashFlowController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kSubText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          ...items.map(
            (item) => _buildWebCashFlowRow(controller, item.name, item.amount),
          ),
          Divider(color: Colors.grey.withOpacity(0.15), height: 16),
          _buildWebCashFlowRow(controller, netLabel, netValue, isBold: true),
        ],
      ),
    );
  }

  Widget _buildWebCashFlowRow(
    CashFlowController controller,
    String label,
    double amount, {
    bool isBold = false,
  }) {
    final color = amount >= 0 ? kSuccess : kDanger;
    final display =
        (amount < 0 ? '-' : '') + controller.formatAmount(amount.abs());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: isBold
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                : EdgeInsets.zero,
            decoration: isBold
                ? BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              display,
              style: TextStyle(
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNetCashFlowCard(CashFlowController controller) {
    return Obx(() {
      final net = controller.netCashFlow.value;
      final color = net >= 0 ? kSuccess : kDanger;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Cash Flow Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Increase / Decrease',
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
                    (net < 0 ? '-' : '') + controller.formatAmount(net.abs()),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  net >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  net >= 0 ? 'Positive Cash Flow' : 'Negative Cash Flow',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWebReconciliationCard(CashFlowController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Balance Reconciliation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kSubText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kSubText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            _buildWebReconciliationRow(
              'Opening Cash Balance',
              controller.formatAmount(controller.openingCashBalance.value),
            ),
            _buildWebReconciliationRow(
              'Add: Net Cash Flow',
              controller.formatAmount(controller.netCashFlow.value),
              isAdd: true,
            ),
            Divider(color: Colors.grey.withOpacity(0.15), height: 16),
            _buildWebReconciliationRow(
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

  Widget _buildWebReconciliationRow(
    String label,
    String amount, {
    bool isAdd = false,
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
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
                    color: kText,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWebActionButtons(
    CashFlowController controller,
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _generateAndPrintPDF(controller, context),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Save as PDF', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => controller.printReport(),
            icon: const Icon(Icons.print, size: 16, color: Colors.white),
            label: const Text(
              'Print Report',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ---- Web Footer Bar ----

  Widget _buildWebFooterBar(CashFlowController controller) {
    return Obx(
      () => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${controller.operatingItems.length + controller.investingItems.length + controller.financingItems.length} line items  •  Period: ${controller.selectedPeriod.value}',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
            Obx(() {
              final net = controller.netCashFlow.value;
              final color = net >= 0 ? kSuccess : kDanger;
              return Row(
                children: [
                  Icon(
                    net >= 0
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    net >= 0
                        ? 'Net positive cash position'
                        : 'Net negative cash position',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED: ERROR STATE ====================

  Widget _buildErrorState(
    BuildContext context,
    CashFlowController controller, {
    required bool isMobile,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: isMobile ? 64 : 80, color: kDanger),
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            controller.errorMessage.value,
            style: TextStyle(fontSize: isMobile ? 13 : 14, color: kDanger),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          ElevatedButton(
            onPressed: () => controller.retryLoad(),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DATE RANGE PICKER ====================

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

  // ==================== PDF GENERATION ====================

  Future<void> _generateAndPrintPDF(
    CashFlowController controller,
    BuildContext context,
  ) async {
    final isWeb = ResponsiveUtils.isWeb(context);
    try {
      Get.dialog(
        Center(
          child: Container(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(
                  color: kPrimary,
                  size: isWeb ? 50 : 40,
                ),
                SizedBox(height: isWeb ? 16 : 12),
                Text(
                  'Generating PDF...',
                  style: TextStyle(fontSize: isWeb ? 14 : 12, color: kText),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildPdfHeader(controller),
            pw.SizedBox(height: 20),
            _buildPdfCashBalanceSummary(controller),
            pw.SizedBox(height: 20),
            _buildPdfActivitiesSection(
              'Cash Flow from Operating Activities',
              controller.operatingItems,
              controller.cashFlowFromOperations.value,
              'Net Cash from Operating Activities',
              PdfColors.blue,
            ),
            pw.SizedBox(height: 15),
            _buildPdfActivitiesSection(
              'Cash Flow from Investing Activities',
              controller.investingItems,
              controller.cashFlowFromInvesting.value,
              'Net Cash from Investing Activities',
              PdfColors.orange,
            ),
            pw.SizedBox(height: 15),
            _buildPdfActivitiesSection(
              'Cash Flow from Financing Activities',
              controller.financingItems,
              controller.cashFlowFromFinancing.value,
              'Net Cash from Financing Activities',
              PdfColors.green,
            ),
            pw.SizedBox(height: 20),
            _buildPdfNetCashFlowSection(controller),
            pw.SizedBox(height: 20),
            _buildPdfCashBalanceReconciliation(controller),
            pw.SizedBox(height: 30),
            _buildPdfFooter(),
          ],
        ),
      );

      Get.back();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'Cash_Flow_Statement_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
      AppSnackbar.success(
        Colors.green,
        'Success',
        'PDF generated successfully',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.back();
      AppSnackbar.error(
        Colors.red,
        'Error',
        'Failed to generate PDF: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ---- PDF Widgets ----

  pw.Widget _buildPdfHeader(CashFlowController controller) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Cash Flow Statement',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          controller.periodText.value,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPdfCashBalanceSummary(CashFlowController controller) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildPdfBalanceCard(
          'Opening Balance',
          controller.formatAmount(controller.openingCashBalance.value),
          PdfColors.blue,
        ),
        _buildPdfBalanceCard(
          'Net Cash Flow',
          controller.formatAmount(controller.netCashFlow.value),
          controller.netCashFlow.value >= 0 ? PdfColors.green : PdfColors.red,
        ),
        _buildPdfBalanceCard(
          'Closing Balance',
          controller.formatAmount(controller.closingCashBalance.value),
          PdfColors.green,
        ),
      ],
    );
  }

  pw.Widget _buildPdfBalanceCard(String title, String amount, PdfColor color) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfActivitiesSection(
    String title,
    List items,
    double netValue,
    String netLabel,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 10),
        ...items.map((item) => _buildPdfRow(item.name, item.amount)),
        pw.Divider(),
        _buildPdfRow(netLabel, netValue, isBold: true),
      ],
    );
  }

  pw.Widget _buildPdfNetCashFlowSection(CashFlowController controller) {
    final color = controller.netCashFlow.value >= 0
        ? PdfColors.green
        : PdfColors.red;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          _buildPdfRow(
            'Net Increase / Decrease in Cash',
            controller.netCashFlow.value,
            isBold: true,
            color: color,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            controller.netCashFlow.value >= 0
                ? 'Positive Cash Flow'
                : 'Negative Cash Flow',
            style: pw.TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCashBalanceReconciliation(CashFlowController controller) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cash Balance Reconciliation',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildPdfReconciliationRow(
          'Opening Cash Balance',
          controller.formatAmount(controller.openingCashBalance.value),
        ),
        _buildPdfReconciliationRow(
          'Add: Net Cash Flow',
          controller.formatAmount(controller.netCashFlow.value),
          isAdd: true,
        ),
        pw.Divider(),
        _buildPdfReconciliationRow(
          'Closing Cash Balance',
          controller.formatAmount(controller.closingCashBalance.value),
          isBold: true,
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'This is a computer-generated document and does not require a signature.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildPdfRow(
    String label,
    double amount, {
    bool isBold = false,
    PdfColor? color,
  }) {
    final amountColor = amount >= 0 ? PdfColors.green : PdfColors.red;
    final display = (amount < 0 ? '-' : '') + _formatAmountForPdf(amount.abs());
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
          pw.Text(
            display,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? amountColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfReconciliationRow(
    String label,
    String amount, {
    bool isAdd = false,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isAdd ? '   + $label' : label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmountForPdf(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return CurrencyUtils.format(amount);
  }
}
