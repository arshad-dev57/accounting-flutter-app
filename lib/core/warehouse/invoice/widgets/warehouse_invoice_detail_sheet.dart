// import 'package:BisonsTechs_app/Utils/colors.dart';

// import 'package:BisonsTechs_app/Utils/currency_controller.dart';

// import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';

// import 'package:BisonsTechs_app/core/warehouse/invoice/model/warehouse_invoice_model.dart';

// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import 'package:intl/intl.dart';



// class WarehouseInvoiceDetailSheet extends StatefulWidget {

//   final WarehouseInvoiceController controller;

//   final WarehouseInvoiceModel invoice;

//   final VoidCallback onClose;



//   const WarehouseInvoiceDetailSheet({

//     super.key,

//     required this.controller,

//     required this.invoice,

//     required this.onClose,

//   });



//   @override

//   State<WarehouseInvoiceDetailSheet> createState() => _WarehouseInvoiceDetailSheetState();

// }



// class _WarehouseInvoiceDetailSheetState extends State<WarehouseInvoiceDetailSheet> {

//   final _paymentCtrl = TextEditingController();



//   String _format(double v) => Get.find<CurrencyController>().formatAmount(v);



//   @override

//   void initState() {

//     super.initState();

//     _paymentCtrl.text = widget.invoice.outstanding.toStringAsFixed(2);

//   }



//   @override

//   void dispose() {

//     _paymentCtrl.dispose();

//     super.dispose();

//   }



//   Future<void> _recordPayment() async {

//     final amount = double.tryParse(_paymentCtrl.text.trim()) ?? 0;

//     if (amount <= 0) {

//       Get.snackbar('Validation', 'Enter a valid payment amount');

//       return;

//     }

//     final ok = await widget.controller.recordPayment(widget.invoice.id, amount);

//     if (ok) widget.onClose();

//   }



//   @override

//   Widget build(BuildContext context) {

//     final invoice = widget.invoice;

//     final color = widget.controller.statusColor(invoice);



//     return DraggableScrollableSheet(

//       expand: false,

//       initialChildSize: 0.85,

//       maxChildSize: 0.95,

//       minChildSize: 0.5,

//       builder: (_, scrollController) {

//         return Container(

//           decoration: const BoxDecoration(

//             color: Colors.white,

//             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),

//           ),

//           child: ListView(

//             controller: scrollController,

//             padding: const EdgeInsets.all(20),

//             children: [

//               Row(

//                 children: [

//                   Expanded(

//                     child: Text(invoice.invoiceNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary)),

//                   ),

//                   IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),

//                 ],

//               ),

//               const SizedBox(height: 8),

//               Wrap(

//                 spacing: 8,

//                 runSpacing: 6,

//                 children: [

//                   _badge(invoice.invoiceStatus, Colors.blueGrey),

//                   _badge(invoice.paymentStatus, color),

//                   if (invoice.isOverdue) _badge('Overdue', Colors.red),

//                   if (invoice.orderNumber != null) _badge('Order ${invoice.orderNumber}', Colors.indigo),

//                 ],

//               ),

//               const SizedBox(height: 16),

//               _row('Customer', invoice.customerName),

//               _row('Issue date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),

//               _row('Due date', DateFormat('dd MMM yyyy').format(invoice.dueDate)),

//               const Divider(height: 24),

//               const Text('Line Items', style: TextStyle(fontWeight: FontWeight.w700)),

//               const SizedBox(height: 8),

//               ...invoice.items.map((item) => ListTile(

//                     contentPadding: EdgeInsets.zero,

//                     title: Text(item.productName),

//                     subtitle: Text('${item.quantity} × ${_format(item.unitPrice)} • Tax ${item.taxRate}%'),

//                     trailing: Text(_format(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700)),

//                   )),

//               const Divider(height: 24),

//               _row('Subtotal', _format(invoice.subtotal)),

//               _row('Tax', _format(invoice.taxTotal)),

//               if (invoice.discountTotal > 0) _row('Discount', '-${_format(invoice.discountTotal)}'),

//               _row('Total', _format(invoice.grandTotal), bold: true),

//               _row('Paid', _format(invoice.paidAmount)),

//               _row('Outstanding', _format(invoice.outstanding)),

//               if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[

//                 const Divider(height: 24),

//                 _row('Notes', invoice.notes!),

//               ],

//               if (invoice.paymentStatus != 'Paid' && invoice.outstanding > 0) ...[

//                 const Divider(height: 24),

//                 const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.w700)),

//                 const SizedBox(height: 8),

//                 TextField(

//                   controller: _paymentCtrl,

//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),

//                   decoration: const InputDecoration(

//                     labelText: 'Amount',

//                     border: OutlineInputBorder(),

//                     isDense: true,

//                   ),

//                 ),

//                 const SizedBox(height: 10),

//                 Obx(() => SizedBox(

//                       width: double.infinity,

//                       child: ElevatedButton(

//                         onPressed: widget.controller.isSubmitting.value ? null : _recordPayment,

//                         style: ElevatedButton.styleFrom(backgroundColor: kPrimary),

//                         child: widget.controller.isSubmitting.value

//                             ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))

//                             : const Text('Record Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),

//                       ),

//                     )),

//               ],

//               const SizedBox(height: 20),

//               if (invoice.paymentStatus != 'Paid')

//                 SizedBox(

//                   width: double.infinity,

//                   child: OutlinedButton.icon(

//                     onPressed: () async {

//                       final ok = await showDialog<bool>(

//                         context: context,

//                         builder: (ctx) => AlertDialog(

//                           title: const Text('Delete invoice?'),

//                           content: Text('Delete ${invoice.invoiceNumber}? Paid invoices cannot be deleted.'),

//                           actions: [

//                             TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),

//                             TextButton(

//                               onPressed: () => Navigator.pop(ctx, true),

//                               child: const Text('Delete', style: TextStyle(color: Colors.red)),

//                             ),

//                           ],

//                         ),

//                       );

//                       if (ok == true) {

//                         final deleted = await widget.controller.deleteInvoice(invoice);

//                         if (deleted) widget.onClose();

//                       }

//                     },

//                     icon: const Icon(Icons.delete_outline, color: Colors.red),

//                     label: const Text('Delete', style: TextStyle(color: Colors.red)),

//                   ),

//                 ),

//             ],

//           ),

//         );

//       },

//     );

//   }



//   Widget _row(String label, String value, {bool bold = false}) {

//     return Padding(

//       padding: const EdgeInsets.only(bottom: 10),

//       child: Row(

//         crossAxisAlignment: CrossAxisAlignment.start,

//         children: [

//           SizedBox(width: 110, child: Text(label, style: TextStyle(color: kSubText, fontSize: 13))),

//           Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),

//         ],

//       ),

//     );

//   }



//   Widget _badge(String text, Color color) {

//     return Container(

//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

//       decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),

//       child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),

//     );

//   }

// }


