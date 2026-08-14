// screens/balance_sheet_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/widgets/expandable_stat_card.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:BisonsTechs_app/core/balancesheet/controller/balance_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fiscalYearController = Get.isRegistered<FiscalYearController>()
        ? Get.find<FiscalYearController>()
        : Get.put(FiscalYearController(), permanent: true);
    final alreadyBound = Get.isRegistered<BalanceSheetController>();
    final controller = Get.put(BalanceSheetController());
    if (alreadyBound) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadBalanceSheet();
      });
    }

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller, fiscalYearController),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  _buildFiscalYearPicker(
                    fiscalYearController,
                    controller,
                  ),
                  const SizedBox(height: 8),
                  _buildDateHeader(controller, fiscalYearController),
                  const SizedBox(height: 8),
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
                      if (controller.isEmptyReport.value) {
                        return _buildEmptyYearState(fiscalYearController);
                      }
                      return Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummaryCards(controller),
                                const SizedBox(height: 14),
                                _buildSectionCard(
                                  title: 'Assets',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: kPrimary,
                                  dataEntries:
                                      controller.assetsData.entries.toList(),
                                  totalLabel: 'Total Assets',
                                  totalValue: controller.totalAssets.value,
                                ),
                                const SizedBox(height: 12),
                                _buildSectionCard(
                                  title: 'Liabilities',
                                  icon: Icons.money_off_outlined,
                                  color: kDanger,
                                  dataEntries: controller
                                      .liabilitiesData.entries
                                      .toList(),
                                  totalLabel: 'Total Liabilities',
                                  totalValue:
                                      controller.totalLiabilities.value,
                                ),
                                if (controller.hasEquitySection) ...[
                                  const SizedBox(height: 12),
                                  _buildSectionCard(
                                    title: 'Equity',
                                    icon: Icons.trending_up_outlined,
                                    color: kSuccess,
                                    dataEntries:
                                        controller.equityData.entries.toList(),
                                    totalLabel: 'Total Equity',
                                    totalValue: controller.equity.value,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _buildEquationCard(controller),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          if (controller.isRefreshing.value)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: kPrimary,
                                backgroundColor: kPrimary.withOpacity(0.12),
                              ),
                            ),
                        ],
                      );
                    }),
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
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(
    BuildContext context,
    BalanceSheetController controller,
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
                          'Balance Sheet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            'As of ${DateFormat('dd MMM yyyy').format(controller.asOfDate.value)}',
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
                    onTap: () => controller.loadBalanceSheet(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: controller.periodOptions.map((p) {
                      final isSelected = controller.selectedPeriod.value == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => controller.changePeriod(p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? kPrimary : Colors.white,
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
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DATE HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFiscalYearPicker(
    FiscalYearController fyController,
    BalanceSheetController controller,
  ) {
    return Obx(() {
      if (fyController.fiscalYears.isEmpty) {
        return TextButton.icon(
          onPressed: () => Get.to(() => const FiscalYearListScreen()),
          icon: Icon(Icons.calendar_month_outlined, size: 16, color: kPrimary),
          label: const Text('Set up fiscal year'),
        );
      }

      final selected = fyController.selectedFiscalYear.value;
      final selectedId = fyController.fiscalYears.any((y) => y.id == selected?.id)
          ? selected!.id
          : fyController.fiscalYears.first.id;

      return Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 22),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: fyController.fiscalYears.map((FiscalYear year) {
              return DropdownMenuItem<String>(
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
                        '${year.name}  ·  ${DateFormat('dd MMM yyyy').format(year.startDate)} – ${DateFormat('dd MMM yyyy').format(year.endDate)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id == null) return;
              final year = fyController.fiscalYears.firstWhereOrNull(
                (y) => y.id == id,
              );
              if (year != null) controller.changeFiscalYear(year);
            },
          ),
        ),
      );
    });
  }

  Widget _buildDateHeader(
    BalanceSheetController controller,
    FiscalYearController fyController,
  ) {
    return Obx(
      () {
        final fy = fyController.selectedFiscalYear.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: kSubText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fy == null
                      ? 'As of ${DateFormat('dd MMM yyyy').format(controller.asOfDate.value)}'
                      : '${fy.name}  ·  As of ${DateFormat('dd MMM yyyy').format(controller.asOfDate.value)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  controller.selectedPeriod.value,
                  style: TextStyle(
                    fontSize: 10,
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(BalanceSheetController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Assets',
              amount: controller.formatAmount(controller.totalAssets.value),
              color: kPrimary,
              icon: Icons.account_balance_wallet,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Liabilities',
              amount: controller.formatAmount(
                controller.totalLiabilities.value,
              ),
              color: kDanger,
              icon: Icons.money_off,
              bgColor: kDanger.withOpacity(0.08),
              borderColor: kDanger.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Equity',
              amount: controller.formatAmount(controller.equity.value),
              color: kSuccess,
              icon: Icons.trending_up,
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
    bool isNumber = false,
  }) {
    return ExpandableStatCard(
      title: title,
      amount: amount,
      color: color,
      icon: icon,
      bgColor: bgColor,
      borderColor: borderColor,
    );
  }


  // ═══════════════════════════════════════════════════════════════
  // SECTION CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<MapEntry<String, Map<String, double>>> dataEntries,
    required String totalLabel,
    required double totalValue,
  }) {
    if (dataEntries.isEmpty || dataEntries.every((e) => e.value.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(16),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const Spacer(),
            Text('No entries', style: TextStyle(fontSize: 12, color: kSubText)),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kText,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dataEntries.map((entry) {
                if (entry.value.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSubSection(entry.key, entry.value, color),
                );
              }).toList(),
            ),
          ),
          // Total
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
                  totalLabel,
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
                    _formatAmount(totalValue),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
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

  Widget _buildSubSection(
    String title,
    Map<String, double> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ...items.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    e.key,
                    style: TextStyle(fontSize: 12, color: kText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatAmount(e.value),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: e.value < 0 ? kDanger : kText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACCOUNTING EQUATION CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEquationCard(BalanceSheetController controller) {
    return Obx(() {
      final isBalanced = controller.isBalanced.value;
      final diff = controller.balanceDifference.value;
      final totalLE =
          controller.totalLiabilities.value + controller.equity.value;
      final color = isBalanced ? kSuccess : kDanger;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calculate_outlined, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  'Accounting Equation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Assets
            _buildEquationRow(
              'Total Assets',
              controller.totalAssets.value,
              kPrimary,
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '=',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                ],
              ),
            ),

            // Liabilities
            _buildEquationRow(
              'Total Liabilities',
              controller.totalLiabilities.value,
              kDanger,
            ),
            const SizedBox(height: 4),

            // Plus sign
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kSubText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Equity
            _buildEquationRow(
              'Total Equity',
              controller.equity.value,
              kSuccess,
            ),

            Divider(color: Colors.grey.withOpacity(0.2), height: 16),

            // L + E Total
            _buildEquationRow(
              'Total L + E',
              totalLE,
              Colors.purple,
              bold: true,
            ),

            const SizedBox(height: 12),

            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBalanced ? Icons.check_circle : Icons.warning_amber,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isBalanced
                        ? 'Assets = Liabilities + Equity ✓'
                        : 'Difference: ${_formatAmount(diff)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
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

  Widget _buildEquationRow(
    String label,
    double amount,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: kText,
          ),
        ),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyYearState(FiscalYearController fyController) {
    final fy = fyController.selectedFiscalYear.value;
    final name = fy?.name ?? 'this fiscal year';
    final range = fy == null
        ? ''
        : '${DateFormat('dd MMM yyyy').format(fy.startDate)} – ${DateFormat('dd MMM yyyy').format(fy.endDate)}';
    final isFuture = fy != null && fy.startDate.isAfter(DateTime.now());

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 56, color: kPrimary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              isFuture
                  ? '$name has not started yet'
                  : 'No posted activity in $name',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2E),
              ),
              textAlign: TextAlign.center,
            ),
            if (range.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                range,
                style: TextStyle(fontSize: 13, color: kSubText),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              isFuture
                  ? 'Switch to the current fiscal year to see balances.'
                  : 'Balances only include journals posted in the selected year.',
              style: TextStyle(fontSize: 13, color: kSubText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BalanceSheetController controller) {
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

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
