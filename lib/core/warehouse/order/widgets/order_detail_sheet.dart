import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:flutter/material.dart';

class OrderDetailSheet extends StatelessWidget {
  final SalesOrderController controller;
  final OrderModel order;
  final VoidCallback onClose;

  const OrderDetailSheet({
    super.key,
    required this.controller,
    required this.order,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNumber,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary)),
                      Text(order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(order.orderStatus, controller.getStatusColor(order.orderStatus)),
                _chip(order.paymentStatus, controller.getPaymentColor(order.paymentStatus)),
                _chip(order.priority, controller.getPriorityColor(order.priority)),
                _chip(order.orderType, Colors.grey),
              ],
            ),
            const Divider(height: 24),
            _row('Email', order.customerEmail ?? '-'),
            _row('Phone', order.customerPhone ?? '-'),
            _row('Company', order.customerCompany ?? '-'),
            _row('Customer Type', order.customerType ?? '-'),
            _row('Payment Method', order.paymentMethod ?? '-'),
            _row('Shipping Method', order.shippingMethod ?? '-'),
            _row('Source', order.source ?? '-'),
            _row('Sales Person', order.salesPerson ?? '-'),
            _row('Order Date', controller.formatDate(order.orderDate)),
            if (order.expectedDeliveryDate != null)
              _row('Expected Delivery', controller.formatDate(order.expectedDeliveryDate!)),
            if (order.deliveryDate != null)
              _row('Delivered', controller.formatDate(order.deliveryDate!)),
            const SizedBox(height: 12),
            Text('Shipping Address',
                style: TextStyle(fontWeight: FontWeight.w700, color: kSubText)),
            Text(order.shippingAddressText.isEmpty ? '-' : order.shippingAddressText),
            const SizedBox(height: 12),
            Text('Billing Address',
                style: TextStyle(fontWeight: FontWeight.w700, color: kSubText)),
            Text(order.billingAddressText.isEmpty ? '-' : order.billingAddressText),
            const SizedBox(height: 16),
            Text('Items', style: TextStyle(fontWeight: FontWeight.w700, color: kSubText)),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text('${item.sku} • Qty ${item.quantity}'),
                trailing: Text(controller.formatCurrency(item.totalPrice)),
              ),
            ),
            const Divider(height: 24),
            _row('Subtotal', controller.formatCurrency(order.subtotal)),
            _row('Tax', controller.formatCurrency(order.taxTotal)),
            _row('Shipping', controller.formatCurrency(order.shippingCost)),
            _row('Discount', '- ${controller.formatCurrency(order.discountTotal)}'),
            _row('Grand Total', controller.formatCurrency(order.grandTotal), bold: true),
            if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _row('Customer Notes', order.customerNotes!),
            ],
            if (order.internalNotes != null && order.internalNotes!.isNotEmpty)
              _row('Internal Notes', order.internalNotes!),
            if (order.tags.isNotEmpty)
              _row('Tags', order.tags.join(', ')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: kSubText, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? kPrimary : kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
