import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/refunds/controller/sales_refund_controller.dart';
import 'package:LedgerPro_app/core/warehouse/refunds/model/refund_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RefundDetailSheet extends StatelessWidget {
  final SalesRefundController controller;
  final RefundModel refund;
  final VoidCallback onClose;

  const RefundDetailSheet({
    super.key,
    required this.controller,
    required this.refund,
    required this.onClose,
  });

  String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.refunds.firstWhereOrNull((r) => r.id == refund.id) ?? refund;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        current.refundNumber,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary),
                      ),
                    ),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                _row('Status', current.refundStatus),
                _row('Amount', _format(current.amount)),
                _row('Method', current.refundMethod),
                _row('Order', current.orderNumber),
                _row('Customer', current.customerName),
                if (current.customerEmail != null) _row('Email', current.customerEmail!),
                _row('Reason', current.reason),
                if (current.notes != null && current.notes!.isNotEmpty) _row('Notes', current.notes!),
                _row('Date', DateFormat('dd MMM yyyy').format(current.refundDate)),
                if (current.bankName != null) ...[
                  const Divider(height: 24),
                  const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.w700)),
                  _row('Bank', current.bankName!),
                  if (current.accountNumber != null) _row('Account', current.accountNumber!),
                  if (current.accountHolderName != null) _row('Holder', current.accountHolderName!),
                ],
                const SizedBox(height: 24),
                if (current.refundStatus == 'Pending')
                  ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await controller.processRefund(current.id);
                            if (ok) onClose();
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('Process Refund'),
                  ),
                if (current.refundStatus == 'Processing') ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await controller.completeRefund(current.id);
                            if (ok) onClose();
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Complete Refund'),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: kSubText, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
