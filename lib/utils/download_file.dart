// =============================================================================
// FILE: lib/utils/download_file.dart
// PURPOSE: Cross-platform file download (web) or copy to clipboard (non-web)
// =============================================================================

import 'download_file_stub.dart'
    if (dart.library.html) 'download_file_web.dart' as impl;

/// Downloads the content as a file (web) or copies to clipboard (non-web).
/// Returns a success message for the caller to show in a snackbar.
Future<String> downloadFile(String content, String filename, String mimeType) async {
  return impl.downloadFile(content, filename, mimeType);
}
