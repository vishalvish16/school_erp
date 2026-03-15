// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_timetable_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';

class TimetableState {
  final List<dynamic> entries;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedClassId;
  final String? selectedSectionId;

  const TimetableState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedClassId,
    this.selectedSectionId,
  });

  TimetableState copyWith({
    List<dynamic>? entries,
    bool? isLoading,
    String? errorMessage,
    String? selectedClassId,
    String? selectedSectionId,
    bool clearError = false,
  }) =>
      TimetableState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        selectedClassId: selectedClassId ?? this.selectedClassId,
        selectedSectionId: selectedSectionId ?? this.selectedSectionId,
      );
}

class TimetableNotifier extends StateNotifier<TimetableState> {
  final SchoolAdminService _service;

  TimetableNotifier(this._service) : super(const TimetableState());

  Future<void> loadTimetable({String? classId, String? sectionId}) async {
    final cId = classId ?? state.selectedClassId;
    if (cId == null) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedClassId: cId,
      selectedSectionId: sectionId ?? state.selectedSectionId,
    );
    try {
      final entries = await _service.getTimetable(
        classId: cId,
        sectionId: sectionId ?? state.selectedSectionId,
      );
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> saveTimetable({
    required String classId,
    String? sectionId,
    required List<Map<String, dynamic>> entries,
  }) async {
    try {
      await _service.updateTimetableBulk({
        'classId': classId,
        'sectionId': sectionId,
        'entries': entries,
      });
      await loadTimetable(classId: classId, sectionId: sectionId);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final schoolAdminTimetableProvider =
    StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
  return TimetableNotifier(ref.read(schoolAdminServiceProvider));
});
