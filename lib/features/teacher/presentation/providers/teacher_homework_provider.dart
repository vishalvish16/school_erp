import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/homework_model.dart';

// ── List state ──────────────────────────────────────────────────────────────

class TeacherHomeworkListState {
  final List<HomeworkModel> homework;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final String? classFilter;
  final String? sectionFilter;
  final String? subjectFilter;
  final String? statusFilter;

  const TeacherHomeworkListState({
    this.homework = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.classFilter,
    this.sectionFilter,
    this.subjectFilter,
    this.statusFilter,
  });

  TeacherHomeworkListState copyWith({
    List<HomeworkModel>? homework,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    String? classFilter,
    String? sectionFilter,
    String? subjectFilter,
    String? statusFilter,
    bool clearError = false,
    bool clearClassFilter = false,
    bool clearSectionFilter = false,
    bool clearSubjectFilter = false,
    bool clearStatusFilter = false,
  }) {
    return TeacherHomeworkListState(
      homework: homework ?? this.homework,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      classFilter:
          clearClassFilter ? null : (classFilter ?? this.classFilter),
      sectionFilter:
          clearSectionFilter ? null : (sectionFilter ?? this.sectionFilter),
      subjectFilter:
          clearSubjectFilter ? null : (subjectFilter ?? this.subjectFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class TeacherHomeworkListNotifier
    extends StateNotifier<TeacherHomeworkListState> {
  final TeacherService _service;

  TeacherHomeworkListNotifier(this._service)
      : super(const TeacherHomeworkListState());

  Future<void> loadHomework({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getHomework(
        page: refresh ? 1 : state.currentPage,
        classId: state.classFilter,
        sectionId: state.sectionFilter,
        subject: state.subjectFilter,
        status: state.statusFilter,
      );

      final dataWrapper = response['data'];
      List<HomeworkModel> items = [];
      Map<String, dynamic> pagination = {};

      if (dataWrapper is Map<String, dynamic>) {
        final rawList = dataWrapper['data'];
        if (rawList is List) {
          items = rawList
              .map((e) =>
                  HomeworkModel.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList();
        }
        if (dataWrapper['pagination'] is Map<String, dynamic>) {
          pagination = dataWrapper['pagination'] as Map<String, dynamic>;
        }
      }

      state = state.copyWith(
        homework: items,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? 1,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? items.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      currentPage: 1,
    );
    loadHomework(refresh: true);
  }

  void setClassFilter(String? classId) {
    state = state.copyWith(
      classFilter: classId,
      clearClassFilter: classId == null,
      currentPage: 1,
    );
    loadHomework(refresh: true);
  }

  void setSectionFilter(String? sectionId) {
    state = state.copyWith(
      sectionFilter: sectionId,
      clearSectionFilter: sectionId == null,
      currentPage: 1,
    );
    loadHomework(refresh: true);
  }

  void setSubjectFilter(String? subject) {
    state = state.copyWith(
      subjectFilter: subject,
      clearSubjectFilter: subject == null,
      currentPage: 1,
    );
    loadHomework(refresh: true);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadHomework();
  }

  Future<bool> deleteHomework(String id) async {
    try {
      await _service.deleteHomework(id);
      await loadHomework(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _service.updateHomeworkStatus(id, status);
      await loadHomework(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final teacherHomeworkListProvider = StateNotifierProvider.autoDispose<
    TeacherHomeworkListNotifier, TeacherHomeworkListState>((ref) {
  return TeacherHomeworkListNotifier(ref.watch(teacherServiceProvider));
});

// ── Detail provider ─────────────────────────────────────────────────────────

final teacherHomeworkDetailProvider =
    FutureProvider.autoDispose.family<HomeworkModel, String>((ref, id) {
  return ref.read(teacherServiceProvider).getHomeworkDetail(id);
});
