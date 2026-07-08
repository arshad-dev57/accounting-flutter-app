import 'dart:async';

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ─────────────────────── WIDGETS ───────────────────────

class WarehouseInvoiceListView extends StatelessWidget {
  final WarehouseInvoiceController controller;
  final VoidCallback onCreate;
  final VoidCallback onImportOrder;
  final Function(WarehouseInvoiceModel) onView;

  const WarehouseInvoiceListView({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onImportOrder,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search invoices...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: kCardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onChanged: controller.applySearch,
        ),
        const SizedBox(height: 12),

        // Filter Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...WarehouseInvoiceController.statusFilters.map((filter) {
                final isSelected = controller.statusFilter.value == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter == 'all' ? 'All' : filter),
                    selected: isSelected,
                    onSelected: (_) => controller.applyStatusFilter(filter),
                    backgroundColor: kBg,
                    selectedColor: kPrimary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? kPrimary : kSubText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stats Summary
        Obx(() {
          final s = controller.stats.value;
          return Row(
            children: [
              _statChip('Total', s.total, kPrimary),
              _statChip('Unpaid', s.unpaid, Colors.orange),
              _statChip('Partial', s.partial, Colors.blue),
              _statChip('Paid', s.paid, kSuccess),
              _statChip('Overdue', s.overdue, kDanger),
            ],
          );
        }),
        const SizedBox(height: 12),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onImportOrder,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('From Order'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Invoices List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.invoices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: kSubText.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text('No invoices found', style: TextStyle(color: kSubText)),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first invoice',
                      style: TextStyle(color: kSubText, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: controller.invoices.length,
              itemBuilder: (context, index) {
                final invoice = controller.invoices[index];
                return _buildInvoiceCard(invoice);
              },
            );
          }),
        ),

        // Pagination
        Obx(() {
          if (controller.totalPages.value <= 1) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: controller.hasPrev.value ? () => controller.goToPage(controller.currentPage.value - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${controller.currentPage.value} / ${controller.totalPages.value}'),
                IconButton(
                  onPressed: controller.hasNext.value ? () => controller.goToPage(controller.currentPage.value + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInvoiceCard(WarehouseInvoiceModel invoice) {
    final color = Get.find<WarehouseInvoiceController>().statusColor(invoice);
    final status = invoice.invoiceStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Get.find<WarehouseInvoiceController>().selectedInvoice.value = invoice,
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.customerName,
                    style: TextStyle(fontSize: 12, color: kSubText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
              style: TextStyle(fontSize: 11, color: kSubText),
            ),
            const Spacer(),
            Text(
              '${invoice.outstanding > 0 ? invoice.outstanding : 0}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: invoice.outstanding > 0 ? kDanger : kSuccess,
              ),
            ),
          ],
        ),
        isThreeLine: false,
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: () => Get.find<WarehouseInvoiceController>().selectedInvoice.value = invoice,
        ),
      ),
    );
  }
}

// ─────────────────────── MAIN SCREEN ───────────────────────

class WarehouseInvoiceScreen extends StatefulWidget {
  const WarehouseInvoiceScreen({super.key});

  @override
  State<WarehouseInvoiceScreen> createState() => _WarehouseInvoiceScreenState();
}

