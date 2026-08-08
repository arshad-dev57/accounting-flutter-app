import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/controller/sales_refund_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/model/refund_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RefundListView extends StatelessWidget {
  final SalesRefundController controller;
  final VoidCallback onCreate;
  final ValueChanged<RefundModel> onView;

  const RefundListView({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onView,
  });

  String _format(double v) => Get.find<CurrencyController>().formatAmount(v);

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Processing':
        return Colors.blue;
      case 'Failed':
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildStats(),
          const SizedBox(height: 12),
          _buildFilters(context),
          const SizedBox(height: 12),
          Expanded(child: _buildList(context)),
          _buildPagination(context),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 520;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Refunds (${controller.totalRecords.value})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: controller.refreshRefunds,
              icon: const Icon(Icons.refresh, color: Colors.black87),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const Spacer(),
            if (compact)
              ElevatedButton(
                onPressed: onCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                ),
                child: const Icon(Icons.add, color: Colors.black),
              )
            else
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18, color: Colors.black),
                label: const Text(
                  'Create Refund',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    final s = controller.stats.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard('Total', '${s.total}', _format(s.totalAmount)),
          _statCard('Pending', '${s.pending}', null),
          _statCard('Processing', '${s.processing}', null),
          _statCard('Completed', '${s.completed}', null),
        ],
      ),
    );
  }

  Widget _statCard(String label, String count, String? amount) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: kSubText)),
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (amount != null)
            Text(amount, style: TextStyle(fontSize: 11, color: kSubText)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fieldWidth = width < 600 ? width - 48 : 160.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: width < 600 ? double.infinity : 200,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search refunds...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                controller.searchFilter.value = v;
                controller.applyFilters();
              },
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: DropdownButtonFormField<String>(
              value: controller.statusFilter.value,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: SalesRefundController.statusOptions
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s == 'all' ? 'All Status' : s),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                controller.statusFilter.value = v ?? 'all';
                controller.applyFilters();
              },
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: DropdownButtonFormField<String>(
              value: controller.methodFilter.value,
              decoration: const InputDecoration(
                labelText: 'Method',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: SalesRefundController.methodOptions
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m == 'all' ? 'All Methods' : m),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                controller.methodFilter.value = v ?? 'all';
                controller.applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (controller.isLoading.value) {
      return Center(
        child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 36),
      );
    }
    if (controller.refunds.isEmpty) {
      return const Center(child: Text('No refunds found'));
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListView.separated(
        itemCount: controller.refunds.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final refund = controller.refunds[index];
          final color = _statusColor(refund.refundStatus);
          return InkWell(
            onTap: () => onView(refund),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              refund.refundNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              refund.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Order: ${refund.orderNumber}',
                              style: TextStyle(fontSize: 12, color: kSubText),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _format(refund.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => onView(refund),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _badge(
                        refund.refundStatus,
                        color.withOpacity(0.12),
                        color,
                      ),
                      _badge(
                        refund.refundMethod,
                        Colors.grey.shade100,
                        Colors.grey.shade800,
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(refund.refundDate),
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    if (controller.totalPages.value <= 1) return const SizedBox.shrink();
    final compact = MediaQuery.of(context).size.width < 520;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Text(
              'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
            ),
            const SizedBox(height: 8),
            Row(
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
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
          ),
          Row(
            children: [
              IconButton(
                onPressed: controller.hasPrev.value
                    ? () =>
                          controller.goToPage(controller.currentPage.value - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: controller.hasNext.value
                    ? () =>
                          controller.goToPage(controller.currentPage.value + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
