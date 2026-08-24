// screens/journal_entries_screen.dart

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/widgets/expandable_stat_card.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/journalEntries/Controllers/journal_entries_exportservice.dart';
import 'package:BisonsTechs_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:BisonsTechs_app/core/journalEntries/model/journal_entry_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class JournalEntriesScreen extends StatelessWidget {
  const JournalEntriesScreen({super.key});

  static final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JournalEntryController());
    final _searchCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context, controller, _searchCtrl),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.journalEntries.isEmpty) {
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
          onPressed: () => _showAddJournalEntryDialog(context, controller),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    JournalEntryController controller,
    TextEditingController searchCtrl,
  ) {
    void showDateRangePicker_() async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) controller.setDateRange(picked);
    }

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
                          'Journal Entries',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalEntries.value} entries',
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
                    onTap: () => controller.refresh(),
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
                    onTap: () => _showExportBottomSheet(context, controller),
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
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                  controller: searchCtrl,
                  onChanged: (v) => controller.searchEntries(v),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search entries...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchCtrl.clear();
                              controller.searchEntries('');
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            // Filters
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: ['All', 'Posted', 'Draft'].map((filter) {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => controller.changeFilter(filter),
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
                            filter,
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
            // Date Range Display
            Obx(() {
              if (controller.selectedDateRange.value != null) {
                final range = controller.selectedDateRange.value!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => controller.setDateRange(null),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(JournalEntryController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Debit',
                _formatAmount(controller.totalDebit.value),
                kSuccess,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Credit',
                _formatAmount(controller.totalCredit.value),
                kDanger,
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Difference',
                _formatAmount(controller.difference.value),
                controller.difference.value < 0.01 ? kSuccess : kWarning,
                Icons.balance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return ExpandableStatWrap(
      title: title,
      value: amount,
      color: color,
      icon: icon,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 22, 12),
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
                Icon(icon, size: 14, color: color),
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
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildListView(
    JournalEntryController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final entries = controller.journalEntries;
      if (entries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No journal entries found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    _showAddJournalEntryDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'New Entry',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == entries.length) {
            return Obx(
              () => controller.isLoadingMore.value
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
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
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEntryCard(entry, controller, context),
          );
        },
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ENTRY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEntryCard(
    JournalEntry entry,
    JournalEntryController controller,
    BuildContext context,
  ) {
    final isPosted = entry.status == 'Posted';
    final statusColor = isPosted ? kSuccess : kWarning;
    final statusIcon = isPosted ? Icons.check_circle : Icons.edit;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewJournalEntryDetails(entry),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.entryNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                                  entry.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(entry.date),
                                style: TextStyle(fontSize: 11, color: kSubText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.description,
                            style: TextStyle(fontSize: 12, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatAmount(entry.entryAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (entry.lines.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _entryLinesPreview(entry),
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _sideBadge('Dr', _formatAmount(entry.totalDebit), kSuccess),
                    _sideBadge('Cr', _formatAmount(entry.totalCredit), kDanger),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (entry.isBalanced ? kSuccess : kWarning)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.isBalanced ? 'Balanced' : 'Unbalanced',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: entry.isBalanced ? kSuccess : kWarning,
                        ),
                      ),
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

  String _entryLinesPreview(JournalEntry entry) {
    final drNames = entry.lines
        .where((l) => l.debit > 0)
        .map((l) => l.accountName)
        .where((n) => n.isNotEmpty)
        .take(2)
        .join(', ');
    final crNames = entry.lines
        .where((l) => l.credit > 0)
        .map((l) => l.accountName)
        .where((n) => n.isNotEmpty)
        .take(2)
        .join(', ');

    final parts = <String>[];
    if (drNames.isNotEmpty) parts.add('Dr: $drNames');
    if (crNames.isNotEmpty) parts.add('Cr: $crNames');
    return parts.join(' · ');
  }

  Widget _sideBadge(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD JOURNAL ENTRY DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showAddJournalEntryDialog(
    BuildContext context,
    JournalEntryController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
            maxWidth: 600,
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
          child: AddJournalEntryDialog(controller: controller),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // VIEW JOURNAL ENTRY DETAILS
  // ═══════════════════════════════════════════════════════════════

  void _viewJournalEntryDetails(JournalEntry entry) {
    final isPosted = entry.status == 'Posted';
    final statusColor = isPosted ? kSuccess : kWarning;
    final statusIcon = isPosted ? Icons.check_circle : Icons.edit;

    showModalBottomSheet(
      context: Get.context!,
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
                              statusIcon,
                              color: statusColor,
                              size: 26,
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
                                        entry.entryNumber,
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
                                        entry.status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${DateFormat('dd MMM yyyy').format(entry.date)}',
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
                            'Total Debit',
                            _formatAmount(entry.totalDebit),
                            kSuccess,
                            Icons.arrow_downward,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Total Credit',
                            _formatAmount(entry.totalCredit),
                            kDanger,
                            Icons.arrow_upward,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Lines',
                            '${entry.lines.length}',
                            kPrimary,
                            Icons.list,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      _detailRow('Description', entry.description),
                      _detailRow(
                        'Reference',
                        entry.reference.isEmpty ? 'N/A' : entry.reference,
                      ),
                      _detailRow('Created By', entry.createdBy),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      Text(
                        'Journal Lines',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...entry.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.accountName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: kText,
                                      ),
                                    ),
                                    Text(
                                      line.accountCode,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  line.debit > 0
                                      ? _formatAmount(line.debit)
                                      : '-',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: line.debit > 0 ? kSuccess : kSubText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  line.credit > 0
                                      ? _formatAmount(line.credit)
                                      : '-',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: line.credit > 0 ? kDanger : kSubText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kPrimary,
                                  side: const BorderSide(color: kPrimary),
                                  minimumSize: const Size.fromHeight(46),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // TODO: Add edit functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(46),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Edit Entry',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
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

  // ═══════════════════════════════════════════════════════════════
  // SEARCH DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showSearchDialog(
    BuildContext context,
    JournalEntryController controller,
  ) {
    final searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Search Entries',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'Entry ID, description, or reference',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onSubmitted: (v) {
            controller.searchEntries(v);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              controller.searchEntries(searchCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('Search', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showFilterDialog(
    BuildContext context,
    JournalEntryController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Filter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.black),
              title: const Text(
                'Date Range',
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black,
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.setDateRange(picked);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showExportBottomSheet(
    BuildContext context,
    JournalEntryController controller,
  ) {
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

  Widget _buildExportContent(
    JournalEntryController controller,
    BuildContext ctx,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Export Journal Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${controller.journalEntries.length} entries will be exported',
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
                    final summary = {
                      'totalDebit': controller.totalDebit.value,
                      'totalCredit': controller.totalCredit.value,
                      'difference': controller.difference.value,
                      'postedCount': controller.postedCount.value,
                      'draftCount': controller.draftCount.value,
                    };
                    await JournalExportService.exportToPdf(
                      controller.journalEntries,
                      summary,
                    );
                    Get.back();
                  } catch (e) {
                    Get.back();
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
                    final summary = {
                      'totalDebit': controller.totalDebit.value,
                      'totalCredit': controller.totalCredit.value,
                      'difference': controller.difference.value,
                      'postedCount': controller.postedCount.value,
                      'draftCount': controller.draftCount.value,
                    };
                    await JournalExportService.exportToExcel(
                      controller.journalEntries,
                      summary,
                    );
                    Get.back();
                  } catch (e) {
                    Get.back();
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

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}

// ═══════════════════════════════════════════════════════════════
// ADD JOURNAL ENTRY DIALOG
// ═══════════════════════════════════════════════════════════════

class AddJournalEntryDialog extends StatefulWidget {
  final JournalEntryController controller;
  const AddJournalEntryDialog({super.key, required this.controller});

  @override
  State<AddJournalEntryDialog> createState() => _AddJournalEntryDialogState();
}

class _AddJournalEntryDialogState extends State<AddJournalEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _description = '';
  String _reference = '';
  List<JournalLineInput> _lines = [];
  bool _showLineErrors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addLine();
  }

  @override
  void dispose() {
    for (var line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() => setState(() => _lines.add(JournalLineInput()));

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  String? _validateLines({bool requireBalanced = false}) {
    if (_lines.length < 2) return 'Add at least two journal lines';
    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      if (line.accountId.isEmpty ||
          line.accountId == 'null' ||
          line.accountId == 'NULL') {
        return 'Select an account for line ${i + 1}';
      }
      if (line.debit <= 0 && line.credit <= 0) {
        return 'Enter a debit or credit amount on line ${i + 1}';
      }
      if (line.debit > 0 && line.credit > 0) {
        return 'A line cannot have both debit and credit';
      }
    }
    if (requireBalanced) {
      final totalDebit = _lines.fold(0.0, (sum, l) => sum + l.debit);
      final totalCredit = _lines.fold(0.0, (sum, l) => sum + l.credit);
      if ((totalDebit - totalCredit).abs() >= 0.01) {
        return 'Total debit must equal total credit';
      }
    }
    return null;
  }

  Widget _buildAccountDropdown(JournalLineInput line) {
    final hasError =
        _showLineErrors &&
        (line.accountId.isEmpty ||
            line.accountId == 'null' ||
            line.accountId == 'NULL');

    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        isDense: true,
        decoration: InputDecoration(
          hintText: 'Select account',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? kDanger : Colors.grey.withOpacity(0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? kDanger : Colors.grey.withOpacity(0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: hasError ? kDanger : kPrimary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          errorText: hasError ? 'Please select an account' : null,
          errorStyle: const TextStyle(fontSize: 10),
        ),
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        value: line.accountId.isEmpty || line.accountId == 'null'
            ? null
            : line.accountId,
        items: widget.controller.accounts.map((account) {
          final accountId = account['id']?.toString() ?? '';
          final code = account['code']?.toString() ?? '';
          final name = account['name']?.toString() ?? '';

          return DropdownMenuItem<String>(
            value: accountId,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                '$code - $name',
                style: const TextStyle(fontSize: 13, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
        onChanged: _isSubmitting
            ? null
            : (value) {
                if (value != null && value.isNotEmpty && value != 'null') {
                  setState(() {
                    line.accountId = value;
                    final selected = widget.controller.accounts.firstWhere(
                      (a) => a['id']?.toString() == value,
                      orElse: () => {},
                    );
                    if (selected.isNotEmpty) {
                      line.accountName = selected['name'] ?? '';
                      line.accountCode = selected['code'] ?? '';
                    }
                  });
                }
              },
        // ✅ KEY FIX: Constrain the dropdown menu to prevent overflow
        menuMaxHeight: 250,
        iconSize: 20,
        icon: Icon(
          Icons.arrow_drop_down,
          color: hasError ? kDanger : Colors.grey.shade600,
        ),
        dropdownColor: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() => _showLineErrors = true);

    if (!_formKey.currentState!.validate()) return;

    final lineError = _validateLines(requireBalanced: true);
    if (lineError != null) {
      AppSnackbar.error(Colors.red, 'Error', lineError);
      return;
    }

    final linesData = <Map<String, dynamic>>[];
    for (final l in _lines) {
      if (l.accountId.isEmpty ||
          l.accountId == 'null' ||
          l.accountId == 'NULL') {
        AppSnackbar.error(
          Colors.red,
          'Error',
          'Please select an account for all lines',
        );
        return;
      }
      linesData.add({
        'accountId': l.accountId,
        'debit': l.debit,
        'credit': l.credit,
      });
    }

    setState(() => _isSubmitting = true);

    if (mounted) Navigator.pop(context);

    try {
      await widget.controller.createJournalEntry(
        date: _selectedDate,
        description: _description,
        reference: _reference,
        lines: linesData,
      );
    } catch (e) {
      // Error snackbar controller ne already show kar diya.
      // Dialog already closed hai.
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDebit = _lines.fold(0.0, (sum, l) => sum + l.debit);
    final totalCredit = _lines.fold(0.0, (sum, l) => sum + l.credit);
    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
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
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_task,
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
                        'New Journal Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a new journal entry',
                        style: TextStyle(fontSize: 12, color: kSubText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.black),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _datePickerField(context),
                    const SizedBox(height: 16),
                    _refField(),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter journal description',
                        filled: true,
                        fillColor: kBgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                        labelStyle: TextStyle(fontSize: 13, color: kSubText),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      maxLines: 2,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (v) => _description = v,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Journal Lines Header
                    Row(
                      children: [
                        Text(
                          'Journal Lines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isSubmitting ? null : _addLine,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kPrimary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: kPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Line',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lines
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return _buildLineCard(line, index);
                    }),

                    const SizedBox(height: 16),

                    // Balance Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isBalanced
                            ? kSuccess.withOpacity(0.08)
                            : kWarning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBalanced
                              ? kSuccess.withOpacity(0.2)
                              : kWarning.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Debit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(totalDebit),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kSuccess,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Credit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kSubText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(totalCredit),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kDanger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Footer
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
                    onPressed: _isSubmitting
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
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Save Entry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

  Widget _buildLineCard(JournalLineInput line, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Line ${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ),
              const Spacer(),
              if (_lines.length > 2)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: kDanger,
                  ),
                  onPressed: _isSubmitting ? null : () => _removeLine(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccountDropdown(line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('debit_$index'),
                  controller: line.debitController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Debit',
                    labelStyle: TextStyle(fontSize: 11, color: kSubText),
                    filled: true,
                    fillColor: kBgLight,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Text(
                        CurrencyUtils.prefix,
                        style: TextStyle(
                          fontSize: 13,
                          color: kText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      line.debit = double.tryParse(value) ?? 0;
                      if (line.debit > 0) {
                        line.credit = 0;
                        line.creditController.clear();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('credit_$index'),
                  controller: line.creditController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Credit',
                    labelStyle: TextStyle(fontSize: 11, color: kSubText),
                    filled: true,
                    fillColor: kBgLight,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Text(
                        CurrencyUtils.prefix,
                        style: TextStyle(
                          fontSize: 13,
                          color: kText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      line.credit = double.tryParse(value) ?? 0;
                      if (line.credit > 0) {
                        line.debit = 0;
                        line.debitController.clear();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePickerField(BuildContext context) {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Journal Date',
                    style: TextStyle(
                      fontSize: 11,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: kText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: kSubText),
          ],
        ),
      ),
    );
  }

  Widget _refField() {
    return TextFormField(
      enabled: !_isSubmitting,
      decoration: InputDecoration(
        labelText: 'Reference Number',
        hintText: 'e.g., INV-001',
        filled: true,
        fillColor: kBgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
        labelStyle: TextStyle(fontSize: 13, color: kSubText),
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black),
      onChanged: (v) => _reference = v,
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}

// ═══════════════════════════════════════════════════════════════
// JOURNAL LINE INPUT CLASS
// ═══════════════════════════════════════════════════════════════

class JournalLineInput {
  String accountId = '';
  String accountName = '';
  String accountCode = '';
  double debit = 0.0;
  double credit = 0.0;
  TextEditingController debitController = TextEditingController();
  TextEditingController creditController = TextEditingController();

  JournalLineInput() {
    debitController.addListener(() {
      debit = double.tryParse(debitController.text) ?? 0;
    });
    creditController.addListener(() {
      credit = double.tryParse(creditController.text) ?? 0;
    });
  }

  void dispose() {
    debitController.dispose();
    creditController.dispose();
  }
}
