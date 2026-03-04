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
  final int _limit = 10;
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  SchoolsViewModel(this._repository) : super(const AsyncValue.loading()) {
    fetchSchools();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchSchools({int? page, bool isRefresh = false}) async {
    if (page != null) _currentPage = page;

    if (!isRefresh && state.hasValue) {
      state = const AsyncLoading<PaginationModel<SchoolModel>>()
          .copyWithPrevious(state);
    } else if (!isRefresh) {
      state = const AsyncLoading();
    }

    try {
      final response = await _repository.getSchools(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        status: _statusFilter,
      );
      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError<PaginationModel<SchoolModel>>(
        e,
        st,
      ).copyWithPrevious(state);
    }
  }

  void onSearchChanged(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      fetchSchools();
    });
  }

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _currentPage = 1;
    fetchSchools();
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

  int get currentPage => _currentPage;
  String get currentStatus => _statusFilter;
  String get currentSearch => _searchQuery;
}
