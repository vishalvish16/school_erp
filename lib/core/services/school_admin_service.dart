// =============================================================================
// FILE: lib/core/services/school_admin_service.dart
// PURPOSE: School Admin API service — all endpoints for the school portal.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../models/school_admin/dashboard_stats_model.dart';
import '../../models/school_admin/student_model.dart';
import '../../models/school_admin/staff_model.dart';
import '../../models/school_admin/staff_qualification_model.dart';
import '../../models/school_admin/staff_document_model.dart';
import '../../models/school_admin/staff_subject_assignment_model.dart';
import '../../models/school_admin/staff_leave_model.dart';
import '../../models/school_admin/staff_timetable_model.dart';
import '../../models/school_admin/school_class_model.dart';
import '../../models/school_admin/section_model.dart';
import '../../models/school_admin/attendance_model.dart';
import '../../models/school_admin/fee_structure_model.dart';
import '../../models/school_admin/fee_payment_model.dart';
import '../../models/school_admin/school_notice_model.dart';
import '../../models/school_admin/non_teaching_staff_role_model.dart';
import '../../models/school_admin/non_teaching_staff_model.dart';
import '../../models/school_admin/non_teaching_qualification_model.dart';
import '../../models/school_admin/non_teaching_document_model.dart';
import '../../models/school_admin/non_teaching_leave_model.dart';

const String _base = '/api/school';
const String _authBase = '/api/school/auth';

class SchoolAdminService {
  SchoolAdminService(this._dio);

