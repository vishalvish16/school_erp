import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/school_model.dart';
import '../../domain/models/pagination_model.dart';
import '../../data/repositories/schools_repository.dart';
import '../../data/providers/schools_providers.dart';

final schoolsViewModelProvider =
    StateNotifierProvider<
      SchoolsViewModel,
      AsyncValue<PaginationModel<SchoolModel>>
    >((ref) {
      final repository = ref.watch(schoolsRepositoryProvider);
      return SchoolsViewModel(repository);
    });

class SchoolsViewModel
    extends StateNotifier<AsyncValue<PaginationModel<SchoolModel>>> {
  final ISchoolsRepository _repository;
  Timer? _debounceTimer;

  int _currentPage = 1;
  final int _limit = 15;
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String _planIdFilter = '';
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  SchoolsViewModel(this._repository) : super(const AsyncValue.loading()) {
    fetchSchools();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSchools({int? page, bool isRefresh = false, bool append = false}) async {
    if (page != null) _currentPage = page;

    if (!append && !isRefresh && state.hasValue) {
      state = const AsyncLoading<PaginationModel<SchoolModel>>()
          .copyWithPrevious(state);
    } else if (!append && !isRefresh) {
      state = const AsyncLoading();
    }

    try {
      final response = await _repository.getSchools(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
        planId: _planIdFilter.isNotEmpty ? _planIdFilter : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (append && state.hasValue) {
        final prev = state.value!;
        state = AsyncData(PaginationModel<SchoolModel>(
          data: [...prev.data, ...response.data],
          total: response.total,
          page: response.page,
          limit: response.limit,
          totalPages: response.totalPages,
        ));
      } else {
        state = AsyncData(response);
      }
    } catch (e, st) {
      if (append) _currentPage--;
      state = AsyncError<PaginationModel<SchoolModel>>(
        e,
        st,
      ).copyWithPrevious(state);
    }
  }

  void onSearchChanged(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    _currentPage = 1;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (trimmed.isEmpty) {
      fetchSchools();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        fetchSchools();
      });
    }
  }

  void applySearchNow([String? queryFromField]) {
    if (queryFromField != null) _searchQuery = queryFromField.trim();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _currentPage = 1;
    fetchSchools();
  }

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _currentPage = 1;
    fetchSchools();
  }

  void setPlanIdFilter(String? planId) {
    final value = planId ?? '';
    if (_planIdFilter == value) return;
    _planIdFilter = value;
    _currentPage = 1;
    fetchSchools();
  }

  void setSort(String sortBy, String sortOrder) {
    if (_sortBy == sortBy && _sortOrder == sortOrder) return;
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _currentPage = 1;
    fetchSchools();
  }

  Future<void> loadMore() async {
    if (!hasMorePages) return;
    _currentPage++;
    await fetchSchools(page: _currentPage, append: true);
  }

  Future<void> suspendSchool(String id) async {
    final previousState = state;

    // Optimistic UI update
    if (state.hasValue) {
      final currentList = state.value!.data;
      final updatedList = currentList.map((s) {
        if (s.id == id) {
          return s.copyWith(status: 'SUSPENDED', isActive: false);
        }
        return s;
      }).toList();

      state = AsyncData(
        PaginationModel<SchoolModel>(
          data: updatedList,
          total: state.value!.total,
          page: state.value!.page,
          limit: state.value!.limit,
          totalPages: state.value!.totalPages,
        ),
      );
    }

    try {
      await _repository.suspendSchool(id);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> activateSchool(String id) async {
    final previousState = state;

    // Optimistic UI update
    if (state.hasValue) {
      final currentList = state.value!.data;
      final updatedList = currentList.map((s) {
        if (s.id == id) {
          return s.copyWith(status: 'ACTIVE', isActive: true);
        }
        return s;
      }).toList();

      state = AsyncData(
        PaginationModel<SchoolModel>(
          data: updatedList,
          total: state.value!.total,
          page: state.value!.page,
          limit: state.value!.limit,
          totalPages: state.value!.totalPages,
        ),
      );
    }

    try {
      await _repository.activateSchool(id);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  int get currentPage => _currentPage;
  int get limit => _limit;
  bool get hasMorePages {
    if (!state.hasValue) return false;
    final d = state.value!;
    return d.page < d.totalPages;
  }
  String get currentStatus => _statusFilter;
  String get currentSearch => _searchQuery;
  String get currentPlanIdFilter => _planIdFilter;
  String get currentSortBy => _sortBy;
  String get currentSortOrder => _sortOrder;
}
