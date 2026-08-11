import 'dart:io';
import 'dart:typed_data';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/pdf_branding_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class PurchaseReportRow {
  final String id;
  final String channel;
  final String reference;
  final DateTime? date;
  final String supplierName;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double tax;
  final double discount;
  final double grandTotal;

  PurchaseReportRow({
    required this.id,
    required this.channel,
    required this.reference,
    required this.date,
    required this.supplierName,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.grandTotal,
  });

  factory PurchaseReportRow.fromJson(Map<String, dynamic> json) {
    DateTime? parsed;
    final raw = json['date'];
    if (raw != null) {
      parsed = DateTime.tryParse(raw.toString());
    }
    return PurchaseReportRow(
      id: json['id']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      date: parsed,
      supplierName: json['supplierName']?.toString() ?? 'Supplier',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      subtotal: _toDouble(json['subtotal']),
      tax: _toDouble(json['tax']),
      discount: _toDouble(json['discount']),
      grandTotal: _toDouble(json['grandTotal']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class PurchaseReportSummary {
  final int count;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final Map<String, Map<String, dynamic>> byChannel;

  PurchaseReportSummary({
    required this.count,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.byChannel,
  });

  factory PurchaseReportSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PurchaseReportSummary(
        count: 0,
        subtotal: 0,
        taxTotal: 0,
        discountTotal: 0,
        grandTotal: 0,
        byChannel: {},
      );
    }
    final by = <String, Map<String, dynamic>>{};
    final rawBy = json['byChannel'];
    if (rawBy is Map) {
      rawBy.forEach((k, v) {
        if (v is Map) {
          by[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
    }
    return PurchaseReportSummary(
      count: (json['count'] as num?)?.toInt() ?? 0,
      subtotal: PurchaseReportRow._toDouble(json['subtotal']),
      taxTotal: PurchaseReportRow._toDouble(json['taxTotal']),
      discountTotal: PurchaseReportRow._toDouble(json['discountTotal']),
      grandTotal: PurchaseReportRow._toDouble(json['grandTotal']),
      byChannel: by,
    );
  }
}

class PurchaseReportController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxString error = ''.obs;

  final RxString channel = 'all'.obs;
  final RxString period = 'month'.obs;
  final RxString status = 'all'.obs;
  final RxString search = ''.obs;
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final RxInt page = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt total = 0.obs;
  final RxList<PurchaseReportRow> rows = <PurchaseReportRow>[].obs;
  final Rxn<PurchaseReportSummary> summary = Rxn<PurchaseReportSummary>();

  final searchController = TextEditingController();

  static const channels = [
    ('All Channels', 'all'),
    ('Purchase Orders', 'orders'),
    ('Invoices', 'invoices'),
    ('Payments', 'payments'),
    ('Returns', 'returns'),
  ];

  static const periods = [
    ('Today', 'today'),
    ('This Week', 'week'),
    ('This Month', 'month'),
    ('This Year', 'year'),
    ('Custom', 'custom'),
  ];

  static const statuses = [
    ('All Status', 'all'),
    ('Approved', 'Approved'),
    ('Sent', 'Sent'),
    ('Posted', 'Posted'),
    ('Paid', 'Paid'),
    ('Partial', 'Partial'),
    ('Unpaid', 'Unpaid'),
    ('Completed', 'Completed'),
    ('Processed', 'Processed'),
  ];

  @override
  void onInit() {
    super.onInit();
    loadReport();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Map<String, dynamic> _query({int? pageOverride, int? limitOverride}) {
    final q = <String, dynamic>{
      'channel': channel.value,
      'period': period.value,
      'status': status.value,
      'page': pageOverride ?? page.value,
      'limit': limitOverride ?? 50,
    };
    final s = search.value.trim();
    if (s.isNotEmpty) q['search'] = s;
    if (period.value == 'custom') {
      if (startDate.value != null) {
        q['startDate'] = DateFormat('yyyy-MM-dd').format(startDate.value!);
      }
      if (endDate.value != null) {
        q['endDate'] = DateFormat('yyyy-MM-dd').format(endDate.value!);
      }
    }
    return q;
  }

  Future<void> loadReport() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiClient.get(
        '/api/purchase/reports',
        queryParameters: _query(),
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final list = (data['rows'] as List? ?? [])
            .map((e) => PurchaseReportRow.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        rows.assignAll(list);
        summary.value = PurchaseReportSummary.fromJson(
          data['summary'] is Map
              ? Map<String, dynamic>.from(data['summary'])
              : null,
        );
        final pagination = data['pagination'];
        if (pagination is Map) {
          total.value = (pagination['total'] as num?)?.toInt() ?? list.length;
          totalPages.value =
              (pagination['totalPages'] as num?)?.toInt() ?? 1;
        } else {
          total.value = list.length;
          totalPages.value = 1;
        }
      } else {
        error.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load sales report';
        rows.clear();
        summary.value = null;
      }
    } catch (e) {
      error.value = e.toString();
      rows.clear();
      summary.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    search.value = searchController.text.trim();
    page.value = 1;
    loadReport();
  }

  void setChannel(String value) {
    channel.value = value;
    page.value = 1;
    loadReport();
  }

  void setPeriod(String value) {
    period.value = value;
    page.value = 1;
    if (value != 'custom') loadReport();
  }

  void setStatus(String value) {
    status.value = value;
    page.value = 1;
    loadReport();
  }

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      startDate.value = picked;
      if (endDate.value != null && period.value == 'custom') {
        page.value = 1;
        loadReport();
      }
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.value ?? DateTime.now(),
      firstDate: startDate.value ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      endDate.value = picked;
      if (startDate.value != null && period.value == 'custom') {
        page.value = 1;
        loadReport();
      }
    }
  }

  void nextPage() {
    if (page.value < totalPages.value) {
      page.value++;
      loadReport();
    }
  }

  void prevPage() {
    if (page.value > 1) {
      page.value--;
      loadReport();
    }
  }

  String formatCurrency(double value) {
    final currencyController = Get.find<CurrencyController>();
    return currencyController.formatAmount(value);
  }

  String formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  String get periodLabel {
    return periods
        .firstWhere((p) => p.$2 == period.value, orElse: () => ('Custom', 'custom'))
        .$1;
  }

  String get channelLabel {
    return channels
        .firstWhere((c) => c.$2 == channel.value, orElse: () => ('All', 'all'))
        .$1;
  }

  Future<List<PurchaseReportRow>> _fetchAllForExport() async {
    final response = await _apiClient.get(
      '/api/purchase/reports',
      queryParameters: _query(pageOverride: 1, limitOverride: 2000),
      requiresAuth: true,
    );
    if (!response.success || response.data == null) {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to load export data',
      );
    }
    final data = response.data['data'] ?? response.data;
    return (data['rows'] as List? ?? [])
        .map((e) => PurchaseReportRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> exportToPdf() async {
    if (isExporting.value) return;

    try {
      isExporting.value = true;

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

      final exportRows = await _fetchAllForExport();
      if (exportRows.isEmpty) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.error(kDanger, 'Empty', 'No records for selected filters');
        return;
      }

      final bytes = await _generatePdfBytes(exportRows);
      final fileName =
          'purchase_report_${channel.value}_${period.value}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

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
      AppSnackbar.success(kSuccess, 'Success', 'Purchase report PDF downloaded');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(kDanger, 'Error', 'Failed to export PDF: $e');
    } finally {
      isExporting.value = false;
    }
  }

  Future<Uint8List> _generatePdfBytes(List<PurchaseReportRow> exportRows) async {
    final branding = await PdfBrandingBundle.load();
    final pdf = pw.Document();
    final s = summary.value;

    String dateRangeText;
    if (period.value == 'custom' &&
        startDate.value != null &&
        endDate.value != null) {
      dateRangeText =
          '${formatDate(startDate.value)} – ${formatDate(endDate.value)}';
    } else {
      dateRangeText = periodLabel;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => branding.buildHeader(reportTitle: 'Purchase Report'),
        footer: (ctx) => branding.buildFooter(ctx),
        build: (context) => [
          pw.Text(
            'Channel: $channelLabel  |  Period: $dateRangeText  |  Records: ${exportRows.length}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          if (s != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Grand Total: ${formatCurrency(s.grandTotal)}   Subtotal: ${formatCurrency(s.subtotal)}   Tax: ${formatCurrency(s.taxTotal)}   Discount: ${formatCurrency(s.discountTotal)}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: branding.accent,
              ),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: pw.BoxDecoration(color: branding.accent),
            child: pw.Row(
              children: [
                _pdfCell('Date', flex: 12, bold: true, light: true),
                _pdfCell('Channel', flex: 10, bold: true, light: true),
                _pdfCell('Reference', flex: 14, bold: true, light: true),
                _pdfCell('Supplier', flex: 16, bold: true, light: true),
                _pdfCell('Status', flex: 11, bold: true, light: true),
                _pdfCell('Payment', flex: 11, bold: true, light: true),
                _pdfCell('Total', flex: 12, bold: true, light: true, right: true),
              ],
            ),
          ),
          ...exportRows.map((r) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  _pdfCell(formatDate(r.date), flex: 12),
                  _pdfCell(r.channel.toUpperCase(), flex: 10),
                  _pdfCell(r.reference, flex: 14),
                  _pdfCell(r.supplierName, flex: 16),
                  _pdfCell(r.status, flex: 11),
                  _pdfCell(r.paymentStatus, flex: 11),
                  _pdfCell(formatCurrency(r.grandTotal), flex: 12, right: true, bold: true),
                ],
              ),
            );
          }),
          branding.buildSignatureBlock(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfCell(
    String text, {
    required int flex,
    bool bold = false,
    bool light = false,
    bool right = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: light ? PdfColors.white : PdfColors.grey800,
        ),
      ),
    );
  }
}
