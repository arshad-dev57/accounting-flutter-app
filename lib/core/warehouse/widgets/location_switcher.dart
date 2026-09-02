// core/warehouse/widgets/location_switcher.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/model/location_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Compact location picker for drawer / header (mirrors FiscalYearSelect).
class LocationSwitcher extends StatelessWidget {
  final bool compact;
  final bool showManageLink;

  const LocationSwitcher({
    super.key,
    this.compact = true,
    this.showManageLink = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LocationController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<LocationController>();

    return Obx(() {
      if (c.isLoading.value && c.locations.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
          ),
        );
      }

      if (c.locations.isEmpty) {
        final isAdmin = Get.isRegistered<PermissionService>() &&
            PermissionService.to.isAdmin;
        if (!isAdmin) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'No store assigned',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }
        return TextButton.icon(
          onPressed: () => Get.toNamed('/warehouse/locations'),
          icon: const Icon(Icons.place_outlined, size: 16, color: kPrimary),
          label: Text(
            'Set up location',
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

      final selected = c.selectedLocation.value;
      final selectedId = c.locations.any((l) => l.id == selected?.id)
          ? selected?.id
          : c.locations.first.id;
      final current =
          c.locations.firstWhereOrNull((l) => l.id == selectedId) ??
          c.locations.first;

      final chip = _LocationChip(
        compact: compact,
        current: current,
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
                _showLocationPicker(
                  sheetContext,
                  c,
                  selectedId,
                  showManageLink: showManageLink,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: chip,
            ),
            if (showManageLink &&
                !useSheet &&
                Get.isRegistered<PermissionService>() &&
                PermissionService.to.isAdmin)
              _ManageLocationsButton(
                onPressed: () => Get.toNamed('/warehouse/locations'),
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
              final match = c.locations.firstWhereOrNull((l) => l.id == id);
              if (match != null) c.selectLocation(match);
            },
            itemBuilder: (ctx) => c.locations.map((WarehouseLocation loc) {
              return PopupMenuItem<String>(
                value: loc.id,
                child: Row(
                  children: [
                    if (loc.id == selectedId)
                      Icon(Icons.check, size: 16, color: kPrimary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        loc.isDefault ? '${loc.name} · Default' : loc.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: chip,
          ),
          if (showManageLink &&
              Get.isRegistered<PermissionService>() &&
              PermissionService.to.isAdmin)
            _ManageLocationsButton(
              onPressed: () => Get.toNamed('/warehouse/locations'),
            ),
        ],
      );
    });
  }
}

void _showLocationPicker(
  BuildContext context,
  LocationController c,
  String? selectedId, {
  bool showManageLink = false,
}) {
  final isAdmin = Get.isRegistered<PermissionService>() &&
      PermissionService.to.isAdmin;

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
                      'Select location',
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
            ...c.locations.map((loc) {
              final selected = loc.id == selectedId;
              return ListTile(
                leading: Icon(
                  selected ? Icons.check_circle : Icons.place_outlined,
                  color: selected ? kPrimary : Colors.grey,
                ),
                title: Text(loc.name),
                subtitle: Text(loc.code),
                onTap: () {
                  c.selectLocation(loc);
                  Navigator.pop(ctx);
                },
              );
            }),
            if (showManageLink && isAdmin) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: kPrimary),
                title: const Text('Manage locations'),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.toNamed('/warehouse/locations');
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

class _ManageLocationsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ManageLocationsButton({required this.onPressed});

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

class _LocationChip extends StatelessWidget {
  final bool compact;
  final WarehouseLocation current;

  const _LocationChip({required this.compact, required this.current});

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
            Icons.place_rounded,
            size: compact ? 14 : 16,
            color: kPrimary,
          ),
          SizedBox(width: compact ? 4 : 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 56 : 120),
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
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                current.code,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
