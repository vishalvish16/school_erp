// =============================================================================
// FILE: lib/core/services/parent_service.dart
// PURPOSE: Parent Portal API service — all endpoints for /api/parent/.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/parent/parent_models.dart';

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
      list = raw['children'] ?? raw['data'];
      if (list is Map && list['data'] is List) list = list['data'];
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
      list = raw['attendances'] ?? raw['data'];
      if (list is Map && list['data'] is List) list = list['data'];
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

    final noticesRaw = raw['notices'] ?? raw['data'];
    List<NoticeSummaryModel> notices = [];
    if (noticesRaw is List) {
      notices = noticesRaw
          .map((e) => NoticeSummaryModel.fromJson(
                e is Map<String, dynamic> ? e : {},
              ))
          .toList();
    }

    Map<String, dynamic> pagination = {};
    if (raw['pagination'] is Map) {
      pagination = Map<String, dynamic>.from(raw['pagination'] as Map);
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

  // ── Auth (parent login) ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resolveUserByPhone({
    required String phone,
    required String userType,
  }) async {
    final res = await _dio.post(
      ApiConfig.resolveUserByPhone,
      data: {'phone': phone, 'user_type': userType},
    );
    return res.data is Map<String, dynamic> ? res.data : {};
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
    return res.data is Map<String, dynamic> ? res.data : {};
  }
}

final parentServiceProvider = Provider<ParentService>((ref) {
  return ParentService(ref.read(dioProvider));
});
