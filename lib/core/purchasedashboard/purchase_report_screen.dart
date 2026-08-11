import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PurchaseReportScreen extends StatelessWidget {
  const PurchaseReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PurchaseReportController());
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Purchase Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isExporting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              onPressed: controller.isExporting.value
                  ? null
                  : () => controller.exportToPdf(),
              tooltip: 'Download PDF',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadReport(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(controller: controller, isMobile: isMobile),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rows.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              if (controller.error.value.isNotEmpty && controller.rows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error.value, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: controller.loadReport,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadReport,
                child: ListView(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  children: [
                    _SummaryCards(controller: controller, isMobile: isMobile),
                    const SizedBox(height: 12),
                    _ChannelBreakdown(controller: controller),
                    const SizedBox(height: 12),
                    _RowsTable(controller: controller, isMobile: isMobile),
                    const SizedBox(height: 12),
                    _Pagination(controller: controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.exportToPdf(),
        backgroundColor: kPrimary,
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text(
          'Download PDF',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final PurchaseReportController controller;
  final bool isMobile;

  const _FiltersBar({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 12, isMobile ? 12 : 20, 12),
        child: Obx(() {
          return Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ChipDropdown(
                    label: 'Channel',
                    value: controller.channel.value,
                    items: PurchaseReportController.channels,
                    onChanged: controller.setChannel,
                  ),
                  _ChipDropdown(
                    label: 'Period',
                    value: controller.period.value,
                    items: PurchaseReportController.periods,
                    onChanged: controller.setPeriod,
                  ),
                  _ChipDropdown(
                    label: 'Status',
                    value: controller.status.value,
                    items: PurchaseReportController.statuses,
                    onChanged: controller.setStatus,
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 220,
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search ref / supplier',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => controller.applyFilters(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: controller.applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
              if (controller.period.value == 'custom') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.pickStartDate(context),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          controller.startDate.value == null
                              ? 'Start date'
                              : DateFormat('dd MMM yyyy')
                                  .format(controller.startDate.value!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.pickEndDate(context),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          controller.endDate.value == null
                              ? 'End date'
                              : DateFormat('dd MMM yyyy')
                                  .format(controller.endDate.value!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _ChipDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _ChipDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          hint: Text(label),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e.$2,
                  child: Text(e.$1, style: const TextStyle(fontSize: 13)),
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
}

class _SummaryCards extends StatelessWidget {
  final PurchaseReportController controller;
  final bool isMobile;

  const _SummaryCards({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      final cards = [
        ('Records', '${s?.count ?? 0}', Icons.receipt_long),
        (
          'Grand Total',
          controller.formatCurrency(s?.grandTotal ?? 0),
          Icons.payments_outlined
        ),
        (
          'Tax',
          controller.formatCurrency(s?.taxTotal ?? 0),
          Icons.account_balance
        ),
        (
          'Discount',
          controller.formatCurrency(s?.discountTotal ?? 0),
          Icons.local_offer_outlined
        ),
      ];

      return GridView.count(
        crossAxisCount: isMobile ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isMobile ? 1.6 : 2.2,
        children: cards.map((c) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(c.$3, size: 18, color: kPrimary),
                const SizedBox(height: 6),
                Text(
                  c.$1,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  c.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _ChannelBreakdown extends StatelessWidget {
  final PurchaseReportController controller;

  const _ChannelBreakdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final by = controller.summary.value?.byChannel ?? {};
      if (by.isEmpty) return const SizedBox.shrink();

      Widget chip(String key, Color color) {
        final data = by[key] ?? {};
        final count = (data['count'] as num?)?.toInt() ?? 0;
        final rawTotal = data['grandTotal'];
        final total = rawTotal is num
            ? rawTotal.toDouble()
            : double.tryParse(rawTotal?.toString() ?? '') ?? 0;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$count sales', style: const TextStyle(fontSize: 12)),
                Text(
                  controller.formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Row(
        children: [
          chip('orders', const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          chip('invoices', const Color(0xFF059669)),
          const SizedBox(width: 8),
          chip('payments', const Color(0xFF0284C7)),
          const SizedBox(width: 8),
          chip('returns', const Color(0xFFD97706)),
        ],
      );
    });
  }
}

class _RowsTable extends StatelessWidget {
  final PurchaseReportController controller;
  final bool isMobile;

  const _RowsTable({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.rows.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('No purchases found for these filters')),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 12, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 10, child: Text('Channel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 14, child: Text('Reference', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 16, child: Text('Supplier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 12, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 12, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.right)),
                  ],
                ),
              ),
            ...controller.rows.map((r) {
              if (isMobile) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(
                    r.reference,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${controller.formatDate(r.date)} · ${r.channel.toUpperCase()} · ${r.supplierName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        controller.formatCurrency(r.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        r.paymentStatus.isEmpty ? r.status : r.paymentStatus,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 12, child: Text(controller.formatDate(r.date), style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 10, child: Text(r.channel.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Expanded(flex: 14, child: Text(r.reference, style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 16, child: Text(r.supplierName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 12, child: Text(r.status, style: const TextStyle(fontSize: 12))),
                    Expanded(
                      flex: 12,
                      child: Text(
                        controller.formatCurrency(r.grandTotal),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _Pagination extends StatelessWidget {
  final PurchaseReportController controller;

  const _Pagination({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.totalPages.value <= 1) {
        return Text(
          '${controller.total.value} record(s)',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: controller.page.value > 1 ? controller.prevPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${controller.page.value} / ${controller.totalPages.value}  (${controller.total.value})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed:
                controller.page.value < controller.totalPages.value
                    ? controller.nextPage
                    : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      );
    });
  }
}
