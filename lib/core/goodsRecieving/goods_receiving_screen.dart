// lib/core/warehouse/goods_receiving/views/goods_receiving_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/goodsRecieving/goods_receiving_controller.dart';
import 'package:LedgerPro_app/core/goodsRecieving/goods_receiving_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GoodsReceivingScreen extends StatelessWidget {
  const GoodsReceivingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GoodsReceivingController());

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text(
          'Goods Receiving',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: controller.refreshGRNs,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.showCreateWizard.value) {
          return _CreateGRNWizard(
            controller: controller,
            onCancel: controller.closeCreateWizard,
          );
        }

        return Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _GRNListView(
                  controller: controller,
                  onCreate: controller.openCreateWizard,
                  onView: (item) => _showDetail(context, controller, item),
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreateWizard,
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildTopHeader(GoodsReceivingController controller) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goods Receiving',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.totalRecords.value} GRNs',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Obx(() => Row(
                    children: [
                      _compactKpi('Draft', controller.stats.value.draftCount.toString(), Colors.orange.shade800),
                      const SizedBox(width: 6),
                      _compactKpi('Partial', controller.stats.value.partiallyReceivedCount.toString(), Colors.blue.shade800),
                      const SizedBox(width: 6),
                      _compactKpi('Received', controller.stats.value.fullyReceivedCount.toString(), Colors.green.shade800),
                    ],
                  )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshGRNs,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.refresh_rounded, size: 17, color: Colors.black.withOpacity(0.65)),
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
            Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _filterChip('All', controller.selectedFilter.value == 'all', () => controller.filterGRNs('all')),
                  _filterChip('Draft', controller.selectedFilter.value == 'Draft', () => controller.filterGRNs('Draft')),
                  _filterChip('Partial', controller.selectedFilter.value == 'Partially Received', () => controller.filterGRNs('Partially Received')),
                  _filterChip('Received', controller.selectedFilter.value == 'Fully Received', () => controller.filterGRNs('Fully Received')),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w600)),
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
            color: selected ? Colors.black : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.black : Colors.white.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, GoodsReceivingController controller, GoodsReceivingModel item) {
    controller.selectGRN(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
                  child: _GRNDetailSheet(
                    controller: controller,
                    grnItem: item,
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
  final GoodsReceivingController controller;
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
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchGRNs(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search GRNs...',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CREATE GRN WIZARD
// ═══════════════════════════════════════════════════════════════

class _CreateGRNWizard extends StatelessWidget {
  final GoodsReceivingController controller;
  final VoidCallback onCancel;

  const _CreateGRNWizard({
    required this.controller,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Create Goods Receiving',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _stepIndicator(),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(context),
              ),
            ),
            _buildNavButtons(context),
          ],
        );
      }),
    );
  }

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = controller.wizardStep.value >= i;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: active ? kPrimary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (controller.wizardStep.value) {
      case 0:
        return _stepFindOrder(context);
      case 1:
        return _stepSelectItems();
      default:
        return _stepDetails(context);
    }
  }

  // ─── STEP 1: FIND PURCHASE ORDER ─────────────────────────────

  Widget _stepFindOrder(BuildContext context) {
    return _section('Select Purchase Order', [
      TextField(
        controller: controller.orderSearchController,
        decoration: const InputDecoration(
          hintText: 'Search order # or supplier...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onChanged: controller.searchOrders,
      ),
      if (controller.isSearchingOrders.value)
        const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator())),
      ...controller.orderSearchResults.map(_orderTile),
      if (controller.selectedOrder.value != null)
        _selectedOrderCard(controller.selectedOrder.value!),
    ]);
  }

  // ─── STEP 2: SELECT ITEMS ─────────────────────────────────────

  Widget _stepSelectItems() {
    return Obx(() {
      return _section('Enter Receiving Quantities', [
        ...List.generate(controller.lineDrafts.length, (index) {
          final line = controller.lineDrafts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('SKU: ${line.sku}', style: TextStyle(fontSize: 11, color: kSubText)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: line.isFullyReceived ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          line.isFullyReceived ? 'Complete' : '${line.alreadyReceived}/${line.orderedQuantity}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: line.isFullyReceived ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Ordered: ', style: TextStyle(fontSize: 11, color: kSubText)),
                      Text('${line.orderedQuantity}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Text('Received: ', style: TextStyle(fontSize: 11, color: kSubText)),
                      Text('${line.alreadyReceived}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Text('Remaining: ', style: TextStyle(fontSize: 11, color: kSubText)),
                      Text('${line.remainingQuantity}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: line.receivingQuantity > 0 ? line.receivingQuantity.toString() : '',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Receiving Qty',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            suffixText: line.unit,
                            suffixStyle: TextStyle(color: kSubText),
                          ),
                          onChanged: (v) {
                            final q = int.tryParse(v) ?? 0;
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.receivingQuantity = q.clamp(0, line.remainingQuantity);
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            if (index < controller.lineDrafts.length) {
                              final updatedLine = controller.lineDrafts[index];
                              updatedLine.receivingQuantity = line.remainingQuantity;
                              controller.lineDrafts[index] = updatedLine;
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Full',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (controller.lineDrafts.isNotEmpty) ...[
          const SizedBox(height: 8),
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
                  'Total Receiving Quantity',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${controller.totalReceivingQuantity} items',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ]);
    });
  }

  // ─── STEP 3: DETAILS ──────────────────────────────────────────

  Widget _stepDetails(BuildContext context) {
    return _section('Receiving Details', [
      _buildDateField(
        controller: controller.receivingDateController,
        label: 'Receiving Date *',
        onTap: () => controller.selectReceivingDate(context),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.receivedByController,
        decoration: const InputDecoration(
          labelText: 'Received By (Optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes (Optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Purchase Order', controller.selectedOrder.value?.orderNumber ?? ''),
            _summaryRow('Supplier', controller.selectedOrder.value?.supplierName ?? ''),
            _summaryRow('Items', '${controller.lineDrafts.length} items'),
            _summaryRow('Total Receiving', '${controller.totalReceivingQuantity} items'),
          ],
        ),
      ),
    ]);
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: kSubText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.text.isEmpty ? label : controller.text,
                style: TextStyle(
                  fontSize: 13,
                  color: controller.text.isEmpty ? kSubText : kText,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: kSubText),
          ],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.inventory_2, size: 18, color: kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: kText,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${controller.wizardStep.value + 1}/3',
                style: TextStyle(fontSize: 11, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _orderTile(PurchaseOrderForReceiving order) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt_long, size: 18, color: kPrimary),
        ),
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${order.supplierName} • ${order.totalRemainingItems} items remaining',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Icon(Icons.chevron_right, color: kSubText, size: 18),
        onTap: () => controller.selectOrderForReceiving(order),
      ),
    );
  }

  Widget _selectedOrderCard(PurchaseOrderForReceiving order) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
                ),
                Text(
                  order.supplierName,
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
                Text(
                  '${order.totalRemainingItems} items remaining',
                  style: TextStyle(fontSize: 11, color: kSubText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          if (controller.wizardStep.value > 0)
            OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, size: 16, color: kSubText),
                  const SizedBox(width: 4),
                  Text('Back', style: TextStyle(color: kSubText, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const Spacer(),
          if (controller.wizardStep.value < 2)
            ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                children: [
                  Text('Next', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : controller.createGRN,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Row(
                      children: [
                        Icon(Icons.save, size: 18, color: Colors.black),
                        const SizedBox(width: 6),
                        Text('Save Draft', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRN DETAIL SHEET
// ═══════════════════════════════════════════════════════════════

class _GRNDetailSheet extends StatefulWidget {
  final GoodsReceivingController controller;
  final GoodsReceivingModel grnItem;
  final VoidCallback onClose;

  const _GRNDetailSheet({
    required this.controller,
    required this.grnItem,
    required this.onClose,
  });

  @override
  State<_GRNDetailSheet> createState() => _GRNDetailSheetState();
}

class _GRNDetailSheetState extends State<_GRNDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = widget.controller.grns.firstWhereOrNull((g) => g.id == widget.grnItem.id) ??
          widget.grnItem;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.controller.getStatusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  current.isFullyReceived ? Icons.check_circle : Icons.inventory_2,
                  color: widget.controller.getStatusColor(current.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.grnNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Goods Receiving',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.controller.getStatusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.controller.getStatusLabel(current.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.controller.getStatusColor(current.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 16),

          // ─── Details Grid ────────────────────────────────────
          _detailGrid(current),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),

          // ─── Items ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Received Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${current.totalItems} items',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...current.items.map((item) => Container(
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
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Ordered: ${item.orderedQuantity} • Received: ${item.receivingQuantity} • Remaining: ${item.remainingQuantity}',
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isFullyReceived ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.isFullyReceived ? 'Complete' : '${item.receivingQuantity}/${item.orderedQuantity}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: item.isFullyReceived ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 12),

          // ─── Progress ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Receiving Progress',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(current.receivingProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: widget.controller.getStatusColor(current.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: current.receivingProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.controller.getStatusColor(current.status),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Received: ${current.totalReceivedQty}',
                      style: TextStyle(fontSize: 11, color: kSubText),
                    ),
                    Text(
                      'Ordered: ${current.totalOrderedQty}',
                      style: TextStyle(fontSize: 11, color: kSubText),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Action Buttons ──────────────────────────────────
          if (current.canConfirm) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.confirmGRN(current.id);
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Receiving',
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
                        final ok = await widget.controller.deleteGRN(current.id);
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: kSubText,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _detailGrid(GoodsReceivingModel current) {
    final items = [
      {'label': 'Purchase Order', 'value': current.purchaseOrderNumber, 'icon': Icons.receipt_long},
      {'label': 'Supplier', 'value': current.supplierName, 'icon': Icons.business},
      {'label': 'Receiving Date', 'value': DateFormat('dd MMM yyyy').format(current.receivingDate), 'icon': Icons.calendar_today},
      if (current.receivedBy != null && current.receivedBy!.isNotEmpty)
        {'label': 'Received By', 'value': current.receivedBy!, 'icon': Icons.person},
      if (current.notes != null && current.notes!.isNotEmpty)
        {'label': 'Notes', 'value': current.notes!, 'icon': Icons.note},
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(item['icon'] as IconData, size: 14, color: kPrimary),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: Text(
                  item['label'] as String,
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ),
              Expanded(
                child: Text(
                  item['value'] as String,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRN LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _GRNListView extends StatelessWidget {
  final GoodsReceivingController controller;
  final VoidCallback onCreate;
  final ValueChanged<GoodsReceivingModel> onView;

  const _GRNListView({
    required this.controller,
    required this.onCreate,
    required this.onView,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Partially Received':
        return Colors.blue;
      case 'Fully Received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.grns.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final grns = controller.filteredGrns;

      if (grns.isEmpty && !controller.isLoading.value) {
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
                  Icons.inventory_2_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No goods receiving yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to receive goods from purchase order',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Receive Goods',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        itemCount: grns.length,
        itemBuilder: (context, index) {
          final item = grns[index];
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
                          item.isFullyReceived ? Icons.check_circle : Icons.inventory_2,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.grnNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.supplierName,
                              style: TextStyle(
                                fontSize: 12,
                                color: kText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
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
                                    controller.getStatusLabel(item.status),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                                    '${item.totalItems} items',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy').format(item.receivingDate),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                            // Progress bar for received items
                            if (!item.isDraft) ...[
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: item.receivingProgress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.totalReceivedQty}/${item.totalOrderedQty}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
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