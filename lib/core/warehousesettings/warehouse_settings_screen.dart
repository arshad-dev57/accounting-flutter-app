import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehousesettings/warehouse_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ============================================================
// COLOR CONSTANTS — match your app
// ============================================================
const Color kPrimaryLight = Color(0xFFE8F6FD);
const Color kBg = Color(0xFFEFF2F5);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1A1F36);
const Color kTextGrey = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);

// ============================================================
// SETTINGS SCREEN
// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Obx(() => ctrl.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: kWhite),
                  onPressed: ctrl.fetchSettings,
                )),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────
          Obx(() {
            if (ctrl.successMessage.value.isNotEmpty) {
              return _MessageBanner(
                message: ctrl.successMessage.value,
                isSuccess: true,
              );
            }
            if (ctrl.errorMessage.value.isNotEmpty) {
              return _MessageBanner(
                message: ctrl.errorMessage.value,
                isSuccess: false,
              );
            }
            return const SizedBox.shrink();
          }),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Product Settings Tabs ──────────────────
                _SectionCard(
                  title: 'Product Settings',
                  icon: Icons.inventory_2_outlined,
                  categories: productSettingCategories,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 12),

                // ── Order Settings Tabs ────────────────────
                _SectionCard(
                  title: 'Order Settings',
                  icon: Icons.shopping_cart_outlined,
                  categories: orderSettingCategories,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 12),

                // ── Search ────────────────────────────────
                _SearchBar(ctrl: ctrl),
                const SizedBox(height: 12),

                // ── List ─────────────────────────────────
                _SettingsList(ctrl: ctrl),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: () => _showFormSheet(context, ctrl, null),
        child: const Icon(Icons.add, color: kWhite),
      ),
    );
  }
}

// ============================================================
// MESSAGE BANNER
// ============================================================
class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;
  const _MessageBanner({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isSuccess ? kGreen.withOpacity(0.1) : kRed.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: isSuccess ? kGreen : kRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? kGreen : kRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION CARD (tabs)
// ============================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<SettingCategory> categories;
  final SettingsController ctrl;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.categories,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: kPrimary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable tabs
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Obx(() {
                  final isActive = ctrl.activeCategory.value == cat.id;
                  return GestureDetector(
                    onTap: () => ctrl.setCategory(cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? kPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? kWhite : kTextGrey,
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEARCH BAR
// ============================================================
class _SearchBar extends StatelessWidget {
  final SettingsController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: TextField(
        onChanged: (v) => ctrl.searchQuery.value = v,
        style: const TextStyle(fontSize: 14, color: kTextDark),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(color: kTextGrey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: kTextGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS LIST
// ============================================================
class _SettingsList extends StatelessWidget {
  final SettingsController ctrl;
  const _SettingsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Loading ──
      if (ctrl.isLoading.value) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: kPrimary),
          ),
        );
      }

      final items = ctrl.filteredItems;

      // ── Empty ──
      if (items.isEmpty) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No items found',
                style: TextStyle(color: kTextGrey, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add one',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ),
        );
      }

      // ── List ──
      return Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ctrl.activeCategoryInfo?.label ?? 'Items',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: kTextGrey),
                  ),
                ],
              ),
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
              itemBuilder: (context, index) {
                final item = items[index];
                final showZone = ctrl.activeCategory.value == 'rackLocation';
                return _SettingTile(
                  item: item,
                  showZone: showZone,
                  onEdit: () => _showFormSheet(context, ctrl, item),
                  onDelete: () => _confirmDelete(context, ctrl, item),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

// ============================================================
// SETTING TILE
// ============================================================
class _SettingTile extends StatelessWidget {
  final SettingItem item;
  final bool showZone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SettingTile({
    required this.item,
    required this.showZone,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: kTextDark,
                      ),
                    ),
                    if (item.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
                if (showZone && item.zone != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Zone: ${item.zone}',
                    style: const TextStyle(fontSize: 12, color: kTextGrey),
                  ),
                ],
              ],
            ),
          ),

          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGreen),
            ),
          ),
          const SizedBox(width: 8),

          // Edit
          _ActionBtn(
            icon: Icons.edit_outlined,
            color: Colors.orange,
            onTap: onEdit,
          ),
          const SizedBox(width: 4),

          // Delete
          _ActionBtn(
            icon: Icons.delete_outline,
            color: kRed,
            onTap: item.isDefault ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[100] : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: disabled ? Colors.grey[350] : color,
        ),
      ),
    );
  }
}

