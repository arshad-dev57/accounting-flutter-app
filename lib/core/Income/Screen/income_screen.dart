import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/Income/controller/income_controller.dart';
import 'package:BisonsTechs_app/core/Income/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IncomeController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.incomes.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
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
              color: kPrimary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddIncomeDialog(controller, context),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context, IncomeController controller) {
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
                          'Income',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.incomes.length} entries',
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
                    onTap: controller.refreshData,
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
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.exportIncomes(),
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
            // Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: controller.incomeTypes.map((type) {
                      final isSelected = controller.selectedType.value == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => controller.applyTypeFilter(
                            isSelected ? 'All' : type,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? kPrimary : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 38,
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
                  controller: controller.searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search income...',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
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

  Widget _buildSummaryCards(IncomeController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Total Income',
              amount: controller.formatAmount(controller.totalIncome.value),
              color: kSuccess,
              icon: Icons.trending_up,
              bgColor: kSuccess.withOpacity(0.08),
              borderColor: kSuccess.withOpacity(0.2),
            ),
            const SizedBox(width: 6),
            _buildProfessionalCard(
              title: 'This Month',
              amount: controller.formatAmount(controller.thisMonthTotal.value),
              color: kPrimary,
              icon: Icons.calendar_month,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 6),
            _buildProfessionalCard(
              title: 'Records',
              amount: controller.totalCount.value.toString(),
              color: kWarning,
              icon: Icons.receipt_long,
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
        padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 12, color: color),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 9,
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
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Container(
              height: 2,
              width: 25,
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

  Widget _buildListView(IncomeController controller, BuildContext context) {
    return Obx(() {
      final incomes = controller.incomes;

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
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showAddIncomeDialog(controller, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
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
                  'Add Income',
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

      // ✅ Lazy Loading with NotificationListener
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
          padding: const EdgeInsets.all(8),
          itemCount: incomes.length + 1,
          itemBuilder: (context, index) {
            if (index == incomes.length) {
              return Obx(
                () => controller.isLoadingMore.value
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
            final income = incomes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildIncomeCard(income, controller, context),
            );
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL INCOME CARD
  // ═══════════════════════════════════════════════════════════════

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
    final typeColor = Color(
      int.parse(
            controller.getTypeColor(income.incomeType).substring(1, 7),
            radix: 16,
          ) +
          0xFF000000,
    );

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
          onTap: () => _showIncomeDetails(income, controller, context),
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
                            typeColor.withOpacity(0.15),
                            typeColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        controller.getTypeIcon(income.incomeType),
                        size: 22,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            income.incomeNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  income.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kBgLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  income.paymentMethod,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kSubText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (income.customerName.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    income.customerName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kSuccess,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yy').format(income.date),
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
                            _showIncomeDetails(income, controller, context),
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
                    if (income.status == 'Draft') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.postIncome(income.id),
                          icon: const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Post',
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
  // ADD INCOME DIALOG - PROFESSIONAL DESIGN
  // ═══════════════════════════════════════════════════════════════

  void _showAddIncomeDialog(IncomeController controller, BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    String incomeType = 'Sales';
    String? selectedIncomeAccountId;
    String? selectedCustomerId;
    double simpleAmount = 0;
    List<Map<String, dynamic>> items = [
      {'description': '', 'quantity': 1, 'unitPrice': 0.0},
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
              double subtotal = items.fold(
                0.0,
                (s, i) =>
                    s +
                    (i['quantity'] as num).toDouble() *
                        (i['unitPrice'] as num).toDouble(),
              );
              return subtotal + subtotal * (taxRate / 100);
            }
            return simpleAmount;
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
                            Icons.trending_up,
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
                                'Add Income',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new income entry',
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
                              'Date',
                              selectedDate,
                              (d) => setState(() => selectedDate = d),
                              context,
                            ),
                            const SizedBox(height: 16),

                            _buildDropdownField(
                              label: 'Income Type',
                              value: incomeType,
                              items: controller.incomeTypes.skip(1).toList(),
                              onChanged: (v) => setState(() => incomeType = v!),
                            ),
                            const SizedBox(height: 16),

                            Obx(() {
                              final hasMatch =
                                  selectedIncomeAccountId == null ||
                                  controller.incomeAccounts.any(
                                    (a) =>
                                        (a['id'] ?? a['_id']).toString() ==
                                        selectedIncomeAccountId,
                                  );
                              return _buildIncomeAccountDropdownField(
                                hasMatch ? selectedIncomeAccountId : null,
                                (v) =>
                                    setState(() => selectedIncomeAccountId = v),
                                controller.incomeAccounts.toList(),
                              );
                            }),
                            const SizedBox(height: 16),

                            Obx(() {
                              if (controller.customers.isEmpty)
                                return const SizedBox.shrink();
                              final hasMatch =
                                  selectedCustomerId == null ||
                                  controller.customers.any(
                                    (c) =>
                                        (c['id'] ?? c['_id']).toString() ==
                                        selectedCustomerId,
                                  );
                              return _buildCustomerDropdownField(
                                hasMatch ? selectedCustomerId : null,
                                (v) => setState(() => selectedCustomerId = v),
                                controller.customers.toList(),
                              );
                            }),
                            const SizedBox(height: 16),

                            // Items or Simple Amount
                            if (requiresItems()) ...[
                              _buildItemsSection(items, setState),
                              const SizedBox(height: 16),
                              _buildTaxField(
                                taxRate,
                                (v) => setState(() => taxRate = v),
                              ),
                            ] else ...[
                              _buildAmountField(
                                simpleAmount,
                                (v) => setState(() => simpleAmount = v),
                              ),
                            ],
                            const SizedBox(height: 16),

                            _buildDescriptionField(
                              description,
                              (v) => description = v,
                            ),
                            const SizedBox(height: 16),

                            _buildReferenceField(
                              reference,
                              (v) => reference = v,
                            ),
                            const SizedBox(height: 16),

                            _buildPaymentMethodField(
                              paymentMethod,
                              (v) => setState(() {
                                paymentMethod = v!;
                                if (paymentMethod == 'Cash') {
                                  selectedBankAccountId = null;
                                }
                              }),
                            ),
                            const SizedBox(height: 16),

                            if (paymentMethod != 'Cash' &&
                                controller.bankAccounts.isNotEmpty)
                              _buildBankDropdownField(
                                selectedBankAccountId,
                                (v) =>
                                    setState(() => selectedBankAccountId = v),
                                controller.bankAccounts,
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
                                    kSuccess.withOpacity(0.08),
                                    kSuccess.withOpacity(0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
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
                                      fontSize: 14,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    controller.formatAmount(calculateTotal()),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: kSuccess,
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
                                      if (!formKey.currentState!.validate())
                                        return;

                                      if (selectedIncomeAccountId == null ||
                                          selectedIncomeAccountId!.isEmpty) {
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
                                          final price = (i['unitPrice'] as num)
                                              .toDouble();
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

                                      Navigator.pop(context);
                                      await controller.createIncome(
                                        date: selectedDate,
                                        incomeType: incomeType,
                                        incomeAccountId:
                                            selectedIncomeAccountId,
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
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Save Income',
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
  // INCOME DETAILS DIALOG - PROFESSIONAL DESIGN
  // ═══════════════════════════════════════════════════════════════

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
                              color: kSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              size: 26,
                              color: kSuccess,
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
                                        income.incomeNumber,
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
                                        income.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${DateFormat('dd MMM yyyy').format(income.date)}',
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
                            controller.formatAmount(income.totalAmount),
                            kSuccess,
                            Icons.trending_up,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Subtotal',
                            controller.formatAmount(income.subtotal),
                            kPrimary,
                            Icons.receipt,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Tax',
                            controller.formatAmount(income.taxAmount),
                            kWarning,
                            Icons.receipt,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Details
                      _detailRow('Income Type', income.incomeType),
                      if (income.incomeAccount != null)
                        _detailRow(
                          'Income Account',
                          '${income.incomeAccount?['code'] ?? ''} - ${income.incomeAccount?['name'] ?? ''}',
                        ),
                      if (income.customerName.isNotEmpty)
                        _detailRow('Customer', income.customerName),
                      _detailRow('Payment Method', income.paymentMethod),
                      if (income.reference.isNotEmpty)
                        _detailRow('Reference', income.reference),
                      if (income.description.isNotEmpty)
                        _detailRow('Description', income.description),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),

                      // Items
                      if (income.items.isNotEmpty) ...[
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...income.items
                            .map(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            '${item.quantity} × ${controller.formatAmount(item.unitPrice)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: kSubText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      controller.formatAmount(item.amount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: kSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: Colors.grey.withOpacity(0.12),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Footer Buttons
                      Row(
                        children: [
                          if (income.status == 'Draft') ...[
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    controller.postIncome(income.id);
                                  },
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    'Post Income',
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kText,
            ),
          ),
        ],
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        onChanged: (v) =>
                            setState(() => item['description'] = v),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
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
            items.add({'description': '', 'quantity': 1, 'unitPrice': 0.0});
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

  Widget _buildTaxField(double taxRate, void Function(double) onChanged) {
    return TextFormField(
      initialValue: '0',
      decoration: InputDecoration(
        labelText: 'Tax Rate (%)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }

  Widget _buildAmountField(double amount, void Function(double) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Amount *',
        prefixText: CurrencyUtils.prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      validator: (v) =>
          (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
    );
  }

  Widget _buildDescriptionField(String value, void Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter description',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      maxLines: 2,
      onChanged: onChanged,
    );
  }

  Widget _buildReferenceField(String value, void Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Reference #',
        hintText: 'e.g., INV-001',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      onChanged: onChanged,
    );
  }

  Widget _buildPaymentMethodField(
    String value,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: TextStyle(fontSize: 13, color: kText),
      items: const ['Cash', 'Bank Transfer', 'Cheque', 'Credit Card']
          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
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
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Bank Account',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: TextStyle(fontSize: 13, color: kText),
      hint: Text(
        'Select bank account',
        style: TextStyle(fontSize: 12, color: kSubText),
        overflow: TextOverflow.ellipsis,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('None (Cash)')),
        ...bankAccounts.map(
          (a) => DropdownMenuItem<String>(
            value: (a['id'] ?? a['_id']).toString(),
            child: Text(
              a['accountName'] ?? '',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
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
                  Text(label, style: TextStyle(fontSize: 11, color: kSubText)),
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
            Icon(Icons.arrow_drop_down, size: 20, color: kSubText),
          ],
        ),
      ),
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
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: TextStyle(fontSize: 13, color: kText),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildIncomeAccountDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> incomeAccounts,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Income Account *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: TextStyle(fontSize: 13, color: kText),
      hint: Text(
        incomeAccounts.isEmpty
            ? 'No accounts available'
            : 'Select income account',
        style: TextStyle(fontSize: 12, color: kSubText),
        overflow: TextOverflow.ellipsis,
      ),
      items: incomeAccounts.isEmpty
          ? []
          : incomeAccounts
                .map(
                  (a) {
                    final label = '${a['code'] ?? ''} - ${a['name'] ?? ''}';
                    return DropdownMenuItem<String>(
                      value: (a['id'] ?? a['_id']).toString(),
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                )
                .toList(),
      selectedItemBuilder: incomeAccounts.isEmpty
          ? null
          : (context) => incomeAccounts.map((a) {
                final label = '${a['code'] ?? ''} - ${a['name'] ?? ''}';
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
      onChanged: incomeAccounts.isEmpty ? null : onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an income account';
        }
        return null;
      },
    );
  }

  Widget _buildCustomerDropdownField(
    String? selectedId,
    void Function(String?) onChanged,
    List<Map<String, dynamic>> customers,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Customer',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 11, color: kSubText),
      ),
      style: TextStyle(fontSize: 13, color: kText),
      hint: Text(
        'Select customer',
        style: TextStyle(fontSize: 12, color: kSubText),
        overflow: TextOverflow.ellipsis,
      ),
      items: customers
          .map(
            (c) => DropdownMenuItem<String>(
              value: (c['id'] ?? c['_id']).toString(),
              child: Text(
                c['name'] ?? '',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
