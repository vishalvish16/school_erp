// =============================================================================
// FILE: lib/core/services/theme_service.dart
// PURPOSE: API calls for dynamic theme configuration
// =============================================================================

import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ThemeService {
  ThemeService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>?> getSuperAdminTheme() async {
    final resp = await _dio.get(ApiConfig.publicPlatformTheme);
    if (resp.data['success'] == true) {
      return resp.data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> saveSuperAdminTheme({
    required Map<String, dynamic> light,
    required Map<String, dynamic> dark,
    required String presetName,
  }) async {
    await _dio.put(ApiConfig.superAdminTheme, data: {
      'light': light,
      'dark': dark,
      'presetName': presetName,
    });
  }

  Future<Map<String, dynamic>> applyThemeToPortals({
    required List<String> portals,
    required Map<String, dynamic> light,
    required Map<String, dynamic> dark,
  }) async {
    final resp = await _dio.post(ApiConfig.superAdminThemeApply, data: {
      'portals': portals,
      'light': light,
      'dark': dark,
    });
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getSchoolTheme() async {
    try {
      final resp = await _dio.get(ApiConfig.schoolTheme);
      if (resp.data['success'] == true) {
        return resp.data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getParentTheme() async {
    try {
      final resp = await _dio.get(ApiConfig.parentTheme);
      if (resp.data['success'] == true) {
        return resp.data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
