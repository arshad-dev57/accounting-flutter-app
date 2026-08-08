// lib/core/warehouse/sales_invoice/views/sales_invoice_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/sales_invoice_model.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/salesinvoice_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SalesInvoiceScreen extends StatelessWidget {
  const SalesInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesInvoiceController());

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sales Invoices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: controller.refreshInvoices,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.showCreateWizard.value) {
          return _CreateInvoiceWizard(
            controller: controller,
            onCancel: controller.closeCreateWizard,
          );
        }

        return Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _InvoiceListView(
                  controller: controller,
                  onCreate: controller.openCreateWizard,
                  onView: (item) => _showDetail(context, controller, item),
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreateWizard,
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTopHeader(SalesInvoiceController controller) {
    return Container(
      color: kPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Invoices',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${controller.totalRecords.value} invoices',
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
                Obx(
                  () => Row(
                    children: [
                      _compactKpi(
                        'Draft',
                        controller.stats.value.draft.toString(),
                        Colors.orange.shade200,
                      ),
                      const SizedBox(width: 8),
                      _compactKpi(
                        'Posted',
                        controller.stats.value.posted.toString(),
                        Colors.lightBlue.shade100,
                      ),
                      const SizedBox(width: 8),
                      _compactKpi(
                        'Paid',
                        controller.stats.value.paid.toString(),
                        Colors.green.shade200,
                      ),
                      const SizedBox(width: 8),
                      _compactKpi(
                        'Outstanding',
                        controller.formatCurrency(
                          controller.stats.value.outstanding,
                        ),
                        Colors.purple.shade200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: controller.refreshInvoices,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 17,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              height: 40,
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
              child: _SearchField(controller: controller),
            ),
          ),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _filterChip(
                    'All',
                    controller.selectedFilter.value == 'all',
                    () => controller.filterInvoices('all'),
                  ),
                  _filterChip(
                    'Draft',
                    controller.selectedFilter.value == 'Draft',
                    () => controller.filterInvoices('Draft'),
                  ),
                  _filterChip(
                    'Posted',
                    controller.selectedFilter.value == 'Posted',
                    () => controller.filterInvoices('Posted'),
                  ),
                  _filterChip(
                    'Partial',
                    controller.selectedFilter.value == 'Partially Paid',
                    () => controller.filterInvoices('Partially Paid'),
                  ),
                  _filterChip(
                    'Paid',
                    controller.selectedFilter.value == 'Paid',
                    () => controller.filterInvoices('Paid'),
                  ),
                  _filterChip(
                    'Cancelled',
                    controller.selectedFilter.value == 'Cancelled',
                    () => controller.filterInvoices('Cancelled'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? kPrimary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    SalesInvoiceController controller,
    SalesInvoiceModel item,
  ) {
    controller.selectInvoice(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _InvoiceDetailSheet(
                    controller: controller,
                    invoiceItem: item,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEARCH FIELD
// ═══════════════════════════════════════════════════════════════

class _SearchField extends StatefulWidget {
  final SalesInvoiceController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() {});
        v.isEmpty
            ? widget.controller.clearSearch()
            : widget.controller.searchInvoices(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search invoices...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  widget.controller.clearSearch();
                  setState(() {});
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE INVOICE WIZARD
// ═══════════════════════════════════════════════════════════════

class _CreateInvoiceWizard extends StatelessWidget {
  final SalesInvoiceController controller;
  final VoidCallback onCancel;

  const _CreateInvoiceWizard({
    required this.controller,
    required this.onCancel,
  });

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Create Invoice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _stepIndicator(),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(context),
              ),
            ),
            _buildNavButtons(context),
          ],
        );
      }),
    );
  }

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = controller.wizardStep.value >= i;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (controller.wizardStep.value) {
      case 0:
        return _stepFindOrder(context);
      case 1:
        return _stepSelectItems();
      default:
        return _stepDetails(context);
    }
  }

  Widget _stepFindOrder(BuildContext context) {
    return _section('Step 1: Find Order', [
      TextField(
        controller: controller.orderSearchController,
        decoration: const InputDecoration(
          hintText: 'Search order # or customer',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: controller.searchOrders,
      ),
      if (controller.isSearchingOrders.value)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
      ...controller.orderSearchResults.map(_orderTile),
      if (controller.selectedOrder.value != null)
        _selectedOrderCard(controller.selectedOrder.value!),
    ]);
  }

  Widget _stepSelectItems() {
    return Obx(() {
      return _section('Step 2: Review Items', [
        ...List.generate(controller.lineDrafts.length, (index) {
          final line = controller.lineDrafts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'SKU: ${line.sku} • Qty: ${line.quantity}',
                              style: TextStyle(fontSize: 11, color: kSubText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _format(line.unitPrice),
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: line.quantity.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onChanged: (v) {
                            final q = int.tryParse(v) ?? 1;
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.quantity = q.clamp(1, 9999);
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: line.unitPrice.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onChanged: (v) {
                            final p = double.tryParse(v) ?? 0;
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.unitPrice = p;
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: line.discount.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Disc%',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onChanged: (v) {
                            final d = double.tryParse(v) ?? 0;
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.discount = d.clamp(0, 100);
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: line.taxRate.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tax%',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onChanged: (v) {
                            final t = double.tryParse(v) ?? 0;
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.taxRate = t.clamp(0, 100);
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Line Total: ',
                        style: TextStyle(fontSize: 12, color: kSubText),
                      ),
                      Text(
                        _format(line.lineTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (controller.lineDrafts.isNotEmpty) ...[
          const Divider(),
          _summaryRow('Subtotal', _format(controller.selectedSubtotal)),
          _summaryRow(
            'Discount',
            '-${_format(controller.selectedTotalDiscount)}',
            color: Colors.red,
          ),
          _summaryRow(
            'Tax',
            _format(controller.selectedTotalTax),
            color: Colors.blue,
          ),
          _summaryRow('Total Items', controller.totalItems.toString()),
          const Divider(),
          _summaryRow(
            'Grand Total',
            _format(controller.selectedGrandTotal),
            bold: true,
          ),
        ],
      ]);
    });
  }

  Widget _stepDetails(BuildContext context) {
    return _section('Step 3: Invoice Details', [
      TextField(
        controller: controller.invoiceDateController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Invoice Date *',
          suffixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onTap: () => controller.selectInvoiceDate(context),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.dueDateController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Due Date *',
          suffixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onTap: () => controller.selectDueDate(context),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.paymentTermsController,
        decoration: const InputDecoration(
          labelText: 'Payment Terms',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes (Optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow(
              'Customer',
              controller.selectedOrder.value?['customerName'] ?? '',
            ),
            _summaryRow(
              'Order #',
              controller.selectedOrder.value?['orderNumber'] ?? '',
            ),
            _summaryRow('Items', controller.totalItems.toString()),
            _summaryRow(
              'Grand Total',
              _format(controller.selectedGrandTotal),
              bold: true,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? (bold ? kPrimary : kText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        order['orderNumber'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${order['customerName']} • ${order['items']?.length ?? 0} items',
      ),
      trailing: Icon(Icons.chevron_right, color: kSubText),
      onTap: () => controller.selectOrderForInvoice(order),
    );
  }

  Widget _selectedOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order['orderNumber'] ?? '',
            style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
          ),
          Text(order['customerName'] ?? ''),
          Text('${order['items']?.length ?? 0} items ready for invoicing'),
        ],
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (controller.wizardStep.value > 0)
            OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text('Back', style: TextStyle(color: kSubText)),
            ),
          const Spacer(),
          if (controller.wizardStep.value < 2)
            ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.createInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INVOICE DETAIL SHEET
// ═══════════════════════════════════════════════════════════════

class _InvoiceDetailSheet extends StatefulWidget {
  final SalesInvoiceController controller;
  final SalesInvoiceModel invoiceItem;
  final VoidCallback onClose;

  const _InvoiceDetailSheet({
    required this.controller,
    required this.invoiceItem,
    required this.onClose,
  });

  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  final _rejectController = TextEditingController();

  @override
  void dispose() {
    _rejectController.dispose();
    super.dispose();
  }

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Posted':
        return Colors.blue;
      case 'Partially Paid':
        return Colors.purple;
      case 'Paid':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current =
          widget.controller.invoices.firstWhereOrNull(
            (i) => i.id == widget.invoiceItem.id,
          ) ??
          widget.invoiceItem;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _statusColor(current.invoiceStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  current.isPaid ? Icons.check_circle : Icons.receipt_long,
                  color: _statusColor(current.invoiceStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.invoiceNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Sales Invoice',
                      style: TextStyle(fontSize: 12, color: kSubText),
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
                  color: _statusColor(current.invoiceStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.controller.getStatusLabel(current.invoiceStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(current.invoiceStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 16),
          _detailRow('Customer', current.customerName),
          if (current.customerEmail != null &&
              current.customerEmail!.isNotEmpty)
            _detailRow('Email', current.customerEmail!),
          if (current.customerPhone != null &&
              current.customerPhone!.isNotEmpty)
            _detailRow('Phone', current.customerPhone!),
          if (current.orderNumber != null && current.orderNumber!.isNotEmpty)
            _detailRow('Order', current.orderNumber!),
          if (current.deliveryNumber != null &&
              current.deliveryNumber!.isNotEmpty)
            _detailRow('Delivery', current.deliveryNumber!),
          _detailRow(
            'Invoice Date',
            DateFormat('dd MMM yyyy').format(current.invoiceDate),
          ),
          _detailRow(
            'Due Date',
            DateFormat('dd MMM yyyy').format(current.dueDate),
          ),
          _detailRow('Payment Terms', current.paymentTerms),
          if (current.isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'OVERDUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          if (current.notes != null && current.notes!.isNotEmpty)
            _detailRow('Notes', current.notes!),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                '${current.totalItems} items',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...current.items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.06)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Qty: ${item.quantity} × ${_format(item.unitPrice)}',
                          style: TextStyle(fontSize: 11, color: kSubText),
                        ),
                        if (item.discount > 0)
                          Text(
                            'Disc: ${item.discount}% • Tax: ${item.taxRate}%',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _format(item.lineTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', _format(current.subtotal)),
                if (current.discountTotal > 0)
                  _summaryRow(
                    'Discount',
                    '-${_format(current.discountTotal)}',
                    color: Colors.red,
                  ),
                if (current.taxTotal > 0)
                  _summaryRow(
                    'Tax',
                    _format(current.taxTotal),
                    color: Colors.blue,
                  ),
                const Divider(height: 12),
                _summaryRow(
                  'Grand Total',
                  _format(current.grandTotal),
                  bold: true,
                ),
                if (current.paidAmount > 0) ...[
                  _summaryRow(
                    'Paid',
                    _format(current.paidAmount),
                    color: Colors.green,
                  ),
                  _summaryRow(
                    'Outstanding',
                    _format(current.outstanding),
                    bold: true,
                    color: current.isOverdue ? Colors.red : Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ─── PDF & Share Actions ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share Invoice',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: kSubText.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.download, size: 18),
                        label: Text(
                          'Download PDF',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: widget.controller.isSubmitting.value
                            ? null
                            : () => widget.controller.generateAndDownloadPdf(
                                current,
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: BorderSide(color: Colors.indigo.shade300),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.share, size: 18),
                        label: Text('Share', style: TextStyle(fontSize: 12)),
                        onPressed: widget.controller.isSubmitting.value
                            ? null
                            : () => widget.controller.shareInvoice(current),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.shade300),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ─── Status Actions ──────────────────────────────
          if (current.canPost) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.postInvoice(
                              current.id,
                            );
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Post Invoice',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await widget.controller.deleteInvoice(
                        current.id,
                      );
                      if (ok) widget.onClose();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (current.canCancel) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.cancelInvoice(
                              current.id,
                            );
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel Invoice',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.sendInvoice(
                              current.id,
                            );
                            if (ok) widget.onClose();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (current.isPosted && !current.isPaid) ...[
            OutlinedButton(
              onPressed: widget.controller.isSubmitting.value
                  ? null
                  : () async {
                      final ok = await widget.controller.sendInvoice(
                        current.id,
                      );
                      if (ok) widget.onClose();
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.blue.shade300),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(
                'Send Invoice',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (current.journalEntry != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, size: 16, color: kSubText),
                      const SizedBox(width: 8),
                      Text(
                        'Journal Entry: ${current.journalEntry!.entryNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSubText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...current.journalEntry!.lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              line.accountName,
                              style: TextStyle(fontSize: 11, color: kSubText),
                            ),
                          ),
                          if (line.debit > 0)
                            Text(
                              'Dr ${_format(line.debit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          if (line.credit > 0)
                            Text(
                              'Cr ${_format(line.credit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (current.accountsReceivable != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accounts Receivable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          'Status: ${current.accountsReceivable!.status} • Due: ${DateFormat('dd MMM yyyy').format(current.accountsReceivable!.dueDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _format(current.accountsReceivable!.outstanding),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: Colors.grey.shade300),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600, color: kSubText),
            ),
          ),
        ],
      );
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? (bold ? kPrimary : kText),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INVOICE LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _InvoiceListView extends StatelessWidget {
  final SalesInvoiceController controller;
  final VoidCallback onCreate;
  final ValueChanged<SalesInvoiceModel> onView;

  const _InvoiceListView({
    required this.controller,
    required this.onCreate,
    required this.onView,
  });

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Posted':
        return Colors.blue;
      case 'Partially Paid':
        return Colors.purple;
      case 'Paid':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Draft':
        return 'Draft';
      case 'Posted':
        return 'Posted';
      case 'Partially Paid':
        return 'Partial Paid';
      case 'Paid':
        return 'Paid';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.invoices.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final invoices = controller.filteredInvoices;

      if (invoices.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No invoices yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first invoice',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Create Invoice',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final item = invoices[index];
          final color = _statusColor(item.invoiceStatus);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onView(item),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.isPaid ? Icons.check_circle : Icons.receipt_long,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.invoiceNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.customerName,
                              style: TextStyle(fontSize: 12, color: kText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _statusLabel(item.invoiceStatus),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.paymentStatus == 'Paid'
                                        ? Colors.green.withOpacity(0.1)
                                        : item.paymentStatus == 'Partial'
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.paymentStatus,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: item.paymentStatus == 'Paid'
                                          ? Colors.green
                                          : item.paymentStatus == 'Partial'
                                          ? Colors.orange
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (item.isOverdue)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'OVERDUE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(item.invoiceDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                            // Payment progress bar
                            if (!item.isDraft && !item.isCancelled) ...[
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: item.paidPercentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: item.isPaid
                                          ? Colors.green
                                          : Colors.blue,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _format(item.grandTotal),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (item.outstanding > 0 && !item.isPaid)
                            Text(
                              'Due: ${_format(item.outstanding)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: item.isOverdue ? Colors.red : kSubText,
                                fontWeight: item.isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
