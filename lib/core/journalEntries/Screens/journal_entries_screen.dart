// screens/journal_entries_screen.dart

import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/journalEntries/Controllers/journal_entries_exportservice.dart';
import 'package:LedgerPro_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:LedgerPro_app/core/journalEntries/model/journal_entry_model.dart';
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

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.journalEntries.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return RepaintBoundary(
          key: _repaintKey,
          child: Column(
            children: [
              _buildFilterBar(controller, context),
              _buildSummaryCards(controller, context),
              Expanded(
                child: _buildListView(controller, context),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddJournalEntryDialog(context, controller),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black),
        elevation: 2,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    JournalEntryController controller,
  ) {
    return AppBar(
      title: const Text(
        'Journal Entries',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () => _showSearchDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
          onPressed: () => _showFilterDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black),
          onPressed: () => _showExportBottomSheet(context, controller),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterBar(
    JournalEntryController controller,
    BuildContext context,
  ) {
    void showDateRangePicker_(JournalEntryController c) async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null) c.setDateRange(picked);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kCardBg,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: TextField(
                    onChanged: (v) => controller.searchEntries(v),
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search entries...',
                      hintStyle: TextStyle(fontSize: 12, color: kSubText),
                      prefixIcon: Icon(Icons.search, size: 20, color: kSubText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(
                    () => DropdownButton<String>(
                      value: controller.selectedFilter.value,
                      icon: const Icon(Icons.arrow_drop_down, size: 22),
                      style: TextStyle(fontSize: 13, color: kText),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'Posted',
                          child: Text('Posted'),
                        ),
                        DropdownMenuItem(
                          value: 'Custom Range',
                          child: Text('Custom Range'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          if (value == 'Custom Range') {
                            showDateRangePicker_(controller);
                          } else {
                            controller.changeFilter(value);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.selectedDateRange.value != null) {
              final range = controller.selectedDateRange.value!;
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.date_range, size: 16, color: kPrimary),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: kPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => controller.setDateRange(null),
                        child: Icon(Icons.close, size: 16, color: kPrimary),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(
    JournalEntryController controller,
    BuildContext context,
  ) {
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
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
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST VIEW (Mobile & Tablet Unified)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildListView(
    JournalEntryController controller,
    BuildContext context,
  ) {
    if (controller.journalEntries.isEmpty) {
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
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () =>
                    _showAddJournalEntryDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'New Entry',
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
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
            controller.loadMoreJournalEntries();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: controller.journalEntries.length +
            (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.journalEntries.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LoadingAnimationWidget.waveDots(
                  color: kPrimary,
                  size: 40,
                ),
              ),
            );
          }
          final entry = controller.journalEntries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEntryCard(entry, controller, context),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ENTRY CARD (Unified for Mobile & Tablet)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEntryCard(
    JournalEntry entry,
    JournalEntryController controller,
    BuildContext context,
  ) {
    final isPosted = entry.status == 'Posted';
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPosted ? kSuccess.withOpacity(0.05) : kWarning.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPosted
                                  ? kSuccess.withOpacity(0.2)
                                  : kWarning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.entryNumber,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isPosted ? kSuccess : kWarning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPosted
                                  ? kSuccess.withOpacity(0.1)
                                  : kWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPosted
                                      ? Icons.check_circle_outline
                                      : Icons.edit_outlined,
                                  size: 12,
                                  color: isPosted ? kSuccess : kWarning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPosted ? kSuccess : kWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.description,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: kSubText),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(entry.date),
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    if (entry.reference.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ref: ${entry.reference}',
                        style: TextStyle(fontSize: 11, color: kSubText),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ─── Lines ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: isTablet ? 4 : 3,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSubText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Debit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSubText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Credit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSubText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.lines.take(isTablet ? 4 : 3).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: isTablet ? 4 : 3,
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
                                style: TextStyle(fontSize: 10, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            line.debit > 0 ? _formatAmount(line.debit) : '-',
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
                            line.credit > 0 ? _formatAmount(line.credit) : '-',
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
                if (entry.lines.length > (isTablet ? 4 : 3))
                  Text(
                    '+ ${entry.lines.length - (isTablet ? 4 : 3)} more lines',
                    style: TextStyle(fontSize: 11, color: kSubText),
                  ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: isTablet ? 4 : 3,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAmount(entry.totalDebit),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kSuccess,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAmount(entry.totalCredit),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kDanger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Footer ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: kSubText),
                    const SizedBox(width: 4),
                    Text(
                      entry.createdBy,
                      style: TextStyle(fontSize: 11, color: kSubText),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // ✅ View Button
                    IconButton(
                      onPressed: () => _viewJournalEntryDetails(entry),
                      icon: const Icon(
                        Icons.remove_red_eye,
                        size: 20,
                        color: Colors.black,
                      ),
                      tooltip: 'View',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // ✅ Delete Button (with balance reversal)
                    IconButton(
                      onPressed: () => _confirmDeleteEntry(entry, controller),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.black,
                      ),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE CONFIRMATION WITH BALANCE REVERSAL WARNING
  // ═══════════════════════════════════════════════════════════════

  void _confirmDeleteEntry(
    JournalEntry entry,
    JournalEntryController controller,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text(
          'Delete Entry',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this journal entry?',
              style: TextStyle(fontSize: 13, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: kWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will reverse all balance changes made by this entry.',
                      style: TextStyle(
                        fontSize: 12,
                        color: kWarning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entry: ${entry.entryNumber}',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteJournalEntry(entry.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.black),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 600,
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
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            JournalEntryDetailsSheet(
              entry: entry,
              scrollController: scrollController,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.searchEntries(searchCtrl.text);
              Navigator.pop(context);
            },
            child: const Text(
              'Search',
              style: TextStyle(color: Colors.black),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
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
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.black),
            ),
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
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportingLoader(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      double totalDebit = _lines.fold(0, (sum, line) => sum + line.debit);
      double totalCredit = _lines.fold(0, (sum, line) => sum + line.credit);
      bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;
      if (!isBalanced) {
        return 'Total debit must equal total credit';
      }
    }
    return null;
  }

  Widget _buildAccountDropdown(JournalLineInput line) {
    final hasError = _showLineErrors &&
        (line.accountId.isEmpty ||
            line.accountId == 'null' ||
            line.accountId == 'NULL');

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: 'Select account',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: hasError ? kDanger : Colors.grey.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
              color: hasError ? kDanger : Colors.grey.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: hasError ? kDanger : kPrimary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        errorText: hasError ? 'Please select an account' : null,
      ),
      style: const TextStyle(fontSize: 12, color: Colors.black),
      value: line.accountId.isEmpty || line.accountId == 'null'
          ? null
          : line.accountId,
      items: widget.controller.accounts.map((account) {
        final accountId = account['id']?.toString() ?? '';
        return DropdownMenuItem<String>(
          value: accountId,
          child: Text(
            '${account['code']} - ${account['name']}',
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (value) {
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
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _showLineErrors = true);

    if (!_formKey.currentState!.validate()) return;
    final error = _validateLines(requireBalanced: true);
    if (error != null) {
      AppSnackbar.error(Colors.red, 'Error', error);
      return;
    }

    final linesData = <Map<String, dynamic>>[];
    for (final l in _lines) {
      if (l.accountId.isEmpty ||
          l.accountId == 'null' ||
          l.accountId == 'NULL') {
        AppSnackbar.error(
            Colors.red, 'Error', 'Please select an account for all lines');
        return;
      }
      linesData.add({
        'accountId': l.accountId,
        'debit': l.debit,
        'credit': l.credit,
      });
    }

    Navigator.pop(context);
    await widget.controller.createJournalEntry(
      date: _selectedDate,
      description: _description,
      reference: _reference,
      lines: linesData,
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalDebit = _lines.fold(0, (sum, line) => sum + line.debit);
    double totalCredit = _lines.fold(0, (sum, line) => sum + line.credit);
    bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_task, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'New Journal Entry',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.black),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Divider(height: 16, color: Colors.grey.withOpacity(0.2)),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _datePickerField(context),
                    const SizedBox(height: 12),
                    _refField(),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter journal description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      maxLines: 2,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (v) => _description = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Description required' : null,
                    ),
                    const SizedBox(height: 20),
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
                        InkWell(
                          onTap: _addLine,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: kPrimary),
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
                    const SizedBox(height: 10),
                    // Lines table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'ACCOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'DEBIT',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'CREDIT',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildAccountDropdown(line),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                key: ValueKey('debit_$index'),
                                controller: line.debitController,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: CurrencyUtils.prefix,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.right,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
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
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                key: ValueKey('credit_$index'),
                                controller: line.creditController,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: CurrencyUtils.prefix,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.right,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
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
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: () => _removeLine(index),
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Icon(Icons.delete_outline,
                                      size: 16, color: kDanger),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Balance status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isBalanced
                            ? kSuccess.withOpacity(0.08)
                            : kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isBalanced
                              ? kSuccess.withOpacity(0.2)
                              : kDanger.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBalanced
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: isBalanced ? kSuccess : kDanger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBalanced
                                ? 'Entry is balanced'
                                : 'Debit ≠ Credit — entry is not balanced',
                            style: TextStyle(
                              fontSize: 12,
                              color: isBalanced ? kSuccess : kDanger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'DR: ${_formatAmount(totalDebit)}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'CR: ${_formatAmount(totalCredit)}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── ✅ UPDATED: Only Post Button (No Draft) ──────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14, color: kSubText),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccess,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Post Entry',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
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
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 15, color: kSubText),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Journal Date',
                  style: TextStyle(fontSize: 11, color: kSubText),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _refField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Reference Number',
        hintText: 'e.g., INV-001',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black),
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

// ═══════════════════════════════════════════════════════════════
// JOURNAL ENTRY DETAILS SHEET
// ═══════════════════════════════════════════════════════════════

class JournalEntryDetailsSheet extends StatelessWidget {
  final JournalEntry entry;
  final ScrollController scrollController;

  const JournalEntryDetailsSheet({
    super.key,
    required this.entry,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Journal Entry Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 24, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.2)),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildInfoCard(context),
                const SizedBox(height: 16),
                _buildLinesTable(context),
                const SizedBox(height: 16),
                _buildAuditInfo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildDetailRow('Journal ID', entry.entryNumber, context),
          _buildDetailRow(
            'Date',
            DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
            context,
          ),
          _buildDetailRow('Description', entry.description, context),
          _buildDetailRow(
            'Reference',
            entry.reference.isEmpty ? 'N/A' : entry.reference,
            context,
          ),
          _buildDetailRow('Status', entry.status, context),
        ],
      ),
    );
  }

  Widget _buildLinesTable(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journal Lines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Debit',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Credit',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 12, color: Colors.grey.withOpacity(0.2)),
          ...entry.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.accountName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          line.accountCode,
                          style: TextStyle(fontSize: 11, color: kSubText),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      line.debit > 0 ? _formatAmount(line.debit) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      line.credit > 0 ? _formatAmount(line.credit) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 12, color: Colors.grey.withOpacity(0.2)),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(entry.totalDebit),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kSuccess,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatAmount(entry.totalCredit),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kDanger,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Created By', entry.createdBy, context),
          _buildDetailRow(
            'Created At',
            DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt),
            context,
          ),
          if (entry.postedBy != null) ...[
            _buildDetailRow('Posted By', entry.postedBy!, context),
            _buildDetailRow(
              'Posted At',
              DateFormat('dd MMM yyyy, hh:mm a').format(entry.postedAt!),
              context,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => CurrencyUtils.format(amount);
}