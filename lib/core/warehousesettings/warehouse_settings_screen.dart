// lib/core/warehousesettings/views/settings_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehousesettings/warehouse_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color kPrimaryLight = Color(0xFFE8F6FD);
const Color kBg = Color(0xFFF3F5FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1A1F36);
const Color kTextGrey = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kGreen = Color(0xFF10B981);
const Color kRed = Color(0xFFEF4444);

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: kPrimary,
            child: TabBar(
              controller: ctrl.tabController,
              indicatorColor: kWhite,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: kWhite,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'Product',
                ),
                Tab(
                  icon: Icon(Icons.shopping_cart_outlined, size: 18),
                  text: 'Order',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Message Banner ──
          Obx(() {
            if (ctrl.successMessage.value.isNotEmpty) {
              return _MessageBanner(message: ctrl.successMessage.value, isSuccess: true);
            }
            if (ctrl.errorMessage.value.isNotEmpty) {
              return _MessageBanner(message: ctrl.errorMessage.value, isSuccess: false);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: TabBarView(
              controller: ctrl.tabController,
              children: [
                _SettingsTab(
                  title: 'Product Settings',
                  icon: Icons.inventory_2_outlined,
                  description: 'Manage product-related settings like units, brands, tax rates',
                  categories: productSettingCategories,
                  ctrl: ctrl,
                ),
                _SettingsTab(
                  title: 'Order Settings',
                  icon: Icons.shopping_cart_outlined,
                  description: 'Manage order-related settings like warehouses, locations, statuses',
                  categories: orderSettingCategories,
                  ctrl: ctrl,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        elevation: 4,
        onPressed: () => _showFormSheet(context, ctrl, null),
        child: const Icon(Icons.add, color: kWhite, size: 26),
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
// SETTINGS TAB
// ============================================================
class _SettingsTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<SettingCategory> categories;
  final SettingsController ctrl;

  const _SettingsTab({
    required this.title,
    required this.icon,
    required this.description,
    required this.categories,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section Header ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: kTextGrey,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── Category Chips ──────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Obx(() {
                final isActive = ctrl.activeCategory.value == cat.id;
                return GestureDetector(
                  onTap: () => ctrl.setCategory(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      color: isActive ? kPrimary : kWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? kPrimary : kBorder,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(cat.id),
                          size: 13,
                          color: isActive ? kWhite : kTextGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? kWhite : kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),

        const SizedBox(height: 12),

        // ─── Search Bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchBar(ctrl: ctrl),
        ),

        const SizedBox(height: 12),

        // ─── List ──────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _SettingsList(ctrl: ctrl),
          ),
        ),
      ],
    );
  }
}

IconData _getCategoryIcon(String categoryId) {
  switch (categoryId) {
    case 'currency':
      return Icons.monetization_on_outlined;
    case 'rackLocation':
      return Icons.location_on_outlined;
    case 'unit':
      return Icons.straighten_outlined;
    case 'brand':
      return Icons.branding_watermark_outlined;
    case 'taxRate':
      return Icons.percent_rounded;
    case 'warehouse':
      return Icons.warehouse_outlined;
    case 'orderStatus':
      return Icons.pending_actions_outlined;
    case 'carrier':
      return Icons.local_shipping_outlined;
    default:
      return Icons.label_outline_rounded;
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
    return Obx(() {
      final label = ctrl.activeCategoryInfo?.label ?? 'items';
      final icon = _getCategoryIcon(ctrl.activeCategory.value);
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 17, color: kTextGrey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => ctrl.searchQuery.value = v,
                style: const TextStyle(fontSize: 14, color: kTextDark),
                decoration: InputDecoration(
                  hintText: 'Search ${label.toLowerCase()}...',
                  hintStyle: const TextStyle(color: kTextGrey, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Obx(() => ctrl.searchQuery.value.isNotEmpty
                ? GestureDetector(
                    onTap: () => ctrl.searchQuery.value = '',
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, size: 16, color: kTextGrey),
                    ),
                  )
                : const SizedBox(width: 12)),
          ],
        ),
      );
    });
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
      if (ctrl.isLoading.value) {
        return Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5),
            ),
          ),
        );
      }

      final items = ctrl.filteredItems;

      // ─── EMPTY STATE ──────────────────────────────────────────
      if (items.isEmpty) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorder),
                ),
                child: Icon(
                  _getCategoryIcon(ctrl.activeCategory.value),
                  size: 28,
                  color: kTextGrey.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No ${ctrl.activeCategoryInfo?.label.toLowerCase() ?? 'items'} found',
                style: const TextStyle(
                  color: kTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap + to add one',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _showFormSheet(context, ctrl, null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Add ${ctrl.activeCategoryInfo?.label.replaceAll(RegExp(r's$'), '') ?? 'Item'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final categoryLabel = ctrl.activeCategoryInfo?.label ?? 'Items';

      return Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ─── Header with count ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(ctrl.activeCategory.value), size: 15, color: kPrimary),
                  const SizedBox(width: 7),
                  Text(
                    categoryLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} item${items.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showFormSheet(context, ctrl, null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: kPrimary.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.add, size: 15, color: kPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // ─── List Items ──────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final showZone = ctrl.activeCategory.value == 'rackLocation';
                  return _SettingTile(
                    item: item,
                    showZone: showZone,
                    categoryLabel: categoryLabel,
                    categoryIcon: _getCategoryIcon(ctrl.activeCategory.value),
                    onEdit: () => _showFormSheet(context, ctrl, item),
                    onDelete: () => _confirmDelete(context, ctrl, item),
                  );
                },
              ),
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
  final String categoryLabel;
  final IconData categoryIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SettingTile({
    required this.item,
    required this.showZone,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, size: 18, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: kTextDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  showZone && item.zone != null ? 'Zone: ${item.zone}' : categoryLabel,
                  style: const TextStyle(fontSize: 11, color: kTextGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kGreen),
            ),
          ),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.edit_outlined, color: Colors.orange, onTap: onEdit),
          const SizedBox(width: 6),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[100] : color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled ? kBorder : color.withOpacity(0.2),
          ),
        ),
        child: Icon(icon, size: 16, color: disabled ? Colors.grey[350] : color),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: kRed,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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

  final singularLabel = categoryInfo?.label.replaceAll(RegExp(r's$'), '') ?? 'Item';
  final sectionLabel = activeCategory == 'currency' ||
          activeCategory == 'unit' ||
          activeCategory == 'brand' ||
          activeCategory == 'taxRate'
      ? 'Product Settings'
      : 'Order Settings';
  final sectionIcon = activeCategory == 'currency' ||
          activeCategory == 'unit' ||
          activeCategory == 'brand' ||
          activeCategory == 'taxRate'
      ? Icons.inventory_2_outlined
      : Icons.shopping_cart_outlined;

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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // ── Context Bar ──
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(sectionIcon, size: 17, color: kPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editing in' : 'Adding to',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kTextGrey,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              sectionLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kTextDark,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.chevron_right_rounded, size: 14, color: kTextGrey),
                            ),
                            Text(
                              categoryInfo?.label ?? 'Items',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEditing ? 'Edit' : 'New',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Title Row ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_outlined : Icons.add_outlined,
                    color: kPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isEditing ? 'Edit' : 'Add'} $singularLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kTextDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Icon(Icons.close, size: 18, color: kTextGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Name field ──
            _FieldLabel('Name *'),
            const SizedBox(height: 6),
            _InputField(
              controller: nameCtrl,
              hint: 'Enter ${singularLabel.toLowerCase()} name...',
              prefixIcon: _getCategoryIcon(activeCategory),
            ),
            const SizedBox(height: 14),

            // ── Currency fields ──
            if (isCurrency) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Symbol'),
                        const SizedBox(height: 6),
                        _InputField(controller: symbolCtrl, hint: 'e.g. \$, €, £'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Code'),
                        const SizedBox(height: 6),
                        _InputField(controller: codeCtrl, hint: 'e.g. PKR, USD'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Rack location zone ──
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
                        hint: const Text('Select zone...',
                            style: TextStyle(color: kTextGrey, fontSize: 14)),
                        isExpanded: true,
                        items: zoneOptions
                            .map((z) => DropdownMenuItem(
                                  value: z,
                                  child: Text(z, style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => selectedZone.value = v ?? '',
                      ),
                    ),
                  )),
              const SizedBox(height: 14),
            ],

            // ── Default checkbox ──
            Obx(() => GestureDetector(
                  onTap: () => isDefaultObs.value = !isDefaultObs.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDefaultObs.value ? kPrimaryLight : kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDefaultObs.value ? kPrimary.withOpacity(0.3) : kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDefaultObs.value ? kPrimary : kWhite,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isDefaultObs.value ? kPrimary : kBorder,
                              width: 2,
                            ),
                          ),
                          child: isDefaultObs.value
                              ? const Icon(Icons.check, size: 14, color: kWhite)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set as Default',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kTextDark,
                                ),
                              ),
                              Text(
                                'This will be the default option for new ${singularLabel.toLowerCase()}s',
                                style: const TextStyle(fontSize: 11, color: kTextGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextGrey,
                      side: const BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                                if (nameCtrl.text.trim().isEmpty) {
                                  Get.snackbar('Error', 'Name is required');
                                  return;
                                }
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
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor: kPrimary.withOpacity(0.5),
                        ),
                        child: ctrl.isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: kWhite, strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'Update $singularLabel' : 'Add $singularLabel',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    );

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextGrey, fontSize: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: kTextGrey) : null,
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}