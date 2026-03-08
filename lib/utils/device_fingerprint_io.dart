import 'dart:io' show Platform;

Future<String> getDeviceFingerprintParts() async {
  try {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    return '$platform|$version';
  } catch (_) {
    return 'mobile_${DateTime.now().millisecondsSinceEpoch}';
  }
}
