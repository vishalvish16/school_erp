import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/teacher/teacher_dashboard_model.dart';
import '../../models/teacher/attendance_model.dart';
import '../../models/teacher/homework_model.dart';
import '../../models/teacher/class_diary_model.dart';
import '../../models/teacher/teacher_profile_model.dart';

class TeacherService {
  TeacherService(this._dio);

  final Dio _dio;

  // ── Dashboard ──────────────────────────────────────────────────────────────
  Future<TeacherDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiConfig.teacherDashboard);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return TeacherDashboardModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────
  Future<List<TeacherSectionModel>> getSections() async {
    final res = await _dio.get(ApiConfig.teacherSections);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : null;
    }
    if (list is! List) return [];
    return list
        .map((e) =>
            TeacherSectionModel.fromJson(e is Map<String, dynamic> ? e : {}))
        .toList();
  }

  // ── Attendance ─────────────────────────────────────────────────────────────
  Future<SectionAttendanceModel> getAttendance(
    String sectionId, {
    String? date,
  }) async {
    final q = <String, dynamic>{'sectionId': sectionId};
    if (date != null && date.isNotEmpty) q['date'] = date;
    final res =
        await _dio.get(ApiConfig.teacherAttendance, queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SectionAttendanceModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Map<String, dynamic>> markAttendance(
      Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.teacherAttendance, data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<AttendanceReportModel> getAttendanceReport(
    String sectionId, {
    String? fromDate,
    String? toDate,
  }) async {
    final q = <String, dynamic>{'sectionId': sectionId};
    if (fromDate != null && fromDate.isNotEmpty) q['fromDate'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) q['toDate'] = toDate;
    final res = await _dio.get(ApiConfig.teacherAttendanceReport,
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return AttendanceReportModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Homework ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHomework({
    int page = 1,
    int limit = 20,
    String? classId,
    String? sectionId,
    String? subject,
    String? status,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (classId != null && classId.isNotEmpty) q['classId'] = classId;
    if (sectionId != null && sectionId.isNotEmpty) q['sectionId'] = sectionId;
    if (subject != null && subject.isNotEmpty) q['subject'] = subject;
    if (status != null && status.isNotEmpty) q['status'] = status;
    final res =
        await _dio.get(ApiConfig.teacherHomework, queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': {}, 'pagination': {}};
  }

  Future<HomeworkModel> createHomework(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.teacherHomework, data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return HomeworkModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<HomeworkModel> getHomeworkDetail(String id) async {
    final res = await _dio.get('${ApiConfig.teacherHomework}/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return HomeworkModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<HomeworkModel> updateHomework(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConfig.teacherHomework}/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return HomeworkModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> updateHomeworkStatus(String id, String status) async {
    await _dio.put('${ApiConfig.teacherHomework}/$id/status',
        data: {'status': status});
  }

  Future<void> deleteHomework(String id) async {
    await _dio.delete('${ApiConfig.teacherHomework}/$id');
  }

  // ── Class Diary ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDiaryEntries({
    int page = 1,
    int limit = 20,
    String? classId,
    String? sectionId,
    String? subject,
    String? fromDate,
    String? toDate,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (classId != null && classId.isNotEmpty) q['classId'] = classId;
    if (sectionId != null && sectionId.isNotEmpty) q['sectionId'] = sectionId;
    if (subject != null && subject.isNotEmpty) q['subject'] = subject;
    if (fromDate != null && fromDate.isNotEmpty) q['fromDate'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) q['toDate'] = toDate;
    final res = await _dio.get(ApiConfig.teacherDiary, queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': {}, 'pagination': {}};
  }

  Future<ClassDiaryModel> createDiaryEntry(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiConfig.teacherDiary, data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return ClassDiaryModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<ClassDiaryModel> updateDiaryEntry(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('${ApiConfig.teacherDiary}/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return ClassDiaryModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteDiaryEntry(String id) async {
    await _dio.delete('${ApiConfig.teacherDiary}/$id');
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<TeacherProfileModel> getProfile() async {
    final res = await _dio.get(ApiConfig.teacherProfile);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return TeacherProfileModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }
}

final teacherServiceProvider = Provider<TeacherService>((ref) {
  return TeacherService(ref.read(dioProvider));
});
