// lib/core/warehouse/purchase_payment/views/purchase_payment_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_controller.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PurchasePaymentScreen extends StatelessWidget {
  const PurchasePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchasePaymentController());

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Purchase Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: controller.refreshPayments,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.showCreateForm.value) {
          return PurchasePaymentCreateForm(
            controller: controller,
            onCancel: controller.closeCreateForm,
          );
        }

        return Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _PaymentListView(
                  controller: controller,
                  onCreate: controller.openCreateForm,
                  onView: (item) => _showDetail(context, controller, item),
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(
        () => controller.showCreateForm.value
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: controller.openCreateForm,
                backgroundColor: kPrimary,
                elevation: 2,
                child: const Icon(Icons.payment, color: Colors.white, size: 24),
              ),
      ),
    );
  }

  Widget _buildTopHeader(PurchasePaymentController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Purchase Payments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalRecords.value} payments',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _compactKpi(
                              'Today',
                              controller.formatCurrency(
                                controller.stats.value.todayAmount,
                              ),
                              Colors.green.shade200,
                            ),
                            const SizedBox(width: 8),
                            _compactKpi(
                              'Month',
                              controller.formatCurrency(
                                controller.stats.value.monthAmount,
                              ),
                              Colors.lightBlue.shade100,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshPayments,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _SearchField(controller: controller),
              ),
            ),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    _filterChip(
                      'All',
                      controller.selectedFilter.value == 'all',
                      () => controller.filterPayments('all'),
                    ),
                    _filterChip(
                      'Completed',
                      controller.selectedFilter.value == 'Completed',
                      () => controller.filterPayments('Completed'),
                    ),
                    _filterChip(
                      'Pending',
                      controller.selectedFilter.value == 'Pending',
                      () => controller.filterPayments('Pending'),
                    ),
                    _filterChip(
                      'Cancelled',
                      controller.selectedFilter.value == 'Cancelled',
                      () => controller.filterPayments('Cancelled'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? kPrimary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    PurchasePaymentController controller,
    PurchasePaymentModel item,
  ) {
    controller.selectPayment(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _PaymentDetailSheet(
                    controller: controller,
                    paymentItem: item,
                    onClose: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEARCH FIELD
// ═══════════════════════════════════════════════════════════════

class _SearchField extends StatefulWidget {
  final PurchasePaymentController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() {});
        v.isEmpty
            ? widget.controller.clearSearch()
            : widget.controller.searchPayments(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search payments...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  widget.controller.clearSearch();
                  setState(() {});
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE PAYMENT FORM
// ═══════════════════════════════════════════════════════════════

class PurchasePaymentCreateForm extends StatelessWidget {
  final PurchasePaymentController controller;
  final VoidCallback onCancel;
  final VoidCallback? onSuccess;

  const PurchasePaymentCreateForm({
    super.key,
    required this.controller,
    required this.onCancel,
    this.onSuccess,
  });

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Make Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildFormContent(context),
              ),
            ),
            _buildActionButtons(context),
          ],
        );
      }),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Supplier Section ─────────────────────────────────
        _section('Supplier', [
          if (!controller.lockSupplier.value) ...[
            TextField(
              controller: controller.supplierSearchController,
              decoration: const InputDecoration(
                hintText: 'Search supplier by name, email, phone...',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: controller.searchSuppliers,
            ),
            if (controller.isSearchingSuppliers.value)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ...controller.supplierSearchResults.map(_supplierTile),
          ],
          if (controller.selectedSupplier.value != null)
            _selectedSupplierCard(controller.selectedSupplier.value!),
        ]),

        const SizedBox(height: 16),

        // ─── Invoices Section ──────────────────────────────────
        if (controller.selectedSupplier.value != null) ...[
          _section('Select Invoices', [
            if (controller.isLoadingInvoices.value)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (controller.availableInvoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No unpaid invoices found for this supplier',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...controller.availableInvoices.map((invoice) {
                final isSelected = controller.selectedInvoices.any(
                  (inv) => inv.id == invoice.id,
                );
                return _invoiceTile(invoice, isSelected);
              }),
          ]),
          const SizedBox(height: 16),
        ],

        // ─── Payment Details Section ──────────────────────────
        if (controller.selectedInvoices.isNotEmpty) ...[
          _section('Payment Details', [
            // Payment Date
            TextField(
              controller: controller.paymentDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Payment Date *',
                suffixIcon: Icon(Icons.calendar_today, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onTap: () => controller.selectPaymentDate(context),
            ),
            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<String>(
              value: controller.paymentMethod.value,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Payment Method *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: PurchasePaymentController.paymentMethods
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(
                        method,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.paymentMethod.value = value;
                  if (value == 'Cash') {
                    controller.selectedBankAccount.value = null;
                  }
                }
              },
            ),
            const SizedBox(height: 12),

            // Bank Account (required for non-cash methods)
            if (controller.paymentMethod.value != 'Cash') ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                value: controller.selectedBankAccount.value,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Bank Account *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                items: controller.bankAccounts.map((account) {
                  final name =
                      (account['accountName'] ??
                              account['name'] ??
                              'Account')
                          .toString();
                  final bank = (account['bankName'] ?? '').toString();
                  final label = bank.isEmpty ? name : '$name - $bank';
                  return DropdownMenuItem(
                    value: account,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) {
                  return controller.bankAccounts.map((account) {
                    final name =
                        (account['accountName'] ??
                                account['name'] ??
                                'Account')
                            .toString();
                    final bank = (account['bankName'] ?? '').toString();
                    final label = bank.isEmpty ? name : '$name - $bank';
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList();
                },
                onChanged: (value) {
                  controller.selectedBankAccount.value = value;
                },
              ),
              const SizedBox(height: 12),
            ],

            // Amount
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount *',
                prefixIcon: Icon(Icons.currency_rupee, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: (v) {
                // Update total if manually edited
                final amount = double.tryParse(v) ?? 0;
                if (amount > 0) {
                  // Distribute amount proportionally or keep as is
                }
              },
            ),
            const SizedBox(height: 12),

            // Reference
            TextField(
              controller: controller.referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: controller.notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ─── Summary ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryRow(
                  'Supplier',
                  controller.selectedSupplier.value?['name'] ?? '',
                ),
                _summaryRow(
                  'Invoices',
                  '${controller.selectedInvoices.length} invoices',
                ),
                _summaryRow('Payment Method', controller.paymentMethod.value),
                const Divider(),
                _summaryRow(
                  'Total Amount',
                  _format(controller.selectedTotalAmount),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _supplierTile(Map<String, dynamic> supplier) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        supplier['name'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(supplier['email'] ?? supplier['phone'] ?? ''),
      trailing: Icon(Icons.chevron_right, color: kSubText),
      onTap: () => controller.selectSupplier(supplier),
    );
  }

  Widget _selectedSupplierCard(Map<String, dynamic> supplier) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
            supplier['name'] ?? '',
            style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
          ),
          if (supplier['email'] != null) Text(supplier['email']),
          if (supplier['phone'] != null) Text(supplier['phone']),
          Text('Company: ${supplier['companyName'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _invoiceTile(PurchaseInvoiceForPayment invoice, bool isSelected) {
    final color = invoice.isOverdue ? Colors.red : Colors.blue;
    final canPay = invoice.payable;

    return Opacity(
      opacity: canPay ? 1 : 0.75,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? kPrimary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: !canPay
              ? Colors.orange.withOpacity(0.45)
              : isSelected
                  ? kPrimary
                  : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => controller.toggleInvoiceSelection(invoice),
                  activeColor: kPrimary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice.isDraft
                            ? 'Not payable'
                            : '${invoice.paymentStatus.isNotEmpty ? invoice.paymentStatus : invoice.invoiceStatus}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: invoice.isDraft
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                        ),
                      ),
                      if (invoice.supplierInvoiceNo != null)
                        Text(
                          'Supplier Inv: ${invoice.supplierInvoiceNo}',
                          style: TextStyle(fontSize: 10, color: kSubText),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(invoice.dueDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: invoice.isOverdue ? Colors.red : kSubText,
                          fontWeight: invoice.isOverdue
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _format(invoice.outstanding),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    if (invoice.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (isSelected && canPay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: invoice.amountToPay.toStringAsFixed(2),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount to Pay',
                        prefixIcon: Icon(Icons.currency_rupee, size: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final amount = double.tryParse(v) ?? 0;
                        controller.updateInvoiceAmount(invoice, amount);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      controller.updateInvoiceAmount(
                        invoice,
                        invoice.outstanding,
                      );
                    },
                    child: const Text('Full'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? kPrimary : kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Cancel',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kSubText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    controller.isSubmitting.value || !controller.canMakePayment
                    ? null
                    : () async {
                        final ok = await controller.makePayment();
                        if (ok) onSuccess?.call();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'Make Payment',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT DETAIL SHEET
// ═══════════════════════════════════════════════════════════════

class _PaymentDetailSheet extends StatefulWidget {
  final PurchasePaymentController controller;
  final PurchasePaymentModel paymentItem;
  final VoidCallback onClose;

  const _PaymentDetailSheet({
    required this.controller,
    required this.paymentItem,
    required this.onClose,
  });

  @override
  State<_PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends State<_PaymentDetailSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current =
          widget.controller.payments.firstWhereOrNull(
            (p) => p.id == widget.paymentItem.id,
          ) ??
          widget.paymentItem;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _statusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.payment,
                  color: _statusColor(current.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.paymentNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Payment Made to Supplier',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  current.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(current.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 16),
          _detailRow('Supplier', current.supplierName),
          _detailRow(
            'Date',
            DateFormat('dd MMM yyyy').format(current.paymentDate),
          ),
          _detailRow('Method', current.paymentMethod),
          if (current.bankAccountId != null &&
              current.bankAccountName.isNotEmpty)
            _detailRow('Bank Account', current.bankAccountName),
          if (current.reference.isNotEmpty)
            _detailRow('Reference', current.reference),
          if (current.notes.isNotEmpty) _detailRow('Notes', current.notes),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoices Paid',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                '${current.totalInvoices} invoices',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...current.invoicePayments.map(
            (inv) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.06)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (inv.invoice != null)
                          Text(
                            'Total: ${_format(inv.invoice!.grandTotal)}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _format(inv.amountPaid),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  _format(current.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: kSuccess,
                  ),
                ),
              ],
            ),
          ),
          if (current.journalEntry != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, size: 16, color: kSubText),
                      const SizedBox(width: 8),
                      Text(
                        'Journal Entry: ${current.journalEntry!.entryNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSubText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...current.journalEntry!.lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              line.accountName,
                              style: TextStyle(fontSize: 11, color: kSubText),
                            ),
                          ),
                          if (line.debit > 0)
                            Text(
                              'Dr ${_format(line.debit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          if (line.credit > 0)
                            Text(
                              'Cr ${_format(line.credit)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (current.canCancel) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.cancelPayment(
                              current.id,
                            );
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel Payment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (current.canDelete) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await widget.controller.deletePayment(
                          current.id,
                        );
                        if (ok) widget.onClose();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: Colors.grey.shade300),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600, color: kSubText),
            ),
          ),
        ],
      );
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _PaymentListView extends StatelessWidget {
  final PurchasePaymentController controller;
  final VoidCallback onCreate;
  final ValueChanged<PurchasePaymentModel> onView;

  const _PaymentListView({
    required this.controller,
    required this.onCreate,
    required this.onView,
  });

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.payments.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final payments = controller.filteredPayments;

      if (payments.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.payment_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No payments yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to make payment',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                label: const Text(
                  'Make Payment',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final item = payments[index];
          final color = _statusColor(item.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onView(item),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.isCompleted ? Icons.check_circle : Icons.payment,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.paymentNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: kPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _format(item.amount),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.supplierName,
                              style: TextStyle(fontSize: 12, color: kText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.totalInvoices} inv',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple.shade800,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(item.paymentDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
