// import 'package:BisonsTechs_app/Utils/colors.dart';
// import 'package:BisonsTechs_app/Utils/currency_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/model/warehouse_invoice_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class WarehouseInvoiceListView extends StatelessWidget {
//   final WarehouseInvoiceController controller;
//   final VoidCallback onCreate;
//   final VoidCallback onImportOrder;
//   final ValueChanged<WarehouseInvoiceModel> onView;

//   const WarehouseInvoiceListView({
//     super.key,
//     required this.controller,
//     required this.onCreate,
//     required this.onImportOrder,
//     required this.onView,
//   });

//   String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildHeader(context),
//           const SizedBox(height: 12),
//           _buildStats(),
//           const SizedBox(height: 12),
//           _buildFilters(context),
//           const SizedBox(height: 12),
//           Expanded(child: _buildList(context)),
//         ],
//       );
//     });
//   }

//   Widget _buildHeader(BuildContext context) {
//     final compact = MediaQuery.of(context).size.width < 520;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         Text(
//           'Sales Invoices (${controller.invoices.length})',
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Bill warehouse sales — linked to orders and payments',
//           style: TextStyle(fontSize: 12, color: kSubText),
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           alignment: WrapAlignment.end,
//           children: [
//             IconButton(
//               onPressed: controller.refreshInvoices,
//               icon: const Icon(Icons.refresh, color: Colors.black87),
//               padding: EdgeInsets.zero,
//               constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
//             ),
//             OutlinedButton.icon(
//               onPressed: onImportOrder,
//               icon: const Icon(Icons.shopping_bag_outlined, size: 16),
//               label: Text(compact ? 'From Order' : 'From Order', style: const TextStyle(fontSize: 12)),
//             ),
//             ElevatedButton.icon(
//               onPressed: onCreate,
//               icon: const Icon(Icons.add, size: 18, color: Colors.black),
//               label: Text(compact ? 'New' : 'New Invoice', style: const TextStyle(color: Colors.black)),
//               style: ElevatedButton.styleFrom(backgroundColor: kPrimary, elevation: 0),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStats() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           _stat('Total', _format(controller.stats.value.grandTotal)),
//           _stat('Paid', _format(controller.stats.value.paidAmount)),
//           _stat('Outstanding', _format(controller.stats.value.outstanding)),
//           _stat('Count', '${controller.stats.value.total}', amount: false),
//         ],
//       ),
//     );
//   }

//   Widget _stat(String label, String value, {bool amount = true}) {
//     return Container(
//       width: amount ? 130 : 90,
//       margin: const EdgeInsets.only(right: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.withOpacity(0.15)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: TextStyle(fontSize: 11, color: kSubText)),
//           Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilters(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.withOpacity(0.15)),
//       ),
//       child: Column(
//         children: [
//           TextField(
//             decoration: const InputDecoration(
//               hintText: 'Search invoice # or customer...',
//               prefixIcon: Icon(Icons.search, size: 20),
//               isDense: true,
//               border: OutlineInputBorder(),
//             ),
//             onSubmitted: controller.applySearch,
//           ),
//           const SizedBox(height: 8),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Obx(() => Row(
//                   children: WarehouseInvoiceController.statusFilters.map((f) {
//                     final selected = controller.statusFilter.value == f;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 6),
//                       child: FilterChip(
//                         label: Text(f, style: const TextStyle(fontSize: 11)),
//                         selected: selected,
//                         onSelected: (_) => controller.applyStatusFilter(f),
//                         selectedColor: kPrimary.withOpacity(0.2),
//                       ),
//                     );
//                   }).toList(),
//                 )),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildList(BuildContext context) {
//     if (controller.isLoading.value) {
//       return Center(child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 36));
//     }
//     if (controller.invoices.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.receipt_long_outlined, size: 56, color: kSubText.withOpacity(0.4)),
//             const SizedBox(height: 12),
//             Text('No invoices yet', style: TextStyle(color: kSubText)),
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: onCreate, style: ElevatedButton.styleFrom(backgroundColor: kPrimary), child: const Text('Create Invoice', style: TextStyle(color: Colors.black))),
//           ],
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.withOpacity(0.15)),
//       ),
//       child: ListView.separated(
//         itemCount: controller.invoices.length,
//         separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
//         itemBuilder: (context, index) {
//           final inv = controller.invoices[index];
//           final color = controller.statusColor(inv);
//           return InkWell(
//             onTap: () => onView(inv),
//             child: Padding(
//               padding: const EdgeInsets.all(14),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.12),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(Icons.receipt_long, color: color, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(inv.invoiceNumber, style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary, fontSize: 13)),
//                         Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
//                         Wrap(
//                           spacing: 6,
//                           runSpacing: 4,
//                           children: [
//                             _badge(inv.paymentStatus, color.withOpacity(0.12), color),
//                             Text(
//                               'Due ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
//                               style: TextStyle(fontSize: 11, color: kSubText),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(_format(inv.grandTotal), style: const TextStyle(fontWeight: FontWeight.w800)),
//                       if (inv.outstanding > 0)
//                         Text('Due ${_format(inv.outstanding)}', style: TextStyle(fontSize: 11, color: kDanger)),
//                       IconButton(
//                         visualDensity: VisualDensity.compact,
//                         padding: EdgeInsets.zero,
//                         icon: const Icon(Icons.visibility_outlined, size: 20),
//                         onPressed: () => onView(inv),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _badge(String text, Color bg, Color fg) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
//       child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
//     );
//   }
// }
