import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/Income/controller/income_controller.dart';
import 'package:LedgerPro_app/core/Income/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IncomeController());
    return _buildMobileLayout(context, controller);
  }

  // ==================== MOBILE/TABLET LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context, IncomeController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.incomes.isEmpty) {
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
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!controller.isLoadingMore.value &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    controller.loadMoreData();
                  }
                  return false;
                },
                child: _buildIncomeList(controller, context),
              ),
            ),
            Obx(() => controller.isLoadingMore.value
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: LoadingAnimationWidget.discreteCircle(
                        color: kPrimary,
                        size: 30,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeDialog(controller, context),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, IncomeController controller) {
    return AppBar(
      title: const Text(
        'Income',
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
          onPressed: () => controller.exportIncomes(),
        ),
      ],
    );
  }

  Widget _buildFilterBar(IncomeController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: controller.incomeTypes.map((type) {
              final isSelected = controller.selectedType.value == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) =>
                      controller.applyTypeFilter(isSelected ? 'All' : type),
                  backgroundColor: kBg,
                  selectedColor: kPrimary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? kPrimary : kSubText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildSummaryCards(IncomeController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _buildSummaryCard(
                'Total Income',
                controller.formatAmount(controller.totalIncome.value),
                kSuccess,
                Icons.trending_up,
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
                kWarning,
                Icons.calendar_today,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Total Tax',
                controller.formatAmount(controller.totalTax.value),
                kWarning,
                Icons.receipt,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Records',
                controller.totalCount.value.toString(),
                kPrimary,
                Icons.receipt_long,
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
    String amount,
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
            amount,
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

  Widget _buildIncomeList(IncomeController controller, BuildContext context) {
    return Obx(() {
      final incomes = controller.incomes;

      if (controller.isLoading.value && incomes.isEmpty) {
        return const SizedBox.shrink();
      }

      if (incomes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No income records found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddIncomeDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Income',
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
        itemCount: incomes.length,
        itemBuilder: (context, index) {
          final income = incomes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIncomeCard(income, controller, context),
          );
        },
      );
    });
  }

  Widget _buildIncomeCard(
    Income income,
    IncomeController controller,
    BuildContext context,
  ) {
    final statusColor = income.status == 'Posted'
        ? kSuccess
        : income.status == 'Draft'
            ? kWarning
            : kDanger;
    final typeColor = Color(int.parse(
            controller.getTypeColor(income.incomeType).substring(1, 7),
            radix: 16) +
        0xFF000000);

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
          onTap: () => _showIncomeDetails(income, controller, context),
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
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        controller.getTypeIcon(income.incomeType),
                        size: 20,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            income.incomeNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            income.customerName.isNotEmpty
                                ? '${income.incomeType} • ${income.customerName}'
                                : income.incomeType,
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
                                  income.status,
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
                                  income.paymentMethod,
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
                          controller.formatAmount(income.totalAmount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kSuccess,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yy').format(income.date),
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
                            _showIncomeDetails(income, controller, context),
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
                    if (income.status == 'Draft') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.postIncome(income.id),
                          icon: const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.black87,
                          ),
                          label: const Text(
                            'Post',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
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

  // ==================== ADD INCOME DIALOG ====================

  void _showAddIncomeDialog(IncomeController controller, BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    String incomeType = 'Sales';
    String? selectedIncomeAccountId; // ✅ NEW: Income Account
    String? selectedCustomerId;
    double simpleAmount = 0;
    List<Map<String, dynamic>> items = [
      {'description': '', 'quantity': 1, 'unitPrice': 0.0}
    ];
    double taxRate = 0;
    String description = '';
    String reference = '';
    String paymentMethod = 'Cash';
    String? selectedBankAccountId;

    bool requiresItems() => incomeType == 'Sales' || incomeType == 'Services';

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double calculateTotal() {
            if (requiresItems()) {
              double total = items.fold(
                0.0,
                (s, i) => s +
                    (i['quantity'] ?? 1).toDouble() *
                        (i['unitPrice'] ?? 0).toDouble(),
              );
              return total + total * (taxRate / 100);
            }
            return simpleAmount;
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 92.w,
              constraints: BoxConstraints(maxHeight: 85.h),
              padding: EdgeInsets.all(5.w),
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
                        child: Icon(Icons.trending_up, size: 18, color: kSuccess),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Income',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
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
                            // Date Picker
                            _buildDatePickerField(
                              'Date',
                              selectedDate,
                              (d) => setState(() => selectedDate = d),
                              context,
                            ),
                            const SizedBox(height: 12),
                            
                            // Income Type Dropdown
                            _buildDropdownField(
                              label: 'Income Type',
                              value: incomeType,
                              items: controller.incomeTypes.skip(1).toList(),
                              onChanged: (v) => setState(() => incomeType = v!),
                            ),
                            const SizedBox(height: 12),
                            
                            // ─── ✅ NEW: Income Account Dropdown ──────
                            if (controller.incomeAccounts.isNotEmpty) ...[
                              _buildIncomeAccountDropdownField(
                                selectedIncomeAccountId,
                                (v) => setState(() => selectedIncomeAccountId = v),
                                controller.incomeAccounts,
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Customer Dropdown
                            if (controller.customers.isNotEmpty)
                              _buildCustomerDropdownField(
                                selectedCustomerId,
                                (v) => setState(() => selectedCustomerId = v),
                                controller.customers,
                              ),
                            if (controller.customers.isNotEmpty)
                              const SizedBox(height: 12),
                            
                            // Items or Simple Amount
                            if (requiresItems()) ...[
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...items.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _formField(
                                              'Description *',
                                              '',
                                              (v) => item['description'] = v,
                                              initialValue: item['description'],
                                            ),
                                          ),
                                          if (items.length > 1) ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => setState(() {
                                                items.removeAt(idx);
                                              }),
                                              child: Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: kDanger,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _formField(
                                              'Qty',
                                              '1',
                                              (v) => item['quantity'] =
                                                  int.tryParse(v) ?? 1,
                                              initialValue: item['quantity']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: _formField(
                                              'Unit Price *',
                                              '0.00',
                                              (v) => item['unitPrice'] =
                                                  double.tryParse(v) ?? 0,
                                              initialValue: item['unitPrice']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              prefixText: CurrencyUtils.prefix,
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
                                    'unitPrice': 0.0
                                  });
                                }),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'Add Item',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _formField(
                                'Tax Rate (%)',
                                '0',
                                (v) => taxRate = double.tryParse(v) ?? 0,
                                keyboardType: TextInputType.number,
                              ),
                            ] else
                              _formField(
                                'Amount *',
                                '0.00',
                                (v) => simpleAmount = double.tryParse(v) ?? 0,
                                keyboardType: TextInputType.number,
                                prefixText: CurrencyUtils.prefix,
                              ),
                            const SizedBox(height: 12),
                            
                            // Description and Reference
                            _formField(
                              'Description',
                              '',
                              (v) => description = v,
                            ),
                            const SizedBox(height: 12),
                            _formField(
                              'Reference #',
                              '',
                              (v) => reference = v,
                            ),
                            const SizedBox(height: 12),
                            
                            // Payment Method Dropdown
                            _buildDropdownField(
                              label: 'Payment Method',
                              value: paymentMethod,
                              items: const [
                                'Cash',
                                'Bank Transfer',
                                'Cheque',
                                'Credit Card'
                              ],
                              onChanged: (v) {
                                setState(() {
                                  paymentMethod = v!;
                                  if (paymentMethod == 'Cash') {
                                    selectedBankAccountId = null;
                                  }
                                });
                              },
                            ),
                            
                            // Bank Account dropdown - show only for non-Cash
                            if (paymentMethod != 'Cash' &&
                                controller.bankAccounts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildBankDropdownField(
                                selectedBankAccountId,
                                (v) {
                                  setState(() {
                                    selectedBankAccountId = v;
                                    print('🔍 Bank account selected: $v');
                                  });
                                },
                                controller.bankAccounts,
                              ),
                            ],
                            const SizedBox(height: 12),
                            
                            // Total Amount
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: kSuccess.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: kSuccess.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    controller.formatAmount(calculateTotal()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: kSuccess,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: kSubText,
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
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      // ─── ✅ Validate Income Account ──
                                      if (selectedIncomeAccountId == null || selectedIncomeAccountId!.isEmpty) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please select an income account',
                                        );
                                        return;
                                      }

                                      if (requiresItems()) {
                                        final hasInvalidItem = items.any((i) {
                                          final desc = (i['description'] ?? '')
                                              .toString()
                                              .trim();
                                          final price = double.tryParse(
                                                  i['unitPrice'].toString()) ??
                                              0.0;
                                          return desc.isEmpty || price <= 0;
                                        });
                                        if (hasInvalidItem) {
                                          AppSnackbar.error(
                                            kWarning,
                                            'Error',
                                            'Please fill all item details',
                                          );
                                          return;
                                        }
                                      } else if (simpleAmount <= 0) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please enter a valid amount',
                                        );
                                        return;
                                      }

                                      // Bank Transfer requires a bank account
                                      if (paymentMethod != 'Cash' &&
                                          (selectedBankAccountId == null ||
                                              selectedBankAccountId!.isEmpty)) {
                                        AppSnackbar.error(
                                          kWarning,
                                          'Error',
                                          'Please select a bank account for $paymentMethod',
                                        );
                                        return;
                                      }

                                      final finalBankAccountId =
                                          paymentMethod == 'Cash'
                                              ? null
                                              : selectedBankAccountId;

                                      print('🔍 Payment Method: $paymentMethod');
                                      print('🔍 Selected Income Account: $selectedIncomeAccountId');
                                      print('🔍 Selected Bank Account: $selectedBankAccountId');
                                      print('🔍 Final Bank Account ID: $finalBankAccountId');

                                      Navigator.pop(context);
                                      await controller.createIncome(
                                        date: selectedDate,
                                        incomeType: incomeType,
                                        incomeAccountId: selectedIncomeAccountId, // ✅ NEW
                                        customerId: selectedCustomerId,
                                        items: requiresItems() ? items : [],
                                        amount: requiresItems()
                                            ? null
                                            : simpleAmount,
                                        taxRate: requiresItems() ? taxRate : 0,
                                        description: description,
                                        reference: reference,
                                        paymentMethod: paymentMethod,
                                        bankAccountId: finalBankAccountId,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isProcessing.value
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: LoadingAnimationWidget.waveDots(
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  )
                                : Text(
                                    'Save Income',
                                    style: TextStyle(
                                      fontSize: 13.sp,
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
          );
        },
      ),
    );
  }

  // ─── ✅ NEW: Income Account Dropdown Field ──────────────────
  Widget _buildIncomeAccountDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> incomeAccounts,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Income Account *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 12.sp, color: kText),
      hint: Text(
        'Select income account',
        style: TextStyle(fontSize: 12.sp, color: kSubText),
      ),
      items: incomeAccounts.map((a) => DropdownMenuItem<String>(
        value: (a['id'] ?? a['_id']).toString(),
        child: Text(
          '${a['code']} - ${a['name']}',
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an income account';
        }
        return null;
      },
    );
  }

  // ==================== INCOME DETAILS DIALOG ====================

  void _showIncomeDetails(
    Income income,
    IncomeController controller,
    BuildContext context,
  ) {
    final statusColor = income.status == 'Posted'
        ? kSuccess
        : income.status == 'Draft'
            ? kWarning
            : kDanger;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 92.w,
          constraints: const BoxConstraints(maxHeight: 600),
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
                    child: Icon(
                      Icons.trending_up,
                      size: 28,
                      color: kSuccess,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          income.incomeNumber,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        Text(
                          '${income.incomeType} • ${DateFormat('dd MMM yyyy').format(income.date)}',
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
                      income.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow('Income Type', income.incomeType),
                      
                      // ─── ✅ NEW: Show Income Account ──────────────
                      if (income.incomeAccount != null) ...[
                        _buildDetailRow(
                          'Income Account',
                          '${income.incomeAccount?['code']} - ${income.incomeAccount?['name']}',
                        ),
                      ],
                      
                      if (income.customerName.isNotEmpty)
                        _buildDetailRow('Customer', income.customerName),
                      _buildDetailRow('Payment Method', income.paymentMethod),
                      if (income.reference.isNotEmpty)
                        _buildDetailRow('Reference', income.reference),
                      _buildDetailRow('Subtotal', _formatAmount(income.subtotal)),
                      if (income.taxRate > 0)
                        _buildDetailRow(
                          'Tax (${income.taxRate.toStringAsFixed(0)}%)',
                          _formatAmount(income.taxAmount),
                        ),
                      Divider(height: 20, color: Colors.grey.withOpacity(0.15)),
                      _buildDetailRow(
                        'Total Amount',
                        _formatAmount(income.totalAmount),
                        valueColor: kSuccess,
                      ),
                      if (income.description.isNotEmpty)
                        _buildDetailRow('Description', income.description),
                      if (income.items.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...income.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(8),
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kText,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} × ${_formatAmount(item.unitPrice)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatAmount(item.amount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kSuccess,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (income.status == 'Draft') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          controller.postIncome(income.id);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Post Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
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
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: kSubText,
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
    );
  }

  // ==================== DIALOGS ====================

  void _showSearchDialog(BuildContext context, IncomeController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Income',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller.searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter income number, customer...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchController.clear();
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

  void _showFilterDialog(IncomeController controller, BuildContext context) {
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
                  initialDateRange: controller.startDate.value != null &&
                          controller.endDate.value != null
                      ? DateTimeRange(
                          start: controller.startDate.value!,
                          end: controller.endDate.value!,
                        )
                      : null,
                );
                if (range != null) {
                  controller.setDateRange(range.start, range.end);
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
                controller.clearFilters();
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

  // ==================== HELPER WIDGETS ====================

  Widget _formField(
    String label,
    String hint,
    void Function(String) onChanged, {
    String initialValue = '',
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 12.sp, color: kText),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T extends String>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 12.sp, color: kText),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
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
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
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
                    style: TextStyle(fontSize: 10.sp, color: kSubText),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: kText,
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

  Widget _buildCustomerDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> customers,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Customer',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 12.sp, color: kText),
      hint: Text(
        'Select customer',
        style: TextStyle(fontSize: 12.sp, color: kSubText),
      ),
      items: customers
          .map((c) => DropdownMenuItem<String>(
                value: (c['id'] ?? c['_id']).toString(),
                child: Text(
                  c['name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBankDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> bankAccounts,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      decoration: InputDecoration(
        labelText: 'Bank Account',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11.sp, color: kSubText),
      ),
      style: TextStyle(fontSize: 12.sp, color: kText),
      hint: Text(
        'Select bank account',
        style: TextStyle(fontSize: 12.sp, color: kSubText),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None (Cash)'),
        ),
        ...bankAccounts.map((a) => DropdownMenuItem<String>(
              value: (a['id'] ?? a['_id']).toString(),
              child: Text(
                a['accountName'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (value) {
        onChanged(value);
        print('🔍 Selected bank account: $value');
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
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