// lib/core/warehouse/reports/screen/expiry_report_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/controller/expiry_report_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ExpiryReportScreen extends StatelessWidget {
  const ExpiryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpiryReportController());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
                Icons.event_busy_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Expiry Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
            onPressed: () => controller.exportToPdf(),
            tooltip: 'Download PDF',
          ),
        ],
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
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
    ExpiryReportController controller,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Column(
      children: [
        // Header Card
        _buildHeader(controller, isMobile),

        const SizedBox(height: 12),

        // KPI Cards
        _buildKpiCards(controller, isMobile),

        const SizedBox(height: 12),

        // Tab Bar
        _buildTabBar(controller, isMobile, isWeb),
      ],
    );
  }

  // ─── Header ──────────────────────────────────────────────────────

  Widget _buildHeader(ExpiryReportController controller, bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
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
              Icons.event_outlined,
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
                  'Expiry Report',
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
                  '${controller.totalProducts.value}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Products',
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

  Widget _buildKpiCards(ExpiryReportController controller, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: Row(
        children: [
          Expanded(
            child: _kpiCard(
              'Expired',
              controller.expiredCount.value.toString(),
              Icons.cancel_outlined,
              Colors.red,
              'Products expired',
              isMobile,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpiCard(
              'Expiring Soon',
              controller.expiringSoonCount.value.toString(),
              Icons.warning_amber_rounded,
              Colors.orange,
              'Within 30 days',
              isMobile,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpiCard(
              'No Expiry',
              controller.noExpiryCount.value.toString(),
              Icons.check_circle_outline,
              Colors.green,
              'No expiry date',
              isMobile,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: isMobile ? 14 : 16),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: isMobile ? 7 : 8,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────

  Widget _buildTabBar(
    ExpiryReportController controller,
    bool isMobile,
    bool isWeb,
  ) {
    return Expanded(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: kCardBg,
              width: double.infinity,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: kPrimary,
                unselectedLabelColor: kSubText,
                indicatorColor: kPrimary,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 20,
                ),
                labelStyle: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  _buildExpiryTab(
                    icon: Icons.warning_amber_rounded,
                    label: isMobile ? 'Soon' : 'Expiring Soon',
                    count: controller.expiringSoonCount.value,
                    isMobile: isMobile,
                  ),
                  _buildExpiryTab(
                    icon: Icons.cancel_outlined,
                    label: 'Expired',
                    count: controller.expiredCount.value,
                    isMobile: isMobile,
                  ),
                  _buildExpiryTab(
                    icon: Icons.list_alt_outlined,
                    label: 'All',
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildExpiringSoonList(controller, isMobile, isWeb),
                  _buildExpiredList(controller, isMobile, isWeb),
                  _buildAllExpiryList(controller, isMobile, isWeb),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildExpiryTab({
    required IconData icon,
    required String label,
    required bool isMobile,
    int? count,
  }) {
    final text = count != null ? '$label ($count)' : label;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 16),
          SizedBox(width: isMobile ? 4 : 6),
          Text(text),
        ],
      ),
    );
  }

  // ─── Expiring Soon List ─────────────────────────────────────────

  Widget _buildExpiringSoonList(
    ExpiryReportController controller,
    bool isMobile,
    bool isWeb,
  ) {
    final products = controller.expiringSoon;

    if (products.isEmpty) {
      return _buildEmptyState(
        'No products expiring soon',
        Icons.check_circle_outline,
        Colors.green,
      );
    }

    return _buildProductList(products, isMobile, isWeb, isExpiring: true);
  }

  // ─── Expired List ───────────────────────────────────────────────

  Widget _buildExpiredList(
    ExpiryReportController controller,
    bool isMobile,
    bool isWeb,
  ) {
    final products = controller.expired;

    if (products.isEmpty) {
      return _buildEmptyState(
        'No expired products',
        Icons.check_circle_outline,
        Colors.green,
      );
    }

    return _buildProductList(products, isMobile, isWeb, isExpired: true);
  }

  // ─── All Expiry List ────────────────────────────────────────────

  Widget _buildAllExpiryList(
    ExpiryReportController controller,
    bool isMobile,
    bool isWeb,
  ) {
    final products = controller.productsWithExpiry;

    if (products.isEmpty) {
      return _buildEmptyState(
        'No products with expiry dates',
        Icons.event_outlined,
        Colors.blue,
      );
    }

    return _buildProductList(products, isMobile, isWeb);
  }

  // ─── Product List ───────────────────────────────────────────────

  Widget _buildProductList(
    List<ProductModel> products,
    bool isMobile,
    bool isWeb, {
    bool isExpiring = false,
    bool isExpired = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: isMobile
          ? ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildProductCard(
                    products[index],
                    isMobile,
                    isExpiring: isExpiring,
                    isExpired: isExpired,
                  ),
                );
              },
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWeb ? 2 : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.5,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  isMobile,
                  isExpiring: isExpiring,
                  isExpired: isExpired,
                );
              },
            ),
    );
  }

  // ─── Product Card ───────────────────────────────────────────────

  Widget _buildProductCard(
    ProductModel product,
    bool isMobile, {
    bool isExpiring = false,
    bool isExpired = false,
  }) {
    Color statusColor = Colors.green;
    String status = 'Good';

    if (isExpired) {
      statusColor = Colors.red;
      status = 'Expired';
    } else if (isExpiring) {
      statusColor = Colors.orange;
      status = 'Expiring Soon';
    }

    final daysLeft = product.expiryDate != null
        ? product.expiryDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.2)),
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
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    daysLeft > 0 ? '$daysLeft' : '0',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'days',
                    style: TextStyle(
                      fontSize: isMobile ? 7 : 8,
                      color: statusColor,
                    ),
                  ),
                ],
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
                        'Stock: ${product.currentStock}',
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
                  status,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (product.expiryDate != null)
                Text(
                  '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: kSubText,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
