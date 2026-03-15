// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_classes_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/school_class_model.dart';

class ClassesState {
  final List<SchoolClassModel> classes;
  final bool isLoading;
  final String? errorMessage;

  const ClassesState({
    this.classes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ClassesState copyWith({
    List<SchoolClassModel>? classes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ClassesState(
        classes: classes ?? this.classes,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ClassesNotifier extends StateNotifier<ClassesState> {
  final SchoolAdminService _service;

  ClassesNotifier(this._service) : super(const ClassesState());

  Future<void> loadClasses() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final classes = await _service.getClasses();
      state = state.copyWith(classes: classes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createClass(String name, {int? numeric}) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (numeric != null) body['numeric'] = numeric;
      await _service.createClass(body);
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateClass(
      String id, String name, {int? numeric}) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (numeric != null) body['numeric'] = numeric;
      await _service.updateClass(id, body);
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      await _service.deleteClass(id);
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> createSection(
      String classId, String name, {String? classTeacherId, int? capacity}) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (classTeacherId != null) body['classTeacherId'] = classTeacherId;
      if (capacity != null) body['capacity'] = capacity;
      await _service.createSection(classId, body);
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteSection(String sectionId) async {
    try {
      await _service.deleteSection(sectionId);
      await loadClasses();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final schoolAdminClassesProvider =
    StateNotifierProvider<ClassesNotifier, ClassesState>((ref) {
  return ClassesNotifier(ref.read(schoolAdminServiceProvider));
});
