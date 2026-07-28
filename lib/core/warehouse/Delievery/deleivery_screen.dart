// lib/core/warehouse/delivery/views/delivery_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/warehouse/Delievery/deleivery_controller.dart';
import 'package:LedgerPro_app/core/warehouse/Delievery/deleivery_model.dart';
import 'package:LedgerPro_app/widgets/sales_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:universal_html/js.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DeliveryController());
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: kBgLight,
      drawer: isMobile ? const SalesDrawer(currentRoute: '/sales/delivery') : null,
      appBar: AppBar(
        title: const Text(
          'Deliveries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: 
           
             IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Get.back(),
              ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: controller.refreshDeliveries,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.showCreateWizard.value) {
          return _CreateDeliveryWizard(
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
                child: _DeliveryListView(
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

  Widget _buildTopHeader(DeliveryController controller) {
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
                          'Deliveries',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.totalRecords.value} deliveries',
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
                      _compactKpi('Pending', controller.stats.value.pending.toString(), Colors.orange.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Partial', controller.stats.value.partiallyDelivered.toString(), Colors.blue.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Delivered', controller.stats.value.delivered.toString(), Colors.green.shade800),
                    ],
                  )),
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
                  _filterChip('All', controller.selectedFilter.value == 'all', () => controller.filterDeliveries('all')),
                  _filterChip('Pending', controller.selectedFilter.value == 'Pending', () => controller.filterDeliveries('Pending')),
                  _filterChip('Partially', controller.selectedFilter.value == 'Partially Delivered', () => controller.filterDeliveries('Partially Delivered')),
                  _filterChip('Delivered', controller.selectedFilter.value == 'Delivered', () => controller.filterDeliveries('Delivered')),
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

  void _showDetail(BuildContext context, DeliveryController controller, DeliveryModel item) {
    controller.selectDelivery(item);
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
                  child: _DeliveryDetailSheet(
                    controller: controller,
                    deliveryItem: item,
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
  final DeliveryController controller;
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
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchDeliveries(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search deliveries...',
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

class _CreateDeliveryWizard extends StatelessWidget {
  final DeliveryController controller;
  final VoidCallback onCancel;

  const _CreateDeliveryWizard({
    required this.controller,
    required this.onCancel,
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
        leading: IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Create Delivery',
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
                child: _buildStepContent(),
              ),
            ),
            _buildNavButtons(),
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

  Widget _buildStepContent() {
    switch (controller.wizardStep.value) {
      case 0:
        return _stepFindOrder();
      case 1:
        return _stepSelectItems();
      default:
        return _stepDetails();
    }
  }

  Widget _stepFindOrder() {
    return _section('Step 1: Find Order', [
      TextField(
        controller: controller.orderSearchController,
        decoration: const InputDecoration(
          hintText: 'Search order # or customer',
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

  Widget _stepSelectItems() {
    return Obx(() {
      return _section('Step 2: Select Items', [
        ...List.generate(controller.lineDrafts.length, (index) {
          final line = controller.lineDrafts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: line.selected.value,
                    onChanged: (v) {
                      line.selected.value = v ?? false;
                    },
                    title: Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('SKU: ${line.sku} • Qty ordered: ${line.orderQuantity}'),
                  ),
                  if (line.selected.value) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: line.deliveryQuantity.value.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final q = int.tryParse(v) ?? 1;
                              line.deliveryQuantity.value = q.clamp(1, line.remainingQuantity);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining',
                                  style: TextStyle(fontSize: 11, color: kSubText),
                                ),
                                Text(
                                  '${line.remainingQuantity}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (controller.lineDrafts.any((l) => l.selected.value))
          Text(
            'Total Items: ${controller.totalDeliveryQuantity}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
      ]);
    });
  }

  Widget _stepDetails() {
    return _section('Step 3: Delivery Details', [
      TextField(
        controller: controller.deliveryDateController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Delivery Date *',
          suffixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onTap: () => controller.selectDeliveryDate(Get.context!),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.deliveryPersonController,
        decoration: const InputDecoration(
          labelText: 'Delivery Person (Optional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: controller.trackingNumberController,
        decoration: const InputDecoration(
          labelText: 'Tracking Number (Optional)',
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
            _summaryRow('Total Items', controller.totalDeliveryQuantity.toString()),
            _summaryRow('Order #', controller.selectedOrder.value?.orderNumber ?? ''),
            _summaryRow('Customer', controller.selectedOrder.value?.customerName ?? ''),
          ],
        ),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kSubText)),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? kPrimary : kText,
          )),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text('Back', style: TextStyle(color: kSubText)),
            ),
          const Spacer(),
          if (controller.wizardStep.value < 2)
            ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Next', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : controller.createDelivery,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  : const Text('Create Delivery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
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

  Widget _orderTile(OrderForDelivery order) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${order.customerName} • ${order.items.length} items available'),
      trailing: Icon(Icons.chevron_right, color: kSubText),
      onTap: () => controller.selectOrderForDelivery(order),
    );
  }

  Widget _selectedOrderCard(OrderForDelivery order) {
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
          Text(order.orderNumber, style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary)),
          Text(order.customerName),
          Text('${order.items.length} items available for delivery'),
        ],
      ),
    );
  }
}


class _DeliveryDetailSheet extends StatelessWidget {
  final DeliveryController controller;
  final DeliveryModel deliveryItem;
  final VoidCallback onClose;

  const _DeliveryDetailSheet({
    required this.controller,
    required this.deliveryItem,
    required this.onClose,
  });

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Partially Delivered':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.deliveries.firstWhereOrNull((d) => d.id == deliveryItem.id) ??
          deliveryItem;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _statusColor(current.deliveryStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: _statusColor(current.deliveryStatus), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.deliveryNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Delivery',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(current.deliveryStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  current.deliveryStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(current.deliveryStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 16),
          _detailRow('Order', current.salesOrderNumber),
          _detailRow('Customer', current.customerName),
          _detailRow('Date', DateFormat('dd MMM yyyy').format(current.deliveryDate)),
          if (current.deliveryPerson != null && current.deliveryPerson!.isNotEmpty)
            _detailRow('Delivery Person', current.deliveryPerson!),
          if (current.trackingNumber != null && current.trackingNumber!.isNotEmpty)
            _detailRow('Tracking', current.trackingNumber!),
          if (current.notes != null && current.notes!.isNotEmpty)
            _detailRow('Notes', current.notes!),
          if (current.confirmedAt != null)
            _detailRow('Confirmed', DateFormat('dd MMM yyyy HH:mm').format(current.confirmedAt!)),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${current.totalDeliveredQty}/${current.totalOrderedQty}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: current.deliveryProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: _statusColor(current.deliveryStatus),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...current.items.map((item) => Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                            'Ordered: ${item.orderedQuantity} • Delivered: ${item.deliveredQuantity} • Remaining: ${item.remainingQuantity}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isFullyDelivered ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.isFullyDelivered ? 'Complete' : '${item.deliveredQuantity}/${item.orderedQuantity}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.isFullyDelivered ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          // Action buttons
          if (!current.isDelivered && !current.isConfirmed) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await controller.confirmDelivery(current.id);
                            if (ok) onClose();
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
                      'Confirm Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final ok = await controller.deleteDelivery(current.id);
                      if (ok) onClose();
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
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: Colors.grey.shade300),
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
// DELIVERY LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _DeliveryListView extends StatelessWidget {
  final DeliveryController controller;
  final VoidCallback onCreate;
  final ValueChanged<DeliveryModel> onView;

  const _DeliveryListView({
    required this.controller,
    required this.onCreate,
    required this.onView,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Partially Delivered':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.deliveries.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final deliveries = controller.filteredDeliveries;

      if (deliveries.isEmpty && !controller.isLoading.value) {
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
                  Icons.local_shipping_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No deliveries yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first delivery',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Create Delivery',
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
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final item = deliveries[index];
          final color = _statusColor(item.deliveryStatus);

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
                        child: Icon(Icons.local_shipping, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.deliveryNumber,
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
                              item.customerName,
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
                                    item.deliveryStatus,
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
                                if (item.isConfirmed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Confirmed',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy').format(item.deliveryDate),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: item.deliveryProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.totalDeliveredQty}/${item.totalOrderedQty}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kSubText,
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