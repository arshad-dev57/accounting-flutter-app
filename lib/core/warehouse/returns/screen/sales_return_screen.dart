// lib/core/warehouse/returns/views/returns_screen.dart - COMPLETE WITHOUT DRAWER

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:LedgerPro_app/core/warehouse/returns/controller/sales_return_controller.dart';
import 'package:LedgerPro_app/core/warehouse/returns/model/return_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SalesReturnScreen extends StatelessWidget {
  const SalesReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesReturnController());

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text(
          'Sales Return',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.showCreateWizard.value) {
          return _CreateReturnWizard(
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
                child: _ReturnListView(
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
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildTopHeader(SalesReturnController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales Return',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.totalRecords.value} returns',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Obx(() => Row(
                    children: [
                      _compactKpi('Pending', controller.stats.value.pending.toString(), Colors.orange.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Approved', controller.stats.value.approved.toString(), Colors.green.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Rejected', controller.stats.value.rejected.toString(), Colors.red.shade700),
                    ],
                  )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshReturns,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.refresh_rounded, size: 17, color: Colors.black.withOpacity(0.65)),
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
            Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _filterChip('All', controller.selectedFilter.value == 'all', () => controller.filterReturns('all')),
                  _filterChip('Pending', controller.selectedFilter.value == 'Pending', () => controller.filterReturns('Pending')),
                  _filterChip('Approved', controller.selectedFilter.value == 'Approved', () => controller.filterReturns('Approved')),
                  _filterChip('Completed', controller.selectedFilter.value == 'Completed', () => controller.filterReturns('Completed')),
                  _filterChip('Rejected', controller.selectedFilter.value == 'Rejected', () => controller.filterReturns('Rejected')),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w600)),
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
            color: selected ? Colors.black : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.black : Colors.white.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, SalesReturnController controller, ReturnModel item) {
    controller.selectReturn(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.93,
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
                  child: _ReturnDetailSheet(
                    controller: controller,
                    returnItem: item,
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
  final SalesReturnController controller;
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
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchReturns(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search returns...',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE RETURN WIZARD
// ═══════════════════════════════════════════════════════════════
class _CreateReturnWizard extends StatelessWidget {
  final SalesReturnController controller;
  final VoidCallback onCancel;

  const _CreateReturnWizard({
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
        leading: IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Create Return',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
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
                child: _buildStepContent(),
              ),
            ),
            _buildNavButtons(),
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
                color: active ? kPrimary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (controller.wizardStep.value) {
      case 0:
        return _stepFindOrder();
      case 1:
        return _stepSelectItems();
      default:
        return _stepDetails();
    }
  }

  Widget _stepFindOrder() {
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
        const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator())),
      ...controller.orderSearchResults.map(_orderTile),
      if (controller.selectedOrder.value != null)
        _selectedOrderCard(controller.selectedOrder.value!),
    ]);
  }

  Widget _stepSelectItems() {
    return Obx(() {
      return _section('Step 2: Select Items', [
        ...List.generate(controller.lineDrafts.length, (index) {
          final line = controller.lineDrafts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: line.selected.value,
                    onChanged: (v) {
                      line.selected.value = v ?? false;
                    },
                    title: Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('SKU: ${line.sku} • Qty ordered: ${line.orderQuantity}'),
                  ),
                  if (line.selected.value) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: line.returnQuantity.value.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Return Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final q = int.tryParse(v) ?? 1;
                              line.returnQuantity.value = q.clamp(1, line.orderQuantity);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: line.condition.value,
                            decoration: const InputDecoration(
                              labelText: 'Condition',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: SalesReturnController.conditionOptions
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              line.condition.value = v ?? 'New';
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Refund: ${_format(line.refundAmount)}', style: TextStyle(color: kPrimary)),
                  ],
                ],
              ),
            ),
          );
        }),
        if (controller.lineDrafts.any((l) => l.selected.value))
          Text('Subtotal: ${_format(controller.selectedSubtotal)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);
    });
  }

  Widget _stepDetails() {
    return _section('Step 3: Return Details', [
      DropdownButtonFormField<String>(
        value: controller.returnType.value,
        decoration: const InputDecoration(
          labelText: 'Return Type',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        items: SalesReturnController.typeOptions
            .where((t) => t != 'all')
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (v) => controller.returnType.value = v ?? 'Return',
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: controller.returnMethod.value,
        decoration: const InputDecoration(
          labelText: 'Refund Method',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        items: SalesReturnController.methodOptions
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (v) => controller.returnMethod.value = v ?? 'Original Payment',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.reasonController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Reason *',
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
          labelText: 'Notes',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.restockingFeeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Restocking Fee',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.shippingCostController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Shipping Cost',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
        ],
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
            _summaryRow('Subtotal', _format(controller.selectedSubtotal)),
            _summaryRow('Restocking Fee', _format(controller.restockingFee)),
            _summaryRow('Shipping', _format(controller.shippingCost)),
            const Divider(),
            _summaryRow('Total Refund', _format(controller.totalRefundAmount), bold: true),
          ],
        ),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kSubText)),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? kPrimary : kText,
          )),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Next', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : controller.createReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Submit Return', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
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

  Widget _orderTile(OrderModel order) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${order.customerName} • ${order.items.length} items'),
      trailing: Icon(Icons.chevron_right, color: kSubText),
      onTap: () => controller.selectOrderForReturn(order),
    );
  }

  Widget _selectedOrderCard(OrderModel order) {
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
          Text(order.orderNumber, style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary)),
          Text(order.customerName),
          Text('${order.items.length} line items'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RETURN DETAIL SHEET
// ═══════════════════════════════════════════════════════════════
class _ReturnDetailSheet extends StatefulWidget {
  final SalesReturnController controller;
  final ReturnModel returnItem;
  final VoidCallback onClose;

  const _ReturnDetailSheet({
    required this.controller,
    required this.returnItem,
    required this.onClose,
  });

  @override
  State<_ReturnDetailSheet> createState() => _ReturnDetailSheetState();
}

class _ReturnDetailSheetState extends State<_ReturnDetailSheet> {
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
      case 'Approved':
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = widget.controller.returns.firstWhereOrNull((r) => r.id == widget.returnItem.id) ??
          widget.returnItem;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _statusColor(current.returnStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.undo, color: _statusColor(current.returnStatus), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.returnNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Return',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(current.returnStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  current.returnStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(current.returnStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 16),
          _detailRow('Type', current.returnType),
          _detailRow('Method', current.returnMethod),
          _detailRow('Order', current.orderNumber),
          _detailRow('Customer', current.customerName),
          _detailRow('Total Refund', _format(current.totalRefund)),
          _detailRow('Reason', current.reason),
          if (current.rejectionReason != null && current.rejectionReason!.isNotEmpty)
            _detailRow('Rejection', current.rejectionReason!),
          _detailRow('Date', DateFormat('dd MMM yyyy').format(current.returnDate)),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          const Text(
            'Return Items',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...current.items.map((item) => Container(
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
                            'Qty: ${item.returnQuantity} • ${item.condition}',
                            style: TextStyle(fontSize: 12, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _format(item.refundAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          if (current.returnStatus == 'Pending') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.approveReturn(current.id);
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Approve Return',
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
                    onPressed: () {
                      if (_rejectController.text.trim().isEmpty) {
                        Get.snackbar('Error', 'Please enter rejection reason');
                        return;
                      }
                      widget.controller.rejectReturn(current.id, _rejectController.text);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Reject',
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
            TextField(
              controller: _rejectController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
          if (current.returnStatus == 'Approved') ...[
            ElevatedButton(
              onPressed: widget.controller.isSubmitting.value
                  ? null
                  : () async {
                      final ok = await widget.controller.completeReturn(current.id);
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
                'Complete Return',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: kSubText,
              ),
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
}

// ═══════════════════════════════════════════════════════════════
// RETURN LIST VIEW
// ═══════════════════════════════════════════════════════════════
class _ReturnListView extends StatelessWidget {
  final SalesReturnController controller;
  final VoidCallback onCreate;
  final ValueChanged<ReturnModel> onView;

  const _ReturnListView({
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
      case 'Approved':
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.returns.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final returns = controller.filteredReturns;

      if (returns.isEmpty && !controller.isLoading.value) {
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
                  Icons.undo_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No returns yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first return',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Create Return',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        itemCount: returns.length,
        itemBuilder: (context, index) {
          final item = returns[index];
          final color = _statusColor(item.returnStatus);

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
                        child: Icon(Icons.undo, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.returnNumber,
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
                              style: TextStyle(
                                fontSize: 12,
                                color: kText,
                              ),
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
                                    item.returnStatus,
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
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.returnType,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple.shade800,
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
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.totalReturnQty} items',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy').format(item.returnDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _format(item.totalRefund),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
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