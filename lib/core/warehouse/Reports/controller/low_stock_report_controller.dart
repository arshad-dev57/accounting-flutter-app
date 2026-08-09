// lib/core/warehouse/reports/controller/low_stock_report_controller.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/model/product_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class LowStockReportController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<ProductModel> lowStockProducts = <ProductModel>[].obs;

  // Summary stats
  final RxInt totalLowStock = 0.obs;
  final RxInt totalProducts = 0.obs;
  final RxInt criticalCount = 0.obs;
  final RxInt lowCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      final response = await _apiClient.get(
        '/api/warehouse/reports/low-stock',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'];

        // Parse summary stats
        totalProducts.value = data['summary']['totalProducts'] ?? 0;
        totalLowStock.value = data['summary']['lowStockCount'] ?? 0;
        criticalCount.value = data['summary']['criticalCount'] ?? 0;
        lowCount.value = data['summary']['lowCount'] ?? 0;

        // Parse low stock products
        final lowStockList = data['lowStockProducts'] as List;
        lowStockProducts.value = lowStockList
            .map((item) => ProductModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error loading low stock data: $e');
    } finally {
      isLoading.value = false;
    }
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

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(),
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
          'low_stock_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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

  Future<Uint8List> _generatePdfBytes() async {
    final branding = await PdfBrandingBundle.load();
    final pdf = pw.Document();

    // Safe data
    final totalLowStockValue = totalLowStock.value;
    final criticalCountValue = criticalCount.value;
    final lowCountValue = lowCount.value;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => branding.buildHeader(
          reportTitle: 'Low Stock Report',
        ),
        footer: (ctx) => branding.buildFooter(ctx),
        build: (context) => [
              // Summary Cards
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor(
                    branding.accent.red,
                    branding.accent.green,
                    branding.accent.blue,
                    0.06,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor(
                      branding.accent.red,
                      branding.accent.green,
                      branding.accent.blue,
                      0.35,
                    ),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Low Stock',
                          totalLowStockValue.toString(),
                        ),
                        _buildSummaryItem(
                          'Critical (Out of Stock)',
                          criticalCountValue.toString(),
                        ),
                        _buildSummaryItem(
                          'Low Stock',
                          lowCountValue.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Products Table Header
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
                        'Product',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'SKU',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Stock',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Min',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Need',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Status',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Data
              ...lowStockProducts.map((product) {
                final needed = product.minimumStock - product.currentStock;
                final isOutOfStock = product.currentStock <= 0;
                final status = isOutOfStock ? 'Out of Stock' : 'Low Stock';
                final statusColor = isOutOfStock
                    ? PdfColors.red700
                    : PdfColors.orange700;

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
                          product.name,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          product.sku,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          product.currentStock.toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          product.minimumStock.toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          needed.toString(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: statusColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            status,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              branding.buildSignatureBlock(),
        ],
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
