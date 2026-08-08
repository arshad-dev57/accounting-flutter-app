import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/BankReconciliation/controllers/bank_reconciliation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

class BankReconciliationScreen extends StatelessWidget {
  const BankReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BankReconciliationController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(controller),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: ResponsiveUtils.isWeb(context) ? 32 : 40,
            ),
          );
        }

        if (controller.selectedAccount.value == null) {
          return _buildAccountSelector(controller);
        }

        return _buildReconciliationScreen(controller);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BankReconciliationController controller) {
    return AppBar(
      title: Text(
        'Bank Reconciliation',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        if (controller.selectedAccount.value != null)
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 5.w),
            onPressed: () => controller.clearSelectedAccount(),
          ),
      ],
    );
  }

  Widget _buildAccountSelector(BankReconciliationController controller) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(5.w),
        margin: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance,
              size: 15.w,
              color: kPrimary.withOpacity(0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select Bank Account',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: 80.w,
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedAccountId.value.isEmpty
                      ? null
                      : controller.selectedAccountId.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp, color: kText),
                  hint: Text(
                    'Choose an account',
                    style: TextStyle(fontSize: 12.sp, color: kSubText),
                  ),
                  items: controller.bankAccounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${account.number} • Balance: ${_formatAmount(account.balance)}',
                            style: TextStyle(fontSize: 12.sp, color: kSubText),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.selectAccount(value);
                  },
                ),
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationScreen(BankReconciliationController controller) {
    return Obx(() {
      return Column(
        children: [
          _buildBalanceCards(controller),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildAdjustmentsCard(controller),
                SizedBox(height: 2.h),
                _buildTransactionsList(controller),
                SizedBox(height: 2.h),
                _buildActionButtons(controller),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBalanceCards(BankReconciliationController controller) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: kCardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Book Balance',
                  _formatAmount(controller.bookBalance.value),
                  kPrimary,
                  Icons.book,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildBalanceCard(
                  'Statement Balance',
                  _formatAmount(controller.statementBalance.value),
                  kWarning,
                  Icons.receipt,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: controller.isBalanced.value
                  ? kSuccess.withOpacity(0.1)
                  : kDanger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Difference',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: kSubText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatAmount(controller.difference.value),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: controller.isBalanced.value ? kSuccess : kDanger,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: controller.isBalanced.value
                        ? kSuccess.withOpacity(0.2)
                        : kDanger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.isBalanced.value ? 'Balanced ✓' : 'Not Balanced',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: controller.isBalanced.value ? kSuccess : kDanger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 4.w, color: color),
              SizedBox(width: 1.5.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsCard(BankReconciliationController controller) {
    return Container(
      padding: EdgeInsets.all(4.w),
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
          Text(
            'Adjustments',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildAdjustmentField(
                  'Service Charge',
                  controller.serviceCharge.value,
                  (value) => controller.updateServiceCharge(value),
                  Icons.receipt,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildAdjustmentField(
                  'Interest Earned',
                  controller.interestEarned.value,
                  (value) => controller.updateInterestEarned(value),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentField(
    String label,
    double value,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 4.w, color: kPrimary),
            SizedBox(width: 1.5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: TextFormField(
            initialValue: value == 0 ? '' : value.toString(),
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: '0.00',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              prefixText: CurrencyUtils.prefix,
              prefixStyle: TextStyle(fontSize: 12.sp, color: kSubText),
            ),
            onChanged: (text) {
              double val = double.tryParse(text) ?? 0;
              onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BankReconciliationController controller) {
    List<TransactionForRecon> deposits = controller.transactions
        .where((t) => t.type == 'Deposit')
        .toList();
    List<TransactionForRecon> payments = controller.transactions
        .where((t) => t.type == 'Payment')
        .toList();

    return Container(
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
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 5.w, color: kPrimary),
                SizedBox(width: 2.w),
                Text(
                  'Transactions to Match',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ],
            ),
          ),
          if (deposits.isNotEmpty)
            _buildTransactionSection(
              'Deposits',
              deposits,
              kSuccess,
              controller,
            ),
          if (payments.isNotEmpty)
            _buildTransactionSection('Payments', payments, kDanger, controller),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(
    String title,
    List<TransactionForRecon> transactions,
    Color color,
    BankReconciliationController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        ...transactions.map(
          (transaction) =>
              _buildTransactionItem(transaction, color, controller),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    TransactionForRecon transaction,
    Color color,
    BankReconciliationController controller,
  ) {
    bool isChecked = controller.clearedTransactionIds.contains(transaction.id);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isChecked ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? color : kBorder,
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (checked) {
              controller.toggleClearedTransaction(transaction.id);
            },
            activeColor: color,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  '${DateFormat('dd MMM yyyy').format(transaction.date)} • Ref: ${transaction.reference}',
                  style: TextStyle(fontSize: 12.sp, color: kSubText),
                ),
              ],
            ),
          ),
          Text(
            transaction.type == 'Deposit'
                ? '+ ${_formatAmount(transaction.amount)}'
                : '- ${_formatAmount(transaction.amount)}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: transaction.type == 'Deposit' ? kSuccess : kDanger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BankReconciliationController controller) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isReconciling.value
                    ? null
                    : controller.resetReconciliation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kDanger,
                  side: BorderSide(color: kDanger, width: 1),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    controller.isReconciling.value ||
                        !controller.isBalanced.value
                    ? null
                    : () => controller.completeReconciliation(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isBalanced.value
                      ? kSuccess
                      : kSubText,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isReconciling.value
                    ? SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Complete Reconciliation',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
