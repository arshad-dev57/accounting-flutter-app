import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
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

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, PLController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40));
        }
        return Column(
          children: [
            _buildMobilePeriodBar(controller, context),
            Expanded(child: _buildReportBody(controller, context, isMobile: true)),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, PLController controller) {
    return AppBar(
      title: const Text(
        'Profit & Loss',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
          onPressed: () => controller.exportToPdf(),
        ),
        IconButton(
          icon: const Icon(Icons.table_chart, color: Colors.black87),
          onPressed: () => controller.exportToExcel(),
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Colors.black87),
          onPressed: () => controller.printReport(),
        ),
      ],
    );
  }

  Widget _buildMobilePeriodBar(PLController controller, BuildContext context) {
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
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(p),
                      selected: isSelected,
                      onSelected: (_) => controller.changePeriod(p),
                      backgroundColor: kBg,
                      selectedColor: kPrimary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? kPrimary : kSubText,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  );
                }).toList(),
              ),
            )),
          ),
          InkWell(
            onTap: () => _selectDateRange(controller, context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.date_range, size: 18, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, PLController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32));
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildReportBody(controller, context, isMobile: false)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, PLController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Profit & Loss Statement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          ElevatedButton.icon(
            onPressed: () => controller.exportToExcel(),
            icon: const Icon(Icons.table_chart, size: 15, color: Colors.black87),
            label: const Text('Excel', style: TextStyle(fontSize: 13, color: Colors.black87)),
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
            onPressed: () => controller.exportToPdf(),
            icon: const Icon(Icons.picture_as_pdf, size: 15, color: Colors.black87),
            label: const Text('PDF', style: TextStyle(fontSize: 13, color: Colors.black87)),
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
            onPressed: () => controller.printReport(),
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
        ],
      ),
    );
  }

  Widget _buildWebKpiStrip(PLController controller) {
    return Obx(() {
      final isProfit = controller.netProfit.value >= 0;
      return Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: [
            _buildWebKpiTile('Total Revenue', _formatAmount(controller.totalRevenue.value), kSuccess, Icons.trending_up),
            _buildWebKpiDivider(),
            _buildWebKpiTile('COGS', _formatAmount(controller.costOfGoodsSold.value), kWarning, Icons.inventory_2_outlined),
            _buildWebKpiDivider(),
            _buildWebKpiTile('Gross Profit', _formatAmount(controller.grossProfit.value), kPrimary, Icons.account_balance_outlined),
            _buildWebKpiDivider(),
            _buildWebKpiTile('Op. Expenses', _formatAmount(controller.operatingExpenses.value), kDanger, Icons.receipt_long),
            _buildWebKpiDivider(),
            _buildWebKpiTile(isProfit ? 'Net Profit' : 'Net Loss', _formatAmount(controller.netProfit.value.abs()), isProfit ? kSuccess : kDanger, isProfit ? Icons.arrow_upward : Icons.arrow_downward),
          ],
        ),
      );
    });
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

  Widget _buildWebToolbar(PLController controller, BuildContext context) {
    final periods = controller.periodOptions.where((p) => p != 'Custom Range').toList();
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
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: periods.map((p) {
                final isSelected = controller.selectedPeriod.value == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => controller.changePeriod(p),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                      ),
                      child: Text(
                        p,
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
          const Spacer(),
          // Active date range chip
          Obx(() {
            final range = controller.selectedDateRange.value;
            if (range != null) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range, size: 13, color: kPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd MMM').format(range.start)} – ${DateFormat('dd MMM yyyy').format(range.end)}',
                      style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.clearDateRange(),
                      child: Icon(Icons.close, size: 12, color: kPrimary),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          // Custom range button
          InkWell(
            onTap: () => _selectDateRange(controller, context),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 14, color: kSubText),
                  const SizedBox(width: 6),
                  Text('Custom Range', style: TextStyle(fontSize: 12, color: kSubText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REPORT BODY (shared mobile/web) ====================

  Widget _buildReportBody(PLController controller, BuildContext context, {required bool isMobile}) {
    final h = isMobile ? 12.0 : 16.0;
    final hPad = isMobile ? 16.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: h),
      physics: const BouncingScrollPhysics(),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period title card
          _buildPeriodTitleCard(controller, isMobile),
          SizedBox(height: h),

          // Revenue
          _buildSection(
            title: 'Revenue',
            icon: Icons.trending_up,
            color: kSuccess,
            items: controller.revenueItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
            total: controller.totalRevenue.value,
            totalLabel: 'Total Revenue',
            isMobile: isMobile,
          ),
          SizedBox(height: h),

          // COGS
          if (controller.costOfGoodsSold.value > 0) ...[
            _buildSection(
              title: 'Cost of Goods Sold',
              icon: Icons.inventory_2_outlined,
              color: kDanger,
              items: [_SectionItem('COGS', controller.costOfGoodsSold.value)],
              total: controller.costOfGoodsSold.value,
              totalLabel: 'Total COGS',
              isMobile: isMobile,
            ),
            SizedBox(height: h),
          ],

          // Gross Profit
          _buildGrossProfitCard(controller, isMobile),
          SizedBox(height: h),

          // Operating Expenses
          _buildSection(
            title: 'Operating Expenses',
            icon: Icons.receipt_long,
            color: kDanger,
            items: controller.expenseItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
            total: controller.operatingExpenses.value,
            totalLabel: 'Total Operating Expenses',
            isMobile: isMobile,
          ),
          SizedBox(height: h),

          // Other Income
          if (controller.otherIncomeItems.isNotEmpty) ...[
            _buildSection(
              title: 'Other Income',
              icon: Icons.add_circle_outline,
              color: kSuccess,
              items: controller.otherIncomeItems.map((i) => _SectionItem(i.name, i.amount)).toList(),
              total: controller.otherIncomeItems.fold(0.0, (s, i) => s + i.amount),
              totalLabel: 'Total Other Income',
              isMobile: isMobile,
            ),
            SizedBox(height: h),
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
              isMobile: isMobile,
            ),
            SizedBox(height: h),
          ],

          // Net Profit / Loss
          _buildNetProfitCard(controller, isMobile),
          SizedBox(height: h * 1.5),

          // Action buttons
          _buildActionButtons(controller, isMobile),
          const SizedBox(height: 20),
        ],
      )),
    );
  }

  Widget _buildPeriodTitleCard(PLController controller, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text('Profit & Loss Statement',
              style: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 4),
          Obx(() => Text(controller.periodText.value,
              style: TextStyle(fontSize: isMobile ? 12 : 13, color: kSubText))),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_SectionItem> items,
    required double total,
    required String totalLabel,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
          // Line items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
            child: Column(
              children: [
                ...items.map((item) => _buildReportRow(item.name, item.amount, isMobile)),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                _buildReportRow(totalLabel, total, isMobile, isBold: true),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
        ],
      ),
    );
  }

  Widget _buildGrossProfitCard(PLController controller, bool isMobile) {
    final isProfit = controller.grossProfit.value >= 0;
    final color = isProfit ? kSuccess : kDanger;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.account_balance_outlined, size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Text('Gross Profit', style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
            child: Column(
              children: [
                _buildReportRow('Total Revenue', controller.totalRevenue.value, isMobile),
                if (controller.costOfGoodsSold.value > 0)
                  _buildReportRow('Less: COGS', controller.costOfGoodsSold.value, isMobile, isNegative: true),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                _buildReportRow('Gross Profit', controller.grossProfit.value, isMobile, isBold: true, color: color),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard(PLController controller, bool isMobile) {
    final isProfit = controller.netProfit.value >= 0;
    final color = isProfit ? kSuccess : kDanger;
    final label = isProfit ? 'Net Profit' : 'Net Loss';

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(isProfit ? Icons.arrow_upward : Icons.arrow_downward, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(label, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
              Text(
                _formatAmount(controller.netProfit.value.abs()),
                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isProfit ? Icons.trending_up : Icons.trending_down, size: 16, color: color),
                const SizedBox(width: 8),
                Obx(() => Text(
                  'Profit Margin: ${controller.netProfitMargin.value.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: isMobile ? 13 : 14, color: color, fontWeight: FontWeight.w600),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, double amount, bool isMobile,
      {bool isBold = false, Color? color, bool isNegative = false, double? fontSize}) {
    final fs = fontSize ?? (isMobile ? (isBold ? 13.0 : 12.0) : (isBold ? 14.0 : 13.0));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 7 : 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fs,
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
              fontSize: fs,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isNegative ? kDanger : kText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PLController controller, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.exportToExcel(),
            icon: Icon(Icons.table_chart, size: isMobile ? 16 : 18),
            label: Text('Export Excel', style: TextStyle(fontSize: isMobile ? 12 : 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: BorderSide(color: kPrimary),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.exportToPdf(),
            icon: Icon(Icons.picture_as_pdf, size: isMobile ? 16 : 18),
            label: Text('Save PDF', style: TextStyle(fontSize: isMobile ? 12 : 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kDanger,
              side: BorderSide(color: kDanger),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 10 : 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.printReport(),
            icon: Icon(Icons.print_outlined, size: isMobile ? 16 : 18, color: Colors.black87),
            label: Text('Print', style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

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

// Helper model for report items within the screen
class _SectionItem {
  final String name;
  final double amount;
  _SectionItem(this.name, this.amount);
}
