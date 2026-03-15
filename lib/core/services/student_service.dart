// =============================================================================
// FILE: lib/core/services/student_service.dart
// PURPOSE: API service for the Student portal.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/student/student_profile_model.dart';
import '../../models/student/student_dashboard_model.dart';
import '../../models/student/student_attendance_model.dart';
import '../../models/student/student_fee_models.dart';
import '../../models/student/student_timetable_model.dart';
import '../../models/student/student_notice_model.dart';
import '../../models/student/student_document_model.dart';

class StudentService {
  StudentService(this._dio);

  final Dio _dio;

  dynamic _extractData(dynamic response) {
    final raw = response.data;
    if (raw is Map && raw.containsKey('data')) {
      return raw['data'];
    }
    return raw;
  }

  Future<StudentProfileModel> getProfile() async {
    final res = await _dio.get(ApiConfig.studentProfile);
    final data = _extractData(res);
    return StudentProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<StudentDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiConfig.studentDashboard);
    final data = _extractData(res);
    return StudentDashboardModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<StudentAttendanceModel> getAttendance({required String month}) async {
    final res = await _dio.get(
      ApiConfig.studentAttendance,
      queryParameters: {'month': month},
    );
    final data = _extractData(res);
    return StudentAttendanceModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<AttendanceSummaryModel> getAttendanceSummary({String? month}) async {
    final q = <String, dynamic>{};
    if (month != null && month.isNotEmpty) q['month'] = month;
    final res = await _dio.get(
      ApiConfig.studentAttendanceSummary,
      queryParameters: q.isNotEmpty ? q : null,
    );
    final data = _extractData(res);
    return AttendanceSummaryModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<StudentFeeDuesModel> getFeeDues() async {
    final res = await _dio.get(ApiConfig.studentFeeDues);
    final data = _extractData(res);
    return StudentFeeDuesModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Map<String, dynamic>> getFeePayments({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConfig.studentFeePayments,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': {}, 'pagination': {}};
  }

  Future<StudentReceiptModel> getReceiptByReceiptNo(String receiptNo) async {
    final res = await _dio.get(
      ApiConfig.studentFeeReceipt,
      queryParameters: {'receipt_no': receiptNo},
    );
    final data = _extractData(res);
    return StudentReceiptModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<StudentTimetableModel> getTimetable() async {
    final res = await _dio.get(ApiConfig.studentTimetable);
    final data = _extractData(res);
    return StudentTimetableModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Map<String, dynamic>> getNotices({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      ApiConfig.studentNotices,
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': {}, 'pagination': {}};
  }

  Future<StudentNoticeModel> getNoticeById(String id) async {
    final res = await _dio.get('${ApiConfig.studentNotices}/$id');
    final data = _extractData(res);
    return StudentNoticeModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<List<StudentDocumentModel>> getDocuments() async {
    final res = await _dio.get(ApiConfig.studentDocuments);
    final data = _extractData(res);
    final list = data is List ? data : (data is Map && data['documents'] is List ? data['documents'] : null);
    if (list is! List) return [];
    return list
        .map((e) => StudentDocumentModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(ApiConfig.studentChangePassword, data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(ref.read(dioProvider));
});
