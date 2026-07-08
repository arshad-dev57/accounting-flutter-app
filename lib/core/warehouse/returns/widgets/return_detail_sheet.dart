import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/returns/controller/sales_return_controller.dart';
import 'package:LedgerPro_app/core/warehouse/returns/model/return_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReturnDetailSheet extends StatefulWidget {
  final SalesReturnController controller;
  final ReturnModel returnItem;
  final VoidCallback onClose;

  const ReturnDetailSheet({
    super.key,
    required this.controller,
    required this.returnItem,
    required this.onClose,
  });

  @override
  State<ReturnDetailSheet> createState() => _ReturnDetailSheetState();
}

class _ReturnDetailSheetState extends State<ReturnDetailSheet> {
  final _rejectController = TextEditingController();

  @override
  void dispose() {
    _rejectController.dispose();
    super.dispose();
  }

  String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = widget.controller.returns.firstWhereOrNull((r) => r.id == widget.returnItem.id) ??
          widget.returnItem;

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
                        current.returnNumber,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary),
                      ),
                    ),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                _row('Status', current.returnStatus),
                _row('Type', current.returnType),
                _row('Method', current.returnMethod),
                _row('Order', current.orderNumber),
                _row('Customer', current.customerName),
                _row('Total Refund', _format(current.totalRefund)),
                _row('Reason', current.reason),
                if (current.rejectionReason != null) _row('Rejection', current.rejectionReason!),
                _row('Date', DateFormat('dd MMM yyyy').format(current.returnDate)),
                const Divider(height: 24),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...current.items.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.productName),
                      subtitle: Text('Qty: ${item.returnQuantity} • ${item.condition}'),
                      trailing: Text(_format(item.refundAmount)),
                    )),
                if (current.returnStatus == 'Pending') ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.approveReturn(current.id);
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve Return'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rejectController,
                    decoration: const InputDecoration(
                      labelText: 'Rejection reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.rejectReturn(
                              current.id,
                              _rejectController.text,
                            );
                            if (ok) widget.onClose();
                          },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject Return'),
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
