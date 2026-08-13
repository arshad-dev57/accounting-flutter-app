// screens/general_ledger_screen.dart - COMPLETE UPDATED VERSION

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Controller/general_ledger_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class GeneralLedgerScreen extends StatelessWidget {
  const GeneralLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GeneralLedgerController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    } else {
      return _buildWebLayout(context, controller);
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    GeneralLedgerController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.ledgerEntries.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileKpiStrip(controller, context),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.maxScrollExtent <= 0) return false;
                  if (controller.hasNextPage.value &&
                      !controller.isLoadingMore.value &&
                      !controller.isLoading.value &&
                      scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                    controller.loadMoreData();
                  }
                  return false;
                },
                child: _buildMobileLedgerList(controller, context),
              ),
            ),
            Obx(
              () => controller.isLoadingMore.value
                  ? Center(
                      child: LoadingAnimationWidget.discreteCircle(
                        color: kPrimary,
                        size: 40,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWebLayout(
    BuildContext context,
    GeneralLedgerController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          _buildWebKpiStrip(controller),
          _buildWebToolbar(controller, context),
          Expanded(child: _buildWebLedgerTable(controller, context)),
          _buildWebPaginationBar(controller, context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    GeneralLedgerController controller,
  ) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'General Ledger',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.white),
          onPressed: () => _showExportBottomSheet(controller, context),
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
          onPressed: () => _showFilterDialog(controller, context),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    final List<String> filterOptions = [
      'All',
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
      'Custom Range',
    ];

    return Container(
      color: kCardBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _compactField(
                  height: 36,
                  child: DropdownButtonHideUnderline(
                    child: Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedAccount.value,
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        isExpanded: true,
                        style: TextStyle(fontSize: 12, color: kText),
                        items: [
                          const DropdownMenuItem(
                            value: 'All Accounts',
                            child: Text('All Accounts'),
                          ),
                          ...controller.accountSummaries.map((account) {
                            return DropdownMenuItem(
                              value: account.accountName,
                              child: Text(
                                account.accountName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.changeAccount(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _compactField(
                  height: 36,
                  child: DropdownButtonHideUnderline(
                    child: Obx(
                      () => DropdownButton<String>(
                        value: controller.selectedFilter.value,
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        isExpanded: true,
                        style: TextStyle(fontSize: 12, color: kText),
                        items: filterOptions.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          if (value == 'Custom Range') {
                            _selectDateRange(controller, context);
                          } else {
                            controller.changeFilter(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _compactField(
            height: 36,
            child: TextField(
              onChanged: (value) => controller.searchEntries(value),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search entries...',
                hintStyle: TextStyle(fontSize: 12, color: kSubText),
                prefixIcon: Icon(Icons.search, size: 18, color: kSubText),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Obx(() {
            final range = controller.selectedDateRange.value;
            if (range == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: kPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${DateFormat('dd MMM yyyy').format(range.start)} – ${DateFormat('dd MMM yyyy').format(range.end)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.setDateRange(null),
                      child: Icon(Icons.close, size: 16, color: kPrimary),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _compactField({required double height, required Widget child}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }

  // ==================== MOBILE KPI STRIP ====================
  Widget _buildMobileKpiStrip(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final summary = controller.getCurrentSummary();
      final isAllAccounts = controller.isAllAccountsSelected;
      final closingBalance = controller.selectedAccountClosingBalance;

      final cards = <Widget>[
        _buildMobileKpiCard(
          'Debit',
          _formatAmount(summary['totalDebit']),
          kSuccess,
          Icons.trending_up,
        ),
        _buildMobileKpiCard(
          'Credit',
          _formatAmount(summary['totalCredit']),
          kDanger,
          Icons.trending_down,
        ),
        if (isAllAccounts)
          _buildMobileTrialBalanceCard(
            summary['isBalanced'],
            summary['netDifference'],
          )
        else
          _buildMobileKpiCard(
            'Balance',
            _formatAmount(closingBalance),
            closingBalance >= 0 ? kSuccess : kDanger,
            Icons.account_balance,
          ),
        _buildMobileKpiCard(
          'Entries',
          '${summary['entryCount']}',
          kPrimary,
          Icons.receipt,
        ),
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      );
    });
  }

  Widget _buildMobileKpiCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 132,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTrialBalanceCard(bool isBalanced, double netDifference) {
    final statusColor = isBalanced ? kSuccess : kDanger;
    final statusIcon = isBalanced
        ? Icons.check_circle
        : Icons.warning_amber_rounded;
    final statusText = isBalanced ? 'Balanced' : 'Unbalanced';
    final subtitle = isBalanced
        ? 'OK'
        : _formatAmount(netDifference.abs());

    return Container(
      width: 140,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, size: 14, color: statusColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Trial Balance',
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$statusText · $subtitle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      height: 1.1,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLedgerList(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final entries = controller.filteredLedgerEntries;
      if (entries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No ledger entries found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMobileEntryCard(entry),
          );
        },
      );
    });
  }

  Widget _buildMobileEntryCard(LedgerEntry entry) {
    return Card(
      color: kCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getAccountTypeColor(
                      _getAccountType(entry.accountName),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAccountIcon(_getAccountType(entry.accountName)),
                    size: 18,
                    color: _getAccountTypeColor(
                      _getAccountType(entry.accountName),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.accountName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${entry.accountCode}',
                        style: TextStyle(fontSize: 10, color: kSubText),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd MMM yy').format(entry.date),
                      style: TextStyle(fontSize: 10, color: kSubText),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'JE-${entry.id.substring(0, entry.id.length > 6 ? 6 : entry.id.length)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  entry.description,
                  style: TextStyle(fontSize: 12, color: kText),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kSuccess.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debit',
                              style: TextStyle(fontSize: 10, color: kSubText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.debit > 0
                                  ? _formatAmount(entry.debit)
                                  : '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kSuccess,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credit',
                              style: TextStyle(fontSize: 10, color: kSubText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.credit > 0
                                  ? _formatAmount(entry.credit)
                                  : '-',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: kDanger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance',
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                      Text(
                        _formatAmount(entry.balance),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: entry.balance >= 0 ? kSuccess : kDanger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED DIALOGS & HELPERS ====================
  void _selectDateRange(
    GeneralLedgerController controller,
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

  Widget _buildWebTopBar(
    BuildContext context,
    GeneralLedgerController controller,
  ) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'General Ledger',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            width: 240,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(
                () => DropdownButton<String>(
                  value: controller.selectedAccount.value,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  dropdownColor: kCardBg,
                  items: [
                    const DropdownMenuItem(
                      value: 'All Accounts',
                      child: Text(
                        'All Accounts',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    ...controller.accountSummaries.map((account) {
                      return DropdownMenuItem(
                        value: account.accountName,
                        child: Text(
                          account.accountName,
                          style: TextStyle(color: kText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.changeAccount(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              onChanged: (value) => controller.searchEntries(value),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search entries...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _webHeaderBtn(
            Icons.download_outlined,
            'Export',
            () => _showExportBottomSheet(controller, context),
          ),
        ],
      ),
    );
  }

  Widget _webHeaderBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WEB KPI STRIP ====================
  Widget _buildWebKpiStrip(GeneralLedgerController controller) {
    return Obx(() {
      final summary = controller.getCurrentSummary();
      final isAllAccounts = controller.isAllAccountsSelected;
      final closingBalance = controller.selectedAccountClosingBalance;

      return Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildWebKpiTile(
                      'Total Debit',
                      _formatAmount(summary['totalDebit']),
                      kSuccess,
                      Icons.trending_up,
                    ),
                    _buildWebKpiDivider(),
                    _buildWebKpiTile(
                      'Total Credit',
                      _formatAmount(summary['totalCredit']),
                      kDanger,
                      Icons.trending_down,
                    ),
                    _buildWebKpiDivider(),
                    if (isAllAccounts)
                      _buildWebTrialBalanceTile(
                        summary['isBalanced'],
                        summary['netDifference'],
                      )
                    else
                      _buildWebKpiTile(
                        'Closing Balance',
                        _formatAmount(closingBalance),
                        closingBalance >= 0 ? kSuccess : kDanger,
                        Icons.account_balance,
                      ),
                    _buildWebKpiDivider(),
                    _buildWebKpiTile(
                      'Total Entries',
                      '${summary['entryCount']}',
                      kPrimary,
                      Icons.receipt,
                    ),
                  ],
                ),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildWebKpiTile(
                    'Total Debit',
                    _formatAmount(summary['totalDebit']),
                    kSuccess,
                    Icons.trending_up,
                  ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: _buildWebKpiTile(
                    'Total Credit',
                    _formatAmount(summary['totalCredit']),
                    kDanger,
                    Icons.trending_down,
                  ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: isAllAccounts
                      ? _buildWebTrialBalanceTile(
                          summary['isBalanced'],
                          summary['netDifference'],
                        )
                      : _buildWebKpiTile(
                          'Closing Balance',
                          _formatAmount(closingBalance),
                          closingBalance >= 0 ? kSuccess : kDanger,
                          Icons.account_balance,
                        ),
                ),
                _buildWebKpiDivider(),
                Expanded(
                  child: _buildWebKpiTile(
                    'Total Entries',
                    '${summary['entryCount']}',
                    kPrimary,
                    Icons.receipt,
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildWebKpiTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebTrialBalanceTile(bool isBalanced, double netDifference) {
    final statusColor = isBalanced ? kSuccess : kDanger;
    final statusIcon = isBalanced
        ? Icons.check_circle
        : Icons.warning_amber_rounded;
    final statusText = isBalanced ? '✓ Balanced' : '⚠ Not Balanced';
    final subtitle = isBalanced
        ? 'Assets = Liabilities + Equity'
        : 'Diff: ${_formatAmount(netDifference.abs())}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, size: 16, color: statusColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trial Balance',
                style: TextStyle(
                  fontSize: 11,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    const filterOptions = [
      'All',
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(
                      () => Row(
                        children: filterOptions.map((filter) {
                          final isSelected =
                              controller.selectedFilter.value == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildFilterChip(
                              filter,
                              isSelected,
                              controller,
                              context,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(controller, context),
                const SizedBox(width: 8),
                _buildDateRangeButton(controller, context),
              ],
            );
          }
          return Row(
            children: [
              Obx(
                () => Row(
                  children: filterOptions.map((filter) {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildFilterChip(
                        filter,
                        isSelected,
                        controller,
                        context,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              _buildDebitCreditToggle(controller),
              const SizedBox(width: 12),
              _buildFilterButton(controller, context),
              const SizedBox(width: 8),
              _buildDateRangeButton(controller, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String filter,
    bool isSelected,
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        if (filter == 'Custom Range') {
          _selectDateRange(controller, context);
        } else {
          controller.changeFilter(filter);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: kPrimary.withOpacity(0.3))
              : null,
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? kPrimary : kSubText,
          ),
        ),
      ),
    );
  }

  Widget _buildDebitCreditToggle(GeneralLedgerController controller) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Obx(
            () => _toggleButton(
              label: 'Debit',
              isActive: controller.showOnlyDebit.value,
              color: kSuccess,
              onTap: () => controller.toggleDebitFilter(),
            ),
          ),
          Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.3)),
          Obx(
            () => _toggleButton(
              label: 'Credit',
              isActive: controller.showOnlyCredit.value,
              color: kDanger,
              onTap: () => controller.toggleCreditFilter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? color : kSubText,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _showFilterDialog(controller, context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 13, color: kSubText),
            const SizedBox(width: 4),
            Text('Filters', style: TextStyle(fontSize: 12, color: kSubText)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () => _selectDateRange(controller, context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 13, color: kSubText),
            const SizedBox(width: 4),
            Text('Date Range', style: TextStyle(fontSize: 12, color: kSubText)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLedgerTable(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final entries = controller.filteredLedgerEntries;

      if (entries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance,
                size: 48,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No ledger entries found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(flex: 2, child: _tableHeaderCell('Date')),
                Expanded(flex: 2, child: _tableHeaderCell('Journal ID')),
                Expanded(flex: 3, child: _tableHeaderCell('Account')),
                Expanded(flex: 2, child: _tableHeaderCell('Reference')),
                Expanded(flex: 4, child: _tableHeaderCell('Description')),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Debit', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Credit', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Balance', align: TextAlign.right),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.maxScrollExtent <= 0) return false;
                if (controller.hasNextPage.value &&
                    !controller.isLoadingMore.value &&
                    !controller.isLoading.value &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                  controller.loadMoreData();
                }
                return false;
              },
              child: ListView.separated(
                itemCount: entries.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  if (index >= entries.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: LoadingAnimationWidget.discreteCircle(
                          color: kPrimary,
                          size: 28,
                        ),
                      ),
                    );
                  }
                  final entry = entries[index];
                  return _buildWebTableRow(entry);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: kSubText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWebTableRow(LedgerEntry entry) {
    final isDebit = entry.debit > 0;
    final balancePositive = entry.balance >= 0;
    final accountType = _getAccountType(entry.accountName);
    final accountColor = _getAccountTypeColor(accountType);
    final accountIcon = _getAccountIcon(accountType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(entry.date),
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'JE-${entry.id.substring(0, entry.id.length > 6 ? 6 : entry.id.length)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(accountIcon, size: 14, color: accountColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.accountName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            entry.accountCode,
                            style: TextStyle(fontSize: 10, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.reference.isEmpty ? '—' : entry.reference,
                  style: TextStyle(fontSize: 12, color: kSubText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  entry.description,
                  style: TextStyle(fontSize: 12, color: kText),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.debit > 0 ? _formatAmount(entry.debit) : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isDebit ? FontWeight.w700 : FontWeight.w400,
                    color: isDebit ? kSuccess : kSubText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  entry.credit > 0 ? _formatAmount(entry.credit) : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !isDebit && entry.credit > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: !isDebit && entry.credit > 0 ? kDanger : kSubText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: balancePositive
                        ? kSuccess.withOpacity(0.08)
                        : kDanger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatAmount(entry.balance),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: balancePositive ? kSuccess : kDanger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WEB PAGINATION BAR ====================
  Widget _buildWebPaginationBar(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    return Obx(
      () => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.totalItems.value > 0
                  ? 'Showing ${controller.ledgerEntries.length} of ${controller.totalItems.value} records'
                  : 'Showing ${controller.ledgerEntries.length} records',
              style: TextStyle(fontSize: 13, color: kSubText),
            ),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        controller.hasPrevPage.value &&
                            !controller.isLoadingMore.value
                        ? () => controller.loadPreviousPage()
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: controller.hasPrevPage.value
                              ? kPrimary
                              : Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 18,
                            color: controller.hasPrevPage.value
                                ? kPrimary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.hasPrevPage.value
                                  ? kPrimary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        controller.hasNextPage.value &&
                            !controller.isLoadingMore.value
                        ? () => controller.loadNextPage()
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: controller.hasNextPage.value
                              ? kPrimary
                              : Colors.grey.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.hasNextPage.value
                                  ? kPrimary
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: controller.hasNextPage.value
                                ? kPrimary
                                : Colors.grey,
                          ),
                        ],
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

  // ==================== SHARED DIALOGS & HELPERS ====================
  void _showFilterDialog(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 12 : 16),
        ),
        child: Container(
          width: isWeb ? 380 : double.infinity,
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter Ledger',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 18,
                      fontWeight: FontWeight.w700,
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
              const SizedBox(height: 16),
              Obx(
                () => SwitchListTile(
                  secondary: Icon(Icons.trending_up, color: kSuccess, size: 20),
                  title: Text(
                    'Show Debit Entries Only',
                    style: TextStyle(fontSize: isWeb ? 13 : 14),
                  ),
                  value: controller.showOnlyDebit.value,
                  onChanged: (val) => controller.toggleDebitFilter(),
                  activeColor: kSuccess,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Obx(
                () => SwitchListTile(
                  secondary: Icon(
                    Icons.trending_down,
                    color: kDanger,
                    size: 20,
                  ),
                  title: Text(
                    'Show Credit Entries Only',
                    style: TextStyle(fontSize: isWeb ? 13 : 14),
                  ),
                  value: controller.showOnlyCredit.value,
                  onChanged: (val) => controller.toggleCreditFilter(),
                  activeColor: kDanger,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.date_range, size: 20),
                title: Text(
                  'Date Range',
                  style: TextStyle(fontSize: isWeb ? 13 : 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  _selectDateRange(controller, context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 10 : 12,
                        ),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 14,
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

  void _showExportBottomSheet(
    GeneralLedgerController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);

    if (isWeb) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: _buildExportContent(controller, ctx),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: kCardBg,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _buildExportContent(controller, ctx),
        ),
      );
    }
  }

  Widget _buildExportContent(
    GeneralLedgerController controller,
    BuildContext ctx,
  ) {
    final isWeb = ResponsiveUtils.isWeb(ctx);
    final entries = controller.filteredLedgerEntries;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Export General Ledger',
              style: TextStyle(
                fontSize: isWeb ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${entries.length} entries will be exported',
          style: TextStyle(fontSize: 12, color: kSubText),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _exportOptionCard(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                subtitle: 'Formatted report',
                color: const Color(0xFFE53935),
                bgColor: const Color(0xFFFFEBEE),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  _showExportingLoader('Generating PDF...');
                  try {
                    await _exportToPdf(controller);
                    if (Get.isDialogOpen ?? false) Get.back();
                  } catch (e) {
                    if (Get.isDialogOpen ?? false) Get.back();
                    AppSnackbar.error(
                      Colors.red,
                      'Error',
                      'Failed to export PDF: $e',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _exportOptionCard(
                icon: Icons.table_chart_outlined,
                label: 'Excel',
                subtitle: 'Spreadsheet',
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Future.delayed(const Duration(milliseconds: 100));
                  _showExportingLoader('Building Excel...');
                  try {
                    await _exportToExcel(controller);
                    if (Get.isDialogOpen ?? false) Get.back();
                  } catch (e) {
                    if (Get.isDialogOpen ?? false) Get.back();
                    AppSnackbar.error(
                      Colors.red,
                      'Error',
                      'Failed to export Excel: $e',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exportOptionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportingLoader(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.waveDots(color: kPrimary, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kText,
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _exportToPdf(GeneralLedgerController controller) async {
    final entries = controller.filteredLedgerEntries;
    final selectedAccount = controller.selectedAccount.value;
    final summary = controller.getCurrentSummary();

    final branding = await PdfBrandingBundle.load();
    final accent = branding.accent;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => branding.buildHeader(
          reportTitle: 'General Ledger Report',
        ),
        footer: (ctx) => branding.buildFooter(ctx),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor(accent.red, accent.green, accent.blue, 0.06),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: PdfColor(accent.red, accent.green, accent.blue, 0.35),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfSummaryItem('Account', selectedAccount, accent),
                    _pdfSummaryItem(
                      'Total Entries',
                      '${summary['entryCount']}',
                      accent,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfSummaryItem(
                      'Total Debit',
                      _formatAmount(summary['totalDebit']),
                      PdfColors.green700,
                    ),
                    _pdfSummaryItem(
                      'Total Credit',
                      _formatAmount(summary['totalCredit']),
                      PdfColors.red700,
                    ),
                    _pdfSummaryItem(
                      'Net Change',
                      _formatAmount(summary['netDifference']),
                      summary['isBalanced']
                          ? PdfColors.green700
                          : PdfColors.red700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Journal ID',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Account',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Reference',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'Description',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Debit',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Credit',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Balance',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map(
            (entry) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      DateFormat('dd/MM/yyyy').format(entry.date),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'JE-${entry.id.substring(0, entry.id.length > 6 ? 6 : entry.id.length)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      entry.accountName,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      entry.reference.isEmpty ? '-' : entry.reference,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      entry.description,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      entry.debit > 0 ? _formatAmount(entry.debit) : '-',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.green700,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      entry.credit > 0 ? _formatAmount(entry.credit) : '-',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.red700),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      _formatAmount(entry.balance),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          branding.buildSignatureBlock(),
        ],
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'general_ledger_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }

    AppSnackbar.success(
      Colors.green,
      'Success',
      '${entries.length} ledger entries exported to PDF',
    );
  }

  pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel(GeneralLedgerController controller) async {
    final entries = controller.filteredLedgerEntries;

    final excel = Excel.createExcel();
    final sheet = excel['General Ledger'];
    excel.delete('Sheet1');

    final headers = [
      'Date',
      'Journal ID',
      'Account Code',
      'Account Name',
      'Reference',
      'Description',
      'Debit',
      'Credit',
      'Balance',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      );
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = i + 1;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        DateFormat('dd/MM/yyyy').format(entry.date),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        'JE-${entry.id.substring(0, entry.id.length > 6 ? 6 : entry.id.length)}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        entry.accountCode,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        entry.accountName,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        entry.reference.isEmpty ? '-' : entry.reference,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(
        entry.description,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = DoubleCellValue(
        entry.debit,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = DoubleCellValue(
        entry.credit,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = DoubleCellValue(
        entry.balance,
      );
    }

    final colWidths = [12.0, 12.0, 12.0, 25.0, 12.0, 35.0, 12.0, 12.0, 15.0];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel save failed');

    final fileName =
        'general_ledger_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    if (kIsWeb) {
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case 'Assets':
        return kSuccess;
      case 'Liabilities':
        return kDanger;
      case 'Income':
        return kPrimary;
      case 'Expenses':
        return kWarning;
      default:
        return kSubText;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'Assets':
        return Icons.account_balance;
      case 'Liabilities':
        return Icons.payment;
      case 'Income':
        return Icons.trending_up;
      case 'Expenses':
        return Icons.trending_down;
      default:
        return Icons.account_balance;
    }
  }

  String _getAccountType(String accountName) {
    if (accountName.contains('Cash') ||
        accountName.contains('Bank') ||
        accountName.contains('Receivable'))
      return 'Assets';
    if (accountName.contains('Payable') || accountName.contains('Loan'))
      return 'Liabilities';
    if (accountName.contains('Revenue') || accountName.contains('Sales'))
      return 'Income';
    if (accountName.contains('Expense') ||
        accountName.contains('Rent') ||
        accountName.contains('Salary'))
      return 'Expenses';
    return 'Assets';
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}
