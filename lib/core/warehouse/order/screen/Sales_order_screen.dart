// lib/core/warehouse/order/screen/sales_order_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/create_order_form.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/order_detail_sheet.dart';
import 'package:LedgerPro_app/core/warehouse/order/widgets/order_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SalesOrdersScreen extends StatelessWidget {
  const SalesOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesOrderController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Obx(() {
        if (controller.showCreateForm.value) {
          return CreateOrderForm(
            controller: controller,
            onCancel: controller.closeCreateForm,
          );
        }

        return Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _buildBody(controller, context),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreateForm,
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }

  // ─── TOP HEADER ──────────────────────────────────────────────

  Widget _buildTopHeader(SalesOrderController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalRecords.value} orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compact KPIs
                  Obx(
                    () => Row(
                      children: [
                        _compactKpi(
                          'Pending',
                          controller.orders
                              .where((o) => o.orderStatus == 'Pending')
                              .length
                              .toString(),
                          Colors.orange.shade800,
                        ),
                        const SizedBox(width: 12),
                        _compactKpi(
                          'Processing',
                          controller.orders
                              .where((o) => o.orderStatus == 'Processing')
                              .length
                              .toString(),
                          Colors.blue.shade800,
                        ),
                        const SizedBox(width: 12),
                        _compactKpi(
                          'Done',
                          controller.orders
                              .where((o) => o.orderStatus == 'Delivered')
                              .length
                              .toString(),
                          Colors.green.shade800,
                        ),
                      ],
                    ),
                  ),
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
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──
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

            // ── Filter dropdowns row (replaces chips) ──
            Obx(
              () => Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    // Status — widest
                    Expanded(
                      flex: 5,
                      child: _headerDropdown(
                        value: controller.statusFilter.value,
                        items: SalesOrderController.statusOptions,
                        label: 'Status',
                        onChanged: (v) => controller.updateFilter('status', v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Payment
                    Expanded(
                      flex: 4,
                      child: _headerDropdown(
                        value: controller.paymentStatusFilter.value,
                        items: SalesOrderController.paymentOptions,
                        label: 'Payment',
                        onChanged: (v) =>
                            controller.updateFilter('paymentStatus', v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Priority
                    Expanded(
                      flex: 4,
                      child: _headerDropdown(
                        value: controller.priorityFilter.value,
                        items: SalesOrderController.priorityOptions,
                        label: 'Priority',
                        onChanged: (v) =>
                            controller.updateFilter('priority', v),
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

  // ── Styled dropdown that sits nicely in the yellow header ──
  Widget _headerDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Colors.black54,
          ),
          items: items
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(
                    opt == 'all' ? 'All $label' : opt,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
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
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────

  Widget _buildBody(SalesOrderController controller, BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: kPrimary,
            size: 40,
          ),
        );
      }

      if (controller.orders.isEmpty && !controller.isLoading.value) {
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
                  Icons.shopping_cart_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No sales orders yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to create your first sales order',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: controller.openCreateForm,
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

      return OrderListView(
        controller: controller,
        onView: (order) => _showOrderDetail(context, controller, order),
      );
    });
  }

  // ─── ORDER DETAIL ─────────────────────────────────────────────

  void _showOrderDetail(
    BuildContext context,
    SalesOrderController controller,
    OrderModel order,
  ) {
    controller.openOrderDetail(order);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.93,
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
                  child: OrderDetailSheet(
                    controller: controller,
                    order: order,
                    onClose: () {
                      controller.closeOrderDetail();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.closeOrderDetail);
  }
}

// ─── SEARCH FIELD ──────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  final SalesOrderController controller;
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
            : widget.controller.searchOrders(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search sales orders...',
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
