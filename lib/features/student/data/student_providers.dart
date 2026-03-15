// =============================================================================
// FILE: lib/features/student/data/student_providers.dart
// PURPOSE: Riverpod providers for the Student portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/student_service.dart';
import '../../../models/student/student_profile_model.dart';
import '../../../models/student/student_dashboard_model.dart';
import '../../../models/student/student_attendance_model.dart';
import '../../../models/student/student_fee_models.dart';
import '../../../models/student/student_timetable_model.dart';
import '../../../models/student/student_notice_model.dart';
import '../../../models/student/student_document_model.dart';

final studentProfileProvider =
    FutureProvider.autoDispose<StudentProfileModel>((ref) {
  return ref.read(studentServiceProvider).getProfile();
});

final studentDashboardProvider =
    FutureProvider.autoDispose<StudentDashboardModel>((ref) {
  return ref.read(studentServiceProvider).getDashboard();
});

final studentAttendanceProvider =
    FutureProvider.autoDispose.family<StudentAttendanceModel, String>((ref, month) {
  return ref.read(studentServiceProvider).getAttendance(month: month);
});

final studentAttendanceSummaryProvider =
    FutureProvider.autoDispose.family<AttendanceSummaryModel, String?>((ref, month) {
  return ref.read(studentServiceProvider).getAttendanceSummary(month: month);
});

final studentFeeDuesProvider =
    FutureProvider.autoDispose<StudentFeeDuesModel>((ref) {
  return ref.read(studentServiceProvider).getFeeDues();
});

final studentFeePaymentsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, page) {
  return ref.read(studentServiceProvider).getFeePayments(page: page);
});

final studentTimetableProvider =
    FutureProvider.autoDispose<StudentTimetableModel>((ref) {
  return ref.read(studentServiceProvider).getTimetable();
});

final studentNoticesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, page) {
  return ref.read(studentServiceProvider).getNotices(page: page);
});

final studentNoticeByIdProvider =
    FutureProvider.autoDispose.family<StudentNoticeModel, String>((ref, id) {
  return ref.read(studentServiceProvider).getNoticeById(id);
});

final studentDocumentsProvider =
    FutureProvider.autoDispose<List<StudentDocumentModel>>((ref) {
  return ref.read(studentServiceProvider).getDocuments();
});

final studentReceiptProvider =
    FutureProvider.autoDispose.family<StudentReceiptModel, String>((ref, receiptNo) {
  return ref.read(studentServiceProvider).getReceiptByReceiptNo(receiptNo);
});
