// screens/accounts_payable_screen.dart - COMPLETE FIXED VERSION

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/AccountPayable/controller/account_payable_controller.dart';
import 'package:LedgerPro_app/core/Vendor&Supplier/screens/vendor_supplier_screen.dart';
import 'package:LedgerPro_app/core/warehouse/supplier/screen/supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountsPayableScreen extends StatelessWidget {
  const AccountsPayableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountsPayableController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.bills.isEmpty) {
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
                    Expanded(
                      child: _buildListView(controller, context),
                    ),
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
              color: kPrimary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddBillDialog(controller, context),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.black, size: 24),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context, AccountsPayableController controller) {
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
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accounts Payable',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.bills.length} bills',
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
                  GestureDetector(
                    onTap: controller.fetchAllData,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.exportReport(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: Colors.black.withOpacity(0.65),
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
                        onChanged: (value) => controller.searchBills(value),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search bills...',
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          underline: const SizedBox.shrink(),
                          items: ['All', 'Unpaid', 'Paid', 'Overdue', 'Partial'].map((f) {
                            return DropdownMenuItem(value: f, child: Text(f));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) controller.changeFilter(v);
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

  Widget _buildSummaryCards(AccountsPayableController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Outstanding',
              amount: _formatAmount(controller.totalOutstanding.value),
              color: kDanger,
              icon: Icons.payment,
              bgColor: kDanger.withOpacity(0.08),
              borderColor: kDanger.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Overdue',
              amount: _formatAmount(controller.totalOverdue.value),
              color: kWarning,
              icon: Icons.warning_amber_rounded,
              bgColor: kWarning.withOpacity(0.08),
              borderColor: kWarning.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Due This Month',
              amount: _formatAmount(controller.totalDueThisMonth.value),
              color: kPrimary,
              icon: Icons.calendar_month,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
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

  Widget _buildListView(AccountsPayableController controller, BuildContext context) {
    return Obx(() {
      final bills = controller.bills;

      if (bills.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No bills found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showAddBillDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Bill',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
          itemCount: bills.length + 1,
          itemBuilder: (context, index) {
            if (index == bills.length) {
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
            final bill = bills[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBillCard(bill, controller, context),
            );
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL BILL CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBillCard(
    Bill bill,
    AccountsPayableController controller,
    BuildContext context,
  ) {
    final statusColor = bill.status == 'Paid'
        ? kSuccess
        : bill.status == 'Overdue'
            ? kDanger
            : bill.status == 'Partial'
                ? kWarning
                : kPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
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
          onTap: () => _showBillDetails(bill, controller, context),
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
                            statusColor.withOpacity(0.15),
                            statusColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 22,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billNumber,
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
                            bill.supplierName,
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
                              _statusBadge(bill.status, statusColor),
                              _badge(
                                'Due: ${DateFormat('dd MMM yy').format(bill.dueDate)}',
                                bill.isOverdue ? kDanger : kSubText,
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
                          _formatAmount(bill.outstanding),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kDanger,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Outstanding',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kDanger,
                            ),
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
                        onPressed: () => _showBillDetails(bill, controller, context),
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
                    if (bill.status != 'Paid') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _recordBillPayment(bill, controller, context),
                          icon: const Icon(
                            Icons.payment,
                            size: 14,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Pay',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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
  // ADD BILL DIALOG - PROFESSIONAL DESIGN
  // ═══════════════════════════════════════════════════════════════

  void _showAddBillDialog(AccountsPayableController controller, BuildContext ctx) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    String supplierId = '';
    String reference = '';
    String description = '';
    double subtotal = 0;
    double taxRate = 0;
    double discount = 0;
    List<Map<String, dynamic>> items = [
      {'description': '', 'quantity': 1, 'unitPrice': 0.0},
    ];

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculateTotal() {
            double itemTotal = items.fold(
              0.0,
              (s, i) => s + (i['quantity'] as num).toDouble() * (i['unitPrice'] as num).toDouble(),
            );
            double tax = itemTotal * (taxRate / 100);
            return itemTotal + tax - discount;
          }

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
                            Icons.receipt_long,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Bill',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new supplier bill',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: controller.isSaving.value
                              ? null
                              : () => Navigator.pop(context),
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
                            _buildDatePickerField(
                              'Bill Date',
                              selectedDate,
                              (d) => setState(() => selectedDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            _buildDatePickerField(
                              'Due Date',
                              dueDate,
                              (d) => setState(() => dueDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            Obx(() {
                              final hasMatch = supplierId.isEmpty ||
                                  controller.suppliers.any(
                                    (s) => s.id == supplierId,
                                  );
                              return _buildSupplierDropdownField(
                                hasMatch ? supplierId : null,
                                (v) => setState(() => supplierId = v ?? ''),
                                controller.suppliers.toList(),
                                context,
                                () => controller.fetchAllData(),
                              );
                            }),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference',
                              hint: 'e.g., PO-001',
                              onChanged: (v) => reference = v,
                            ),
                            const SizedBox(height: 16),

                            // Items Section
                            _buildItemsSection(items, setState),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Tax Rate (%)',
                              hint: '0',
                              onChanged: (v) => setState(() => taxRate = double.tryParse(v) ?? 0),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Discount',
                              hint: '0.00',
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) => setState(() => discount = double.tryParse(v) ?? 0),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Description',
                              hint: 'Enter bill description',
                              onChanged: (v) => description = v,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // Total Box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kDanger.withOpacity(0.08),
                                    kDanger.withOpacity(0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kDanger.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(calculateTotal()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: kDanger,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
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
                            onPressed: controller.isSaving.value
                                ? null
                                : () => Navigator.pop(context),
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
                              onPressed: controller.isSaving.value
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;

                                      if (supplierId.isEmpty) {
                                        AppSnackbar.error(kDanger, 'Error', 'Please select a supplier');
                                        return;
                                      }

                                      Navigator.pop(context);
                                      await controller.createBill({
                                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                        'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
                                        'supplierId': supplierId,
                                        'reference': reference,
                                        'description': description,
                                        'items': items,
                                        'taxRate': taxRate,
                                        'discount': discount,
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isSaving.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Text(
                                      'Save Bill',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
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
  // BILL DETAILS DIALOG - PROFESSIONAL DESIGN
  // ═══════════════════════════════════════════════════════════════

  void _showBillDetails(
    Bill bill,
    AccountsPayableController controller,
    BuildContext context,
  ) {
    final statusColor = bill.status == 'Paid'
        ? kSuccess
        : bill.status == 'Overdue'
            ? kDanger
            : bill.status == 'Partial'
                ? kWarning
                : kPrimary;

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
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              size: 26,
                              color: statusColor,
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
                                        bill.billNumber,
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
                                        bill.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${DateFormat('dd MMM yyyy').format(bill.date)}',
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
                            'Total',
                            _formatAmount(bill.totalAmount),
                            kText,
                            Icons.receipt,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Paid',
                            _formatAmount(bill.paidAmount),
                            kSuccess,
                            Icons.check_circle,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Outstanding',
                            _formatAmount(bill.outstanding),
                            kDanger,
                            Icons.payment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Supplier', bill.supplierName),
                      _detailRow('Bill Date', DateFormat('dd MMM yyyy').format(bill.date)),
                      _detailRow('Due Date', DateFormat('dd MMM yyyy').format(bill.dueDate),
                          valueColor: bill.isOverdue ? kDanger : null),
                      if (bill.reference.isNotEmpty) _detailRow('Reference', bill.reference),
                      if (bill.description.isNotEmpty) _detailRow('Description', bill.description),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Items
                      if (bill.items.isNotEmpty) ...[
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bill.items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kText,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity} × ${_formatAmount(item.unitPrice)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: kSubText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatAmount(item.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kDanger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                        const SizedBox(height: 16),
                      ],

                      // Footer Buttons
                      Row(
                        children: [
                          if (bill.status != 'Paid') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _recordBillPayment(bill, controller, context);
                                  },
                                  icon: const Icon(
                                    Icons.payment,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    'Record Payment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
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
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimary,
                                  side: const BorderSide(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
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
  // RECORD PAYMENT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _recordBillPayment(
    Bill bill,
    AccountsPayableController controller,
    BuildContext ctx,
  ) {
    final formKey = GlobalKey<FormState>();
    double amount = bill.outstanding;
    DateTime paymentDate = DateTime.now();
    String paymentMethod = 'Bank Transfer';
    String reference = '';
    String selectedBankAccountId = '';

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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 420,
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
                      color: kSuccess.withOpacity(0.05),
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
                            color: kSuccess,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.black,
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
                                bill.billNumber,
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: controller.isProcessing.value
                              ? null
                              : () => Navigator.pop(context),
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
                            // Bill Summary
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kBgLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _detailRow('Supplier', bill.supplierName),
                                  _detailRow('Bill Date', DateFormat('dd MMM yyyy').format(bill.date)),
                                  _detailRow('Due Date', DateFormat('dd MMM yyyy').format(bill.dueDate),
                                      valueColor: bill.isOverdue ? kDanger : null),
                                  _detailRow('Total', _formatAmount(bill.totalAmount)),
                                  _detailRow('Outstanding', _formatAmount(bill.outstanding),
                                      valueColor: kDanger),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Payment Amount *',
                              hint: bill.outstanding.toStringAsFixed(2),
                              prefixText: CurrencyUtils.prefix,
                              onChanged: (v) => amount = double.tryParse(v) ?? 0,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Amount required';
                                final val = double.tryParse(v);
                                if (val == null || val <= 0) return 'Invalid amount';
                                if (val > bill.outstanding) return 'Exceeds outstanding';
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildDatePickerField(
                              'Payment Date',
                              paymentDate,
                              (d) => setState(() => paymentDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            _buildDropdownField(
                              label: 'Payment Method',
                              value: paymentMethod,
                              items: const ['Bank Transfer', 'Cash', 'Cheque', 'Credit Card'],
                              onChanged: (v) => setState(() => paymentMethod = v!),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Reference',
                              hint: 'e.g., PAY-001',
                              onChanged: (v) => reference = v,
                            ),
                            const SizedBox(height: 16),

                            if (paymentMethod == 'Bank Transfer') ...[
                              Obx(() {
                                final hasMatch = selectedBankAccountId.isEmpty ||
                                    controller.bankAccounts.any(
                                      (a) => (a['id'] ?? a['_id']).toString() == selectedBankAccountId,
                                    );
                                return _buildBankAccountDropdownField(
                                  hasMatch ? selectedBankAccountId : null,
                                  (v) => setState(() => selectedBankAccountId = v ?? ''),
                                  controller.bankAccounts.toList(),
                                );
                              }),
                            ],
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
                            onPressed: controller.isProcessing.value
                                ? null
                                : () => Navigator.pop(context),
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
                              onPressed: controller.isProcessing.value
                                  ? null
                                  : () {
                                      if (formKey.currentState!.validate()) {
                                        if (paymentMethod == 'Bank Transfer' && selectedBankAccountId.isEmpty) {
                                          AppSnackbar.error(kDanger, 'Error', 'Please select a bank account');
                                          return;
                                        }
                                        Navigator.pop(context);
                                        controller.recordPayment(
                                          supplierId: bill.supplierId,
                                          billId: bill.id,
                                          amount: amount,
                                          paymentDate: paymentDate,
                                          paymentMethod: paymentMethod,
                                          reference: reference,
                                          bankAccountId: selectedBankAccountId,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kSuccess,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isProcessing.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required void Function(String) onChanged,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? initialValue,
    TextEditingController? controller,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ═══════════════════════════════════════════════════════════════
// FIXED: Supplier Dropdown - Converts Supplier objects to Map
// ═══════════════════════════════════════════════════════════════

Widget _buildSupplierDropdownField(
  String? selectedId,
  void Function(String?) onChanged,
  List<Supplier> suppliers,  // ✅ Changed from List<Map<String, dynamic>> to List<Supplier>
  BuildContext context,
  VoidCallback onRefresh,
) {
  // Ensure selectedId is valid (exists in suppliers list)
  final validSelectedId = suppliers.any((s) => s.id == selectedId) ? selectedId : null;
  
  return Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<String>(
          value: validSelectedId,
          decoration: InputDecoration(
            labelText: 'Supplier *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            labelStyle: TextStyle(fontSize: 12, color: kSubText),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          hint: Text(
            suppliers.isEmpty ? 'No suppliers available' : 'Select supplier',
            style: TextStyle(fontSize: 12, color: kSubText),
          ),
          items: suppliers.isEmpty
              ? []
              : suppliers
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,  // ✅ Direct access to Supplier properties
                      child: Text(
                        s.name,  // ✅ Direct access
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
          onChanged: suppliers.isEmpty ? null : onChanged,
          validator: (value) => value == null ? 'Please select a supplier' : null,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.black, size: 20),
          onPressed: () async {
            Navigator.pop(context);
            await Get.to(() =>  SuppliersScreen());
            onRefresh();
          },
          padding: EdgeInsets.zero,
        ),
      ),
    ],
  );
}
  Widget _buildBankAccountDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> bankAccounts,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Bank Account *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      hint: Text(
        'Select bank account',
        style: TextStyle(fontSize: 12, color: kSubText),
      ),
      items: bankAccounts.isEmpty
          ? []
          : bankAccounts
              .map(
                (a) => DropdownMenuItem<String>(
                  value: (a['id'] ?? a['_id']).toString(),
                  child: Text(
                    a['accountName'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: bankAccounts.isEmpty ? null : onChanged,
      validator: (value) => value == null ? 'Please select a bank account' : null,
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    void Function(DateTime) onChanged,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: kSubText),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: kSubText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(
    List<Map<String, dynamic>> items,
    void Function(void Function()) setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item['description'],
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                          labelStyle: TextStyle(fontSize: 11, color: kSubText),
                        ),
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                        onChanged: (v) => setState(() => item['description'] = v),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    if (items.length > 1) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InkWell(
                          onTap: () => setState(() => items.removeAt(idx)),
                          child: Icon(Icons.delete, size: 18, color: kDanger),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item['quantity'].toString(),
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                          labelStyle: TextStyle(fontSize: 11, color: kSubText),
                        ),
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {
                          item['quantity'] = int.tryParse(v) ?? 1;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item['unitPrice'].toString(),
                        decoration: InputDecoration(
                          labelText: 'Unit Price *',
                          prefixText: CurrencyUtils.prefix,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                          labelStyle: TextStyle(fontSize: 11, color: kSubText),
                        ),
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) => setState(() {
                          item['unitPrice'] = double.tryParse(v) ?? 0;
                        }),
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter valid price'
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () => setState(() {
            items.add({
              'description': '',
              'quantity': 1,
              'unitPrice': 0.0,
            });
          }),
          icon: const Icon(Icons.add, size: 16, color: kPrimary),
          label: Text(
            'Add Item',
            style: TextStyle(fontSize: 12, color: kPrimary),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}