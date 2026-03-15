// =============================================================================
// FILE: lib/core/services/staff_service.dart
// PURPOSE: Staff/Clerk portal API service — all endpoints for /api/staff/.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../models/staff/staff_dashboard_model.dart';
import '../../models/staff/staff_payment_model.dart';
import '../../models/staff/staff_fee_structure_model.dart';
import '../../models/staff/staff_student_model.dart';
import '../../models/staff/staff_notice_model.dart';
import '../../models/staff/staff_profile_model.dart';

const String _base = '/api/staff';
const String _authBase = '/api/staff/auth';

class StaffService {
  StaffService(this._dio);

  final Dio _dio;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<StaffDashboardModel> getDashboardStats() async {
    final res = await _dio.get('$_base/dashboard/stats');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffDashboardModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Fee Payments ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFeePayments({
    int page = 1,
    int limit = 20,
    String? studentId,
    String? month,
    String? academicYear,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (studentId != null && studentId.isNotEmpty) q['studentId'] = studentId;
    if (month != null && month.isNotEmpty) q['month'] = month;
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academicYear'] = academicYear;
    }

    final res = await _dio.get('$_base/fees/payments', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<StaffPaymentModel> getFeePaymentById(String id) async {
    final res = await _dio.get('$_base/fees/payments/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffPaymentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StaffPaymentModel> collectFee(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/fees/payments', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffPaymentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<Map<String, dynamic>> getFeeSummary({String? month}) async {
    final q = <String, dynamic>{};
    if (month != null && month.isNotEmpty) q['month'] = month;
    final res = await _dio.get('$_base/fees/summary', queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Fee Structures (read-only) ─────────────────────────────────────────────
  Future<List<StaffFeeStructureModel>> getFeeStructures({
    String? academicYear,
    String? classId,
  }) async {
    final q = <String, dynamic>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academicYear'] = academicYear;
    }
    if (classId != null && classId.isNotEmpty) q['classId'] = classId;

    final res = await _dio.get('$_base/fees/structures', queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => StaffFeeStructureModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  // ── Students (read-only) ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
    String? sectionId,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (classId != null && classId.isNotEmpty) q['classId'] = classId;
    if (sectionId != null && sectionId.isNotEmpty) q['sectionId'] = sectionId;

    final res = await _dio.get('$_base/students', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<StaffStudentModel> getStudentById(String id) async {
    final res = await _dio.get('$_base/students/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffStudentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  // ── Classes (for filters/dropdowns) ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getClasses() async {
    final res = await _dio.get('$_base/classes');
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
  }

  // ── Notices (read-only) ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotices({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '$_base/notices',
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : {'data': [], 'pagination': {}};
  }

  Future<StaffNoticeModel> getNoticeById(String id) async {
    final res = await _dio.get('$_base/notices/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffNoticeModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '$_base/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('$_base/notifications/unread-count');
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
    await _dio.put('$_base/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.put('$_base/notifications/read-all');
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<StaffProfileModel> getProfile() async {
    final res = await _dio.get('$_base/profile');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<StaffProfileModel> updateUserProfile(
      Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/profile/user', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<void> sendOtp() async {
    await _dio.post('$_base/profile/send-otp');
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('$_authBase/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.read(dioProvider));
});
