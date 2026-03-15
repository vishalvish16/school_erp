// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_staff_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/staff_model.dart';

class StaffState {
  final List<StaffModel> staff;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final String searchQuery;
  final String? designationFilter;
  final bool? isActiveFilter;

  const StaffState({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.searchQuery = '',
    this.designationFilter,
    this.isActiveFilter,
  });

  StaffState copyWith({
    List<StaffModel>? staff,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    String? searchQuery,
    String? designationFilter,
    bool? isActiveFilter,
    bool clearError = false,
    bool clearDesignation = false,
    bool clearIsActive = false,
  }) =>
      StaffState(
        staff: staff ?? this.staff,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        searchQuery: searchQuery ?? this.searchQuery,
        designationFilter: clearDesignation
            ? null
            : (designationFilter ?? this.designationFilter),
        isActiveFilter:
            clearIsActive ? null : (isActiveFilter ?? this.isActiveFilter),
      );
}

class StaffNotifier extends StateNotifier<StaffState> {
  final SchoolAdminService _service;

  StaffNotifier(this._service) : super(const StaffState());

  Future<void> loadStaff({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = refresh ? 1 : state.currentPage;
      final response = await _service.getStaff(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        designation: state.designationFilter,
        isActive: state.isActiveFilter,
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
      final staff =
          rawList.map((e) => StaffModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(
        staff: staff,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? staff.length,
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
    loadStaff(refresh: true);
  }

  void setDesignationFilter(String? designation) {
    state = state.copyWith(
      designationFilter: designation,
      clearDesignation: designation == null,
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

  Future<bool> createStaff(Map<String, dynamic> data) async {
    try {
      await _service.createStaff(data);
      await loadStaff(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateStaff(id, data);
      await loadStaff(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _service.deleteStaff(id);
      await loadStaff(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final schoolAdminStaffProvider =
    StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier(ref.read(schoolAdminServiceProvider));
});
