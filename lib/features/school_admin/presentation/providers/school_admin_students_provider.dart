// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_students_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/student_model.dart';

class StudentsState {
  final List<StudentModel> students;
  final bool isLoading;
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
    state = state.copyWith(isLoading: true, clearError: true);
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
