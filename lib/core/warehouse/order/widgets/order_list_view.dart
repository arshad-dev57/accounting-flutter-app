
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:LedgerPro_app/core/warehouse/order/model/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


class OrderListView extends StatelessWidget {
  final SalesOrderController controller;
  final ValueChanged<OrderModel> onView;

  const OrderListView({
    super.key,
    required this.controller,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildList(context)),
          _buildPagination(context),
          const SizedBox(height: 80), 
        ],
      );
    });
  }


  Widget _buildList(BuildContext context) {
    if (controller.isLoading.value && controller.orders.isEmpty) {
      return Center(
        child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 36),
      );
    }

    if (controller.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: kSubText.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('No orders found', style: TextStyle(color: kSubText, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Try changing your filters', style: TextStyle(color: kSubText.withOpacity(0.65), fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: controller.orders.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final order = controller.orders[index];
          return _OrderCard(
            order: order,
            controller: controller,
            onView: onView,
          );
        },
      ),
    );
  }


  Widget _buildPagination(BuildContext context) {
    if (controller.orders.isEmpty) return const SizedBox.shrink();

    final start = ((controller.currentPage.value - 1) * controller.pageLimit.value) + 1;
    final end = (controller.currentPage.value * controller.pageLimit.value)
        .clamp(0, controller.totalRecords.value);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Showing $start–$end of ${controller.totalRecords.value} orders',
            style: TextStyle(fontSize: 12, color: kSubText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageButton(
                icon: Icons.chevron_left,
                enabled: controller.hasPrev.value,
                onTap: () => controller.goToPage(controller.currentPage.value - 1),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.currentPage.value} / ${controller.totalPages.value}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              _pageButton(
                icon: Icons.chevron_right,
                enabled: controller.hasNext.value,
                onTap: () => controller.goToPage(controller.currentPage.value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(10),
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Icon(icon, size: 20),
    );
  }
}


class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final SalesOrderController controller;
  final ValueChanged<OrderModel> onView;

  const _OrderCard({
    required this.order,
    required this.controller,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onView(order),
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: order info + amount ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number + customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (order.customerEmail != null && order.customerEmail!.isNotEmpty)
                        Text(
                          order.customerEmail!,
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                    ],
                  ),
                ),
                // Amount + view icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.formatCurrency(order.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => onView(order),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.visibility_outlined, size: 16, color: kPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 9),

            // ── Badges row ──
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _badge(order.orderType, Colors.grey.shade100, Colors.grey.shade700),
                _badge(
                  '${controller.itemCount(order)} item${controller.itemCount(order) == 1 ? '' : 's'}',
                  Colors.blue.shade50,
                  Colors.blue.shade700,
                ),
                _badge(
                  order.orderStatus,
                  controller.getStatusColor(order.orderStatus).withOpacity(0.12),
                  controller.getStatusColor(order.orderStatus),
                ),
                _badge(
                  order.paymentStatus,
                  controller.getPaymentColor(order.paymentStatus).withOpacity(0.12),
                  controller.getPaymentColor(order.paymentStatus),
                ),
                _badge(
                  order.priority,
                  controller.getPriorityColor(order.priority).withOpacity(0.12),
                  controller.getPriorityColor(order.priority),
                ),
                _badge(
                  controller.formatDate(order.orderDate),
                  Colors.transparent,
                  kSubText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: bg == Colors.transparent
            ? Border.all(color: fg.withOpacity(0.25))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}