// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_non_teaching_attendance_provider.dart
// PURPOSE: StateNotifier for bulk daily attendance marking for non-teaching staff.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';

class NonTeachingAttendanceState {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> staffWithAttendance;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? categoryFilter;
  final String? departmentFilter;
  // Local edits: staffId -> {status, checkInTime, checkOutTime, remarks}
  final Map<String, Map<String, dynamic>> localEdits;

  const NonTeachingAttendanceState({
    required this.selectedDate,
    this.staffWithAttendance = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.categoryFilter,
    this.departmentFilter,
    this.localEdits = const {},
  });

  NonTeachingAttendanceState copyWith({
    DateTime? selectedDate,
    List<Map<String, dynamic>>? staffWithAttendance,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? categoryFilter,
    String? departmentFilter,
    Map<String, Map<String, dynamic>>? localEdits,
    bool clearError = false,
    bool clearCategory = false,
    bool clearDepartment = false,
  }) =>
      NonTeachingAttendanceState(
        selectedDate: selectedDate ?? this.selectedDate,
        staffWithAttendance: staffWithAttendance ?? this.staffWithAttendance,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        categoryFilter:
            clearCategory ? null : (categoryFilter ?? this.categoryFilter),
        departmentFilter:
            clearDepartment ? null : (departmentFilter ?? this.departmentFilter),
        localEdits: localEdits ?? this.localEdits,
      );

  // Compute summary stats from localEdits + loaded data
  Map<String, int> get summary {
    final counts = <String, int>{
      'PRESENT': 0,
      'ABSENT': 0,
      'HALF_DAY': 0,
      'ON_LEAVE': 0,
      'LATE': 0,
      'HOLIDAY': 0,
    };
    for (final entry in staffWithAttendance) {
      final staffId = entry['id'] as String? ?? '';
      final edit = localEdits[staffId];
      final status = edit?['status'] as String? ??
          entry['attendanceStatus'] as String?;
      if (status != null && counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }
}

class NonTeachingAttendanceNotifier
    extends StateNotifier<NonTeachingAttendanceState> {
  final SchoolAdminService _service;

  NonTeachingAttendanceNotifier(this._service)
      : super(NonTeachingAttendanceState(selectedDate: DateTime.now()));

  Future<void> loadForDate(DateTime date) async {
    if (state.isLoading) return;
    state = state.copyWith(
      selectedDate: date,
      isLoading: true,
      clearError: true,
      localEdits: {},
    );
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final result = await _service.getNonTeachingAttendanceForDate(
        dateStr,
        department: state.departmentFilter,
        category: state.categoryFilter,
      );
      // Backend returns a list of { staff: {...}, attendance: {...}|null }
      // Flatten into a single map per entry for UI consumption.
      final staffMaps = result.map((e) {
        final entry = e as Map<String, dynamic>;
        final staffObj = entry['staff'] as Map<String, dynamic>? ?? {};
        final attendanceObj = entry['attendance'] as Map<String, dynamic>?;
        return <String, dynamic>{
          ...staffObj,
          'attendanceStatus': attendanceObj?['status'],
          'attendanceId': attendanceObj?['id'],
          'checkInTime': attendanceObj?['check_in_time'],
          'checkOutTime': attendanceObj?['check_out_time'],
          'attendanceRemarks': attendanceObj?['remarks'],
        };
      }).toList();
      state = state.copyWith(
        staffWithAttendance: staffMaps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateLocalRecord(
    String staffId,
    String status, {
    String? checkIn,
    String? checkOut,
    String? remarks,
  }) {
    final updated = Map<String, Map<String, dynamic>>.from(state.localEdits);
    updated[staffId] = {
      'status': status,
      'check_in_time': checkIn,
      'check_out_time': checkOut,
      'remarks': remarks,
    }..removeWhere((_, v) => v == null);
    state = state.copyWith(localEdits: updated);
  }

  Future<bool> saveAll() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final dateStr =
          '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';

      // Build records from localEdits + default status for unmarked staff
      final records = <Map<String, dynamic>>[];
      for (final staff in state.staffWithAttendance) {
        final staffId = staff['id'] as String? ?? '';
        final edit = state.localEdits[staffId];
        final existingStatus = staff['attendanceStatus'] as String?;
        if (edit != null) {
          records.add({'staff_id': staffId, ...edit});
        } else if (existingStatus != null) {
          records.add({'staff_id': staffId, 'status': existingStatus});
        }
      }

      await _service.bulkMarkNonTeachingAttendance({
        'date': dateStr,
        'records': records,
      });
      state = state.copyWith(isSaving: false);
      // Reload to get fresh data
      await loadForDate(state.selectedDate);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void changeDate(DateTime date) {
    loadForDate(date);
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
    );
    loadForDate(state.selectedDate);
  }

  void setDepartmentFilter(String? department) {
    state = state.copyWith(
      departmentFilter: department,
      clearDepartment: department == null,
    );
    loadForDate(state.selectedDate);
  }
}

final nonTeachingAttendanceProvider = StateNotifierProvider<
    NonTeachingAttendanceNotifier, NonTeachingAttendanceState>((ref) {
  return NonTeachingAttendanceNotifier(ref.read(schoolAdminServiceProvider));
});
