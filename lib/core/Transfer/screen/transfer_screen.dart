import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/transfer/controller/transfer_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransferController());
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: ResponsiveUtils.isWeb(context) ? 32 : 40,
            ),
          );
        }

        return SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Center(
            child: SizedBox(
              width: ResponsiveUtils.getFormWidth(context),
              child: Column(
                children: [
                  _buildHeader(context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildFromAccountCard(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildArrowIcon(context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildToAccountCard(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 20 : 24),
                  _buildAmountField(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildDateField(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildReferenceField(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildDescriptionField(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 24 : 32),
                  _buildTransferButton(controller, context),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 20),
                  _buildExchangeRateInfo(controller, context),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return AppBar(
      title: Text(
        'Transfer Money',
        style: TextStyle(
          fontSize: ResponsiveUtils.getHeadingFontSize(context),
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      centerTitle: isMobile,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: ResponsiveUtils.getIconSize(context),
        ),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isWeb
                ? 50
                : isTablet
                ? 45
                : 40,
            height: isWeb
                ? 50
                : isTablet
                ? 45
                : 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                isWeb
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
              ),
            ),
            child: Icon(
              Icons.swap_horiz,
              size: isWeb
                  ? 28
                  : isTablet
                  ? 24
                  : 20,
              color: kPrimary,
            ),
          ),
          SizedBox(
            width: isWeb
                ? 16
                : isTablet
                ? 12
                : 8,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Between Accounts',
                  style: TextStyle(
                    fontSize: isWeb
                        ? 18
                        : isTablet
                        ? 16
                        : 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                SizedBox(height: isWeb ? 4 : 2),
                Text(
                  'Move money from one bank account to another',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                    color: kSubText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromAccountCard(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
              Icon(
                Icons.arrow_upward,
                size: isWeb
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
                color: kDanger,
              ),
              SizedBox(
                width: isWeb
                    ? 8
                    : isTablet
                    ? 6
                    : 4,
              ),
              Text(
                'From Account',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: kDanger,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isWeb
                ? 16
                : isTablet
                ? 12
                : 10,
          ),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.fromAccountId.value.isEmpty
                  ? null
                  : controller.fromAccountId.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isWeb
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isWeb
                      ? 16
                      : isTablet
                      ? 12
                      : 10,
                  vertical: isWeb
                      ? 14
                      : isTablet
                      ? 12
                      : 10,
                ),
              ),
              style: TextStyle(
                fontSize: isWeb
                    ? 14
                    : isTablet
                    ? 13
                    : 12,
              ),
              hint: Text(
                'Select account to transfer from',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  color: kSubText,
                ),
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
                          fontSize: isWeb
                              ? 14
                              : isTablet
                              ? 13
                              : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${account.number} • Balance: ${_formatAmount(account.balance)} ${account.currency}',
                        style: TextStyle(
                          fontSize: isWeb
                              ? 12
                              : isTablet
                              ? 11
                              : 10,
                          color: kSubText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.setFromAccount(value);
              },
            ),
          ),
          if (controller.fromAccountId.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: isWeb
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
              ),
              child: _buildAccountBalance(controller.getFromAccount(), context),
            ),
        ],
      ),
    );
  }

  Widget _buildToAccountCard(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
              Icon(
                Icons.arrow_downward,
                size: isWeb
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
                color: kSuccess,
              ),
              SizedBox(
                width: isWeb
                    ? 8
                    : isTablet
                    ? 6
                    : 4,
              ),
              Text(
                'To Account',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: kSuccess,
                ),
              ),
            ],
          ),
          SizedBox(
            height: isWeb
                ? 16
                : isTablet
                ? 12
                : 10,
          ),
          Obx(
            () => DropdownButtonFormField<String>(
              value: controller.toAccountId.value.isEmpty
                  ? null
                  : controller.toAccountId.value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isWeb
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isWeb
                      ? 16
                      : isTablet
                      ? 12
                      : 10,
                  vertical: isWeb
                      ? 14
                      : isTablet
                      ? 12
                      : 10,
                ),
              ),
              style: TextStyle(
                fontSize: isWeb
                    ? 14
                    : isTablet
                    ? 13
                    : 12,
              ),
              hint: Text(
                'Select account to transfer to',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  color: kSubText,
                ),
              ),
              items: controller.bankAccounts
                  .where(
                    (account) => account.id != controller.fromAccountId.value,
                  )
                  .map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: TextStyle(
                              fontSize: isWeb
                                  ? 14
                                  : isTablet
                                  ? 13
                                  : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${account.number} • Balance: ${_formatAmount(account.balance)} ${account.currency}',
                            style: TextStyle(
                              fontSize: isWeb
                                  ? 12
                                  : isTablet
                                  ? 11
                                  : 10,
                              color: kSubText,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.setToAccount(value);
              },
            ),
          ),
          if (controller.toAccountId.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: isWeb
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
              ),
              child: _buildAccountBalance(controller.getToAccount(), context),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountBalance(
    BankAccountForTransfer? account,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    if (account == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 12
            : isTablet
            ? 10
            : 8,
      ),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 12
              : isTablet
              ? 10
              : 8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              fontSize: isWeb
                  ? 12
                  : isTablet
                  ? 11
                  : 10,
              color: kSubText,
            ),
          ),
          Text(
            _formatAmount(account.balance),
            style: TextStyle(
              fontSize: isWeb
                  ? 13
                  : isTablet
                  ? 12
                  : 11,
              fontWeight: FontWeight.w700,
              color: kSuccess,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIcon(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      width: isWeb
          ? 48
          : isTablet
          ? 40
          : 32,
      height: isWeb
          ? 48
          : isTablet
          ? 40
          : 32,
      decoration: BoxDecoration(
        color: kCardBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_downward,
        size: isWeb
            ? 24
            : isTablet
            ? 20
            : 16,
        color: kPrimary,
      ),
    );
  }

  Widget _buildAmountField(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
            'Amount',
            style: TextStyle(
              fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          SizedBox(
            height: isWeb
                ? 12
                : isTablet
                ? 10
                : 8,
          ),
          TextFormField(
            onChanged: (value) => controller.setAmount(value),
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: isWeb
                  ? 22
                  : isTablet
                  ? 20
                  : 18,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              prefixText: CurrencyUtils.prefix,
              prefixStyle: TextStyle(
                fontSize: isWeb
                    ? 22
                    : isTablet
                    ? 20
                    : 18,
                fontWeight: FontWeight.w800,
                color: kPrimary,
              ),
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isWeb
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb
                    ? 16
                    : isTablet
                    ? 12
                    : 10,
                vertical: isWeb
                    ? 14
                    : isTablet
                    ? 12
                    : 10,
              ),
            ),
          ),
          Obx(() {
            if (controller.amount.value > 0) {
              final fromAccount = controller.getFromAccount();
              if (fromAccount != null &&
                  controller.amount.value > fromAccount.balance) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: isWeb
                        ? 8
                        : isTablet
                        ? 6
                        : 4,
                  ),
                  child: Text(
                    'Insufficient balance! Available: ${_formatAmount(fromAccount.balance)}',
                    style: TextStyle(
                      fontSize: isWeb
                          ? 11
                          : isTablet
                          ? 10
                          : 9,
                      color: kDanger,
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildDateField(TransferController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
            'Transfer Date',
            style: TextStyle(
              fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          SizedBox(
            height: isWeb
                ? 12
                : isTablet
                ? 10
                : 8,
          ),
          Obx(
            () => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                size: isWeb
                    ? 24
                    : isTablet
                    ? 20
                    : 18,
                color: kPrimary,
              ),
              title: Text(
                DateFormat(
                  'EEEE, MMMM d, yyyy',
                ).format(controller.selectedDate.value),
                style: TextStyle(
                  fontSize: isWeb
                      ? 14
                      : isTablet
                      ? 13
                      : 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: isWeb
                    ? 18
                    : isTablet
                    ? 16
                    : 14,
                color: kSubText,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: Get.context!,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  controller.setDate(picked);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceField(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
            'Reference (Optional)',
            style: TextStyle(
              fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          SizedBox(
            height: isWeb
                ? 12
                : isTablet
                ? 10
                : 8,
          ),
          TextFormField(
            onChanged: (value) => controller.setReference(value),
            decoration: InputDecoration(
              hintText: 'e.g., TRANS-001, Salary Transfer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isWeb
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb
                    ? 16
                    : isTablet
                    ? 12
                    : 10,
                vertical: isWeb
                    ? 14
                    : isTablet
                    ? 12
                    : 10,
              ),
            ),
            style: TextStyle(
              fontSize: isWeb
                  ? 14
                  : isTablet
                  ? 13
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      padding: EdgeInsets.all(
        isWeb
            ? 20
            : isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(
          isWeb
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
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
            'Description (Optional)',
            style: TextStyle(
              fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              fontWeight: FontWeight.w600,
              color: kText,
            ),
          ),
          SizedBox(
            height: isWeb
                ? 12
                : isTablet
                ? 10
                : 8,
          ),
          TextFormField(
            onChanged: (value) => controller.setDescription(value),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a note about this transfer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  isWeb
                      ? 12
                      : isTablet
                      ? 10
                      : 8,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb
                    ? 16
                    : isTablet
                    ? 12
                    : 10,
                vertical: isWeb
                    ? 14
                    : isTablet
                    ? 12
                    : 10,
              ),
            ),
            style: TextStyle(
              fontSize: isWeb
                  ? 14
                  : isTablet
                  ? 13
                  : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: ResponsiveUtils.getButtonHeight(context),
        child: ElevatedButton(
          onPressed: controller.isTransferring.value
              ? null
              : controller.transfer,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                isWeb
                    ? 12
                    : isTablet
                    ? 10
                    : 8,
              ),
            ),
          ),
          child: controller.isTransferring.value
              ? SizedBox(
                  width: isWeb
                      ? 24
                      : isTablet
                      ? 20
                      : 18,
                  height: isWeb
                      ? 24
                      : isTablet
                      ? 20
                      : 18,
                  child: CircularProgressIndicator(
                    strokeWidth: isWeb ? 2.5 : 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Transfer Money',
                  style: TextStyle(
                    fontSize: isWeb
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildExchangeRateInfo(
    TransferController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Obx(() {
      final fromAccount = controller.getFromAccount();
      final toAccount = controller.getToAccount();

      if (fromAccount != null &&
          toAccount != null &&
          fromAccount.currency != toAccount.currency &&
          controller.amount.value > 0) {
        return Container(
          padding: EdgeInsets.all(
            isWeb
                ? 16
                : isTablet
                ? 12
                : 10,
          ),
          decoration: BoxDecoration(
            color: kWarning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              isWeb
                  ? 12
                  : isTablet
                  ? 10
                  : 8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: isWeb
                    ? 20
                    : isTablet
                    ? 18
                    : 16,
                color: kWarning,
              ),
              SizedBox(
                width: isWeb
                    ? 8
                    : isTablet
                    ? 6
                    : 4,
              ),
              Expanded(
                child: Text(
                  'Different currencies detected. Exchange rate will be applied at current market rate.',
                  style: TextStyle(
                    fontSize: isWeb
                        ? 11
                        : isTablet
                        ? 10
                        : 9,
                    color: kWarning,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
