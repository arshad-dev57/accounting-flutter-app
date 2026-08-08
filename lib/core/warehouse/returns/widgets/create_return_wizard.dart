import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
import 'package:BisonsTechs_app/core/warehouse/returns/controller/sales_return_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateReturnWizard extends StatelessWidget {
  final SalesReturnController controller;
  final VoidCallback onCancel;

  const CreateReturnWizard({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
                const Expanded(
                  child: Text(
                    'Create Return',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          _stepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),
          _buildNavButtons(),
        ],
      );
    });
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
          labelText: 'Search order # or customer',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
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
                      controller.lineDrafts.refresh();
                    },
                    title: Text(
                      line.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'SKU: ${line.sku} • Qty ordered: ${line.orderQuantity}',
                    ),
                  ),
                  if (line.selected.value) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '${line.returnQuantity.value}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Return Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final q = int.tryParse(v) ?? 1;
                              line.returnQuantity.value = q.clamp(
                                1,
                                line.orderQuantity,
                              );
                              controller.lineDrafts.refresh();
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
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              line.condition.value = v ?? 'New';
                              controller.lineDrafts.refresh();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Refund: ${_format(line.refundAmount)}',
                      style: TextStyle(color: kPrimary),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (controller.lineDrafts.any((l) => l.selected.value))
          Text(
            'Subtotal: ${_format(controller.selectedSubtotal)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
      ]);
    });
  }

  Widget _stepDetails() {
    return _section('Step 3: Return Details', [
      DropdownButtonFormField<String>(
        value: controller.returnType.value,
        decoration: const InputDecoration(
          labelText: 'Return Type',
          border: OutlineInputBorder(),
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
          border: OutlineInputBorder(),
        ),
        items: SalesReturnController.methodOptions
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (v) =>
            controller.returnMethod.value = v ?? 'Original Payment',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.reasonController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Reason *',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.restockingFeeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Restocking Fee',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => controller.lineDrafts.refresh(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.shippingCostController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Shipping Cost',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => controller.lineDrafts.refresh(),
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
            _summaryRow(
              'Total Refund',
              _format(controller.totalRefundAmount),
              bold: true,
            ),
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
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (controller.wizardStep.value > 0)
            OutlinedButton(
              onPressed: controller.previousStep,
              child: const Text('Back'),
            ),
          const Spacer(),
          if (controller.wizardStep.value < 2)
            ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: const Text('Next', style: TextStyle(color: Colors.black)),
            )
          else
            ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.createReturn,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Submit Return',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
      title: Text(
        order.orderNumber,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${order.customerName} • ${order.items.length} items'),
      trailing: const Icon(Icons.chevron_right),
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
          Text(
            order.orderNumber,
            style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
          ),
          Text(order.customerName),
          Text('${order.items.length} line items'),
        ],
      ),
    );
  }
}
