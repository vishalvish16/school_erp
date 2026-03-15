// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_attendance_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/attendance_model.dart';

class AttendanceState {
  final List<AttendanceRecord> records;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedClassId;
  final String? selectedSectionId;
  final String selectedDate;
  final bool isSaving;

  AttendanceState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedClassId,
    this.selectedSectionId,
    String? selectedDate,
    this.isSaving = false,
  }) : selectedDate = selectedDate ?? _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    bool? isLoading,
    String? errorMessage,
    String? selectedClassId,
    String? selectedSectionId,
    String? selectedDate,
    bool? isSaving,
    bool clearError = false,
    bool clearClassId = false,
    bool clearSectionId = false,
  }) =>
      AttendanceState(
        records: records ?? this.records,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        selectedClassId:
            clearClassId ? null : (selectedClassId ?? this.selectedClassId),
        selectedSectionId: clearSectionId
            ? null
            : (selectedSectionId ?? this.selectedSectionId),
        selectedDate: selectedDate ?? this.selectedDate,
        isSaving: isSaving ?? this.isSaving,
      );
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final SchoolAdminService _service;

  AttendanceNotifier(this._service) : super(AttendanceState());

  Future<void> loadAttendance() async {
    if (state.selectedSectionId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final records = await _service.getAttendance(
        classId: state.selectedClassId,
        sectionId: state.selectedSectionId,
        date: state.selectedDate,
      );
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setClass(String classId) {
    state = state.copyWith(
      selectedClassId: classId,
      clearSectionId: true,
      records: [],
    );
  }

  void setSection(String sectionId) {
    state = state.copyWith(selectedSectionId: sectionId);
    loadAttendance();
  }

  void setDate(String date) {
    state = state.copyWith(selectedDate: date);
    loadAttendance();
  }

  Future<bool> saveAttendance(List<Map<String, dynamic>> records) async {
    if (state.selectedSectionId == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.bulkMarkAttendance(
        sectionId: state.selectedSectionId!,
        date: state.selectedDate,
        records: records,
      );
      state = state.copyWith(isSaving: false);
      await loadAttendance();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final schoolAdminAttendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref.read(schoolAdminServiceProvider));
});
