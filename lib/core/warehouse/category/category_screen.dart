
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

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.categories.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _CategoryListView(
                  controller: controller,
                  onCategoryTap: (cat, index) => _showCategoryDetails(context, cat, controller, index),
                  onAddCategory: () => _showAddCategoryDialog(context, controller, null),
                  onSubCategoryTap: (parentId) => _showSubCategories(context, parentId, controller),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, controller, null),
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black, size: 24),
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
                        Obx(() => Text(
                          '${controller.totalCategories.value} categories • ${controller.totalSubCategories.value} sub-categories',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Obx(() => Row(
                    children: [
                      _compactKpi('Main', controller.rootCategories.value.toString(), Colors.blue.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Sub', controller.totalSubCategories.value.toString(), Colors.purple.shade800),
                      const SizedBox(width: 10),
                      _compactKpi('Products', controller.totalProducts.value.toString(), Colors.green.shade800),
                    ],
                  )),
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
                      child: Icon(Icons.refresh_rounded, size: 17, color: Colors.black.withOpacity(0.65)),
                    ),
                  ),
                ],
              ),
            ),
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
            Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: controller.filters.map((filter) {
                  final isSelected = controller.selectedFilter.value == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => controller.changeFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
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
  void _showSubCategories(
    BuildContext context,
    String parentId,
    CategoriesController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                child: FutureBuilder(
                  future: controller.getSubCategories(parentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final subCategories = snapshot.data as List<Map<String, dynamic>>? ?? [];
                    return SingleChildScrollView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder_open, color: kPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Sub-Categories',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kText,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${subCategories.length} items',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kSubText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (subCategories.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 48,
                                    color: kSubText.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No sub-categories yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kSubText,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showAddCategoryDialog(context, controller, parentId);
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Sub-Category'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...subCategories.map((cat) => _subCategoryTile(
                              cat,
                              controller,
                              context,
                            )),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddCategoryDialog(context, controller, parentId);
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Sub-Category'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subCategoryTile(
    Map<String, dynamic> cat,
    CategoriesController controller,
    BuildContext context,
  ) {
    final color = controller.getCategoryColor(cat['level'] ?? 1);
    final productCount = cat['productCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.subdirectory_arrow_right,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          cat['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${cat['subCategoryCount'] ?? 0} sub-categories • $productCount products',
          style: TextStyle(fontSize: 11, color: kSubText),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 20,
        ),
        onTap: () {
          Navigator.pop(context);
          _showSubCategories(context, cat['id'], controller);
        },
      ),
    );
  }

  // ─── CATEGORY DETAILS ──────────────────────────────────────────

  void _showCategoryDetails(
    BuildContext context,
    Map<String, dynamic> cat,
    CategoriesController controller,
    int index,
  ) {
    final color = controller.getCategoryColor(cat['level'] ?? 1);
    final productCount = cat['productCount'] ?? 0;
    final subCount = cat['subCategoryCount'] ?? 0;
    final createdAt = cat['createdAt'] != null
        ? DateTime.tryParse(cat['createdAt'])
        : null;

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
                              cat['parentId'] == null ? Icons.folder : Icons.subdirectory_arrow_right,
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
                                Text(
                                  cat['parentId'] == null ? 'Main Category' : 'Sub-Category',
                                  style: TextStyle(fontSize: 12, color: kSubText),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      _detailRow('Level', 'Level ${cat['level'] ?? 1}'),
                      _detailRow('Sub-Categories', '$subCount'),
                      _detailRow('Products', '$productCount items'),
                      if (cat['parentName'] != null)
                        _detailRow('Parent', cat['parentName'] ?? ''),
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
                                _showAddCategoryDialog(context, controller, cat['id']);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Add Sub',
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
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditCategoryDialog(context, cat, controller);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
                      if (subCount > 0) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSubCategories(context, cat['id'], controller);
                          },
                          icon: Icon(Icons.folder_open, size: 18, color: kPrimary),
                          label: Text(
                            'View ${subCount} Sub-Categories',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            side: BorderSide(color: kPrimary.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  // ─── ADD CATEGORY DIALOG (with Parent selection) ─────────────

  void _showAddCategoryDialog(
    BuildContext context,
    CategoriesController controller,
    String? parentId,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isSubCategory = parentId != null;

    // Find parent name if parentId is provided
    String parentName = '';
    if (parentId != null) {
      final parent = controller.categories.firstWhere(
        (c) => c['id'] == parentId,
        orElse: () => {},
      );
      parentName = parent['name'] ?? '';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSubCategory ? Icons.subdirectory_arrow_right : Icons.category,
                  color: kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isSubCategory ? 'Add Sub-Category' : 'Add New Category',
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
                if (isSubCategory) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder, size: 16, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Parent: $parentName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Category Name *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: isSubCategory ? 'e.g., Smartphones' : 'e.g., Electronics',
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
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Description (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter category description...',
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: kSubText),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        };
                        if (parentId != null) {
                          data['parentId'] = parentId;
                        }
                        final ok = await controller.createCategory(data);
                        if (ok) {
                          Navigator.pop(context);
                          Get.snackbar(
                            'Success',
                            isSubCategory ? 'Sub-category created successfully' : 'Category created successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kSuccess,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to create category',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kDanger,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        isSubCategory ? 'Add Sub-Category' : 'Save Category',
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

  // ─── EDIT CATEGORY DIALOG ────────────────────────────────────

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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                const SizedBox(height: 8),
                Text(
                  'Category Name *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g., Electronics',
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
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Description (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter category description...',
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: kSubText),
              ),
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
                          Get.snackbar(
                            'Success',
                            'Category updated successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kSuccess,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to update category',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kDanger,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
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
      ),
    );
  }

  // ─── DELETE DIALOG ────────────────────────────────────────────

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              style: TextStyle(
                fontSize: 14,
                color: kText,
              ),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: kDanger,
                        ),
                      ),
                    if (productCount > 0)
                      Text(
                        '• $productCount product(s) will be affected',
                        style: TextStyle(
                          fontSize: 13,
                          color: kDanger,
                        ),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: kSubText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await controller.deleteCategory(cat['id'] ?? '');
              if (ok) {
                Get.snackbar(
                  'Deleted',
                  'Category deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: kSuccess,
                  colorText: Colors.black,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to delete category',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: kDanger,
                  colorText: Colors.black,
                  margin: const EdgeInsets.all(16),
                );
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
        v.isEmpty ? widget.controller.clearSearch() : widget.controller.searchCategories(v);
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
// CATEGORY LIST VIEW
// ═══════════════════════════════════════════════════════════════

class _CategoryListView extends StatelessWidget {
  final CategoriesController controller;
  final void Function(Map<String, dynamic>, int) onCategoryTap;
  final VoidCallback onAddCategory;
  final void Function(String) onSubCategoryTap;

  const _CategoryListView({
    required this.controller,
    required this.onCategoryTap,
    required this.onAddCategory,
    required this.onSubCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.filteredCategories;

      if (categories.isEmpty && !controller.isLoading.value) {
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
                child: Icon(
                  Icons.category_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No categories yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to add your first category',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAddCategory,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Add Category',
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
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final color = controller.getCategoryColor(cat['level'] ?? 1);
          final productCount = cat['productCount'] ?? 0;
          final subCount = cat['subCategoryCount'] ?? 0;
          final isRoot = cat['parentId'] == null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onCategoryTap(cat, index),
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
                        child: Icon(
                          isRoot ? Icons.folder : Icons.subdirectory_arrow_right,
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
                                if (!isRoot)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Sub',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (cat['description'] != null && cat['description'] != '')
                                  Expanded(
                                    child: Text(
                                      cat['description'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSubText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else
                                  Text(
                                    'No description',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: kSubText.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (subCount > 0)
                                  GestureDetector(
                                    onTap: () => onSubCategoryTap(cat['id']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.folder_open,
                                            size: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$subCount sub',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$productCount items',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}