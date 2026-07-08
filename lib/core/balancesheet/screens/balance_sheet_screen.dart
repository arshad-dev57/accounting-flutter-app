import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/balancesheet/controller/balance_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class BalanceSheetScreen extends StatelessWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BalanceSheetController());
    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, BalanceSheetController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        if (controller.hasError.value) {
          return _buildErrorState(controller);
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileDateHeader(controller),
              const SizedBox(height: 12),
              _buildMobileSummaryCards(controller),
              const SizedBox(height: 16),
              // Assets Section
              _buildMobileSectionCard(
                title: 'Assets',
                icon: Icons.account_balance_wallet_outlined,
                color: kPrimary,
                dataEntries: controller.assetsData.entries.toList(),
                totalLabel: 'Total Assets',
                totalValue: controller.totalAssets.value,
              ),
              const SizedBox(height: 12),
              // Liabilities Section
              _buildMobileSectionCard(
                title: 'Liabilities',
                icon: Icons.money_off_outlined,
                color: kDanger,
                dataEntries: controller.liabilitiesData.entries.toList(),
                totalLabel: 'Total Liabilities',
                totalValue: controller.totalLiabilities.value,
              ),
              if (controller.hasEquitySection) ...[
                const SizedBox(height: 12),
                // Equity Section
                _buildMobileSectionCard(
                  title: 'Equity',
                  icon: Icons.trending_up_outlined,
                  color: kSuccess,
                  dataEntries: controller.equityData.entries.toList(),
                  totalLabel: 'Total Equity',
                  totalValue: controller.equity.value,
                ),
              ],
              const SizedBox(height: 16),
              // Equation Card
              _buildMobileEquationCard(controller),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, BalanceSheetController controller) {
    return AppBar(
      title: const Text(
        'Balance Sheet',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        Obx(() => Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedPeriod.value,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black87, size: 18),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              dropdownColor: kCardBg,
              items: controller.periodOptions
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: TextStyle(fontSize: 12, color: kText)),
                      ))
                  .toList(),
              onChanged: (v) { if (v != null) controller.changePeriod(v); },
            ),
          ),
        )),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportToExcel(),
        ),
      ],
    );
  }

  Widget _buildMobileDateHeader(BalanceSheetController controller) {
    return Obx(() => Text(
      'As of ${DateFormat('dd MMM yyyy').format(controller.asOfDate.value)}',
      style: TextStyle(fontSize: 12, color: kSubText, fontWeight: FontWeight.w500),
    ));
  }

  Widget _buildMobileSummaryCards(BalanceSheetController controller) {
    return Obx(() {
      final totalLE = controller.totalLiabilities.value + controller.equity.value;
      final isBalanced = controller.isBalanced.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMobileSummaryCard('Total Assets', controller.formatAmount(controller.totalAssets.value), kPrimary, Icons.account_balance_wallet),
            const SizedBox(width: 10),
            _buildMobileSummaryCard('Liabilities', controller.formatAmount(controller.totalLiabilities.value), kDanger, Icons.money_off),
            const SizedBox(width: 10),
            _buildMobileSummaryCard('Equity', controller.formatAmount(controller.equity.value), kSuccess, Icons.trending_up),
            const SizedBox(width: 10),
            _buildMobileSummaryCard('L + E', controller.formatAmount(totalLE), Colors.purple, Icons.calculate_outlined),
            const SizedBox(width: 10),
            _buildMobileSummaryCard('Status', isBalanced ? 'Balanced ✓' : 'Unbalanced ✗',
                isBalanced ? kSuccess : kDanger,
                isBalanced ? Icons.check_circle_outline : Icons.warning_amber_outlined),
          ],
        ),
      );
    });
  }

  Widget _buildMobileSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title, style: TextStyle(fontSize: 10, color: kSubText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMobileSectionCard({
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
          const Spacer(),
          Text('No entries', style: TextStyle(fontSize: 12, color: kSubText)),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kText)),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dataEntries.map((entry) {
                if (entry.value.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMobileSubSection(entry.key, entry.value),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(totalLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(_formatAmount(totalValue), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSubSection(String title, Map<String, double> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSubText)),
        const SizedBox(height: 6),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(flex: 3, child: Text(e.key, style: TextStyle(fontSize: 12, color: kText), overflow: TextOverflow.ellipsis)),
            Text(_formatAmount(e.value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: e.value < 0 ? kDanger : kText)),
          ]),
        )),
      ],
    );
  }

  // ==================== EQUATION CARD (Mobile) ====================
  Widget _buildMobileEquationCard(BalanceSheetController controller) {
    return Obx(() {
      final isBalanced = controller.isBalanced.value;
      final diff = controller.balanceDifference.value;
      final totalLE = controller.totalLiabilities.value + controller.equity.value;
      final color = isBalanced ? kSuccess : kDanger;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            // Equation title
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.calculate_outlined, size: 16, color: color),
              const SizedBox(width: 6),
              Text('Accounting Equation',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ]),
            const SizedBox(height: 12),
            // Assets row
            _buildEquationRow('Total Assets', controller.totalAssets.value, kPrimary),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('=', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                ),
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
              ]),
            ),
            // Liabilities row
            _buildEquationRow('Total Liabilities', controller.totalLiabilities.value, kDanger),
            const SizedBox(height: 6),
            // Plus sign
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kSubText)),
            ]),
            const SizedBox(height: 6),
            // Equity row
            _buildEquationRow('Total Equity', controller.equity.value, kSuccess),
            Divider(color: Colors.grey.withOpacity(0.2), height: 16),
            // L + E total
            _buildEquationRow('Total L + E', totalLE, Colors.purple, bold: true),
            const SizedBox(height: 12),
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isBalanced ? Icons.check_circle : Icons.warning_amber, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  isBalanced
                      ? 'Assets = Liabilities + Equity ✓'
                      : 'Difference: ${_formatAmount(diff)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ]),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEquationRow(String label, double amount, Color color, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: kText)),
      Text(_formatAmount(amount),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    ]);
  }

  Widget _buildErrorState(BalanceSheetController controller) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 48, color: kDanger),
        const SizedBox(height: 12),
        Text(controller.errorMessage.value, style: TextStyle(color: kSubText, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: controller.retryLoad,
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, BalanceSheetController controller) {
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
              if (controller.hasError.value) {
                return _buildErrorState(controller);
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller),
                  Expanded(child: _buildWebBody(controller, context)),
                  _buildWebTotalsBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, BalanceSheetController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Balance Sheet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const Expanded(child: SizedBox()),
          Obx(() => Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedPeriod.value,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 18),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                dropdownColor: kCardBg,
                items: controller.periodOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 13, color: kText))))
                    .toList(),
                onChanged: (v) { if (v != null) controller.changePeriod(v); },
              ),
            ),
          )),
          _webTopBarBtn(Icons.download_outlined, 'Export', () => controller.exportToExcel()),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _webTopBarBtn(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: Colors.black87),
      label: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
      ),
    );
  }

  // ---- Web KPI Strip ----
  Widget _buildWebKpiStrip(BalanceSheetController controller) {
    return Obx(() {
      final isBalanced = controller.isBalanced.value;
      final totalLE = controller.totalLiabilities.value + controller.equity.value;
      return Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: [
            _buildWebKpiTile('Total Assets', controller.formatAmount(controller.totalAssets.value), kPrimary, Icons.account_balance_wallet),
            _buildWebKpiDivider(),
            _buildWebKpiTile('Total Liabilities', controller.formatAmount(controller.totalLiabilities.value), kDanger, Icons.money_off),
            _buildWebKpiDivider(),
            _buildWebKpiTile('Total Equity', controller.formatAmount(controller.equity.value), kSuccess, Icons.trending_up),
            _buildWebKpiDivider(),
            _buildWebKpiTile('L + E', controller.formatAmount(totalLE), Colors.purple, Icons.calculate_outlined),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              isBalanced ? 'Balanced ✓' : 'Unbalanced ✗',
              isBalanced ? 'Assets = L + E' : 'Diff: ${controller.formatAmount(controller.balanceDifference.value)}',
              isBalanced ? kSuccess : kDanger,
              isBalanced ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() => Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  // ---- Web Toolbar ----
  Widget _buildWebToolbar(BalanceSheetController controller) {
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
      child: Obx(() => Row(children: [
        Icon(Icons.calendar_today_outlined, size: 14, color: kSubText),
        const SizedBox(width: 6),
        Text(
          'As of ${DateFormat('dd MMM yyyy').format(controller.asOfDate.value)}  •  Period: ${controller.selectedPeriod.value}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kSubText),
        ),
      ])),
    );
  }

  // ---- Web Body — LEFT: Liabilities + Equity | RIGHT: Assets ----
  Widget _buildWebBody(BalanceSheetController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT — Liabilities + Equity
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWebSectionGroup(
                    title: 'Liabilities',
                    icon: Icons.money_off_outlined,
                    color: kDanger,
                    dataEntries: controller.liabilitiesData.entries.toList(),
                  ),
                  if (controller.hasEquitySection) ...[
                    const SizedBox(height: 16),
                    _buildWebSectionGroup(
                      title: 'Equity',
                      icon: Icons.trending_up_outlined,
                      color: kSuccess,
                      dataEntries: controller.equityData.entries.toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Vertical divider
          Container(width: 1, color: Colors.grey.withOpacity(0.18), margin: const EdgeInsets.symmetric(horizontal: 16)),
          // RIGHT — Assets
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildWebSectionGroup(
                title: 'Assets',
                icon: Icons.account_balance_wallet_outlined,
                color: kPrimary,
                dataEntries: controller.assetsData.entries.toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSectionGroup({
    required String title,
    required IconData icon,
    required Color color,
    required List<MapEntry<String, Map<String, double>>> dataEntries,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: kBg,
            child: Row(children: [
              Expanded(flex: 3, child: Text('ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.5))),
              Text('AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.5)),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          if (dataEntries.isEmpty || dataEntries.every((e) => e.value.isEmpty))
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No entries', style: TextStyle(fontSize: 13, color: kSubText)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dataEntries.map((entry) {
                  if (entry.value.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildWebSubSection(entry.key, entry.value),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebSubSection(String title, Map<String, double> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        ...items.entries.map((e) => Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: kPrimary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(4),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(children: [
                const SizedBox(width: 12),
                Expanded(flex: 3, child: Text(e.key, style: TextStyle(fontSize: 13, color: kText), overflow: TextOverflow.ellipsis)),
                Text(_formatAmount(e.value),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: e.value < 0 ? kDanger : kText)),
              ]),
            ),
          ),
        )),
      ],
    );
  }

  // ---- Web Totals Bar — Assets = Liabilities + Equity ----
  Widget _buildWebTotalsBar(BalanceSheetController controller) {
    return Obx(() {
      final isBalanced = controller.isBalanced.value;
      final totalLE = controller.totalLiabilities.value + controller.equity.value;
      final statusColor = isBalanced ? kSuccess : kDanger;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            // LEFT: Total Liabilities + Equity
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Liabilities + Equity',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatAmount(controller.totalLiabilities.value)}  +  ${_formatAmount(controller.equity.value)}',
                        style: TextStyle(fontSize: 10, color: kSubText),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatAmount(totalLE),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kDanger),
                    ),
                  ),
                ]),
              ),
            ),
            // Divider
            Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.grey.withOpacity(0.2)),
            // RIGHT: Total Assets
            Expanded(
              flex: 4,
              child: Row(children: [
                Text('Total Assets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _formatAmount(controller.totalAssets.value),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kPrimary),
                  ),
                ),
              ]),
            ),
            // Balance Status Pill
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(children: [
                Icon(isBalanced ? Icons.check_circle : Icons.warning_amber, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  isBalanced ? 'Balanced ✓' : 'Diff: ${_formatAmount(controller.balanceDifference.value)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ]),
            ),
          ],
        ),
      );
    });
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}