
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/purchases/controller/purchase_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/purchases/model/purchase_model.dart';
import 'package:LedgerPro_app/core/warehouse/supplier/screen/supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PurchaseOrderScreen extends StatelessWidget {
  const PurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseOrderController());

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text(
          'Purchase Orders',
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
            onPressed: controller.refreshOrders,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.showCreateWizard.value) {
          return _CreateOrderWizard(
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
                child: _OrderListView(
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

  Widget _buildTopHeader(PurchaseOrderController controller) {
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
                          'Purchase Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(() => Text(
                          '${controller.totalRecords.value} orders',
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
                      _compactKpi('Draft', controller.statusCounts.value.draft.toString(), Colors.orange.shade800),
                      const SizedBox(width: 6),
                      _compactKpi('Sent', controller.statusCounts.value.sent.toString(), Colors.blue.shade800),
                      const SizedBox(width: 6),
                      _compactKpi('Approved', controller.statusCounts.value.approved.toString(), Colors.green.shade800),
                    ],
                  )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshOrders,
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
                  _filterChip('All', controller.selectedFilter.value == 'all', () => controller.filterOrders('all')),
                  _filterChip('Draft', controller.selectedFilter.value == 'Draft', () => controller.filterOrders('Draft')),
                  _filterChip('Sent', controller.selectedFilter.value == 'Sent', () => controller.filterOrders('Sent')),
                  _filterChip('Approved', controller.selectedFilter.value == 'Approved', () => controller.filterOrders('Approved')),
                  _filterChip('Cancelled', controller.selectedFilter.value == 'Cancelled', () => controller.filterOrders('Cancelled')),
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

  void _showDetail(BuildContext context, PurchaseOrderController controller, PurchaseOrderModel item) {
    controller.selectOrder(item);
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
                  child: _OrderDetailSheet(
                    controller: controller,
                    orderItem: item,
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
  final PurchaseOrderController controller;
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
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchOrders(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search purchase orders...',
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
// CREATE ORDER WIZARD - REDESIGNED
// ═══════════════════════════════════════════════════════════════

class _CreateOrderWizard extends StatelessWidget {
  final PurchaseOrderController controller;
  final VoidCallback onCancel;

  const _CreateOrderWizard({
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
          'Create Purchase Order',
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
        return _stepSelectSupplier(context);
      case 1:
        return _stepAddItems(context);
      default:
        return _stepDetails(context);
    }
  }

  // ─── STEP 1: SELECT SUPPLIER ──────────────────────────────────

  Widget _stepSelectSupplier(BuildContext context) {
    return _section(
      'Select Supplier',
      Icons.business,
      [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: controller.supplierSearchController,
                  decoration:  InputDecoration(
                    hintText: 'Search supplier...',
                    prefixIcon: Icon(Icons.search, size: 18, color: kSubText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: controller.searchSuppliers,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.black, size: 22),
                onPressed: () {
                  Get.to(() => const SuppliersScreen())?.then((_) {
                    controller.supplierSearchResults.clear();
                    controller.supplierSearchController.clear();
                  });
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (controller.isSearchingSuppliers.value)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ...controller.supplierSearchResults.map(_supplierTile),
        if (controller.selectedSupplier.value != null)
          _selectedSupplierCard(controller.selectedSupplier.value!),
      ],
    );
  }

  // ─── STEP 2: ADD ITEMS ────────────────────────────────────────

  Widget _stepAddItems(BuildContext context) {
    return _section(
      'Add Items',
      Icons.inventory,
      [
        Container(
          decoration: BoxDecoration(
            color: kBgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.productSearchController,
                  decoration:  InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search, size: 18, color: kSubText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: controller.searchProducts,
                ),
              ),
              if (controller.isSearchingProducts.value)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        if (controller.productSearchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.productSearchResults.length,
              itemBuilder: (context, index) {
                final product = controller.productSearchResults[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.inventory_2, size: 16, color: kPrimary),
                  ),
                  title: Text(
                    product['name'] ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'SKU: ${product['sku']} • ${_format(product['costPrice']?.toDouble() ?? 0)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 16),
                  ),
                  onTap: () => controller.addProductToOrder(product),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        if (controller.lineDrafts.isEmpty)
          Container(
            padding:  EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: kSubText.withOpacity(0.3)),
                const SizedBox(height: 8),
                Text(
                  'No items added yet',
                  style: TextStyle(color: kSubText, fontSize: 13),
                ),
                Text(
                  'Search and add products above',
                  style: TextStyle(color: kSubText.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          )
        else
          ...List.generate(controller.lineDrafts.length, (index) {
            final line = controller.lineDrafts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'SKU: ${line.sku}',
                                style: TextStyle(fontSize: 11, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                          onPressed: () => controller.removeProductFromOrder(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'Qty',
                            value: line.quantity.toString(),
                            onChanged: (v) {
                              final q = int.tryParse(v) ?? 1;
                              controller.updateProductQuantity(index, q.clamp(1, 9999));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'Unit Price',
                            value: line.unitPrice.toString(),
                            onChanged: (v) {
                              final p = double.tryParse(v) ?? 0;
                              controller.updateProductUnitPrice(index, p);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            label: 'Disc%',
                            value: line.discount.toString(),
                            onChanged: (v) {
                              final d = double.tryParse(v) ?? 0;
                              controller.updateProductDiscount(index, d.clamp(0, 100));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            label: 'Tax%',
                            value: line.taxRate.toString(),
                            onChanged: (v) {
                              final t = double.tryParse(v) ?? 0;
                              controller.updateProductTaxRate(index, t.clamp(0, 100));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Line Total: ', style: TextStyle(fontSize: 12, color: kSubText)),
                        Text(
                          _format(line.lineTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kPrimary,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', _format(controller.selectedSubtotal)),
                _summaryRow('Discount', '-${_format(controller.selectedTotalDiscount)}', color: Colors.red),
                _summaryRow('Tax', _format(controller.selectedTotalTax), color: Colors.blue),
                _summaryRow('Total Items', controller.totalItems.toString()),
                const Divider(height: 16),
                _summaryRow('Grand Total', _format(controller.selectedGrandTotal), bold: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      style: const TextStyle(fontSize: 12),
      onChanged: onChanged,
    );
  }

  // ─── STEP 3: ORDER DETAILS ────────────────────────────────────

  Widget _stepDetails(BuildContext context) {
    return _section(
      'Order Details',
      Icons.description,
      [
        _buildDateField(
          controller: controller.orderDateController,
          label: 'Order Date *',
          onTap: () => controller.selectOrderDate(context),
        ),
        const SizedBox(height: 12),
        _buildDateField(
          controller: controller.expectedDeliveryDateController,
          label: 'Expected Delivery',
          onTap: () => controller.selectExpectedDeliveryDate(context),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.notesController,
          label: 'Notes',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.termsConditionsController,
          label: 'Terms & Conditions',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kPrimary.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryRow('Supplier', controller.selectedSupplier.value?['name'] ?? ''),
              _summaryRow('Items', controller.totalItems.toString()),
              const Divider(height: 16),
              _summaryRow('Grand Total', _format(controller.selectedGrandTotal), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kBgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: kSubText, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
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
                child: Icon(icon, size: 18, color: kPrimary),
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

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: kSubText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? (bold ? kPrimary : kText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierTile(Map<String, dynamic> supplier) {
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
          child: Icon(Icons.business, size: 18, color: kPrimary),
        ),
        title: Text(
          supplier['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          supplier['email'] ?? supplier['phone'] ?? '',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Icon(Icons.chevron_right, color: kSubText, size: 18),
        onTap: () => controller.selectSupplier(supplier),
      ),
    );
  }

  Widget _selectedSupplierCard(Map<String, dynamic> supplier) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
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
                  supplier['name'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
                ),
                if (supplier['email'] != null)
                  Text(supplier['email'], style: TextStyle(fontSize: 12, color: kSubText)),
                if (supplier['phone'] != null)
                  Text(supplier['phone'], style: TextStyle(fontSize: 12, color: kSubText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NAVIGATION BUTTONS ───────────────────────────────────────

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
              onPressed: controller.isSubmitting.value ? null : controller.createOrder,
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
                        Icon(Icons.check, size: 18, color: Colors.black),
                        const SizedBox(width: 6),
                        Text('Create Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORDER DETAIL SHEET
// ═══════════════════════════════════════════════════════════════

class _OrderDetailSheet extends StatefulWidget {
  final PurchaseOrderController controller;
  final PurchaseOrderModel orderItem;
  final VoidCallback onClose;

  const _OrderDetailSheet({
    required this.controller,
    required this.orderItem,
    required this.onClose,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = widget.controller.orders.firstWhereOrNull((o) => o.id == widget.orderItem.id) ??
          widget.orderItem;

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
                  color: _statusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  current.isApproved ? Icons.check_circle : Icons.receipt_long,
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
                      current.orderNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                    Text(
                      'Purchase Order',
                      style: TextStyle(fontSize: 12, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(current.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.controller.getStatusLabel(current.status),
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
                'Items',
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
                        'Qty: ${item.quantity} × ${_format(item.unitPrice)}',
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                      if (item.discount > 0)
                        Text(
                          'Disc: ${item.discount}% • Tax: ${item.taxRate}%',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                    ],
                  ),
                ),
                Text(
                  _format(item.lineTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 12),

          // ─── Totals ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', _format(current.subtotal)),
                if (current.totalDiscount > 0)
                  _summaryRow('Discount', '-${_format(current.totalDiscount)}', color: Colors.red),
                if (current.totalTax > 0)
                  _summaryRow('Tax', _format(current.totalTax), color: Colors.blue),
                const Divider(height: 12),
                _summaryRow('Grand Total', _format(current.grandTotal), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Action Buttons ──────────────────────────────────
          if (current.canSend) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.sendOrder(current.id);
                            if (ok) widget.onClose();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send Order',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (current.canApprove)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.controller.isSubmitting.value
                          ? null
                          : () async {
                              final ok = await widget.controller.updateOrderStatus(current.id, 'Approved');
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
                        'Approve',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (current.canCancel) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSubmitting.value
                        ? null
                        : () async {
                            final ok = await widget.controller.cancelOrder(current.id);
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
                      'Cancel Order',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (current.canDelete)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await widget.controller.deleteOrder(current.id);
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

  String _format(double v) {
    final currency = Get.find<CurrencyController>();
    return currency.formatAmount(v);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.orange;
      case 'Sent':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _detailGrid(PurchaseOrderModel current) {
    final items = [
      {'label': 'Supplier', 'value': current.supplierName, 'icon': Icons.business},
      if (current.supplierEmail != null && current.supplierEmail!.isNotEmpty)
        {'label': 'Email', 'value': current.supplierEmail!, 'icon': Icons.email},
      if (current.supplierPhone != null && current.supplierPhone!.isNotEmpty)
        {'label': 'Phone', 'value': current.supplierPhone!, 'icon': Icons.phone},
      {'label': 'Order Date', 'value': DateFormat('dd MMM yyyy').format(current.orderDate), 'icon': Icons.calendar_today},
      if (current.expectedDeliveryDate != null)
        {'label': 'Expected Delivery', 'value': DateFormat('dd MMM yyyy').format(current.expectedDeliveryDate!), 'icon': Icons.calendar_today},
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
                width: 90,
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

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
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
              color: color ?? (bold ? kPrimary : kText),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORDER LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _OrderListView extends StatelessWidget {
  final PurchaseOrderController controller;
  final VoidCallback onCreate;
  final ValueChanged<PurchaseOrderModel> onView;

  const _OrderListView({
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
      case 'Draft':
        return Colors.orange;
      case 'Sent':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      final orders = controller.filteredOrders;

      if (orders.isEmpty && !controller.isLoading.value) {
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
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No purchase orders yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first purchase order',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Create Order',
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
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final item = orders[index];
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
                          item.isApproved ? Icons.check_circle : Icons.receipt_long,
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
                              item.orderNumber,
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
                                  DateFormat('dd MMM yyyy').format(item.orderDate),
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
                          Text(
                            _format(item.grandTotal),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
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