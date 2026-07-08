import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/loanBorrowing/controller/loan_controller.dart';
import 'package:LedgerPro_app/core/loanBorrowing/models/loan_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoansBorrowingsScreen extends StatelessWidget {
  const LoansBorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoanController());
    return _buildMobileLayout(context, controller);
  }


  Widget _buildMobileLayout(BuildContext context, LoanController controller) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.loans.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(color: kPrimary, size: 40),
          );
        }
        return Column(
          children: [
            _buildFilterBar(controller, context),
            _buildSummaryCards(controller, context),
            Expanded(child: _buildLoansList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showAddLoanDialog(),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LoanController controller) {
    return AppBar(
      title: const Text(
        'Loans & Borrowings',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showSearchDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.calculate_outlined, color: Colors.black87),
          onPressed: () => controller.showEMICalculator(),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportLoans(),
        ),
      ],
    );
  }

  Widget _buildFilterBar(LoanController controller, BuildContext context) {
    final filters = ['All', 'Active', 'Fully Paid', 'Overdue', 'Defaulted'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: filters.map((f) {
            final isSelected = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (_) => controller.applyFilter(isSelected ? 'All' : f),
                backgroundColor: kBg,
                selectedColor: kPrimary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? kPrimary : kSubText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildSummaryCards(LoanController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildSummaryCard('Total Loans', controller.totalLoans.value.toString(), kPrimary, Icons.credit_card, isNumber: true),
            const SizedBox(width: 12),
            _buildSummaryCard('Total Principal', controller.formatAmount(controller.totalPrincipal.value), kPrimary, Icons.attach_money),
            const SizedBox(width: 12),
            _buildSummaryCard('Outstanding', controller.formatAmount(controller.totalOutstanding.value), kDanger, Icons.payment),
            const SizedBox(width: 12),
            _buildSummaryCard('Total Paid', controller.formatAmount(controller.totalPaid.value), kSuccess, Icons.check_circle_outline),
            const SizedBox(width: 12),
            _buildSummaryCard('Monthly EMI', controller.formatAmount(controller.totalEMI.value), kWarning, Icons.calendar_month),
          ],
        )),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, {bool isNumber = false}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title, style: TextStyle(fontSize: 11, color: kSubText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLoansList(LoanController controller, BuildContext context) {
    return Obx(() {
      final loans = controller.loans;

      if (controller.isLoading.value && loans.isEmpty) {
        return const SizedBox.shrink();
      }

      if (loans.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card_outlined, size: 64, color: kSubText.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('No loans found', style: TextStyle(fontSize: 16, color: kSubText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.showAddLoanDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Loan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLoanCard(loans[index], controller, context),
        ),
      );
    });
  }

  Widget _buildLoanCard(Loan loan, LoanController controller, BuildContext context) {
    final statusColor = loan.status == 'Active'
        ? kPrimary
        : loan.status == 'Fully Paid'
            ? kSuccess
            : kDanger;
    final typeColor = controller.getLoanTypeColor(loan.loanType);
    final paidPercent = loan.loanAmount > 0
        ? (loan.totalPaid / loan.loanAmount).clamp(0.0, 1.0)
        : 0.0;
    final isOverdue = loan.nextPaymentDate != null &&
        loan.nextPaymentDate!.isBefore(DateTime.now()) &&
        loan.status == 'Active';

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.showLoanDetails(loan),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(controller.getLoanIcon(loan.loanType), size: 20, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loan.loanNumber,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                          const SizedBox(height: 2),
                          Text(loan.lenderName,
                              style: TextStyle(fontSize: 11, color: kSubText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(loan.status,
                                    style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(4)),
                                child: Text(loan.loanType,
                                    style: TextStyle(fontSize: 8, color: kSubText, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Outstanding', style: TextStyle(fontSize: 9, color: kSubText)),
                        Text(controller.formatAmount(loan.outstandingBalance),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kDanger)),
                        const SizedBox(height: 2),
                        Text('EMI: ${controller.formatAmount(loan.emiAmount)}',
                            style: TextStyle(fontSize: 10, color: kWarning, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Repayment progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Repaid', style: TextStyle(fontSize: 10, color: kSubText)),
                        Text('${(paidPercent * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 10, color: paidPercent >= 1.0 ? kSuccess : kPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: paidPercent,
                        backgroundColor: kBg,
                        valueColor: AlwaysStoppedAnimation<Color>(paidPercent >= 1.0 ? kSuccess : kPrimary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: kDanger),
                        const SizedBox(width: 6),
                        Text('Payment Overdue!',
                            style: TextStyle(fontSize: 11, color: kDanger, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.showLoanDetails(loan),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text('Details', style: TextStyle(fontSize: 11, color: kText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    if (loan.status == 'Active') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.viewPaymentSchedule(loan),
                          icon: Icon(Icons.calendar_view_month, size: 14, color: kPrimary),
                          label: const Text('Schedule', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.showRecordPaymentDialog(loan),
                          icon: const Icon(Icons.payment, size: 14, color: Colors.black87),
                          label: const Text('Pay EMI', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  // ==================== HELPERS ====================

  void _showSearchDialog(BuildContext context, LoanController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Search Loans', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Loan #, lender, type…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => controller.searchController.text = v,
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () { controller.searchController.clear(); Navigator.pop(ctx); },
            child: const Text('Clear'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }
}