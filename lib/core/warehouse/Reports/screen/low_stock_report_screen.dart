// lib/core/warehouse/reports/screen/low_stock_report_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/warehouse/Reports/controller/low_stock_report_controller.dart';
import 'package:LedgerPro_app/core/warehouse/products/model/product_model.dart';
import 'package:LedgerPro_app/core/warehouse/widgets/drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LowStockReportScreen extends StatelessWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LowStockReportController());
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      drawer: (isMobile || isTablet) ? const WarehouseDrawer() : null,
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Low Stock Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        leading: (isMobile || isTablet)
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Get.back(),
              ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.black,
            ),
            onPressed: () => controller.exportToPdf(),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 40,
            ),
          );
        }
        return _buildContent(context, controller);
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LowStockReportController controller,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(controller, isMobile),

          const SizedBox(height: 16),

          _buildKpiCards(controller, isMobile),

          const SizedBox(height: 16),

          // Low Stock List
          _buildLowStockList(controller, isMobile, isWeb),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────

  Widget _buildHeader(LowStockReportController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2F), Color(0xFF3A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Report',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Generated on ${controller.getCurrentDate()}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38),
            ),
            child: Column(
              children: [
                Text(
                  '${controller.totalLowStock.value}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Low Items',
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Cards ───────────────────────────────────────────────────

  Widget _buildKpiCards(LowStockReportController controller, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            'Critical',
            controller.criticalCount.value.toString(),
            Icons.cancel_outlined,
            Colors.red,
            'Out of stock',
            isMobile,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            'Low Stock',
            controller.lowCount.value.toString(),
            Icons.warning_amber_rounded,
            Colors.orange,
            'Below minimum',
            isMobile,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            'Total Products',
            controller.totalProducts.value.toString(),
            Icons.inventory_2_outlined,
            Colors.blue,
            'All products',
            isMobile,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String sub,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: isMobile ? 16 : 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: isMobile ? 8 : 9,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Low Stock List ─────────────────────────────────────────────

  Widget _buildLowStockList(
    LowStockReportController controller,
    bool isMobile,
    bool isWeb,
  ) {
    final products = controller.lowStockProducts;

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No Low Stock Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All products are above minimum stock levels',
              style: TextStyle(fontSize: 13, color: kSubText),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Products Needing Attention (${products.length})',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        isMobile
            ? Column(
                children: products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildProductCard(product, isMobile),
                  );
                }).toList(),
              )
            : GridView.count(
                shrinkWrap: true,
                crossAxisCount: isWeb ? 2 : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: products.map((product) {
                  return _buildProductCard(product, isMobile);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product, bool isMobile) {
    final needed = product.minimumStock - product.currentStock;
    final isOutOfStock = product.currentStock <= 0;
    final statusColor = isOutOfStock ? Colors.red : Colors.orange;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOutOfStock
              ? Colors.red.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 44,
            height: isMobile ? 40 : 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${product.currentStock}',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'SKU: ${product.sku}',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: kSubText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Min: ${product.minimumStock}',
                        style: TextStyle(
                          fontSize: isMobile ? 9 : 10,
                          color: kSubText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOutOfStock ? 'Out of Stock' : 'Need $needed',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: isMobile ? 14 : 16,
                    color: kPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reorder',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