// ============================================================
// CONFIRM DELETE
// ============================================================
void _confirmDelete(BuildContext context, SettingsController ctrl, SettingItem item) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Text('Delete "${item.name}"?', style: const TextStyle(color: kTextGrey)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kTextGrey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: kWhite, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            ctrl.deleteSetting(item.id);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ============================================================
// ADD / EDIT BOTTOM SHEET
// ============================================================
void _showFormSheet(BuildContext context, SettingsController ctrl, SettingItem? item) {
  final isEditing = item != null;
  final nameCtrl = TextEditingController(text: item?.name ?? '');
  final symbolCtrl = TextEditingController(text: item?.symbol ?? '');
  final codeCtrl = TextEditingController(text: item?.code ?? '');
  final isDefaultObs = (item?.isDefault ?? false).obs;
  final selectedZone = (item?.zone ?? '').obs;

  final activeCategory = ctrl.activeCategory.value;
  final isCurrency = activeCategory == 'currency';
  final isRackLocation = activeCategory == 'rackLocation';

  final zoneOptions = ['Receiving', 'Storage', 'Picking', 'Shipping', 'Returns', 'Bulk'];
  final categoryInfo = ctrl.activeCategoryInfo;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings_outlined, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isEditing ? 'Edit' : 'Add'} ${categoryInfo?.label.replaceAll(RegExp(r's$'), '') ?? 'Item'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kTextDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, size: 18, color: kTextGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            _FieldLabel('Name *'),
            const SizedBox(height: 6),
            _InputField(controller: nameCtrl, hint: 'Enter name...'),
            const SizedBox(height: 14),

            // Currency fields
            if (isCurrency) ...[
              _FieldLabel('Symbol'),
              const SizedBox(height: 6),
              _InputField(controller: symbolCtrl, hint: 'e.g. \$, €, £'),
              const SizedBox(height: 14),
              _FieldLabel('Code'),
              const SizedBox(height: 6),
              _InputField(controller: codeCtrl, hint: 'e.g. PKR, USD'),
              const SizedBox(height: 14),
            ],

            // Rack location zone
            if (isRackLocation) ...[
              _FieldLabel('Zone'),
              const SizedBox(height: 6),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedZone.value.isEmpty ? null : selectedZone.value,
                        hint: const Text('Select zone...', style: TextStyle(color: kTextGrey, fontSize: 14)),
                        isExpanded: true,
                        items: zoneOptions.map((z) => DropdownMenuItem(value: z, child: Text(z, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => selectedZone.value = v ?? '',
                      ),
                    ),
                  )),
              const SizedBox(height: 14),
            ],

            // Default checkbox
            Obx(() => GestureDetector(
                  onTap: () => isDefaultObs.value = !isDefaultObs.value,
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDefaultObs.value ? kPrimary : kWhite,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: isDefaultObs.value ? kPrimary : kBorder, width: 2),
                        ),
                        child: isDefaultObs.value
                            ? const Icon(Icons.check, size: 14, color: kWhite)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Text('Set as Default', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextGrey,
                      side: BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Obx(() => ElevatedButton(
                        onPressed: ctrl.isSaving.value
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                final payload = <String, dynamic>{
                                  'category': activeCategory,
                                  'name': nameCtrl.text.trim(),
                                  'isDefault': isDefaultObs.value,
                                };
                                if (isCurrency) {
                                  payload['symbol'] = symbolCtrl.text.trim();
                                  payload['code'] = codeCtrl.text.trim().toUpperCase();
                                }
                                if (isRackLocation && selectedZone.value.isNotEmpty) {
                                  payload['zone'] = selectedZone.value;
                                }
                                bool success;
                                if (isEditing) {
                                  success = await ctrl.updateSetting(item!.id, payload);
                                } else {
                                  success = await ctrl.createSetting(payload);
                                }
                                if (success && context.mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          disabledBackgroundColor: kPrimary.withOpacity(0.5),
                        ),
                        child: ctrl.isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'Update' : 'Add',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// HELPERS
// ============================================================
Widget _FieldLabel(String label) => Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
    );

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _InputField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextGrey, fontSize: 14),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}