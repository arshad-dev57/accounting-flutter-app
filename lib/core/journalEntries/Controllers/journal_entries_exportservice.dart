import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/journalEntries/model/journal_entry_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:LedgerPro_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:universal_html/html.dart' as html;

class JournalExportService {
  static String _formatAmount(double amount) =>
      CurrencyUtils.format(amount);

  static Future<void> exportToPdf(
      List<JournalEntry> entries, Map<String, dynamic> summary) async {
    try {
      // Show loading only on mobile
      if (!kIsWeb) {
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Generating PDF...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      }
      
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => _pdfHeader(),
          footer: (ctx) => _pdfFooter(ctx),
          build: (ctx) => [
            _pdfSummarySection(summary),
            pw.SizedBox(height: 8),
            pw.Text('Total Entries Exported: ${entries.length}',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            _pdfEntriesSection(entries),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'journal_entries_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        // WEB: Download using HTML anchor tag
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', '${entries.length} entries exported to PDF');
      } else {
        // MOBILE: Save to file and open
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', '${entries.length} entries exported to PDF');
        
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          AppSnackbar.error(Colors.red, 'Error', 'PDF khul nahi saka: ${result.message}');
        }
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export PDF: $e');
    }
  }

  static pw.Widget _pdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Journal Entries Report',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800)),
            pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
                color: PdfColors.indigo800,
                borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text('LedgerPro',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Confidential - For Internal Use Only',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _pdfSummarySection(Map<String, dynamic> summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.indigo200)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdfSummaryItem('Total Debit',
              _formatAmount(summary['totalDebit'] ?? 0.0), PdfColors.green700),
          _pdfSummaryItem('Total Credit',
              _formatAmount(summary['totalCredit'] ?? 0.0), PdfColors.red700),
          _pdfSummaryItem(
              'Difference',
              _formatAmount(summary['difference'] ?? 0.0),
              (summary['difference'] ?? 0.0) < 0.01
                  ? PdfColors.green700
                  : PdfColors.orange700),
          _pdfSummaryItem('Posted', '${summary['postedCount'] ?? 0}',
              PdfColors.indigo700),
          _pdfSummaryItem(
              'Draft', '${summary['draftCount'] ?? 0}', PdfColors.orange700),
        ],
      ),
    );
  }

  static pw.Widget _pdfSummaryItem(
      String label, String value, PdfColor color) {
    return pw.Column(children: [
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.SizedBox(height: 4),
      pw.Text(value,
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }

  static pw.Widget _pdfEntriesSection(List<JournalEntry> entries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: entries.map((entry) => _pdfEntryCard(entry)).toList(),
    );
  }

  static pw.Widget _pdfEntryCard(JournalEntry entry) {
    final isPosted = entry.status == 'Posted';
    final statusColor = isPosted ? PdfColors.green700 : PdfColors.orange700;
    final bgColor = isPosted ? PdfColors.green50 : PdfColors.orange50;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200),
          borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                            color: statusColor,
                            borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Text(entry.entryNumber,
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: statusColor)),
                        child: pw.Text(entry.status,
                            style: pw.TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Text(entry.description,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        DateFormat('dd MMM yyyy').format(entry.date),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                    if (entry.reference.isNotEmpty)
                      pw.Text('Ref: ${entry.reference}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                  ]),
            ],
          ),
        ),
        // Lines table
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(children: [
            // Table header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          color: PdfColors.grey300, width: 0.5))),
              child: pw.Row(children: [
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('Account',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Debit',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Credit',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600))),
              ]),
            ),
            // Lines
            ...entry.lines.map((line) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 5),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey200, width: 0.5))),
                  child: pw.Row(children: [
                    pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(line.accountName,
                                  style: const pw.TextStyle(fontSize: 10)),
                              pw.Text(line.accountCode,
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: PdfColors.grey500)),
                            ])),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                            line.debit > 0 ? _formatAmount(line.debit) : '-',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: line.debit > 0
                                    ? PdfColors.green700
                                    : PdfColors.grey400))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                            line.credit > 0
                                ? _formatAmount(line.credit)
                                : '-',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: line.credit > 0
                                    ? PdfColors.red700
                                    : PdfColors.grey400))),
                  ]),
                )),
            // Total row
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Row(children: [
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('Total',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text(_formatAmount(entry.totalDebit),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text(_formatAmount(entry.totalCredit),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red700))),
              ]),
            ),
          ]),
        ),
        // Footer
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(8),
                  bottomRight: pw.Radius.circular(8))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Created by: ${entry.createdBy}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
              pw.Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt),
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────── IMAGE ───────────────────────────
  static Future<void> exportToImage(
      GlobalKey repaintKey, List<JournalEntry> entries) async {
    try {
      final boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.error(Colors.red, 'Error', 'Could not capture screen');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.error(Colors.red, 'Error', 'Failed to capture image');
        return;
      }

      final fileName = 'journal_entries_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';

      if (kIsWeb) {
        // WEB: Download image
        final blob = html.Blob([byteData.buffer.asUint8List()], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', 'Image saved successfully');
      } else {
        // MOBILE: Save and open
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', 'Image saved successfully');
        
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          AppSnackbar.error(Colors.red, 'Error', 'Image khul nahi saka: ${result.message}');
        }
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export image: $e');
    }
  }

  static Future<void> exportToExcel(
      List<JournalEntry> entries, Map<String, dynamic> summary) async {
    try {
      // Show loading only on mobile
      if (!kIsWeb) {
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Building Excel...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      }
      
      final excel = Excel.createExcel();

      // ── Summary Sheet ──
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      _excelSetCell(summarySheet, 0, 0, 'Journal Entries Report',
          bold: true, fontSize: 14, bgColor: '1A237E', fontColor: 'FFFFFF');
      _excelSetCell(summarySheet, 1, 0,
          'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          fontSize: 9, fontColor: '757575');
      _excelSetCell(summarySheet, 2, 0,
          'Total Entries: ${entries.length}',
          fontSize: 10, fontColor: '1A237E', bold: true);

      _excelSetCell(summarySheet, 4, 0, 'SUMMARY',
          bold: true, fontSize: 11, bgColor: 'E8EAF6');
      final summaryHeaders = ['Metric', 'Value'];
      for (int i = 0; i < summaryHeaders.length; i++) {
        _excelSetCell(summarySheet, 5, i, summaryHeaders[i],
            bold: true, bgColor: '3949AB', fontColor: 'FFFFFF');
      }
      final summaryRows = [
        ['Total Debit', _formatAmount(summary['totalDebit'] ?? 0.0)],
        ['Total Credit', _formatAmount(summary['totalCredit'] ?? 0.0)],
        ['Difference', _formatAmount(summary['difference'] ?? 0.0)],
        ['Posted Entries', '${summary['postedCount'] ?? 0}'],
        ['Draft Entries', '${summary['draftCount'] ?? 0}'],
        ['Total Entries', '${entries.length}'],
      ];
      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < 2; c++) {
          _excelSetCell(summarySheet, 6 + r, c, summaryRows[r][c],
              bgColor: r.isEven ? 'FFFFFF' : 'F5F5F5');
        }
      }
      summarySheet.setColumnWidth(0, 25);
      summarySheet.setColumnWidth(1, 20);

      // ── Entries Sheet ──
      final entriesSheet = excel['Journal Entries'];
      final entryHeaders = [
        'Entry #',
        'Date',
        'Description',
        'Reference',
        'Status',
        'Total Debit',
        'Total Credit',
        'Created By',
        'Created At',
      ];
      for (int i = 0; i < entryHeaders.length; i++) {
        _excelSetCell(entriesSheet, 0, i, entryHeaders[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }
      int row = 1;
      for (final entry in entries) {
        final bg = row.isEven ? 'F5F5F5' : 'FFFFFF';
        final statusBg = entry.status == 'Posted' ? 'E8F5E9' : 'FFF8E1';
        _excelSetCell(entriesSheet, row, 0, entry.entryNumber,
            bold: true, bgColor: bg);
        _excelSetCell(
            entriesSheet, row, 1, DateFormat('dd/MM/yyyy').format(entry.date),
            bgColor: bg);
        _excelSetCell(entriesSheet, row, 2, entry.description, bgColor: bg);
        _excelSetCell(
            entriesSheet, row, 3, entry.reference.isEmpty ? '-' : entry.reference,
            bgColor: bg);
        _excelSetCell(entriesSheet, row, 4, entry.status,
            bgColor: statusBg, bold: true);
        _excelSetCell(entriesSheet, row, 5, entry.totalDebit,
            bgColor: bg, fontColor: '2E7D32');
        _excelSetCell(entriesSheet, row, 6, entry.totalCredit,
            bgColor: bg, fontColor: 'C62828');
        _excelSetCell(entriesSheet, row, 7, entry.createdBy, bgColor: bg);
        _excelSetCell(
            entriesSheet,
            row,
            8,
            DateFormat('dd/MM/yyyy hh:mm a').format(entry.createdAt),
            bgColor: bg);
        row++;
      }
      final colWidths = [14.0, 12.0, 35.0, 16.0, 10.0, 16.0, 16.0, 22.0, 20.0];
      for (int i = 0; i < colWidths.length; i++) {
        entriesSheet.setColumnWidth(i, colWidths[i]);
      }

      // ── Lines Sheet ──
      final linesSheet = excel['Journal Lines'];
      final lineHeaders = [
        'Entry #',
        'Date',
        'Description',
        'Account Code',
        'Account Name',
        'Debit',
        'Credit',
        'Status',
      ];
      for (int i = 0; i < lineHeaders.length; i++) {
        _excelSetCell(linesSheet, 0, i, lineHeaders[i],
            bold: true, bgColor: '1A237E', fontColor: 'FFFFFF', fontSize: 10);
      }
      int lineRow = 1;
      for (final entry in entries) {
        for (final line in entry.lines) {
          final bg = lineRow.isEven ? 'F5F5F5' : 'FFFFFF';
          _excelSetCell(linesSheet, lineRow, 0, entry.entryNumber, bgColor: bg);
          _excelSetCell(linesSheet, lineRow, 1,
              DateFormat('dd/MM/yyyy').format(entry.date),
              bgColor: bg);
          _excelSetCell(linesSheet, lineRow, 2, entry.description, bgColor: bg);
          _excelSetCell(linesSheet, lineRow, 3, line.accountCode, bgColor: bg);
          _excelSetCell(linesSheet, lineRow, 4, line.accountName, bgColor: bg);
          _excelSetCell(linesSheet, lineRow, 5, line.debit > 0 ? line.debit : '',
              bgColor: bg, fontColor: '2E7D32');
          _excelSetCell(
              linesSheet, lineRow, 6, line.credit > 0 ? line.credit : '',
              bgColor: bg, fontColor: 'C62828');
          _excelSetCell(linesSheet, lineRow, 7, entry.status, bgColor: bg);
          lineRow++;
        }
      }
      final lineColWidths = [14.0, 12.0, 30.0, 14.0, 28.0, 14.0, 14.0, 10.0];
      for (int i = 0; i < lineColWidths.length; i++) {
        linesSheet.setColumnWidth(i, lineColWidths[i]);
      }

      // Remove default Sheet1
      excel.delete('Sheet1');

      final bytes = excel.save();
      if (bytes == null) throw Exception('Excel save failed');

      final fileName = 'journal_entries_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        // WEB: Download Excel
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', '${entries.length} entries exported to Excel');
      } else {
        // MOBILE: Save and open
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.success(Colors.green, 'Success', '${entries.length} entries exported to Excel');
        
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          AppSnackbar.error(Colors.red, 'Error', 'Excel khul nahi saka: ${result.message}');
        }
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error(Colors.red, 'Error', 'Failed to export Excel: $e');
    }
  }

  static void _excelSetCell(
    Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool bold = false,
    double fontSize = 10,
    String? bgColor,
    String fontColor = '000000',
  }) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value is double
        ? DoubleCellValue(value)
        : value is int
            ? IntCellValue(value)
            : TextCellValue(value.toString());

    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize.toInt(),
      fontColorHex: ExcelColor.fromHexString('#$fontColor'),
      backgroundColorHex: bgColor != null
          ? ExcelColor.fromHexString('#$bgColor')
          : ExcelColor.fromHexString('#FFFFFF'),
    );
  }
}