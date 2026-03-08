// =============================================================================
// FILE: lib/core/services/auth_service.dart
// PURPOSE: Auth API service — login, verify OTP, session check, logout, devices
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/school_identity.dart';
import '../../utils/device_fingerprint.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

class AuthService {
  AuthService(this._dio);

  final dynamic _dio;

  Future<SchoolIdentity?> resolveSubdomain(String subdomain) async {
    try {
      final res = await _dio.post(
        '/api/platform/auth/resolve-subdomain',
        data: {'subdomain': subdomain},
      );
      if (res.statusCode == 200 && res.data['success'] == true && res.data['data'] != null) {
        return SchoolIdentity.fromJson(Map<String, dynamic>.from(res.data['data']));
      }
    } catch (_) {}
    return null;
  }

  /// Login — returns either session tokens or requires_otp with otp_session_id
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? portalType,
    String? schoolId,
    bool trustDevice = false,
  }) async {
    final fingerprint = await DeviceFingerprint.generate();
    final data = {
      'identifier': identifier,
      'password': password,
      'portal_type': portalType ?? 'school_admin',
      'school_id': schoolId,
      'device_fingerprint': fingerprint,
      'device_meta': {
        'device_type': 'unknown',
        'trust_device': trustDevice,
      },
    };

    final res = await _dio.post(ApiConfig.loginEndpoint, data: data);
    if (res.statusCode == 200 && res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['data'] ?? {});
    }
    throw Exception(res.data['message'] ?? 'Login failed');
  }

  /// Verify 2FA (TOTP) — used when super admin has 2FA enabled
  Future<Map<String, dynamic>> verify2fa({
    required String tempToken,
    required String totpCode,
    bool trustDevice = true,
  }) async {
    final fingerprint = await DeviceFingerprint.generate();
    final res = await _dio.post(
      '/api/platform/auth/super-admin/verify-2fa',
      data: {
        'temp_token': tempToken,
        'totp_code': totpCode,
        'device_fingerprint': fingerprint,
        'device_meta': {'device_type': 'unknown', 'trust_device': trustDevice},
      },
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['data'] ?? {});
    }
    throw Exception(res.data['message'] ?? '2FA verification failed');
  }

  /// Verify device OTP
  Future<Map<String, dynamic>> verifyDeviceOtp({
    required String otpSessionId,
    required String otpCode,
    bool trustDevice = true,
    String? portalType,
  }) async {
    final fingerprint = await DeviceFingerprint.generate();
    final data = <String, dynamic>{
      'otp_session_id': otpSessionId,
      'otp_code': otpCode,
      'trust_device': trustDevice,
      'device_fingerprint': fingerprint,
      'device_meta': {'device_type': 'unknown'},
    };
    if (portalType != null) data['portal_type'] = portalType;
    final res = await _dio.post(
      '/api/platform/auth/verify-device-otp',
      data: data,
    );
    if (res.statusCode == 200 && res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['data'] ?? {});
    }
    throw Exception(res.data['message'] ?? 'Verification failed');
  }

  Future<Map<String, dynamic>?> checkSession() async {
    try {
      final res = await _dio.get('/api/platform/auth/session-check');
      if (res.statusCode == 200 && res.data['success'] == true && res.data['data'] != null) {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout({bool removeDeviceTrust = false}) async {
    try {
      await _dio.delete(
        '/api/platform/auth/logout',
        data: removeDeviceTrust ? {'remove_device_trust': true} : null,
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getMyDevices() async {
    try {
      final res = await _dio.get('/api/platform/auth/my-devices');
      if (res.statusCode == 200 && res.data['success'] == true && res.data['data'] != null) {
        return List<Map<String, dynamic>>.from(
          (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (_) {}
    return [];
  }

  Future<void> removeDevice(String deviceId) async {
    await _dio.delete('/api/platform/auth/devices/$deviceId');
  }
}
