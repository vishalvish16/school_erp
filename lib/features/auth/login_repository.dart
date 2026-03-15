// =============================================================================
// FILE: lib/features/auth/login_repository.dart
// PURPOSE: Repository for Super Admin & Group Admin Login using Dio for HTTP calls
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/local_storage_service.dart';
import '../../utils/device_fingerprint.dart';
import '../../utils/subdomain_resolver.dart';
import '../../utils/hostname_stub.dart'
    if (dart.library.html) '../../utils/hostname_web.dart'
    as hostname_impl;

/// Result: either direct token or requires OTP
typedef LoginResult = Map<String, dynamic>;

/// Abstract interface for Login operations
abstract class LoginRepository {
  Future<LoginResult> login(
    String email,
    String password, {
    bool trustDevice = false,
    String? portalType,
  });
}

/// Production implementation using Dio
class AuthRepository implements LoginRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Resolve portal_type from context (web: subdomain, mobile: saved school/portal)
  /// Web: admin.vidyron.in or localhost → super_admin; {group}.vidyron.in → group_admin
  /// Mobile: no subdomain — use saved portal type, saved school type, or null (backend determines)
  Future<String?> _resolvePortalType(String? override) async {
    if (override != null && override.isNotEmpty) return override;
    if (kIsWeb) {
      final host = await hostname_impl.getHostname();
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      final sub = await SubdomainResolver.getCurrentSubdomain();
      if (sub == 'admin' || isLocalhost) return 'super_admin';
      if (sub != null && sub.isNotEmpty) return 'group_admin';
      return 'super_admin';
    }
    // Mobile: no subdomain — use saved context or let backend determine
    final storage = LocalStorageService();
    final savedPortal = await storage.getPortalType();
    if (savedPortal != null && savedPortal.isNotEmpty) return savedPortal;
    final school = await storage.getSavedSchool();
    if (school != null) {
      if (school.type == 'group') return 'group_admin';
      return 'school_admin';
    }
    return null; // Backend will use default and return actual portal_type from user role
  }

  @override
  Future<LoginResult> login(
    String email,
    String password, {
    bool trustDevice = false,
    String? portalType,
  }) async {
    try {
      String fingerprint = '';
      try {
        fingerprint = await DeviceFingerprint.generate();
      } catch (_) {
        fingerprint = 'unknown';
      }
      final resolvedPortal = await _resolvePortalType(portalType);
      final body = <String, dynamic>{
        'email': email,
        'identifier': email,
        'password': password,
        'device_fingerprint': fingerprint,
        'device_meta': {'device_type': 'unknown', 'trust_device': trustDevice},
      };
      if (resolvedPortal != null) body['portal_type'] = resolvedPortal;
      final response = await _dio.post(ApiConfig.loginEndpoint, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) throw Exception('Invalid response');

        if (data['requires_2fa'] == true) {
          return {
            'requires_2fa': true,
            'temp_token': data['temp_token'],
            'expires_in': data['expires_in'] ?? 300,
            if (data['portal_type'] != null) 'portal_type': data['portal_type'],
          };
        }

        if (data['requires_otp'] == true) {
          return {
            'requires_otp': true,
            'otp_session_id': data['otp_session_id'],
            'expires_in': data['expires_in'] ?? 120,
            'masked_phone': data['masked_phone'],
            'masked_email': data['masked_email'],
            'otp_sent_to': data['otp_sent_to'],
            if (data['portal_type'] != null) 'portal_type': data['portal_type'],
            if (data['dev_otp'] != null) 'dev_otp': data['dev_otp'],
          };
        }

        final token = data['session_token'] ?? data['access_token'];
        if (token != null) {
          return {
            'access_token': token,
            'refresh_token': data['refresh_token'],
            'user': data['user'],
            if (data['portal_type'] != null) 'portal_type': data['portal_type'],
          };
        }
        throw Exception('Access token missing from response payload');
      } else if (response.statusCode == 429) {
        throw Exception(
          response.data['message'] ?? 'Too many attempts. Try again later.',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password. Access denied.');
      } else {
        throw Exception(
          response.data['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timed out. Please check your internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network unreachable. Please try again later.');
      } else {
        throw Exception(
          e.response?.data?['message'] ??
              e.message ??
              'An unexpected network error occurred.',
        );
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}

/// Mock implementation for local testing without backend
class MockLoginRepository implements LoginRepository {
  @override
  Future<LoginResult> login(
    String email,
    String password, {
    bool trustDevice = false,
    String? portalType,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'vishal.vish16@gmail.com' && password == 'password123') {
      return {'access_token': 'mock_jwt_token_123'};
    } else {
      throw Exception('Invalid demo credentials. Use vishal.vish16@gmail.com');
    }
  }
}

/// Toggle this to use real API or Mock
const bool useMockAuth = false;

/// Provider to switch between mock and real repository
final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  if (useMockAuth) {
    return MockLoginRepository();
  }
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
