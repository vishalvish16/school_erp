import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/attendance_model.dart';

// Sections the teacher is assigned to
final teacherSectionsProvider =
    FutureProvider.autoDispose<List<TeacherSectionModel>>((ref) {
  return ref.read(teacherServiceProvider).getSections();
});

// Attendance marking state
class TeacherAttendanceState {
  final TeacherSectionModel? selectedSection;
  final DateTime selectedDate;
  final SectionAttendanceModel? attendance;
  final List<StudentAttendanceRecord> editableRecords;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  TeacherAttendanceState({
    this.selectedSection,
    DateTime? selectedDate,
    this.attendance,
    this.editableRecords = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  }) : selectedDate = selectedDate ?? DateTime.now();

  TeacherAttendanceState copyWith({
    TeacherSectionModel? selectedSection,
    DateTime? selectedDate,
    SectionAttendanceModel? attendance,
    List<StudentAttendanceRecord>? editableRecords,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearAttendance = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TeacherAttendanceState(
      selectedSection: selectedSection ?? this.selectedSection,
      selectedDate: selectedDate ?? this.selectedDate,
      attendance: clearAttendance ? null : (attendance ?? this.attendance),
      editableRecords: editableRecords ?? this.editableRecords,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TeacherAttendanceNotifier extends StateNotifier<TeacherAttendanceState> {
  final TeacherService _service;

  TeacherAttendanceNotifier(this._service)
      : super(TeacherAttendanceState(selectedDate: DateTime.now()));

  void selectSection(TeacherSectionModel section) {
    state = state.copyWith(
      selectedSection: section,
      clearAttendance: true,
      clearError: true,
      clearSuccess: true,
    );
    loadAttendance();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      clearAttendance: true,
      clearError: true,
      clearSuccess: true,
    );
    if (state.selectedSection != null) loadAttendance();
  }

  Future<void> loadAttendance() async {
    final section = state.selectedSection;
    if (section == null) return;
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final dateStr =
          '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';
      final attendance =
          await _service.getAttendance(section.sectionId, date: dateStr);

      final records = attendance.students
          .map((s) => StudentAttendanceRecord(
                studentId: s.studentId,
                admissionNo: s.admissionNo,
                name: s.name,
                rollNo: s.rollNo,
                status: s.status,
                remarks: s.remarks,
              ))
          .toList();

      state = state.copyWith(
        attendance: attendance,
        editableRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateStudentStatus(String studentId, String newStatus) {
    final records = [...state.editableRecords];
    final idx = records.indexWhere((r) => r.studentId == studentId);
    if (idx >= 0) {
      records[idx].status = newStatus;
      state = state.copyWith(editableRecords: records, clearSuccess: true);
    }
  }

  void updateStudentRemarks(String studentId, String remarks) {
    final records = [...state.editableRecords];
    final idx = records.indexWhere((r) => r.studentId == studentId);
    if (idx >= 0) {
      records[idx].remarks = remarks.isEmpty ? null : remarks;
      state = state.copyWith(editableRecords: records);
    }
  }

  void markAllPresent() {
    final records = [...state.editableRecords];
    for (final r in records) {
      r.status = 'PRESENT';
    }
    state = state.copyWith(editableRecords: records, clearSuccess: true);
  }

  Future<bool> saveAttendance() async {
    final section = state.selectedSection;
    if (section == null || state.editableRecords.isEmpty) return false;
    if (state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final dateStr =
          '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';
      await _service.markAttendance({
        'section_id': section.sectionId,
        'date': dateStr,
        'records': state.editableRecords.map((r) => r.toJson()).toList(),
      });
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Attendance saved successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  AttendanceSummary get liveSummary {
    int present = 0, absent = 0, late = 0, halfDay = 0;
    for (final r in state.editableRecords) {
      switch (r.status) {
        case 'PRESENT':
          present++;
        case 'ABSENT':
          absent++;
        case 'LATE':
          late++;
        case 'HALF_DAY':
          halfDay++;
      }
    }
    return AttendanceSummary(
      total: state.editableRecords.length,
      present: present,
      absent: absent,
      late: late,
      halfDay: halfDay,
      notMarked: 0,
    );
  }
}

final teacherAttendanceProvider = StateNotifierProvider.autoDispose<
    TeacherAttendanceNotifier, TeacherAttendanceState>((ref) {
  return TeacherAttendanceNotifier(ref.watch(teacherServiceProvider));
});
