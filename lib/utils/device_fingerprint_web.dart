import 'dart:html' as html;

Future<String> getDeviceFingerprintParts() async {
  try {
    final ua = html.window.navigator.userAgent;
    final w = html.window.screen?.width ?? 0;
    final h = html.window.screen?.height ?? 0;
    return '$ua|${w}x$h';
  } catch (_) {
    return 'web_${DateTime.now().millisecondsSinceEpoch}';
  }
}
