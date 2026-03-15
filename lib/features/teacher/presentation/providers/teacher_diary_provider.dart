import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/class_diary_model.dart';

class TeacherDiaryListState {
  final List<ClassDiaryModel> entries;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final String? classFilter;
  final String? sectionFilter;
  final String? subjectFilter;

  const TeacherDiaryListState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.classFilter,
    this.sectionFilter,
    this.subjectFilter,
  });

  TeacherDiaryListState copyWith({
    List<ClassDiaryModel>? entries,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    String? classFilter,
    String? sectionFilter,
    String? subjectFilter,
    bool clearError = false,
    bool clearClassFilter = false,
    bool clearSectionFilter = false,
    bool clearSubjectFilter = false,
  }) {
    return TeacherDiaryListState(
      entries: entries ?? this.entries,
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
    );
  }
}

class TeacherDiaryListNotifier extends StateNotifier<TeacherDiaryListState> {
  final TeacherService _service;

  TeacherDiaryListNotifier(this._service)
      : super(const TeacherDiaryListState());

  Future<void> loadEntries({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.getDiaryEntries(
        page: refresh ? 1 : state.currentPage,
        classId: state.classFilter,
        sectionId: state.sectionFilter,
        subject: state.subjectFilter,
      );

      final dataWrapper = response['data'];
      List<ClassDiaryModel> items = [];
      Map<String, dynamic> pagination = {};

      if (dataWrapper is Map<String, dynamic>) {
        final rawList = dataWrapper['data'];
        if (rawList is List) {
          items = rawList
              .map((e) => ClassDiaryModel.fromJson(
                  e is Map<String, dynamic> ? e : {}))
              .toList();
        }
        if (dataWrapper['pagination'] is Map<String, dynamic>) {
          pagination = dataWrapper['pagination'] as Map<String, dynamic>;
        }
      }

      state = state.copyWith(
        entries: items,
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

  void setClassFilter(String? classId) {
    state = state.copyWith(
      classFilter: classId,
      clearClassFilter: classId == null,
      currentPage: 1,
    );
    loadEntries(refresh: true);
  }

  void setSectionFilter(String? sectionId) {
    state = state.copyWith(
      sectionFilter: sectionId,
      clearSectionFilter: sectionId == null,
      currentPage: 1,
    );
    loadEntries(refresh: true);
  }

  void setSubjectFilter(String? subject) {
    state = state.copyWith(
      subjectFilter: subject,
      clearSubjectFilter: subject == null,
      currentPage: 1,
    );
    loadEntries(refresh: true);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadEntries();
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _service.deleteDiaryEntry(id);
      await loadEntries(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final teacherDiaryListProvider = StateNotifierProvider.autoDispose<
    TeacherDiaryListNotifier, TeacherDiaryListState>((ref) {
  return TeacherDiaryListNotifier(ref.watch(teacherServiceProvider));
});
