import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/Sales/controller/sales_credit_controller.dart';
import 'package:BisonsTechs_app/core/Sales/model/sales_credit_model.dart';
import 'package:BisonsTechs_app/widgets/sales_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Sales Credits — invoice-linked flow (like Sales Payments):
/// Customer → select invoice → issue credit → apply to invoice → AR/GL.
class SalesCreditsScreen extends StatelessWidget {
  const SalesCreditsScreen({super.key});

  static const routeName = '/sales/credits';

  @override
  Widget build(BuildContext context) {
    final perms = PermissionService.to;
    if (!perms.isAdmin && !perms.hasSubPageAccess('sales', 'credits')) {
      return Scaffold(
        backgroundColor: kBgLight,
        appBar: AppBar(
          title: const Text('Sales Credits'),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'You do not have permission to access Sales Credits.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Keep one controller instance for this route; avoid dispose races on rebuild.
    final controller = Get.isRegistered<SalesCreditController>()
        ? Get.find<SalesCreditController>()
        : Get.put(SalesCreditController());
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: kBgLight,
      drawer: isMobile
          ? const SalesDrawer(currentRoute: SalesCreditsScreen.routeName)
          : null,
      body: Obx(() {
        if (controller.showCreateForm.value) {
          return _CreateCreditForm(
            controller: controller,
            onCancel: controller.closeCreateForm,
          );
        }
        if (controller.showApplyForm.value) {
          return _ApplyCreditForm(
            controller: controller,
            onCancel: controller.closeApplyForm,
          );
        }
        return Column(
          children: [
            _ListHeader(controller: controller, isMobile: isMobile),
            Expanded(child: _CreditList(controller: controller)),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.showCreateForm.value || controller.showApplyForm.value) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: controller.openCreateForm,
          backgroundColor: kPrimary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Credit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIST HEADER
// ═══════════════════════════════════════════════════════════════

class _ListHeader extends StatelessWidget {
  final SalesCreditController controller;
  final bool isMobile;

  const _ListHeader({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Get.back();
                      } else {
                        Get.offNamed('/warehouse/sales');
                      }
                    },
                  ),
                  if (isMobile)
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Colors.white),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Sales Credits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Obx(() {
                      final s = controller.summary.value;
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _kpi(
                              'Issued',
                              controller.formatCurrency(s.totalAmount),
                            ),
                            const SizedBox(width: 10),
                            _kpi(
                              'Unapplied',
                              controller.formatCurrency(s.remainingAmount),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: controller.refreshAll,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search credit #, customer, invoice...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: controller.filters.map((f) {
                    final selected = controller.selectedFilter.value == f;
                    final label = f == 'all'
                        ? 'All'
                        : f == 'PartiallyApplied'
                            ? 'Partial'
                            : f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => controller.filterCredits(f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
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
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
}

// ═══════════════════════════════════════════════════════════════
// LIST
// ═══════════════════════════════════════════════════════════════

class _CreditList extends StatelessWidget {
  final SalesCreditController controller;
  const _CreditList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.credits.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
        );
      }
      final list = controller.filteredCredits;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No sales credits yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a credit against a sales invoice\n(same flow as receiving payment)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: kPrimary,
        onRefresh: controller.refreshAll,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _CreditCard(
            credit: list[i],
            controller: controller,
          ),
        ),
      );
    });
  }
}

class _CreditCard extends StatelessWidget {
  final SalesCredit credit;
  final SalesCreditController controller;

  const _CreditCard({required this.credit, required this.controller});

  Color get _statusColor {
    switch (credit.status) {
      case 'Applied':
        return kSuccess;
      case 'PartiallyApplied':
        return kWarning;
      case 'Voided':
      case 'Expired':
      case 'Cancelled':
        return kDanger;
      default:
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      credit.creditNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      credit.status == 'PartiallyApplied'
                          ? 'Partial'
                          : credit.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                credit.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Invoice ${credit.originalInvoiceNumber} · ${credit.reasonType}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _amt('Amount', controller.formatCurrency(credit.amount)),
                  _amt(
                    'Remaining',
                    controller.formatCurrency(credit.remainingAmount),
                  ),
                  Text(
                    dateFmt.format(credit.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              if (credit.canApply) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.openApplyForm(credit),
                    icon: const Icon(Icons.playlist_add_check, size: 16),
                    label: const Text('Apply to Invoice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amt(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              credit.creditNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _row('Customer', credit.customerName),
            _row('Invoice', credit.originalInvoiceNumber),
            _row('Reason', '${credit.reasonType} — ${credit.reason}'),
            _row('Amount', controller.formatCurrency(credit.amount)),
            _row('Applied', controller.formatCurrency(credit.appliedAmount)),
            _row('Remaining', controller.formatCurrency(credit.remainingAmount)),
            _row('Status', credit.status),
            if (credit.notes.isNotEmpty) _row('Notes', credit.notes),
            const SizedBox(height: 16),
            if (credit.canApply)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.openApplyForm(credit);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  child: const Text(
                    'Apply to Invoice',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (credit.status == 'Issued' || credit.status == 'PartiallyApplied')
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final ok = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Void credit?'),
                      content: Text('Void ${credit.creditNumber}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('Void', style: TextStyle(color: kDanger)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) controller.voidCredit(credit);
                },
                child: const Text('Void credit', style: TextStyle(color: kDanger)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE FORM (payment-style)
// ═══════════════════════════════════════════════════════════════

class _CreateCreditForm extends StatelessWidget {
  final SalesCreditController controller;
  final VoidCallback onCancel;

  const _CreateCreditForm({required this.controller, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onCancel,
        ),
        title: const Text(
          'Issue Sales Credit',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hintBanner(),
                    const SizedBox(height: 14),
                    _section('1. Customer', [
                      TextField(
                        controller: controller.customerSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search customer...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          isDense: true,
                        ),
                        onChanged: controller.searchCustomers,
                      ),
                      if (controller.isSearchingCustomers.value)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ...controller.customerSearchResults.map(_customerTile),
                      if (controller.selectedCustomer.value != null)
                        _selectedChip(
                          controller.selectedCustomer.value!['name']?.toString() ??
                              '',
                          Icons.person,
                        ),
                    ]),
                    if (controller.selectedCustomer.value != null) ...[
                      const SizedBox(height: 14),
                      _section('2. Select Invoice', [
                        if (controller.isLoadingInvoices.value)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (controller.availableInvoices.isEmpty)
                          const Text(
                            'No unpaid sales invoices for this customer.\nCreate a Sales Invoice first (same as Payments).',
                            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.35),
                          )
                        else
                          ...controller.availableInvoices.map(_invoiceTile),
                      ]),
                    ],
                    if (controller.selectedInvoice.value != null) ...[
                      const SizedBox(height: 14),
                      _section('3. Credit Details', [
                        DropdownButtonFormField<String>(
                          value: controller.reasonType.value,
                          decoration: const InputDecoration(
                            labelText: 'Reason type *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            isDense: true,
                          ),
                          items: SalesCreditController.reasonTypes
                              .map(
                                (t) => DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) controller.onReasonTypeChanged(v);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller.reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller.amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Credit amount *',
                            helperText:
                                'Max eligible: ${controller.formatCurrency(controller.selectedInvoice.value!.eligibleCredit)}',
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller.notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ]),
                      if (['Return', 'Damaged Goods']
                          .contains(controller.reasonType.value)) ...[
                        const SizedBox(height: 14),
                        _section('4. Return quantities', [
                          ...List.generate(controller.lineItems.length, (i) {
                            final item = controller.lineItems[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'Qty ${item.quantity} · ${controller.formatCurrency(item.unitPrice)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: item.returnQty > 0
                                          ? () => controller.setReturnQty(
                                              i,
                                              item.returnQty - 1,
                                            )
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    ),
                                    Text(
                                      '${item.returnQty}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: item.returnQty < item.quantity
                                          ? () => controller.setReturnQty(
                                              i,
                                              item.returnQty + 1,
                                            )
                                          : null,
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ]),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            _bottomBar(
              enabled: controller.canCreateCredit && !controller.isSubmitting.value,
              loading: controller.isSubmitting.value,
              label: 'Issue Credit',
              onPressed: () => controller.createCredit(),
            ),
          ],
        );
      }),
    );
  }

  Widget _hintBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: const Text(
        'Same pattern as Sales Payments: pick customer → invoice → amount. '
        'Posts contra-revenue / AR journal and updates the invoice balance.',
        style: TextStyle(fontSize: 11, height: 1.35),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _customerTile(Map<String, dynamic> c) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.person_outline, size: 20),
      title: Text(c['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        c['email']?.toString() ?? c['phone']?.toString() ?? '',
        style: const TextStyle(fontSize: 11),
      ),
      onTap: () => controller.selectCustomer(c),
    );
  }

  Widget _selectedChip(String name, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSuccess.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccess.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const Icon(Icons.check_circle, color: kSuccess, size: 18),
        ],
      ),
    );
  }

  Widget _invoiceTile(SalesCreditInvoice inv) {
    final selected = controller.selectedInvoice.value?.id == inv.id;
    return GestureDetector(
      onTap: () => controller.selectInvoice(inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kPrimary : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? kPrimary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                  '${DateFormat('dd MMM yyyy').format(inv.date)} · ${inv.status}'
                  '${inv.invoiceSource == 'sales' ? ' · Sales' : ''}'
                  '${inv.outstanding > 0 ? ' · Due ${controller.formatCurrency(inv.outstanding)}' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatCurrency(inv.eligibleCredit),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Eligible',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar({
    required bool enabled,
    required bool loading,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// APPLY FORM
// ═══════════════════════════════════════════════════════════════

class _ApplyCreditForm extends StatelessWidget {
  final SalesCreditController controller;
  final VoidCallback onCancel;

  const _ApplyCreditForm({required this.controller, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final credit = controller.selectedCredit.value;
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onCancel,
        ),
        title: Text(
          'Apply ${credit?.creditNumber ?? 'Credit'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (credit != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              credit.customerName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remaining: ${controller.formatCurrency(credit.remainingAmount)}',
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select invoice to apply',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (controller.isLoadingApplyInvoices.value)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else if (controller.applyInvoices.isEmpty)
                      const Text(
                        'No unpaid invoices to apply against',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...controller.applyInvoices.map((inv) {
                        final selected = controller.applyInvoice.value?.id == inv.id;
                        return GestureDetector(
                          onTap: () => controller.selectApplyInvoice(inv),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? kPrimary.withOpacity(0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? kPrimary : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected ? kPrimary : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    inv.invoiceNumber,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  controller.formatCurrency(inv.outstanding),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    if (controller.applyInvoice.value != null) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller.applyAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount to apply *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.canApplyCredit &&
                            !controller.isSubmitting.value
                        ? () => controller.applyCredit()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Apply Credit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
