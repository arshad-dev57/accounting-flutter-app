// core/FiscalYear/widgets/fiscal_year_select.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Header / inline fiscal year picker (mirrors Next.js FiscalYearSelect).
class FiscalYearSelect extends StatelessWidget {
  final bool compact;
  final bool showManageLink;

  const FiscalYearSelect({
    super.key,
    this.compact = true,
    this.showManageLink = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FiscalYearController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<FiscalYearController>();

    return Obx(() {
      if (c.isLoading.value && c.fiscalYears.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
          ),
        );
      }

      if (c.fiscalYears.isEmpty) {
        return TextButton.icon(
          onPressed: () => Get.to(() => const FiscalYearListScreen()),
          icon: const Icon(Icons.calendar_month_outlined, size: 16, color: kPrimary),
          label: Text(
            'Set up FY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }

      final selected = c.selectedFiscalYear.value;
      final selectedId = c.fiscalYears.any((y) => y.id == selected?.id)
          ? selected?.id
          : c.fiscalYears.first.id;
      final current =
          c.fiscalYears.firstWhereOrNull((y) => y.id == selectedId) ??
          c.fiscalYears.first;
      final isClosed = current.isClosed;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: '${current.name} (${current.statusDisplay})',
            initialValue: selectedId,
            onSelected: (id) {
              final match = c.fiscalYears.firstWhereOrNull((y) => y.id == id);
              if (match != null) c.selectFiscalYear(match);
            },
            itemBuilder: (ctx) => c.fiscalYears.map((FiscalYear y) {
              return PopupMenuItem<String>(
                value: y.id,
                child: Row(
                  children: [
                    if (y.id == selectedId)
                      Icon(Icons.check, size: 16, color: kPrimary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        y.isClosed ? '${y.name} · Closed' : y.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: compact ? 14 : 16,
                    color: kPrimary,
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 64 : 110),
                    child: Text(
                      current.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D2E),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    size: compact ? 16 : 18,
                    color: const Color(0xFF1A1D2E),
                  ),
                  // Status pill only on non-compact headers (avoids AppBar overflow)
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isClosed
                            ? Colors.grey.shade100
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isClosed ? 'Closed' : 'Open',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isClosed
                              ? Colors.grey.shade700
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Compact: tiny status dot instead of "Open"/"Closed" chip
                    const SizedBox(width: 4),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isClosed
                            ? Colors.grey.shade500
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showManageLink)
            IconButton(
              tooltip: 'Manage fiscal years',
              icon: Icon(Icons.settings_outlined, size: 18, color: kPrimary),
              onPressed: () => Get.to(() => const FiscalYearListScreen()),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      );
    });
  }
}
