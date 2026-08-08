import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/dashboard/controllers/transaction_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: _buildAppBar(controller),
        body: Obx(() {
          if (controller.isLoading.value && controller.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: ResponsiveUtils.isWeb(context) ? 32 : 40,
                  ),

                  Text(
                    'Loading transactions...',
                    style: TextStyle(fontSize: 13.sp, color: kSubText),
                  ),
                ],
              ),
            );
          }

          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 12.w, color: kDanger),
                  SizedBox(height: 2.h),
                  Text(
                    controller.errorMessage.value,
                    style: TextStyle(fontSize: 13.sp, color: kDanger),
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () => controller.refreshData(),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                    child: Text('Retry', style: TextStyle(fontSize: 13.sp)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildPeriodSelector(controller),
              _buildSummaryCards(controller),
              _buildTabs(controller),
              Expanded(child: _buildTransactionsList(controller)),
            ],
          );
        }),
        floatingActionButton: _buildFAB(controller),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TransactionController controller) {
    return AppBar(
      title: Text(
        'Transactions',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.filter_alt_outlined, color: Colors.white, size: 5.w),
          onPressed: () => _showFilterDialog(controller),
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.white, size: 5.w),
          onPressed: () => _showSearchDialog(controller),
        ),
        IconButton(
          icon: Icon(Icons.download_outlined, color: Colors.white, size: 5.w),
          onPressed: () => controller.exportTransactions(),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(TransactionController controller) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      color: kCardBg,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 6.h,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedPeriod.value,
                    icon: Icon(Icons.arrow_drop_down, size: 5.w),
                    isExpanded: true,
                    style: TextStyle(fontSize: 13.sp, color: kText),
                    items: controller.periodOptions.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period, style: TextStyle(fontSize: 13.sp)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        if (value == 'Custom Range') {
                          _selectDateRange(controller);
                        } else {
                          controller.changePeriod(value);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.selectedDateRange.value != null) {
              return Row(
                children: [
                  SizedBox(width: 3.w),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 6.h,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${DateFormat('dd MMM yyyy').format(controller.selectedDateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(controller.selectedDateRange.value!.end)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.clearDateRange(),
                            child: Icon(
                              Icons.close,
                              size: 5.w,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TransactionController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _buildSummaryCard(
                'Total Income',
                controller.formatAmount(controller.totalIncome.value),
                kSuccess,
                Icons.trending_up,
                controller.totalIncome.value,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Obx(
              () => _buildSummaryCard(
                'Total Expense',
                controller.formatAmount(controller.totalExpense.value),
                kDanger,
                Icons.trending_down,
                controller.totalExpense.value,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Obx(
              () => _buildSummaryCard(
                'Net Cash Flow',
                controller.formatAmount(controller.netCashFlow.value),
                controller.netCashFlow.value >= 0 ? kSuccess : kDanger,
                controller.netCashFlow.value >= 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                controller.netCashFlow.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
    double value,
  ) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 4.w, color: color),
              SizedBox(width: 1.5.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(TransactionController controller) {
    return Container(
      color: kCardBg,
      child: TabBar(
        tabs: [
          Tab(
            text: 'All',
            icon: Icon(Icons.list, size: 4.w),
          ),
          Tab(
            text: 'Income',
            icon: Icon(Icons.trending_up, size: 4.w, color: kSuccess),
          ),
          Tab(
            text: 'Expense',
            icon: Icon(Icons.trending_down, size: 4.w, color: kDanger),
          ),
        ],
        labelColor: kPrimary,
        unselectedLabelColor: kSubText,
        indicatorColor: kPrimary,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        onTap: (index) {
          controller.changeTab(index);
        },
      ),
    );
  }

  Widget _buildTransactionsList(TransactionController controller) {
    if (controller.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 15.w,
              color: kSubText.withOpacity(0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 14.sp,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickActionButton(
                  'Add Income',
                  Icons.add_circle_outline,
                  kSuccess,
                  () {
                    _showAddTransactionDialog(controller, 'income');
                  },
                ),
                SizedBox(width: 3.w),
                _buildQuickActionButton(
                  'Add Expense',
                  Icons.remove_circle_outline,
                  kDanger,
                  () {
                    _showAddTransactionDialog(controller, 'expense');
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 100) {
          if (controller.hasMore.value && !controller.isLoadingMore.value) {
            controller.loadMoreTransactions();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.all(4.w),
        itemCount:
            controller.transactions.length + (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.transactions.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Center(
                child: LoadingAnimationWidget.waveDots(
                  color: kPrimary,
                  size: 10.w,
                ),
              ),
            );
          }
          final transaction = controller.transactions[index];
          return _buildTransactionCard(controller, transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionController controller,
    Map<String, dynamic> transaction,
  ) {
    final type = transaction['type'] as String? ?? '';
    final isIncome = type == 'income';
    final amountColor = isIncome ? kSuccess : kDanger;
    final amountPrefix = isIncome ? '+' : '-';

    final icon = controller.getIconForTransaction(transaction);
    final color = controller.getColorForTransaction(transaction);
    final title = controller.getTransactionTitle(transaction);
    final subtitle = controller.getTransactionSubtitle(transaction);

    // SAFE DATE PARSING
    final dateStr = transaction['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    // FIX: Safe amount parsing with null check
    dynamic amountValue = transaction['amount'];
    double amount = 0.0;
    if (amountValue is num) {
      amount = amountValue.toDouble();
    } else if (amountValue is String) {
      amount = double.tryParse(amountValue) ?? 0.0;
    } else {
      amount = 0.0;
    }

    // SAFE OUTSTANDING PARSING
    dynamic outstandingValue = transaction['outstanding'];
    double? outstanding;
    if (outstandingValue is num) {
      outstanding = outstandingValue.toDouble();
    } else if (outstandingValue is String) {
      outstanding = double.tryParse(outstandingValue);
    }

    // SAFE STRING FIELDS
    final paymentMethod = transaction['paymentMethod'] as String? ?? 'Cash';
    final description = transaction['description'] as String? ?? '';
    final reference = transaction['reference'] as String? ?? '';
    final transactionNumber = transaction['transactionNumber'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetails(controller, transaction),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 7.w, color: color),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 12.sp, color: kSubText),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                            style: TextStyle(fontSize: 12.sp, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$amountPrefix ${controller.formatAmount(amount)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: amountColor,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? kSuccess.withOpacity(0.1)
                                : kDanger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paymentMethod,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: amountColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (outstanding != null && outstanding > 0)
                          Padding(
                            padding: EdgeInsets.only(top: 0.3.h),
                            child: Text(
                              'Outstanding: ${controller.formatAmount(outstanding)}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: kWarning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 4.w, color: kSubText),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: kSubText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 1.h),
                Divider(color: kBorder, height: 1),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.receipt, size: 3.5.w, color: kSubText),
                          SizedBox(width: 1.w),
                          Text(
                            reference.isNotEmpty
                                ? reference
                                : transactionNumber,
                            style: TextStyle(fontSize: 12.sp, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showTransactionDetails(controller, transaction),
                      icon: Icon(Icons.visibility, size: 4.w, color: kPrimary),
                      label: Text(
                        'Details',
                        style: TextStyle(fontSize: 12.sp, color: kPrimary),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
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

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 4.w, color: color),
        label: Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1),
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(TransactionController controller) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionMenu(controller),
      backgroundColor: kPrimary,
      icon: Icon(Icons.add, color: Colors.white, size: 5.w),
      label: Text(
        'Add Transaction',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevation: 3,
    );
  }

  void _showQuickActionMenu(TransactionController controller) {
    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Transaction',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Income',
                    Icons.add_circle_outline,
                    kSuccess,
                    () {
                      Navigator.pop(context);
                      _showAddTransactionDialog(controller, 'income');
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildQuickActionCard(
                    'Expense',
                    Icons.remove_circle_outline,
                    kDanger,
                    () {
                      Navigator.pop(context);
                      _showAddTransactionDialog(controller, 'expense');
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Divider(color: kBorder),
            SizedBox(height: 1.h),
            _buildQuickActionListItem(
              'Transfer',
              Icons.swap_horiz,
              kPrimary,
              () {
                Navigator.pop(context);
                AppSnackbar.info('Transfer', 'Transfer feature coming soon');
              },
            ),
            _buildQuickActionListItem(
              'Import Transactions',
              Icons.import_export,
              kPrimary,
              () {
                Navigator.pop(context);
                AppSnackbar.info('Import', 'Import feature coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 8.w, color: color),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionListItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(fontSize: 13.sp, color: kText),
      ),
      trailing: Icon(Icons.chevron_right, size: 5.w, color: kSubText),
      onTap: onTap,
    );
  }

  void _showAddTransactionDialog(
    TransactionController controller,
    String type,
  ) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    double amount = 0;
    DateTime date = DateTime.now();
    String category = type == 'income'
        ? (controller.incomeCategories.isNotEmpty
              ? controller.incomeCategories[0]
              : 'Sales')
        : (controller.expenseCategories.isNotEmpty
              ? controller.expenseCategories[0]
              : 'Rent');
    String paymentMethod = 'Cash';
    String reference = '';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 90.w,
          constraints: BoxConstraints(maxHeight: 85.h),
          padding: EdgeInsets.all(5.w),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add ${type == 'income' ? 'Income' : 'Expense'}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Title *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              onChanged: (v) => title = v,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Title required'
                                  : null,
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Amount *',
                                prefixText: CurrencyUtils.prefix,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  amount = double.tryParse(v) ?? 0,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Amount required'
                                  : null,
                            ),
                            SizedBox(height: 2.h),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: Get.context!,
                                  initialDate: date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null)
                                  setState(() => date = picked);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 5.w,
                                      color: kPrimary,
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date *',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: kSubText,
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(date),
                                            style: TextStyle(
                                              fontSize: 13.sp,
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
                            ),
                            SizedBox(height: 2.h),
                            Obx(
                              () => Container(
                                decoration: BoxDecoration(
                                  color: kCardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: category,
                                  decoration: InputDecoration(
                                    labelText: 'Category *',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 3.w,
                                      vertical: 1.5.h,
                                    ),
                                    labelStyle: TextStyle(fontSize: 12.sp),
                                  ),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: kText,
                                  ),
                                  dropdownColor: kCardBg,
                                  items:
                                      (type == 'income'
                                              ? controller.incomeCategories
                                              : controller.expenseCategories)
                                          .map((cat) {
                                            return DropdownMenuItem(
                                              value: cat,
                                              child: Text(
                                                cat,
                                                style: TextStyle(color: kText),
                                              ),
                                            );
                                          })
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => category = v!),
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: paymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Payment Method *',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 1.5.h,
                                  ),
                                  labelStyle: TextStyle(fontSize: 12.sp),
                                ),
                                style: TextStyle(fontSize: 14.sp, color: kText),
                                dropdownColor: kCardBg,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Cash',
                                    child: Text('Cash'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Bank Transfer',
                                    child: Text('Bank Transfer'),
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
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Reference Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              onChanged: (v) => reference = v,
                            ),
                            SizedBox(height: 2.h),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                fillColor: kCardBg,
                                filled: true,
                                labelStyle: TextStyle(fontSize: 12.sp),
                              ),
                              style: TextStyle(fontSize: 14.sp, color: kText),
                              maxLines: 2,
                              onChanged: (v) => description = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Get.back();
                              controller.createTransaction(
                                type: type,
                                title: title,
                                description: description,
                                amount: amount,
                                date: date,
                                category: category,
                                paymentMethod: paymentMethod,
                                reference: reference,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'income'
                                ? kSuccess
                                : kDanger,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            type == 'income' ? 'Add Income' : 'Add Expense',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
    TransactionController controller,
    Map<String, dynamic> transaction,
  ) {
    final isIncome = transaction['type'] == 'income';
    final amountColor = isIncome ? kSuccess : kDanger;
    final date = DateTime.parse(transaction['date']);

    // FIX: Use getIconForTransaction instead of getIconForCategory
    final icon = controller.getIconForTransaction(transaction);
    final color = controller.getColorForTransaction(transaction);
    final title = controller.getTransactionTitle(transaction);
    final subtitle = controller.getTransactionSubtitle(transaction);
    final amount = (transaction['amount'] as num).toDouble();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: 85.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 7.w, color: color),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      Text(
                        transaction['transactionNumber'] ??
                            transaction['id'] ??
                            '',
                        style: TextStyle(fontSize: 12.sp, color: kSubText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isIncome ? 'Income' : 'Expense',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
              'Date',
              DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(date),
            ),
            _buildDetailRow('Category', transaction['category']),
            _buildDetailRow(
              'Amount',
              '${isIncome ? '+' : '-'} ${controller.formatAmount(amount)}',
              color: amountColor,
            ),
            _buildDetailRow('Payment Method', transaction['paymentMethod']),
            _buildDetailRow(
              'Reference',
              transaction['reference'] ??
                  transaction['transactionNumber'] ??
                  'N/A',
            ),
            if (transaction['description'] != null &&
                transaction['description'].isNotEmpty)
              _buildDetailRow('Description', transaction['description']),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      AppSnackbar.info('Print', 'Printing receipt...');
                    },
                    icon: Icon(Icons.print, size: 4.5.w),
                    label: Text('Print', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: color ?? kText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(TransactionController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Transactions',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Category', style: TextStyle(fontSize: 13.sp)),
              trailing: Icon(Icons.chevron_right, size: 5.w),
              onTap: () {
                Navigator.pop(context);
                AppSnackbar.info('Filter', 'Category filter coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Amount Range', style: TextStyle(fontSize: 13.sp)),
              trailing: Icon(Icons.chevron_right, size: 5.w),
              onTap: () {
                Navigator.pop(context);
                AppSnackbar.info('Filter', 'Amount filter coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payment Method', style: TextStyle(fontSize: 13.sp)),
              trailing: Icon(Icons.chevron_right, size: 5.w),
              onTap: () {
                Navigator.pop(context);
                AppSnackbar.info('Filter', 'Payment method filter coming soon');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.clear),
              title: Text(
                'Clear All Filters',
                style: TextStyle(fontSize: 13.sp, color: kDanger),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.clearFilters();
                AppSnackbar.success(
                  kSuccess,
                  'Filters Cleared',
                  'All filters have been cleared',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(TransactionController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Transactions',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller.searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by title, description, reference...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            controller.searchQuery.value = value;
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  void _selectDateRange(TransactionController controller) async {
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );
    if (picked != null) {
      controller.setDateRange(picked);
    }
  }
}