class _WarehouseInvoiceScreenState extends State<WarehouseInvoiceScreen> {
  InvoiceDraft? _orderDraft;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WarehouseInvoiceController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Invoices',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshInvoices(),
          ),
        ],
      ),
      body: Obx(() {
        // Show detail view if selected
        if (controller.selectedInvoice.value != null) {
          return _buildDetailView(controller);
        }

        // Show create form
        if (controller.showCreateForm.value) {
          return _buildCreateForm(controller);
        }

        // Show list view
        return Padding(
          padding: const EdgeInsets.all(16),
          child: WarehouseInvoiceListView(
            controller: controller,
            onCreate: () {
              _orderDraft = null;
              controller.openCreateForm();
            },
            onImportOrder: () => _showFromOrder(context, controller),
            onView: (inv) => controller.selectedInvoice.value = inv,
          ),
        );
      }),
    );
  }

  Widget _buildCreateForm(WarehouseInvoiceController controller) {
    return CreateWarehouseInvoiceForm(
      controller: controller,
      initialDraft: _orderDraft,
      onCancel: () {
        _orderDraft = null;
        controller.closeCreateForm();
      },
      onSuccess: () {
        _orderDraft = null;
        controller.closeCreateForm();
      },
    );
  }

  Widget _buildDetailView(WarehouseInvoiceController controller) {
    final invoice = controller.selectedInvoice.value!;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.selectedInvoice.value = null,
        ),
        actions: [
          if (invoice.isUnpaid || invoice.isPartial)
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () => _showPaymentDialog(controller, invoice),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: controller.statusColor(invoice).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Status: ${invoice.invoiceStatus}',
                style: TextStyle(
                  color: controller.statusColor(invoice),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(invoice.customerName),
                    if (invoice.customerEmail != null) Text(invoice.customerEmail!),
                    if (invoice.customerPhone != null) Text(invoice.customerPhone!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Invoice Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice Date', style: TextStyle(fontSize: 12, color: kSubText)),
                              Text(DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text('Due Date', style: TextStyle(fontSize: 12, color: kSubText)),
                              Text(DateFormat('dd MMM yyyy').format(invoice.dueDate)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...invoice.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productName}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text('${item.unitPrice}'),
                        ],
                      ),
                    )),
                    const Divider(),
                    _totalRow('Subtotal', '${invoice.subtotal}'),
                    _totalRow('Tax', '${invoice.taxTotal}'),
                    if (invoice.discountTotal > 0)
                      _totalRow('Discount', '-${invoice.discountTotal}'),
                    _totalRow('Grand Total', '${invoice.grandTotal}', bold: true),
                    if (invoice.paidAmount > 0)
                      _totalRow('Paid', '${invoice.paidAmount}'),
                    _totalRow('Outstanding', '${invoice.outstanding}', bold: true, color: invoice.outstanding > 0 ? kDanger : kSuccess),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(invoice.notes!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                if (invoice.isUnpaid || invoice.isPartial)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(controller, invoice),
                      icon: const Icon(Icons.payment),
                      label: const Text('Record Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!invoice.isPaid && !invoice.isCancelled) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirm(controller, invoice),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(WarehouseInvoiceController controller, WarehouseInvoiceModel invoice) {
    final amountCtrl = TextEditingController(text: invoice.outstanding.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invoice: ${invoice.invoiceNumber}'),
            const SizedBox(height: 8),
            Text('Outstanding: ${invoice.outstanding}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0 || amount > invoice.outstanding) {
                Get.snackbar('Error', 'Invalid amount');
                return;
              }
              Navigator.pop(ctx);
              await controller.recordPayment(invoice.id, amount);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(WarehouseInvoiceController controller, WarehouseInvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice ${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteInvoice(invoice);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFromOrder(BuildContext context, WarehouseInvoiceController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        controller.fetchBillableOrders();
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final orders = controller.billableOrders;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select Order to Create Invoice',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          title: Text(order.orderNumber),
                          subtitle: Text(order.customerName),
                          trailing: Text('${order.subtotal}'),
                          onTap: () {
                            final draft = controller.draftFromOrder(order);
                            Navigator.pop(context);
                            _orderDraft = draft;
                            controller.openCreateForm();
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }
}

// ─────────────────────── CREATE FORM WIDGET ───────────────────────

class CreateWarehouseInvoiceForm extends StatefulWidget {
  final WarehouseInvoiceController controller;
  final InvoiceDraft? initialDraft;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const CreateWarehouseInvoiceForm({
    super.key,
    required this.controller,
    this.initialDraft,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<CreateWarehouseInvoiceForm> createState() => _CreateWarehouseInvoiceFormState();
}

class _CreateWarehouseInvoiceFormState extends State<CreateWarehouseInvoiceForm> {
  late InvoiceDraft _draft;
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _productResults = [];
  bool _loadingProducts = false;
  Timer? _debounce;

  String _format(double v) => '${v.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ??
        InvoiceDraft(
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
        );
    _discountCtrl.text = _draft.discount.toStringAsFixed(2);
    _notesCtrl.text = _draft.notes;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }

  void _searchProducts(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().length < 2) {
        setState(() => _productResults.clear());
        return;
      }
      setState(() => _loadingProducts = true);
      final list = await widget.controller.searchProducts(q);
      if (!mounted) return;
      setState(() {
        _productResults
          ..clear()
          ..addAll(list);
        _loadingProducts = false;
      });
    });
  }

  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      _draft.lines.add(InvoiceLineDraft.fromProduct(product));
      _productResults.clear();
      _productSearchCtrl.clear();
    });
  }

  void _removeLine(int index) {
    setState(() => _draft.lines.removeAt(index));
  }

  Future<void> _pickDate(bool issue) async {
    final initial = issue ? _draft.issueDate : _draft.dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (issue) {
          _draft.issueDate = picked;
        } else {
          _draft.dueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    _draft.discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    _draft.notes = _notesCtrl.text.trim();

    if (_draft.customerName == null || _draft.customerName!.trim().isEmpty) {
      Get.snackbar('Validation', 'Customer is required');
      return;
    }
    if (_draft.lines.isEmpty) {
      Get.snackbar('Validation', 'Add at least one line item');
      return;
    }

    final ok = await widget.controller.createInvoice(_draft);
    if (ok) widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.arrow_back)),
              const Expanded(
                child: Text('Create Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (_draft.sourceOrderNumber != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text('From warehouse order: ${_draft.sourceOrderNumber}', style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
            ),
          _section('Customer', [
            Obx(() {
              return DropdownButtonFormField<String>(
                value: _draft.customerId,
                decoration: const InputDecoration(
                  labelText: 'Select warehouse customer *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.controller.customers.map((c) {
                  final id = (c['id'] ?? c['_id'])?.toString() ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text('${c['name'] ?? 'Customer'}${c['email'] != null ? ' • ${c['email']}' : ''}'),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _draft.customerId = v;
                    if (v != null) {
                      final match = widget.controller.customers.firstWhere(
                        (c) => (c['id'] ?? c['_id'])?.toString() == v,
                        orElse: () => {},
                      );
                      _draft.customerName = match['name']?.toString();
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _draft.customerName,
              decoration: const InputDecoration(
                labelText: 'Customer name (if not in list)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _draft.customerName = v.trim(),
            ),
          ]),
          const SizedBox(height: 12),
          _section('Invoice Dates', [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Issue date', style: TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_draft.issueDate)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () => _pickDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date', style: TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_draft.dueDate)),
                    trailing: const Icon(Icons.event, size: 18),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          _section('Line Items', [
            TextField(
              controller: _productSearchCtrl,
              decoration: InputDecoration(
                labelText: 'Add product from warehouse catalog',
                hintText: 'Search name or SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loadingProducts ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _searchProducts,
            ),
            if (_productResults.isNotEmpty)
              ..._productResults.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${p['sku']} • ${_format((p['sellingPrice'] as num?)?.toDouble() ?? 0)}'),
                    trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addProduct(p)),
                  )),
            const SizedBox(height: 8),
            ...List.generate(_draft.lines.length, (index) => _lineCard(index)),
            if (_draft.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No line items yet', style: TextStyle(color: kSubText, fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 12),
          _section('Totals', [
            _totalRow('Subtotal', _format(_draft.subtotal)),
            _totalRow('Tax', _format(_draft.taxTotal)),
            TextField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Discount', border: OutlineInputBorder(), isDense: true),
              onChanged: (_) => setState(() => _draft.discount = double.tryParse(_discountCtrl.text) ?? 0),
            ),
            const Divider(),
            _totalRow('Grand Total', _format(_draft.grandTotal), bold: true),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes / Terms', border: OutlineInputBorder()),
            ),
          ]),
          const SizedBox(height: 20),
          Obx(() => ElevatedButton(
                onPressed: widget.controller.isSubmitting.value ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: widget.controller.isSubmitting.value
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Create Invoice', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              )),
        ],
      ),
    );
  }

  Widget _lineCard(int index) {
    final line = _draft.lines[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(line.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _removeLine(index)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '${line.quantity}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => line.quantity = int.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: line.unitPrice.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit price', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => line.unitPrice = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: line.taxRate.toStringAsFixed(1),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tax %', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => line.taxRate = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Line total: ${_format(line.lineTotal)}', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}