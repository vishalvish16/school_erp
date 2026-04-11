// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_students_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/student_model.dart';

class StudentsState {
  final List<StudentModel> students;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final String searchQuery;
  final String? classFilter;
  final String? sectionFilter;
  final String? statusFilter;

  const StudentsState({
    this.students = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.pageSize = 15,
    this.searchQuery = '',
    this.classFilter,
    this.sectionFilter,
    this.statusFilter,
  });

  StudentsState copyWith({
    List<StudentModel>? students,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    int? pageSize,
    String? searchQuery,
    String? classFilter,
    String? sectionFilter,
    String? statusFilter,
    bool clearError = false,
    bool clearClassFilter = false,
    bool clearSectionFilter = false,
    bool clearStatusFilter = false,
  }) =>
      StudentsState(
        students: students ?? this.students,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        pageSize: pageSize ?? this.pageSize,
        searchQuery: searchQuery ?? this.searchQuery,
        classFilter: clearClassFilter ? null : (classFilter ?? this.classFilter),
        sectionFilter:
            clearSectionFilter ? null : (sectionFilter ?? this.sectionFilter),
        statusFilter:
            clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      );
}

class StudentsNotifier extends StateNotifier<StudentsState> {
  final SchoolAdminService _service;

  StudentsNotifier(this._service) : super(const StudentsState());

  Future<void> loadStudents({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, isLoadingMore: false, clearError: true);
    try {
      final page = refresh ? 1 : state.currentPage;
      final response = await _service.getStudents(
        page: page,
        limit: state.pageSize,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        classId: state.classFilter,
        sectionId: state.sectionFilter,
        status: state.statusFilter,
      );
      final parsed = _parseListResponse(response);
      state = state.copyWith(
        students: parsed.students,
        isLoading: false,
        currentPage: parsed.page ?? page,
        totalPages: parsed.totalPages,
        total: parsed.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Appends next page (mobile infinite scroll). Desktop uses [goToPage] / [loadStudents].
  Future<void> loadMoreStudents() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.students.isEmpty) return;
    if (state.students.length >= state.total && state.total > 0) return;
    final nextPage = state.currentPage + 1;
    if (nextPage > state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final response = await _service.getStudents(
        page: nextPage,
        limit: state.pageSize,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        classId: state.classFilter,
        sectionId: state.sectionFilter,
        status: state.statusFilter,
      );
      final parsed = _parseListResponse(response);
      state = state.copyWith(
        students: [...state.students, ...parsed.students],
        isLoadingMore: false,
        currentPage: parsed.page ?? nextPage,
        totalPages: parsed.totalPages,
        total: parsed.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  _ParsedStudentsPage _parseListResponse(Map<String, dynamic> response) {
    final dataWrapper = response['data'];
    List<dynamic> rawList = [];
    Map<String, dynamic> pagination = {};
    if (dataWrapper is Map) {
      rawList = (dataWrapper['data'] as List?) ?? [];
      pagination = (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
    } else if (dataWrapper is List) {
      rawList = dataWrapper;
    }
    final students =
        rawList.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
    return _ParsedStudentsPage(
      students: students,
      page: (pagination['page'] as num?)?.toInt(),
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? students.length,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadStudents(refresh: true);
  }

  void setClassFilter(String? classId) {
    state = state.copyWith(
      classFilter: classId,
      clearClassFilter: classId == null,
      currentPage: 1,
    );
    loadStudents(refresh: true);
  }

  void setSectionFilter(String? sectionId) {
    state = state.copyWith(
      sectionFilter: sectionId,
      clearSectionFilter: sectionId == null,
      currentPage: 1,
    );
    loadStudents(refresh: true);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      currentPage: 1,
    );
    loadStudents(refresh: true);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, currentPage: 1);
    loadStudents(refresh: true);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadStudents();
  }

  Future<bool> createStudent(Map<String, dynamic> data) async {
    try {
      await _service.createStudent(data);
      await loadStudents(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateStudent(id, data);
      await loadStudents(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _service.deleteStudent(id);
      await loadStudents(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final schoolAdminStudentsProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
  return StudentsNotifier(ref.read(schoolAdminServiceProvider));
});

class _ParsedStudentsPage {
  const _ParsedStudentsPage({
    required this.students,
    this.page,
    required this.totalPages,
    required this.total,
  });

  final List<StudentModel> students;
  final int? page;
  final int totalPages;
  final int total;
}
