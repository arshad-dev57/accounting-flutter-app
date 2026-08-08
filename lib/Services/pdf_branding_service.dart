import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

/// Shared PDF branding loaded from local `pdf_report_settings`.
class PdfBrandingSettings {
  final String companyName;
  final String companyAddress;
  final String logo;
  final String signature;
  final bool showLogo;
  final bool showSignature;
  final bool showCompanyName;
  final bool showAddress;
  final bool showPageNumbers;
  final String layout;
  final String logoPosition;
  final String headerSubtitle;
  final String footerText;
  final String accentColor;
  final String signatureLabel;

  const PdfBrandingSettings({
    required this.companyName,
    required this.companyAddress,
    required this.logo,
    required this.signature,
    required this.showLogo,
    required this.showSignature,
    required this.showCompanyName,
    required this.showAddress,
    required this.showPageNumbers,
    required this.layout,
    required this.logoPosition,
    required this.headerSubtitle,
    required this.footerText,
    required this.accentColor,
    required this.signatureLabel,
  });

  factory PdfBrandingSettings.defaults() => const PdfBrandingSettings(
    companyName: '',
    companyAddress: '',
    logo: '',
    signature: '',
    showLogo: true,
    showSignature: true,
    showCompanyName: true,
    showAddress: true,
    showPageNumbers: true,
    layout: 'classic',
    logoPosition: 'left',
    headerSubtitle: '',
    footerText: 'Confidential - For Internal Use Only',
    accentColor: '#014582',
    signatureLabel: 'Authorized Signature',
  );

  PdfColor get accentPdfColor {
    try {
      final hex = accentColor.replaceAll('#', '');
      if (hex.length != 6) return PdfColors.indigo800;
      return PdfColor.fromInt(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return PdfColors.indigo800;
    }
  }

  String get displayCompanyName =>
      companyName.trim().isEmpty ? 'BisonsTechs' : companyName.trim();

  static Future<PdfBrandingSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pdfRaw = prefs.getString('pdf_report_settings');
      if (pdfRaw == null || pdfRaw.isEmpty) {
        return PdfBrandingSettings.defaults();
      }

      final data = json.decode(pdfRaw) as Map<String, dynamic>;
      return PdfBrandingSettings(
        companyName: (data['companyName'] as String?) ?? '',
        companyAddress: (data['companyAddress'] as String?) ?? '',
        logo: (data['logo'] as String?) ?? '',
        signature: (data['signature'] as String?) ?? '',
        showLogo: data['showLogo'] != false,
        showSignature: data['showSignature'] != false,
        showCompanyName: data['showCompanyName'] != false,
        showAddress: data['showAddress'] != false,
        showPageNumbers: data['showPageNumbers'] != false,
        layout: (data['layout'] as String?) ?? 'classic',
        logoPosition: (data['logoPosition'] as String?) ?? 'left',
        headerSubtitle: (data['headerSubtitle'] as String?) ?? '',
        footerText:
            (data['footerText'] as String?)?.trim().isNotEmpty == true
            ? data['footerText'] as String
            : 'Confidential - For Internal Use Only',
        accentColor:
            (data['accentColor'] as String?)?.startsWith('#') == true
            ? data['accentColor'] as String
            : '#014582',
        signatureLabel:
            (data['signatureLabel'] as String?)?.trim().isNotEmpty == true
            ? data['signatureLabel'] as String
            : 'Authorized Signature',
      );
    } catch (_) {
      return PdfBrandingSettings.defaults();
    }
  }

  static Future<Uint8List?> loadImageBytes(String path) async {
    if (path.trim().isEmpty) return null;
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final res = await http.get(Uri.parse(path));
        if (res.statusCode == 200) return res.bodyBytes;
        return null;
      }
      if (!kIsWeb) {
        final file = File(path);
        if (await file.exists()) return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }
}

/// Ready-to-use PDF widgets from saved report settings.
class PdfBrandingBundle {
  final PdfBrandingSettings settings;
  final pw.ImageProvider? logoImage;
  final pw.ImageProvider? signatureImage;

