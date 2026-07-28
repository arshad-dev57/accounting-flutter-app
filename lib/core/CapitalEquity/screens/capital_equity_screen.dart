// screens/capital_equity_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/CapitalEquity/controller/equity_controller.dart';
import 'package:LedgerPro_app/core/CapitalEquity/models/equity_model.dart';
import 'package:LedgerPro_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CapitalEquityScreen extends StatelessWidget {
  const CapitalEquityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EquityController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.equityAccounts.isEmpty) {
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
          onPressed: () {
            if (controller.equityAccounts.isEmpty) {
              AppSnackbar.error(
                kWarning,
                'No Equity Account',
                'Please add an Equity account from Chart of Accounts first',
                duration: const Duration(seconds: 3),
              );
              Get.to(() => const ChartOfAccountsScreen());
            } else {
              controller.showAddTransactionDialog();
            }
          },
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

  Widget _buildTopHeader(BuildContext context, EquityController controller) {
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
                          'Capital & Equity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.equityAccounts.length} accounts',
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
                    onTap: () {
                      controller.loadEquityAccounts();
                      controller.loadTransactions();
                      controller.loadSummary();
                    },
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
                    onTap: () => controller.exportEquity(),
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
                        onChanged: (value) => controller.searchEquity(value),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search accounts...',
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
                          items: ['All', 'Capital', 'Retained Earnings', 'Drawings', 'Reserves'].map((f) {
                            return DropdownMenuItem(value: f, child: Text(f));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) controller.applyFilter(v);
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

  Widget _buildSummaryCards(EquityController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            _buildProfessionalCard(
              title: 'Total Equity',
              amount: controller.formatAmount(controller.totalEquity.value),
              color: kPrimary,
              icon: Icons.account_balance_wallet,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Capital',
              amount: controller.formatAmount(controller.totalCapital.value),
              color: kPrimary,
              icon: Icons.account_balance,
              bgColor: kPrimary.withOpacity(0.08),
              borderColor: kPrimary.withOpacity(0.2),
            ),
            const SizedBox(width: 8),
            _buildProfessionalCard(
              title: 'Retained',
              amount: controller.formatAmount(controller.totalRetainedEarnings.value),
              color: kSuccess,
              icon: Icons.trending_up,
              bgColor: kSuccess.withOpacity(0.08),
              borderColor: kSuccess.withOpacity(0.2),
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

  Widget _buildListView(EquityController controller, BuildContext context) {
    return Obx(() {
      final accounts = controller.equityAccounts;

      if (accounts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No equity accounts found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Get.to(() => const ChartOfAccountsScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Equity Account',
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
          itemCount: accounts.length + 1,
          itemBuilder: (context, index) {
            if (index == accounts.length) {
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
            final account = accounts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEquityCard(account, controller, context),
            );
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFESSIONAL EQUITY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEquityCard(
    EquityAccount account,
    EquityController controller,
    BuildContext context,
  ) {
    final typeColor = _getTypeColor(account.accountType);
    final typeIcon = _getTypeIcon(account.accountType);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: typeColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.showAccountDetails(account),
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
                        typeIcon,
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
                            account.accountName,
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
                            account.accountCode,
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
                              _badge(account.accountType, typeColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          controller.formatAmount(account.currentBalance),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontSize: 9,
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
                        onPressed: () => controller.showAccountDetails(account),
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
                    if (account.accountType == 'Capital') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.showAddCapitalDialog(account),
                          icon: const Icon(
                            Icons.add_circle,
                            size: 14,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Add Capital',
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
                    ] else if (account.accountType == 'Drawings') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.showRecordDrawingsDialog(account),
                          icon: const Icon(
                            Icons.remove_circle,
                            size: 14,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Draw',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
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
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

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

  Color _getTypeColor(String accountType) {
    switch (accountType) {
      case 'Capital':
        return kPrimary;
      case 'Retained Earnings':
        return kSuccess;
      case 'Reserves':
        return kWarning;
      default:
        return kDanger; // Drawings
    }
  }

  IconData _getTypeIcon(String accountType) {
    switch (accountType) {
      case 'Capital':
        return Icons.account_balance;
      case 'Retained Earnings':
        return Icons.trending_up;
      case 'Reserves':
        return Icons.savings;
      default:
        return Icons.remove_circle_outline; // Drawings
    }
  }
}