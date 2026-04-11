// =============================================================================
// FILE: lib/core/services/parent_service.dart
// PURPOSE: Parent Portal API service — all endpoints for /api/parent/.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/parent/parent_models.dart';
import '../../models/parent/parent_notification_model.dart';

class ParentService {
  ParentService(this._dio);

  final Dio _dio;

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<ParentProfileModel> getProfile() async {
    final res = await _dio.get(ApiConfig.parentProfile);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return ParentProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<ParentProfileModel> updateProfile(Map<String, dynamic> body) async {
    final res = await _dio.patch(ApiConfig.parentProfile, data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return ParentProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Children ──────────────────────────────────────────────────────────────
  Future<List<ChildSummaryModel>> getChildren() async {
    final res = await _dio.get(ApiConfig.parentChildren);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final data = raw['data'];
      list = raw['children'] ?? (data is Map ? data['children'] : null) ?? data;
      if (list is Map && list['data'] is List) list = list['data'];
      if (list is Map && list['children'] is List) list = list['children'];
    }
    if (list is! List) return [];
    return list
        .map((e) => ChildSummaryModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<ChildDetailModel?> getChildById(String studentId) async {
    try {
      final res = await _dio.get('${ApiConfig.parentChildren}/$studentId');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return ChildDetailModel.fromJson(
        data is Map<String, dynamic> ? data : {},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<AttendanceEntryModel>> getChildAttendance(
    String studentId, {
    String? month,
    int? limit,
  }) async {
    final q = <String, dynamic>{};
    if (month != null && month.isNotEmpty) q['month'] = month;
    if (limit != null) q['limit'] = limit;

    final res = await _dio.get(
      '${ApiConfig.parentChildren}/$studentId/attendance',
      queryParameters: q.isEmpty ? null : q,
    );
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final data = raw['data'];
      list = raw['attendances'] ?? (data is Map ? data['attendances'] : null) ?? data;
      if (list is Map && list['data'] is List) list = list['data'];
      if (list is Map && list['attendances'] is List) list = list['attendances'];
    }
    if (list is! List) return [];
    return list
        .map((e) => AttendanceEntryModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<Map<String, dynamic>> getChildFees(
    String studentId, {
    String? academicYear,
  }) async {
    final q = <String, dynamic>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academic_year'] = academicYear;
    }

    final res = await _dio.get(
      '${ApiConfig.parentChildren}/$studentId/fees',
      queryParameters: q.isEmpty ? null : q,
    );
    final raw = res.data is Map ? res.data as Map<String, dynamic> : {};
    final data = raw['data'] ?? raw;

    List<FeePaymentSummaryModel> feePayments = [];
    List<FeeStructureSummaryModel> feeStructure = [];

    if (data is Map) {
      final payments = data['feePayments'] ?? data['fee_payments'];
      if (payments is List) {
        feePayments = payments
            .map((e) => FeePaymentSummaryModel.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList();
      }
      final structure = data['feeStructure'] ?? data['fee_structure'];
      if (structure is List) {
        feeStructure = structure
            .map((e) => FeeStructureSummaryModel.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList();
      }
    }

    return {
      'feePayments': feePayments,
      'feeStructure': feeStructure,
    };
  }

  // ── Notices ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotices({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConfig.parentNotices,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    if (raw is! Map) return {'notices': [], 'pagination': {}};

    final data = raw['data'];
    final noticesRaw = raw['notices'] ?? (data is Map ? data['notices'] : null) ?? data;
    List<NoticeSummaryModel> notices = [];
    if (noticesRaw is List) {
      notices = noticesRaw
          .map((e) => NoticeSummaryModel.fromJson(
                e is Map<String, dynamic> ? e : {},
              ))
          .toList();
    }

    Map<String, dynamic> pagination = {};
    final pagRaw = raw['pagination'] ?? (data is Map ? data['pagination'] : null);
    if (pagRaw is Map) {
      pagination = Map<String, dynamic>.from(pagRaw);
    }

    return {'notices': notices, 'pagination': pagination};
  }

  Future<NoticeDetailModel?> getNoticeById(String id) async {
    try {
      final res = await _dio.get('${ApiConfig.parentNotices}/$id');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      return NoticeDetailModel.fromJson(
        data is Map<String, dynamic> ? data : {},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Bus Location ──────────────────────────────────────────────────────────
  Future<BusLocationModel> getChildBusLocation(String studentId) async {
    final res = await _dio.get('${ApiConfig.parentChildren}/$studentId/bus');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return BusLocationModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  // ── Attendance Summary ───────────────────────────────────────────────────
  Future<AttendanceSummaryModel> getChildAttendanceSummary(
    String studentId, {
    String? month,
  }) async {
    final q = <String, dynamic>{};
    if (month != null) q['month'] = month;
    final res = await _dio.get(
      '${ApiConfig.parentChildren}/$studentId/attendance/summary',
      queryParameters: q.isEmpty ? null : q,
    );
    final raw = res.data;
    final data = raw is Map ? (raw['data'] ?? raw) : {};
    return AttendanceSummaryModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Timetable ──────────────────────────────────────────────────────────────
  Future<List<TimetableSlotModel>> getChildTimetable(String studentId) async {
    final res = await _dio.get(
      '${ApiConfig.parentChildren}/$studentId/timetable',
    );
    final raw = res.data;
    final data = raw is Map ? (raw['data'] ?? raw) : {};
    final list = data is Map ? (data['slots'] ?? data['timetable'] ?? []) : [];
    if (list is! List) return [];
    return list
        .map((e) =>
            TimetableSlotModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();
  }

  // ── Documents ──────────────────────────────────────────────────────────────
  Future<List<StudentDocumentModel>> getChildDocuments(
      String studentId) async {
    final res = await _dio.get(
      '${ApiConfig.parentChildren}/$studentId/documents',
    );
    final raw = res.data;
    final data = raw is Map ? (raw['data'] ?? raw) : {};
    final list =
        data is Map ? (data['documents'] ?? data['data'] ?? []) : [];
    if (list is! List) return [];
    return list
        .map((e) =>
            StudentDocumentModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConfig.parentNotifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    if (raw is! Map) return {'data': [], 'pagination': {}};

    final data = raw['data'];
    final list = data is Map ? (data['data'] ?? data) : raw['data'];
    final notifications = list is List
        ? list
            .map((e) => ParentNotificationModel.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <ParentNotificationModel>[];

    final pagination = (data is Map ? data['pagination'] : raw['pagination'])
        as Map<String, dynamic>?;

    return {
      'data': notifications,
      'pagination': pagination ?? {},
    };
  }

  Future<int> getUnreadNotificationCount() async {
    final res = await _dio.get(ApiConfig.parentNotificationsUnreadCount);
    final raw = res.data;
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map && data['count'] != null) {
        return (data['count'] as num).toInt();
      }
    }
    return 0;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.put('${ApiConfig.parentNotifications}/$id/read');
  }

  // ── Change Password ────────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(ApiConfig.parentChangePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ── Auth (parent login) ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resolveUserByPhone({
    required String phone,
    required String userType,
  }) async {
    final res = await _dio.post(
      ApiConfig.resolveUserByPhone,
      data: {'phone': phone, 'user_type': userType},
    );
    final data = res.data;
    if (data is Map && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> verifyParentOtp({
    required String otpSessionId,
    required String otp,
    required String phone,
    required String schoolId,
  }) async {
    final res = await _dio.post(
      ApiConfig.verifyParentOtp,
      data: {
        'otp_session_id': otpSessionId,
        'otp': otp,
        'phone': phone,
        'school_id': schoolId,
      },
    );
    final data = res.data;
    if (data is Map && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> verifyStudentOtp({
    required String otpSessionId,
    required String otp,
    required String phone,
    required String schoolId,
  }) async {
    final res = await _dio.post(
      ApiConfig.verifyStudentOtp,
      data: {
        'otp_session_id': otpSessionId,
        'otp': otp,
        'phone': phone,
        'school_id': schoolId,
      },
    );
    final data = res.data;
    if (data is Map && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response format');
  }
}

final parentServiceProvider = Provider<ParentService>((ref) {
  return ParentService(ref.read(dioProvider));
});