  const PdfBrandingBundle({
    required this.settings,
    this.logoImage,
    this.signatureImage,
  });

  PdfColor get accent => settings.accentPdfColor;

  static Future<PdfBrandingBundle> load() async {
    final settings = await PdfBrandingSettings.load();
    pw.MemoryImage? logo;
    pw.MemoryImage? signature;

    if (settings.showLogo && settings.logo.isNotEmpty) {
      final bytes = await PdfBrandingSettings.loadImageBytes(settings.logo);
      if (bytes != null) logo = pw.MemoryImage(bytes);
    }
    if (settings.showSignature && settings.signature.isNotEmpty) {
      final bytes = await PdfBrandingSettings.loadImageBytes(
        settings.signature,
      );
      if (bytes != null) signature = pw.MemoryImage(bytes);
    }

    return PdfBrandingBundle(
      settings: settings,
      logoImage: logo,
      signatureImage: signature,
    );
  }

  pw.Widget buildHeader({required String reportTitle}) {
    final s = settings;
    final accentColor = this.accent;
    final generated =
        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}';

    final logoWidget = (s.showLogo && logoImage != null)
        ? pw.Container(
            width: 48,
            height: 48,
            child: pw.Image(logoImage!, fit: pw.BoxFit.contain),
          )
        : null;

    final companyBlock = pw.Column(
      crossAxisAlignment: s.logoPosition == 'center'
          ? pw.CrossAxisAlignment.center
          : (s.logoPosition == 'right'
                ? pw.CrossAxisAlignment.end
                : pw.CrossAxisAlignment.start),
      children: [
        if (s.showCompanyName)
          pw.Text(
            s.displayCompanyName,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
        if (s.showAddress && s.companyAddress.trim().isNotEmpty)
          pw.Text(
            s.companyAddress.trim(),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: s.logoPosition == 'center'
                ? pw.TextAlign.center
                : pw.TextAlign.left,
          ),
        if (s.headerSubtitle.trim().isNotEmpty)
          pw.Text(
            s.headerSubtitle.trim(),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
      ],
    );

    final titleBlock = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          reportTitle,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          generated,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );

    pw.Widget brandRow;
    if (s.logoPosition == 'center') {
      brandRow = pw.Column(
        children: [
          if (logoWidget != null) ...[logoWidget, pw.SizedBox(height: 6)],
          companyBlock,
        ],
      );
    } else if (s.logoPosition == 'right') {
      brandRow = pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          titleBlock,
          pw.Row(
            children: [
              companyBlock,
              if (logoWidget != null) ...[pw.SizedBox(width: 8), logoWidget],
            ],
          ),
        ],
      );
    } else {
      brandRow = pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoWidget != null) ...[logoWidget, pw.SizedBox(width: 10)],
              companyBlock,
            ],
          ),
          titleBlock,
        ],
      );
    }

    final content = s.logoPosition == 'center'
        ? pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              brandRow,
              pw.SizedBox(height: 8),
              titleBlock,
            ],
          )
        : brandRow;

    if (s.layout == 'modern') {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor(
            accentColor.red,
            accentColor.green,
            accentColor.blue,
            0.08,
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: content,
      );
    }

    if (s.layout == 'minimal') {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: content,
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: accentColor, width: 2),
        ),
      ),
      child: content,
    );
  }

  pw.Widget buildFooter(pw.Context ctx) {
    final s = settings;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              s.footerText,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
          if (s.showPageNumbers)
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
        ],
      ),
    );
  }

  pw.Widget buildSignatureBlock() {
    final s = settings;
    if (!s.showSignature) return pw.SizedBox();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 28),
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (signatureImage != null)
            pw.Container(
              height: 42,
              width: 120,
              child: pw.Image(signatureImage!, fit: pw.BoxFit.contain),
            )
          else
            pw.Container(
              width: 120,
              height: 28,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
                ),
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            s.signatureLabel,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
