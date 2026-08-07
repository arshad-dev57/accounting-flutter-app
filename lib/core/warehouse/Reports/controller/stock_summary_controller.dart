// lib/core/warehouse/reports/controller/stock_summary_controller.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class StockSummaryController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<Map<String, dynamic>> categorySummary =
      <Map<String, dynamic>>[].obs;

  // Summary stats
  final RxInt totalProducts = 0.obs;
  final RxDouble totalStockValue = 0.0.obs;
  final RxDouble averagePrice = 0.0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxInt outOfStockCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      final response = await _apiClient.get(
        '/api/warehouse/products',
        queryParameters: {'limit': 1000},
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as List;
        products.value = data
            .map((item) => ProductModel.fromJson(item))
            .toList();

        _calculateSummary();
        _calculateCategorySummary();
      }
    } catch (e) {
      print('Error loading stock summary: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSummary() {
    totalProducts.value = products.length;

    double totalValue = 0;
    int lowStock = 0;
    int outOfStock = 0;
    double totalPrice = 0;

    for (var product in products) {
      final stock = product.currentStock ?? 0;
      final price = product.sellingPrice ?? 0;

      totalValue += stock * price;
      totalPrice += price;

      if (stock <= 0) {
        outOfStock++;
      } else if (stock <= (product.minimumStock ?? 5)) {
        lowStock++;
      }
    }

    totalStockValue.value = totalValue;
    lowStockCount.value = lowStock;
    outOfStockCount.value = outOfStock;
    averagePrice.value = products.isNotEmpty ? totalPrice / products.length : 0;
  }

  void _calculateCategorySummary() {
    final Map<String, Map<String, dynamic>> categoryMap = {};

    for (var product in products) {
      final categoryName = product.categoryName ?? 'Uncategorized';

      if (!categoryMap.containsKey(categoryName)) {
        categoryMap[categoryName] = {
          'name': categoryName,
          'count': 0,
          'value': 0.0,
          'color': _getCategoryColor(categoryMap.length),
        };
      }

      categoryMap[categoryName]!['count'] =
          categoryMap[categoryName]!['count'] + 1;
      categoryMap[categoryName]!['value'] =
          (categoryMap[categoryName]!['value'] ?? 0.0) +
          ((product.currentStock ?? 0) * (product.sellingPrice ?? 0));
    }

    categorySummary.value = categoryMap.values.toList();
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
      const Color(0xFFF39C12),
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
      const Color(0xFF34495E),
    ];
    return colors[index % colors.length];
  }

  String getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  String formatCurrency(double value) {
    final currencyController = Get.find<CurrencyController>();
    return currencyController.formatAmount(value);
  }

  // ─── PDF Export ──────────────────────────────────────────────────────

  Future<void> exportToPdf() async {
    if (isExporting.value) return;

    try {
      isExporting.value = true;

      // Show loading dialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingAnimationWidget.waveDots(color: kPrimary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Generating PDF...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kText,
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final bytes = await _generatePdfBytes();

      final fileName =
          'stock_summary_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }

      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.success(kSuccess, 'Success', 'PDF exported successfully!');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('PDF Export Error: $e');
      AppSnackbar.error(
        kDanger,
        'Error',
        'Failed to export PDF: ${e.toString()}',
      );
    } finally {
      isExporting.value = false;
    }
  }

  // ✅ Simplified PDF generation - returns bytes directly
  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();

    // Safe data
    final totalProductsValue = totalProducts.value;
    final totalStockValueValue = totalStockValue.value;
    final averagePriceValue = averagePrice.value;
    final lowStockCountValue = lowStockCount.value;
    final outOfStockCountValue = outOfStockCount.value;

    // Safe category data
    final safeCategories = categorySummary.map((cat) {
      return {
        'name': cat['name']?.toString() ?? 'Uncategorized',
        'count': (cat['count'] ?? 0) as int,
        'value': (cat['value'] ?? 0.0) as double,
      };
    }).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Stock Summary Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo800,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo800,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'BisonsTechs',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Summary Cards
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Products',
                          totalProductsValue.toString(),
                        ),
                        _buildSummaryItem(
                          'Total Stock Value',
                          formatCurrency(totalStockValueValue),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Average Price',
                          formatCurrency(averagePriceValue),
                        ),
                        _buildSummaryItem(
                          'Low Stock',
                          lowStockCountValue.toString(),
                        ),
                        _buildSummaryItem(
                          'Out of Stock',
                          outOfStockCountValue.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Category Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Category',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Items',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Value',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Data
              ...safeCategories.map((cat) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          cat['name'] as String,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          (cat['count'] as int).toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          formatCurrency(cat['value'] as double),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Total Row
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        totalProductsValue.toString(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        formatCurrency(totalStockValueValue),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by BisonsTechs',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo700,
          ),
        ),
      ],
    );
  }
}
