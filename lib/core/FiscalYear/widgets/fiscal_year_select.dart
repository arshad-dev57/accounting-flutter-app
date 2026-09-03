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

      final chip = _FiscalYearChip(
        compact: compact,
        current: current,
        isClosed: isClosed,
      );

      final useSheet =
          compact || Overlay.maybeOf(context) == null;

      if (useSheet) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                final sheetContext = Get.overlayContext ?? context;
                _showFiscalYearPicker(
                  sheetContext,
                  c,
                  selectedId,
                  showManageLink: showManageLink,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: chip,
            ),
            if (showManageLink && !useSheet)
              _ManageFiscalYearsButton(
                onPressed: () => Get.to(() => const FiscalYearListScreen()),
              ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
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
            child: chip,
          ),
          if (showManageLink)
            _ManageFiscalYearsButton(
              onPressed: () => Get.to(() => const FiscalYearListScreen()),
            ),
        ],
      );
    });
  }
}

void _showFiscalYearPicker(
  BuildContext context,
  FiscalYearController c,
  String? selectedId, {
  bool showManageLink = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select fiscal year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            ...c.fiscalYears.map((y) {
              final selected = y.id == selectedId;
              return ListTile(
                leading: Icon(
                  selected ? Icons.check_circle : Icons.calendar_month_outlined,
                  color: selected ? kPrimary : Colors.grey,
                ),
                title: Text(y.name),
                subtitle: Text(y.isClosed ? 'Closed' : 'Open'),
                onTap: () {
                  c.selectFiscalYear(y);
                  Navigator.pop(ctx);
                },
              );
            }),
            if (showManageLink) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: kPrimary),
                title: const Text('Manage fiscal years'),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.to(() => const FiscalYearListScreen());
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _ManageFiscalYearsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ManageFiscalYearsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.settings_outlined, size: 18, color: kPrimary),
        ),
      ),
    );
  }
}

class _FiscalYearChip extends StatelessWidget {
  final bool compact;
  final FiscalYear current;
  final bool isClosed;

  const _FiscalYearChip({
    required this.compact,
    required this.current,
    required this.isClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            constraints: BoxConstraints(maxWidth: compact ? 52 : 110),
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
          if (!compact) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}
