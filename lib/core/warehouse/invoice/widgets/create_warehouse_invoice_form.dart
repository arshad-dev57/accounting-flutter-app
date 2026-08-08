// import 'dart:async';

// import 'package:BisonsTechs_app/Utils/colors.dart';
// import 'package:BisonsTechs_app/Utils/currency_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
// import 'package:BisonsTechs_app/core/warehouse/invoice/model/invoice_draft.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class CreateWarehouseInvoiceForm extends StatefulWidget {
//   final WarehouseInvoiceController controller;
//   final InvoiceDraft? initialDraft;
//   final VoidCallback onCancel;
//   final VoidCallback onSuccess;

//   const CreateWarehouseInvoiceForm({
//     super.key,
//     required this.controller,
//     this.initialDraft,
//     required this.onCancel,
//     required this.onSuccess,
//   });

//   @override
//   State<CreateWarehouseInvoiceForm> createState() => _CreateWarehouseInvoiceFormState();
// }

// class _CreateWarehouseInvoiceFormState extends State<CreateWarehouseInvoiceForm> {
//   late InvoiceDraft _draft;
//   final _discountCtrl = TextEditingController(text: '0');
//   final _notesCtrl = TextEditingController();
//   final _productSearchCtrl = TextEditingController();
//   final List<Map<String, dynamic>> _productResults = [];
//   bool _loadingProducts = false;
//   Timer? _debounce;

//   String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

//   @override
//   void initState() {
//     super.initState();
//     _draft = widget.initialDraft ??
//         InvoiceDraft(
//           issueDate: DateTime.now(),
//           dueDate: DateTime.now().add(const Duration(days: 30)),
//         );
//     _discountCtrl.text = _draft.discount.toStringAsFixed(2);
//     _notesCtrl.text = _draft.notes;
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _discountCtrl.dispose();
//     _notesCtrl.dispose();
//     _productSearchCtrl.dispose();
//     super.dispose();
//   }

//   void _searchProducts(String q) {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 300), () async {
//       if (q.trim().length < 2) {
//         setState(() => _productResults.clear());
//         return;
//       }
//       setState(() => _loadingProducts = true);
//       final list = await widget.controller.searchProducts(q);
//       if (!mounted) return;
//       setState(() {
//         _productResults
//           ..clear()
//           ..addAll(list);
//         _loadingProducts = false;
//       });
//     });
//   }

//   void _addProduct(Map<String, dynamic> product) {
//     setState(() {
//       _draft.lines.add(InvoiceLineDraft.fromProduct(product));
//       _productResults.clear();
//       _productSearchCtrl.clear();
//     });
//   }

//   void _removeLine(int index) {
//     setState(() => _draft.lines.removeAt(index));
//   }

