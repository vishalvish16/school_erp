// =============================================================================
// FILE: lib/core/services/group_admin_service.dart
// PURPOSE: Group Admin API service — dashboard, schools, profile, notifications, auth.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../models/group_admin/group_admin_models.dart';

const String _basePath = '/api/platform/group-admin';
const String _authPath = '/api/platform/auth/group-admin';

class GroupAdminService {
  GroupAdminService(this._dio);

  final Dio _dio;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<GroupAdminDashboardStats> getDashboardStats() async {
    final res = await _dio.get('$_basePath/dashboard/stats');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return GroupAdminDashboardStats.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Schools ───────────────────────────────────────────────────────────────
  Future<List<GroupAdminSchoolModel>> getSchools({
    String? search,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    final q = <String, String>{
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (search != null && search.isNotEmpty) q['search'] = search;

    final res = await _dio.get('$_basePath/schools', queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map && inner['data'] is List) {
        list = inner['data'];
      } else if (inner is List) {
        list = inner;
      } else {
        list = inner;
      }
    }
    if (list is! List) return [];
    return list
        .map((e) => GroupAdminSchoolModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<GroupAdminSchoolDetailModel> getSchoolById(String id) async {
    final res = await _dio.get('$_basePath/schools/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return GroupAdminSchoolDetailModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<GroupAdminProfileModel> getProfile() async {
    final res = await _dio.get('$_basePath/profile');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return GroupAdminProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Map<String, dynamic>> sendProfileOtp({String? email, String? phone}) async {
    final res = await _dio.post('$_basePath/profile/send-otp', data: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<GroupAdminProfileModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarBase64,
    String? otpSessionId,
    String? otpCode,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      body['avatar_base64'] = avatarBase64;
    }
    if (otpSessionId != null) body['otp_session_id'] = otpSessionId;
    if (otpCode != null) body['otp_code'] = otpCode;

    final res = await _dio.put('$_basePath/profile', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return GroupAdminProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put('$_basePath/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '$_basePath/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('$_basePath/notifications/unread-count');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      if (data is Map && data['count'] != null) {
        return (data['count'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.put('$_basePath/notifications/$id/read');
  }

  // ── Reports / Analytics ───────────────────────────────────────────────────
  Future<GroupAdminComparisonReport> getSchoolComparison() async {
    final res = await _dio.get('$_basePath/reports/comparison');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return GroupAdminComparisonReport.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Map<String, dynamic>> getAttendanceReport() async {
    try {
      final res = await _dio.get('$_basePath/reports/attendance');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return data is Map<String, dynamic>
          ? data
          : {'message': 'Attendance module not yet activated', 'data': []};
    } catch (_) {
      return {'message': 'Attendance module not yet activated', 'data': []};
    }
  }

  Future<Map<String, dynamic>> getFeesReport() async {
    try {
      final res = await _dio.get('$_basePath/reports/fees');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return data is Map<String, dynamic>
          ? data
          : {'message': 'Fees module not yet activated', 'data': []};
    } catch (_) {
      return {'message': 'Fees module not yet activated', 'data': []};
    }
  }

  Future<Map<String, dynamic>> getPerformanceReport() async {
    try {
      final res = await _dio.get('$_basePath/reports/performance');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return data is Map<String, dynamic>
          ? data
          : {'message': 'Performance module not yet activated', 'data': []};
    } catch (_) {
      return {'message': 'Performance module not yet activated', 'data': []};
    }
  }

  // ── Students ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentStats() async {
    final res = await _dio.get('$_basePath/students/stats');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Notices ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotices({int page = 1, int limit = 20, String? search}) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) q['search'] = search;
    final res = await _dio.get('$_basePath/notices', queryParameters: q);
    final raw = res.data;
    return raw is Map && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : {'data': [], 'pagination': {}};
  }

  Future<Map<String, dynamic>> createNotice(Map<String, dynamic> body) async {
    final res = await _dio.post('$_basePath/notices', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> updateNotice(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_basePath/notices/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> deleteNotice(String id) async {
    await _dio.delete('$_basePath/notices/$id');
  }

  // ── Alert Rules ───────────────────────────────────────────────────────────
  Future<List<dynamic>> getAlertRules() async {
    final res = await _dio.get('$_basePath/alerts');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> createAlertRule(Map<String, dynamic> body) async {
    final res = await _dio.post('$_basePath/alerts', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> updateAlertRule(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_basePath/alerts/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> deleteAlertRule(String id) async {
    await _dio.delete('$_basePath/alerts/$id');
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final res = await _dio.post('$_authPath/login', data: body);
    if (res.statusCode != null && res.statusCode! >= 400) {
      final data = res.data is Map ? res.data : {};
      final message = data['message'] ?? data['error'] ?? 'Login failed';
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: message,
      );
    }
    return res.data is Map<String, dynamic>
        ? (res.data['data'] ?? res.data) as Map<String, dynamic>
        : {};
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('$_authPath/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post('$_authPath/reset-password', data: {
      'token': token,
      'new_password': newPassword,
    });
  }
}

final groupAdminServiceProvider = Provider<GroupAdminService>((ref) {
  return GroupAdminService(ref.read(dioProvider));
});
