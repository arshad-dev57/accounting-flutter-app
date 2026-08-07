import 'dart:async';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/screen/product_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
        TextField(
          decoration: InputDecoration(
            hintText: 'Search invoices...',
            hintStyle: TextStyle(color: kSubText, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: kSubText, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: kCardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: controller.applySearch,
        ),
        const SizedBox(height: 12),

        // Invoice type: All / Sales / Purchase
        Obx(() {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WarehouseInvoiceController.invoiceTypeFilters.map((
                filter,
              ) {
                final isSelected = controller.invoiceTypeFilter.value == filter;
                final label = filter == 'all'
                    ? 'All'
                    : (filter == 'sales' ? 'Sales' : 'Purchase');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => controller.applyInvoiceTypeFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary : kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? kPrimary
                              : Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : kSubText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 10),

        // ✅ FIXED Filter Chips
        Obx(() {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WarehouseInvoiceController.statusFilters.map((filter) {
                final isSelected = controller.statusFilter.value == filter;
                final label = filter == 'all' ? 'All Status' : filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => controller.applyStatusFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary : kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? kPrimary
                              : Colors.grey.withOpacity(0.25),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : kSubText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 12),

        // Amount summary: Total / Paid / Unpaid
        Obx(() {
          final s = controller.stats.value;
          final fmt = NumberFormat('#,##0.00');
          return Row(
            children: [
              Expanded(
                child: _amountSummaryCard(
                  'Total',
                  fmt.format(s.grandTotal),
                  '${s.total} invoices',
                  kPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _amountSummaryCard(
                  'Paid',
                  fmt.format(s.paidAmount),
                  '${s.paid} paid',
                  kSuccess,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _amountSummaryCard(
                  'Unpaid',
                  fmt.format(s.outstanding),
                  '${s.unpaid + s.partial} open',
                  kDanger,
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 10),

        // Status count chips
        Obx(() {
          final s = controller.stats.value;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statChip('All', s.total, kPrimary),
                _statChip('Unpaid', s.unpaid, Colors.orange),
                _statChip('Partial', s.partial, Colors.blue),
                _statChip('Paid', s.paid, kSuccess),
                _statChip('Overdue', s.overdue, kDanger),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Create Invoice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onImportOrder,
                icon: Icon(Icons.download, size: 16, color: kPrimary),
                label: Text(
                  'From Order',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
              return Center(child: CircularProgressIndicator(color: kPrimary));
            }
            if (controller.invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: kSubText.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No invoices found',
                      style: TextStyle(
                        color: kSubText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first invoice',
                      style: TextStyle(
                        color: kSubText.withOpacity(0.6),
                        fontSize: 12,
                      ),
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
                  onPressed: controller.hasPrev.value
                      ? () => controller.goToPage(
                          controller.currentPage.value - 1,
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${controller.currentPage.value} / ${controller.totalPages.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.hasNext.value
                      ? () => controller.goToPage(
                          controller.currentPage.value + 1,
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _amountSummaryCard(
    String label,
    String amount,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 9, color: kSubText)),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(WarehouseInvoiceModel invoice) {
    final controller = Get.find<WarehouseInvoiceController>();
    final color = controller.statusColor(invoice);
    final status = invoice.invoiceStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.selectedInvoice.value = invoice,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Invoice icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_outlined,
                      color: kPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                invoice.invoiceNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: invoice.isPurchase
                                    ? const Color(0xFF7C3AED).withOpacity(0.1)
                                    : kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                invoice.isPurchase ? 'Purchase' : 'Sales',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: invoice.isPurchase
                                      ? const Color(0xFF7C3AED)
                                      : kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.customerName,
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
              const SizedBox(height: 10),
              // Financial summary row
              Row(
                children: [
                  Expanded(
                    child: _invoiceMetric(
                      'Total',
                      invoice.grandTotal.toStringAsFixed(2),
                      kText,
                    ),
                  ),
                  Expanded(
                    child: _invoiceMetric(
                      'Paid',
                      invoice.paidAmount.toStringAsFixed(2),
                      kSuccess,
                    ),
                  ),
                  Expanded(
                    child: _invoiceMetric(
                      'Credit',
                      invoice.creditIssued.toStringAsFixed(2),
                      kWarning,
                    ),
                  ),
                  Expanded(
                    child: _invoiceMetric(
                      'Outstanding',
                      invoice.outstanding.toStringAsFixed(2),
                      invoice.outstanding < 0
                          ? kSuccess
                          : (invoice.outstanding > 0 ? kDanger : kSuccess),
                    ),
                  ),
                ],
              ),
              if (invoice.displayStatus == 'Credit Balance') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Credit Balance',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kSuccess,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: kSubText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                    ],
                  ),
                  Text(
                    invoice.displayStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: invoice.outstanding < 0 ? kSuccess : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: kSubText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
    final statusColor = controller.statusColor(invoice);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.selectedInvoice.value = null,
        ),
        actions: [
          if (!invoice.isPurchase && (invoice.isUnpaid || invoice.isPartial))
            IconButton(
              icon: const Icon(Icons.payment, color: Colors.white),
              onPressed: () => _showPaymentDialog(controller, invoice),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── INVOICE PAPER ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: Logo + Status ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.12),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo placeholder
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kPrimary.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            'Your Logo',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Status + type badges
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: invoice.isPurchase
                                    ? const Color(0xFF7C3AED).withOpacity(0.12)
                                    : kPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                invoice.isPurchase ? 'PURCHASE' : 'SALES',
                                style: TextStyle(
                                  color: invoice.isPurchase
                                      ? const Color(0xFF7C3AED)
                                      : kPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                invoice.invoiceStatus.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── FROM / TO ──
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Your Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your details:',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'FROM',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'BisonsTechs',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Warehouse Management',
                                style: TextStyle(color: kSubText, fontSize: 11),
                              ),
                              Text(
                                'Business Address',
                                style: TextStyle(color: kSubText, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Container(
                          width: 1,
                          height: 100,
                          color: Colors.grey.withOpacity(0.15),
                        ),
                        const SizedBox(width: 16),
                        // Client Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.isPurchase
                                    ? 'Supplier details:'
                                    : 'Client\'s details:',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.isPurchase ? 'FROM' : 'TO',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 9,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                invoice.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (invoice.customerEmail != null)
                                Text(
                                  invoice.customerEmail!,
                                  style: TextStyle(
                                    color: kSubText,
                                    fontSize: 11,
                                  ),
                                ),
                              if (invoice.customerPhone != null)
                                Text(
                                  invoice.customerPhone!,
                                  style: TextStyle(
                                    color: kSubText,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Invoice Meta ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice No',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.invoiceNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice Date',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd MMM, yyyy',
                                ).format(invoice.invoiceDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd MMM, yyyy',
                                ).format(invoice.dueDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: invoice.isOverdue ? kDanger : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Items Table Header ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ITEM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            'QTY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'RATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'SUBTOTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Items ──
                  ...invoice.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isEven = i % 2 == 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : Colors.grey.withOpacity(0.04),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (item.description != null &&
                                    item.description!.isNotEmpty &&
                                    item.description != item.productName)
                                  Text(
                                    item.description!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: kSubText,
                                    ),
                                  ),
                                if (item.sku != null && item.sku!.isNotEmpty)
                                  Text(
                                    'SKU: ${item.sku}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: kSubText.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              item.unitPrice.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              item.totalPrice.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // ── Invoice Summary ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      width: 260,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.08),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Invoice Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rows
                          _summaryRow('Subtotal', invoice.subtotal),
                          if (invoice.taxTotal > 0)
                            _summaryRow('Tax', invoice.taxTotal),
                          if (invoice.discountTotal > 0)
                            _summaryRow('Discount', -invoice.discountTotal),
                          Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          _summaryRow(
                            'Total',
                            invoice.grandTotal,
                            bold: true,
                            color: kPrimary,
                          ),
                          if (invoice.paidAmount > 0)
                            _summaryRow(
                              'Paid',
                              invoice.paidAmount,
                              color: kSuccess,
                            ),
                          if (invoice.creditIssued > 0)
                            _summaryRow(
                              'Credit Issued',
                              invoice.creditIssued,
                              color: kWarning,
                            ),
                          _summaryRow(
                            invoice.outstanding < 0
                                ? 'Credit Balance'
                                : 'Outstanding',
                            invoice.outstanding.abs(),
                            bold: true,
                            color: invoice.outstanding < 0 ? kSuccess : kDanger,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  // Notes
                  if (invoice.notes != null && invoice.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                invoice.notes!,
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Footer line
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 4,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Action Buttons (sales invoices only) ──
            const SizedBox(height: 20),
            if (!invoice.isPurchase && (invoice.isUnpaid || invoice.isPartial))
              ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(controller, invoice),
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text(
                  'Record Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            if (!invoice.isPurchase &&
                !invoice.isPaid &&
                !invoice.isCancelled) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showDeleteConfirm(controller, invoice),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Invoice',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: kSubText,
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    WarehouseInvoiceController controller,
    WarehouseInvoiceModel invoice,
  ) {
    final amountCtrl = TextEditingController(
      text: invoice.outstanding.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: kSuccess, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Record Payment',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice: ${invoice.invoiceNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Outstanding: ${invoice.outstanding.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: kDanger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: kSuccess,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Record',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    WarehouseInvoiceController controller,
    WarehouseInvoiceModel invoice,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Invoice',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}? This action cannot be undone.',
          style: TextStyle(color: kSubText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteInvoice(invoice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFromOrder(
    BuildContext context,
    WarehouseInvoiceController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        controller.fetchBillableOrders();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return Obx(() {
                final orders = controller.billableOrders;
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined, color: kPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Select Order to Create Invoice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                    Expanded(
                      child: orders.isEmpty
                          ? Center(
                              child: Text(
                                'No billable orders found',
                                style: TextStyle(color: kSubText),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: orders.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: kCardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.12),
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      final draft = controller.draftFromOrder(
                                        order,
                                      );
                                      Navigator.pop(context);
                                      _orderDraft = draft;
                                      controller.openCreateForm();
                                    },
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: kPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        color: kPrimary,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      order.customerName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kSubText,
                                      ),
                                    ),
                                    trailing: Text(
                                      order.subtotal.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              });
            },
          ),
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
  State<CreateWarehouseInvoiceForm> createState() =>
      _CreateWarehouseInvoiceFormState();
}

class _CreateWarehouseInvoiceFormState
    extends State<CreateWarehouseInvoiceForm> {
  late InvoiceDraft _draft;
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final _productSearchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _productResults = [];
  bool _loadingProducts = false;
  Timer? _debounce;

  String _format(double v) => v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initialDraft ??
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
          // Header
          Row(
            children: [
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: kCardBg),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Create Invoice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // From order banner
          if (_draft.sourceOrderNumber != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'From warehouse order: ${_draft.sourceOrderNumber}',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          _section('Customer', [
            Obx(() {
              return DropdownButtonFormField<String>(
                value: _draft.customerId,
                decoration: InputDecoration(
                  labelText: 'Select warehouse customer *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                items: widget.controller.customers.map((c) {
                  final id = (c['id'] ?? c['_id'])?.toString() ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(
                      '${c['name'] ?? 'Customer'}${c['email'] != null ? ' • ${c['email']}' : ''}',
                    ),
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
              decoration: InputDecoration(
                labelText: 'Customer name (if not in list)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                  child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: kPrimary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Issue date',
                                style: TextStyle(fontSize: 10, color: kSubText),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(_draft.issueDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 16, color: kPrimary),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due date',
                                style: TextStyle(fontSize: 10, color: kSubText),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(_draft.dueDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 12),

          _section('Line Items', [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _productSearchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Add product from warehouse catalog',
                      hintText: 'Search name or SKU...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _loadingProducts
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    onChanged: _searchProducts,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Go to Products',
                  child: InkWell(
                    onTap: () => Get.to(() => const ProductsScreen()),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_productResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: _productResults
                      .map(
                        (p) => ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          title: Text(
                            p['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${p['sku']} • ${_format((p['sellingPrice'] as num?)?.toDouble() ?? 0)}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle, color: kPrimary),
                            onPressed: () => _addProduct(p),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            ...List.generate(_draft.lines.length, (index) => _lineCard(index)),
            if (_draft.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 36,
                        color: kSubText.withOpacity(0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No line items yet',
                        style: TextStyle(color: kSubText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),

          _section('Totals', [
            _totalRow('Subtotal', _format(_draft.subtotal)),
            _totalRow('Tax', _format(_draft.taxTotal)),
            const SizedBox(height: 8),
            TextField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Discount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(
                () =>
                    _draft.discount = double.tryParse(_discountCtrl.text) ?? 0,
              ),
            ),
            const Divider(height: 20),
            _totalRow('Grand Total', _format(_draft.grandTotal), bold: true),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes / Terms',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.isSubmitting.value ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.controller.isSubmitting.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create Invoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _lineCard(int index) {
    final line = _draft.lines[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeLine(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '${line.quantity}',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => line.quantity = int.tryParse(v) ?? 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: line.unitPrice.toStringAsFixed(2),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Unit price',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) => setState(
                      () => line.unitPrice = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: line.taxRate.toStringAsFixed(1),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tax %',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => line.taxRate = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line total: ${_format(line.lineTotal)}',
                style: TextStyle(
                  fontSize: 12,
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
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
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: kSubText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
