// screens/payments_made_screen.dart - COMPLETE FIXED VERSION

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/Bills/Screen/bill_Screen.dart';
import 'package:LedgerPro_app/core/PaymentMade/controller/paymentmade_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PaymentsMadeScreen extends StatelessWidget {
  const PaymentsMadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMadeController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ─────────────────────────────────────────
  // MOBILE LAYOUT
  // ─────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.payments.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobilePaymentsList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordPaymentDialog(controller, context),
        backgroundColor: kDanger,
        child: const Icon(Icons.payment, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    return AppBar(
      title: const Text(
        'Payments Made',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showSearchDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
          onPressed: () => _showFilterDialog(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportPayments(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(
    PaymentMadeController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: controller.filterOptions.map((f) {
              final isSelected = controller.selectedFilter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) =>
                      controller.applyDateFilter(isSelected ? 'All' : f),
                  backgroundColor: kBg,
                  selectedColor: kPrimary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? kPrimary : kSubText,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCards(
    PaymentMadeController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _buildSummaryCard(
                'Total Paid',
                controller.formatAmount(controller.totalPaid.value),
                kDanger,
                Icons.payment,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'This Month',
                controller.formatAmount(controller.thisMonthTotal.value),
                kPrimary,
                Icons.calendar_month,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'This Week',
                controller.formatAmount(controller.thisWeekTotal.value),
                kPrimary,
                Icons.view_week_outlined,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Today',
                controller.formatAmount(controller.todayTotal.value),
                kWarning,
                Icons.today,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Pending',
                controller.pendingCount.value.toString(),
                kWarning,
                Icons.pending_outlined,
                isNumber: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePaymentsList(
    PaymentMadeController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final payments = controller.payments;

      if (controller.isLoading.value && payments.isEmpty) {
        return const SizedBox.shrink();
      }

      if (payments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment_outlined,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No payments found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showRecordPaymentDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDanger,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobilePaymentCard(payments[index], controller, context),
        ),
      );
    });
  }

  Widget _buildMobilePaymentCard(
    PaymentMade payment,
    PaymentMadeController controller,
    BuildContext context,
  ) {
    final statusColor = payment.status == 'Cleared' || payment.status == 'Completed'
        ? kSuccess
        : kWarning;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentDetails(payment, controller, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 20,
                        color: kDanger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.paymentNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.supplierName,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment.status,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment.paymentMethod,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: kSubText,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          controller.formatAmount(payment.amount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kDanger,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yy').format(payment.paymentDate),
                          style: TextStyle(fontSize: 9, color: kSubText),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showPaymentDetails(payment, controller, context),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text(
                          'Details',
                          style: TextStyle(fontSize: 11, color: kText),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.printVoucher(payment),
                        icon: const Icon(
                          Icons.print,
                          size: 14,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Voucher',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEB LAYOUT
  // ─────────────────────────────────────────
  Widget _buildWebLayout(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.payments.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 32,
                  ),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebPaymentsTable(controller, context)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Payments Made',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search payments…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black45),
                filled: true,
                fillColor: Colors.white.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.black26)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(controller, context),
            icon: const Icon(Icons.tune, size: 15, color: Colors.black87),
            label: const Text('Filter', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.exportPayments(),
            icon: const Icon(Icons.download_outlined, size: 15, color: Colors.black87),
            label: const Text('Export', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showRecordPaymentDialog(controller, context),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text('Record Payment', style: TextStyle(fontSize: 13, color: Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Colors.black26)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiStrip(PaymentMadeController controller) {
    return Obx(() => Container(
      color: kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: Row(
        children: [
          _buildWebKpiTile('Total Paid', controller.formatAmount(controller.totalPaid.value), kDanger, Icons.payment),
          _buildWebKpiDivider(),
          _buildWebKpiTile('This Month', controller.formatAmount(controller.thisMonthTotal.value), kPrimary, Icons.calendar_month),
          _buildWebKpiDivider(),
          _buildWebKpiTile('This Week', controller.formatAmount(controller.thisWeekTotal.value), kPrimary, Icons.view_week_outlined),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Today', controller.formatAmount(controller.todayTotal.value), kWarning, Icons.today),
          _buildWebKpiDivider(),
          _buildWebKpiTile('Pending', controller.pendingCount.value.toString(), kWarning, Icons.pending_outlined),
        ],
      ),
    ));
  }

  Widget _buildWebKpiTile(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() => Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(PaymentMadeController controller, BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: controller.filterOptions.map((filter) {
                  final isSelected = controller.selectedFilter.value == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => controller.applyDateFilter(filter),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? Border.all(color: kPrimary.withOpacity(0.3)) : null,
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? kPrimary : kSubText,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
          ),
          const SizedBox(width: 8),
          Obx(() {
            if (controller.selectedDateRange.value != null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range, size: 13, color: kPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd MMM').format(controller.selectedDateRange.value!.start)} – ${DateFormat('dd MMM yyyy').format(controller.selectedDateRange.value!.end)}',
                      style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.clearDateRange(),
                      child: Icon(Icons.close, size: 12, color: kPrimary),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildWebPaymentsTable(PaymentMadeController controller, BuildContext context) {
    return Obx(() {
      final payments = controller.payments;

      if (payments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 48, color: kSubText.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No payments found', style: TextStyle(fontSize: 15, color: kSubText)),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => _showRecordPaymentDialog(controller, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('+ Record Payment', style: TextStyle(fontSize: 13, color: Colors.black87)),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _tableHeaderCell('Payment #')),
                Expanded(flex: 2, child: _tableHeaderCell('Date')),
                Expanded(flex: 3, child: _tableHeaderCell('Supplier')),
                Expanded(flex: 2, child: _tableHeaderCell('Bill #')),
                Expanded(flex: 2, child: _tableHeaderCell('Method')),
                Expanded(flex: 2, child: _tableHeaderCell('Amount', align: TextAlign.right)),
                Expanded(flex: 1, child: _tableHeaderCell('Status', align: TextAlign.center)),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: payments.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) => _buildWebTableRow(payments[index], controller, context),
            ),
          ),
          _buildWebTableFooter(payments, controller),
        ],
      );
    });
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText, letterSpacing: 0.5),
    );
  }

  Widget _buildWebTableRow(PaymentMade payment, PaymentMadeController controller, BuildContext context) {
    final statusColor = payment.status == 'Cleared' || payment.status == 'Completed' ? kSuccess : kWarning;
    final statusText = payment.status == 'Cleared' || payment.status == 'Completed' ? 'CLR' : 'PNG';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPaymentDetails(payment, controller, context),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.payment, size: 14, color: kDanger),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(payment.paymentNumber,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText),
                          overflow: TextOverflow.ellipsis),
                      if (payment.reference.isNotEmpty)
                        Text(payment.reference,
                            style: TextStyle(fontSize: 11, color: kSubText),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(payment.paymentDate),
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  payment.supplierName,
                  style: TextStyle(fontSize: 12, color: kText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  payment.billNumber,
                  style: TextStyle(fontSize: 12, color: kSubText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(payment.paymentMethod,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  controller.formatAmount(payment.amount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDanger),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(Icons.visibility, kSubText, () => _showPaymentDetails(payment, controller, context)),
                    const SizedBox(width: 4),
                    _webIconBtn(Icons.print, kSubText, () => controller.printVoucher(payment)),
                    const SizedBox(width: 4),
                    _webIconBtn(Icons.more_vert, kSubText, () => _showRowActions(controller, payment, context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28, height: 28,
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildWebTableFooter(List<PaymentMade> payments, PaymentMadeController controller) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
              )),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: Text(
                controller.formatAmount(controller.totalPaid.value),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDanger),
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────

  void _showSearchDialog(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Payments',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller.searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Payment #, supplier, bill…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchController.clear();
              controller.searchQuery.value = '';
              controller.payments.value = controller.allPayments.value;
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(
    PaymentMadeController controller,
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Filter Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.date_range, color: kPrimary),
              title: const Text(
                'Select Date Range',
                style: TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: controller.selectedDateRange.value,
                );
                if (range != null) {
                  controller.selectedDateRange.value = range;
                  controller.selectedFilter.value = 'Custom Range';
                  await controller.loadPayments();
                  await controller.loadSummary();
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.clear_all, color: kDanger),
              title: const Text(
                'Clear All Filters',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                controller.clearDateRange();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // RECORD PAYMENT DIALOG (MULTI-BILL SUPPORT)
  // ─────────────────────────────────────────

  void _showRecordPaymentDialog(
    PaymentMadeController controller,
    BuildContext ctx,
  ) {
    final formKey = GlobalKey<FormState>();
    String selectedSupplierId = '';
    double amount = 0;
    String paymentMethod = 'Bank Transfer';
    String reference = '';
    String selectedBankAccountId = '';
    String notes = '';

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.payment, size: 18, color: kDanger),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Record Payment Made',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.clearBillSelections();
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Divider(
                  height: 16,
                  color: Colors.grey.withOpacity(0.2),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Supplier Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedSupplierId.isEmpty
                                ? null
                                : selectedSupplierId,
                            decoration: _inputDecoration('Select Supplier *'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            hint: Text(
                              'Select supplier',
                              style: TextStyle(fontSize: 12, color: kSubText),
                            ),
                            items: controller.suppliers
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              selectedSupplierId = v!;
                              controller.clearBillSelections();
                              await controller.getUnpaidBills(selectedSupplierId);
                              amount = 0;
                              setState(() {});
                            },
                            validator: (v) =>
                                v == null ? 'Supplier required' : null,
                          ),
                          const SizedBox(height: 12),

                          // Bills Selection
                          Obx(() {
                            if (selectedSupplierId.isNotEmpty &&
                                controller.isLoadingBills.value) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: LoadingAnimationWidget.waveDots(
                                    color: kPrimary,
                                    size: 30,
                                  ),
                                ),
                              );
                            }

                            if (selectedSupplierId.isNotEmpty &&
                                controller.currentBills.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kWarning.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kWarning.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: kWarning,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'No unpaid bills for this supplier.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kWarning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (controller.currentBills.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Select Bills *',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: kText,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Total: ${controller.formatAmount(controller.totalSelectedAmount.value)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kDanger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...controller.currentBills.map((bill) {
                                  final isSelected = controller.selectedBillIds
                                      .contains(bill.id);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? kDanger.withOpacity(0.05)
                                          : kBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? kDanger
                                            : Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      dense: true,
                                      value: isSelected,
                                      onChanged: (bool? checked) {
                                        setState(() {
                                          if (checked == true) {
                                            controller.toggleBillSelection(
                                              bill.id,
                                              bill.outstanding,
                                            );
                                          } else {
                                            controller.toggleBillSelection(
                                              bill.id,
                                              bill.outstanding,
                                            );
                                          }
                                          amount = controller.totalSelectedAmount.value;
                                        });
                                      },
                                      title: Text(
                                        bill.billNumber,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? kDanger : kText,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: kSubText,
                                            ),
                                          ),
                                          Text(
                                            'Outstanding: ${controller.formatAmount(bill.outstanding)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? kDanger : kDanger,
                                            ),
                                          ),
                                        ],
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      activeColor: kDanger,
                                    ),
                                  );
                                }).toList(),

                                // Select All / Deselect All
                                if (controller.currentBills.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              if (controller.selectedBillIds.length ==
                                                  controller.currentBills.length) {
                                                controller.clearBillSelections();
                                              } else {
                                                for (var bill in controller.currentBills) {
                                                  if (!controller.selectedBillIds.contains(bill.id)) {
                                                    controller.toggleBillSelection(
                                                      bill.id,
                                                      bill.outstanding,
                                                    );
                                                  }
                                                }
                                              }
                                              amount = controller.totalSelectedAmount.value;
                                            });
                                          },
                                          child: Text(
                                            controller.selectedBillIds.length ==
                                                controller.currentBills.length
                                                ? 'Deselect All'
                                                : 'Select All',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: kPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${controller.selectedBillIds.length} selected',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kSubText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (controller.selectedBillIds.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Please select at least one bill',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kDanger,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 12),

                          // Amount Field
                          _amountField(
                            amount,
                            (v) {
                              final val = double.tryParse(v) ?? 0;
                              final maxAmount = controller.totalSelectedAmount.value;
                              if (maxAmount > 0 && val > maxAmount) {
                                AppSnackbar.error(
                                  kWarning,
                                  'Error',
                                  'Amount cannot exceed total outstanding: ${controller.formatAmount(maxAmount)}',
                                );
                                amount = maxAmount;
                              } else {
                                amount = val;
                              }
                              setState(() {});
                            },
                            maxAmount: controller.totalSelectedAmount.value,
                          ),
                          const SizedBox(height: 12),

                          // Payment Method
                          _methodDropdown(
                            paymentMethod,
                            (v) => setState(() => paymentMethod = v!),
                          ),
                          const SizedBox(height: 12),

                          _formField(
                            'Reference Number',
                            'e.g. TRX-001',
                            (v) => reference = v,
                          ),

                          // Bank account for Bank Transfer
                          if (paymentMethod == 'Bank Transfer') ...[
                            const SizedBox(height: 12),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: selectedBankAccountId.isEmpty
                                    ? null
                                    : selectedBankAccountId,
                                decoration: _inputDecoration('From Bank Account *'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                hint: Text(
                                  'Select bank account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
                                  ),
                                ),
                                items: controller.bankAccounts
                                    .map(
                                      (acc) => DropdownMenuItem(
                                        value: acc.id,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              acc.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${acc.number} • Balance: ${controller.formatAmount(acc.balance)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: kSubText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => selectedBankAccountId = v ?? '',
                                ),
                                validator: (v) =>
                                    paymentMethod == 'Bank Transfer' &&
                                        (v == null || v.isEmpty)
                                        ? 'Bank account required'
                                        : null,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          _formField(
                            'Notes',
                            '',
                            (v) => notes = v,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.clearBillSelections();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14, color: kSubText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isRecording.value
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    // Validate bill selection
                                    if (controller.selectedBillIds.isEmpty) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Please select at least one bill',
                                      );
                                      return;
                                    }

                                    if (amount <= 0) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Please enter a valid payment amount',
                                      );
                                      return;
                                    }

                                    if (paymentMethod == 'Bank Transfer' &&
                                        selectedBankAccountId.isEmpty) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Please select a bank account',
                                      );
                                      return;
                                    }

                                    if (amount > controller.totalSelectedAmount.value) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Amount cannot exceed total outstanding',
                                      );
                                      return;
                                    }

                                    Navigator.pop(context);
                                    await controller.recordPayment(
                                      supplierId: selectedSupplierId,
                                      billIds: controller.selectedBillIds
                                          .toList(),
                                      amount: amount,
                                      paymentDate: DateTime.now(),
                                      paymentMethod: paymentMethod,
                                      reference: reference,
                                      bankAccountId: selectedBankAccountId
                                          .isEmpty
                                          ? null
                                          : selectedBankAccountId,
                                      notes: notes,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isRecording.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: LoadingAnimationWidget.waveDots(
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                )
                              : Text(
                                  'Record Payment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // PAYMENT DETAILS DIALOG
  // ─────────────────────────────────────────

  void _showPaymentDetails(
    PaymentMade payment,
    PaymentMadeController controller,
    BuildContext context,
  ) {
    final statusColor = payment.status == 'Cleared' || payment.status == 'Completed'
        ? kSuccess
        : kWarning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, size: 28, color: kDanger),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.paymentNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(payment.paymentDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: kSubText,
                        ),
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    payment.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow('Supplier', payment.supplierName),
                    _buildDetailRow('Bill #', payment.billNumber),
                    _buildDetailRow('Bill Amount', controller.formatAmount(payment.billAmount)),
                    Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                    _buildDetailRow('Payment Amount', controller.formatAmount(payment.amount), valueColor: kDanger),
                    _buildDetailRow('Payment Method', payment.paymentMethod),
                    if (payment.reference.isNotEmpty)
                      _buildDetailRow('Reference', payment.reference),
                    if (payment.bankAccountName.isNotEmpty)
                      _buildDetailRow('Bank Account', payment.bankAccountName),
                    _buildDetailRow('Recorded At', DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt)),
                    if (payment.notes.isNotEmpty) ...[
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow('Notes', payment.notes),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.viewBill(payment);
                    },
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text('View Bill', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.printVoucher(payment);
                    },
                    icon: const Icon(Icons.print, size: 16, color: Colors.black87),
                    label: const Text('Voucher', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Clear Cheque Button
                if (payment.paymentMethod == 'Cheque' && payment.status != 'Cleared')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final confirm = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Clear Cheque Payment'),
                            content: Text('Clear cheque payment ${payment.paymentNumber}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Clear', style: TextStyle(color: kSuccess)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await controller.clearChequePayment(payment.id);
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.black87),
                      label: const Text('Clear Cheque', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (payment.paymentMethod == 'Cheque' && payment.status != 'Cleared')
                  const SizedBox(width: 10),
                // Delete Payment Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Delete Payment'),
                          content: Text('Delete payment ${payment.paymentNumber}?\nThis will reverse the journal entry.'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Delete', style: TextStyle(color: kDanger)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await controller.deletePayment(payment.id);
                      }
                    },
                    icon: const Icon(Icons.delete, size: 16, color: kDanger),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, color: kDanger)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: kDanger.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
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
  }

  // ─────────────────────────────────────────
  // ROW ACTIONS
  // ─────────────────────────────────────────

  void _showRowActions(PaymentMadeController controller, PaymentMade payment, BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          onTap: () => _showPaymentDetails(payment, controller, context),
          child: const ListTile(leading: Icon(Icons.visibility, size: 18), title: Text('View Details', style: TextStyle(fontSize: 13)), dense: true),
        ),
        PopupMenuItem(
          onTap: () => controller.printVoucher(payment),
          child: const ListTile(leading: Icon(Icons.print, size: 18), title: Text('Print Voucher', style: TextStyle(fontSize: 13)), dense: true),
        ),
        if (payment.paymentMethod == 'Cheque' && payment.status != 'Cleared')
          PopupMenuItem(
            onTap: () async {
              await controller.clearChequePayment(payment.id);
            },
            child: ListTile(leading: Icon(Icons.check_circle, size: 18, color: kSuccess), title: Text('Clear Cheque', style: TextStyle(fontSize: 13)), dense: true),
          ),
        PopupMenuItem(
          onTap: () async {
            final confirm = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Delete Payment'),
                content: Text('Delete payment ${payment.paymentNumber}?'),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Get.back(result: true), child: const Text('Delete', style: TextStyle(color: kDanger))),
                ],
              ),
            );
            if (confirm == true) {
              await controller.deletePayment(payment.id);
            }
          },
          child: ListTile(leading: Icon(Icons.delete, size: 18, color: kDanger), title: Text('Delete', style: TextStyle(fontSize: 13)), dense: true),
        ),
      ],
      elevation: 4,
    );
  }

  // ─────────────────────────────────────────
  // FORM HELPERS
  // ─────────────────────────────────────────

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String initialValue = '',
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue.isEmpty ? null : initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _amountField(
    double amount,
    void Function(String) onChanged, {
    double maxAmount = 0,
  }) {
    return TextFormField(
      initialValue: amount > 0 ? amount.toStringAsFixed(2) : null,
      decoration: InputDecoration(
        labelText: 'Payment Amount *',
        prefixText: CurrencyUtils.prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        helperText: maxAmount > 0 ? 'Max: ${_formatAmount(maxAmount)}' : null,
        helperStyle: TextStyle(fontSize: 10, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Amount required' : null,
    );
  }

  Widget _methodDropdown(
    String value,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Payment Method *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      items: const [
        DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
        DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                fontSize: 13,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}