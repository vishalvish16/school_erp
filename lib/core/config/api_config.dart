// =============================================================================
// FILE: lib/core/config/api_config.dart
// PURPOSE: Centralized API configurations and environment-specific variables
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  // Change this to your production / staging URL as needed
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid)
      return 'http://192.168.1.14:3000'; // Actual Desktop Wi-Fi IP for physical phones
    return 'http://192.168.1.14:3000';
  }

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
