// lib/core/warehouse/inventory/screen/inventory_valuation_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/inventory_valuation/controller/inventory_valuation_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/inventory_valuation/model/inventory_valuation_model.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class InventoryValuationScreen extends StatelessWidget {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryValuationController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Inventory Valuation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: kPrimary,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return Column(
          children: [
            _buildSearchAndFilterBar(controller),
            Expanded(child: _buildResponsiveLayout(context, controller)),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndFilterBar(InventoryValuationController controller) {
    return Container(
      color: kCardBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Obx(() {
        final categories = ['all', ...controller.categories];
        final selected = categories.contains(controller.selectedCategory.value)
            ? controller.selectedCategory.value
            : 'all';
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c == 'all' ? 'All Categories' : c,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.filterByCategory(v);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    InventoryValuationController controller,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return _buildMobileLayout(context, controller);
    } else if (screenWidth < 1200) {
      return _buildTabletLayout(context, controller);
    } else {
      return _buildWebLayout(context, controller);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(
    BuildContext context,
    InventoryValuationController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildSummaryCards(controller, isMobile: true),
          const SizedBox(height: 12),
          _buildMobileItemList(controller),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(controller),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TABLET LAYOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabletLayout(
    BuildContext context,
    InventoryValuationController controller,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSummaryCards(controller, isMobile: false),
                const SizedBox(height: 12),
                _buildTabletItemList(controller),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildCategoryBreakdown(controller),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWebLayout(
    BuildContext context,
    InventoryValuationController controller,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSummaryCards(controller, isMobile: false),
                const SizedBox(height: 12),
                Expanded(child: _buildWebTable(controller)),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCategoryBreakdown(controller),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(
    InventoryValuationController controller, {
    required bool isMobile,
  }) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null) return const SizedBox.shrink();

      final cards = [
        _buildSummaryCard(
          'Total Items',
          summary.totalItems.toString(),
          const Color(0xFF3498DB),
          Icons.inventory_2_outlined,
        ),
        _buildSummaryCard(
          'Total Qty',
          summary.totalQty.toString(),
          const Color(0xFF2ECC71),
          Icons.numbers,
        ),
        _buildSummaryCard(
          'Total Value',
          controller.formatCurrency(summary.totalCostValue),
          const Color(0xFFF39C12),
          Icons.attach_money,
        ),
        _buildSummaryCard(
          'Potential Profit',
          controller.formatCurrency(summary.totalPotentialProfit),
          summary.totalPotentialProfit > 0
              ? const Color(0xFF2ECC71)
              : const Color(0xFFE74C3C),
          Icons.trending_up,
        ),
        _buildSummaryCard(
          'Low Stock',
          summary.lowStockCount.toString(),
          const Color(0xFFE74C3C),
          Icons.warning_amber_rounded,
        ),
        _buildSummaryCard(
          'Over Stock',
          summary.overStockCount.toString(),
          const Color(0xFFF39C12),
          Icons.inventory_2_outlined,
        ),
        _buildSummaryCard(
          'Avg Profit Margin',
          '${summary.avgProfitMargin.toStringAsFixed(1)}%',
          const Color(0xFF9B59B6),
          Icons.percent,
        ),
        _buildSummaryCard(
          'Selling Value',
          controller.formatCurrency(summary.totalSellingValue),
          const Color(0xFF1ABC9C),
          Icons.sell,
        ),
      ];

      if (isMobile) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (MediaQuery.of(Get.context!).size.width - 40) / 2,
                  child: card,
                ),
              )
              .toList(),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cards
            .map((card) => SizedBox(width: 140, child: card))
            .toList(),
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MOBILE ITEM LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileItemList(InventoryValuationController controller) {
    return Obx(() {
      if (controller.items.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.items.length,
        itemBuilder: (context, index) {
          final item = controller.items[index];
          return _buildMobileItemCard(item, controller);
        },
      );
    });
  }

  Widget _buildMobileItemCard(
    InventoryValuationModel item,
    InventoryValuationController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: kPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.sku} • ${item.category}',
                      style: TextStyle(fontSize: 10, color: kSubText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.getStatusColor().withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.getStatusIcon(),
                      size: 10,
                      color: item.getStatusColor(),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.getStatusLabel(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: item.getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMobileInfo('Qty', item.qty.toString()),
              _buildMobileInfo(
                'Unit Cost',
                controller.formatCurrency(item.unitCost),
              ),
              _buildMobileInfo(
                'Total',
                controller.formatCurrency(item.totalCostValue),
              ),
              _buildMobileInfo(
                'Profit',
                '${item.profitMargin.toStringAsFixed(1)}%',
                color: controller.getProfitColor(item.profitMargin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfo(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? kText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TABLET ITEM LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabletItemList(InventoryValuationController controller) {
    return Obx(() {
      if (controller.items.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: _headerText('Product')),
                  Expanded(flex: 1, child: _headerText('SKU')),
                  Expanded(flex: 1, child: _headerText('Qty')),
                  Expanded(flex: 1, child: _headerText('Unit Cost')),
                  Expanded(flex: 1, child: _headerText('Total')),
                  Expanded(
                    flex: 1,
                    child: _headerText('Status', align: TextAlign.center),
                  ),
                ],
              ),
            ),
            // Body
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.sku,
                            style: TextStyle(fontSize: 10, color: kSubText),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.qty.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.formatCurrency(item.unitCost),
                            style: TextStyle(fontSize: 10, color: kSubText),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.formatCurrency(item.totalCostValue),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.getStatusColor().withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.getStatusLabel(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: item.getStatusColor(),
                                ),
                              ),
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
      );
    });
  }

  Widget _headerText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: kSubText,
        letterSpacing: 0.3,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEB TABLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWebTable(InventoryValuationController controller) {
    return Obx(() {
      if (controller.items.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  _buildSortableHeader('Product', 'name', controller, flex: 2),
                  _buildSortableHeader('SKU', 'sku', controller, flex: 1),
                  _buildSortableHeader('Qty', 'qty', controller, flex: 1),
                  _buildSortableHeader(
                    'Unit Cost',
                    'unitCost',
                    controller,
                    flex: 1,
                  ),
                  _buildSortableHeader(
                    'Total Value',
                    'totalCostValue',
                    controller,
                    flex: 1,
                  ),
                  _buildSortableHeader(
                    'Profit %',
                    'profitMargin',
                    controller,
                    flex: 1,
                  ),
                  Expanded(
                    flex: 1,
                    child: _headerText('Status', align: TextAlign.center),
                  ),
                  Expanded(
                    flex: 1,
                    child: _headerText(
                      'Selling Price',
                      align: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: kText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.sku,
                            style: TextStyle(fontSize: 10, color: kSubText),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.qty.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.formatCurrency(item.unitCost),
                            style: TextStyle(fontSize: 10, color: kSubText),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.formatCurrency(item.totalCostValue),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item.profitMargin.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: controller.getProfitColor(
                                item.profitMargin,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.getStatusColor().withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.getStatusIcon(),
                                    size: 10,
                                    color: item.getStatusColor(),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.getStatusLabel(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: item.getStatusColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            controller.formatCurrency(item.sellingPrice),
                            style: TextStyle(fontSize: 10, color: kSubText),
                            textAlign: TextAlign.center,
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
      );
    });
  }

  Widget _buildSortableHeader(
    String label,
    String field,
    InventoryValuationController controller, {
    int flex = 1,
  }) {
    final isActive = controller.sortBy.value == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => controller.sortByField(field),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? kPrimary : kSubText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              controller.getSortIcon(field),
              style: TextStyle(
                fontSize: 9,
                color: isActive ? kPrimary : kSubText.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCategoryBreakdown(InventoryValuationController controller) {
    return Obx(() {
      if (controller.categoryBreakdown.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: kPrimary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.categoryBreakdown.map(
              (cat) => _buildCategoryItem(cat, controller),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryItem(
    CategoryBreakdown cat,
    InventoryValuationController controller,
  ) {
    final maxValue = 659560.0; // You can calculate this dynamically
    final percentage = maxValue > 0
        ? (cat.value / maxValue * 100).clamp(0, 100)
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kText,
                ),
              ),
              Text(
                '${cat.items} items',
                style: TextStyle(fontSize: 9, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.08),
                    color: kPrimary,
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                controller.formatCurrency(cat.value),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: kSubText.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: TextStyle(fontSize: 14, color: kSubText),
            ),
          ],
        ),
      ),
    );
  }
}
