import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/FixedAssets/controllers/fixed_asset_controller.dart';
import 'package:LedgerPro_app/core/FixedAssets/models/fixed_asset_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FixedAssetsScreen extends StatelessWidget {
  const FixedAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FixedAssetController());

    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(context, controller);
    }
    return _buildWebLayout(context, controller);
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(
    BuildContext context,
    FixedAssetController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.assets.isEmpty) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return Column(
          children: [
            _buildMobileFilterBar(controller, context),
            _buildMobileSummaryCards(controller, context),
            Expanded(child: _buildMobileAssetsList(controller, context)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.showAddAssetDialog(),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    FixedAssetController controller,
  ) {
    return AppBar(
      title: const Text(
        'Fixed Assets',
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
          onPressed: () => _showMobileSearch(context, controller),
        ),
        IconButton(
          icon: const Icon(Icons.calculate_outlined, color: Colors.black87),
          onPressed: () => controller.runMonthlyDepreciation(),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black87),
          onPressed: () => controller.exportAssets(),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(
    FixedAssetController controller,
    BuildContext context,
  ) {
    final filters = ['All', 'Active', 'Fully Depreciated', 'Disposed'];
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
                      controller.applyFilter(isSelected ? 'All' : f),
                  backgroundColor: kBg,
                  selectedColor: kPrimary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? kPrimary : kSubText,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCards(
    FixedAssetController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _buildMobileSummaryCard(
                'Total Assets',
                controller.totalAssets.value.toString(),
                kPrimary,
                Icons.inventory_2_outlined,
                isNumber: true,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Total Cost',
                controller.formatAmount(controller.totalCost.value),
                kPrimary,
                Icons.attach_money,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Depreciation',
                controller.formatAmount(controller.totalDepreciation.value),
                kWarning,
                Icons.trending_down,
              ),
              const SizedBox(width: 12),
              _buildMobileSummaryCard(
                'Net Book Value',
                controller.formatAmount(controller.totalNetBookValue.value),
                kSuccess,
                Icons.account_balance_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
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

  Widget _buildMobileAssetsList(
    FixedAssetController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final assets = controller.assets;

      if (controller.isLoading.value && assets.isEmpty) {
        return const SizedBox.shrink();
      }

      if (assets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_outlined,
                size: 64,
                color: kSubText.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No assets found',
                style: TextStyle(fontSize: 16, color: kSubText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.showAddAssetDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Asset',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assets.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMobileAssetCard(assets[index], controller, context),
        ),
      );
    });
  }

  Widget _buildMobileAssetCard(
    FixedAsset asset,
    FixedAssetController controller,
    BuildContext context,
  ) {
    final statusColor = asset.status == 'Active'
        ? kSuccess
        : asset.status == 'Fully Depreciated'
        ? kWarning
        : kDanger;
    final categoryColor = controller.getAssetCategoryColor(asset.category);
    final depreciationPercent = asset.purchaseCost > 0
        ? (asset.accumulatedDepreciation / asset.purchaseCost).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.showAssetDetails(asset),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        controller.getAssetIcon(asset.category),
                        size: 20,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${asset.assetCode} • ${asset.category}',
                            style: TextStyle(fontSize: 11, color: kSubText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              asset.status,
                              style: TextStyle(
                                fontSize: 8,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NBV',
                          style: TextStyle(fontSize: 9, color: kSubText),
                        ),
                        Text(
                          controller.formatAmount(asset.netBookValue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kSuccess,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.formatAmount(asset.purchaseCost),
                          style: TextStyle(fontSize: 10, color: kSubText),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Depreciation progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Depreciation',
                          style: TextStyle(fontSize: 10, color: kSubText),
                        ),
                        Text(
                          '${(depreciationPercent * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: depreciationPercent > 0.9
                                ? kDanger
                                : kSubText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: depreciationPercent,
                        backgroundColor: kBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          depreciationPercent > 0.9
                              ? kDanger
                              : depreciationPercent > 0.7
                              ? kWarning
                              : kSuccess,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.showAssetDetails(asset),
                        icon: Icon(Icons.visibility, size: 14, color: kSubText),
                        label: Text(
                          'Details',
                          style: TextStyle(fontSize: 11, color: kText),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    if (asset.status == 'Active') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              controller.showEditAssetDialog(asset),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              controller.showDisposeAssetDialog(asset),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Dispose',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WEB LAYOUT ====================

  Widget _buildWebLayout(
    BuildContext context,
    FixedAssetController controller,
  ) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildWebTopBar(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.assets.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 32,
                  ),
                );
              }
              return Column(
                children: [
                  _buildWebKpiStrip(controller),
                  _buildWebToolbar(controller, context),
                  Expanded(child: _buildWebAssetsTable(controller, context)),
                  _buildWebPaginationBar(controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTopBar(
    BuildContext context,
    FixedAssetController controller,
  ) {
    return Container(
      height: 56,
      color: kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Fixed Assets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const Expanded(child: SizedBox()),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              controller: controller.searchController,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                hintText: 'Search name, code, category…',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.black45,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Colors.black26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => controller.runMonthlyDepreciation(),
            icon: const Icon(
              Icons.calculate_outlined,
              size: 15,
              color: Colors.black87,
            ),
            label: const Text(
              'Run Depreciation',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.exportAssets(),
            icon: const Icon(
              Icons.download_outlined,
              size: 15,
              color: Colors.black87,
            ),
            label: const Text(
              'Export',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.showAddAssetDialog(),
            icon: const Icon(Icons.add, size: 16, color: Colors.black87),
            label: const Text(
              'Add Asset',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.4),
              elevation: 0,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebKpiStrip(FixedAssetController controller) {
    return Obx(
      () => Container(
        color: kCardBg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Row(
          children: [
            _buildWebKpiTile(
              'Total Assets',
              controller.totalAssets.value.toString(),
              kPrimary,
              Icons.inventory_2_outlined,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Total Cost',
              controller.formatAmount(controller.totalCost.value),
              kPrimary,
              Icons.attach_money,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Acc. Depreciation',
              controller.formatAmount(controller.totalDepreciation.value),
              kWarning,
              Icons.trending_down,
            ),
            _buildWebKpiDivider(),
            _buildWebKpiTile(
              'Net Book Value',
              controller.formatAmount(controller.totalNetBookValue.value),
              kSuccess,
              Icons.account_balance_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiDivider() =>
      Container(width: 1, height: 36, color: Colors.grey.withOpacity(0.15));

  Widget _buildWebToolbar(
    FixedAssetController controller,
    BuildContext context,
  ) {
    final filters = ['All', 'Active', 'Fully Depreciated', 'Disposed'];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Obx(
        () => Row(
          children: filters.map((f) {
            final isSelected = controller.selectedFilter.value == f;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => controller.applyFilter(f),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: kPrimary.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? kPrimary : kSubText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== WEB TABLE ====================

  Widget _buildWebAssetsTable(
    FixedAssetController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final assets = controller.assets;

      if (assets.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_outlined,
                size: 48,
                color: kSubText.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No assets found',
                style: TextStyle(fontSize: 15, color: kSubText),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => controller.showAddAssetDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '+ Add Asset',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Header
          Container(
            height: 36,
            color: kBg,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(flex: 2, child: _tableHeaderCell('Code')),
                Expanded(flex: 3, child: _tableHeaderCell('Asset Name')),
                Expanded(flex: 2, child: _tableHeaderCell('Category')),
                Expanded(flex: 2, child: _tableHeaderCell('Purchase Date')),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Cost', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Acc. Depr.', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('NBV', align: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Depr. %', align: TextAlign.center),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Status', align: TextAlign.center),
                ),
                const SizedBox(width: 68),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: ListView.separated(
              itemCount: assets.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) =>
                  _buildWebTableRow(assets[index], controller, context),
            ),
          ),
          if (assets.isNotEmpty) _buildWebTableFooter(assets, controller),
        ],
      );
    });
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: kSubText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWebTableRow(
    FixedAsset asset,
    FixedAssetController controller,
    BuildContext context,
  ) {
    final statusColor = asset.status == 'Active'
        ? kSuccess
        : asset.status == 'Fully Depreciated'
        ? kWarning
        : kDanger;
    final categoryColor = controller.getAssetCategoryColor(asset.category);
    final depreciationPercent = asset.purchaseCost > 0
        ? (asset.accumulatedDepreciation / asset.purchaseCost * 100).clamp(
            0.0,
            100.0,
          )
        : 0.0;
    final deprColor = depreciationPercent > 90
        ? kDanger
        : depreciationPercent > 70
        ? kWarning
        : kSuccess;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.showAssetDetails(asset),
        hoverColor: kPrimary.withOpacity(0.03),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  controller.getAssetIcon(asset.category),
                  size: 14,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 4),
              // Asset Code
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    asset.assetCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      asset.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Category
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    asset.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: categoryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Purchase Date
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('dd MMM yyyy').format(asset.purchaseDate),
                  style: TextStyle(fontSize: 12, color: kSubText),
                ),
              ),
              // Purchase Cost
              Expanded(
                flex: 2,
                child: Text(
                  controller.formatAmount(asset.purchaseCost),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ),
              // Accumulated Depreciation
              Expanded(
                flex: 2,
                child: Text(
                  controller.formatAmount(asset.accumulatedDepreciation),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kWarning,
                  ),
                ),
              ),
              // Net Book Value
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      controller.formatAmount(asset.netBookValue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kSuccess,
                      ),
                    ),
                  ),
                ),
              ),
              // Depreciation %
              Expanded(
                flex: 2,
                child: Center(
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${depreciationPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: deprColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: depreciationPercent / 100,
                            backgroundColor: kBg,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              deprColor,
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Status
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      asset.status == 'Active'
                          ? 'ACT'
                          : asset.status == 'Fully Depreciated'
                          ? 'FDP'
                          : 'DSP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 68,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _webIconBtn(
                      Icons.remove_red_eye_outlined,
                      kSubText,
                      () => controller.showAssetDetails(asset),
                    ),
                    const SizedBox(width: 4),
                    if (asset.status == 'Active')
                      _webIconBtn(
                        Icons.edit_outlined,
                        kPrimary,
                        () => controller.showEditAssetDialog(asset),
                      )
                    else
                      _webIconBtn(
                        Icons.more_vert,
                        kSubText,
                        () => controller.showAssetDetails(asset),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildWebTableFooter(
    List<FixedAsset> assets,
    FixedAssetController controller,
  ) {
    final activeCount = assets.where((a) => a.status == 'Active').length;
    final fdpCount = assets
        .where((a) => a.status == 'Fully Depreciated')
        .length;
    final dspCount = assets.where((a) => a.status == 'Disposed').length;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'TOTALS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 2,
            child: Text(
              controller.formatAmount(
                assets.fold(0.0, (s, a) => s + a.purchaseCost),
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              controller.formatAmount(
                assets.fold(0.0, (s, a) => s + a.accumulatedDepreciation),
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kWarning,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  controller.formatAmount(
                    assets.fold(0.0, (s, a) => s + a.netBookValue),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: kSuccess,
                  ),
                ),
              ),
            ),
          ),
          // Depr % column spacer
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (activeCount > 0)
                    Text(
                      '$activeCount ACT',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: kSuccess,
                      ),
                    ),
                  if (fdpCount > 0)
                    Text(
                      '$fdpCount FDP',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                        color: kWarning,
                      ),
                    ),
                  if (dspCount > 0)
                    Text(
                      '$dspCount DSP',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                        color: kDanger,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }

  // ==================== WEB PAGINATION BAR ====================

  Widget _buildWebPaginationBar(FixedAssetController controller) {
    return Obx(
      () => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${controller.assets.length} of ${controller.totalAssets.value} assets',
              style: TextStyle(fontSize: 13, color: kSubText),
            ),
            Row(
              children: [
                _paginationBtn(Icons.chevron_left, 'Previous', false, null),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Page 1',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _paginationBtn(Icons.chevron_right, 'Next', false, null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationBtn(
    IconData icon,
    String label,
    bool enabled,
    VoidCallback? onTap,
  ) {
    final color = enabled ? kPrimary : Colors.grey;
    final isNext = label == 'Next';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? kPrimary : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (!isNext) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              if (isNext) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  void _showMobileSearch(
    BuildContext context,
    FixedAssetController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Search Assets',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Name, code, category…',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => controller.searchController.text = v,
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
