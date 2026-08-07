// import 'package:BisonsTechs_app/Utils/colors.dart';
// import 'package:BisonsTechs_app/Utils/currency_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/model/invoice_draft.dart';
// import 'package:BisonsTechs_app/core/warehouse/order/model/order_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class InvoiceFromOrderSheet extends StatefulWidget {
//   final WarehouseInvoiceController controller;
//   final ValueChanged<InvoiceDraft> onSelect;

//   const InvoiceFromOrderSheet({
//     super.key,
//     required this.controller,
//     required this.onSelect,
//   });

//   @override
//   State<InvoiceFromOrderSheet> createState() => _InvoiceFromOrderSheetState();
// }

// class _InvoiceFromOrderSheetState extends State<InvoiceFromOrderSheet> {
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     await widget.controller.fetchBillableOrders();
//     if (mounted) setState(() => _loading = false);
//   }

//   String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: 0.75,
//       maxChildSize: 0.92,
//       minChildSize: 0.45,
//       builder: (_, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const Expanded(
//                       child: Text('Invoice from Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
//                     ),
//                     IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Text(
//                   'Pick a warehouse order to pre-fill line items. Stock was already adjusted when the order was created.',
//                   style: TextStyle(fontSize: 12, color: kSubText),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: _loading
//                     ? Center(child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 32))
//                     : Obx(() {
//                         final orders = widget.controller.billableOrders;
//                         if (orders.isEmpty) {
//                           return Center(child: Text('No orders available', style: TextStyle(color: kSubText)));
//                         }
//                         return ListView.separated(
//                           controller: scrollController,
//                           padding: const EdgeInsets.all(16),
//                           itemCount: orders.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 8),
//                           itemBuilder: (context, index) => _orderTile(orders[index]),
//                         );
//                       }),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _orderTile(OrderModel order) {
//     final matched = widget.controller.matchCustomerId(order) != null;
//     return InkWell(
//       onTap: () {
//         final draft = widget.controller.draftFromOrder(order);
//         widget.onSelect(draft);
//         Navigator.pop(context);
//       },
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.withOpacity(0.2)),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(order.orderNumber, style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary)),
//                 ),
//                 Text(_format(order.grandTotal), style: const TextStyle(fontWeight: FontWeight.w800)),
//               ],
//             ),
//             Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 6),
//             Wrap(
//               spacing: 6,
//               runSpacing: 4,
//               children: [
//                 _chip(order.orderStatus),
//                 _chip(order.paymentStatus),
//                 _chip('${order.items.length} items'),
//                 _chip(matched ? 'Customer matched' : 'Enter customer name', color: matched ? Colors.green.shade700 : Colors.orange.shade700),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _chip(String text, {Color? color}) {
//     final c = color ?? Colors.grey.shade700;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
//       child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
//     );
//   }
// }