//   Future<void> _pickDate(bool issue) async {
//     final initial = issue ? _draft.issueDate : _draft.dueDate;
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (issue) {
//           _draft.issueDate = picked;
//         } else {
//           _draft.dueDate = picked;
//         }
//       });
//     }
//   }

//   Future<void> _submit() async {
//     _draft.discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
//     _draft.notes = _notesCtrl.text.trim();
//     final ok = await widget.controller.createInvoice(_draft);
//     if (ok) widget.onSuccess();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.arrow_back)),
//               const Expanded(
//                 child: Text('Create Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//               ),
//             ],
//           ),
//           if (_draft.sourceOrderNumber != null)
//             Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue.shade100),
//               ),
//               child: Text('From warehouse order: ${_draft.sourceOrderNumber}', style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
//             ),
//           _section('Customer', [
//             Obx(() {
//               return DropdownButtonFormField<String>(
//                 value: _draft.customerId,
//                 decoration: const InputDecoration(
//                   labelText: 'Select warehouse customer *',
//                   border: OutlineInputBorder(),
//                   isDense: true,
//                 ),
//                 items: widget.controller.customers.map((c) {
//                   final id = (c['_id'] ?? c['id'])?.toString() ?? '';
//                   return DropdownMenuItem(
//                     value: id,
//                     child: Text('${c['name'] ?? 'Customer'}${c['email'] != null ? ' • ${c['email']}' : ''}'),
//                   );
//                 }).toList(),
//                 onChanged: (v) {
//                   setState(() {
//                     _draft.customerId = v;
//                     if (v != null) {
//                       final match = widget.controller.customers.firstWhere(
//                         (c) => (c['id'] ?? c['_id'])?.toString() == v,
//                         orElse: () => {},
//                       );
//                       _draft.customerName = match['name']?.toString();
//                     }
//                   });
//                 },
//               );
//             }),
//             const SizedBox(height: 8),
//             TextFormField(
//               initialValue: _draft.customerName,
//               decoration: const InputDecoration(
//                 labelText: 'Customer name (if not in list)',
//                 border: OutlineInputBorder(),
//                 isDense: true,
//               ),
//               onChanged: (v) => _draft.customerName = v.trim(),
//             ),
//             if (_draft.customerId == null && _draft.customerName != null && _draft.customerName!.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Text(
//                   'Using order customer "${_draft.customerName}" — pick from list or keep name above.',
//                   style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
//                 ),
//               ),
//           ]),
//           const SizedBox(height: 12),
//           _section('Invoice Dates', [
//             Row(
//               children: [
//                 Expanded(
//                   child: ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     title: const Text('Issue date', style: TextStyle(fontSize: 12)),
//                     subtitle: Text(DateFormat('dd MMM yyyy').format(_draft.issueDate)),
//                     trailing: const Icon(Icons.calendar_today, size: 18),
//                     onTap: () => _pickDate(true),
//                   ),
//                 ),
//                 Expanded(
//                   child: ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     title: const Text('Due date', style: TextStyle(fontSize: 12)),
//                     subtitle: Text(DateFormat('dd MMM yyyy').format(_draft.dueDate)),
//                     trailing: const Icon(Icons.event, size: 18),
//                     onTap: () => _pickDate(false),
//                   ),
//                 ),
//               ],
//             ),
//           ]),
//           const SizedBox(height: 12),
//           _section('Line Items', [
//             TextField(
//               controller: _productSearchCtrl,
//               decoration: InputDecoration(
//                 labelText: 'Add product from warehouse catalog',
//                 hintText: 'Search name or SKU...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: _loadingProducts ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
//                 border: const OutlineInputBorder(),
//                 isDense: true,
//               ),
//               onChanged: _searchProducts,
//             ),
//             if (_productResults.isNotEmpty)
//               ..._productResults.map((p) => ListTile(
//                     dense: true,
//                     contentPadding: EdgeInsets.zero,
//                     title: Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
//                     subtitle: Text('${p['sku']} • ${_format((p['sellingPrice'] as num?)?.toDouble() ?? 0)}'),
//                     trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addProduct(p)),
//                   )),
//             const SizedBox(height: 8),
//             ...List.generate(_draft.lines.length, (index) => _lineCard(index)),
//             if (_draft.lines.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 child: Text('No line items yet', style: TextStyle(color: kSubText, fontSize: 12)),
//               ),
//           ]),
//           const SizedBox(height: 12),
//           _section('Totals', [
//             _totalRow('Subtotal', _format(_draft.subtotal)),
//             _totalRow('Tax', _format(_draft.taxTotal)),
//             TextField(
//               controller: _discountCtrl,
//               keyboardType: const TextInputType.numberWithOptions(decimal: true),
//               decoration: const InputDecoration(labelText: 'Discount', border: OutlineInputBorder(), isDense: true),
//               onChanged: (_) => setState(() => _draft.discount = double.tryParse(_discountCtrl.text) ?? 0),
//             ),
//             const Divider(),
//             _totalRow('Grand Total', _format(_draft.grandTotal), bold: true),
//             const SizedBox(height: 8),
//             TextField(
//               controller: _notesCtrl,
//               maxLines: 3,
//               decoration: const InputDecoration(labelText: 'Notes / Terms', border: OutlineInputBorder()),
//             ),
//           ]),
//           const SizedBox(height: 20),
//           Obx(() => ElevatedButton(
//                 onPressed: widget.controller.isSubmitting.value ? null : _submit,
//                 style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
//                 child: widget.controller.isSubmitting.value
//                     ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
//                     : const Text('Create Invoice', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
//               )),
//         ],
//       ),
//     );
//   }

//   Widget _lineCard(int index) {
//     final line = _draft.lines[index];
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(child: Text(line.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
//                 IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _removeLine(index)),
//               ],
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     initialValue: '${line.quantity}',
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
//                     onChanged: (v) => setState(() => line.quantity = int.tryParse(v) ?? 1),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextFormField(
//                     initialValue: line.unitPrice.toStringAsFixed(2),
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     decoration: const InputDecoration(labelText: 'Unit price', isDense: true, border: OutlineInputBorder()),
//                     onChanged: (v) => setState(() => line.unitPrice = double.tryParse(v) ?? 0),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextFormField(
//                     initialValue: line.taxRate.toStringAsFixed(1),
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     decoration: const InputDecoration(labelText: 'Tax %', isDense: true, border: OutlineInputBorder()),
//                     onChanged: (v) => setState(() => line.taxRate = double.tryParse(v) ?? 0),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text('Line total: ${_format(line.lineTotal)}', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _section(String title, List<Widget> children) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.withOpacity(0.15)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
//           const SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _totalRow(String label, String value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
//           Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }
