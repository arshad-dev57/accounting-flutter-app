// core/Expense/views/expense_screen.dart - COMPLETE WITH LOADING

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/widgets/expandable_stat_card.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/Expense/controller/expense_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_rate_field.dart';
import 'package:BisonsTechs_app/core/Expense/model/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpenseController());

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
    ExpenseController controller,
  ) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildMobileTopHeader(context, controller),
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
                  _buildMobileSummaryCards(controller),
                  Expanded(child: _buildMobileExpenseList(controller, context)),
                ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(controller, context),
        backgroundColor: kPrimary,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  // ── Mobile Top Header (matches Bank Accounts style) ──
  Widget _buildMobileTopHeader(
    BuildContext context,
    ExpenseController controller,
  ) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar row
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
                          'Expenses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.expenses.length} entries',
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
                    onTap: () => controller.refreshData(),
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
                    onTap: () => controller.exportExpenses(),
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
            // Search + Filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
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
                      child: TextField(
                        controller: controller.searchController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search expenses...',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    child: DropdownButtonHideUnderline(
                      child: Obx(
                        () => DropdownButton<String>(
                          value: controller.selectedType.value == 'All'
                              ? 'All Types'
                              : controller.selectedType.value,
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          underline: const SizedBox.shrink(),
                          items: ['All Types', ...controller.expenseTypes].map((
                            f,
                          ) {
                            return DropdownMenuItem(value: f, child: Text(f));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null)
                              controller.applyTypeFilter(
                                v == 'All Types' ? 'All' : v,
                              );
                          },
                        ),
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

  // ── Mobile Summary Cards (matches Bank Accounts layout) ──
  Widget _buildMobileSummaryCards(ExpenseController controller) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          children: [
            // Top row: Total Expense + This Month
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Total Expense',
                    value: controller.formatAmount(
                      controller.totalExpense.value,
                    ),
                    icon: Icons.trending_down,
                    accentColor: kDanger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'This Month',
                    value: controller.formatAmount(
                      controller.thisMonthTotal.value,
                    ),
                    icon: Icons.calendar_month,
                    accentColor: kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom: This Week + Records
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: 'This Week',
                    value: controller.formatAmount(
                      controller.thisWeekTotal.value,
                    ),
                    icon: Icons.calendar_today,
                    accentColor: kWarning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Total Records',
                    value: controller.totalCount.value.toString(),
                    icon: Icons.receipt_long,
                    accentColor: const Color(0xFF9B59B6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return ExpandableStatTile(
      label: label,
      value: value,
      icon: icon,
      accentColor: accentColor,
    );
  }


  Widget _buildMobileExpenseList(
    ExpenseController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final expenses = controller.expenses;
      if (expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_down,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No expense records found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddExpenseDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileExpenseCard(expense, controller, context),
          );
        },
      );
    });
  }

  // ── Mobile Expense Card (matches Bank Accounts card) ──
  Widget _buildMobileExpenseCard(
    Expense expense,
    ExpenseController controller,
    BuildContext context,
  ) {
    final statusColor = expense.status == 'Posted'
        ? kSuccess
        : expense.status == 'Draft'
        ? kWarning
        : kDanger;
    final typeColor = Color(
      int.parse(
            controller.getTypeColor(expense.expenseType).substring(1, 7),
            radix: 16,
          ) +
          0xFF000000,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showExpenseDetails(expense, controller, context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        controller.getTypeIcon(expense.expenseType),
                        size: 20,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.expenseNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            expense.vendorName.isNotEmpty
                                ? '${expense.expenseType} • ${expense.vendorName}'
                                : expense.expenseType,
                            style: TextStyle(
                              fontSize: 10,
                              color: kSubText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _badge(expense.status, statusColor),
                              _badge(expense.paymentMethod, kSubText),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kDanger.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 8,
                              color: kSubText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              controller.formatAmount(expense.totalAmount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kDanger,
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
                const SizedBox(height: 14),
                // Date + Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showExpenseDetails(expense, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (expense.status == 'Draft')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.postExpense(expense.id),
                          icon: const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, ExpenseController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.expenses.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 32,
                  ),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebExpensesTable(controller, context)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, ExpenseController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Expenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            height: 34,
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 130,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(
                () => DropdownButton<String>(
                  value: controller.selectedType.value == 'All'
                      ? 'All Types'
                      : controller.selectedType.value,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  dropdownColor: kCardBg,
                  items: ['All Types', ...controller.expenseTypes].map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(
                        f,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null)
                      controller.applyTypeFilter(v == 'All Types' ? 'All' : v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _webHeaderBtn(
            Icons.add,
            'Add Expense',
            () => _showAddExpenseDialog(controller, context),
          ),
          const SizedBox(width: 8),
          _webHeaderBtn(
            Icons.download_outlined,
            'Export',
            () => controller.exportExpenses(),
          ),
        ],
      ),
    );
  }

  Widget _webHeaderBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiStrip(ExpenseController controller) {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            _buildWebKpiTile(
              'Total Expense',
              controller.formatAmount(controller.totalExpense.value),
              kDanger,
              Icons.trending_down,
            ),
            _buildWebKpiTile(
              'This Month',
              controller.formatAmount(controller.thisMonthTotal.value),
              kPrimary,
              Icons.calendar_month,
            ),
            _buildWebKpiTile(
              'This Week',
              controller.formatAmount(controller.thisWeekTotal.value),
              kWarning,
              Icons.calendar_today,
            ),
            _buildWebKpiTile(
              'Total Records',
              controller.totalCount.value.toString(),
              const Color(0xFF9B59B6),
              Icons.receipt_long,
            ),
          ];

          if (constraints.maxWidth < 1000) {
            return Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i < tiles.length - 1) _kpiDivider(),
                    ],
                  ],
                ),
              ),
            );
          }
          return Obx(
            () => Row(
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  Expanded(child: tiles[i]),
                  if (i < tiles.length - 1) _kpiDivider(),
                ],
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: kSubText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
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

  Widget _kpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(ExpenseController controller, BuildContext context) {
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
          const Text(
            'Expenses',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.expenses.length} entries',
                style: TextStyle(
                  fontSize: 11,
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebExpensesTable(
    ExpenseController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final expenses = controller.expenses;

      if (expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_down,
                size: 56,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No expense records found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddExpenseDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '+ Add Expense',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Table Header
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 52),
                Expanded(flex: 3, child: _tableHeaderCell('Expense #')),
                Expanded(flex: 2, child: _tableHeaderCell('Type')),
                Expanded(flex: 3, child: _tableHeaderCell('Vendor')),
                Expanded(flex: 2, child: _tableHeaderCell('Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Payment')),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Amount', align: TextAlign.right),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Status', align: TextAlign.center),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: expenses.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTableRow(expenses[index], controller, context),
            ),
          ),
          _buildWebTableFooter(expenses, controller),
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
        color: kSubText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWebTableRow(
    Expense expense,
    ExpenseController controller,
    BuildContext context,
  ) {
    final statusColor = expense.status == 'Posted'
        ? kSuccess
        : expense.status == 'Draft'
        ? kWarning
        : kDanger;
    final typeColor = Color(
      int.parse(
            controller.getTypeColor(expense.expenseType).substring(1, 7),
            radix: 16,
          ) +
          0xFF000000,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showExpenseDetails(expense, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: typeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  controller.getTypeIcon(expense.expenseType),
                  size: 18,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),
              // Expense Number + Reference
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      expense.expenseNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (expense.reference.isNotEmpty)
                      Text(
                        expense.reference,
                        style: TextStyle(fontSize: 10, color: kSubText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Type badge
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.expenseType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: typeColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Vendor
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      expense.vendorName.isNotEmpty ? expense.vendorName : '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(expense.date),
                      style: TextStyle(fontSize: 12, color: kSubText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Payment Method
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      expense.paymentMethod,
                      style: TextStyle(fontSize: 12, color: kSubText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.formatAmount(expense.totalAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kDanger,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              const SizedBox(width: 8),
              _webRowActionBtn(
                Icons.more_vert,
                () => _showRowActions(controller, expense, context),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webRowActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.black.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildWebTableFooter(
    List<Expense> expenses,
    ExpenseController controller,
  ) {
    final postedCount = expenses.where((e) => e.status == 'Posted').length;
    final draftCount = expenses.where((e) => e.status == 'Draft').length;

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
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'TOTALS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                controller.formatAmount(controller.totalExpense.value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: kDanger,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$postedCount POST',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: kSuccess,
                    ),
                  ),
                  if (draftCount > 0)
                    Text(
                      '$draftCount DFT',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: kWarning,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // ADD EXPENSE DIALOG WITH LOADING
  // ─────────────────────────────────────────
  void _showAddExpenseDialog(
    ExpenseController controller,
    BuildContext ctx, {
    Expense? expense,
  }) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final isEditing = expense != null;
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = expense?.date ?? DateTime.now();
    String expenseType = 'Rent';
    if (expense != null) {
      final existingType = expense.expenseType;
      if (controller.formExpenseTypes.contains(existingType)) {
        expenseType = existingType;
      } else {
        controller.rememberCustomExpenseType(existingType);
        expenseType = controller.formExpenseTypes.contains(existingType)
            ? existingType
            : 'Other';
      }
    }
    String? selectedExpenseAccountId = expense?.expenseAccountId;
    String? selectedVendorId = expense?.vendorId;
    List<Map<String, dynamic>> items = expense != null && expense.items.isNotEmpty
        ? expense.items
              .map(
                (i) => {
                  'description': i['description'] ?? '',
                  'quantity': i['quantity'] ?? 1,
                  'unitPrice': (i['unitPrice'] ?? 0).toDouble(),
                },
              )
              .toList()
        : [
            {'description': '', 'quantity': 1, 'unitPrice': 0.0},
          ];
    double simpleAmount = expense == null
        ? 0
        : (expense.hasItems ? 0 : (expense.amount > 0 ? expense.amount : expense.totalAmount));
    double taxRate = expense?.taxRate ?? 0;
    String description = expense?.description ?? '';
    String reference = expense?.reference ?? '';
    String paymentMethod = expense?.paymentMethod ?? 'Cash';
    String? selectedBankAccountId = expense?.bankAccountId;
    final customTypeController = TextEditingController(
      text: expense != null && expenseType == 'Other' ? expense.expenseType : '',
    );

    bool requiresItems() => controller.requiresItems(expenseType);

    Widget expenseTypeField(void Function(void Function()) setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdownField(
            label: 'Expense Type',
            value: expenseType,
            items: [
              ...controller.formExpenseTypes,
              if (!controller.formExpenseTypes.contains(expenseType))
                expenseType,
            ],
            onChanged: (v) => setState(() => expenseType = v!),
          ),
          if (expenseType == 'Other') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: customTypeController,
              decoration: InputDecoration(
                labelText: 'Custom expense type *',
                hintText: 'e.g. Printing, Courier, Donation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              validator: (v) {
                if (expenseType != 'Other') return null;
                if (v == null || v.trim().length < 2) {
                  return 'Enter a custom type';
                }
                return null;
              },
            ),
          ],
        ],
      );
    }

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculateTotal() {
            if (requiresItems()) {
              double total = items.fold(
                0.0,
                (s, i) =>
                    s +
                    (i['quantity'] ?? 1).toDouble() *
                        (i['unitPrice'] ?? 0).toDouble(),
              );
              return total + total * (taxRate / 100);
            }
            return simpleAmount;
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: isWeb ? 560 : double.infinity,
              constraints: BoxConstraints(
                maxHeight: isWeb
                    ? 680
                    : MediaQuery.of(context).size.height * 0.88,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.trending_down,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Expense' : 'Add Expense',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEditing
                                    ? 'Update ${expense.expenseNumber} — ledger will follow'
                                    : 'Create a new expense entry',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: controller.isSaving.value
                              ? null
                              : () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isWeb)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDatePickerField(
                                      'Date',
                                      selectedDate,
                                      (d) => setState(() => selectedDate = d),
                                      isWeb,
                                      context,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: expenseTypeField(setState),
                                  ),
                                ],
                              )
                            else ...[
                              _buildDatePickerField(
                                'Date',
                                selectedDate,
                                (d) => setState(() => selectedDate = d),
                                isWeb,
                                context,
                              ),
                              const SizedBox(height: 12),
                              expenseTypeField(setState),
                            ],

                            const SizedBox(height: 12),
                            if (controller.expenseAccounts.isNotEmpty) ...[
                              _buildExpenseAccountDropdownField(
                                selectedExpenseAccountId,
                                (v) => setState(
                                  () => selectedExpenseAccountId = v,
                                ),
                                controller.expenseAccounts,
                                isWeb,
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (controller.vendors.isNotEmpty) ...[
                              _buildVendorDropdownField(
                                selectedVendorId,
                                (v) => setState(() => selectedVendorId = v),
                                controller.vendors,
                                isWeb,
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (requiresItems()) ...[
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: isWeb ? 13 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _formField(
                                              'Description *',
                                              '',
                                              (v) => item['description'] = v,
                                              initialValue: item['description'],
                                            ),
                                          ),
                                          if (items.length > 1) ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => setState(
                                                () => items.removeAt(idx),
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: kDanger,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _formField(
                                              'Qty',
                                              '1',
                                              (v) => item['quantity'] =
                                                  int.tryParse(v) ?? 1,
                                              initialValue: item['quantity']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: _formField(
                                              'Unit Price *',
                                              '0.00',
                                              (v) => item['unitPrice'] =
                                                  double.tryParse(v) ?? 0,
                                              initialValue: item['unitPrice']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              prefixText: CurrencyUtils.prefix,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              TextButton.icon(
                                onPressed: () => setState(
                                  () => items.add({
                                    'description': '',
                                    'quantity': 1,
                                    'unitPrice': 0.0,
                                  }),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'Add Item',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TaxRateField(
                                value: taxRate,
                                onRateChanged: (v) => setState(() => taxRate = v),
                              ),
                            ] else
                              _formField(
                                'Amount *',
                                '0.00',
                                (v) => simpleAmount = double.tryParse(v) ?? 0,
                                initialValue: simpleAmount > 0
                                    ? simpleAmount.toString()
                                    : '',
                                keyboardType: TextInputType.number,
                                prefixText: CurrencyUtils.prefix,
                              ),

                            const SizedBox(height: 12),
                            if (isWeb)
                              Row(
                                children: [
                                  Expanded(
                                    child: _formField(
                                      'Description',
                                      '',
                                      (v) => description = v,
                                      initialValue: description,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _formField(
                                      'Reference #',
                                      '',
                                      (v) => reference = v,
                                      initialValue: reference,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _formField(
                                'Description',
                                '',
                                (v) => description = v,
                                initialValue: description,
                              ),
                              const SizedBox(height: 12),
                              _formField(
                                'Reference #',
                                '',
                                (v) => reference = v,
                                initialValue: reference,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _dropdownField(
                              label: 'Payment Method',
                              value: paymentMethod,
                              items: const [
                                'Cash',
                                'Bank Transfer',
                                'Cheque',
                                'Credit Card',
                                'Online',
                              ],
                              onChanged: (v) => setState(() {
                                paymentMethod = v!;
                                // clear bank selection when switching to Cash
                                if (v == 'Cash') selectedBankAccountId = null;
                              }),
                            ),
                            // Show bank dropdown for all non-Cash methods
                            if (paymentMethod != 'Cash' &&
                                controller.bankAccounts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildBankDropdownField(
                                selectedBankAccountId,
                                (v) =>
                                    setState(() => selectedBankAccountId = v),
                                controller.bankAccounts,
                                isWeb,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: kDanger.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: kDanger.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    controller.formatAmount(calculateTotal()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: kDanger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide.none,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isSaving.value
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      var typeToSave = expenseType;
                                      if (expenseType == 'Other') {
                                        typeToSave =
                                            customTypeController.text.trim();
                                        controller.rememberCustomExpenseType(
                                          typeToSave,
                                        );
                                      }

                                      if (selectedExpenseAccountId == null ||
                                          selectedExpenseAccountId!.isEmpty) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please select an expense account',
                                        );
                                        return;
                                      }

                                      if (requiresItems()) {
                                        if (items.any(
                                          (i) =>
                                              i['description'].isEmpty ||
                                              i['unitPrice'] <= 0,
                                        )) {
                                          AppSnackbar.error(
                                            kWarning,
                                            'Error',
                                            'Please fill all item details',
                                          );
                                          return;
                                        }
                                      } else if (simpleAmount <= 0) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please enter a valid amount',
                                        );
                                        return;
                                      }

                                      if (paymentMethod != 'Cash' &&
                                          (selectedBankAccountId == null ||
                                              selectedBankAccountId!.isEmpty)) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please select a bank account for $paymentMethod',
                                        );
                                        return;
                                      }

                                      final finalBankAccountId =
                                          paymentMethod == 'Cash'
                                          ? null
                                          : selectedBankAccountId;

                                      print(
                                        '🔍 [Flutter Screen] Before createExpense:',
                                      );
                                      print(
                                        '🔍 [Flutter Screen] paymentMethod: $paymentMethod',
                                      );
                                      print(
                                        '🔍 [Flutter Screen] selectedBankAccountId: $selectedBankAccountId',
                                      );
                                      print(
                                        '🔍 [Flutter Screen] selectedBankAccountId type: ${selectedBankAccountId.runtimeType}',
                                      );
                                      print(
                                        '🔍 [Flutter Screen] finalBankAccountId: $finalBankAccountId',
                                      );
                                      print(
                                        '🔍 [Flutter Screen] finalBankAccountId type: ${finalBankAccountId.runtimeType}',
                                      );

                                      Navigator.pop(context);
                                      if (isEditing) {
                                        await controller.updateExpense(
                                          id: expense.id,
                                          date: selectedDate,
                                          expenseType: typeToSave,
                                          expenseAccountId:
                                              selectedExpenseAccountId,
                                          vendorId: selectedVendorId,
                                          items: requiresItems() ? items : [],
                                          amount: requiresItems()
                                              ? null
                                              : simpleAmount,
                                          taxRate: requiresItems() ? taxRate : 0,
                                          description: description,
                                          reference: reference,
                                          paymentMethod: paymentMethod,
                                          bankAccountId: finalBankAccountId,
                                        );
                                      } else {
                                        await controller.createExpense(
                                          date: selectedDate,
                                          expenseType: typeToSave,
                                          expenseAccountId:
                                              selectedExpenseAccountId,
                                          vendorId: selectedVendorId,
                                          items: requiresItems() ? items : [],
                                          amount: requiresItems()
                                              ? null
                                              : simpleAmount,
                                          taxRate: requiresItems() ? taxRate : 0,
                                          description: description,
                                          reference: reference,
                                          paymentMethod: paymentMethod,
                                          bankAccountId: finalBankAccountId,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isSaving.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      isEditing ? 'Update Expense' : 'Save Expense',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
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
        },
      ),
    ).whenComplete(customTypeController.dispose);
  }

  // ─── FORM HELPERS ──────────────────────────────────────────────
  Widget _buildExpenseAccountDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> expenseAccounts,
    bool isWeb,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Expense Account *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      hint: Text(
        'Select expense account',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      items: expenseAccounts
          .map(
            (a) => DropdownMenuItem(
              value: a['id'].toString(),
              child: Text(
                '${a['code']} - ${a['name']}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an expense account';
        }
        return null;
      },
    );
  }

  Widget _buildVendorDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> vendors,
    bool isWeb,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Vendor',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      hint: Text(
        'Select vendor',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      items: vendors
          .map(
            (v) => DropdownMenuItem(
              value: v['_id'].toString(),
              child: Text(v['name'], overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBankDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> bankAccounts,
    bool isWeb,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Bank Account',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      hint: Text(
        'Select bank account',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      items: bankAccounts.map((a) {
        final accountId = a['id']?.toString() ?? a['_id']?.toString();
        print(
          '🔍 [Flutter Bank Dropdown] Account: ${a['accountName']}, id: ${a['id']}, _id: ${a['_id']}, final: $accountId',
        );
        return DropdownMenuItem(
          value: accountId,
          child: Text(a['accountName'], overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    void Function(DateTime) onChanged,
    bool isWeb,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: kSubText)),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kText,
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

  Widget _dropdownField<T extends String>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String initialValue = '',
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  // ─── DETAIL VIEW ──────────────────────────────────────────────────
  void _showExpenseDetails(
    Expense expense,
    ExpenseController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final statusColor = expense.status == 'Posted'
        ? kSuccess
        : expense.status == 'Draft'
        ? kWarning
        : kDanger;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        ),
        child: Container(
          width: isWeb ? 420 : double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isWeb ? 44 : 50,
                    height: isWeb ? 44 : 50,
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_down,
                      size: isWeb ? 22 : 28,
                      color: kDanger,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.expenseNumber,
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        Text(
                          '${expense.expenseType} • ${DateFormat('dd MMM yyyy').format(expense.date)}',
                          style: TextStyle(
                            fontSize: isWeb ? 12 : 13,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      expense.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Expense Type',
                        expense.expenseType,
                        isWeb,
                      ),
                      if (expense.expenseAccount != null) ...[
                        _buildDetailRow(
                          'Expense Account',
                          '${expense.expenseAccount?['code']} - ${expense.expenseAccount?['name']}',
                          isWeb,
                        ),
                      ],
                      if (expense.vendorName.isNotEmpty)
                        _buildDetailRow('Vendor', expense.vendorName, isWeb),
                      _buildDetailRow(
                        'Payment Method',
                        expense.paymentMethod,
                        isWeb,
                      ),
                      if (expense.reference.isNotEmpty)
                        _buildDetailRow('Reference', expense.reference, isWeb),
                      _buildDetailRow(
                        'Subtotal',
                        _formatAmount(expense.subtotal),
                        isWeb,
                      ),
                      if (expense.taxRate > 0)
                        _buildDetailRow(
                          'Tax (${expense.taxRate.toStringAsFixed(0)}%)',
                          _formatAmount(expense.taxAmount),
                          isWeb,
                        ),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow(
                        'Total Amount',
                        _formatAmount(expense.totalAmount),
                        isWeb,
                        valueColor: kDanger,
                      ),
                      if (expense.description.isNotEmpty)
                        _buildDetailRow(
                          'Description',
                          expense.description,
                          isWeb,
                        ),
                      if (expense.items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontSize: isWeb ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...expense.items
                            .map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['description'] ?? '',
                                            style: TextStyle(
                                              fontSize: isWeb ? 13 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: kText,
                                            ),
                                          ),
                                          Text(
                                            '${item['quantity'] ?? 1} × ${_formatAmount((item['unitPrice'] ?? 0).toDouble())}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: kSubText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatAmount(
                                        (item['amount'] ?? 0).toDouble(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kDanger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (expense.status != 'Cancelled') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddExpenseDialog(
                            controller,
                            context,
                            expense: expense,
                          );
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (expense.status == 'Draft') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          controller.postExpense(expense.id);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Post Expense',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: EdgeInsets.symmetric(
                            vertical: isWeb ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 10 : 12,
                        ),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 14,
                          color: kSubText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTHER HELPER METHODS ──────────────────────────────────────
  void _showRowActions(
    ExpenseController controller,
    Expense expense,
    BuildContext context,
  ) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          onTap: () {
            Future.microtask(() {
              if (expense.status == 'Cancelled') {
                AppSnackbar.error(
                  kWarning,
                  'Error',
                  'Cancelled expenses cannot be edited',
                );
                return;
              }
              _showAddExpenseDialog(controller, context, expense: expense);
            });
          },
          child: const ListTile(
            leading: Icon(Icons.edit, size: 18),
            title: Text('Edit', style: TextStyle(fontSize: 13)),
            dense: true,
          ),
        ),
        PopupMenuItem(
          onTap: () => _showDeleteConfirmation(controller, expense, context),
          child: ListTile(
            leading: Icon(Icons.delete, size: 18, color: kDanger),
            title: const Text('Delete', style: TextStyle(fontSize: 13)),
            dense: true,
          ),
        ),
        PopupMenuItem(
          onTap: () => controller.printExpenses(),
          child: const ListTile(
            leading: Icon(Icons.print, size: 18),
            title: Text('Print', style: TextStyle(fontSize: 13)),
            dense: true,
          ),
        ),
      ],
      elevation: 4,
    );
  }

  void _showDeleteConfirmation(
    ExpenseController controller,
    Expense expense,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete ${expense.expenseNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => {
              Navigator.pop(ctx),
              controller.deleteExpense(expense.id, expense.expenseNumber),
            },
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isWeb, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWeb ? 110 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isWeb ? 12 : 13,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWeb ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
