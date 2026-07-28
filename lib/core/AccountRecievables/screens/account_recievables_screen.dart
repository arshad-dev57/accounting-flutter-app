import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/AccountRecievables/controllers/account_recievables_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountsReceivableScreen extends StatelessWidget {
  const AccountsReceivableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountsReceivableController());

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
    AccountsReceivableController controller,
  ) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildMobileTopHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.displayCustomers.isEmpty) {
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
                  Expanded(child: _buildMobileCustomersList(controller, context)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Mobile Top Header (matches Expense/Bank Accounts style) ──
  Widget _buildMobileTopHeader(
    BuildContext context,
    AccountsReceivableController controller,
  ) {
    final List<String> filterOptions = [
      'All',
      'Overdue',
      'Due This Week',
      'Due This Month',
      'Paid',
    ];
    final searchController = TextEditingController();

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
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accounts Receivable',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.displayCustomers.length} customers',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.fetchAllData(),
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
                    onTap: () => controller.exportReport(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: Colors.black.withOpacity(0.65),
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
                        controller: searchController,
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) => controller.searchQuery.value = value,
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          value: controller.selectedFilter.value,
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          underline: const SizedBox.shrink(),
                          items: filterOptions.map((f) {
                            return DropdownMenuItem(value: f, child: Text(f));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) controller.changeFilter(v);
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

  // ── Mobile Summary Cards (matches Expense layout) ──
  Widget _buildMobileSummaryCards(AccountsReceivableController controller) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(
          children: [
            // Top row: Total Outstanding + Overdue
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Total Outstanding',
                    value: _formatAmount(controller.totalOutstanding.value),
                    icon: Icons.receipt,
                    accentColor: kDanger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Overdue',
                    value: _formatAmount(controller.totalOverdue.value),
                    icon: Icons.warning,
                    accentColor: kWarning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom: Due This Week + Active Customers
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Due This Week',
                    value: _formatAmount(controller.totalDueThisWeek.value),
                    icon: Icons.view_week,
                    accentColor: kPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Active Customers',
                    value: controller.activeCustomers.value.toString(),
                    icon: Icons.people,
                    accentColor: kSuccess,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: kSubText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomersList(
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final customers = controller.displayCustomers;
      if (customers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No customers found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileCustomerCard(customer, controller, context),
          );
        },
      );
    });
  }

  Widget _buildMobileCustomerCard(
    Customer customer,
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    final overdueCount = customer.invoices
        .where((inv) => inv.status == 'Overdue')
        .length;
    final statusColor = overdueCount > 0 ? kDanger : kSuccess;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
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
          onTap: () => _showCustomerDetails(customer, controller, context),
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
                        color: kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
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
                            customer.email.isNotEmpty
                                ? customer.email
                                : customer.phone,
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
                              _badge(
                                overdueCount > 0 ? 'Overdue' : 'Active',
                                statusColor,
                              ),
                              _badge('${customer.totalInvoices} invoices', kSubText),
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
                        border: Border.all(
                          color: kDanger.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Outstanding',
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
                              _formatAmount(customer.outstandingAmount),
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
                            _showCustomerDetails(customer, controller, context),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showPaymentDialog(customer, controller, context),
                        icon: const Icon(
                          Icons.payment,
                          size: 14,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Pay',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
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
  // WEB LAYOUT — EXACTLY like ExpenseScreen
  // ─────────────────────────────────────────
  Widget _buildWebLayout(
    BuildContext context,
    AccountsReceivableController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.displayCustomers.isEmpty) {
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
                  Expanded(child: _buildWebCustomersTable(controller, context)),
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
    AccountsReceivableController controller,
  ) {
    final List<String> filterOptions = [
      'All',
      'Overdue',
      'Due This Week',
      'Due This Month',
      'Paid',
    ];

    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'Accounts Receivable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            height: 34,
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.45),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.black.withOpacity(0.5),
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
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(
                () => DropdownButton<String>(
                  value: controller.selectedFilter.value,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  dropdownColor: kCardBg,
                  items: filterOptions.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) controller.changeFilter(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _webHeaderBtn(
            Icons.download_outlined,
            'Export',
            () => controller.exportReport(),
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
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.black.withOpacity(0.65)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiStrip(AccountsReceivableController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tiles = [
          _buildWebKpiTile(
            'Total Outstanding',
            _formatAmount(controller.totalOutstanding.value),
            kDanger,
            Icons.receipt,
          ),
          _buildWebKpiTile(
            'Overdue',
            _formatAmount(controller.totalOverdue.value),
            kWarning,
            Icons.warning,
          ),
          _buildWebKpiTile(
            'Due This Week',
            _formatAmount(controller.totalDueThisWeek.value),
            kPrimary,
            Icons.view_week,
          ),
          _buildWebKpiTile(
            'Due This Month',
            _formatAmount(controller.totalDueThisMonth.value),
            kPrimary,
            Icons.calendar_month,
          ),
          _buildWebKpiTile(
            'Active Customers',
            controller.activeCustomers.value.toString(),
            kSuccess,
            Icons.people,
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
    );
  }

  Widget _buildWebKpiTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
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
                    color: kSubText,
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
      ),
    );
  }

  Widget _kpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(
    AccountsReceivableController controller,
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
          const Text(
            'Accounts Receivable',
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
                '${controller.displayCustomers.length} customers',
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
    
  }

  // EXACT TABLE DESIGN LIKE ExpenseScreen
  Widget _buildWebCustomersTable(
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final customers = controller.displayCustomers;

      if (customers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No Account Recievable found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
              const SizedBox(height: 12),
            
            ],
          ),
        );
      }

      return Column(
        children: [
          // Table header - EXACTLY like ExpenseScreen
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 3, child: _tableHeaderCell('Customer')),
                Expanded(flex: 2, child: _tableHeaderCell('Contact')),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Invoices', align: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Total', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Paid', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell(
                    'Outstanding',
                    align: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Alerts', align: TextAlign.center),
                ),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTableRow(customers[index], controller, context),
            ),
          ),
          _buildWebTableFooter(customers, controller),
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

  // EXACT ROW DESIGN LIKE ExpenseScreen
  Widget _buildWebTableRow(
    Customer customer,
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    final overdueCount = customer.invoices
        .where((inv) => inv.status == 'Overdue')
        .length;
    final dueSoonCount = customer.invoices
        .where((inv) => _isDueSoon(inv.dueDate))
        .length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomerDetails(customer, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Avatar Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    customer.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Customer Name + Email
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.email.isNotEmpty)
                        Text(
                          customer.email,
                          style: TextStyle(fontSize: 11, color: kSubText),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              // Contact (Phone)
              Expanded(
                flex: 2,
                child: Text(
                  customer.phone.isNotEmpty ? customer.phone : '—',
                  style: TextStyle(fontSize: 12, color: kSubText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Invoice count chip
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${customer.totalInvoices}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              // Total Amount
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(customer.totalAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Paid Amount
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(customer.paidAmount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kSuccess,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Outstanding Amount with background
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatAmount(customer.outstandingAmount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kDanger,
                    ),
                  ),
                ),
              ),
              // Alerts
              Expanded(
                flex: 1,
                child: Center(
                  child: Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      if (overdueCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$overdueCount OD',
                            style: TextStyle(
                              fontSize: 10,
                              color: kDanger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (dueSoonCount > 0 && overdueCount == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kWarning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$dueSoonCount DS',
                            style: TextStyle(
                              fontSize: 10,
                              color: kWarning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (overdueCount == 0 && dueSoonCount == 0)
                        Text(
                          '—',
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                    ],
                  ),
                ),
              ),
              // Actions - exactly 68px width like ExpenseScreen
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(
                      Icons.remove_red_eye_outlined,
                      kSubText,
                      () => _showCustomerDetails(customer, controller, context),
                    ),
                    const SizedBox(width: 4),
                    _webIconBtn(
                      Icons.payment,
                      kSuccess,
                      () => _showPaymentDialog(customer, controller, context),
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

  Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // EXACT FOOTER DESIGN LIKE ExpenseScreen
  Widget _buildWebTableFooter(
    List<Customer> customers,
    AccountsReceivableController controller,
  ) {
    final totalAmount = customers.fold(0.0, (s, c) => s + c.totalAmount);
    final totalPaid = customers.fold(0.0, (s, c) => s + c.paidAmount);
    final totalOutstanding = customers.fold(
      0.0,
      (s, c) => s + c.outstandingAmount,
    );
    final overdueCustomers = customers
        .where((c) => c.invoices.any((i) => i.status == 'Overdue'))
        .length;

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
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalAmount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kSubText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalPaid),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kSuccess,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatAmount(totalOutstanding),
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
              child: Text(
                '$overdueCustomers OD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kDanger,
                ),
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DIALOGS - KEEP ORIGINAL LOGIC
  // ─────────────────────────────────────────

  void _showCustomerDetails(
    Customer customer,
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final overdueCount = customer.invoices
        .where((inv) => inv.status == 'Overdue')
        .length;
    final statusColor = overdueCount > 0 ? kDanger : kSuccess;

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
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        customer.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isWeb ? 22 : 28,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        Text(
                          customer.email.isNotEmpty ? customer.email : customer.phone,
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
                      overdueCount > 0 ? 'Overdue' : 'Active',
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
                      _buildDetailRow('Phone', customer.phone, isWeb),
                      _buildDetailRow(
                        'Total Invoices',
                        customer.totalInvoices.toString(),
                        isWeb,
                      ),
                      _buildDetailRow(
                        'Total Amount',
                        _formatAmount(customer.totalAmount),
                        isWeb,
                      ),
                      _buildDetailRow(
                        'Paid Amount',
                        _formatAmount(customer.paidAmount),
                        isWeb,
                        valueColor: kSuccess,
                      ),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow(
                        'Outstanding',
                        _formatAmount(customer.outstandingAmount),
                        isWeb,
                        valueColor: kDanger,
                      ),
                      if (customer.lastPaymentDate != null)
                        _buildDetailRow(
                          'Last Payment',
                          DateFormat('dd MMM yyyy').format(customer.lastPaymentDate!),
                          isWeb,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showPaymentDialog(customer, controller, ctx);
                      },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text(
                        'Record Payment',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
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

  void _showPaymentDialog(
    Customer customer,
    AccountsReceivableController controller,
    BuildContext context,
  ) {
    Get.defaultDialog(
      title: 'Record Payment',
      content: Column(
        children: [
          Text('Customer: ${customer.name}'),
          const SizedBox(height: 10),
          Text('Outstanding: ${_formatAmount(customer.outstandingAmount)}'),
        ],
      ),
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.showRecordPayment(customer);
      },
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
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isWeb ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(Invoice invoice, bool isWeb) {
    final statusColor = invoice.status == 'Paid'
        ? kSuccess
        : invoice.status == 'Overdue'
        ? kDanger
        : kWarning;
    final outstanding = invoice.amount - invoice.paidAmount;

    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 8 : 6),
      padding: EdgeInsets.all(isWeb ? 12 : 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.id,
                  style: TextStyle(
                    fontSize: isWeb ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(invoice.date),
                  style: TextStyle(fontSize: isWeb ? 10 : 9, color: kSubText),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(outstanding),
            style: TextStyle(
              fontSize: isWeb ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 8 : 6,
              vertical: isWeb ? 4 : 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isWeb ? 6 : 4),
            ),
            child: Text(
              invoice.status,
              style: TextStyle(
                fontSize: isWeb ? 10 : 9,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);

