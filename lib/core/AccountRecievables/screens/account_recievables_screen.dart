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
  Widget _buildMobileLayout(BuildContext context, AccountsReceivableController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.displayCustomers.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileCustomersList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AccountsReceivableController controller) {
    return AppBar(
      title: const Text(
        'Accounts Receivable',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showMobileSearch(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportReport(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(AccountsReceivableController controller, BuildContext context) {
    final List<String> filterOptions = ['All', 'Overdue', 'Due This Week', 'Due This Month', 'Paid'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: filterOptions.map((filter) {
            final isSelected = controller.selectedFilter.value == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => controller.changeFilter(isSelected ? 'All' : filter),
                backgroundColor: kBg,
                selectedColor: kPrimary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? kPrimary : kSubText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildMobileSummaryCards(AccountsReceivableController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildMobileSummaryCard('Total Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.receipt),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Overdue', _formatAmount(controller.totalOverdue.value), kWarning, Icons.warning),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Due This Week', _formatAmount(controller.totalDueThisWeek.value), kPrimary, Icons.view_week),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Due This Month', _formatAmount(controller.totalDueThisMonth.value), kPrimary, Icons.calendar_month),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Active Customers', controller.activeCustomers.value.toString(), kSuccess, Icons.people, isNumber: true),
          ],
        )),
      ),
    );
  }

  Widget _buildMobileSummaryCard(String title, String amount, Color color, IconData icon, {bool isNumber = false}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMobileCustomersList(AccountsReceivableController controller, BuildContext context) {
    return Obx(() {
      final customers = controller.displayCustomers;
      if (customers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No customers found', style: TextStyle(fontSize: 16, color: kSubText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddCustomerDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Customer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
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

  Widget _buildMobileCustomerCard(Customer customer, AccountsReceivableController controller, BuildContext context) {
    final overdueCount = customer.invoices.where((inv) => inv.status == 'Overdue').length;
    final dueSoonCount = customer.invoices.where((inv) => _isDueSoon(inv.dueDate)).length;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCustomerDetails(customer, controller, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          const SizedBox(height: 2),
                          Text(
                            customer.email.isNotEmpty ? customer.email : customer.phone,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatAmount(customer.outstandingAmount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kDanger)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: overdueCount > 0 ? kDanger.withOpacity(0.1) : kSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${customer.totalInvoices} inv',
                            style: TextStyle(fontSize: 9, color: overdueCount > 0 ? kDanger : kSuccess, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCustomerDetails(customer, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text('Details', style: TextStyle(fontSize: 11, color: kText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(customer, controller, context),
                        icon: const Icon(Icons.payment, size: 14, color: Colors.black87),
                        label: const Text('Pay', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (overdueCount > 0 || dueSoonCount > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (overdueCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kDanger.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.warning, size: 10, color: kDanger),
                            const SizedBox(width: 2),
                            Text('$overdueCount Overdue', style: TextStyle(fontSize: 9, color: kDanger, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      if (dueSoonCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.schedule, size: 10, color: kWarning),
                            const SizedBox(width: 2),
                            Text('$dueSoonCount Due Soon', style: TextStyle(fontSize: 9, color: kWarning, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT — EXACTLY like ExpenseScreen
  // ─────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, AccountsReceivableController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.displayCustomers.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32),
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

  Widget _buildWebTopBar(BuildContext context, AccountsReceivableController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Accounts Receivable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              onChanged: (value) => controller.searchCustomers(value),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search customers…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black45),
                filled: true,
                fillColor: Colors.white.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => controller.exportReport(),
            icon: const Icon(Icons.download_outlined, size: 15, color: Colors.black87),
            label: const Text('Export', style: TextStyle(fontSize: 13, color: Colors.black87)),
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
            onPressed: () => _showAddCustomerDialog(controller, context),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text('Add Customer', style: TextStyle(fontSize: 13, color: Colors.black87)),
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

  Widget _buildWebKpiStrip(AccountsReceivableController controller) {
    return Obx(() => Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          _buildWebKpiTile('Total Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.receipt),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Overdue', _formatAmount(controller.totalOverdue.value), kWarning, Icons.warning),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Due This Week', _formatAmount(controller.totalDueThisWeek.value), kPrimary, Icons.view_week),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Due This Month', _formatAmount(controller.totalDueThisMonth.value), kPrimary, Icons.calendar_month),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Active Customers', controller.activeCustomers.value.toString(), kSuccess, Icons.people),
        ],
      ),
    ));
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

  Widget _buildWebKpiDivider() => Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(AccountsReceivableController controller, BuildContext context) {
    final List<String> filterOptions = ['All', 'Overdue', 'Due This Week', 'Due This Month', 'Paid'];

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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: filterOptions.map((filter) {
                  final isSelected = controller.selectedFilter.value == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => controller.changeFilter(filter),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                        ),
                        child: Text(
                          filter,
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
              )),
            ),
          ),
        ],
      ),
    );
  }

  // EXACT TABLE DESIGN LIKE ExpenseScreen
  Widget _buildWebCustomersTable(AccountsReceivableController controller, BuildContext context) {
    return Obx(() {
      final customers = controller.displayCustomers;

      if (customers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No customers found', style: TextStyle(fontSize: 15, color: kSubText)),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => _showAddCustomerDialog(controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('+ Add Customer', style: TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
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
                Expanded(flex: 1, child: _tableHeaderCell('Invoices', align: TextAlign.center)),
                Expanded(flex: 2, child: _tableHeaderCell('Total', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Paid', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Outstanding', align: TextAlign.right)),
                Expanded(flex: 1, child: _tableHeaderCell('Alerts', align: TextAlign.center)),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) => _buildWebTableRow(customers[index], controller, context),
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
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.5),
    );
  }

  // EXACT ROW DESIGN LIKE ExpenseScreen
  Widget _buildWebTableRow(Customer customer, AccountsReceivableController controller, BuildContext context) {
    final overdueCount = customer.invoices.where((inv) => inv.status == 'Overdue').length;
    final dueSoonCount = customer.invoices.where((inv) => _isDueSoon(inv.dueDate)).length;

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
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    customer.name[0].toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary),
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
                      Text(customer.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                          overflow: TextOverflow.ellipsis),
                      if (customer.email.isNotEmpty)
                        Text(customer.email,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            overflow: TextOverflow.ellipsis),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${customer.totalInvoices}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
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
                  style: TextStyle(fontSize: 13, color: kSubText, fontWeight: FontWeight.w500),
                ),
              ),
              // Paid Amount
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(customer.paidAmount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: kSuccess, fontWeight: FontWeight.w600),
                ),
              ),
              // Outstanding Amount with background
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatAmount(customer.outstandingAmount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kDanger.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                          child: Text('$overdueCount OD', style: TextStyle(fontSize: 10, color: kDanger, fontWeight: FontWeight.w600)),
                        ),
                      if (dueSoonCount > 0 && overdueCount == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                          child: Text('$dueSoonCount DS', style: TextStyle(fontSize: 10, color: kWarning, fontWeight: FontWeight.w600)),
                        ),
                      if (overdueCount == 0 && dueSoonCount == 0)
                        Text('—', style: TextStyle(fontSize: 12, color: kSubText)),
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
                    _webIconBtn(Icons.remove_red_eye_outlined, kSubText, () => _showCustomerDetails(customer, controller, context)),
                    const SizedBox(width: 4),
                    _webIconBtn(Icons.payment, kSuccess, () => _showPaymentDialog(customer, controller, context)),
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
        width: 28, height: 28,
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // EXACT FOOTER DESIGN LIKE ExpenseScreen
  Widget _buildWebTableFooter(List<Customer> customers, AccountsReceivableController controller) {
    final totalAmount = customers.fold(0.0, (s, c) => s + c.totalAmount);
    final totalPaid = customers.fold(0.0, (s, c) => s + c.paidAmount);
    final totalOutstanding = customers.fold(0.0, (s, c) => s + c.outstandingAmount);
    final overdueCustomers = customers.where((c) => c.invoices.any((i) => i.status == 'Overdue')).length;

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
          const Expanded(flex: 3,
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
              )),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalAmount),
              textAlign: TextAlign.right,
              style:  TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSubText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(totalPaid),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSuccess),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: Text(
                _formatAmount(totalOutstanding),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDanger),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '$overdueCustomers OD',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kDanger),
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
  void _showAddCustomerDialog(AccountsReceivableController controller, BuildContext ctx) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String address = '';

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: isWeb ? 500 : MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(maxHeight: isWeb ? 600 : 500),
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Customer', style: TextStyle(fontSize: isWeb ? 20 : 18, fontWeight: FontWeight.w800, color: kText)),
                  SizedBox(height: isWeb ? 20 : 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            _buildTextField('Customer Name *', (v) => name = v, isWeb: isWeb),
                            SizedBox(height: isWeb ? 16 : 12),
                            _buildTextField('Email', (v) => email = v, isWeb: isWeb),
                            SizedBox(height: isWeb ? 16 : 12),
                            _buildTextField('Phone *', (v) => phone = v, isWeb: isWeb),
                            SizedBox(height: isWeb ? 16 : 12),
                            _buildTextField('Address', (v) => address = v, isWeb: isWeb, maxLines: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(fontSize: isWeb ? 14 : 12))),
                      ),
                      SizedBox(width: isWeb ? 16 : 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              controller.createCustomer({'name': name, 'email': email, 'phone': phone, 'address': address});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                          child: Text('Add Customer', style: TextStyle(fontSize: isWeb ? 14 : 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomerDetails(Customer customer, AccountsReceivableController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: isWeb ? 500 : MediaQuery.of(ctx).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(customer.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kPrimary))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(customer.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
                      Text(customer.email, style: TextStyle(fontSize: 13, color: kSubText)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildDetailRow('Phone', customer.phone, isWeb),
                    _buildDetailRow('Total Invoices', customer.totalInvoices.toString(), isWeb),
                    _buildDetailRow('Total Amount', _formatAmount(customer.totalAmount), isWeb),
                    _buildDetailRow('Paid Amount', _formatAmount(customer.paidAmount), isWeb),
                    _buildDetailRow('Outstanding', _formatAmount(customer.outstandingAmount), isWeb),
                    if (customer.lastPaymentDate != null)
                      _buildDetailRow('Last Payment', DateFormat('dd MMM yyyy').format(customer.lastPaymentDate!), isWeb),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Recent Invoices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
              const SizedBox(height: 8),
              ...customer.invoices.take(3).map((invoice) => _buildInvoiceItem(invoice, isWeb)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { Navigator.pop(ctx); controller.viewInvoices(customer); },
                      icon: const Icon(Icons.receipt, size: 18),
                      label: const Text('All Invoices', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(ctx); _showPaymentDialog(customer, controller, ctx); },
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: kSuccess),
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

  void _showPaymentDialog(Customer customer, AccountsReceivableController controller, BuildContext context) {
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

  void _showMobileSearch(BuildContext context, AccountsReceivableController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Search Customers', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          onChanged: (value) => controller.searchCustomers(value),
          decoration: const InputDecoration(
            hintText: 'Enter name, email or phone...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // FORM HELPERS - KEEP ORIGINAL
  // ─────────────────────────────────────────
  Widget _buildTextField(String label, Function(String) onChanged, {bool isWeb = false, int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
      maxLines: maxLines,
      validator: label.contains('*') ? (value) => value == null || value.isEmpty ? '$label required' : null : null,
      onChanged: onChanged,
    );
  }

  Widget _buildDetailRow(String label, String value, bool isWeb) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 12 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isWeb ? 13 : 11, color: kSubText, fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(Invoice invoice, bool isWeb) {
    final statusColor = invoice.status == 'Paid' ? kSuccess : invoice.status == 'Overdue' ? kDanger : kWarning;
    final outstanding = invoice.amount - invoice.paidAmount;
    
    return Container(
      margin: EdgeInsets.only(bottom: isWeb ? 8 : 6),
      padding: EdgeInsets.all(isWeb ? 12 : 10),
      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(isWeb ? 10 : 8)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(invoice.id, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: kText)),
              Text(DateFormat('dd MMM yyyy').format(invoice.date), style: TextStyle(fontSize: isWeb ? 10 : 9, color: kSubText)),
            ]),
          ),
          Text(_formatAmount(outstanding), style: TextStyle(fontSize: isWeb ? 13 : 11, fontWeight: FontWeight.w700, color: statusColor)),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isWeb ? 8 : 6, vertical: isWeb ? 4 : 2),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(isWeb ? 6 : 4)),
            child: Text(invoice.status, style: TextStyle(fontSize: isWeb ? 10 : 9, color: statusColor, fontWeight: FontWeight.w600)),
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
}