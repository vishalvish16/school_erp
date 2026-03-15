// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_non_teaching_staff_provider.dart
// PURPOSE: StateNotifier for Non-Teaching Staff list screen.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/non_teaching_staff_model.dart';

class NonTeachingStaffState {
  final List<NonTeachingStaffModel> staff;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final String searchQuery;
  final String? categoryFilter;
  final String? employeeTypeFilter;
  final bool? isActiveFilter;
  final bool isSubmitting;

  const NonTeachingStaffState({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.searchQuery = '',
    this.categoryFilter,
    this.employeeTypeFilter,
    this.isActiveFilter,
    this.isSubmitting = false,
  });

  NonTeachingStaffState copyWith({
    List<NonTeachingStaffModel>? staff,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    String? searchQuery,
    String? categoryFilter,
    String? employeeTypeFilter,
    bool? isActiveFilter,
    bool? isSubmitting,
    bool clearError = false,
    bool clearCategory = false,
    bool clearEmployeeType = false,
    bool clearIsActive = false,
  }) =>
      NonTeachingStaffState(
        staff: staff ?? this.staff,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        searchQuery: searchQuery ?? this.searchQuery,
        categoryFilter:
            clearCategory ? null : (categoryFilter ?? this.categoryFilter),
        employeeTypeFilter: clearEmployeeType
            ? null
            : (employeeTypeFilter ?? this.employeeTypeFilter),
        isActiveFilter:
            clearIsActive ? null : (isActiveFilter ?? this.isActiveFilter),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class NonTeachingStaffNotifier
    extends StateNotifier<NonTeachingStaffState> {
  final SchoolAdminService _service;

  NonTeachingStaffNotifier(this._service)
      : super(const NonTeachingStaffState());

  Future<void> loadStaff({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = refresh ? 1 : state.currentPage;
      final response = await _service.getNonTeachingStaffList(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        category: state.categoryFilter,
        employeeType: state.employeeTypeFilter,
        isActive: state.isActiveFilter,
      );
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      final dataWrapper = response['data'];
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination =
            (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final staffList = rawList
          .map((e) => NonTeachingStaffModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        staff: staffList,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? staffList.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _safeErrorMessage(e),
      );
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
    loadStaff(refresh: true);
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
      currentPage: 1,
    );
    loadStaff(refresh: true);
  }

  void setEmployeeTypeFilter(String? employeeType) {
    state = state.copyWith(
      employeeTypeFilter: employeeType,
      clearEmployeeType: employeeType == null,
      currentPage: 1,
    );
    loadStaff(refresh: true);
  }

  void setActiveFilter(bool? isActive) {
    state = state.copyWith(
      isActiveFilter: isActive,
      clearIsActive: isActive == null,
      currentPage: 1,
    );
    loadStaff(refresh: true);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadStaff();
  }

  Future<void> refresh() => loadStaff(refresh: true);

  Future<bool> createStaff(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.createNonTeachingStaff(data);
      await loadStaff(refresh: true);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _safeErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.updateNonTeachingStaff(id, data);
      await loadStaff(refresh: true);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _safeErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _service.deleteNonTeachingStaff(id);
      await loadStaff(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _safeErrorMessage(e));
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      await _service.updateNonTeachingStaffStatus(id, isActive);
      await loadStaff(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _safeErrorMessage(e));
      return false;
    }
  }

  String _safeErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('DioException') || str.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    }
    return str.replaceAll('Exception: ', '');
  }
}

final nonTeachingStaffProvider = StateNotifierProvider<
    NonTeachingStaffNotifier, NonTeachingStaffState>((ref) {
  return NonTeachingStaffNotifier(ref.read(schoolAdminServiceProvider));
});
