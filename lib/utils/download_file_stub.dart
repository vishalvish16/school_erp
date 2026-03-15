// =============================================================================
// FILE: lib/utils/download_file_stub.dart
// PURPOSE: Fallback for non-web: copy to clipboard
// =============================================================================

import 'package:flutter/services.dart';

/// On non-web platforms, copies content to clipboard instead of downloading.
/// Returns a success message for the caller to show in a snackbar.
Future<String> downloadFile(String content, String filename, String mimeType) async {
  await Clipboard.setData(ClipboardData(text: content));
  return 'Copied to clipboard ($filename)';
}
