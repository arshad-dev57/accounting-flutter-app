import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/products/controller/product_controller.dart';
import 'package:LedgerPro_app/core/warehousesettings/warehouse_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class _ProductTab {
  final String label;
  final IconData icon;
  const _ProductTab(this.label, this.icon);
}

const _productTabs = [
  _ProductTab('Basic Info',      Icons.info_outline),
  _ProductTab('Pricing & Stock', Icons.attach_money),
  _ProductTab('Category',        Icons.category_outlined),
  _ProductTab('Warehouse',       Icons.warehouse_outlined),
  _ProductTab('Physical',        Icons.straighten),
  _ProductTab('Expiry & Batch',  Icons.calendar_month_outlined),
  _ProductTab('Shipping',        Icons.local_shipping_outlined),
  _ProductTab('Media',           Icons.image_outlined),
  _ProductTab('Custom',          Icons.tune_outlined),
];

// ═══════════════════════════════════════════════════════════════
// PRODUCTS SCREEN
// ═══════════════════════════════════════════════════════════════
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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openProductPage(BuildContext context, ProductsController controller,
      {Map<String, dynamic>? product}) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _AddProductPage(controller: controller, editingProduct: product),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          // ── Fixed top header ──
          _buildTopHeader(),
          // ── List area ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return Center(
                    child: LoadingAnimationWidget.discreteCircle(
                        color: kPrimary, size: 40));
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _MobileProductsList(
                  controller: controller,
                  onProductTap: (p) => _showProductDetails(context, p, controller),
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
        child: const Icon(Icons.add, color: Colors.black, size: 24),
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
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Products',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.3),
                        ),
                        Obx(() => Text(
                              '${controller.totalProducts.value} items in inventory',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w500),
                            )),
                      ],
                    ),
                  ),
                  // Compact KPIs
                  Obx(() => Row(
                        children: [
                          _compactKpi('Stock', controller.inStockCount.value.toString(), Colors.green.shade800),
                          const SizedBox(width: 10),
                          _compactKpi('Low', controller.lowStockCount.value.toString(), Colors.orange.shade800),
                          const SizedBox(width: 10),
                          _compactKpi('Out', controller.outOfStockCount.value.toString(), Colors.red.shade700),
                        ],
                      )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshProducts,
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
            // Search
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
                        offset: const Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() {});
                    v.isEmpty ? controller.clearSearch() : controller.searchProducts(v);
                  },
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search by name or SKU...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              controller.clearSearch();
                              setState(() {});
                            },
                            child: Icon(Icons.close, size: 16, color: Colors.grey.shade400))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    isDense: true,
                  ),
                ),
              ),
            ),
            // Filter chips
            Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: controller.filters.map((filter) {
                      final isSelected = controller.selectedFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => controller.filterProducts(filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white.withOpacity(0.4)),
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
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Product Details Bottom Sheet ─────────────────────────
  void _showProductDetails(
      BuildContext context, Map<String, dynamic> product, ProductsController controller) {
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
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Header
                  Row(children: [
                    Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.inventory_2, color: kPrimary, size: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product['name'] ?? 'Unknown',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kText)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(product['sku'] ?? '-',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary,
                                  fontFamily: 'monospace')),
                        ),
                        const SizedBox(width: 6),
                        Text('• ${product['categoryName'] ?? ''}',
                            style: TextStyle(fontSize: 11, color: kSubText)),
                      ]),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    _miniKpi(
                        'Selling Price',
                        controller.formatCurrency(
                            (product['sellingPrice'] ?? 0.0).toDouble()),
                        kText,
                        Icons.attach_money),
                    const SizedBox(width: 8),
                    _miniKpi(
                        'Cost Price',
                        controller.formatCurrency(
                            (product['costPrice'] ?? 0.0).toDouble()),
                        kSubText,
                        Icons.money_off_outlined),
                    const SizedBox(width: 8),
                    _miniKpi('Stock', stock.toString(), stockColor,
                        Icons.inventory_outlined),
                  ]),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                  const SizedBox(height: 16),
                  _detailRow('Brand',
                      product['brandName'] ?? product['brand'] ?? '-'),
                  _detailRow('Model No.', product['modelNumber'] ?? '-'),
                  _detailRow('Type', product['productType'] ?? '-'),
                  _detailRow('Supplier', product['supplierName'] ?? '-'),
                  _detailRow(
                      'Status', controller.getStockStatus(stock),
                      badgeColor: stockColor),
                  _detailRow('Min Stock',
                      (product['minimumStock'] ?? '-').toString()),
                  _detailRow('Max Stock',
                      (product['maximumStock'] ?? '-').toString()),
                  _detailRow(
                      'Rack',
                      product['rackLocationName'] ??
                          product['location'] ??
                          '-'),
                  _detailRow('Tax Rate', '${product['taxRate'] ?? 0}%'),
                  if ((product['description'] ?? '').toString().isNotEmpty)
                    _detailRow('Description', product['description']),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openProductPage(context, controller,
                            product: product);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Edit',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    )),
                  ]),
                ]),
              ),
            ),
          ]),
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
          border: Border.all(color: color.withOpacity(0.15))),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: kSubText)),
      ]),
    ));
  }

  Widget _detailRow(String label, String value, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                    fontWeight: FontWeight.w500))),
        Expanded(
            child: badgeColor != null
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeColor)),
                  )
                : Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        color: kText,
                        fontWeight: FontWeight.w500))),
      ]),
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
  late List<Map<String, dynamic>> _taxTypes;
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
  String _currency = 'PKR';
  String _countryOfOrigin = 'Pakistan';
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

  @override
  void initState() {
    super.initState();

    _productTypes      = List<Map<String, dynamic>>.from(_c.productTypes);
    _stockUnits        = List<Map<String, dynamic>>.from(_c.stockUnits);
    _taxTypes          = List<Map<String, dynamic>>.from(_c.taxTypes);
    _categories        = List<Map<String, dynamic>>.from(_c.categories);
    _suppliers         = List<Map<String, dynamic>>.from(_c.suppliers);
    _rackLocations     = List<Map<String, dynamic>>.from(_c.rackLocations);
    _zones             = List<Map<String, dynamic>>.from(_c.zones);
    _storageConditions = List<Map<String, dynamic>>.from(_c.storageConditions);
    _weightUnits       = List<Map<String, dynamic>>.from(_c.weightUnits);
    _dimensionUnits    = List<Map<String, dynamic>>.from(_c.dimensionUnits);
    _sizes             = List<Map<String, dynamic>>.from(_c.sizes);
    _shippingClasses   = List<Map<String, dynamic>>.from(_c.shippingClasses);

    final p = widget.editingProduct;

    _nameCtrl           = TextEditingController(text: p?['name'] ?? '');
    _skuCtrl            = TextEditingController(text: p?['sku'] ?? _c.generateSku());
    _barcodeCtrl        = TextEditingController(text: p?['barcodeNumber'] ?? '');
    _descCtrl           = TextEditingController(text: p?['description'] ?? '');
    _tagsCtrl           = TextEditingController(text: p?['tags'] ?? '');
    _selectedProductType = p?['productType'];

    _costCtrl           = TextEditingController(text: (p?['costPrice'] ?? '').toString());
    _sellCtrl           = TextEditingController(text: (p?['sellingPrice'] ?? '').toString());
    _landingCostCtrl    = TextEditingController(text: (p?['landingCost'] ?? '').toString());
    _taxRateCtrl        = TextEditingController(text: (p?['taxRate'] ?? '0').toString());
    _stockCtrl          = TextEditingController(text: (p?['currentStock'] ?? '').toString());
    _minStockCtrl       = TextEditingController(text: (p?['minimumStock'] ?? '5').toString());
    _maxStockCtrl       = TextEditingController(text: (p?['maximumStock'] ?? '100').toString());
    _reorderPointCtrl   = TextEditingController(text: (p?['reorderPoint'] ?? '').toString());
    _leadTimeCtrl       = TextEditingController(text: (p?['leadTime'] ?? '').toString());
    _selectedStockUnit  = p?['stockUnit'];
    _selectedTaxType    = p?['taxType'];

    _selectedCategoryId = p?['categoryId'];
    _selectedSupplierId = p?['supplierId'];
    _brandCtrl          = TextEditingController(text: p?['brandName'] ?? p?['brand'] ?? '');
    _modelCtrl          = TextEditingController(text: p?['modelNumber'] ?? '');
    _supplierSkuCtrl    = TextEditingController(text: p?['supplierSku'] ?? '');
    if (_selectedCategoryId != null) {
      _subCategories = _c.getSubCategories(_selectedCategoryId);
    }

    _selectedRackLocation     = p?['rackLocationName'] ?? p?['location'];
    _selectedZone             = p?['zone'];
    _selectedStorageCondition = p?['storageCondition'];
    _palletCtrl   = TextEditingController(text: p?['palletNumber'] ?? '');
    _shelfCtrl    = TextEditingController(text: p?['shelfNumber'] ?? '');
    _tempMinCtrl  = TextEditingController(text: (p?['tempMin'] ?? '').toString());
    _tempMaxCtrl  = TextEditingController(text: (p?['tempMax'] ?? '').toString());

    _weightCtrl   = TextEditingController(text: (p?['weight'] ?? '').toString());
    _lengthCtrl   = TextEditingController(text: (p?['length'] ?? '').toString());
    _widthCtrl    = TextEditingController(text: (p?['width'] ?? '').toString());
    _heightCtrl   = TextEditingController(text: (p?['height'] ?? '').toString());
    _colorCtrl    = TextEditingController(text: p?['color'] ?? '');
    _materialCtrl = TextEditingController(text: p?['material'] ?? '');
    _finishCtrl   = TextEditingController(text: p?['finish'] ?? '');
    _selectedWeightUnit    = p?['weightUnitName'];
    _selectedDimensionUnit = p?['dimensionUnit'];
    _selectedSize          = p?['size'];

    _hasExpiry             = p?['hasExpiry'] ?? false;
    _isBatchManaged        = p?['isBatchManaged'] ?? false;
    _isSerialManaged       = p?['isSerialManaged'] ?? false;
    _isExpiryManaged       = p?['isExpiryManaged'] ?? false;
    _isBulkManaged         = p?['isBulkManaged'] ?? false;
    _hasIndividualTracking = p?['hasIndividualTracking'] ?? false;
    _bulkUnit              = p?['bulkUnit'] ?? 'Bale';
    _batchNumberCtrl       = TextEditingController(text: p?['batchNumber'] ?? '');
    _shelfLifeCtrl         = TextEditingController(text: (p?['shelfLife'] ?? '').toString());
    _defaultBatchQtyCtrl   = TextEditingController(text: (p?['defaultBatchQuantity'] ?? '').toString());
    if (p?['expiryDate'] != null) _expiryDate = DateTime.tryParse(p!['expiryDate']);
    if (p?['manufacturingDate'] != null) _manufacturingDate = DateTime.tryParse(p!['manufacturingDate']);

    _hsCodeCtrl         = TextEditingController(text: p?['hsCode'] ?? '');
    _stackingLimitCtrl  = TextEditingController(text: (p?['stackingLimit'] ?? '').toString());
    _unNumberCtrl       = TextEditingController(text: p?['unNumber'] ?? '');
    _handlingCtrl       = TextEditingController(text: p?['handlingInstructions'] ?? '');
    _warrantyPeriodCtrl = TextEditingController(text: (p?['warrantyPeriod'] ?? '').toString());
    _returnDaysCtrl     = TextEditingController(text: (p?['returnDays'] ?? '7').toString());
    _freightClassCtrl   = TextEditingController(text: p?['freightClass'] ?? '');
    _selectedShippingClass = p?['shippingClass'];
    _dangerousGoods     = p?['dangerousGoods'] ?? false;
    _isReturnable       = p?['isReturnable'] ?? true;
    _warrantyUnit       = p?['warrantyUnit'] ?? 'Months';
    _countryOfOrigin    = p?['countryOfOrigin'] ?? 'Pakistan';
    _notesCtrl          = TextEditingController(text: p?['notes'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _skuCtrl, _barcodeCtrl, _descCtrl, _tagsCtrl,
      _costCtrl, _sellCtrl, _landingCostCtrl, _taxRateCtrl,
      _stockCtrl, _minStockCtrl, _maxStockCtrl, _reorderPointCtrl, _leadTimeCtrl,
      _brandCtrl, _modelCtrl, _supplierSkuCtrl,
      _palletCtrl, _shelfCtrl, _tempMinCtrl, _tempMaxCtrl,
      _weightCtrl, _lengthCtrl, _widthCtrl, _heightCtrl,
      _colorCtrl, _materialCtrl, _finishCtrl,
      _batchNumberCtrl, _shelfLifeCtrl, _defaultBatchQtyCtrl,
      _hsCodeCtrl, _stackingLimitCtrl, _unNumberCtrl,
      _handlingCtrl, _warrantyPeriodCtrl, _returnDaysCtrl, _freightClassCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════

  InputDecoration _dec({String hint = '', IconData? icon, String? prefix, String? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
        prefixText: prefix,
        prefixIcon: icon != null ? Icon(icon, size: 16, color: kSubText) : null,
        suffixText: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: kDanger, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: kDanger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: kCardBg,
      );

  Widget _label(String text, {bool req = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          Text(text,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSubText)),
          if (req)
            Text(' *', style: TextStyle(fontSize: 12, color: kDanger, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _field(
          {required String label, bool req = false, required Widget child, double bottom = 12}) =>
      Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(label, req: req),
            child,
          ]));

  Widget _sectionHeader(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 14, top: 4),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 14, color: kPrimary)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
        ]),
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
        unique.any((i) => i[valueKey]?.toString() == value?.toString()) ? value : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? kCardBg : kBgLight,
          border: Border.all(
              color: errorText != null ? kDanger : Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: valid,
            hint: Text(hint, style: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13)),
            isExpanded: true,
            dropdownColor: kCardBg,
            icon: Icon(Icons.arrow_drop_down, color: kSubText, size: 20),
            onChanged: enabled ? onChanged : null,
            items: unique
                .map((item) => DropdownMenuItem<T>(
                      value: item[valueKey] as T,
                      child: Text(item[labelKey]?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black)),
                    ))
                .toList(),
          ),
        ),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(errorText, style: TextStyle(color: kDanger, fontSize: 11)),
        ),
    ]);
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
            onTap: () => Get.to(
              () => const SettingsScreen(),
              arguments: settingsCategory,
            ),
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
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valid,
          hint: Text(hint, style: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13)),
          isExpanded: true,
          dropdownColor: kCardBg,
          icon: Icon(Icons.arrow_drop_down, color: kSubText, size: 20),
          onChanged: onChanged,
          items: items
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.black))))
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
              color: value ? kPrimary.withOpacity(0.4) : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: value ? kPrimary : kSubText),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: value ? kPrimary : kSubText))),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ]),
      ),
    );
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
                colorScheme: ColorScheme.light(primary: kPrimary, onPrimary: Colors.white)),
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
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              value != null
                  ? '${value.day}/${value.month}/${value.year}'
                  : label,
              style: TextStyle(
                  fontSize: 13,
                  color: value != null ? kText : kSubText.withOpacity(0.5))),
          Row(children: [
            if (value != null)
              GestureDetector(
                  onTap: () => setState(() => onChanged(null)),
                  child: Icon(Icons.close, size: 14, color: kSubText)),
            const SizedBox(width: 4),
            Icon(Icons.calendar_today, size: 15, color: kSubText),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case 0: return _tab0Basic();
      case 1: return _tab1Pricing();
      case 2: return _tab2Category();
      case 3: return _tab3Warehouse();
      case 4: return _tab4Physical();
      case 5: return _tab5Expiry();
      case 6: return _tab6Shipping();
      case 7: return _tab7Media();
      case 8: return _tab8Custom();
      default: return _tab0Basic();
    }
  }

  Widget _tab0Basic() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Basic Information', Icons.inventory_2_outlined),
        _field(
            label: 'Product Name',
            req: true,
            child: TextFormField(
              controller: _nameCtrl,
              decoration: _dec(hint: 'e.g., Rice 5kg', icon: Icons.inventory_2_outlined),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            )),
        _field(
            label: 'SKU',
            req: true,
            child: TextFormField(
              controller: _skuCtrl,
              decoration: _dec(hint: 'SKU-001', icon: Icons.qr_code_2).copyWith(
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _skuCtrl.text = _c.generateSku()),
                  child: Icon(Icons.refresh_rounded, size: 18, color: kPrimary),
                ),
              ),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            )),
        _field(
            label: 'Barcode (Optional)',
            child: TextFormField(
              controller: _barcodeCtrl,
              decoration: _dec(
                  hint: 'Enter barcode or leave blank to use SKU',
                  icon: Icons.barcode_reader),
              style: const TextStyle(fontSize: 13, color: Colors.black),
            )),
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Leave blank — SKU will be used as barcode automatically',
                style: TextStyle(fontSize: 10, color: kSubText.withOpacity(0.6)))),
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
            )),
        _field(
            label: 'Tags (Optional)',
            child: TextFormField(
              controller: _tagsCtrl,
              decoration: _dec(hint: 'electronics, sale, imported', icon: Icons.label_outline),
              style: const TextStyle(fontSize: 13, color: Colors.black),
            )),
        Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Comma separated tags',
                style: TextStyle(fontSize: 10, color: kSubText.withOpacity(0.6)))),
      ]);

  Widget _tab1Pricing() {
    String sym;
    try {
      sym = _c.getCurrencySymbol();
    } catch (_) {
      sym = 'Rs';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          )),
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
          )),
      _field(
          label: 'Landing Cost (Optional)',
          child: TextFormField(
            controller: _landingCostCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: '0.00', prefix: '$sym '),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          )),
      _field(
          label: 'Currency',
          child: _simpleDropdown(
            hint: 'Select Currency',
            value: _currency,
            items: ['PKR', 'USD', 'EUR', 'GBP', 'AUD'],
            onChanged: (v) => setState(() => _currency = v ?? 'PKR'),
          )),
      _sectionHeader('Tax', Icons.receipt_long_outlined),
      _field(
          label: 'Tax Rate (%)',
          child: TextFormField(
            controller: _taxRateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: '0', suffix: '%'),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          )),
      _dropdownWithAdd<String>(
        label: 'Tax Type',
        hint: 'Select Tax Type',
        value: _selectedTaxType,
        items: _taxTypes,
        labelKey: 'name',
        valueKey: 'name',
        onChanged: (v) => setState(() => _selectedTaxType = v),
        settingsCategory: 'taxType',
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
          )),
      _field(
          label: 'Minimum Stock',
          child: TextFormField(
              controller: _minStockCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(hint: '5'),
              style: const TextStyle(fontSize: 13, color: Colors.black))),
      _field(
          label: 'Maximum Stock',
          child: TextFormField(
              controller: _maxStockCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(hint: '100'),
              style: const TextStyle(fontSize: 13, color: Colors.black))),
      _field(
          label: 'Reorder Point',
          child: TextFormField(
              controller: _reorderPointCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(hint: '50'),
              style: const TextStyle(fontSize: 13, color: Colors.black))),
    ]);
  }

  Widget _tab2Category() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Category & Supplier', Icons.category_outlined),
        _label('Category', req: true),
        const SizedBox(height: 5),
        _dropdown<String>(
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
        const SizedBox(height: 12),
        _field(
            label: 'Sub-Category',
            child: _dropdown<String>(
              hint: _subCategories.isEmpty ? 'No sub-categories available' : 'Select Sub-Category',
              value: _selectedSubCategoryId,
              items: _subCategories,
              labelKey: 'name',
              valueKey: 'id',
              enabled: _subCategories.isNotEmpty,
              onChanged: (v) => setState(() => _selectedSubCategoryId = v),
            )),
        _field(
            label: 'Brand',
            child: TextFormField(
                controller: _brandCtrl,
                decoration: _dec(hint: 'e.g., Nestlé', icon: Icons.branding_watermark_outlined),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(
            label: 'Model Number',
            child: TextFormField(
                controller: _modelCtrl,
                decoration: _dec(hint: 'e.g., XR-2000', icon: Icons.numbers),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _sectionHeader('Supplier', Icons.local_shipping_outlined),
        _field(
            label: 'Supplier',
            child: _dropdown<String>(
              hint: 'Select Supplier',
              value: _selectedSupplierId,
              items: _suppliers,
              labelKey: 'name',
              valueKey: 'id',
              onChanged: (v) => setState(() => _selectedSupplierId = v),
            )),
        _field(
            label: 'Supplier SKU',
            child: TextFormField(
                controller: _supplierSkuCtrl,
                decoration: _dec(hint: 'Supplier SKU'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(
            label: 'Lead Time (Days)',
            child: TextFormField(
                controller: _leadTimeCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec(hint: '7'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
      ]);

  Widget _tab3Warehouse() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(
            label: 'Shelf Number',
            child: TextFormField(
                controller: _shelfCtrl,
                decoration: _dec(hint: 'Shelf #'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
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
            )),
        Row(children: [
          Expanded(
              child: _field(
                  label: 'Temp Min (°C)',
                  child: TextFormField(
                      controller: _tempMinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(hint: '0'),
                      style: const TextStyle(fontSize: 13, color: Colors.black)))),
          const SizedBox(width: 12),
          Expanded(
              child: _field(
                  label: 'Temp Max (°C)',
                  child: TextFormField(
                      controller: _tempMaxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(hint: '40'),
                      style: const TextStyle(fontSize: 13, color: Colors.black)))),
        ]),
      ]);

  Widget _tab4Physical() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Weight & Dimensions', Icons.straighten),
        _field(
            label: 'Weight',
            child: TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(hint: '0.0'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
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
        Row(children: [
          Expanded(
              child: _field(
                  label: 'Length',
                  child: TextFormField(
                      controller: _lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(hint: '0.0'),
                      style: const TextStyle(fontSize: 13, color: Colors.black)))),
          const SizedBox(width: 12),
          Expanded(
              child: _field(
                  label: 'Width',
                  child: TextFormField(
                      controller: _widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec(hint: '0.0'),
                      style: const TextStyle(fontSize: 13, color: Colors.black)))),
        ]),
        _field(
            label: 'Height',
            child: TextFormField(
                controller: _heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(hint: '0.0'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _sectionHeader('Variants & Material', Icons.palette_outlined),
        _field(
            label: 'Color',
            child: TextFormField(
                controller: _colorCtrl,
                decoration: _dec(hint: 'e.g., Red', icon: Icons.circle_outlined),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
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
                style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(
            label: 'Finish',
            child: TextFormField(
                controller: _finishCtrl,
                decoration: _dec(hint: 'e.g., Matte, Glossy'),
                style: const TextStyle(fontSize: 13, color: Colors.black))),
      ]);

  Widget _tab5Expiry() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Tracking Flags', Icons.track_changes_outlined),
        _toggle(label: 'Has Expiry', value: _hasExpiry, icon: Icons.event_busy_outlined, onChanged: (v) => _hasExpiry = v),
        const SizedBox(height: 8),
        _toggle(label: 'Batch Managed', value: _isBatchManaged, icon: Icons.layers_outlined, onChanged: (v) => _isBatchManaged = v),
        const SizedBox(height: 8),
        _toggle(label: 'Serial Managed', value: _isSerialManaged, icon: Icons.pin_outlined, onChanged: (v) => _isSerialManaged = v),
        const SizedBox(height: 8),
        _toggle(label: 'Expiry Managed', value: _isExpiryManaged, icon: Icons.timer_outlined, onChanged: (v) => _isExpiryManaged = v),
        const SizedBox(height: 16),
        _sectionHeader('Dates & Batch', Icons.calendar_month_outlined),
        _label('Expiry Date (Optional)'),
        const SizedBox(height: 5),
        _datePicker(label: 'Select expiry date', value: _expiryDate, onChanged: (d) => _expiryDate = d),
        const SizedBox(height: 12),
        _label('Manufacturing Date (Optional)'),
        const SizedBox(height: 5),
        _datePicker(label: 'Select manufacturing date', value: _manufacturingDate, onChanged: (d) => _manufacturingDate = d),
        const SizedBox(height: 12),
        _field(label: 'Batch Number', child: TextFormField(controller: _batchNumberCtrl, decoration: _dec(hint: 'BATCH-001'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(label: 'Shelf Life (Days)', child: TextFormField(controller: _shelfLifeCtrl, keyboardType: TextInputType.number, decoration: _dec(hint: '365'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _sectionHeader('Bulk Management', Icons.inventory_2_outlined),
        _toggle(label: 'Bulk Managed', value: _isBulkManaged, icon: Icons.category_outlined, onChanged: (v) => _isBulkManaged = v),
        const SizedBox(height: 8),
        _toggle(label: 'Individual Tracking', value: _hasIndividualTracking, icon: Icons.person_outline, onChanged: (v) => _hasIndividualTracking = v),
        const SizedBox(height: 12),
        _field(label: 'Bulk Unit', child: _simpleDropdown(hint: 'Select bulk unit', value: _bulkUnit, items: ['Bale', 'Box', 'Roll', 'Pallet'], onChanged: (v) => setState(() => _bulkUnit = v ?? 'Bale'))),
        _field(label: 'Default Batch Quantity', child: TextFormField(controller: _defaultBatchQtyCtrl, keyboardType: TextInputType.number, decoration: _dec(hint: '50'), style: const TextStyle(fontSize: 13, color: Colors.black))),
      ]);

  Widget _tab6Shipping() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Shipping Info', Icons.local_shipping_outlined),
        _field(label: 'HS Code', child: TextFormField(controller: _hsCodeCtrl, decoration: _dec(hint: 'e.g., 5201.00.00'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(label: 'Country of Origin', child: _simpleDropdown(hint: 'Select Country', value: _countryOfOrigin, items: ['Pakistan', 'China', 'USA', 'Turkey', 'India', 'Bangladesh'], onChanged: (v) => setState(() => _countryOfOrigin = v ?? 'Pakistan'))),
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
        _field(label: 'Freight Class', child: TextFormField(controller: _freightClassCtrl, decoration: _dec(hint: 'Freight class'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(label: 'Stacking Limit', child: TextFormField(controller: _stackingLimitCtrl, keyboardType: TextInputType.number, decoration: _dec(hint: '5'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _sectionHeader('Safety & Returns', Icons.shield_outlined),
        _toggle(label: 'Dangerous Goods', value: _dangerousGoods, icon: Icons.warning_amber_outlined, onChanged: (v) => _dangerousGoods = v),
        const SizedBox(height: 12),
        _field(label: 'UN Number', child: TextFormField(controller: _unNumberCtrl, decoration: _dec(hint: 'UN #'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _field(label: 'Handling Instructions', child: TextFormField(controller: _handlingCtrl, decoration: _dec(hint: 'Special handling instructions...'), style: const TextStyle(fontSize: 13, color: Colors.black))),
        _sectionHeader('Warranty & Returns', Icons.verified_outlined),
        Row(children: [
          Expanded(child: _field(label: 'Warranty Period', child: TextFormField(controller: _warrantyPeriodCtrl, keyboardType: TextInputType.number, decoration: _dec(hint: '12'), style: const TextStyle(fontSize: 13, color: Colors.black)))),
          const SizedBox(width: 12),
          Expanded(child: _field(label: 'Warranty Unit', child: _simpleDropdown(hint: 'Unit', value: _warrantyUnit, items: ['Days', 'Months', 'Years'], onChanged: (v) => setState(() => _warrantyUnit = v ?? 'Months')))),
        ]),
        _toggle(label: 'Is Returnable', value: _isReturnable, icon: Icons.undo_outlined, onChanged: (v) => _isReturnable = v),
        const SizedBox(height: 12),
        _field(label: 'Return Days', child: TextFormField(controller: _returnDaysCtrl, keyboardType: TextInputType.number, decoration: _dec(hint: '7'), style: const TextStyle(fontSize: 13, color: Colors.black))),
      ]);

  Widget _tab7Media() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Media', Icons.image_outlined),
        _mediaPlaceholder(Icons.image_outlined, 'Product Images', 'Image upload available in web version'),
        const SizedBox(height: 12),
        _mediaPlaceholder(Icons.picture_as_pdf_outlined, 'Specification Sheet (PDF)', 'PDF upload available in web version'),
      ]);

  Widget _mediaPlaceholder(IconData icon, String title, String sub) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withOpacity(0.3))),
        child: Column(children: [
          Icon(icon, size: 32, color: kSubText.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 13, color: kSubText)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: kSubText.withOpacity(0.6))),
        ]),
      );

  Widget _tab8Custom() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Additional Notes', Icons.note_outlined),
        _field(label: 'Notes', child: TextFormField(controller: _notesCtrl, maxLines: 5, decoration: _dec(hint: 'Enter any additional notes...'), style: const TextStyle(fontSize: 13, color: Colors.black))),
      ]);

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
      'currency': _currency,
      'taxRate': _taxRateCtrl.text.trim(),
      'currentStock': _stockCtrl.text.trim(),
      'minimumStock': _minStockCtrl.text.trim(),
      'maximumStock': _maxStockCtrl.text.trim(),
      'reorderPoint': _reorderPointCtrl.text.trim(),
      'leadTime': _leadTimeCtrl.text.trim(),
      'brandName': _brandCtrl.text.trim(),
      'modelNumber': _modelCtrl.text.trim(),
      'supplierSku': _supplierSkuCtrl.text.trim(),
      'palletNumber': _palletCtrl.text.trim(),
      'shelfNumber': _shelfCtrl.text.trim(),
      'tempMin': _tempMinCtrl.text.trim(),
      'tempMax': _tempMaxCtrl.text.trim(),
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
      'shelfLife': _shelfLifeCtrl.text.trim(),
      'defaultBatchQuantity': _defaultBatchQtyCtrl.text.trim(),
      'hsCode': _hsCodeCtrl.text.trim(),
      'countryOfOrigin': _countryOfOrigin,
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
      if (_selectedProductType != null) 'productType': _selectedProductType,
      if (_selectedTaxType != null) 'taxType': _selectedTaxType,
      if (_selectedStockUnit != null) 'stockUnit': _selectedStockUnit,
      if (_selectedSupplierId != null) 'supplierId': _selectedSupplierId,
      if (_selectedSubCategoryId != null) 'subCategoryId': _selectedSubCategoryId,
      if (_selectedRackLocation != null) 'rackLocationName': _selectedRackLocation,
      if (_selectedZone != null) 'zone': _selectedZone,
      if (_selectedStorageCondition != null) 'storageCondition': _selectedStorageCondition,
      if (_selectedWeightUnit != null) 'weightUnitName': _selectedWeightUnit,
      if (_selectedDimensionUnit != null) 'dimensionUnit': _selectedDimensionUnit,
      if (_selectedSize != null) 'size': _selectedSize,
      if (_selectedShippingClass != null) 'shippingClass': _selectedShippingClass,
      if (_expiryDate != null) 'expiryDate': _expiryDate!.toIso8601String(),
      if (_manufacturingDate != null) 'manufacturingDate': _manufacturingDate!.toIso8601String(),
    };

    bool success;
    if (_isEditing) {
      success = await _c.updateProduct(
          widget.editingProduct!['_id'] ?? widget.editingProduct!['id'] ?? '', payload);
    } else {
      success = await _c.createProduct(payload);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      Get.snackbar(
        _isEditing ? 'Updated' : 'Created',
        _isEditing ? 'Product updated successfully' : 'Product created successfully',
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
        title: Text(
          _isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
              : TextButton(
                  onPressed: _submit,
                  child: Text(
                    _isEditing ? 'Update' : 'Save',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
        ],
      ),
      body: Column(children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? kPrimary : kPrimary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(tab.icon, size: 13, color: active ? Colors.black : kSubText),
                        const SizedBox(width: 5),
                        Text(tab.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? Colors.black : kSubText)),
                      ]),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(children: [
            if (_activeTab > 0) ...[
              Expanded(
                  child: OutlinedButton.icon(
                onPressed: _saving ? null : () => setState(() => _activeTab--),
                icon: const Icon(Icons.chevron_left, size: 16, color: Colors.black),
                label: const Text('Back', style: TextStyle(fontSize: 13, color: Colors.black)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: _activeTab < _productTabs.length - 1
                  ? ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_activeTab == 2 && _selectedCategoryId == null) {
                                setState(() => _categoryError = 'Please select a category');
                                return;
                              }
                              setState(() => _activeTab++);
                            },
                      icon: const Text('Next', style: TextStyle(fontSize: 13, color: Colors.black)),
                      label: const Icon(Icons.chevron_right, size: 16, color: Colors.black),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(_isEditing ? 'Update Product' : 'Save Product',
                              style: const TextStyle(fontSize: 13, color: Colors.black)),
                    ),
            ),
          ]),
        ),
      ]),
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
  const _MobileProductsList(
      {required this.controller, required this.onProductTap, required this.onAddProduct});

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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.inventory_2_outlined, size: 36, color: kPrimary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text('No products yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText)),
          const SizedBox(height: 6),
          Text('Tap + to add your first product',
              style: TextStyle(fontSize: 12, color: kSubText)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: widget.onAddProduct,
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text('Add Product',
                  style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ]));
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
          final price = widget.controller.formatCurrency((product['sellingPrice'] ?? 0.0).toDouble());

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
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_rounded, color: stockColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                                      fontFamily: 'monospace'),
                                ),
                              ),
                              if ((product['categoryName'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  product['categoryName'],
                                  style: TextStyle(fontSize: 11, color: kSubText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]
                            ]),
                            const SizedBox(height: 5),
                            Row(children: [
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
                                    color: kSubText),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      // Price + chevron
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kPrimary),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
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
                  child: CircularProgressIndicator(strokeWidth: 2))));
    }
    if (!widget.controller.hasMore.value && widget.controller.products.isNotEmpty) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
              child: Text('All products loaded',
                  style: TextStyle(fontSize: 12, color: kSubText.withOpacity(0.7)))));
    }
    return const SizedBox.shrink();
  }
}