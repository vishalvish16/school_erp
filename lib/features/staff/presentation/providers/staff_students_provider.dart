// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_students_provider.dart
// PURPOSE: Read-only student list provider for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_student_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StaffStudentsState {
  final List<StaffStudentModel> students;
  final List<Map<String, dynamic>> classes;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final String searchQuery;
  final String? filterClassId;

  const StaffStudentsState({
    this.students = const [],
    this.classes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.pageSize = 15,
    this.searchQuery = '',
    this.filterClassId,
  });

  StaffStudentsState copyWith({
    List<StaffStudentModel>? students,
    List<Map<String, dynamic>>? classes,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    int? pageSize,
    String? searchQuery,
    String? filterClassId,
    bool clearError = false,
    bool clearFilterClassId = false,
  }) =>
      StaffStudentsState(
        students: students ?? this.students,
        classes: classes ?? this.classes,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        pageSize: pageSize ?? this.pageSize,
        searchQuery: searchQuery ?? this.searchQuery,
        filterClassId: clearFilterClassId
            ? null
            : (filterClassId ?? this.filterClassId),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StaffStudentsNotifier extends StateNotifier<StaffStudentsState> {
  final StaffService _service;

  StaffStudentsNotifier(this._service) : super(const StaffStudentsState());

  Future<void> loadStudents({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getStudents(
        page: page,
        limit: state.pageSize,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        classId: state.filterClassId,
      );
      final dataWrapper = response['data'];
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination =
            (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final students = rawList
          .map((e) =>
              StaffStudentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        students: students,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? students.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadClasses() async {
    try {
      final classes = await _service.getClasses();
      state = state.copyWith(classes: classes);
    } catch (_) {}
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadStudents(page: 1);
  }

  void setClassFilter(String? classId) {
    state = state.copyWith(
      filterClassId: classId,
      clearFilterClassId: classId == null,
      currentPage: 1,
    );
    loadStudents(page: 1);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadStudents(page: page);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, currentPage: 1);
    loadStudents(page: 1);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final staffStudentsProvider =
    StateNotifierProvider<StaffStudentsNotifier, StaffStudentsState>((ref) {
  return StaffStudentsNotifier(ref.read(staffServiceProvider));
});
