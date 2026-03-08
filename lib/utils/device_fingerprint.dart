// =============================================================================
// FILE: lib/utils/device_fingerprint.dart
// PURPOSE: Generate consistent device fingerprint (SHA-256 hash)
// =============================================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'device_fingerprint_stub.dart'
    if (dart.library.html) 'device_fingerprint_web.dart'
    if (dart.library.io) 'device_fingerprint_io.dart' as impl;

/// Generates a consistent device fingerprint for the current device.
/// Returns SHA-256 hash as hex string. Cached in memory for the session.
class DeviceFingerprint {
  static String? _cached;

  static Future<String> generate() async {
    if (_cached != null) return _cached!;

    final parts = await impl.getDeviceFingerprintParts();
    final input = '$parts|${DateTime.now().timeZoneOffset}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    _cached = digest.toString();
    return _cached!;
  }

  static void clearCache() {
    _cached = null;
  }
}
