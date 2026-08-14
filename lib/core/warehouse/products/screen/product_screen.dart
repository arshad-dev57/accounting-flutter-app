// core/warehouse/products/screen/products_screen.dart

import 'dart:io';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/category/category_screen.dart';
import 'package:BisonsTechs_app/core/tax/tax_rate_field.dart';
import 'package:BisonsTechs_app/core/warehouse/products/controller/product_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/screen/product_qr_scan_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/supplier/screen/supplier_screen.dart';
import 'package:BisonsTechs_app/core/warehousesettings/warehouse_settings_screen.dart';
import 'package:country_picker_pro/country_picker_pro.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _ProductTab {
  final String label;
  final IconData icon;
  const _ProductTab(this.label, this.icon);
}

const _productTabs = [
  _ProductTab('Basic Info', Icons.info_outline),
  _ProductTab('Pricing & Stock', Icons.attach_money),
  _ProductTab('Category', Icons.category_outlined),
  _ProductTab('Warehouse', Icons.warehouse_outlined),
  _ProductTab('Physical', Icons.straighten),
  _ProductTab('Expiry & Batch', Icons.calendar_month_outlined),
  _ProductTab('Shipping', Icons.local_shipping_outlined),
  _ProductTab('Media', Icons.image_outlined),
  _ProductTab('Custom', Icons.tune_outlined),
];

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsController controller;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : Get.put(ProductsController());

    // Initialize QR controller if not registered
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(ProductsController());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openProductPage(
    BuildContext context,
    ProductsController controller, {
    Map<String, dynamic>? product,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _AddProductPage(controller: controller, editingProduct: product),
      ),
    );
  }

  Future<void> _scanBarcodeForSearch() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const ProductQRScanScreen(),
    );

    if (result != null && result.isNotEmpty) {
      final scannedBarcode =
          result['text']?.toString() ??
          result['id']?.toString() ??
          result['url']?.toString() ??
          result['barcode']?.toString() ??
          result['code']?.toString() ??
          result['rawValue']?.toString();

      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        // Search for product by barcode
        final existingProduct = await controller.checkBarcodeExists(
          scannedBarcode,
        );

        if (existingProduct != null) {
          // Show product name in search bar instead of barcode
          final productName =
              existingProduct['name'] ??
              existingProduct['sku'] ??
              scannedBarcode;
          _searchCtrl.text = productName;
          controller.searchProducts(
            scannedBarcode,
          ); // Still search by barcode to get exact match
          setState(() {});

          Get.snackbar(
            'Product Found',
            'Found: ${existingProduct['name']}',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.black,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          // Product not found, show barcode in search
          _searchCtrl.text = scannedBarcode;
          controller.searchProducts(scannedBarcode);
          setState(() {});

          Get.snackbar(
            'Product Not Found',
            'No product found with barcode: $scannedBarcode',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.black,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _MobileProductsList(
                  controller: controller,
                  onProductTap: (p) =>
                      _showProductDetails(context, p, controller),
                  onAddProduct: () => _openProductPage(context, controller),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductPage(context, controller),
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTopHeader() {
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalProducts.value} items in inventory',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
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
                          'Stock',
                          controller.inStockCount.value.toString(),
                          Colors.white,
                        ),
                        const SizedBox(width: 10),
                        _compactKpi(
                          'Low',
                          controller.lowStockCount.value.toString(),
                          Colors.orange.shade200,
                        ),
                        const SizedBox(width: 10),
                        _compactKpi(
                          'Out',
                          controller.outOfStockCount.value.toString(),
                          Colors.red.shade200,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshProducts,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: Colors.white.withOpacity(0.9),
                      ),
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
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() {});
                    v.isEmpty
                        ? controller.clearSearch()
                        : controller.searchProducts(v);
                  },
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search by name or SKU...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              controller.clearSearch();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        GestureDetector(
                          onTap: _scanBarcodeForSearch,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.qr_code_scanner,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: controller.filters.map((filter) {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => controller.filterProducts(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? kPrimary : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Product Details Bottom Sheet ─────────────────────────
  List<String> _productImages(Map<String, dynamic> product) {
    final imgs = product['images'];
    if (imgs is List && imgs.isNotEmpty) {
      return imgs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final main = product['mainImage']?.toString();
    if (main != null && main.isNotEmpty) return [main];
    return [];
  }

  String? _productMainImage(Map<String, dynamic> product) {
    final images = _productImages(product);
    return images.isEmpty ? null : images.first;
  }

  Widget _productAvatar(Map<String, dynamic> product, {double size = 48, Color? fallbackColor}) {
    final url = _productMainImage(product);
    final color = fallbackColor ?? kPrimary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size > 50 ? 14 : 12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.inventory_2, color: color, size: size * 0.5)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: color, size: size * 0.5),
            ),
    );
  }

  void _showProductDetails(
    BuildContext context,
    Map<String, dynamic> product,
    ProductsController controller,
  ) {
    final stock = product['currentStock'] ?? 0;
    final stockColor = controller.getStockColor(stock);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.93,
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
                          _productAvatar(product, size: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product['sku'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimary,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${product['categoryName'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kSubText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_productImages(product).isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _productImages(product).length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final url = _productImages(product)[i];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 88,
                                    height: 88,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _miniKpi(
                            'Selling Price',
                            controller.formatCurrency(
                              (product['sellingPrice'] ?? 0.0).toDouble(),
                            ),
                            kText,
                            Icons.attach_money,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Cost Price',
                            controller.formatCurrency(
                              (product['costPrice'] ?? 0.0).toDouble(),
                            ),
                            kSubText,
                            Icons.money_off_outlined,
                          ),
                          const SizedBox(width: 8),
                          _miniKpi(
                            'Stock',
                            stock.toString(),
                            stockColor,
                            Icons.inventory_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      _detailRow(
                        'Brand',
                        product['brandName'] ?? product['brand'] ?? '-',
                      ),
                      _detailRow('Model No.', product['modelNumber'] ?? '-'),
                      _detailRow('Type', product['productType'] ?? '-'),
                      _detailRow('Supplier', product['supplierName'] ?? '-'),
                      _detailRow(
                        'Status',
                        controller.getStockStatus(stock),
                        badgeColor: stockColor,
                      ),
                      _detailRow(
                        'Min Stock',
                        (product['minimumStock'] ?? '-').toString(),
                      ),
                      _detailRow(
                        'Max Stock',
                        (product['maximumStock'] ?? '-').toString(),
                      ),
                      _detailRow(
                        'Rack',
                        product['rackLocationName'] ??
                            product['location'] ??
                            '-',
                      ),
                      _detailRow('Tax Rate', '${product['taxRate'] ?? 0}%'),
                      if ((product['barcodeNumber'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barcode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: SvgPicture.string(
                                  Barcode.code128().toSvg(
                                    product['barcodeNumber'].toString(),
                                    width: 300,
                                    height: 80,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      if ((product['description'] ?? '').toString().isNotEmpty)
                        _detailRow('Description', product['description']),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _openProductPage(
                                  context,
                                  controller,
                                  product: product,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
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
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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

  Widget _miniKpi(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: kSubText)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? badgeColor}) {
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
            child: badgeColor != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  )
                : Text(
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
}

// ═══════════════════════════════════════════════════════════════
// ADD / EDIT PRODUCT PAGE — 9 TABS
// ═══════════════════════════════════════════════════════════════
class _AddProductPage extends StatefulWidget {
  final ProductsController controller;
  final Map<String, dynamic>? editingProduct;
  const _AddProductPage({required this.controller, this.editingProduct});

  @override
  State<_AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<_AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  int _activeTab = 0;
  bool _saving = false;

  bool get _isEditing => widget.editingProduct != null;
  ProductsController get _c => widget.controller;

  // ── Snapshot lists ──
  late List<Map<String, dynamic>> _productTypes;
  late List<Map<String, dynamic>> _stockUnits;
  late List<Map<String, dynamic>> _categories;
  late List<Map<String, dynamic>> _suppliers;
  late List<Map<String, dynamic>> _rackLocations;
  late List<Map<String, dynamic>> _zones;
  late List<Map<String, dynamic>> _storageConditions;
  late List<Map<String, dynamic>> _weightUnits;
  late List<Map<String, dynamic>> _dimensionUnits;
  late List<Map<String, dynamic>> _sizes;
  late List<Map<String, dynamic>> _shippingClasses;

  // ── Form controllers ──
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _landingCostCtrl;
  late final TextEditingController _taxRateCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _maxStockCtrl;
  late final TextEditingController _reorderPointCtrl;
  late final TextEditingController _leadTimeCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _supplierSkuCtrl;
  late final TextEditingController _palletCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _tempMinCtrl;
  late final TextEditingController _tempMaxCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _materialCtrl;
  late final TextEditingController _finishCtrl;
  late final TextEditingController _batchNumberCtrl;
  late final TextEditingController _shelfLifeCtrl;
  late final TextEditingController _defaultBatchQtyCtrl;
  late final TextEditingController _hsCodeCtrl;
  late final TextEditingController _stackingLimitCtrl;
  late final TextEditingController _unNumberCtrl;
  late final TextEditingController _handlingCtrl;
  late final TextEditingController _warrantyPeriodCtrl;
  late final TextEditingController _returnDaysCtrl;
  late final TextEditingController _freightClassCtrl;
  late final TextEditingController _notesCtrl;

  // ── Dropdowns ──
  String? _selectedProductType;
  String? _selectedStockUnit;
  String? _selectedTaxType;
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSupplierId;
  String? _selectedRackLocation;
  String? _selectedZone;
  String? _selectedStorageCondition;
  String? _selectedWeightUnit;
  String? _selectedDimensionUnit;
  String? _selectedSize;
  String? _selectedShippingClass;
  // These are FORM-LOCAL — changes here never write to CurrencyController or SharedPreferences
  String _currency = 'PKR';
  String _currencyName = 'Pakistani Rupee';
  String _currencySymbol = 'Rs';
  String _countryOfOrigin = 'Pakistan';
  String _countryFlagEmoji = '🇵🇰';
  String _warrantyUnit = 'Months';
  String _bulkUnit = 'Bale';

  List<Map<String, dynamic>> _subCategories = [];
  String? _categoryError;

  // ── Booleans ──
  bool _hasExpiry = false;
  bool _isBatchManaged = false;
  bool _isSerialManaged = false;
  bool _isExpiryManaged = false;
  bool _isBulkManaged = false;
  bool _hasIndividualTracking = false;
  bool _dangerousGoods = false;
  bool _isReturnable = true;

  // ── Dates ──
  DateTime? _expiryDate;
  DateTime? _manufacturingDate;

  // ── Barcode Data ──
  String? _generatedBarcodeData;
  String? _selectedBarcodeFormat = 'Code-128';

  // ── Media / Cloudinary images ──
  final List<String> _existingImages = [];
  final List<String> _newImagePaths = [];

  @override
  void initState() {
    super.initState();

    _productTypes = List<Map<String, dynamic>>.from(_c.productTypes);
    _stockUnits = List<Map<String, dynamic>>.from(_c.stockUnits);
    _categories = List<Map<String, dynamic>>.from(_c.categories);
    _suppliers = List<Map<String, dynamic>>.from(_c.suppliers);
    _rackLocations = List<Map<String, dynamic>>.from(_c.rackLocations);
    _zones = List<Map<String, dynamic>>.from(_c.zones);
    _storageConditions = List<Map<String, dynamic>>.from(_c.storageConditions);
    _weightUnits = List<Map<String, dynamic>>.from(_c.weightUnits);
    _dimensionUnits = List<Map<String, dynamic>>.from(_c.dimensionUnits);
    _sizes = List<Map<String, dynamic>>.from(_c.sizes);
    _shippingClasses = List<Map<String, dynamic>>.from(_c.shippingClasses);

    final p = widget.editingProduct;

    // Helper function to safely convert any value to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      if (value is List) return value.join(', ');
      return value.toString();
    }

    // Load existing Cloudinary images when editing
    final imgs = p?['images'];
    if (imgs is List) {
      _existingImages.addAll(imgs.map((e) => e.toString()).where((e) => e.isNotEmpty));
    } else if (p?['mainImage'] != null && p!['mainImage'].toString().isNotEmpty) {
      _existingImages.add(p['mainImage'].toString());
    }

    _nameCtrl = TextEditingController(text: safeToString(p?['name']));
    _skuCtrl = TextEditingController(
      text: safeToString(p?['sku'] ?? _c.generateSku()),
    );
    _barcodeCtrl = TextEditingController(
      text: safeToString(p?['barcodeNumber']),
    );
    _descCtrl = TextEditingController(text: safeToString(p?['description']));
    _tagsCtrl = TextEditingController(text: safeToString(p?['tags']));
    _selectedProductType = p?['productType'];

    _costCtrl = TextEditingController(text: safeToString(p?['costPrice']));
    _sellCtrl = TextEditingController(text: safeToString(p?['sellingPrice']));
    _landingCostCtrl = TextEditingController(
      text: safeToString(p?['landingCost']),
    );
    _taxRateCtrl = TextEditingController(
      text: safeToString(p?['taxRate'] ?? '0'),
    );
    _stockCtrl = TextEditingController(text: safeToString(p?['currentStock']));
    _minStockCtrl = TextEditingController(
      text: safeToString(p?['minimumStock'] ?? '5'),
    );
    _maxStockCtrl = TextEditingController(
      text: safeToString(p?['maximumStock'] ?? '100'),
    );
    _reorderPointCtrl = TextEditingController(
      text: safeToString(p?['reorderPoint']),
    );
    _leadTimeCtrl = TextEditingController(
      text: safeToString(p?['leadTimeDays']),
    );
    _selectedStockUnit = p?['stockUnitName'];
    _selectedTaxType = p?['taxType'];

    _selectedCategoryId = p?['categoryId'];
    _selectedSupplierId = p?['supplierId'];
    _brandCtrl = TextEditingController(
      text: safeToString(p?['brandName'] ?? p?['brand']),
    );
    _modelCtrl = TextEditingController(text: safeToString(p?['modelNumber']));
    _supplierSkuCtrl = TextEditingController(
      text: safeToString(p?['supplierSku']),
    );
    if (_selectedCategoryId != null) {
      _subCategories = _c.getSubCategories(_selectedCategoryId);
    }

    _selectedRackLocation = p?['rackLocationName'] ?? p?['location'];
    _selectedZone = p?['zoneName'];
    _selectedStorageCondition = p?['storageConditionName'];
    _palletCtrl = TextEditingController(text: safeToString(p?['palletNumber']));
    _shelfCtrl = TextEditingController(text: safeToString(p?['shelfNumber']));
    _tempMinCtrl = TextEditingController(
      text: safeToString(p?['temperatureMin']),
    );
    _tempMaxCtrl = TextEditingController(
      text: safeToString(p?['temperatureMax']),
    );

    _weightCtrl = TextEditingController(text: safeToString(p?['weight']));
    _lengthCtrl = TextEditingController(text: safeToString(p?['length']));
    _widthCtrl = TextEditingController(text: safeToString(p?['width']));
    _heightCtrl = TextEditingController(text: safeToString(p?['height']));
    _colorCtrl = TextEditingController(text: safeToString(p?['color']));
    _materialCtrl = TextEditingController(text: safeToString(p?['material']));
    _finishCtrl = TextEditingController(text: safeToString(p?['finish']));
    _selectedWeightUnit = p?['weightUnitName'];
    _selectedDimensionUnit = p?['dimensionUnit'];
    _selectedSize = p?['size'];

    _hasExpiry = p?['hasExpiry'] ?? false;
    _isBatchManaged = p?['isBatchManaged'] ?? false;
    _isSerialManaged = p?['isSerialManaged'] ?? false;
    _isExpiryManaged = p?['isExpiryManaged'] ?? false;
    _isBulkManaged = p?['isBulkManaged'] ?? false;
    _hasIndividualTracking = p?['hasIndividualTracking'] ?? false;
    _bulkUnit = p?['bulkUnit'] ?? 'Bale';
    _batchNumberCtrl = TextEditingController(
      text: safeToString(p?['batchNumber']),
    );
    _shelfLifeCtrl = TextEditingController(
      text: safeToString(p?['shelfLifeDays']),
    );
    _defaultBatchQtyCtrl = TextEditingController(
      text: safeToString(p?['defaultQuantityPerBatch']),
    );
    if (p?['expiryDate'] != null)
      _expiryDate = DateTime.tryParse(p!['expiryDate']);
    if (p?['manufacturingDate'] != null)
      _manufacturingDate = DateTime.tryParse(p!['manufacturingDate']);

    _hsCodeCtrl = TextEditingController(text: safeToString(p?['hsCode']));
    _stackingLimitCtrl = TextEditingController(
      text: safeToString(p?['stackingLimit']),
    );
    _unNumberCtrl = TextEditingController(text: safeToString(p?['unNumber']));
    _handlingCtrl = TextEditingController(
      text: safeToString(p?['handlingInstructions']),
    );
    _warrantyPeriodCtrl = TextEditingController(
      text: safeToString(p?['warrantyPeriod']),
    );
    _returnDaysCtrl = TextEditingController(
      text: safeToString(p?['returnDays'] ?? '7'),
    );
    _freightClassCtrl = TextEditingController(
      text: safeToString(p?['freightClass']),
    );
    _selectedShippingClass = p?['shippingClass'];
    _dangerousGoods = p?['dangerousGoods'] ?? false;
    _isReturnable = p?['isReturnable'] ?? true;
    _warrantyUnit = p?['warrantyUnit'] ?? 'Months';
    _countryOfOrigin = p?['countryOfOriginName'] ?? 'Pakistan';
    _countryFlagEmoji = p?['countryOfOriginFlag']?.toString() ?? '🇵🇰';
    // For editing: use the product's saved currency.
    // For creating: read the app's current global currency as default (read-only — never writes back).
    final globalCurrency = Get.find<CurrencyController>();
    _currency = p?['currencyCode'] ?? globalCurrency.currencyCode.value;
    _applyCurrencyFromCode(_currency);
    // Override symbol/name from the product record if present (takes priority over CurrencyService lookup)
    if (p?['currencySymbol'] != null &&
        p!['currencySymbol'].toString().isNotEmpty) {
      _currencySymbol = p['currencySymbol'].toString();
    } else if (p == null) {
      // New product: also pull symbol from global currency for correct display
      _currencySymbol = globalCurrency.currencySymbol.value;
    }
    if (p?['currencyName'] != null && p!['currencyName'].toString().isNotEmpty) {
      _currencyName = p['currencyName'].toString();
    }
    _notesCtrl = TextEditingController(text: safeToString(p?['notes']));

    // Load barcode if exists
    if (p?['barcodeNumber'] != null) {
      _generatedBarcodeData = safeToString(p?['barcodeNumber']);
    }

    // Load barcode format if exists
    if (p?['barcodeFormat'] != null) {
      _selectedBarcodeFormat = safeToString(p?['barcodeFormat']);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _skuCtrl,
      _barcodeCtrl,
      _descCtrl,
      _tagsCtrl,
      _costCtrl,
      _sellCtrl,
      _landingCostCtrl,
      _taxRateCtrl,
      _stockCtrl,
      _minStockCtrl,
      _maxStockCtrl,
      _reorderPointCtrl,
      _leadTimeCtrl,
      _brandCtrl,
      _modelCtrl,
      _supplierSkuCtrl,
      _palletCtrl,
      _shelfCtrl,
      _tempMinCtrl,
      _tempMaxCtrl,
      _weightCtrl,
      _lengthCtrl,
      _widthCtrl,
      _heightCtrl,
      _colorCtrl,
      _materialCtrl,
      _finishCtrl,
      _batchNumberCtrl,
      _shelfLifeCtrl,
      _defaultBatchQtyCtrl,
      _hsCodeCtrl,
      _stackingLimitCtrl,
      _unNumberCtrl,
      _handlingCtrl,
      _warrantyPeriodCtrl,
      _returnDaysCtrl,
      _freightClassCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Refresh dropdown data after settings update ──
  Future<void> _refreshDropdownData() async {
    // Fetch fresh data from API using public method
    await _c.refreshDropdownData();

    // Update local lists with fresh data
    setState(() {
      _productTypes = List<Map<String, dynamic>>.from(_c.productTypes);
      _stockUnits = List<Map<String, dynamic>>.from(_c.stockUnits);
      _categories = List<Map<String, dynamic>>.from(_c.categories);
      _suppliers = List<Map<String, dynamic>>.from(_c.suppliers);
      _rackLocations = List<Map<String, dynamic>>.from(_c.rackLocations);
      _zones = List<Map<String, dynamic>>.from(_c.zones);
      _storageConditions = List<Map<String, dynamic>>.from(
        _c.storageConditions,
      );
      _weightUnits = List<Map<String, dynamic>>.from(_c.weightUnits);
      _dimensionUnits = List<Map<String, dynamic>>.from(_c.dimensionUnits);
      _sizes = List<Map<String, dynamic>>.from(_c.sizes);
      _shippingClasses = List<Map<String, dynamic>>.from(_c.shippingClasses);

      // Refresh sub-categories if a category is selected
      if (_selectedCategoryId != null) {
        _subCategories = _c.getSubCategories(_selectedCategoryId);
      }
    });
  }

  // ══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════

  InputDecoration _dec({
    String hint = '',
    IconData? icon,
    String? prefix,
    String? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
    prefixText: prefix,
    prefixIcon: icon != null ? Icon(icon, size: 16, color: kSubText) : null,
    suffixText: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kDanger, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kDanger, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
    filled: true,
    fillColor: kCardBg,
  );

  Widget _label(String text, {bool req = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kSubText,
          ),
        ),
        if (req)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 12,
              color: kDanger,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );

  Widget _field({
    required String label,
    bool req = false,
    required Widget child,
    double bottom = 12,
  }) => Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, req: req),
        child,
      ],
    ),
  );

  Widget _sectionHeader(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: kPrimary),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kText,
          ),
        ),
      ],
    ),
  );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required String valueKey,
    required void Function(T?) onChanged,
    String? errorText,
    bool enabled = true,
  }) {
    final seen = <String>{};
    final unique = items.where((i) {
      final id = i[valueKey]?.toString() ?? '';
      return id.isNotEmpty && seen.add(id);
    }).toList();
    final valid =
        unique.any((i) => i[valueKey]?.toString() == value?.toString())
        ? value
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? kCardBg : kBgLight,
            border: Border.all(
              color: errorText != null ? kDanger : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: valid,
              hint: Text(
                hint,
                style: TextStyle(
                  color: kSubText.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              isExpanded: true,
              dropdownColor: kCardBg,
              icon: Icon(Icons.arrow_drop_down, color: kSubText, size: 20),
              onChanged: enabled ? onChanged : null,
              items: unique
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item[valueKey] as T,
                      child: Text(
                        item[labelKey]?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: TextStyle(color: kDanger, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _dropdownWithAdd<T>({
    required String label,
    required String hint,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required String valueKey,
    required void Function(T?) onChanged,
    required String settingsCategory,
    String? errorText,
    bool enabled = true,
    bool req = false,
  }) {
    return _field(
      label: label,
      req: req,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _dropdown<T>(
              hint: hint,
              value: value,
              items: items,
              labelKey: labelKey,
              valueKey: valueKey,
              onChanged: onChanged,
              errorText: errorText,
              enabled: enabled,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Get.to(
                () => const SettingsScreen(),
                arguments: settingsCategory,
              );
              // Refresh dropdown data after returning from settings
              _refreshDropdownData();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimary.withOpacity(0.35)),
              ),
              child: Icon(Icons.add, size: 18, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static String? _extractCurrencyCode(String s) {
    final m = RegExp(r'\(([A-Z]{3})\)').firstMatch(s);
    return m?.group(1);
  }

  void _applyCurrencyFromCode(String code) {
    try {
      final currency = CurrencyService().findByCode(code);
      if (currency != null) {
        _currency = currency.code;
        _currencyName = currency.name;
        _currencySymbol = currency.symbol;
        return;
      }
    } catch (_) {}
    _currency = code;
  }

  Widget _currencyPickerField() {
    final hasSelection = _currency.isNotEmpty;
    String? flagEmoji;
    if (hasSelection) {
      try {
        final c = CurrencyService().findByCode(_currency);
        if (c != null && c.flag != null) {
          flagEmoji = CurrencyUtils.currencyToEmoji(c);
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        showCurrencyPicker(
          context: context,
          showFlag: true,
          showCurrencyName: true,
          showCurrencyCode: true,
          showSearchField: true,
          favorite: const ['USD', 'EUR', 'GBP', 'PKR', 'SAR', 'AED'],
          theme: CurrencyPickerThemeData(
            backgroundColor: Colors.white,
            flagSize: 26,
            titleTextStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
            subtitleTextStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            bottomSheetHeight: MediaQuery.of(context).size.height * 0.85,
            inputDecoration: InputDecoration(
              hintText: 'Search currency',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
          onSelect: (Currency currency) {
            // FORM-LOCAL only — intentionally NOT calling CurrencyController.setCurrency()
            // so the app's global currency setting is never affected by product form selections.
            setState(() {
              _currency = currency.code;
              _currencyName = currency.name;
              _currencySymbol = currency.symbol;
            });
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (hasSelection && flagEmoji != null) ...[
              Text(flagEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
            ] else ...[
              Icon(Icons.attach_money, color: kSubText.withOpacity(0.5), size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: hasSelection
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_currency${_currencySymbol.isNotEmpty ? " ($_currencySymbol)" : ""}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        if (_currencyName.isNotEmpty)
                          Text(
                            _currencyName,
                            style: TextStyle(
                              fontSize: 11,
                              color: kSubText.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      'Select currency',
                      style: TextStyle(
                        fontSize: 13,
                        color: kSubText.withOpacity(0.5),
                      ),
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: kSubText.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _countryPickerField() {
    final hasSelection = _countryOfOrigin.isNotEmpty;
    return GestureDetector(
      onTap: () {
        CountrySelector(
          context: context,
          appBarTitle: 'Select Country',
          showPhoneCode: false,
          showSearchBox: true,
          searchBarAutofocus: true,
          listType: ListType.list,
          onSelect: (Country selected) {
            // FORM-LOCAL only — currency auto-filled from country, but never persisted globally.
            setState(() {
              _countryOfOrigin = selected.name;
              _countryFlagEmoji = selected.flagEmoji;
              final code = _extractCurrencyCode(selected.currency.toString());
              if (code != null) {
                _applyCurrencyFromCode(code);
              }
            });
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.public, color: kSubText.withOpacity(0.5), size: 18),
            const SizedBox(width: 10),
            if (hasSelection && _countryFlagEmoji.isNotEmpty) ...[
              Text(_countryFlagEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                hasSelection ? _countryOfOrigin : 'Select Country',
                style: TextStyle(
                  fontSize: 13,
                  color: hasSelection
                      ? Colors.black
                      : kSubText.withOpacity(0.5),
                  fontWeight:
                      hasSelection ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: kSubText.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final valid = items.contains(value) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valid,
          hint: Text(
            hint,
            style: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
          ),
          isExpanded: true,
          dropdownColor: kCardBg,
          icon: Icon(Icons.arrow_drop_down, color: kSubText, size: 20),
          onChanged: onChanged,
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _toggle({
    required String label,
    required bool value,
    required IconData icon,
    required void Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => setState(() => onChanged(!value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? kPrimary.withOpacity(0.1) : kCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? kPrimary.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: value ? kPrimary : kSubText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? kPrimary : kSubText,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: (v) => setState(() => onChanged(v)),
              activeColor: kPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  void _showBarcodeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Barcode Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: kPrimary),
                title: const Text('Scan Barcode'),
                subtitle: const Text('Scan existing product barcode'),
                onTap: () {
                  Navigator.pop(context);
                  _scanBarcode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.barcode_reader, color: kPrimary),
                title: const Text('Generate Barcode'),
                subtitle: const Text('Generate new barcode for this product'),
                onTap: () {
                  Navigator.pop(context);
                  _showBarcodeFormatDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const ProductQRScanScreen(),
    );

    if (result != null && result.isNotEmpty) {
      // Get the scanned barcode value from various possible keys
      final scannedBarcode =
          result['text']?.toString() ??
          result['id']?.toString() ??
          result['url']?.toString() ??
          result['barcode']?.toString() ??
          result['code']?.toString() ??
          result['rawValue']?.toString();

      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        // Check if barcode exists in database for this user
        final existingProduct = await _c.checkBarcodeExists(scannedBarcode);

        if (existingProduct != null) {
          // Product already exists for this user
          Get.snackbar(
            'Product Already Exists',
            'This barcode is already registered for product: ${existingProduct['name']}',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.black,
            duration: const Duration(seconds: 3),
          );
          // Navigate back
          Navigator.pop(context);
          return;
        }

        // Barcode doesn't exist, populate form with scanned data
        setState(() {
          if (result['name'] != null) {
            _nameCtrl.text = result['name'].toString();
          }
          if (result['sku'] != null) {
            _skuCtrl.text = result['sku'].toString();
          }
          if (result['id'] != null && _skuCtrl.text.isEmpty) {
            _skuCtrl.text = result['id'].toString();
          }
          if (result['price'] != null) {
            _sellCtrl.text = result['price'].toString();
          }

          // Set the scanned barcode as the generated barcode
          _generatedBarcodeData = scannedBarcode;
        });

        Get.snackbar(
          'New Product',
          'Barcode not found in database. You can add this as a new product.',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black,
        );
      } else {
        Get.snackbar(
          'Scan Error',
          'No valid barcode data found in scan',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
        );
      }
    }
  }

  void _showBarcodeFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Barcode Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _barcodeFormatOption('Code-128', 'Alphanumeric, most common'),
            _barcodeFormatOption('EAN-13', '13 digits, retail products'),
            _barcodeFormatOption('EAN-8', '8 digits, small products'),
            _barcodeFormatOption('UPC-A', '12 digits, US retail'),
            _barcodeFormatOption('Code-39', 'Alphanumeric, industrial'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _barcodeFormatOption(String format, String description) {
    return ListTile(
      title: Text(format),
      subtitle: Text(description),
      trailing: Radio<String>(
        value: format,
        groupValue: _selectedBarcodeFormat,
        onChanged: (value) {
          setState(() => _selectedBarcodeFormat = value);
          Navigator.pop(context);
          _generateBarcode();
        },
      ),
    );
  }

  void _generateBarcode() {
    // Validate required fields
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please enter product name first',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black,
      );
      return;
    }

    if (_skuCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please enter SKU first',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black,
      );
      return;
    }

    // Generate barcode based on format
    final barcodeData = _convertToBarcodeFormat(
      _skuCtrl.text.trim(),
      _selectedBarcodeFormat!,
    );

    // Set the generated barcode to display in form
    setState(() {
      _generatedBarcodeData = barcodeData;
    });

    Get.snackbar(
      'Barcode Generated',
      '$_selectedBarcodeFormat barcode generated successfully!',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.black,
    );
  }

  String _convertToBarcodeFormat(String sku, String format) {
    switch (format) {
      case 'EAN-13':
        // Generate 13-digit barcode from SKU
        return _generateNumericBarcode(sku, 13);
      case 'EAN-8':
        // Generate 8-digit barcode from SKU
        return _generateNumericBarcode(sku, 8);
      case 'UPC-A':
        // Generate 12-digit barcode from SKU
        return _generateNumericBarcode(sku, 12);
      case 'Code-39':
        // Use SKU directly (uppercase for Code-39 compatibility)
        return sku.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9\-\.\ \$\/\+\%]'),
          '',
        );
      case 'Code-128':
      default:
        // Use SKU directly (Code-128 supports all ASCII)
        return sku;
    }
  }

  String _generateNumericBarcode(String sku, int requiredLength) {
    final dataLength = requiredLength - 1;
    final numbers = sku.replaceAll(RegExp(r'[^0-9]'), '');

    String baseNumber;
    if (numbers.isNotEmpty) {
      baseNumber = numbers;
    } else {
      baseNumber = sku.hashCode.abs().toString();
    }

    if (baseNumber.length >= dataLength) {
      baseNumber = baseNumber.substring(0, dataLength);
    } else {
      baseNumber = baseNumber.padRight(dataLength, '0');
    }

    return baseNumber + _eanChecksum(baseNumber);
  }

  /// GS1 checksum: from the right, odd positions (1-based) weight 3.
  String _eanChecksum(String data) {
    int sum = 0;
    for (int i = 0; i < data.length; i++) {
      final digit = int.parse(data[data.length - 1 - i]);
      sum += digit * (i % 2 == 0 ? 3 : 1);
    }
    return ((10 - (sum % 10)) % 10).toString();
  }

  String _withValidChecksum(String value, int totalLength) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < totalLength - 1) {
      return _generateNumericBarcode(value, totalLength);
    }
    final data = digits.substring(0, totalLength - 1);
    return data + _eanChecksum(data);
  }

  bool _validateBarcodeData(String data, String format) {
    switch (format) {
      case 'EAN-13':
        return data.length == 13 && RegExp(r'^[0-9]+$').hasMatch(data);
      case 'EAN-8':
        return data.length == 8 && RegExp(r'^[0-9]+$').hasMatch(data);
      case 'UPC-A':
        return data.length == 12 && RegExp(r'^[0-9]+$').hasMatch(data);
      case 'Code-39':
        return RegExp(
          r'^[A-Z0-9\-\.\ \$\/\+\%]+$',
        ).hasMatch(data.toUpperCase());
      case 'Code-128':
      default:
        return data.isNotEmpty;
    }
  }

  Widget _buildBarcodeWidget() {
    final data = _generatedBarcodeData ?? '';
    if (data.isEmpty) return const SizedBox.shrink();

    return SvgPicture.string(
      _barcodeSvg(data, _selectedBarcodeFormat),
      width: 200,
      height: 80,
    );
  }

  String _barcodeSvg(String data, String? format) {
    try {
      late Barcode barcode;
      var payload = data;
      switch (format) {
        case 'EAN-13':
          barcode = Barcode.ean13();
          payload = _withValidChecksum(data, 13);
          break;
        case 'EAN-8':
          barcode = Barcode.ean8();
          payload = _withValidChecksum(data, 8);
          break;
        case 'UPC-A':
          barcode = Barcode.upcA();
          payload = _withValidChecksum(data, 12);
          break;
        case 'Code-39':
          barcode = Barcode.code39();
          payload = data.toUpperCase().replaceAll(
            RegExp(r'[^A-Z0-9\-\.\ \$\/\+\%]'),
            '',
          );
          if (payload.isEmpty) payload = '0';
          break;
        case 'Code-128':
        default:
          barcode = Barcode.code128();
          break;
      }
      return barcode.toSvg(payload, width: 200, height: 80);
    } catch (_) {
      return Barcode.code128().toSvg(data, width: 200, height: 80);
    }
  }

  Widget _datePicker({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => onChanged(date));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: kCardBg,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null
                  ? '${value.day}/${value.month}/${value.year}'
                  : label,
              style: TextStyle(
                fontSize: 13,
                color: value != null ? kText : kSubText.withOpacity(0.5),
              ),
            ),
            Row(
              children: [
                if (value != null)
                  GestureDetector(
                    onTap: () => setState(() => onChanged(null)),
                    child: Icon(Icons.close, size: 14, color: kSubText),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.calendar_today, size: 15, color: kSubText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case 0:
        return _tab0Basic();
      case 1:
        return _tab1Pricing();
      case 2:
        return _tab2Category();
      case 3:
        return _tab3Warehouse();
      case 4:
        return _tab4Physical();
      case 5:
        return _tab5Expiry();
      case 6:
        return _tab6Shipping();
      case 7:
        return _tab7Media();
      case 8:
        return _tab8Custom();
      default:
        return _tab0Basic();
    }
  }

  Widget _tab0Basic() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Basic Information', Icons.inventory_2_outlined),
      _field(
        label: 'Product Name',
        req: true,
        child: TextFormField(
          controller: _nameCtrl,
          decoration: _dec(
            hint: 'e.g., Rice 5kg',
            icon: Icons.inventory_2_outlined,
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ),
      _field(
        label: 'SKU',
        req: true,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skuCtrl,
                decoration: _dec(hint: 'SKU-001', icon: Icons.qr_code_2),
                style: const TextStyle(fontSize: 13, color: Colors.black),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _skuCtrl.text = _c.generateSku()),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withOpacity(0.35)),
                ),
                child: Icon(Icons.refresh_rounded, size: 18, color: kPrimary),
              ),
            ),
          ],
        ),
      ),
      // Barcode Options
      _field(
        label: 'Barcode',
        child: GestureDetector(
          onTap: _showBarcodeOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: kCardBg,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.barcode_reader, size: 18, color: kSubText),
                    const SizedBox(width: 10),
                    Text(
                      _generatedBarcodeData != null
                          ? 'Barcode Generated'
                          : 'Select Barcode Option',
                      style: TextStyle(
                        fontSize: 13,
                        color: _generatedBarcodeData != null
                            ? kPrimary
                            : kSubText.withOpacity(0.6),
                        fontWeight: _generatedBarcodeData != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_drop_down, color: kSubText),
              ],
            ),
          ),
        ),
      ),
      // Barcode Display
      if (_generatedBarcodeData != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Barcode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format: $_selectedBarcodeFormat',
                          style: TextStyle(fontSize: 11, color: kSubText),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _generatedBarcodeData = null),
                      child: Icon(Icons.close, size: 18, color: kSubText),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: _buildBarcodeWidget()),
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedBarcodeData!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: kText,
                  ),
                ),
              ],
            ),
          ),
        ),
      _dropdownWithAdd<String>(
        label: 'Product Type',
        hint: 'Select Type',
        value: _selectedProductType,
        items: _productTypes,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedProductType = v),
        settingsCategory: 'productType',
      ),
      _field(
        label: 'Description (Optional)',
        child: TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: _dec(hint: 'Product description...'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Tags (Optional)',
        child: TextFormField(
          controller: _tagsCtrl,
          decoration: _dec(
            hint: 'electronics, sale, imported',
            icon: Icons.label_outline,
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),

      // QR Generation Button
    ],
  );

  Widget _tab1Pricing() {
    final sym = _currencySymbol.isNotEmpty ? _currencySymbol : _currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Pricing', Icons.attach_money),
        _field(
          label: 'Cost Price',
          req: true,
          child: TextFormField(
            controller: _costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: '0.00', prefix: '$sym '),
            style: const TextStyle(fontSize: 13, color: Colors.black),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid';
              return null;
            },
          ),
        ),
        _field(
          label: 'Selling Price',
          req: true,
          child: TextFormField(
            controller: _sellCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: '0.00', prefix: '$sym '),
            style: const TextStyle(fontSize: 13, color: Colors.black),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid';
              return null;
            },
          ),
        ),
        _field(
          label: 'Landing Cost (Optional)',
          child: TextFormField(
            controller: _landingCostCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: '0.00', prefix: '$sym '),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
        _field(
          label: 'Currency',
          child: _currencyPickerField(),
        ),
        _sectionHeader('Tax', Icons.receipt_long_outlined),
        _field(
          label: 'Tax class',
          child: TaxRateField(
            value: double.tryParse(_taxRateCtrl.text) ?? 0,
            onRateChanged: (r) {
              _taxRateCtrl.text = r.toString();
              setState(() {});
            },
            onTypeChanged: (t) => setState(() => _selectedTaxType = t),
          ),
        ),
        _sectionHeader('Stock Information', Icons.inventory_outlined),
        _dropdownWithAdd<String>(
          label: 'Stock Unit',
          hint: 'Select Unit',
          value: _selectedStockUnit,
          items: _stockUnits,
          labelKey: 'name',
          valueKey: 'name',
          onChanged: (v) => setState(() => _selectedStockUnit = v),
          settingsCategory: 'stockUnit',
        ),
        _field(
          label: 'Current Stock',
          req: true,
          child: TextFormField(
            controller: _stockCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec(hint: '0', icon: Icons.inventory_outlined),
            style: const TextStyle(fontSize: 13, color: Colors.black),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (int.tryParse(v) == null) return 'Must be a number';
              return null;
            },
          ),
        ),
        _field(
          label: 'Minimum Stock',
          child: TextFormField(
            controller: _minStockCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec(hint: '5'),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
        _field(
          label: 'Maximum Stock',
          child: TextFormField(
            controller: _maxStockCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec(hint: '100'),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
        _field(
          label: 'Reorder Point',
          child: TextFormField(
            controller: _reorderPointCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec(hint: '50'),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _tab2Category() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Category & Supplier', Icons.category_outlined),
      _label('Category', req: true),
      const SizedBox(height: 5),
      Row(
        children: [
          Expanded(
            child: _dropdown<String>(
              hint: 'Select Category',
              value: _selectedCategoryId,
              items: _categories,
              labelKey: 'name',
              valueKey: 'id',
              errorText: _categoryError,
              onChanged: (v) => setState(() {
                _selectedCategoryId = v;
                _selectedSubCategoryId = null;
                _categoryError = null;
                _subCategories = _c.getSubCategories(v);
              }),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Get.to(() => const CategoriesScreen());
              // Refresh dropdown data after returning from categories
              _refreshDropdownData();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _dropdown<String>(
              hint: _subCategories.isEmpty
                  ? 'No sub-categories available'
                  : 'Select Sub-Category',
              value: _selectedSubCategoryId,
              items: _subCategories,
              labelKey: 'name',
              valueKey: 'id',
              enabled: _subCategories.isNotEmpty,
              onChanged: (v) => setState(() => _selectedSubCategoryId = v),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Get.to(() => const CategoriesScreen());
              // Refresh dropdown data after returning from categories
              _refreshDropdownData();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      _field(
        label: 'Brand',
        child: TextFormField(
          controller: _brandCtrl,
          decoration: _dec(
            hint: 'e.g., Nestlé',
            icon: Icons.branding_watermark_outlined,
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Model Number',
        child: TextFormField(
          controller: _modelCtrl,
          decoration: _dec(hint: 'e.g., XR-2000', icon: Icons.numbers),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Supplier', Icons.local_shipping_outlined),
      Row(
        children: [
          Expanded(
            child: _dropdown<String>(
              hint: 'Select Supplier',
              value: _selectedSupplierId,
              items: _suppliers,
              labelKey: 'name',
              valueKey: 'id',
              onChanged: (v) => setState(() => _selectedSupplierId = v),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Get.to(() => const SuppliersScreen());
              // Refresh dropdown data after returning from suppliers
              _refreshDropdownData();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      _field(
        label: 'Supplier SKU',
        child: TextFormField(
          controller: _supplierSkuCtrl,
          decoration: _dec(hint: 'Supplier SKU'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Lead Time (Days)',
        child: TextFormField(
          controller: _leadTimeCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: '7'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    ],
  );

  Widget _tab3Warehouse() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Location', Icons.warehouse_outlined),
      _dropdownWithAdd<String>(
        label: 'Rack Location',
        hint: 'Select Rack',
        value: _selectedRackLocation,
        items: _rackLocations,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedRackLocation = v),
        settingsCategory: 'rackLocation',
      ),
      _dropdownWithAdd<String>(
        label: 'Zone',
        hint: 'Select Zone',
        value: _selectedZone,
        items: _zones,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedZone = v),
        settingsCategory: 'zone',
      ),
      _field(
        label: 'Pallet Number',
        child: TextFormField(
          controller: _palletCtrl,
          decoration: _dec(hint: 'Pallet #'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Shelf Number',
        child: TextFormField(
          controller: _shelfCtrl,
          decoration: _dec(hint: 'Shelf #'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Storage Conditions', Icons.thermostat_outlined),
      _field(
        label: 'Storage Condition',
        child: _dropdown<String>(
          hint: 'Select Condition',
          value: _selectedStorageCondition,
          items: _storageConditions,
          labelKey: 'name',
          valueKey: 'name',
          onChanged: (v) => setState(() => _selectedStorageCondition = v),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _field(
              label: 'Temp Min (°C)',
              child: TextFormField(
                controller: _tempMinCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec(hint: '0'),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              label: 'Temp Max (°C)',
              child: TextFormField(
                controller: _tempMaxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec(hint: '40'),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _tab4Physical() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Weight & Dimensions', Icons.straighten),
      _field(
        label: 'Weight',
        child: TextFormField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(hint: '0.0'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _dropdownWithAdd<String>(
        label: 'Weight Unit',
        hint: 'Select Unit',
        value: _selectedWeightUnit,
        items: _weightUnits,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedWeightUnit = v),
        settingsCategory: 'weightUnit',
      ),
      _dropdownWithAdd<String>(
        label: 'Dimension Unit',
        hint: 'Select Unit',
        value: _selectedDimensionUnit,
        items: _dimensionUnits,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedDimensionUnit = v),
        settingsCategory: 'dimensionUnit',
      ),
      Row(
        children: [
          Expanded(
            child: _field(
              label: 'Length',
              child: TextFormField(
                controller: _lengthCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec(hint: '0.0'),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              label: 'Width',
              child: TextFormField(
                controller: _widthCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec(hint: '0.0'),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      _field(
        label: 'Height',
        child: TextFormField(
          controller: _heightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec(hint: '0.0'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Variants & Material', Icons.palette_outlined),
      _field(
        label: 'Color',
        child: TextFormField(
          controller: _colorCtrl,
          decoration: _dec(hint: 'e.g., Red', icon: Icons.circle_outlined),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _dropdownWithAdd<String>(
        label: 'Size',
        hint: 'Select Size',
        value: _selectedSize,
        items: _sizes,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedSize = v),
        settingsCategory: 'size',
      ),
      _field(
        label: 'Material',
        child: TextFormField(
          controller: _materialCtrl,
          decoration: _dec(hint: 'e.g., Cotton, Steel', icon: Icons.texture),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Finish',
        child: TextFormField(
          controller: _finishCtrl,
          decoration: _dec(hint: 'e.g., Matte, Glossy'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    ],
  );

  Widget _tab5Expiry() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Tracking Flags', Icons.track_changes_outlined),
      _toggle(
        label: 'Has Expiry',
        value: _hasExpiry,
        icon: Icons.event_busy_outlined,
        onChanged: (v) => _hasExpiry = v,
      ),
      const SizedBox(height: 8),
      _toggle(
        label: 'Batch Managed',
        value: _isBatchManaged,
        icon: Icons.layers_outlined,
        onChanged: (v) => _isBatchManaged = v,
      ),
      const SizedBox(height: 8),
      _toggle(
        label: 'Serial Managed',
        value: _isSerialManaged,
        icon: Icons.pin_outlined,
        onChanged: (v) => _isSerialManaged = v,
      ),
      const SizedBox(height: 8),
      _toggle(
        label: 'Expiry Managed',
        value: _isExpiryManaged,
        icon: Icons.timer_outlined,
        onChanged: (v) => _isExpiryManaged = v,
      ),
      const SizedBox(height: 16),
      _sectionHeader('Dates & Batch', Icons.calendar_month_outlined),
      _label('Expiry Date (Optional)'),
      const SizedBox(height: 5),
      _datePicker(
        label: 'Select expiry date',
        value: _expiryDate,
        onChanged: (d) => _expiryDate = d,
      ),
      const SizedBox(height: 12),
      _label('Manufacturing Date (Optional)'),
      const SizedBox(height: 5),
      _datePicker(
        label: 'Select manufacturing date',
        value: _manufacturingDate,
        onChanged: (d) => _manufacturingDate = d,
      ),
      const SizedBox(height: 12),
      _field(
        label: 'Batch Number',
        child: TextFormField(
          controller: _batchNumberCtrl,
          decoration: _dec(hint: 'BATCH-001'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Shelf Life (Days)',
        child: TextFormField(
          controller: _shelfLifeCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: '365'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Bulk Management', Icons.inventory_2_outlined),
      _toggle(
        label: 'Bulk Managed',
        value: _isBulkManaged,
        icon: Icons.category_outlined,
        onChanged: (v) => _isBulkManaged = v,
      ),
      const SizedBox(height: 8),
      _toggle(
        label: 'Individual Tracking',
        value: _hasIndividualTracking,
        icon: Icons.person_outline,
        onChanged: (v) => _hasIndividualTracking = v,
      ),
      const SizedBox(height: 12),
      _field(
        label: 'Bulk Unit',
        child: _simpleDropdown(
          hint: 'Select bulk unit',
          value: _bulkUnit,
          items: ['Bale', 'Box', 'Roll', 'Pallet'],
          onChanged: (v) => setState(() => _bulkUnit = v ?? 'Bale'),
        ),
      ),
      _field(
        label: 'Default Batch Quantity',
        child: TextFormField(
          controller: _defaultBatchQtyCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: '50'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    ],
  );

  Widget _tab6Shipping() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Shipping Info', Icons.local_shipping_outlined),
      _field(
        label: 'HS Code',
        child: TextFormField(
          controller: _hsCodeCtrl,
          decoration: _dec(hint: 'e.g., 5201.00.00'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Country of Origin',
        child: _countryPickerField(),
      ),
      _dropdownWithAdd<String>(
        label: 'Shipping Class',
        hint: 'Select Shipping Class',
        value: _selectedShippingClass,
        items: _shippingClasses,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedShippingClass = v),
        settingsCategory: 'shippingClass',
      ),
      _field(
        label: 'Freight Class',
        child: TextFormField(
          controller: _freightClassCtrl,
          decoration: _dec(hint: 'Freight class'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Stacking Limit',
        child: TextFormField(
          controller: _stackingLimitCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: '5'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Safety & Returns', Icons.shield_outlined),
      _toggle(
        label: 'Dangerous Goods',
        value: _dangerousGoods,
        icon: Icons.warning_amber_outlined,
        onChanged: (v) => _dangerousGoods = v,
      ),
      const SizedBox(height: 12),
      _field(
        label: 'UN Number',
        child: TextFormField(
          controller: _unNumberCtrl,
          decoration: _dec(hint: 'UN #'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _field(
        label: 'Handling Instructions',
        child: TextFormField(
          controller: _handlingCtrl,
          decoration: _dec(hint: 'Special handling instructions...'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
      _sectionHeader('Warranty & Returns', Icons.verified_outlined),
      Row(
        children: [
          Expanded(
            child: _field(
              label: 'Warranty Period',
              child: TextFormField(
                controller: _warrantyPeriodCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec(hint: '12'),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              label: 'Warranty Unit',
              child: _simpleDropdown(
                hint: 'Unit',
                value: _warrantyUnit,
                items: ['Days', 'Months', 'Years'],
                onChanged: (v) => setState(() => _warrantyUnit = v ?? 'Months'),
              ),
            ),
          ),
        ],
      ),
      _toggle(
        label: 'Is Returnable',
        value: _isReturnable,
        icon: Icons.undo_outlined,
        onChanged: (v) => _isReturnable = v,
      ),
      const SizedBox(height: 12),
      _field(
        label: 'Return Days',
        child: TextFormField(
          controller: _returnDaysCtrl,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: '7'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    ],
  );

  Widget _tab7Media() {
    final total = _existingImages.length + _newImagePaths.length;
    final remaining = 5 - total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Media', Icons.image_outlined),
        Row(
          children: [
            Text(
              'Product Images',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kSubText),
            ),
            const Spacer(),
            Text(
              '$total / 5',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSubText),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select multiple images. First image is main. You can add more in batches.',
          style: TextStyle(fontSize: 11, color: kSubText.withOpacity(0.7)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._existingImages.asMap().entries.map((e) {
              final isMain = e.key == 0 && _newImagePaths.isEmpty;
              return _imageThumb(
                child: Image.network(
                  e.value,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
                isMain: isMain,
                onRemove: () => setState(() => _existingImages.remove(e.value)),
              );
            }),
            ..._newImagePaths.asMap().entries.map((e) {
              final isMain = _existingImages.isEmpty && e.key == 0;
              return _imageThumb(
                child: Image.file(File(e.value), fit: BoxFit.cover),
                isMain: isMain,
                onRemove: () => setState(() => _newImagePaths.remove(e.value)),
              );
            }),
            if (remaining > 0)
              InkWell(
                onTap: _showImageSourceSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: kSubText.withOpacity(0.75), size: 26),
                      const SizedBox(height: 4),
                      Text('Add images', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kSubText)),
                      Text('$remaining left', style: TextStyle(fontSize: 9, color: kSubText.withOpacity(0.7))),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (remaining > 0) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickProductImages,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Choose multiple images'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: BorderSide(color: kPrimary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _imageThumb({
    required Widget child,
    required VoidCallback onRemove,
    bool isMain = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMain ? kPrimary.withOpacity(0.55) : Colors.grey.withOpacity(0.3),
              width: isMain ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        if (isMain)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Main',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceSheet() async {
    final remaining = 5 - (_existingImages.length + _newImagePaths.length);
    if (remaining <= 0) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose multiple from gallery'),
                subtitle: Text('Up to $remaining more'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProductImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProductImages() async {
    final picker = ImagePicker();
    final remaining = 5 - (_existingImages.length + _newImagePaths.length);
    if (remaining <= 0) return;
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _newImagePaths.addAll(files.take(remaining).map((f) => f.path));
    });
  }

  Future<void> _pickFromCamera() async {
    final remaining = 5 - (_existingImages.length + _newImagePaths.length);
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _newImagePaths.add(file.path);
    });
  }

  Widget _tab8Custom() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Additional Notes', Icons.note_outlined),
      _field(
        label: 'Notes',
        child: TextFormField(
          controller: _notesCtrl,
          maxLines: 5,
          decoration: _dec(hint: 'Enter any additional notes...'),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    ],
  );

  Future<void> _submit() async {
    if (_selectedCategoryId == null) {
      setState(() {
        _categoryError = 'Please select a category';
        _activeTab = 2;
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'sku': _skuCtrl.text.trim(),
      'barcodeNumber': _barcodeCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'tags': _tagsCtrl.text.trim(),
      'categoryId': _selectedCategoryId,
      'costPrice': _costCtrl.text.trim(),
      'sellingPrice': _sellCtrl.text.trim(),
      'landingCost': _landingCostCtrl.text.trim(),
      'currencyCode': _currency,
      'currencyName': _currencyName,
      'currencySymbol': _currencySymbol,
      'taxRate': _taxRateCtrl.text.trim(),
      'currentStock': _stockCtrl.text.trim(),
      'minimumStock': _minStockCtrl.text.trim(),
      'maximumStock': _maxStockCtrl.text.trim(),
      'reorderPoint': _reorderPointCtrl.text.trim(),
      'leadTimeDays': _leadTimeCtrl.text.trim(),
      'brandName': _brandCtrl.text.trim(),
      'modelNumber': _modelCtrl.text.trim(),
      'supplierSku': _supplierSkuCtrl.text.trim(),
      'palletNumber': _palletCtrl.text.trim(),
      'shelfNumber': _shelfCtrl.text.trim(),
      'temperatureMin': _tempMinCtrl.text.trim(),
      'temperatureMax': _tempMaxCtrl.text.trim(),
      'weight': _weightCtrl.text.trim(),
      'length': _lengthCtrl.text.trim(),
      'width': _widthCtrl.text.trim(),
      'height': _heightCtrl.text.trim(),
      'color': _colorCtrl.text.trim(),
      'material': _materialCtrl.text.trim(),
      'finish': _finishCtrl.text.trim(),
      'hasExpiry': _hasExpiry,
      'isBatchManaged': _isBatchManaged,
      'isSerialManaged': _isSerialManaged,
      'isExpiryManaged': _isExpiryManaged,
      'isBulkManaged': _isBulkManaged,
      'hasIndividualTracking': _hasIndividualTracking,
      'bulkUnit': _bulkUnit,
      'batchNumber': _batchNumberCtrl.text.trim(),
      'shelfLifeDays': _shelfLifeCtrl.text.trim(),
      'defaultQuantityPerBatch': _defaultBatchQtyCtrl.text.trim(),
      'hsCode': _hsCodeCtrl.text.trim(),
      'countryOfOriginName': _countryOfOrigin,
      'countryOfOriginFlag': _countryFlagEmoji,
      'freightClass': _freightClassCtrl.text.trim(),
      'stackingLimit': _stackingLimitCtrl.text.trim(),
      'dangerousGoods': _dangerousGoods,
      'unNumber': _unNumberCtrl.text.trim(),
      'handlingInstructions': _handlingCtrl.text.trim(),
      'warrantyPeriod': _warrantyPeriodCtrl.text.trim(),
      'warrantyUnit': _warrantyUnit,
      'isReturnable': _isReturnable,
      'returnDays': _returnDaysCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      if (_generatedBarcodeData != null) 'barcodeNumber': _generatedBarcodeData,
      if (_selectedBarcodeFormat != null)
        'barcodeFormat': _selectedBarcodeFormat,
      if (_selectedProductType != null) 'productType': _selectedProductType,
      if (_selectedTaxType != null) 'taxType': _selectedTaxType,
      if (_selectedStockUnit != null) 'stockUnitName': _selectedStockUnit,
      if (_selectedSupplierId != null) 'supplierId': _selectedSupplierId,
      if (_selectedSubCategoryId != null)
        'subCategoryId': _selectedSubCategoryId,
      if (_selectedRackLocation != null)
        'rackLocationName': _selectedRackLocation,
      if (_selectedZone != null) 'zoneName': _selectedZone,
      if (_selectedStorageCondition != null)
        'storageConditionName': _selectedStorageCondition,
      if (_selectedWeightUnit != null) 'weightUnitName': _selectedWeightUnit,
      if (_selectedDimensionUnit != null)
        'dimensionUnit': _selectedDimensionUnit,
      if (_selectedSize != null) 'size': _selectedSize,
      if (_selectedShippingClass != null)
        'shippingClass': _selectedShippingClass,
      if (_expiryDate != null) 'expiryDate': _expiryDate!.toIso8601String(),
      if (_manufacturingDate != null)
        'manufacturingDate': _manufacturingDate!.toIso8601String(),
    };

    bool success;
    if (_isEditing) {
      success = await _c.updateProduct(
        widget.editingProduct!['_id'] ?? widget.editingProduct!['id'] ?? '',
        payload,
        imagePaths: _newImagePaths,
        existingImages: _existingImages,
      );
    } else {
      success = await _c.createProduct(
        payload,
        imagePaths: _newImagePaths,
        existingImages: _existingImages,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      Get.snackbar(
        _isEditing ? 'Updated' : 'Created',
        _isEditing
            ? 'Product updated successfully'
            : 'Product created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccess,
        colorText: Colors.black,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Error',
        _isEditing ? 'Failed to update product.' : 'Failed to create product.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.black,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
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
              child: Icon(
                _isEditing ? Icons.edit_outlined : Icons.add_box_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditing ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _submit,
                  child: Text(
                    _isEditing ? 'Update' : 'Save',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: kCardBg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: List.generate(_productTabs.length, (i) {
                  final tab = _productTabs[i];
                  final active = _activeTab == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: active ? kPrimary : kPrimary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 13,
                              color: active ? Colors.white : kSubText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active ? Colors.white : kSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(key: _formKey, child: _buildActiveTab()),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: BoxDecoration(
              color: kCardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_activeTab > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _activeTab--),
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Back',
                        style: TextStyle(fontSize: 13, color: Colors.black),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: _activeTab < _productTabs.length - 1
                      ? ElevatedButton.icon(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_activeTab == 2 &&
                                      _selectedCategoryId == null) {
                                    setState(
                                      () => _categoryError =
                                          'Please select a category',
                                    );
                                    return;
                                  }
                                  setState(() => _activeTab++);
                                },
                          icon: const Text(
                            'Next',
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          label: const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.black,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Update Product'
                                      : 'Save Product',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOBILE PRODUCTS LIST (Infinite Scroll)
// ═══════════════════════════════════════════════════════════════
class _MobileProductsList extends StatefulWidget {
  final ProductsController controller;
  final void Function(Map<String, dynamic>) onProductTap;
  final VoidCallback onAddProduct;
  const _MobileProductsList({
    required this.controller,
    required this.onProductTap,
    required this.onAddProduct,
  });

  @override
  State<_MobileProductsList> createState() => _MobileProductsListState();
}

class _MobileProductsListState extends State<_MobileProductsList> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && pos.maxScrollExtent > 0) {
      widget.controller.fetchMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = widget.controller.products;
      if (products.isEmpty && !widget.controller.isLoading.value) {
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
                  Icons.inventory_2_outlined,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No products yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to add your first product',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onAddProduct,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: products.length + 1,
        itemBuilder: (context, index) {
          if (index == products.length) return _footer();
          final product = products[index];
          final stock = product['currentStock'] ?? 0;
          final stockColor = widget.controller.getStockColor(stock);
          final price = widget.controller.formatCurrency(
            (product['sellingPrice'] ?? 0.0).toDouble(),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onProductTap(product),
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
                      _ProductThumb(product: product, stockColor: stockColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product['sku'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: kSubText,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                if ((product['categoryName'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    product['categoryName'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: kSubText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                _badge(
                                  widget.controller.getStockStatus(stock),
                                  stockColor.withOpacity(0.12),
                                  stockColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Qty: $stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kSubText,
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
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
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

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _footer() {
    if (widget.controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!widget.controller.hasMore.value &&
        widget.controller.products.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            'All products loaded',
            style: TextStyle(fontSize: 12, color: kSubText.withOpacity(0.7)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ProductThumb extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color stockColor;
  const _ProductThumb({required this.product, required this.stockColor});

  String? get _url {
    final main = product['mainImage']?.toString();
    if (main != null && main.isNotEmpty) return main;
    final imgs = product['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.inventory_2_rounded, color: stockColor, size: 22)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.inventory_2_rounded, color: stockColor, size: 22),
            ),
    );
  }
}
