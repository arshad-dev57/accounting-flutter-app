// screens/payments_received_screen.dart - MOBILE & TABLET ONLY

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/paymentRecieved/controller/payment_recieved_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PaymentsReceivedScreen extends StatelessWidget {
  final String? customerId;
  final String? invoiceId;
  const PaymentsReceivedScreen({super.key, this.customerId, this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentReceivedController());
    if (customerId != null && customerId!.isNotEmpty) {
      controller.prefillCustomerId.value = customerId!;
    }
    if (invoiceId != null && invoiceId!.isNotEmpty) {
      controller.prefillInvoiceId.value = invoiceId!;
    }

    return _buildMobileLayout(context, controller);
  }

  // ==================== MOBILE & TABLET LAYOUT ====================

  Widget _buildMobileLayout(
    BuildContext context,
    PaymentReceivedController controller,
  ) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
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
            _buildFilterBar(controller, context),
            _buildSummaryCards(controller, context),
            Expanded(child: _buildPaymentsList(controller, context, isTablet)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordPaymentDialog(controller, context),
        backgroundColor: kSuccess,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PaymentReceivedController controller,
  ) {
    return AppBar(
      title: const Text(
        'Payments Received',
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
          icon: const Icon(Icons.date_range, color: Colors.black87),
          onPressed: () => _selectDateRange(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportPayments(),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    PaymentReceivedController controller,
    BuildContext context,
  ) {
    final filters = ['All', 'Today', 'This Week', 'This Month'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: filters.map((f) {
              final isSelected = controller.selectedFilter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) =>
                      controller.changeFilter(isSelected ? 'All' : f),
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

  Widget _buildSummaryCards(
    PaymentReceivedController controller,
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
                'Total Received',
                _formatAmount(controller.totalReceived.value),
                kSuccess,
                Icons.attach_money,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'This Month',
                _formatAmount(controller.thisMonth.value),
                kPrimary,
                Icons.calendar_month,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'This Week',
                _formatAmount(controller.thisWeek.value),
                kPrimary,
                Icons.view_week_outlined,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Today',
                _formatAmount(controller.today.value),
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

  Widget _buildPaymentsList(
    PaymentReceivedController controller,
    BuildContext context,
    bool isTablet,
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
                  backgroundColor: kSuccess,
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
          child: isTablet
              ? _buildTabletPaymentCard(payments[index], controller, context)
              : _buildMobilePaymentCard(payments[index], controller, context),
        ),
      );
    });
  }

  Widget _buildMobilePaymentCard(
    Payment payment,
    PaymentReceivedController controller,
    BuildContext context,
  ) {
    final statusColor = payment.status == 'Cleared' ? kSuccess : kWarning;

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
                        color: kSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 20,
                        color: kSuccess,
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
                            payment.customerName,
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
                          _formatAmount(payment.amount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kSuccess,
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
                        onPressed: () => controller.printReceipt(payment),
                        icon: const Icon(
                          Icons.print,
                          size: 14,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Receipt',
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

  Widget _buildTabletPaymentCard(
    Payment payment,
    PaymentReceivedController controller,
    BuildContext context,
  ) {
    final statusColor = payment.status == 'Cleared' ? kSuccess : kWarning;

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 22,
                    color: kSuccess,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            payment.paymentNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payment.status,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            payment.customerName,
                            style: TextStyle(
                              fontSize: 12,
                              color: kSubText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payment.invoiceNumber,
                              style: TextStyle(
                                fontSize: 10,
                                color: kPrimary,
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
                      _formatAmount(payment.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kSuccess,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.paymentMethod} • ${DateFormat('dd MMM yy').format(payment.paymentDate)}',
                      style: TextStyle(fontSize: 10, color: kSubText),
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

  // ==================== DIALOGS ====================

  void _showSearchDialog(
    BuildContext context,
    PaymentReceivedController controller,
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
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Payment #, customer, invoice…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => controller.searchPayments(v),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchPayments('');
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

  void _selectDateRange(
    PaymentReceivedController controller,
    BuildContext context,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );
    if (picked != null) controller.setDateRange(picked);
  }

  void _showPaymentDetails(
    Payment payment,
    PaymentReceivedController controller,
    BuildContext context,
  ) {
    final statusColor = payment.status == 'Cleared' ? kSuccess : kWarning;

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
                    color: kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, size: 28, color: kSuccess),
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
                    _buildDetailRow('Customer', payment.customerName),
                    _buildDetailRow('Invoice #', payment.invoiceNumber),
                    _buildDetailRow('Invoice Amount', _formatAmount(payment.invoiceAmount)),
                    Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                    _buildDetailRow('Payment Amount', _formatAmount(payment.amount), valueColor: kSuccess),
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
                      controller.viewInvoice(payment);
                    },
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text('View Invoice', style: TextStyle(fontSize: 12)),
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
                      controller.printReceipt(payment);
                    },
                    icon: const Icon(Icons.print, size: 16, color: Colors.black87),
                    label: const Text('Receipt', style: TextStyle(fontSize: 12, color: Colors.black87)),
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

  // ─── Record Payment Dialog with Multi-Invoice Selection ──────────

  void _showRecordPaymentDialog(
    PaymentReceivedController controller,
    BuildContext ctx,
  ) {
    final formKey = GlobalKey<FormState>();
    String selectedCustomerId = '';
    String selectedInvoiceId = ''; // ✅ FIXED: Store selected invoice ID
    double amount = 0;
    String paymentMethod = 'Bank Transfer';
    String reference = '';
    String selectedBankAccountId = '';
    String notes = '';

    showDialog(
      context: ctx,
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
                        color: kSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.payment, size: 18, color: kSuccess),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Record Payment Received',
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
                        controller.clearInvoiceSelections();
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
                          // Customer Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedCustomerId.isEmpty
                                ? null
                                : selectedCustomerId,
                            decoration: _inputDecoration('Select Customer *'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            hint: Text(
                              'Select customer',
                              style: TextStyle(fontSize: 12, color: kSubText),
                            ),
                            items: controller.customers
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              selectedCustomerId = v!;
                              selectedInvoiceId = ''; // ✅ Reset invoice selection
                              amount = 0;
                              controller.clearInvoiceSelections();
                              await controller.fetchUnpaidInvoices(
                                selectedCustomerId,
                              );
                              setState(() {});
                            },
                            validator: (v) =>
                                v == null ? 'Customer required' : null,
                          ),
                          const SizedBox(height: 12),
                          
                          // ─── Invoice Dropdown ──────────────────────
                          Obx(() {
                            if (selectedCustomerId.isNotEmpty &&
                                controller.unpaidInvoices.isEmpty) {
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
                                        'No unpaid invoices for this customer.',
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
                            
                            if (controller.unpaidInvoices.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedInvoiceId.isEmpty
                                      ? null
                                      : selectedInvoiceId,
                                  decoration: _inputDecoration('Select Invoice *'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  hint: Text(
                                    'Select invoice',
                                    style: TextStyle(fontSize: 12, color: kSubText),
                                  ),
                                  items: controller.unpaidInvoices
                                      .map(
                                        (inv) => DropdownMenuItem(
                                          value: inv.id, // ✅ Store invoice ID
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                inv.invoiceNumber,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Due: ${_formatAmount(inv.outstanding)} • ${DateFormat('dd MMM yyyy').format(inv.dueDate)}',
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
                                  onChanged: (v) {
                                    selectedInvoiceId = v!; // ✅✅✅ Store the invoice ID
                                    final inv = controller.unpaidInvoices
                                        .firstWhere((i) => i.id == v);
                                    amount = inv.outstanding;
                                    setState(() {});
                                  },
                                  validator: (v) =>
                                      controller.unpaidInvoices.isNotEmpty && v == null
                                          ? 'Invoice required'
                                          : null,
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 12),
                          
                          // Amount Field
                          _amountField(
                            amount,
                            (v) {
                              amount = double.tryParse(v) ?? 0;
                              setState(() {});
                            },
                            maxAmount: 0,
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
                                decoration: _inputDecoration('Deposit To'),
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
                                              '${acc.number} • Balance: ${_formatAmount(acc.balance)}',
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
                                        v == null
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
                          controller.clearInvoiceSelections();
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
                                    if (selectedInvoiceId.isEmpty) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Please select an invoice',
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
                                    
                                    // ✅ Validate amount against invoice outstanding
                                    final selectedInvoice = controller.unpaidInvoices
                                        .firstWhere((i) => i.id == selectedInvoiceId);
                                    if (amount > selectedInvoice.outstanding) {
                                      AppSnackbar.error(
                                        kDanger,
                                        'Error',
                                        'Amount cannot exceed outstanding balance',
                                      );
                                      return;
                                    }
                                    
                                    Navigator.pop(context);
                                    await controller.recordPayment(
                                      customerId: selectedCustomerId,
                                      invoiceId: selectedInvoiceId, // ✅ Pass invoice ID
                                      amount: amount,
                                      paymentDate: DateTime.now(),
                                      paymentMethod: paymentMethod,
                                      reference: reference,
                                      bankAccountId: selectedBankAccountId.isEmpty
                                          ? null
                                          : selectedBankAccountId,
                                      notes: notes,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
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

  // ─── Form Helpers ─────────────────────────────────────────────────

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