// screens/capital_equity_screen.dart - COMPLETE PROFESSIONAL MOBILE DESIGN

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/widgets/expandable_stat_card.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/controller/equity_controller.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/models/equity_model.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
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
              if (controller.isLoading.value &&
                  controller.equityAccounts.isEmpty) {
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
          child: const Icon(Icons.add, color: Colors.white, size: 24),
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.equityAccounts.length} accounts',
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
                      controller.loadEquityAccounts();
                      controller.loadTransactions();
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
                    onTap: () => controller.exportEquity(),
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
                        onChanged: (value) => controller.searchEquity(value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
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
                          items:
                              [
                                'All',
                                'Capital',
                                'Retained Earnings',
                                'Drawings',
                                'Reserves',
                              ].map((f) {
                                return DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                );
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
    return Obx(() {
      final up = controller.isCapitalIncrease.value;
      final earned = controller.periodEarnings.value;
      final changeLabel = up ? 'Earned this period' : 'Decreased this period';
      final changeColor = up ? kSuccess : kDanger;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildProfessionalCard(
                  title: 'Your capital',
                  amount: controller.formatAmount(controller.ownerCapital.value),
                  color: kPrimary,
                  icon: Icons.account_balance_wallet_outlined,
                  bgColor: kPrimary.withOpacity(0.08),
                  borderColor: kPrimary.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                _buildProfessionalCard(
                  title: changeLabel,
                  amount: controller.formatAmount(earned),
                  color: changeColor,
                  icon: up
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  bgColor: changeColor.withOpacity(0.08),
                  borderColor: changeColor.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                _buildProfessionalCard(
                  title: 'Equity now',
                  amount: controller.formatAmount(controller.equityNow.value),
                  color: kPrimary,
                  icon: Icons.pie_chart_outline_rounded,
                  bgColor: kPrimary.withOpacity(0.08),
                  borderColor: kPrimary.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                up
                    ? 'Owner capital ${controller.formatAmount(controller.ownerCapital.value)} + ${controller.formatAmount(earned.abs())} this period = equity ${controller.formatAmount(controller.equityNow.value)}.'
                    : 'Owner capital ${controller.formatAmount(controller.ownerCapital.value)} − ${controller.formatAmount(earned.abs())} this period = equity ${controller.formatAmount(controller.equityNow.value)}.',
                style: TextStyle(
                  fontSize: 11,
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
    return ExpandableStatCard(
      title: title,
      amount: amount,
      color: color,
      icon: icon,
      bgColor: bgColor,
      borderColor: borderColor,
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
                  'Add Equity Account',
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
        border: Border.all(color: typeColor.withOpacity(0.2), width: 1.5),
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
                      child: Icon(typeIcon, size: 22, color: typeColor),
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
                            children: [_badge(account.accountType, typeColor)],
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
                          onPressed: () =>
                              controller.showAddCapitalDialog(account),
                          icon: const Icon(
                            Icons.add_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Add Capital',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                          onPressed: () =>
                              controller.showRecordDrawingsDialog(account),
                          icon: const Icon(
                            Icons.remove_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Draw',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