  final Dio _dio;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<DashboardStatsModel> getDashboardStats() async {
    final res = await _dio.get('$_base/dashboard/stats');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return DashboardStatsModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Academic Years ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAcademicYears() async {
    final res = await _dio.get('$_base/academic-years');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final list = data is List ? data : <dynamic>[];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Students ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
    String? classId,
    String? sectionId,
    String? status,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (classId != null && classId.isNotEmpty) q['classId'] = classId;
    if (sectionId != null && sectionId.isNotEmpty) q['sectionId'] = sectionId;
    if (status != null && status.isNotEmpty) q['status'] = status;

    final res = await _dio.get('$_base/students', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<StudentModel> getStudentById(String id) async {
    final res = await _dio.get('$_base/students/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StudentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StudentModel> createStudent(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/students', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StudentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StudentModel> updateStudent(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/students/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StudentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteStudent(String id) async {
    await _dio.delete('$_base/students/$id');
  }

  // ── Staff ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStaff({
    int page = 1,
    int limit = 20,
    String? search,
    String? designation,
    bool? isActive,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (designation != null && designation.isNotEmpty) {
      q['designation'] = designation;
    }
    if (isActive != null) q['isActive'] = isActive;

    final res = await _dio.get('$_base/staff', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<StaffModel> getStaffById(String id) async {
    final res = await _dio.get('$_base/staff/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  /// Get suggested employee number based on school and staff name.
  Future<String> getSuggestedEmployeeNo({
    String? firstName,
    String? lastName,
  }) async {
    final q = <String, dynamic>{};
    if (firstName != null && firstName.isNotEmpty) q['firstName'] = firstName;
    if (lastName != null && lastName.isNotEmpty) q['lastName'] = lastName;
    final res = await _dio.get('$_base/staff/suggest-employee-no',
        queryParameters: q.isNotEmpty ? q : null);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is Map && data['employeeNo'] != null) {
      return data['employeeNo'] as String;
    }
    return 'EMP-001';
  }

  /// Check if employee number is available (not taken by another staff).
  /// [excludeStaffId] used when editing to exclude current staff.
  Future<Map<String, dynamic>> checkEmployeeNoAvailability(
    String employeeNo, {
    String? excludeStaffId,
  }) async {
    final q = <String, dynamic>{'employeeNo': employeeNo};
    if (excludeStaffId != null && excludeStaffId.isNotEmpty) {
      q['excludeStaffId'] = excludeStaffId;
    }
    final res = await _dio.get('$_base/staff/check-employee-no',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {'available': false};
  }

  Future<StaffModel> createStaff(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/staff', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StaffModel> updateStaff(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/staff/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteStaff(String id) async {
    await _dio.delete('$_base/staff/$id');
  }

  Future<void> updateStaffStatus(String id, bool isActive,
      {String? reason}) async {
    await _dio.put('$_base/staff/$id/status', data: {
      'isActive': isActive,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> createStaffLogin(String staffId, String password) async {
    await _dio.post('$_base/staff/$staffId/create-login', data: {
      'password': password,
    });
  }

  Future<void> resetStaffPassword(String staffId, String newPassword) async {
    await _dio.post('$_base/staff/$staffId/reset-password', data: {
      'newPassword': newPassword,
    });
  }

  // ── Staff Qualifications ──────────────────────────────────────────────────
  Future<List<StaffQualificationModel>> getStaffQualifications(
      String staffId) async {
    final res = await _dio.get('$_base/staff/$staffId/qualifications');
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : null;
    }
    if (list is! List) return [];
    return list
        .map((e) => StaffQualificationModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<StaffQualificationModel> addQualification(
      String staffId, Map<String, dynamic> body) async {
    final res =
        await _dio.post('$_base/staff/$staffId/qualifications', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffQualificationModel.fromJson(
        data is Map<String, dynamic> ? data : {});
  }

  Future<StaffQualificationModel> updateQualification(
      String staffId, String qualId, Map<String, dynamic> body) async {
    final res = await _dio.put(
        '$_base/staff/$staffId/qualifications/$qualId',
        data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffQualificationModel.fromJson(
        data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteQualification(String staffId, String qualId) async {
    await _dio.delete('$_base/staff/$staffId/qualifications/$qualId');
  }

  // ── Staff Documents ───────────────────────────────────────────────────────
  Future<List<StaffDocumentModel>> getStaffDocuments(String staffId) async {
    final res = await _dio.get('$_base/staff/$staffId/documents');
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : null;
    }
    if (list is! List) return [];
    return list
        .map((e) => StaffDocumentModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<StaffDocumentModel> addDocument(
      String staffId, Map<String, dynamic> body) async {
    final res =
        await _dio.post('$_base/staff/$staffId/documents', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffDocumentModel.fromJson(
        data is Map<String, dynamic> ? data : {});
  }

  Future<void> verifyDocument(String staffId, String docId) async {
    await _dio.put('$_base/staff/$staffId/documents/$docId/verify');
  }

  Future<void> deleteDocument(String staffId, String docId) async {
    await _dio.delete('$_base/staff/$staffId/documents/$docId');
  }

  // ── Staff Subject Assignments ─────────────────────────────────────────────
  Future<List<StaffSubjectAssignmentModel>> getSubjectAssignments(
      String staffId, {String? academicYear}) async {
    final q = <String, dynamic>{};
    if (academicYear != null) q['academicYear'] = academicYear;
    final res = await _dio.get('$_base/staff/$staffId/subject-assignments',
        queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : null;
    }
    if (list is! List) return [];
    return list
        .map((e) => StaffSubjectAssignmentModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<StaffSubjectAssignmentModel> addSubjectAssignment(
      String staffId, Map<String, dynamic> body) async {
    final res = await _dio
        .post('$_base/staff/$staffId/subject-assignments', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffSubjectAssignmentModel.fromJson(
        data is Map<String, dynamic> ? data : {});
  }

  Future<void> removeSubjectAssignment(
      String staffId, String assignId) async {
    await _dio
        .delete('$_base/staff/$staffId/subject-assignments/$assignId');
  }

  // ── Staff Timetable ───────────────────────────────────────────────────────
  Future<StaffTimetableModel> getStaffTimetable(String staffId) async {
    final res = await _dio.get('$_base/staff/$staffId/timetable');
    final raw = res.data;
    final data = raw is Map ? raw['data'] ?? raw : raw;
    return StaffTimetableModel.fromJson(
        data is Map<String, dynamic> ? data : {});
  }

  // ── Staff Leaves ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLeaves({
    int page = 1,
    int limit = 20,
    String? status,
    String? staffId,
    String? leaveType,
    String? fromDate,
    String? toDate,
    String? academicYear,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (staffId != null && staffId.isNotEmpty) q['staffId'] = staffId;
    if (leaveType != null && leaveType.isNotEmpty) q['leaveType'] = leaveType;
    if (fromDate != null && fromDate.isNotEmpty) q['fromDate'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) q['toDate'] = toDate;
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academicYear'] = academicYear;
    }
    final res =
        await _dio.get('$_base/staff/leaves', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<List<StaffLeaveModel>> getStaffLeaves(
    String staffId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? academicYear,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academicYear'] = academicYear;
    }
    final res = await _dio.get('$_base/staff/$staffId/leaves',
        queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      // Backend returns { data: { data: [...], pagination: {} } }
      if (inner is Map) {
        list = inner['data'];
      } else if (inner is List) {
        list = inner;
      }
    }
    if (list is! List) return [];
    return list
        .map((e) => StaffLeaveModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<StaffLeaveModel> applyLeave(
      String staffId, Map<String, dynamic> body) async {
    final res =
        await _dio.post('$_base/staff/$staffId/leaves', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffLeaveModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StaffLeaveModel> reviewLeave(String leaveId, String status,
      {String? adminRemark}) async {
    final res = await _dio.put('$_base/staff/leaves/$leaveId/review', data: {
      'status': status,
      if (adminRemark != null && adminRemark.isNotEmpty)
        'adminRemark': adminRemark,
    });
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffLeaveModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<StaffLeaveModel> cancelLeave(String leaveId) async {
    final res = await _dio.put('$_base/staff/leaves/$leaveId/cancel');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return StaffLeaveModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<Map<String, dynamic>> getLeaveSummary({
    String? academicYear,
    String? staffId,
  }) async {
    final q = <String, dynamic>{};
    if (academicYear != null && academicYear.isNotEmpty) {
      q['academicYear'] = academicYear;
    }
    if (staffId != null && staffId.isNotEmpty) q['staffId'] = staffId;
    final res = await _dio.get('$_base/staff/leaves/summary',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Classes ───────────────────────────────────────────────────────────────
  Future<List<SchoolClassModel>> getClasses() async {
    final res = await _dio.get('$_base/classes');
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => SchoolClassModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<SchoolClassModel> createClass(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/classes', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SchoolClassModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<SchoolClassModel> updateClass(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/classes/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SchoolClassModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteClass(String id) async {
    await _dio.delete('$_base/classes/$id');
  }

  // ── Sections ──────────────────────────────────────────────────────────────
  Future<List<SectionModel>> getSections(String classId) async {
    final res = await _dio.get('$_base/classes/$classId/sections');
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => SectionModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<SectionModel> createSection(
      String classId, Map<String, dynamic> body) async {
    final res =
        await _dio.post('$_base/classes/$classId/sections', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SectionModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<SectionModel> updateSection(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/sections/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SectionModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteSection(String id) async {
    await _dio.delete('$_base/sections/$id');
  }

  // ── Attendance ────────────────────────────────────────────────────────────
  Future<List<AttendanceRecord>> getAttendance({
    String? classId,
    String? sectionId,
    String? date,
  }) async {
    final q = <String, dynamic>{};
    if (classId != null) q['classId'] = classId;
    if (sectionId != null) q['sectionId'] = sectionId;
    if (date != null) q['date'] = date;

    final res = await _dio.get('$_base/attendance', queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => AttendanceRecord.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<Map<String, dynamic>> bulkMarkAttendance({
    required String sectionId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    final res = await _dio.post('$_base/attendance/bulk', data: {
      'sectionId': sectionId,
      'date': date,
      'records': records,
    });
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<AttendanceReportModel> getAttendanceReport({
    String? classId,
    String? sectionId,
    String? month,
  }) async {
    final q = <String, dynamic>{};
    if (classId != null) q['classId'] = classId;
    if (sectionId != null) q['sectionId'] = sectionId;
    if (month != null) q['month'] = month;

    final res =
        await _dio.get('$_base/attendance/report', queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return AttendanceReportModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  // ── Fee Structures ────────────────────────────────────────────────────────
  Future<List<FeeStructureModel>> getFeeStructures({
    String? academicYear,
    String? classId,
  }) async {
    final q = <String, dynamic>{};
    if (academicYear != null) q['academicYear'] = academicYear;
    if (classId != null) q['classId'] = classId;

    final res =
        await _dio.get('$_base/fees/structures', queryParameters: q);
    if (res.statusCode != null && res.statusCode! >= 400) {
      final msg = res.data is Map ? res.data['message'] as String? : null;
      throw Exception(msg ?? 'Failed to load fee structures');
    }
    final raw = res.data;
    if (raw is Map && raw['success'] == false) {
      throw Exception(raw['message'] as String? ?? 'Failed to load fee structures');
    }
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    if (list is! List) return [];
    return list
        .map((e) => FeeStructureModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<FeeStructureModel> createFeeStructure(
      Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/fees/structures', data: body);
    if (res.statusCode != null && res.statusCode! >= 400) {
      final msg = res.data is Map ? res.data['message'] as String? : null;
      throw Exception(msg ?? 'Failed to create fee structure');
    }
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return FeeStructureModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<FeeStructureModel> updateFeeStructure(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/fees/structures/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return FeeStructureModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteFeeStructure(String id) async {
    await _dio.delete('$_base/fees/structures/$id');
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
    if (studentId != null) q['studentId'] = studentId;
    if (month != null) q['month'] = month;
    if (academicYear != null) q['academicYear'] = academicYear;

    final res = await _dio.get('$_base/fees/payments', queryParameters: q);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<FeePaymentModel> getFeePaymentById(String id) async {
    final res = await _dio.get('$_base/fees/payments/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return FeePaymentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<FeePaymentModel> collectFee(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/fees/payments', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return FeePaymentModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<Map<String, dynamic>> getFeeSummary({String? month}) async {
    final q = <String, dynamic>{};
    if (month != null) q['month'] = month;
    final res = await _dio.get('$_base/fees/summary', queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Timetable ─────────────────────────────────────────────────────────────
  Future<List<dynamic>> getTimetable({
    String? classId,
    String? sectionId,
  }) async {
    final q = <String, dynamic>{};
    if (classId != null) q['classId'] = classId;
    if (sectionId != null) q['sectionId'] = sectionId;

    final res = await _dio.get('$_base/timetable', queryParameters: q);
    final raw = res.data;
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      list = inner is List ? inner : (inner is Map ? inner['data'] : null);
    }
    return list is List ? list : [];
  }

  Future<Map<String, dynamic>> updateTimetableBulk(
      Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/timetable/bulk', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Notices ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotices({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) q['search'] = search;

    final res = await _dio.get('$_base/notices', queryParameters: q);
    final raw = res.data;
    return raw is Map && raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : {'data': [], 'pagination': {}};
  }

  Future<SchoolNoticeModel> createNotice(Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/notices', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SchoolNoticeModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<SchoolNoticeModel> updateNotice(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/notices/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SchoolNoticeModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<void> deleteNotice(String id) async {
    await _dio.delete('$_base/notices/$id');
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

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('$_base/profile');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/profile/user', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> updateSchoolProfile(
      Map<String, dynamic> body) async {
    final res = await _dio.put('$_base/profile/school', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
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

  // ── Non-Teaching Roles ────────────────────────────────────────────────────
  Future<List<NonTeachingStaffRoleModel>> getNonTeachingRoles(
      {bool includeInactive = false}) async {
    final res = await _dio.get('$_base/non-teaching/roles',
        queryParameters: {'includeInactive': includeInactive});
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] : []);
    return (list as List)
        .map((e) =>
            NonTeachingStaffRoleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NonTeachingStaffRoleModel> createNonTeachingRole(
      Map<String, dynamic> body) async {
    final res =
        await _dio.post('$_base/non-teaching/roles', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingStaffRoleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NonTeachingStaffRoleModel> updateNonTeachingRole(
      String roleId, Map<String, dynamic> body) async {
    final res =
        await _dio.put('$_base/non-teaching/roles/$roleId', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingStaffRoleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> toggleNonTeachingRole(String roleId) async {
    await _dio.patch('$_base/non-teaching/roles/$roleId/toggle');
  }

  Future<void> deleteNonTeachingRole(String roleId) async {
    await _dio.delete('$_base/non-teaching/roles/$roleId');
  }

  // ── Non-Teaching Staff CRUD ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getNonTeachingStaffList({
    int page = 1,
    int limit = 20,
    String? search,
    String? roleId,
    String? category,
    String? department,
    String? employeeType,
    bool? isActive,
    String sortBy = 'firstName',
    String sortOrder = 'asc',
  }) async {
    final q = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (roleId != null) q['roleId'] = roleId;
    if (category != null) q['category'] = category;
    if (department != null) q['department'] = department;
    if (employeeType != null) q['employeeType'] = employeeType;
    if (isActive != null) q['isActive'] = isActive;
    final res = await _dio.get('$_base/non-teaching/staff', queryParameters: q);
    final raw = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return raw is Map<String, dynamic>
        ? raw
        : {'data': [], 'pagination': {}};
  }

  Future<NonTeachingStaffModel> getNonTeachingStaffById(String id) async {
    final res = await _dio.get('$_base/non-teaching/staff/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingStaffModel.fromJson(data as Map<String, dynamic>);
  }

  Future<String> suggestNonTeachingEmployeeNo() async {
    final res = await _dio.get('$_base/non-teaching/staff/suggest-employee-no');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final val = data is Map
        ? (data['employee_no'] ?? data['employeeNo'] ?? '')
        : '';
    return val.toString();
  }

  Future<NonTeachingStaffModel> createNonTeachingStaff(
      Map<String, dynamic> body) async {
    final res = await _dio.post('$_base/non-teaching/staff', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingStaffModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NonTeachingStaffModel> updateNonTeachingStaff(
      String id, Map<String, dynamic> body) async {
    final res =
        await _dio.put('$_base/non-teaching/staff/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingStaffModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteNonTeachingStaff(String id) async {
    await _dio.delete('$_base/non-teaching/staff/$id');
  }

  Future<void> updateNonTeachingStaffStatus(String id, bool isActive) async {
    await _dio.patch('$_base/non-teaching/staff/$id/status',
        data: {'is_active': isActive});
  }

  Future<void> createNonTeachingStaffLogin(
      String id, String password) async {
    await _dio.post('$_base/non-teaching/staff/$id/create-login',
        data: {'password': password});
  }

  Future<void> resetNonTeachingStaffPassword(
      String id, String newPassword) async {
    await _dio.post('$_base/non-teaching/staff/$id/reset-password',
        data: {'new_password': newPassword});
  }

  // ── Non-Teaching Qualifications ───────────────────────────────────────────
  Future<List<NonTeachingQualificationModel>> getNonTeachingQualifications(
      String staffId) async {
    final res =
        await _dio.get('$_base/non-teaching/staff/$staffId/qualifications');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final list = data is List ? data : [];
    return (list as List)
        .map((e) => NonTeachingQualificationModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  Future<NonTeachingQualificationModel> addNonTeachingQualification(
      String staffId, Map<String, dynamic> body) async {
    final res = await _dio
        .post('$_base/non-teaching/staff/$staffId/qualifications', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingQualificationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NonTeachingQualificationModel> updateNonTeachingQualification(
      String staffId, String qualId, Map<String, dynamic> body) async {
    final res = await _dio.put(
        '$_base/non-teaching/staff/$staffId/qualifications/$qualId',
        data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingQualificationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteNonTeachingQualification(
      String staffId, String qualId) async {
    await _dio.delete(
        '$_base/non-teaching/staff/$staffId/qualifications/$qualId');
  }

  // ── Non-Teaching Documents ────────────────────────────────────────────────
  Future<List<NonTeachingDocumentModel>> getNonTeachingDocuments(
      String staffId) async {
    final res =
        await _dio.get('$_base/non-teaching/staff/$staffId/documents');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final list = data is List ? data : [];
    return (list as List)
        .map((e) =>
            NonTeachingDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NonTeachingDocumentModel> addNonTeachingDocument(
      String staffId, Map<String, dynamic> body) async {
    final res = await _dio
        .post('$_base/non-teaching/staff/$staffId/documents', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingDocumentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> verifyNonTeachingDocument(
      String staffId, String docId) async {
    await _dio.put(
        '$_base/non-teaching/staff/$staffId/documents/$docId/verify');
  }

  Future<void> deleteNonTeachingDocument(
      String staffId, String docId) async {
    await _dio.delete(
        '$_base/non-teaching/staff/$staffId/documents/$docId');
  }

  // ── Non-Teaching Attendance ───────────────────────────────────────────────
  Future<List<dynamic>> getNonTeachingAttendanceForDate(
    String date, {
    String? department,
    String? category,
  }) async {
    final q = <String, dynamic>{'date': date};
    if (department != null) q['department'] = department;
    if (category != null) q['category'] = category;
    final res = await _dio.get('$_base/non-teaching/attendance',
        queryParameters: q);
    // Backend returns { success: true, data: [...] } where data is a list of
    // { staff: {...}, attendance: {...}|null } entries.
    final raw = res.data;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is List) return inner;
    }
    if (raw is List) return raw;
    return [];
  }

  Future<Map<String, dynamic>> bulkMarkNonTeachingAttendance(
      Map<String, dynamic> body) async {
    final res = await _dio
        .post('$_base/non-teaching/attendance/bulk', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> getNonTeachingAttendanceReport({
    required String month,
    String? staffId,
    String? department,
  }) async {
    final q = <String, dynamic>{'month': month};
    if (staffId != null) q['staffId'] = staffId;
    if (department != null) q['department'] = department;
    final res = await _dio.get('$_base/non-teaching/attendance/report',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Non-Teaching Leaves (admin) ───────────────────────────────────────────
  Future<Map<String, dynamic>> getNonTeachingLeaves({
    int page = 1,
    int limit = 20,
    String? status,
    String? staffId,
    String? leaveType,
    String? fromDate,
    String? toDate,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status != 'ALL') q['status'] = status;
    if (staffId != null) q['staffId'] = staffId;
    if (leaveType != null) q['leaveType'] = leaveType;
    if (fromDate != null) q['fromDate'] = fromDate;
    if (toDate != null) q['toDate'] = toDate;
    final res = await _dio.get('$_base/non-teaching/leaves',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic>
        ? data
        : {'data': [], 'pagination': {}};
  }

  Future<Map<String, dynamic>> getNonTeachingLeaveSummary({
    String? staffId,
    String? academicYear,
  }) async {
    final q = <String, dynamic>{};
    if (staffId != null) q['staffId'] = staffId;
    if (academicYear != null) q['academicYear'] = academicYear;
    final res = await _dio.get('$_base/non-teaching/leaves/summary',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> reviewNonTeachingLeave(
      String leaveId, Map<String, dynamic> body) async {
    await _dio.put('$_base/non-teaching/leaves/$leaveId/review', data: body);
  }

  Future<void> cancelNonTeachingLeave(String leaveId) async {
    await _dio.put('$_base/non-teaching/leaves/$leaveId/cancel');
  }

  Future<List<NonTeachingLeaveModel>> getNonTeachingStaffLeaves(
    String staffId, {
    String? status,
    String? academicYear,
  }) async {
    final q = <String, dynamic>{};
    if (status != null) q['status'] = status;
    if (academicYear != null) q['academicYear'] = academicYear;
    final res = await _dio.get(
        '$_base/non-teaching/staff/$staffId/leaves',
        queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    final list = data is List
        ? data
        : (data is Map && data['data'] is List ? data['data'] : []);
    return (list as List)
        .map((e) =>
            NonTeachingLeaveModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NonTeachingLeaveModel> applyLeaveForNonTeachingStaff(
      String staffId, Map<String, dynamic> body) async {
    final res = await _dio
        .post('$_base/non-teaching/staff/$staffId/leaves', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingLeaveModel.fromJson(data as Map<String, dynamic>);
  }

  // ── Staff Portal: My Attendance & Leaves ──────────────────────────────────
  Future<Map<String, dynamic>> getMyNonTeachingAttendance(
      {String? month}) async {
    final q = <String, dynamic>{};
    if (month != null) q['month'] = month;
    final res = await _dio.get('/api/staff/my/attendance', queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> getMyNonTeachingLeaves(
      {String? status}) async {
    final q = <String, dynamic>{};
    if (status != null) q['status'] = status;
    final res =
        await _dio.get('/api/staff/my/leaves', queryParameters: q);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> getMyNonTeachingLeaveSummary() async {
    final res = await _dio.get('/api/staff/my/leave-summary');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<NonTeachingLeaveModel> applyMyLeave(
      Map<String, dynamic> body) async {
    final res = await _dio.post('/api/staff/my/leaves', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return NonTeachingLeaveModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cancelMyLeave(String leaveId) async {
    await _dio.put('/api/staff/my/leaves/$leaveId/cancel');
  }
}

final schoolAdminServiceProvider = Provider<SchoolAdminService>((ref) {
  return SchoolAdminService(ref.read(dioProvider));
});
