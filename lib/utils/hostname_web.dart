import 'dart:html' as html;

Future<String?> getHostname() async {
  return html.window.location.hostname;
}
