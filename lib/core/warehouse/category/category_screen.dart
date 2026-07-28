import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/category/category_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoriesController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgLight,
        body: Column(
          children: [
            _buildTopHeader(controller),
            Expanded(
              child: TabBarView(
                children: [
                  // ── Tab 1: Main Categories ──
                  _CategoriesTab(controller: controller),
                  // ── Tab 2: Sub-Categories ──
                  _SubCategoriesTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP HEADER ────────────────────────────────────────────────

  Widget _buildTopHeader(CategoriesController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalCategories.value} categories • ${controller.totalSubCategories.value} sub-categories',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Row(
                      children: [
                        _compactKpi(
                          'Main',
                          controller.rootCategories.value.toString(),
                          Colors.blue.shade800,
                        ),
                        const SizedBox(width: 10),
                        _compactKpi(
                          'Sub',
                          controller.totalSubCategories.value.toString(),
                          Colors.purple.shade800,
                        ),
                        const SizedBox(width: 10),
                        _compactKpi(
                          'Products',
                          controller.totalProducts.value.toString(),
                          Colors.green.shade800,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshCategories,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                child: _SearchField(controller: controller),
              ),
            ),

            // ── TabBar ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                padding: const EdgeInsets.all(4),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black.withOpacity(0.6),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder, size: 14),
                        const SizedBox(width: 6),
                        const Text('Categories'),
                        const SizedBox(width: 6),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.rootCategories.value}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 14),
                        const SizedBox(width: 6),
                        const Text('Sub-Categories'),
                        const SizedBox(width: 6),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.totalSubCategories.value}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple.shade700,
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
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 — MAIN CATEGORIES
// ═══════════════════════════════════════════════════════════════

class _CategoriesTab extends StatelessWidget {
  final CategoriesController controller;
  const _CategoriesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }

        final mainCats = controller.filteredCategories
            .where((c) => c['parentId'] == null)
            .toList();

        if (mainCats.isEmpty && !controller.isLoading.value) {
          return _buildEmptyState(
            context,
            icon: Icons.folder_outlined,
            title: 'No categories yet',
            subtitle: 'Tap + to add your first category',
            onAdd: () => _showAddCategoryDialog(context, controller, null),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          itemCount: mainCats.length,
          itemBuilder: (context, index) {
            final cat = mainCats[index];
            return _CategoryCard(
              cat: cat,
              controller: controller,
              onTap: () => _showCategoryDetails(context, cat, controller, index),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, controller, null),
        backgroundColor: kPrimary,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.black, size: 20),
        label: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 — SUB-CATEGORIES
// ═══════════════════════════════════════════════════════════════

class _SubCategoriesTab extends StatefulWidget {
  final CategoriesController controller;
  const _SubCategoriesTab({required this.controller});

  @override
  State<_SubCategoriesTab> createState() => _SubCategoriesTabState();
}

class _SubCategoriesTabState extends State<_SubCategoriesTab> {
  String? _selectedParentId;

  CategoriesController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }

        final mainCats = controller.categories
            .where((c) => c['parentId'] == null)
            .toList();

        if (mainCats.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.folder_outlined,
            title: 'No categories yet',
            subtitle: 'Add a main category first, then add sub-categories',
            onAdd: null,
          );
        }

        final subCats = controller.filteredCategories
            .where((c) {
              if (c['parentId'] == null) return false;
              if (_selectedParentId != null && _selectedParentId != 'all') {
                return c['parentId'] == _selectedParentId;
              }
              return true;
            })
            .toList();

        return Column(
          children: [
            // ── Parent Filter Chips ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Filter by parent category',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kSubText,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _parentChip('All', null, mainCats),
                        ...mainCats.map(
                          (cat) => _parentChip(
                            cat['name'] ?? '',
                            cat['id'],
                            mainCats,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Sub-Category List ──
            Expanded(
              child: subCats.isEmpty
                  ? _buildEmptyState(
                      context,
                      icon: Icons.account_tree_outlined,
                      title: _selectedParentId != null && _selectedParentId != 'all'
                          ? 'No sub-categories in this category'
                          : 'No sub-categories yet',
                      subtitle: 'Tap + to add a sub-category under a parent',
                      onAdd: () => _showAddSubCategoryDialog(
                        context,
                        controller,
                        mainCats,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                      itemCount: subCats.length,
                      itemBuilder: (context, index) {
                        final cat = subCats[index];
                        return _SubCategoryCard(
                          cat: cat,
                          controller: controller,
                          parentName: _getParentName(cat['parentId'], mainCats),
                          onTap: () => _showSubCategoryDetails(
                            context,
                            cat,
                            controller,
                            mainCats,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final mainCats = controller.categories
              .where((c) => c['parentId'] == null)
              .toList();
          _showAddSubCategoryDialog(context, controller, mainCats);
        },
        backgroundColor: kPrimary,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.black, size: 20),
        label: const Text(
          'Add Sub-Category',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _parentChip(
    String label,
    String? id,
    List<Map<String, dynamic>> mainCats,
  ) {
    final isSelected = id == null
        ? (_selectedParentId == null || _selectedParentId == 'all')
        : _selectedParentId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedParentId = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : kSubText,
            ),
          ),
        ),
      ),
    );
  }

  String _getParentName(String? parentId, List<Map<String, dynamic>> mainCats) {
    if (parentId == null) return '';
    final parent = mainCats.firstWhere(
      (c) => c['id'] == parentId,
      orElse: () => {},
    );
    return parent['name'] ?? '';
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY CARD (Main)
// ═══════════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final CategoriesController controller;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.cat,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = controller.getCategoryColor(cat['level'] ?? 1);
    final productCount = cat['productCount'] ?? 0;
    final subCount = cat['subCategoryCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (cat['description'] != null && cat['description'] != '')
                            ? cat['description']
                            : 'No description',
                        style: TextStyle(
                          fontSize: 11,
                          color: (cat['description'] != null &&
                                  cat['description'] != '')
                              ? kSubText
                              : kSubText.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _badgeChip(
                            icon: Icons.account_tree_outlined,
                            label: '$subCount sub',
                            color: Colors.blue.shade700,
                            bg: Colors.blue.withOpacity(0.08),
                          ),
                          const SizedBox(width: 6),
                          _badgeChip(
                            icon: Icons.inventory_2_outlined,
                            label: '$productCount items',
                            color: color,
                            bg: color.withOpacity(0.08),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB-CATEGORY CARD
// ═══════════════════════════════════════════════════════════════

class _SubCategoryCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final CategoriesController controller;
  final String parentName;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.cat,
    required this.controller,
    required this.parentName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = controller.getCategoryColor(cat['level'] ?? 2);
    final productCount = cat['productCount'] ?? 0;
    final subCount = cat['subCategoryCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    color: color,
                    size: 22,
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
                              cat['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (parentName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 10,
                                    color: Colors.purple.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    parentName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (cat['description'] != null && cat['description'] != '')
                            ? cat['description']
                            : 'No description',
                        style: TextStyle(
                          fontSize: 11,
                          color: (cat['description'] != null &&
                                  cat['description'] != '')
                              ? kSubText
                              : kSubText.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (subCount > 0) ...[
                            _badgeChip(
                              icon: Icons.account_tree_outlined,
                              label: '$subCount nested',
                              color: Colors.teal.shade700,
                              bg: Colors.teal.withOpacity(0.08),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _badgeChip(
                            icon: Icons.inventory_2_outlined,
                            label: '$productCount items',
                            color: color,
                            bg: color.withOpacity(0.08),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback? onAdd,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 36, color: kPrimary.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: kSubText),
          textAlign: TextAlign.center,
        ),
        if (onAdd != null) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16, color: Colors.black),
            label: const Text(
              'Add Now',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// SEARCH FIELD
// ═══════════════════════════════════════════════════════════════

class _SearchField extends StatefulWidget {
  final CategoriesController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() {});
        v.isEmpty
            ? widget.controller.clearSearch()
            : widget.controller.searchCategories(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search categories...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  widget.controller.clearSearch();
                  setState(() {});
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — ADD CATEGORY (Main)
// ═══════════════════════════════════════════════════════════════

void _showAddCategoryDialog(
  BuildContext context,
  CategoriesController controller,
  String? parentId,
) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Add Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Category Name *'),
            const SizedBox(height: 6),
            _textField(
              controller: nameCtrl,
              hint: 'e.g., Electronics',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel('Description (Optional)'),
            const SizedBox(height: 6),
            _textField(
              controller: descCtrl,
              hint: 'Enter category description...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: kSubText)),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.createCategory({
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    });
                    if (ok) {
                      Navigator.pop(context);
                      _snackSuccess('Category created successfully');
                    } else {
                      _snackError('Failed to create category');
                    }
                  },
            style: _primaryBtnStyle(),
            child: controller.isSubmitting.value
                ? _loadingIndicator()
                : const Text(
                    'Save Category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — ADD SUB-CATEGORY (with Parent dropdown)
// ═══════════════════════════════════════════════════════════════

void _showAddSubCategoryDialog(
  BuildContext context,
  CategoriesController controller,
  List<Map<String, dynamic>> mainCats, {
  String? preSelectedParentId,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String? selectedParentId = preSelectedParentId ?? 
      (mainCats.isNotEmpty ? mainCats.first['id'] : null);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_tree_outlined,
                color: Colors.purple.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Sub-Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Parent Category Dropdown ──
              _fieldLabel('Parent Category *'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedParentId,
                    hint: Text(
                      'Select parent category',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: kSubText,
                      size: 20,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                    items: mainCats.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'],
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              size: 14,
                              color: controller.getCategoryColor(1),
                            ),
                            const SizedBox(width: 8),
                            Text(cat['name'] ?? ''),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedParentId = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _fieldLabel('Sub-Category Name *'),
              const SizedBox(height: 6),
              _textField(
                controller: nameCtrl,
                hint: 'e.g., Smartphones',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Description (Optional)'),
              const SizedBox(height: 6),
              _textField(
                controller: descCtrl,
                hint: 'Enter sub-category description...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (selectedParentId == null) {
                        _snackError('Please select a parent category');
                        return;
                      }
                      final ok = await controller.createCategory({
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'parentId': selectedParentId,
                      });
                      if (ok) {
                        Navigator.pop(context);
                        _snackSuccess('Sub-category created successfully');
                      } else {
                        _snackError('Failed to create sub-category');
                      }
                    },
              style: _primaryBtnStyle(),
              child: controller.isSubmitting.value
                  ? _loadingIndicator()
                  : const Text(
                      'Add Sub-Category',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — CATEGORY DETAILS (Main)
// ═══════════════════════════════════════════════════════════════

void _showCategoryDetails(
  BuildContext context,
  Map<String, dynamic> cat,
  CategoriesController controller,
  int index,
) {
  final color = controller.getCategoryColor(cat['level'] ?? 1);
  final productCount = cat['productCount'] ?? 0;
  final subCount = cat['subCategoryCount'] ?? 0;
  final createdAt =
      cat['createdAt'] != null ? DateTime.tryParse(cat['createdAt']) : null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _sheetHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.folder, color: color, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Main Category',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$productCount items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                    const SizedBox(height: 16),
                    _detailRow('Description', cat['description'] ?? 'No description'),
                    _detailRow('Sub-Categories', '$subCount'),
                    _detailRow('Products', '$productCount items'),
                    _detailRow(
                      'Created',
                      createdAt != null
                          ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                          : 'N/A',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditCategoryDialog(context, cat, controller);
                            },
                            style: _outlineBtnStyle(),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteDialog(context, cat, controller);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDanger,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
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
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — SUB-CATEGORY DETAILS
// ═══════════════════════════════════════════════════════════════

void _showSubCategoryDetails(
  BuildContext context,
  Map<String, dynamic> cat,
  CategoriesController controller,
  List<Map<String, dynamic>> mainCats,
) {
  final color = controller.getCategoryColor(cat['level'] ?? 2);
  final productCount = cat['productCount'] ?? 0;
  final subCount = cat['subCategoryCount'] ?? 0;
  final createdAt =
      cat['createdAt'] != null ? DateTime.tryParse(cat['createdAt']) : null;
  final parentName = mainCats.firstWhere(
    (c) => c['id'] == cat['parentId'],
    orElse: () => {},
  )['name'] ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _sheetHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.subdirectory_arrow_right,
                            color: color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 11,
                                    color: Colors.purple.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Under: $parentName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kSubText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$productCount items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                    const SizedBox(height: 16),
                    _detailRow('Description', cat['description'] ?? 'No description'),
                    _detailRow('Parent Category', parentName),
                    _detailRow('Nested Sub-Categories', '$subCount'),
                    _detailRow('Products', '$productCount items'),
                    _detailRow(
                      'Created',
                      createdAt != null
                          ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                          : 'N/A',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditCategoryDialog(context, cat, controller);
                            },
                            style: _outlineBtnStyle(),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteDialog(context, cat, controller);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDanger,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
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
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — EDIT CATEGORY
// ═══════════════════════════════════════════════════════════════

void _showEditCategoryDialog(
  BuildContext context,
  Map<String, dynamic> cat,
  CategoriesController controller,
) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: cat['name'] ?? '');
  final descCtrl = TextEditingController(text: cat['description'] ?? '');

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit_outlined, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Category Name *'),
            const SizedBox(height: 6),
            _textField(
              controller: nameCtrl,
              hint: 'e.g., Electronics',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel('Description (Optional)'),
            const SizedBox(height: 6),
            _textField(
              controller: descCtrl,
              hint: 'Enter category description...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: kSubText)),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final ok = await controller.updateCategory(
                      cat['id'] ?? '',
                      {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      },
                    );
                    if (ok) {
                      Navigator.pop(context);
                      _snackSuccess('Category updated successfully');
                    } else {
                      _snackError('Failed to update category');
                    }
                  },
            style: _primaryBtnStyle(),
            child: controller.isSubmitting.value
                ? _loadingIndicator()
                : const Text(
                    'Update Category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// DIALOGS — DELETE
// ═══════════════════════════════════════════════════════════════

void _showDeleteDialog(
  BuildContext context,
  Map<String, dynamic> cat,
  CategoriesController controller,
) {
  final productCount = cat['productCount'] ?? 0;
  final subCount = cat['subCategoryCount'] ?? 0;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: kDanger, size: 22),
          const SizedBox(width: 10),
          Text(
            'Delete Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${cat['name']}"?',
            style: TextStyle(fontSize: 14, color: kText),
          ),
          if (productCount > 0 || subCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDanger.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subCount > 0)
                    Text(
                      '• $subCount sub-category(s) will be deleted',
                      style: TextStyle(fontSize: 13, color: kDanger),
                    ),
                  if (productCount > 0)
                    Text(
                      '• $productCount product(s) will be affected',
                      style: TextStyle(fontSize: 13, color: kDanger),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: kSubText)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await controller.deleteCategory(cat['id'] ?? '');
            if (ok) {
              _snackSuccess('Category deleted successfully');
            } else {
              _snackError('Failed to delete category');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kDanger,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════

Widget _sheetHandle() {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: kText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _fieldLabel(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: kSubText,
    ),
  );
}

Widget _textField({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      filled: true,
      fillColor: kCardBg,
    ),
    style: TextStyle(fontSize: 13, color: kText),
  );
}

ButtonStyle _primaryBtnStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );
}

ButtonStyle _outlineBtnStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: kPrimary,
    side: const BorderSide(color: kPrimary),
    padding: const EdgeInsets.symmetric(vertical: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

Widget _loadingIndicator() {
  return const SizedBox(
    height: 16,
    width: 16,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
  );
}

void _snackSuccess(String msg) {
  Get.snackbar(
    'Success',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: kSuccess,
    colorText: Colors.black,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  );
}

void _snackError(String msg) {
  Get.snackbar(
    'Error',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: kDanger,
    colorText: Colors.black,
    margin: const EdgeInsets.all(16),
  );
}