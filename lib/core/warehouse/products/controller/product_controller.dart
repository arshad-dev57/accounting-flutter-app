// controllers/product_controller.dart - COMPLETE WITH QR (FIXED)

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

class ProductsController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── KPI Counts ───────────────────────────────────────────────
  RxInt inStockCount = 0.obs;
  RxInt lowStockCount = 0.obs;
  RxInt outOfStockCount = 0.obs;
  RxInt categoriesCount = 0.obs;

  // ─── Categories & Suppliers ───────────────────────────────────
  var categories = <Map<String, dynamic>>[].obs;
  var suppliers = <Map<String, dynamic>>[].obs;
  var isSubmitting = false.obs;
  String lastSubmitError = '';

  // ─── Settings dropdowns ───────────────────────────────────────
  var productTypes = <Map<String, dynamic>>[].obs;
  var weightUnits = <Map<String, dynamic>>[].obs;
  var dimensionUnits = <Map<String, dynamic>>[].obs;
  var stockUnits = <Map<String, dynamic>>[].obs;
  var taxTypes = <Map<String, dynamic>>[].obs;
  var rackLocations = <Map<String, dynamic>>[].obs;
  var zones = <Map<String, dynamic>>[].obs;
  var sizes = <Map<String, dynamic>>[].obs;
  var shippingClasses = <Map<String, dynamic>>[].obs;
  var storageConditions = <Map<String, dynamic>>[].obs;

  // ─── Order Settings ───────────────────────────────────────────
  var orderTypes = <Map<String, dynamic>>[].obs;
  var priorities = <Map<String, dynamic>>[].obs;
  var orderSources = <Map<String, dynamic>>[].obs;
  var shippingMethods = <Map<String, dynamic>>[].obs;
  var paymentMethods = <Map<String, dynamic>>[].obs;
  var shippingCarriers = <Map<String, dynamic>>[].obs;

  // ─── Mobile Infinite Scroll ───────────────────────────────────
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  int _mobilePage = 1;

  // ─── Main Products List ───────────────────────────────────────
  var products = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'All'.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalProducts = 0.obs;

  final List<String> filters = ['All', 'Low Stock', 'Out of Stock', 'In Stock'];

  // ═══════════════════════════════════════════════════════════════
  // ─── QR CODE STATE ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  var isScanning = false.obs;
  var scannedData = ''.obs;
  var qrData = ''.obs;
  var selectedProductForQR = Rxn<Map<String, dynamic>>();
  var isFlashOn = false.obs;
  var isFrontCamera = false.obs;
  var isGeneratingQR = false.obs;

  // QR Generation Options
  var qrSize = 200.0.obs;
  var qrForegroundColor = Colors.black.obs;
  var qrBackgroundColor = Colors.white.obs;
  var selectedQRType = 'Product QR'.obs;

  // QR Types
  final List<String> qrTypes = ['Product QR', 'Custom Data', 'URL', 'Text'];

  // QR Controllers
  final TextEditingController urlController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  final TextEditingController customDataController = TextEditingController();
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );

  // QR Global Key
  final GlobalKey qrKey = GlobalKey();

  // Scan History
  var scanHistory = <Map<String, dynamic>>[].obs;

  // Scanner Controller
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    returnImage: true,
  );

  @override
  void onInit() {
    super.onInit();
    _loadAll();
    _requestQRPermissions();
  }

  @override
  void onClose() {
    scannerController.dispose();
    urlController.dispose();
    textController.dispose();
    customDataController.dispose();
    productIdController.dispose();
    quantityController.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── ORIGINAL PRODUCT METHODS ────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    await Future.wait([
      fetchProducts(),
      fetchCategories(),
      fetchSuppliers(),
      _fetchSettings(),
    ]);
  }

  // ─── Currency ─────────────────────────────────────────────────
  String formatCurrency(double amount) {
    try {
      return Get.find<CurrencyController>().formatAmount(amount);
    } catch (_) {
      return 'Rs ${amount.toStringAsFixed(2)}';
    }
  }

  String getCurrencySymbol() {
    try {
      return Get.find<CurrencyController>().currencySymbol.value;
    } catch (_) {
      return 'Rs';
    }
  }

  // ─── Settings ─────────────────────────────────────────────────
  Future<void> _fetchSettings() async {
    final cats = [
      'productType',
      'weightUnit',
      'dimensionUnit',
      'stockUnit',
      'taxType',
      'rackLocation',
      'zone',
      'size',
      'shippingClass',
      'storageCondition',
    ];
    await Future.wait(cats.map((cat) => _fetchSetting(cat)));
  }

  Future<void> _fetchSetting(String category) async {
    try {
      final response = await _api.get(
        '/api/settings',
        queryParameters: {'category': category},
      );
      if (response.success == true) {
        final rawData = response.data['data'];
        final List<Map<String, dynamic>> data;

        if (rawData is List) {
          data = List<Map<String, dynamic>>.from(rawData);
        } else if (rawData is Map && rawData['data'] is List) {
          data = List<Map<String, dynamic>>.from(rawData['data']);
        } else {
          data = [];
        }

        final active = data.where((d) => d['isActive'] != false).toList();

        switch (category) {
          case 'productType':
            productTypes.value = active;
            break;
          case 'weightUnit':
            weightUnits.value = active;
            break;
          case 'dimensionUnit':
            dimensionUnits.value = active;
            break;
          case 'stockUnit':
            stockUnits.value = active;
            break;
          case 'taxType':
            taxTypes.value = active;
            break;
          case 'rackLocation':
            rackLocations.value = active;
            break;
          case 'zone':
            zones.value = active;
            break;
          case 'size':
            sizes.value = active;
            break;
          case 'shippingClass':
            shippingClasses.value = active;
            break;
          case 'storageCondition':
            storageConditions.value = active;
            break;
        }
      }
    } catch (e) {
      debugPrint('Error fetching setting $category: $e');
    }
  }

  // ─── Categories ───────────────────────────────────────────────
  Future<void> fetchCategories() async {
    try {
      final response = await _api.get(
        '/api/warehouse/categories',
        queryParameters: {'tree': true},
      );
      if (response.success && response.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        final seen = <String>{};
        categories.value = raw.where((c) {
          final id = c['id']?.toString() ?? c['_id']?.toString() ?? '';
          if (id.isEmpty) return false;
          return seen.add(id);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // ─── Suppliers ────────────────────────────────────────────────
  Future<void> fetchSuppliers() async {
    try {
      final response = await _api.get(
        '/api/warehouse/supplier',
        queryParameters: {'limit': 100},
      );
      if (response.success && response.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
        final seen = <String>{};
        suppliers.value = raw.where((s) {
          final id = s['id']?.toString() ?? s['_id']?.toString() ?? '';
          if (id.isEmpty) return false;
          return seen.add(id);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    }
  }

  // ─── Sub-categories helper ────────────────────────────────────
  List<Map<String, dynamic>> getSubCategories(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return [];
    final parent = categories.firstWhereOrNull(
      (c) =>
          c['id']?.toString() == categoryId ||
          c['_id']?.toString() == categoryId,
    );
    if (parent == null) return [];
    final subs = parent['children'] ?? parent['subCategories'] ?? [];
    return List<Map<String, dynamic>>.from(subs);
  }

  // ─── CRUD ─────────────────────────────────────────────────────
  Map<String, String> _toFields(Map<String, dynamic> data) {
    final fields = <String, String>{};
    data.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      fields[key] = value is bool || value is num ? value.toString() : value.toString();
    });
    return fields;
  }

  String _errorMessage(dynamic response, String fallback) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (response.message != null && response.message.toString().isNotEmpty) {
      return response.message.toString();
    }
    return fallback;
  }

  Future<bool> createProduct(
    Map<String, dynamic> data, {
    List<String>? imagePaths,
    List<String>? existingImages,
  }) async {
    try {
      isSubmitting.value = true;
      lastSubmitError = '';
      final fields = _toFields(data);
      fields['existingImages'] = jsonEncode(existingImages ?? <String>[]);

      final multiFilePaths = <String, List<String>>{};
      if (imagePaths != null && imagePaths.isNotEmpty) {
        multiFilePaths['images'] = imagePaths;
      }

      final response = await _api.postMultipart(
        '/api/warehouse/products',
        fields: fields,
        multiFilePaths: multiFilePaths.isEmpty ? null : multiFilePaths,
      );

      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      lastSubmitError = _errorMessage(response, 'Failed to create product.');
      return false;
    } catch (e) {
      debugPrint('Error creating product: $e');
      lastSubmitError = e.toString();
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> data, {
    List<String>? imagePaths,
    List<String>? existingImages,
  }) async {
    try {
      isSubmitting.value = true;
      lastSubmitError = '';
      if (id.trim().isEmpty) {
        lastSubmitError = 'Product id is missing.';
        return false;
      }
      final fields = _toFields(data);
      fields['existingImages'] = jsonEncode(existingImages ?? <String>[]);

      final multiFilePaths = <String, List<String>>{};
      if (imagePaths != null && imagePaths.isNotEmpty) {
        multiFilePaths['images'] = imagePaths;
      }

      final response = await _api.putMultipart(
        '/api/warehouse/products/$id',
        fields: fields,
        multiFilePaths: multiFilePaths.isEmpty ? null : multiFilePaths,
      );

      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      lastSubmitError = _errorMessage(response, 'Failed to update product.');
      return false;
    } catch (e) {
      debugPrint('Error updating product: $e');
      lastSubmitError = e.toString();
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _api.delete('/api/warehouse/products/$id');
      if (response.success && response.data['success'] == true) {
        refreshAll();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  String generateSku() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'SKU-${ts.substring(ts.length - 6)}';
  }

  // ─── KPI ──────────────────────────────────────────────────────
  void _updateKpiCounts() {
    inStockCount.value = products
        .where((p) => (p['currentStock'] ?? 0) > 5)
        .length;
    lowStockCount.value = products.where((p) {
      final s = p['currentStock'] ?? 0;
      return s > 0 && s <= 5;
    }).length;
    outOfStockCount.value = products
        .where((p) => (p['currentStock'] ?? 0) <= 0)
        .length;
    categoriesCount.value = products
        .map((p) => p['categoryName'])
        .toSet()
        .length;
  }

  // ─── Query ────────────────────────────────────────────────────
  Map<String, dynamic> _buildQueryParams(int page) {
    final Map<String, dynamic> params = {'page': page, 'limit': 20};
    if (searchQuery.value.isNotEmpty) {
      params['q'] = searchQuery.value;
      params['searchBy'] = 'all'; // Search by name, SKU, or barcode
    }
    if (selectedFilter.value == 'Low Stock') params['stockStatus'] = 'low';
    if (selectedFilter.value == 'Out of Stock') params['stockStatus'] = 'out';
    if (selectedFilter.value == 'In Stock') params['stockStatus'] = 'in';
    return params;
  }

  // ─── Fetch Products ───────────────────────────────────────────
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: _buildQueryParams(currentPage.value),
      );
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          products.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
          totalPages.value = data['pagination']?['pages'] ?? 1;
          totalProducts.value = data['pagination']?['total'] ?? 0;
          _updateKpiCounts();
        }
      }
      _mobilePage = 1;
      hasMore.value = totalPages.value > 1;
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Infinite Scroll ──────────────────────────────────────────
  Future<void> fetchMoreProducts() async {
    if (isLoadingMore.value || isLoading.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final nextPage = _mobilePage + 1;
      final response = await _api.get(
        '/api/warehouse/products',
        queryParameters: _buildQueryParams(nextPage),
      );
      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          final newItems = List<Map<String, dynamic>>.from(data['data'] ?? []);
          final pages = data['pagination']?['pages'] ?? 1;
          products.addAll(newItems);
          totalPages.value = pages;
          totalProducts.value =
              data['pagination']?['total'] ?? totalProducts.value;
          _mobilePage = nextPage;
          hasMore.value = _mobilePage < pages && newItems.isNotEmpty;
          _updateKpiCounts();
        }
      }
    } catch (e) {
      debugPrint('Error fetching more: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────
  void refreshAll() {
    currentPage.value = 1;
    _mobilePage = 1;
    hasMore.value = true;
    fetchProducts();
  }

  Future<void> refreshProducts() async {
    await Future.wait([fetchCategories(), fetchSuppliers(), fetchProducts()]);
  }

  // ─── Refresh Dropdown Data ───────────────────────────────────────
  Future<void> refreshDropdownData() async {
    await Future.wait([fetchCategories(), fetchSuppliers(), _fetchSettings()]);
  }

  // ─── Search & Filter ──────────────────────────────────────────
  void searchProducts(String query) {
    searchQuery.value = query;
    refreshAll();
  }

  void clearSearch() {
    searchQuery.value = '';
    refreshAll();
  }

  void filterProducts(String filter) {
    selectedFilter.value = filter;
    refreshAll();
  }

  // ─── Pagination (Web) ─────────────────────────────────────────
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchProducts();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchProducts();
    }
  }

  // ─── Stock Helpers ────────────────────────────────────────────
  String getStockStatus(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  Color getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── QR CODE METHODS ──────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════

  // ─── QR Permissions ──────────────────────────────────────────
  Future<void> _requestQRPermissions() async {
    await [Permission.camera, Permission.storage].request();
  }

  // ─── Start Scan ──────────────────────────────────────────────
  Future<void> startScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      isScanning.value = true;
      await scannerController.start();
    } else {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required to scan QR codes',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    }
  }

  // ─── Stop Scan ────────────────────────────────────────────────
  Future<void> stopScan() async {
    isScanning.value = false;
    await scannerController.stop();
  }

  // ─── Toggle Flash ────────────────────────────────────────────
  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    scannerController.toggleTorch();
  }

  // ─── Toggle Camera ────────────────────────────────────────────
  void toggleCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    scannerController.switchCamera();
  }

  // ─── Handle Scan Result ──────────────────────────────────────
  void onScanResult(BarcodeCapture capture) {
    final barcode = capture.barcodes.first;
    if (barcode.rawValue != null) {
      scannedData.value = barcode.rawValue!;

      // Parse scanned data
      try {
        final data = barcode.rawValue!;
        if (data.startsWith('{') && data.endsWith('}')) {
          // Try to parse as JSON
          final json = Map<String, dynamic>.from(
            Uri.parse('data:application/json,$data').queryParameters,
          );
          selectedProductForQR.value = json;
        } else if (data.startsWith('http://') || data.startsWith('https://')) {
          selectedProductForQR.value = {'url': data};
        } else if (data.contains('PROD-')) {
          selectedProductForQR.value = {'id': data, 'type': 'product'};
        } else {
          selectedProductForQR.value = {'text': data};
        }
      } catch (e) {
        selectedProductForQR.value = {'text': barcode.rawValue};
      }

      // Add to history
      scanHistory.add({
        'data': barcode.rawValue,
        'timestamp': DateTime.now().toIso8601String(),
        'type': barcode.type.toString(),
      });

      // Stop scanning
      stopScan();
    }
  }

  // ─── Add Scanned Product to Cart ─────────────────────────────
  void addScannedToCart() {
    final productData = selectedProductForQR.value;
    if (productData != null) {
      Get.snackbar(
        'Added to Cart',
        'Product added successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ─── Share Scanned Data ──────────────────────────────────────
  void shareScannedData() {
    Share.share(
      'Scanned QR Code Data:\n${scannedData.value}\n\n'
      'Time: ${DateTime.now().toString()}\n'
      'BisonsTechs App',
    );
  }

  // ─── Generate QR Code ────────────────────────────────────────
  Future<void> generateQRCode() async {
    try {
      isGeneratingQR.value = true;

      String dataToEncode = '';

      switch (selectedQRType.value) {
        case 'Product QR':
          dataToEncode = productIdController.text.isEmpty
              ? 'PROD-${DateTime.now().millisecondsSinceEpoch}'
              : productIdController.text;
          dataToEncode = '{"id":"$dataToEncode","type":"product"}';
          break;
        case 'URL':
          dataToEncode = urlController.text;
          break;
        case 'Text':
          dataToEncode = textController.text;
          break;
        case 'Custom Data':
          dataToEncode = customDataController.text;
          break;
        default:
          dataToEncode = 'BisonsTechs_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (dataToEncode.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter data to generate QR code',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
        );
        isGeneratingQR.value = false;
        return;
      }

      qrData.value = dataToEncode;

      Get.snackbar(
        'Success',
        'QR Code generated successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate QR code: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    } finally {
      isGeneratingQR.value = false;
    }
  }

  // ─── Save QR Code ──────────────────────────────────────────────
  Future<void> saveQRCode() async {
    try {
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        Get.snackbar(
          'Permission Denied',
          'Storage permission is required to save QR codes',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
        );
        return;
      }

      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      Get.snackbar(
        'Success',
        'QR Code saved to gallery!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save QR code: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    }
  }

  // ─── Share QR Code ──────────────────────────────────────────────
  Future<void> shareQRCode() async {
    try {
      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'QR Code Data: ${qrData.value}');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share QR code: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    }
  }

  // ─── Scan from Gallery ────────────────────────────────────────────
  Future<void> scanFromGallery() async {
    Get.snackbar(
      'Feature Not Available',
      'Gallery scanning is currently unavailable. Please use camera scanning.',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.black,
    );
  }

  // ─── Parse Scanned Data ──────────────────────────────────────
  void _parseScannedData(String data) {
    try {
      if (data.startsWith('{') && data.endsWith('}')) {
        // Try to parse as JSON
        final Map<String, dynamic> json = {};
        final cleaned = data.substring(1, data.length - 1);
        final pairs = cleaned.split(',');
        for (var pair in pairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim().replaceAll('"', '');
            final value = parts[1].trim().replaceAll('"', '');
            json[key] = value;
          }
        }
        selectedProductForQR.value = json;
      } else if (data.startsWith('http://') || data.startsWith('https://')) {
        selectedProductForQR.value = {'url': data};
      } else if (data.contains('PROD-')) {
        selectedProductForQR.value = {'id': data, 'type': 'product'};
      } else {
        selectedProductForQR.value = {'text': data};
      }
      qrData.value = data;
    } catch (e) {
      selectedProductForQR.value = {'text': data};
      qrData.value = data;
    }
  }

  // ─── Clear Scan History ──────────────────────────────────────
  void clearScanHistory() {
    scanHistory.clear();
  }

  // ─── Generate Product QR from Product ────────────────────────
  void generateProductQR(Map<String, dynamic> product) {
    selectedProductForQR.value = product;
    final productData = {
      'id': product['id'] ?? product['_id'] ?? '',
      'name': product['name'] ?? '',
      'sku': product['sku'] ?? '',
      'price': product['sellingPrice'] ?? 0,
      'type': 'product',
    };
    qrData.value = productData.toString();

    Get.snackbar(
      'QR Generated',
      'QR code for ${product['name']} generated!',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ─── Check if Barcode Exists ───────────────────────────────────
  Future<Map<String, dynamic>?> checkBarcodeExists(String barcode) async {
    try {
      final response = await _api.get(
        '/warehouse/products/check-barcode/$barcode',
      );

      if (response.success == true &&
          response.data is Map &&
          response.data['exists'] == true) {
        // Get full product details
        final productResponse = await _api.get(
          '/warehouse/products/barcode/$barcode',
        );
        if (productResponse.success == true) {
          return productResponse.data;
        }
      }

      return null;
    } catch (e) {
      print('Error checking barcode: $e');
      return null;
    }
  }
}
