// =============================================================================
// FILE: lib/utils/download_file_web.dart
// PURPOSE: Trigger file download in browser (web only)
// =============================================================================

import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Triggers a file download in the browser.
/// Returns a success message for the caller to show in a snackbar.
Future<String> downloadFile(String content, String filename, String mimeType) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'Downloaded $filename';
}
