import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/controller/sales_refund_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRefundForm extends StatelessWidget {
  final SalesRefundController controller;
  final VoidCallback onCancel;

  const CreateRefundForm({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Text(
                  'Create Refund',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section('Find Order', [
              TextField(
                controller: controller.orderSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search by order # or customer',
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
              if (controller.orderSearchResults.isNotEmpty)
                ...controller.orderSearchResults.map(_orderTile),
              if (controller.selectedOrder.value != null) ...[
                const SizedBox(height: 8),
                _selectedOrderCard(controller.selectedOrder.value!),
              ],
            ]),
            const SizedBox(height: 16),
            _section('Refund Details', [
              TextField(
                controller: controller.amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Refund Amount *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: controller.refundMethod.value,
                decoration: const InputDecoration(
                  labelText: 'Refund Method',
                  border: OutlineInputBorder(),
                ),
                items: SalesRefundController.methodOptions
                    .where((m) => m != 'all')
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    controller.refundMethod.value = v ?? 'Original Payment',
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
              if (controller.refundMethod.value == 'Bank Transfer') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller.bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: controller.referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.createRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
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
                      'Submit Refund',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
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
      subtitle: Text(
        '${order.customerName} • ${order.grandTotal.toStringAsFixed(2)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => controller.selectOrderForRefund(order),
    );
  }

  Widget _selectedOrderCard(OrderModel order) {
    return Container(
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
          Text('Total: ${order.grandTotal.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
