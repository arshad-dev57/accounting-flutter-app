// lib/core/warehouse/reports/controller/expiry_report_controller.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/warehouse/products/model/product_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class ExpiryReportController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  final RxList<ProductModel> expiringSoon = <ProductModel>[].obs;
  final RxList<ProductModel> expired = <ProductModel>[].obs;
  final RxList<ProductModel> productsWithExpiry = <ProductModel>[].obs;

  final RxInt totalProducts = 0.obs;
  final RxInt expiringSoonCount = 0.obs;
  final RxInt expiredCount = 0.obs;
  final RxInt noExpiryCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;

      final response = await _apiClient.get(
        '/api/warehouse/reports/expiry',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'];
        
        // Parse summary stats
        totalProducts.value = data['summary']['totalProducts'] ?? 0;
        expiredCount.value = data['summary']['expiredCount'] ?? 0;
        expiringSoonCount.value = data['summary']['expiringSoonCount'] ?? 0;
        noExpiryCount.value = data['summary']['noExpiryCount'] ?? 0;

        // Parse product lists
        final expiredList = data['expired'] as List;
        final expiringSoonList = data['expiringSoon'] as List;
        final allExpiryList = data['productsWithExpiry'] as List;

        expired.value = expiredList
            .map((item) => ProductModel.fromJson(item))
            .toList();
        expiringSoon.value = expiringSoonList
            .map((item) => ProductModel.fromJson(item))
            .toList();
        productsWithExpiry.value = allExpiryList
            .map((item) => ProductModel.fromJson(item))
            .toList();
        
        // Also populate the full products list for compatibility
        products.value = productsWithExpiry;
      }
    } catch (e) {
      print('Error loading expiry data: $e');
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
          'expiry_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
    final pdf = pw.Document();

    // Safe data
    final totalProductsValue = totalProducts.value;
    final expiredCountValue = expiredCount.value;
    final expiringSoonCountValue = expiringSoonCount.value;
    final noExpiryCountValue = noExpiryCount.value;

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
                        'Expiry Report',
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
                      'LedgerPro',
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
                  color: PdfColors.orange50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.orange200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Products',
                      totalProductsValue.toString(),
                    ),
                    _buildSummaryItem(
                      'Expired',
                      expiredCountValue.toString(),
                      PdfColors.red700,
                    ),
                    _buildSummaryItem(
                      'Expiring Soon',
                      expiringSoonCountValue.toString(),
                      PdfColors.orange700,
                    ),
                    _buildSummaryItem(
                      'No Expiry',
                      noExpiryCountValue.toString(),
                      PdfColors.green700,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Expiring Soon Section
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Text(
                  'Expiring Soon',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),

              // Expiring Soon Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Product',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'SKU',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Days',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Stock',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Expiry Date',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Status',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expiring Soon Products
              ...expiringSoon.map((product) {
                final daysLeft = product.expiryDate!
                    .difference(DateTime.now())
                    .inDays;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey100,
                        width: 0.3,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          product.name,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          product.sku,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          daysLeft.toString(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: daysLeft <= 7
                                ? PdfColors.red700
                                : PdfColors.orange700,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          product.currentStock.toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          DateFormat('dd/MM/yyyy').format(product.expiryDate!),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.orange700,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'Soon',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 16),

              // Expired Section
              if (expired.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Text(
                    'Expired Products',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Expired Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey200),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Product',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'SKU',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Stock',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Expiry Date',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Status',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expired Products
                ...expired.map((product) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey100,
                          width: 0.3,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            product.name,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            product.sku,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            product.currentStock.toString(),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(product.expiryDate!),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.red700,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'Expired',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by LedgerPro',
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

  pw.Widget _buildSummaryItem(String label, String value, [PdfColor? color]) {
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
            color: color ?? PdfColors.indigo700,
          ),
        ),
      ],
    );
  }
}
