// lib/core/CreditNote/screens/creditnote_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/CreditNote/controllers/creditnote_controller.dart';
import 'package:LedgerPro_app/core/CreditNote/models/credit_note_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sizer/sizer.dart';

class CreditNotesScreen extends StatelessWidget {
  const CreditNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreditNoteController());
    return _buildMobileLayout(context, controller);
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout(
    BuildContext context,
    CreditNoteController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.creditNotes.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return Column(
          children: [
            _buildFilterBar(controller),
            _buildSummaryStrip(controller),
            Expanded(child: _buildCreditNotesList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showCreateCreditNoteDialog(),
        backgroundColor: kWarning,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CreditNoteController controller,
  ) {
    return AppBar(
      title: const Text(
        'Credit Notes',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showSearchDialog(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.date_range, color: Colors.black87),
          onPressed: () => controller.selectDateRange(),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportCreditNotes(),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(CreditNoteController controller) {
    final filters = ['All', 'Issued', 'Applied', 'Expired'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: kCardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: filters.map((f) {
              final isSelected = controller.selectedFilter.value == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) =>
                      controller.applyDateFilter(isSelected ? 'All' : f),
                  backgroundColor: kBg,
                  selectedColor: kPrimary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? kPrimary : kSubText,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY STRIP
  // ============================================================

  Widget _buildSummaryStrip(CreditNoteController controller) {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _summaryCard(
                'Total',
                controller.totalCount.value.toString(),
                kPrimary,
                Icons.note_alt_outlined,
                isCount: true,
              ),
              const SizedBox(width: 10),
              _summaryCard(
                'Amount',
                controller.formatAmount(controller.totalAmount.value),
                kWarning,
                Icons.attach_money,
              ),
              const SizedBox(width: 10),
              _summaryCard(
                'Applied',
                controller.formatAmount(controller.appliedAmount.value),
                kSuccess,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _summaryCard(
                'Remaining',
                controller.formatAmount(controller.remainingAmount.value),
                kPrimary,
                Icons.pending_outlined,
              ),
              const SizedBox(width: 10),
              _summaryCard(
                'Expired',
                controller.formatAmount(controller.expiredAmount.value),
                kDanger,
                Icons.warning_amber_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREDIT NOTES LIST
  // ============================================================

  Widget _buildCreditNotesList(
    CreditNoteController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final notes = controller.creditNotes;

      if (notes.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_outlined,
                size: 64,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No credit notes found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.showCreateCreditNoteDialog(),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Create Credit Note',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWarning,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadCreditNotesData();
          await controller.loadSummary();
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: notes.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCreditNoteCard(notes[index], controller),
          ),
        ),
      );
    });
  }

  Widget _buildCreditNoteCard(
    CreditNote cn,
    CreditNoteController controller,
  ) {
    final statusColor = cn.status == 'Issued'
        ? kWarning
        : cn.status == 'Applied'
            ? kSuccess
            : kDanger;

    final isExpiringSoon = cn.status == 'Issued' &&
        cn.expiryDate != null &&
        cn.expiryDate!.difference(DateTime.now()).inDays <= 7;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.viewCreditNoteDetails(cn),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ──────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      size: 20,
                      color: kWarning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cn.creditNoteNumber,
                          style:  TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cn.customerName,
                          style: TextStyle(fontSize: 12, color: kSubText),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statusBadge(cn.status, statusColor),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd MMM yyyy').format(cn.date),
                              style:
                                  TextStyle(fontSize: 10, color: kSubText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        controller.formatAmount(cn.amount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kWarning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rem: ${controller.formatAmount(cn.remainingAmount)}',
                        style:
                            TextStyle(fontSize: 10, color: kPrimary),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Invoice ref ──────────────────────────────────
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_outlined, size: 13, color: kSubText),
                    const SizedBox(width: 6),
                    Text(
                      'Invoice: ${cn.originalInvoiceNumber}',
                      style: TextStyle(fontSize: 11, color: kSubText),
                    ),
                    const Spacer(),
                    Text(
                      cn.reasonType,
                      style: TextStyle(
                        fontSize: 10,
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Expiry warning ───────────────────────────────
              if (isExpiringSoon && cn.expiryDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 13, color: kDanger),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${DateFormat('dd MMM yyyy').format(cn.expiryDate!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: kDanger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Action buttons ───────────────────────────────
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _outlineBtn(
                      Icons.visibility_outlined,
                      'Details',
                      kSubText,
                      () => controller.viewCreditNoteDetails(cn),
                    ),
                  ),
                  if (cn.status == 'Issued') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _filledBtn(
                        Icons.check_circle_outline,
                        'Apply',
                        kSuccess,
                        () => controller.showApplyCreditNoteDialog(cn),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _outlineBtn(
                      Icons.print_outlined,
                      'Print',
                      kSubText,
                      () => controller.printCreditNote(cn),
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

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _outlineBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: kText)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _filledBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: Colors.white),
      label:
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ============================================================
  // SEARCH DIALOG
  // ============================================================

  void _showSearchDialog(
    BuildContext context,
    CreditNoteController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Credit Notes',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Credit note #, customer, invoice…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) {
            controller.searchController.text = v;
            controller.searchController.selection =
                TextSelection.fromPosition(
              TextPosition(offset: v.length),
            );
          },
          onSubmitted: (_) => Navigator.pop(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}