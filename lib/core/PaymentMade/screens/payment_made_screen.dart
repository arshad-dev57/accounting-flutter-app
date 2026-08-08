// screens/payments_made_screen.dart - PROFESSIONAL MOBILE DESIGN (NO WEB)

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/PaymentMade/controller/paymentmade_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/supplier/screen/supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PaymentsMadeScreen extends StatelessWidget {
  const PaymentsMadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMadeController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.payments.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Column(
                  children: [
                    _buildSummaryCards(controller),
                    const SizedBox(height: 8),
                    Expanded(child: _buildListView(controller, context)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kDanger.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showRecordPaymentDialog(controller, context),
          backgroundColor: kDanger,
          elevation: 0,
          child: const Icon(Icons.payment, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    PaymentMadeController controller,
  ) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payments Made',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.payments.length} payments',
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
                  GestureDetector(
                    onTap: () {
                      controller.loadPayments(resetPage: true);
                      controller.loadSummary();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.exportPayments(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search & Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
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
                      child: TextField(
                        onChanged: (value) => controller.searchPayments(value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search payments...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    child: DropdownButtonHideUnderline(
                      child: Obx(
                        () => DropdownButton<String>(
                          value: controller.selectedFilter.value,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          underline: const SizedBox.shrink(),
                          items: ['All', 'Today', 'This Week', 'This Month']
                              .map((f) {
                                return DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                );
                              })
                              .toList(),
                          onChanged: (v) {
                            if (v != null) controller.applyDateFilter(v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(PaymentMadeController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Total Paid',
              amount: controller.formatAmount(controller.totalPaid.value),
              color: kDanger,
              icon: Icons.payment,
              bgColor: kDanger.withOpacity(0.08),
              borderColor: kDanger.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'This Month',
              amount: controller.formatAmount(controller.thisMonthTotal.value),
              color: kPrimary,
              icon: Icons.calendar_month,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Pending',
              amount: controller.pendingCount.value.toString(),
              color: kWarning,
              icon: Icons.pending_outlined,
              bgColor: kWarning.withOpacity(0.08),
              borderColor: kWarning.withOpacity(0.2),
              isNumber: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    bool isNumber = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST VIEW WITH LAZY LOADING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildListView(
    PaymentMadeController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final payments = controller.payments;

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
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showRecordPaymentDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDanger,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!controller.isLoadingMore.value &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            controller.loadMoreData();
          }
          return false;
        },
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: payments.length + 1,
          itemBuilder: (context, index) {
            if (index == payments.length) {
              return Obx(
                () => controller.isLoadingMore.value
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: LoadingAnimationWidget.discreteCircle(
                            color: kPrimary,
                            size: 30,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }
            final payment = payments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentCard(payment, controller, context),
            );
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL PAYMENT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPaymentCard(
    PaymentMade payment,
    PaymentMadeController controller,
    BuildContext context,
  ) {
    final statusColor =
        payment.status == 'Cleared' || payment.status == 'Completed'
        ? kSuccess
        : kWarning;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentDetails(payment, controller, context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kDanger.withOpacity(0.15),
                            kDanger.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kDanger.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 22,
                        color: kDanger,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.paymentNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.supplierName,
                            style: TextStyle(
                              fontSize: 12,
                              color: kSubText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _statusBadge(payment.status, statusColor),
                              _badge(payment.paymentMethod, kPrimary),
                              _badge('Bill: ${payment.billNumber}', kSubText),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kDanger,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yy').format(payment.paymentDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: kSubText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showPaymentDetails(payment, controller, context),
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: kSubText,
                        ),
                        label: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 11,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.printVoucher(payment),
                        icon: const Icon(
                          Icons.print,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Voucher',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  // ═══════════════════════════════════════════════════════════════
  // RECORD PAYMENT DIALOG - PROFESSIONAL DESIGN
  // ═══════════════════════════════════════════════════════════════

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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Record Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record payment made to supplier',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: controller.isRecording.value
                              ? null
                              : () {
                                  controller.clearBillSelections();
                                  Navigator.pop(context);
                                },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Supplier Dropdown
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedSupplierId.isEmpty
                                        ? null
                                        : selectedSupplierId,
                                    decoration: InputDecoration(
                                      labelText: 'Supplier *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      isDense: true,
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: kSubText,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                    hint: Text(
                                      'Select supplier',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kSubText,
                                      ),
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
                                      await controller.getUnpaidBills(
                                        selectedSupplierId,
                                      );
                                      amount = 0;
                                      setState(() {});
                                    },
                                    validator: (v) =>
                                        v == null ? 'Supplier required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: kPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Get.to(() => const SuppliersScreen());
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

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
                                    final isSelected = controller
                                        .selectedBillIds
                                        .contains(bill.id);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? kDanger.withOpacity(0.05)
                                            : kBgLight,
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
                                            amount = controller
                                                .totalSelectedAmount
                                                .value;
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
                                                color: isSelected
                                                    ? kDanger
                                                    : kDanger,
                                              ),
                                            ),
                                          ],
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                                if (controller
                                                        .selectedBillIds
                                                        .length ==
                                                    controller
                                                        .currentBills
                                                        .length) {
                                                  controller
                                                      .clearBillSelections();
                                                } else {
                                                  for (var bill
                                                      in controller
                                                          .currentBills) {
                                                    if (!controller
                                                        .selectedBillIds
                                                        .contains(bill.id)) {
                                                      controller
                                                          .toggleBillSelection(
                                                            bill.id,
                                                            bill.outstanding,
                                                          );
                                                    }
                                                  }
                                                }
                                                amount = controller
                                                    .totalSelectedAmount
                                                    .value;
                                              });
                                            },
                                            child: Text(
                                              controller
                                                          .selectedBillIds
                                                          .length ==
                                                      controller
                                                          .currentBills
                                                          .length
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
                            const SizedBox(height: 16),

                            // Amount Field
                            TextFormField(
                              initialValue: amount > 0
                                  ? amount.toStringAsFixed(2)
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Payment Amount *',
                                prefixText: CurrencyUtils.prefix,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                ),
                                helperText:
                                    controller.totalSelectedAmount.value > 0
                                    ? 'Max: ${controller.formatAmount(controller.totalSelectedAmount.value)}'
                                    : null,
                                helperStyle: TextStyle(
                                  fontSize: 10,
                                  color: kSubText,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final val = double.tryParse(v) ?? 0;
                                final maxAmount =
                                    controller.totalSelectedAmount.value;
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
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Amount required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Payment Method
                            DropdownButtonFormField<String>(
                              value: paymentMethod,
                              decoration: InputDecoration(
                                labelText: 'Payment Method *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Text('Bank Transfer'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cash',
                                  child: Text('Cash'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cheque',
                                  child: Text('Cheque'),
                                ),
                                DropdownMenuItem(
                                  value: 'Credit Card',
                                  child: Text('Credit Card'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => paymentMethod = v!),
                            ),
                            const SizedBox(height: 16),

                            // Reference
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Reference Number',
                                hintText: 'e.g. TRX-001',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              onChanged: (v) => reference = v,
                            ),
                            const SizedBox(height: 16),

                            // Bank Account (for Bank Transfer)
                            if (paymentMethod == 'Bank Transfer') ...[
                              Obx(
                                () => DropdownButtonFormField<String>(
                                  value: selectedBankAccountId.isEmpty
                                      ? null
                                      : selectedBankAccountId,
                                  decoration: InputDecoration(
                                    labelText: 'From Bank Account *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: kSubText,
                                    ),
                                  ),
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
                              const SizedBox(height: 16),
                            ],

                            // Notes
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Notes',
                                hintText: 'Additional notes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              onChanged: (v) => notes = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.isRecording.value
                                ? null
                                : () {
                                    controller.clearBillSelections();
                                    Navigator.pop(context);
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
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
                                      if (!formKey.currentState!.validate())
                                        return;

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

                                      if (amount >
                                          controller
                                              .totalSelectedAmount
                                              .value) {
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
                                        bankAccountId:
                                            selectedBankAccountId.isEmpty
                                            ? null
                                            : selectedBankAccountId,
                                        notes: notes,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kDanger,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isRecording.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Record Payment',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYMENT DETAILS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showPaymentDetails(
    PaymentMade payment,
    PaymentMadeController controller,
    BuildContext context,
  ) {
    final statusColor =
        payment.status == 'Cleared' || payment.status == 'Completed'
        ? kSuccess
        : kWarning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: kDanger.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.payment,
                              size: 26,
                              color: kDanger,
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
                                        payment.paymentNumber,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: kText,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                        color: statusColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        payment.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}',
                                      style: TextStyle(
                                        fontSize: 11,
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
                      const SizedBox(height: 16),

                      // KPI Cards
                      Row(
                        children: [
                          _miniKpi(
                            'Amount',
                            controller.formatAmount(payment.amount),
                            kDanger,
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Bill',
                            payment.billNumber,
                            kPrimary,
                            Icons.receipt,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Method',
                            payment.paymentMethod,
                            kSubText,
                            Icons.payment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Supplier', payment.supplierName),
                      _detailRow('Bill #', payment.billNumber),
                      _detailRow(
                        'Bill Amount',
                        controller.formatAmount(payment.billAmount),
                      ),
                      _detailRow('Payment Method', payment.paymentMethod),
                      if (payment.reference.isNotEmpty)
                        _detailRow('Reference', payment.reference),
                      if (payment.bankAccountName.isNotEmpty)
                        _detailRow('Bank Account', payment.bankAccountName),
                      if (payment.notes.isNotEmpty)
                        _detailRow('Notes', payment.notes),
                      _detailRow(
                        'Recorded At',
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(payment.createdAt),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Footer Buttons
                      Row(
                        children: [
                          if (payment.paymentMethod == 'Cheque' &&
                              payment.status != 'Cleared') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    final confirm = await Get.dialog<bool>(
                                      AlertDialog(
                                        title: const Text(
                                          'Clear Cheque Payment',
                                        ),
                                        content: Text(
                                          'Clear cheque payment ${payment.paymentNumber}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: true),
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(color: kSuccess),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await controller.clearChequePayment(
                                        payment.id,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Clear Cheque',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kSuccess,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  controller.printVoucher(payment);
                                },
                                icon: Icon(
                                  Icons.print,
                                  size: 16,
                                  color: kSubText,
                                ),
                                label: Text(
                                  'Voucher',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kText,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final confirm = await Get.dialog<bool>(
                                    AlertDialog(
                                      title: const Text('Delete Payment'),
                                      content: Text(
                                        'Delete payment ${payment.paymentNumber}?\nThis will reverse the journal entry.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Get.back(result: true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: kDanger),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await controller.deletePayment(payment.id);
                                  }
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: kDanger,
                                ),
                                label: Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kDanger,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kDanger),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  controller.viewBill(payment);
                                },
                                icon: Icon(
                                  Icons.receipt,
                                  size: 16,
                                  color: kPrimary,
                                ),
                                label: Text(
                                  'View Bill',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
