import 'package:LedgerPro_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/Invoice/controller/invoice_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class InvoicesScreen extends StatelessWidget {
  final String? customerId;
  const InvoicesScreen({super.key, this.customerId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvoiceController());
    if (customerId != null && customerId!.isNotEmpty) {
      controller.filterByCustomer(customerId!);
    }

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, InvoiceController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.invoices.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileInvoicesList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateInvoiceDialog(context, controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, InvoiceController controller) {
    return AppBar(
      title: const Text(
        'Invoices',
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
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
          onPressed: () => _showFilterDialog(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportInvoices(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(InvoiceController controller, BuildContext context) {
    final filters = ['All', 'Unpaid', 'Paid', 'Overdue', 'Partial'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: filters.map((f) {
            final isSelected = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (_) => controller.changeFilter(isSelected ? 'All' : f),
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

  Widget _buildMobileSummaryCards(InvoiceController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildMobileSummaryCard('Total Invoices', controller.invoices.length.toString(), kPrimary, Icons.receipt_long_outlined, isNumber: true),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Total Amount', _formatAmount(controller.totalAmount.value), kPrimary, Icons.attach_money),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Amount Paid', _formatAmount(controller.totalPaid.value), kSuccess, Icons.check_circle_outline),
            const SizedBox(width: 12),
            _buildMobileSummaryCard('Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.pending_outlined),
          ],
        )),
      ),
    );
  }

  Widget _buildMobileSummaryCard(String title, String value, Color color, IconData icon, {bool isNumber = false}) {
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
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildMobileInvoicesList(InvoiceController controller, BuildContext context) {
    return Obx(() {
      final invoices = controller.invoices;
      if (invoices.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No invoices found', style: TextStyle(fontSize: 16, color: kSubText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showCreateInvoiceDialog(context, controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Create Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileInvoiceCard(invoices[index], controller, context),
        ),
      );
    });
  }

  Widget _buildMobileInvoiceCard(Invoice invoice, InvoiceController controller, BuildContext context) {
    final statusColor = _statusColor(invoice.status, invoice.isOverdue);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice, controller, context),
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
                      child: Icon(Icons.receipt, size: 20, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invoice.invoiceNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          const SizedBox(height: 2),
                          Text(invoice.customerName, style: TextStyle(fontSize: 11, color: kSubText), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(invoice.status, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatAmount(invoice.totalAmount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                        const SizedBox(height: 2),
                        if (invoice.outstanding > 0)
                          Text('Due: ${_formatAmount(invoice.outstanding)}', style: TextStyle(fontSize: 10, color: kDanger)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: kSubText),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(invoice.date), style: TextStyle(fontSize: 10, color: kSubText)),
                    const SizedBox(width: 12),
                    Icon(Icons.event_busy, size: 11, color: invoice.isOverdue ? kDanger : kSubText),
                    const SizedBox(width: 4),
                    Text('Due ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                        style: TextStyle(fontSize: 10, color: invoice.isOverdue ? kDanger : kSubText)),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showInvoiceDetails(invoice, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text('View', style: TextStyle(fontSize: 11, color: kText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    if (invoice.status != 'Paid') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _recordPayment(invoice, controller, context),
                          icon: const Icon(Icons.payment, size: 14, color: Colors.white),
                          label: const Text('Pay', style: TextStyle(fontSize: 11, color: Colors.white)),
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

  Widget _buildWebLayout(BuildContext context, InvoiceController controller) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.invoices.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebInvoicesTable(controller, context)),
                  _buildWebPaginationBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(BuildContext context, InvoiceController controller) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Invoices',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              // controller: controller.searchController,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search invoice, customer…',
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
            onPressed: () => _showFilterDialog(controller, context),
            icon: const Icon(Icons.filter_alt_outlined, size: 15, color: Colors.black87),
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
            onPressed: () => controller.exportInvoices(),
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
            onPressed: () => _showCreateInvoiceDialog(context, controller, context),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text('New Invoice', style: TextStyle(fontSize: 13, color: Colors.black87)),
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

  Widget _buildWebKpiStrip(InvoiceController controller) {
    return Obx(() => Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          _buildWebKpiTile('Total Invoices', controller.invoices.length.toString(), kPrimary, Icons.receipt_long_outlined),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Total Amount', _formatAmount(controller.totalAmount.value), kPrimary, Icons.attach_money),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Amount Paid', _formatAmount(controller.totalPaid.value), kSuccess, Icons.check_circle_outline),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Outstanding', _formatAmount(controller.totalOutstanding.value), kDanger, Icons.pending_outlined),
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

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(InvoiceController controller, BuildContext context) {
    final filters = ['All', 'Unpaid', 'Paid', 'Overdue', 'Partial'];
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
      child: Obx(() => Row(
        children: filters.map((f) {
          final isSelected = controller.selectedFilter.value == f;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => controller.changeFilter(f),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                ),
                child: Text(
                  f,
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
    );
  }

  // ==================== WEB TABLE ====================

  Widget _buildWebInvoicesTable(InvoiceController controller, BuildContext context) {
    return Obx(() {
      final invoices = controller.invoices;

      if (invoices.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No invoices found', style: TextStyle(fontSize: 15, color: kSubText)),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () => _showCreateInvoiceDialog(context, controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('+ New Invoice', style: TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Header
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _tableHeaderCell('Invoice #')),
                Expanded(flex: 3, child: _tableHeaderCell('Customer')),
                Expanded(flex: 2, child: _tableHeaderCell('Issue Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Due Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Amount', align: TextAlign.right)),
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
              itemCount: invoices.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTableRow(invoices[index], controller, context),
            ),
          ),
          if (invoices.isNotEmpty) _buildWebTableFooter(invoices, controller),
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

  Widget _buildWebTableRow(Invoice invoice, InvoiceController controller, BuildContext context) {
    final statusColor = _statusColor(invoice.status, invoice.isOverdue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInvoiceDetails(invoice, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Icon
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.receipt, size: 14, color: statusColor),
              ),
              const SizedBox(width: 4),
              // Invoice #
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(invoice.invoiceNumber,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              // Customer
              Expanded(
                flex: 3,
                child: Text(invoice.customerName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText),
                    overflow: TextOverflow.ellipsis),
              ),
              // Issue Date
              Expanded(
                flex: 2,
                child: Text(DateFormat('dd MMM yyyy').format(invoice.date),
                    style: TextStyle(fontSize: 12, color: kSubText)),
              ),
              // Due Date
              Expanded(
                flex: 2,
                child: Text(DateFormat('dd MMM yyyy').format(invoice.dueDate),
                    style: TextStyle(fontSize: 12, color: invoice.isOverdue ? kDanger : kSubText,
                        fontWeight: invoice.isOverdue ? FontWeight.w600 : FontWeight.normal)),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Text(_formatAmount(invoice.totalAmount),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
              ),
              // Paid
              Expanded(
                flex: 2,
                child: Text(_formatAmount(invoice.paidAmount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSuccess)),
              ),
              // Outstanding
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: invoice.outstanding > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_formatAmount(invoice.outstanding),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger)),
                        )
                      : Text(_formatAmount(0), style: const TextStyle(fontSize: 13, color: kSuccess, fontWeight: FontWeight.w600)),
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                    child: Text(
                      invoice.status == 'Paid' ? 'PAID' :
                      invoice.status == 'Unpaid' ? 'UNPD' :
                      invoice.status == 'Overdue' ? 'OVRD' : 'PART',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(Icons.remove_red_eye_outlined, kSubText,
                        () => _showInvoiceDetails(invoice, controller, context)),
                    const SizedBox(width: 4),
                  
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
      child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 15, color: color)),
    );
  }

  Widget _buildWebTableFooter(List<Invoice> invoices, InvoiceController controller) {
    final paidCount = invoices.where((i) => i.status == 'Paid').length;
    final unpaidCount = invoices.where((i) => i.status == 'Unpaid').length;
    final overdueCount = invoices.where((i) => i.isOverdue).length;

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
            flex: 2,
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
            child: Obx(() => Text(
              _formatAmount(controller.totalAmount.value),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            )),
          ),
          Expanded(
            flex: 2,
            child: Obx(() => Text(
              _formatAmount(controller.totalPaid.value),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSuccess),
            )),
          ),
          Expanded(
            flex: 2,
            child: Obx(() => Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _formatAmount(controller.totalOutstanding.value),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDanger),
                ),
              ),
            )),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (paidCount > 0) Text('$paidCount PAID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9, color: kSuccess)),
                  if (unpaidCount > 0) Text('$unpaidCount UNPD', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: kWarning)),
                  if (overdueCount > 0) Text('$overdueCount OVRD', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: kDanger)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ==================== PAGINATION ====================

  Widget _buildWebPaginationBar(InvoiceController controller) {
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
            'Showing ${controller.invoices.length} of ${controller.invoices.length} invoices',
            style: TextStyle(fontSize: 13, color: kSubText),
          ),
          Row(
            children: [
              _paginationBtn(Icons.chevron_left, 'Previous', false, null),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Page 1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary)),
              ),
              const SizedBox(width: 12),
              _paginationBtn(Icons.chevron_right, 'Next', false, null),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _paginationBtn(IconData icon, String label, bool enabled, VoidCallback? onTap) {
    final color = enabled ? kPrimary : Colors.grey;
    final isNext = label == 'Next';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? kPrimary : Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (!isNext) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              if (isNext) ...[const SizedBox(width: 4), Icon(icon, size: 18, color: color)],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== INVOICE DETAIL DIALOG (Professional Print View) ====================

  void _showInvoiceDetails(Invoice invoice, InvoiceController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    showDialog(
      context: Get.context!,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
        insetPadding: EdgeInsets.symmetric(horizontal: isWeb ? 120 : 16, vertical: isWeb ? 40 : 20),
        child: Container(
          width: isWeb ? 600 : double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * (isWeb ? 0.88 : 0.92)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog top bar (matches fixed assets style)
              Container(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 18, vertical: isWeb ? 16 : 12),
                decoration: const BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INVOICE', style: TextStyle(fontSize: isWeb ? 10 : 9, color: Colors.white60, letterSpacing: 2, fontWeight: FontWeight.w600)),
                          Text(invoice.invoiceNumber, style: TextStyle(fontSize: isWeb ? 16 : 14, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                    _statusBadgeWhite(invoice.status, invoice.isOverdue),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Professional Invoice Body ──
              Expanded(
                child: SingleChildScrollView(
                  child: _buildProfessionalInvoiceView(invoice, isWeb),
                ),
              ),

              // Footer actions
              Container(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: isWeb ? 14 : 12),
                decoration: BoxDecoration(
                  color: kCardBg,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.12))),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () { Navigator.pop(ctx); _exportSingleInvoice(invoice, controller, context); },
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: Text('Export', style: TextStyle(fontSize: isWeb ? 13 : 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kWarning,
                          side: BorderSide(color: kWarning),
                          padding: EdgeInsets.symmetric(vertical: isWeb ? 12 : 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (invoice.status != 'Paid') ...[
                      const SizedBox(width: 12),
                                       ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Professional invoice exactly matching the image: logo top-right, From/For,
  /// invoice meta table, dark-header items table, subtotal/tax/total, balance due, notes.
  Widget _buildProfessionalInvoiceView(Invoice invoice, bool isWeb) {
    final statusColor = _statusColor(invoice.status, invoice.isOverdue);
    final double subtotal = invoice.subtotal;
    final double tax = invoice.taxTotal;
    final double discount = invoice.discount;
    final double total = invoice.totalAmount;
    final double paid = invoice.paidAmount;
    final double balanceDue = invoice.outstanding;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isWeb ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Invoice title + Company Logo ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Invoice',
                  style: TextStyle(
                    fontSize: isWeb ? 28 : 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                width: isWeb ? 100 : 80,
                height: isWeb ? 80 : 64,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isWeb ? 36 : 28,
                      height: isWeb ? 36 : 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimary),
                      child: const Icon(Icons.business, color: Colors.white, size: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('Company\nLogo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isWeb ? 10 : 9, color: Colors.grey.shade500, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 28 : 20),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: isWeb ? 20 : 14),

          // ── Row 2: From / For ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From', style: TextStyle(fontSize: isWeb ? 11 : 10, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('Your Business Name',
                        style: TextStyle(fontSize: isWeb ? 15 : 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text('your@email.com', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade600)),
                    Text('Your Address', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade600)),
                    Text('P: (123) 456 7890', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              SizedBox(width: isWeb ? 24 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('For', style: TextStyle(fontSize: isWeb ? 11 : 10, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(invoice.customerName,
                        style: TextStyle(fontSize: isWeb ? 15 : 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text('client@email.com', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade600)),
                    Text('Client Address', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 20 : 14),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: isWeb ? 14 : 10),

          // ── Invoice Meta (Number / Date / Terms / Due) ────────────
          Column(
            children: [
              _invoiceMetaRow('Number', invoice.invoiceNumber, isWeb),
              _invoiceMetaRow('Date', DateFormat('dd MMM yyyy').format(invoice.date), isWeb),
              _invoiceMetaRow('Terms', 'Net 30', isWeb),
              _invoiceMetaRow('Due', DateFormat('dd MMM yyyy').format(invoice.dueDate), isWeb,
                  valueColor: invoice.isOverdue ? kDanger : Colors.black87),
            ],
          ),

          SizedBox(height: isWeb ? 20 : 14),

          // ── Items Table ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 14 : 10, vertical: isWeb ? 10 : 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D3D3D),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('Description', style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      SizedBox(
                        width: isWeb ? 70 : 55,
                        child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      SizedBox(
                        width: isWeb ? 44 : 36,
                        child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      SizedBox(
                        width: isWeb ? 80 : 65,
                        child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                // Items
                ...invoice.items.asMap().entries.map((entry) {
                  final isEven = entry.key.isEven;
                  final item = entry.value;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 14 : 10, vertical: isWeb ? 10 : 8),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF9F9F9),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description,
                                  style: TextStyle(fontSize: isWeb ? 13 : 11, color: Colors.black87, fontWeight: FontWeight.w500)),
                              if (item.taxRate > 0)
                                Text('Tax: ${item.taxRate}%',
                                    style: TextStyle(fontSize: isWeb ? 11 : 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isWeb ? 70 : 55,
                          child: Text(_formatAmount(item.unitPrice),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black87)),
                        ),
                        SizedBox(
                          width: isWeb ? 44 : 36,
                          child: Text(item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black87)),
                        ),
                        SizedBox(
                          width: isWeb ? 80 : 65,
                          child: Text(_formatAmount(item.amount),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          SizedBox(height: isWeb ? 16 : 12),

          // ── Totals (right-aligned) ────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: isWeb ? 260 : 200,
              child: Column(
                children: [
                  _totalLineRow('Subtotal', _formatAmount(subtotal), isWeb, isBold: false),
                  if (tax > 0) _totalLineRow('Tax (${_getTaxPercent(invoice)}%)', _formatAmount(tax), isWeb, isBold: false),
                  if (discount > 0) _totalLineRow('Discount', '- ${_formatAmount(discount)}', isWeb, isBold: false, valueColor: kDanger),
                  Divider(color: Colors.grey.shade300, height: isWeb ? 16 : 12),
                  _totalLineRow('Total', _formatAmount(total), isWeb, isBold: true),
                  if (paid > 0) _totalLineRow('Amount Paid', _formatAmount(paid), isWeb, isBold: false, valueColor: kSuccess),
                  SizedBox(height: isWeb ? 10 : 8),
                  // Balance Due highlight
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 14 : 10, vertical: isWeb ? 10 : 8),
                    decoration: BoxDecoration(
                      color: balanceDue > 0 ? const Color(0xFFF5F5F5) : kSuccess.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Balance Due',
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 12,
                              fontWeight: FontWeight.w800,
                              color: balanceDue > 0 ? Colors.black87 : kSuccess,
                            )),
                        Text(_formatAmount(balanceDue),
                            style: TextStyle(
                              fontSize: isWeb ? 16 : 14,
                              fontWeight: FontWeight.w900,
                              color: balanceDue > 0 ? Colors.black87 : kSuccess,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Notes ────────────────────────────────────────────────
          if (invoice.notes.isNotEmpty) ...[
            SizedBox(height: isWeb ? 20 : 14),
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: isWeb ? 12 : 8),
            Text(invoice.notes,
                style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ] else ...[
            SizedBox(height: isWeb ? 20 : 14),
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: isWeb ? 12 : 8),
            Text('Notes, any relevant info, terms, payment instructions, e.t.c.',
                style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _invoiceMetaRow(String label, String value, bool isWeb, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 4 : 3),
      child: Row(
        children: [
          SizedBox(
            width: isWeb ? 60 : 54,
            child: Text(label, style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey.shade500)),
          ),
          Text(value, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _totalLineRow(String label, String value, bool isWeb, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWeb ? 3 : 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isWeb ? 13 : 11, color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: isWeb ? 13 : 11, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _statusBadgeWhite(String status, bool isOverdue) {
    final color = _statusColor(status, isOverdue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(status, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  String _getTaxPercent(Invoice invoice) {
    if (invoice.items.isEmpty || invoice.subtotal == 0) return '0';
    final rate = invoice.items.first.taxRate;
    return rate.toStringAsFixed(0);
  }

  // ==================== CREATE INVOICE DIALOG ====================

  void _showCreateInvoiceDialog(BuildContext context, InvoiceController controller, BuildContext mainContext) {
    final isWeb = ResponsiveUtils.isWeb(mainContext);

    String? selectedCustomerId;
    DateTime issueDate = DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    String notes = '';
    double discount = 0;

    final items = <Map<String, dynamic>>[
      {'description': '', 'quantity': 1, 'unitPrice': 0.0, 'taxRate': 0.0},
    ];
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: Get.context!,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          double subtotal = 0;
          double taxTotal = 0;
          for (final item in items) {
            final qty = (item['quantity'] as num).toDouble();
            final price = (item['unitPrice'] as num).toDouble();
            final tax = (item['taxRate'] as num).toDouble();
            final amt = qty * price;
            subtotal += amt;
            taxTotal += amt * tax / 100;
          }
          final disc = double.tryParse(discountController.text) ?? 0;
          final total = (subtotal + taxTotal - disc).clamp(0, double.infinity);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
            insetPadding: EdgeInsets.symmetric(horizontal: isWeb ? 120 : 16, vertical: isWeb ? 40 : 20),
            child: Container(
              width: isWeb ? 600 : double.infinity,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (matches top bar style)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 18, vertical: isWeb ? 16 : 14),
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create New Invoice', style: TextStyle(fontSize: isWeb ? 16 : 14, fontWeight: FontWeight.w800, color: Colors.black45)),
                              Text('Fill in the details below', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black45)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isWeb ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dialogSectionLabel('Customer & Dates', isWeb),
                          const SizedBox(height: 10),
                          _dialogLabel('Customer *', isWeb),
                          const SizedBox(height: 4),
                          Container(
                            height: isWeb ? 44 : 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedCustomerId,
                                hint: Text('Select customer...', style: TextStyle(fontSize: isWeb ? 13 : 12, color: kSubText)),
                                style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                                items: controller.customers.map((c) => DropdownMenuItem(
                                  value: c['_id']?.toString() ?? '',
                                  child: Text(c['name'] ?? '', overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setState(() => selectedCustomerId = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dialogLabel('Issue Date *', isWeb),
                                  const SizedBox(height: 4),
                                  _datePicker(context: ctx, date: issueDate, isWeb: isWeb, onChanged: (d) => setState(() => issueDate = d)),
                                ],
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _dialogLabel('Due Date *', isWeb),
                                  const SizedBox(height: 4),
                                  _datePicker(context: ctx, date: dueDate, isWeb: isWeb, onChanged: (d) => setState(() => dueDate = d)),
                                ],
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              _dialogSectionLabel('Items / Services', isWeb),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text('${items.length} item${items.length > 1 ? 's' : ''}',
                                    style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(flex: 4, child: Text('Description', style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText, fontWeight: FontWeight.w600))),
                              SizedBox(width: isWeb ? 56 : 44, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 6),
                              SizedBox(width: isWeb ? 90 : 74, child: Text('Unit Price', textAlign: TextAlign.right, style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 6),
                              SizedBox(width: isWeb ? 60 : 50, child: Text('Tax %', textAlign: TextAlign.right, style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 28),
                            ],
                          ),
                          const SizedBox(height: 6),

                          ...items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            final descCtrl = TextEditingController(text: item['description']);
                            final qtyCtrl = TextEditingController(text: item['quantity'].toString());
                            final priceCtrl = TextEditingController(text: item['unitPrice'].toString());
                            final taxCtrl = TextEditingController(text: item['taxRate'].toString());

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(flex: 4, child: _dialogInput(controller: descCtrl, hint: 'Description...', isWeb: isWeb, onChanged: (v) => item['description'] = v)),
                                  const SizedBox(width: 6),
                                  SizedBox(width: isWeb ? 56 : 44, child: _dialogInput(controller: qtyCtrl, hint: '1', isWeb: isWeb, keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (v) { item['quantity'] = int.tryParse(v) ?? 1; setState(() {}); })),
                                  const SizedBox(width: 6),
                                  SizedBox(width: isWeb ? 90 : 74, child: _dialogInput(controller: priceCtrl, hint: '0.00', isWeb: isWeb, keyboardType: TextInputType.number, textAlign: TextAlign.right, onChanged: (v) { item['unitPrice'] = double.tryParse(v) ?? 0; setState(() {}); })),
                                  const SizedBox(width: 6),
                                  SizedBox(width: isWeb ? 60 : 50, child: _dialogInput(controller: taxCtrl, hint: '0', isWeb: isWeb, keyboardType: TextInputType.number, textAlign: TextAlign.right, onChanged: (v) { item['taxRate'] = double.tryParse(v) ?? 0; setState(() {}); })),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: items.length > 1 ? () => setState(() => items.removeAt(i)) : null,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: items.length > 1 ? kDanger : kSubText.withOpacity(0.3))),
                                  ),
                                ],
                              ),
                            );
                          }),

                          InkWell(
                            onTap: () => setState(() => items.add({'description': '', 'quantity': 1, 'unitPrice': 0.0, 'taxRate': 0.0})),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: kPrimary.withOpacity(0.4), style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 14, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text('Add Item', style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.black45, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Totals
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                            child: Column(
                              children: [
                                _totalsRow('Subtotal', _formatAmount(subtotal), isWeb),
                                const SizedBox(height: 6),
                                _totalsRow('Tax', _formatAmount(taxTotal), isWeb, color: kSubText),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Discount', style: TextStyle(fontSize: isWeb ? 13 : 11, color: kSubText)),
                                    SizedBox(
                                      width: 100,
                                      child: _dialogInput(controller: discountController, hint: '0.00', isWeb: isWeb, keyboardType: TextInputType.number, textAlign: TextAlign.right, onChanged: (_) => setState(() {})),
                                    ),
                                  ],
                                ),
                                Divider(color: kBorder, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: TextStyle(fontSize: isWeb ? 15 : 13, fontWeight: FontWeight.w800, color: kText)),
                                    Text(_formatAmount(total.toDouble()), style: TextStyle(fontSize: isWeb ? 15 : 13, fontWeight: FontWeight.w800, color: kPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          _dialogLabel('Notes (optional)', isWeb),
                          const SizedBox(height: 4),
                          TextField(
                            maxLines: 3,
                            style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
                            decoration: InputDecoration(
                              hintText: 'Payment terms, special instructions...',
                              hintStyle: TextStyle(fontSize: isWeb ? 13 : 12, color: kSubText),
                              filled: true, fillColor: kBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (v) => notes = v,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: isWeb ? 16 : 12),
                    decoration: BoxDecoration(color: kCardBg, border: Border(top: BorderSide(color: kBorder)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: isWeb ? 14 : 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: Text('Cancel', style: TextStyle(fontSize: isWeb ? 13 : 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Obx(() => ElevatedButton(
                            onPressed: controller.isCreating.value ? null : () async {
                              if (selectedCustomerId == null || selectedCustomerId!.isEmpty) {
                                AppSnackbar.error(kDanger, 'Validation', 'Please select a customer');
                                return;
                              }
                              final validItems = items.where((item) => (item['description'] as String).trim().isNotEmpty).toList();
                              if (validItems.isEmpty) {
                                AppSnackbar.error(kDanger, 'Validation', 'Add at least one item with a description');
                                return;
                              }
                              final invoiceData = {
                                'customerId': selectedCustomerId,
                                'date': issueDate.toIso8601String(),
                                'dueDate': dueDate.toIso8601String(),
                                'discount': double.tryParse(discountController.text) ?? 0,
                                'notes': notes,
                                'items': validItems.map((item) => {'description': item['description'], 'quantity': item['quantity'], 'unitPrice': item['unitPrice'], 'taxRate': item['taxRate']}).toList(),
                              };
                              Navigator.pop(ctx);
                              await controller.createInvoice(invoiceData);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              padding: EdgeInsets.symmetric(vertical: isWeb ? 14 : 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: controller.isCreating.value
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Create Invoice', style: TextStyle(fontSize: isWeb ? 13 : 12, fontWeight: FontWeight.w700, color: Colors.black45)),
                          )),
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
    );
  }

  // ==================== FILTER DIALOG ====================

  void _showFilterDialog(InvoiceController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Invoices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.pending_outlined, color: kPrimary, size: 22),
              title: const Text('Unpaid Only', style: TextStyle(fontSize: 13)),
              trailing: Obx(() => Switch(value: controller.selectedFilter.value == 'Unpaid', onChanged: (v) { Navigator.pop(ctx); controller.changeFilter(v ? 'Unpaid' : 'All'); }, activeColor: kPrimary)),
            ),
            ListTile(
              leading: Icon(Icons.event_busy, color: kDanger, size: 22),
              title: const Text('Overdue Only', style: TextStyle(fontSize: 13)),
              trailing: Obx(() => Switch(value: controller.selectedFilter.value == 'Overdue', onChanged: (v) { Navigator.pop(ctx); controller.changeFilter(v ? 'Overdue' : 'All'); }, activeColor: kDanger)),
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: kSuccess, size: 22),
              title: const Text('Paid Only', style: TextStyle(fontSize: 13)),
              trailing: Obx(() => Switch(value: controller.selectedFilter.value == 'Paid', onChanged: (v) { Navigator.pop(ctx); controller.changeFilter(v ? 'Paid' : 'All'); }, activeColor: kSuccess)),
            ),
            Divider(color: kBorder),
            ListTile(
              leading: const Icon(Icons.clear, size: 22),
              title: const Text('Clear Filters', style: TextStyle(fontSize: 13)),
              onTap: () { Navigator.pop(ctx); controller.clearFilters(); },
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(fontSize: 13)))],
      ),
    );
  }

  // ==================== HELPERS ====================

  void _showMobileSearch(BuildContext context, InvoiceController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Search Invoices', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Invoice #, customer...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
          // onChanged: (v) => controller.searchController.text = v,
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  Color _statusColor(String status, bool isOverdue) {
    if (status == 'Paid') return kSuccess;
    if (isOverdue || status == 'Overdue') return kDanger;
    if (status == 'Partial') return kWarning;
    return kPrimary;
  }

  void _recordPayment(Invoice invoice, InvoiceController controller, BuildContext context) {
    Get.to(() => PaymentsReceivedScreen(
      customerId: invoice.customerId,
      invoiceId: invoice.id,
    ));
  }

  void _exportSingleInvoice(Invoice invoice, InvoiceController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Invoice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format', style: TextStyle(fontSize: 13, color: kSubText)),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.picture_as_pdf, color: kDanger), title: const Text('Export as PDF'),
                onTap: () { Navigator.pop(ctx); controller.exportSingleInvoiceToPdf(invoice); }),
            ListTile(leading: const Icon(Icons.table_chart, color: kSuccess), title: const Text('Export as Excel'),
                onTap: () { Navigator.pop(ctx); controller.exportSingleInvoiceToExcel(invoice); }),
          ],
        ),
      ),
    );
  }

  static String _formatAmount(double amount) => CurrencyUtils.format(amount);

  // ── Dialog Helpers ────────────────────────────────────────────────

  Widget _dialogSectionLabel(String text, bool isWeb) {
    return Text(text, style: TextStyle(fontSize: isWeb ? 14 : 13, fontWeight: FontWeight.w700, color: kText));
  }

  Widget _dialogLabel(String text, bool isWeb) {
    return Text(text, style: TextStyle(fontSize: isWeb ? 12 : 11, fontWeight: FontWeight.w600, color: kSubText));
  }

  Widget _dialogInput({
    required TextEditingController controller,
    required String hint,
    required bool isWeb,
    TextInputType keyboardType = TextInputType.text,
    TextAlign textAlign = TextAlign.left,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: isWeb ? 13 : 12, color: kSubText),
        filled: true, fillColor: kBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimary)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _datePicker({
    required BuildContext context,
    required DateTime date,
    required bool isWeb,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: isWeb ? 44 : 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: kSubText),
            const SizedBox(width: 6),
            Text(DateFormat('dd MMM yyyy').format(date), style: TextStyle(fontSize: isWeb ? 13 : 12, color: kText)),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, String value, bool isWeb, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isWeb ? 13 : 11, color: color ?? kSubText)),
        Text(value, style: TextStyle(fontSize: isWeb ? 13 : 12, fontWeight: FontWeight.w600, color: color ?? kText)),
      ],
    );
  }
}