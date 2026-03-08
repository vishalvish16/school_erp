// =============================================================================
// FILE: lib/core/config/api_config.dart
// PURPOSE: Centralized API configurations and environment-specific variables
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// Backend port — must match backend .env PORT (default 3000)
  static const int backendPort = 3000;

  /// Override: flutter run --dart-define=API_HOST=192.168.1.100
  /// Emulator: 10.0.2.2 = host localhost. If timeout, try: adb reverse tcp:3000 tcp:3000 + API_HOST=127.0.0.1
  static String get _host {
    const fromEnv = String.fromEnvironment(
      'API_HOST',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2'; // Emulator; use --dart-define for physical device
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:$backendPort';

  // Specific endpoints
  static const String loginEndpoint = '/api/platform/auth/login';
  static const String forgotPasswordEndpoint =
      '/api/platform/auth/forgot-password';
  static const String resetPasswordEndpoint =
      '/api/platform/auth/reset-password';

  // Request settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
