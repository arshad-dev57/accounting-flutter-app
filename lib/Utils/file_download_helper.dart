import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
class FileDownloadHelper {
  static void downloadFile(List<int> bytes, String fileName, String mimeType) {
    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}