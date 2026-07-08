// screens/accounts_payable_screen.dart - COMPLETE FIXED VERSION

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/AccountPayable/controller/account_payable_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountsPayableScreen extends StatelessWidget {
  const AccountsPayableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountsPayableController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, AccountsPayableController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.bills.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }

        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileBillsList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillDialog(controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AccountsPayableController controller) {
    return AppBar(
      title: const Text(
        'Accounts Payable',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
          onPressed: () => _showFilterDialog(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportReport(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(AccountsPayableController controller, BuildContext context) {
    final statuses = ['All', 'Unpaid', 'Paid', 'Overdue', 'Partial'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: statuses.map((status) {
            final isSelected = controller.selectedFilter.value == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (_) => controller.changeFilter(isSelected ? 'All' : status),
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

  Widget _buildMobileSummaryCards(AccountsPayableController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildMobileSummaryCard('Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.payment),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Overdue', _formatAmount(controller.totalOverdue.value), kWarning, Icons.warning_amber_rounded),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Due This Week', _formatAmount(controller.totalDueThisWeek.value), kPrimary, Icons.next_week_outlined),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Due This Month', _formatAmount(controller.totalDueThisMonth.value), kPrimary, Icons.calendar_month),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Suppliers', controller.activeSuppliers.value.toString(), kSuccess, Icons.business, isNumber: true),
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

  Widget _buildMobileBillsList(AccountsPayableController controller, BuildContext context) {
    return Obx(() {
      final bills = controller.bills;

      if (controller.isLoading.value && bills.isEmpty) {
        return const SizedBox.shrink();
      }

      if (bills.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No bills found', style: TextStyle(fontSize: 16, color: kSubText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddBillDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Bill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileBillCard(bill, controller, context),
          );
        },
      );
    });
  }

  Widget _buildMobileBillCard(Bill bill, AccountsPayableController controller, BuildContext context) {
    final statusColor = bill.status == 'Paid'
        ? kSuccess
        : bill.status == 'Overdue'
            ? kDanger
            : bill.status == 'Partial'
                ? kWarning
                : kPrimary;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBillDetails(bill, controller, context),
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
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long, size: 20, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bill.billNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          const SizedBox(height: 2),
                          Text(
                            bill.supplierName,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(bill.status, style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(4)),
                                child: Text('Due: ${DateFormat('dd MMM yy').format(bill.dueDate)}',
                                    style: TextStyle(fontSize: 8, color: bill.isOverdue ? kDanger : kSubText, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatAmount(bill.totalAmount),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                        const SizedBox(height: 4),
                        Text('Due: ${_formatAmount(bill.outstanding)}',
                            style: TextStyle(fontSize: 10, color: bill.outstanding > 0 ? kDanger : kSuccess, fontWeight: FontWeight.w600)),
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
                        onPressed: () => _showBillDetails(bill, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text('Details', style: TextStyle(fontSize: 11, color: kText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    if (bill.status != 'Paid') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _recordBillPayment(bill, controller, context),
                          icon: const Icon(Icons.payment, size: 14, color: Colors.black87),
                          label: const Text('Pay Now', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(BuildContext context, AccountsPayableController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.bills.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebBillsTable(controller, context)),
                  _buildWebPaginationBar(controller, context),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, AccountsPayableController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Accounts Payable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(controller, context),
            icon: const Icon(Icons.tune, size: 15, color: Colors.black87),
            label: const Text('Filter', style: TextStyle(fontSize: 13, color: Colors.black87)),
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
            onPressed: () => _showAddBillDialog(controller, context),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text('Add Bill', style: TextStyle(fontSize: 13, color: Colors.black87)),
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

  Widget _buildWebKpiStrip(AccountsPayableController controller) {
    return Obx(() => Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          _buildWebKpiTile('Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.payment),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Overdue', _formatAmount(controller.totalOverdue.value), kWarning, Icons.warning_amber_rounded),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Due This Week', _formatAmount(controller.totalDueThisWeek.value), kPrimary, Icons.next_week_outlined),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Due This Month', _formatAmount(controller.totalDueThisMonth.value), kPrimary, Icons.calendar_month),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Active Suppliers', controller.activeSuppliers.value.toString(), kSuccess, Icons.business),
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

  Widget _buildWebToolbar(AccountsPayableController controller, BuildContext context) {
    final statuses = ['All', 'Unpaid', 'Paid', 'Overdue', 'Partial'];
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
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: statuses.map((status) {
                  final isSelected = controller.selectedFilter.value == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => controller.changeFilter(status),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                        ),
                        child: Text(
                          status,
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
          ),
          const SizedBox(width: 8),
          Obx(() {
            if (controller.startDate.value != null && controller.endDate.value != null) {
              return Container(
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
                      '${DateFormat('dd MMM').format(controller.startDate.value!)} – ${DateFormat('dd MMM yyyy').format(controller.endDate.value!)}',
                      style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.clearFilters(),
                      child: Icon(Icons.close, size: 12, color: kPrimary),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 8),
          // ✅ Supplier filter dropdown
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedSupplierId.value.isEmpty ? '' : controller.selectedSupplierId.value,
                icon: Icon(Icons.arrow_drop_down, size: 16, color: kSubText),
                isDense: true,
                style: TextStyle(fontSize: 12, color: kText),
                dropdownColor: kCardBg,
                hint: Text('All Suppliers', style: TextStyle(fontSize: 12, color: kSubText)),
                items: [
                  DropdownMenuItem<String>(value: '', child: Text('All Suppliers', style: TextStyle(fontSize: 12, color: kText))),
                  ...controller.suppliers.map((s) => DropdownMenuItem<String>(
                    value: s.id,
                    child: Text(s.name, style: TextStyle(fontSize: 12, color: kText), overflow: TextOverflow.ellipsis),
                  )).toList(),
                ],
                onChanged: (v) { if (v != null) controller.filterBySupplier(v); },
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ==================== WEB TABLE ====================

  Widget _buildWebBillsTable(AccountsPayableController controller, BuildContext context) {
    return Obx(() {
      final bills = controller.bills;

      if (bills.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No bills found', style: TextStyle(fontSize: 15, color: kSubText)),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => _showAddBillDialog(controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('+ Add Bill', style: TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Header row
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 3, child: _tableHeaderCell('Bill #')),
                Expanded(flex: 3, child: _tableHeaderCell('Supplier')),
                Expanded(flex: 2, child: _tableHeaderCell('Bill Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Due Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Total', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Paid', align: TextAlign.right)),
                Expanded(flex: 2, child: _tableHeaderCell('Outstanding', align: TextAlign.right)),
                Expanded(flex: 1, child: _tableHeaderCell('Status', align: TextAlign.center)),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: bills.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) => _buildWebTableRow(bills[index], controller, context),
            ),
          ),
          if (bills.isNotEmpty) _buildWebTableFooter(bills, controller),
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

  Widget _buildWebTableRow(Bill bill, AccountsPayableController controller, BuildContext context) {
    final statusColor = bill.status == 'Paid'
        ? kSuccess
        : bill.status == 'Overdue'
            ? kDanger
            : bill.status == 'Partial'
                ? kWarning
                : kPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBillDetails(bill, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.receipt_long, size: 14, color: statusColor),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(bill.billNumber,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                          overflow: TextOverflow.ellipsis),
                      if (bill.notes.isNotEmpty)
                        Text(bill.notes,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(bill.supplierName,
                    style: TextStyle(fontSize: 12, color: kSubText),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 2,
                child: Text(DateFormat('dd MMM yyyy').format(bill.date),
                    style: TextStyle(fontSize: 12, color: kSubText)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(bill.dueDate),
                  style: TextStyle(fontSize: 12, color: bill.isOverdue ? kDanger : kSubText, fontWeight: bill.isOverdue ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(bill.totalAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(bill.paidAmount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSuccess),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bill.outstanding > 0 ? kDanger.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatAmount(bill.outstanding),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: bill.outstanding > 0 ? kDanger : kSuccess),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                    child: Text(
                      bill.status.length > 4 ? bill.status.substring(0, 4).toUpperCase() : bill.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(Icons.remove_red_eye_outlined, kSubText, () => _showBillDetails(bill, controller, context)),
                    const SizedBox(width: 4),
                    if (bill.status != 'Paid')
                      _webIconBtn(Icons.payment, kSuccess, () => _recordBillPayment(bill, controller, context))
                    else
                      _webIconBtn(Icons.more_vert, kSubText, () => _showRowActions(controller, bill, context)),
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

  Widget _buildWebTableFooter(List<Bill> bills, AccountsPayableController controller) {
    final paidCount = bills.where((b) => b.status == 'Paid').length;
    final unpaidCount = bills.where((b) => b.status != 'Paid').length;

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
              child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(bills.fold(0.0, (s, b) => s + b.totalAmount)),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(bills.fold(0.0, (s, b) => s + b.paidAmount)),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSuccess),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _formatAmount(bills.fold(0.0, (s, b) => s + b.outstanding)),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDanger),
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
                  Text('$paidCount PAID', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: kSuccess)),
                  if (unpaidCount > 0)
                    Text('$unpaidCount DUE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: kWarning)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ==================== WEB PAGINATION BAR ====================

  Widget _buildWebPaginationBar(AccountsPayableController controller, BuildContext context) {
    return Obx(() => Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${controller.bills.length} bills',
            style: TextStyle(fontSize: 13, color: kSubText),
          ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Previous', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Page 1',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text('Next', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  // ==================== DIALOGS ====================

  void _showAddBillDialog(AccountsPayableController controller, BuildContext ctx) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    String selectedSupplierId = '';  // ✅ Changed
    DateTime selectedDate = DateTime.now();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));
    List<Map<String, dynamic>> items = [{'description': '', 'quantity': 1, 'unitPrice': 0.0}];
    double discount = 0;
    String notes = '';

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculateTotal() {
            double subtotal = items.fold(0.0, (s, i) => s + (i['quantity'] ?? 1) * (i['unitPrice'] ?? 0.0));
            return subtotal - discount;
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 12 : 16)),
            child: Container(
              width: isWeb ? 560 : double.infinity,
              constraints: BoxConstraints(maxHeight: isWeb ? 680 : 600),
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Add Bill', style: TextStyle(fontSize: isWeb ? 16 : 18, fontWeight: FontWeight.w700, color: kText)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: isWeb ? 20 : 16, color: Colors.grey.withOpacity(0.2)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Supplier dropdown
                            DropdownButtonFormField<String>(
                              value: selectedSupplierId.isEmpty ? null : selectedSupplierId,
                              decoration: InputDecoration(
                                labelText: 'Supplier *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                                labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: kSubText),
                              ),
                              style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                              hint: Text('Select supplier', style: TextStyle(fontSize: 12, color: kSubText)),
                              items: controller.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => selectedSupplierId = v!,
                              validator: (v) => v == null ? 'Supplier required' : null,
                            ),
                            const SizedBox(height: 12),
                            // Dates
                            if (isWeb)
                              Row(children: [
                                Expanded(child: _buildDatePickerField('Bill Date', selectedDate, (d) => setState(() => selectedDate = d), isWeb, context)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDatePickerField('Due Date', selectedDueDate, (d) => setState(() => selectedDueDate = d), isWeb, context)),
                              ])
                            else ...[
                              _buildDatePickerField('Bill Date', selectedDate, (d) => setState(() => selectedDate = d), isWeb, context),
                              const SizedBox(height: 12),
                              _buildDatePickerField('Due Date', selectedDueDate, (d) => setState(() => selectedDueDate = d), isWeb, context),
                            ],
                            const SizedBox(height: 12),
                            // Items
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Items', style: TextStyle(fontSize: isWeb ? 13 : 12, fontWeight: FontWeight.w600, color: kText)),
                                TextButton.icon(
                                  onPressed: () => setState(() => items.add({'description': '', 'quantity': 1, 'unitPrice': 0.0})),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...items.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _formField('Description *', '', (v) => item['description'] = v, initialValue: item['description'], isWeb: isWeb)),
                                        if (items.length > 1) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => setState(() => items.removeAt(idx)),
                                            child: Icon(Icons.delete, size: 18, color: kDanger),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: _formField('Qty', '1', (v) => item['quantity'] = int.tryParse(v) ?? 1, initialValue: item['quantity'].toString(), keyboardType: TextInputType.number, isWeb: isWeb)),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 2, child: _formField('Unit Price *', '0.00', (v) => item['unitPrice'] = double.tryParse(v) ?? 0, initialValue: item['unitPrice'].toString(), keyboardType: TextInputType.number, prefixText: CurrencyUtils.prefix, isWeb: isWeb)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 12),
                            _formField('Discount', '0.00', (v) => discount = double.tryParse(v) ?? 0, prefixText: CurrencyUtils.prefix, keyboardType: TextInputType.number, isWeb: isWeb),
                            const SizedBox(height: 12),
                            _formField('Notes', '', (v) => notes = v, isWeb: isWeb),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: kDanger.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kDanger.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kText)),
                                  Text(_formatAmount(calculateTotal()), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kDanger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: isWeb ? 13 : 14, color: kSubText)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: controller.isProcessing.value
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate() && selectedSupplierId.isNotEmpty) {
                                    Navigator.pop(context);
                                    await controller.createBill({
                                      'supplierId': selectedSupplierId,  // ✅ Changed
                                      'date': selectedDate.toIso8601String(),
                                      'dueDate': selectedDueDate.toIso8601String(),
                                      'items': items.map((i) => ({
                                        'description': i['description'],
                                        'quantity': i['quantity'],
                                        'unitPrice': i['unitPrice'],
                                        'taxRate': 0.0,
                                      })).toList(),
                                      'discount': discount,
                                      'notes': notes,
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: controller.isProcessing.value
                              ? SizedBox(width: 20, height: 20, child: LoadingAnimationWidget.waveDots(color: Colors.black87, size: 20))
                              : Text('Create Bill', style: TextStyle(fontSize: isWeb ? 13 : 14, color: Colors.black87)),
                        )),
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

  void _recordBillPayment(Bill bill, AccountsPayableController controller, BuildContext ctx) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final formKey = GlobalKey<FormState>();
    double amount = bill.outstanding;
    DateTime paymentDate = DateTime.now();
    String paymentMethod = 'Bank Transfer';
    String reference = '';
    String selectedBankAccountId = '';

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.payment, size: 18, color: kSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay Bill', style: TextStyle(fontSize: isWeb ? 16 : 14, fontWeight: FontWeight.w800)),
                    Text(bill.billNumber, style: TextStyle(fontSize: 12, color: kSubText)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: isWeb ? 400 : 280,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          _buildDetailRow('Supplier', bill.supplierName, isWeb),
                          _buildDetailRow('Bill Date', DateFormat('dd MMM yyyy').format(bill.date), isWeb),
                          _buildDetailRow('Due Date', DateFormat('dd MMM yyyy').format(bill.dueDate), isWeb),
                          _buildDetailRow('Total', _formatAmount(bill.totalAmount), isWeb),
                          _buildDetailRow('Outstanding', _formatAmount(bill.outstanding), isWeb, valueColor: kDanger),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: amount.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount *',
                        prefixText: CurrencyUtils.prefix,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                      onChanged: (v) => amount = double.tryParse(v) ?? 0,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Amount required';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Invalid amount';
                        if (val > bill.outstanding) return 'Exceeds outstanding';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDatePickerField('Payment Date', paymentDate, (d) => setState(() => paymentDate = d), isWeb, context),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                      items: const [
                        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      ],
                      onChanged: (v) => setState(() => paymentMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    _formField('Reference Number', '', (v) => reference = v, isWeb: isWeb),
                    if (paymentMethod == 'Bank Transfer') ...[
                      const SizedBox(height: 12),
                      Obx(() => DropdownButtonFormField<String>(
                        value: selectedBankAccountId.isEmpty ? null : selectedBankAccountId,
                        decoration: InputDecoration(
                          labelText: 'Bank Account *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                        hint: Text('Select account', style: TextStyle(fontSize: 12, color: kSubText)),
                        items: controller.bankAccounts.map((acc) => DropdownMenuItem<String>(
                          value: acc['_id']?.toString(),
                          child: Text(acc['accountName'], overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedBankAccountId = v ?? ''),
                        validator: (v) => v == null ? 'Bank account required' : null,
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontSize: isWeb ? 14 : 12, color: kSubText)),
            ),
            Obx(() => ElevatedButton(
              onPressed: controller.isProcessing.value
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        if (paymentMethod == 'Bank Transfer' && selectedBankAccountId.isEmpty) {
                          AppSnackbar.error(Colors.red, 'Error', 'Please select a bank account');
                          return;
                        }
                        Navigator.pop(context);
                        controller.recordPayment(
                          supplierId: bill.supplierId,  // ✅ Changed
                          billId: bill.id,
                          amount: amount,
                          paymentDate: paymentDate,
                          paymentMethod: paymentMethod,
                          reference: reference,
                          bankAccountId: selectedBankAccountId,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccess,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: controller.isProcessing.value
                  ? SizedBox(width: 20, height: 20, child: LoadingAnimationWidget.waveDots(color: Colors.black87, size: 20))
                  : Text('Record Payment', style: TextStyle(fontSize: isWeb ? 14 : 12, color: Colors.black87)),
            )),
          ],
        ),
      ),
    );
  }

  void _showBillDetails(Bill bill, AccountsPayableController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final statusColor = bill.status == 'Paid'
        ? kSuccess
        : bill.status == 'Overdue'
            ? kDanger
            : kWarning;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 12 : 16)),
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
                    width: isWeb ? 44 : 50, height: isWeb ? 44 : 50,
                    decoration: BoxDecoration(color: kDanger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.receipt_long, size: isWeb ? 22 : 28, color: kDanger),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bill.billNumber, style: TextStyle(fontSize: isWeb ? 16 : 18, fontWeight: FontWeight.w700, color: kText)),
                        Text('${bill.supplierName} • ${DateFormat('dd MMM yyyy').format(bill.date)}', style: TextStyle(fontSize: isWeb ? 12 : 13, color: kSubText)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(bill.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
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
                      _buildDetailRow('Supplier', bill.supplierName, isWeb),
                      _buildDetailRow('Bill Date', DateFormat('dd MMM yyyy').format(bill.date), isWeb),
                      _buildDetailRow('Due Date', DateFormat('dd MMM yyyy').format(bill.dueDate), isWeb,
                          valueColor: bill.isOverdue ? kDanger : null),
                      _buildDetailRow('Subtotal', _formatAmount(bill.subtotal), isWeb),
                      if (bill.taxTotal > 0) _buildDetailRow('Tax', _formatAmount(bill.taxTotal), isWeb),
                      if (bill.discount > 0) _buildDetailRow('Discount', '-${_formatAmount(bill.discount)}', isWeb),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow('Total Amount', _formatAmount(bill.totalAmount), isWeb),
                      _buildDetailRow('Paid Amount', _formatAmount(bill.paidAmount), isWeb, valueColor: kSuccess),
                      _buildDetailRow('Outstanding', _formatAmount(bill.outstanding), isWeb, valueColor: kDanger),
                      if (bill.notes.isNotEmpty) ...[
                        Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                        _buildDetailRow('Notes', bill.notes, isWeb),
                      ],
                      if (bill.items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Items', style: TextStyle(fontSize: isWeb ? 13 : 14, fontWeight: FontWeight.w600, color: kText)),
                        ),
                        const SizedBox(height: 8),
                        ...bill.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item.description, style: TextStyle(fontSize: isWeb ? 13 : 12, fontWeight: FontWeight.w600, color: kText)),
                                  Text('${item.quantity} × ${_formatAmount(item.unitPrice)}', style: TextStyle(fontSize: 10, color: kSubText)),
                                ]),
                              ),
                              Text(_formatAmount(item.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger)),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (bill.status != 'Paid') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(ctx); _recordBillPayment(bill, controller, ctx); },
                        icon: const Icon(Icons.payment, size: 16, color: Colors.black87),
                        label: const Text('Pay Now', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccess,
                          padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 10 : 12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text('Close', style: TextStyle(fontSize: isWeb ? 13 : 14, color: kSubText)),
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

  void _showFilterDialog(AccountsPayableController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Filter Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range, color: kPrimary),
              title: const Text('Select Date Range', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: controller.startDate.value != null && controller.endDate.value != null
                      ? DateTimeRange(start: controller.startDate.value!, end: controller.endDate.value!)
                      : null,
                );
                if (range != null) {
                  controller.setDateRange(range.start, range.end);
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: kDanger),
              title: const Text('Clear All Filters', style: TextStyle(fontSize: 14)),
              onTap: () {
                controller.clearFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRowActions(AccountsPayableController controller, Bill bill, BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          onTap: () => _showBillDetails(bill, controller, context),
          child: ListTile(
            leading: Icon(Icons.remove_red_eye, size: 18, color: kPrimary),
            title: const Text('View Details', style: TextStyle(fontSize: 13)),
            dense: true,
          ),
        ),
        if (bill.status != 'Paid')
          PopupMenuItem(
            onTap: () => _recordBillPayment(bill, controller, context),
            child: ListTile(
              leading: Icon(Icons.payment, size: 18, color: kSuccess),
              title: const Text('Record Payment', style: TextStyle(fontSize: 13)),
              dense: true,
            ),
          ),
      ],
      elevation: 4,
    );
  }

  // ==================== FORM HELPERS ====================

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String initialValue = '',
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    required bool isWeb,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: isWeb ? 12 : 11, color: kSubText),
      ),
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDatePickerField(String label, DateTime date, void Function(DateTime) onChanged, bool isWeb, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
            Icon(Icons.calendar_today, size: isWeb ? 16 : 14, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText)),
                Text(DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(fontSize: isWeb ? 13 : 12, fontWeight: FontWeight.w600, color: kText)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isWeb, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWeb ? 110 : 100,
            child: Text(label, style: TextStyle(fontSize: isWeb ? 12 : 13, color: kSubText, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isWeb ? 12 : 13, fontWeight: FontWeight.w600, color: valueColor ?? kText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}