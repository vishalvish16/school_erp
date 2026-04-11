// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/profile_requests_provider.dart
// PURPOSE: Riverpod providers for student profile update requests.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/profile_request_service.dart';
import '../../../../models/school_admin/profile_update_request_model.dart';

// ── Pending count (for badge) ───────────────────────────────────────────────

final pendingProfileRequestsCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(profileRequestServiceProvider);
  return service.fetchPendingCount();
});

// ── Profile requests list ───────────────────────────────────────────────────

class ProfileRequestsState {
  final List<ProfileUpdateRequest> requests;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? statusFilter;
  final int page;
  final int total;
  final int totalPages;
  final int pageSize;
  // Static counts per status — fetched once and unchanged by filter changes.
  final Map<String?, int> statusTotals;

  const ProfileRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.statusFilter,
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.pageSize = 15,
    this.statusTotals = const {},
  });

  ProfileRequestsState copyWith({
    List<ProfileUpdateRequest>? requests,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? statusFilter,
    int? page,
    int? total,
    int? totalPages,
    int? pageSize,
    Map<String?, int>? statusTotals,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return ProfileRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      statusTotals: statusTotals ?? this.statusTotals,
    );
  }
}

class ProfileRequestsNotifier extends StateNotifier<ProfileRequestsState> {
  final ProfileRequestService _service;
  final Ref _ref;

  ProfileRequestsNotifier(this._service, this._ref)
      : super(const ProfileRequestsState());

  Future<void> load({bool refresh = false, int? page}) async {
    if (state.isLoading && !refresh) return;
    final targetPage = page ?? state.page;
    final needsCounts = state.statusTotals.isEmpty || refresh;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      // Fetch the page data and, if needed, all per-status totals in parallel.
      final futures = <Future>[
        _service.fetchSchoolProfileRequests(
          page: targetPage,
          limit: state.pageSize,
          status: state.statusFilter,
        ),
        if (needsCounts) ...[
          _service.fetchSchoolProfileRequests(page: 1, limit: 1, status: null),
          _service.fetchSchoolProfileRequests(page: 1, limit: 1, status: 'PENDING'),
          _service.fetchSchoolProfileRequests(page: 1, limit: 1, status: 'APPROVED'),
          _service.fetchSchoolProfileRequests(page: 1, limit: 1, status: 'REJECTED'),
        ],
      ];
      final results = await Future.wait(futures);
      final result = results[0] as dynamic;
      Map<String?, int> totals = state.statusTotals;
      if (needsCounts && results.length >= 5) {
        totals = {
          null: (results[1] as dynamic).total as int,
          'PENDING': (results[2] as dynamic).total as int,
          'APPROVED': (results[3] as dynamic).total as int,
          'REJECTED': (results[4] as dynamic).total as int,
        };
      }
      state = state.copyWith(
        requests: result.requests as List<ProfileUpdateRequest>,
        total: result.total as int,
        page: result.page as int,
        totalPages: result.totalPages as int,
        isLoading: false,
        statusTotals: totals,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Appends next page (mobile infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.requests.isEmpty) return;
    if (state.requests.length >= state.total && state.total > 0) return;
    final nextPage = state.page + 1;
    if (nextPage > state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final result = await _service.fetchSchoolProfileRequests(
        page: nextPage,
        limit: state.pageSize,
        status: state.statusFilter,
      );
      final seen = <String>{};
      final merged = [...state.requests, ...result.requests]
          .where((r) => seen.add(r.id))
          .toList();
      state = state.copyWith(
        requests: merged,
        isLoadingMore: false,
        page: result.page,
        total: result.total,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setStatusFilter(String? filter) {
    if (filter == state.statusFilter) return;
    state = state.copyWith(
      statusFilter: filter,
      clearFilter: filter == null,
      page: 1,
    );
    load(refresh: true, page: 1);
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    load(refresh: true, page: page);
  }

  void setPageSize(int size) {
    if (size == state.pageSize) return;
    state = state.copyWith(pageSize: size, page: 1);
    load(refresh: true, page: 1);
  }

  Future<bool> approveRequest(String requestId, {String? note}) async {
    try {
      await _service.approveRequest(requestId, note: note);
      await load(refresh: true);
      _ref.invalidate(pendingProfileRequestsCountProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId, {required String note}) async {
    try {
      await _service.rejectRequest(requestId, note: note);
      await load(refresh: true);
      _ref.invalidate(pendingProfileRequestsCountProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final profileRequestsProvider =
    StateNotifierProvider<ProfileRequestsNotifier, ProfileRequestsState>((ref) {
  return ProfileRequestsNotifier(
    ref.watch(profileRequestServiceProvider),
    ref,
  );
});

// ── Parent profile requests list ────────────────────────────────────────────

/// State for parent profile requests (supports pagination).
class ParentProfileRequestsState {
  final List<ProfileUpdateRequest> requests;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final int total;
  final int totalPages;
  final int pageSize;

  const ParentProfileRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.pageSize = 15,
  });
}

class ParentProfileRequestsNotifier extends StateNotifier<ParentProfileRequestsState> {
  final ProfileRequestService _service;
  final String? studentId;

  ParentProfileRequestsNotifier(this._service, this.studentId)
      : super(const ParentProfileRequestsState());

  Future<void> load({bool refresh = false, int? page}) async {
    if (state.isLoading && !refresh) return;
    final targetPage = page ?? state.page;
    state = ParentProfileRequestsState(
      requests: state.requests,
      isLoading: true,
      isLoadingMore: false,
      errorMessage: null,
      page: targetPage,
      total: state.total,
      totalPages: state.totalPages,
      pageSize: state.pageSize,
    );
    try {
      final result = await _service.fetchParentProfileRequests(
        page: targetPage,
        limit: state.pageSize,
        studentId: studentId,
      );
      state = ParentProfileRequestsState(
        requests: result.requests,
        isLoading: false,
        isLoadingMore: false,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        pageSize: state.pageSize,
      );
    } catch (e) {
      state = ParentProfileRequestsState(
        requests: state.requests,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        page: state.page,
        total: state.total,
        totalPages: state.totalPages,
        pageSize: state.pageSize,
      );
    }
  }

  /// Appends next page (mobile infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.requests.isEmpty) return;
    if (state.requests.length >= state.total && state.total > 0) return;
    final nextPage = state.page + 1;
    if (nextPage > state.totalPages) return;
    state = ParentProfileRequestsState(
      requests: state.requests,
      isLoading: false,
      isLoadingMore: true,
      errorMessage: null,
      page: state.page,
      total: state.total,
      totalPages: state.totalPages,
      pageSize: state.pageSize,
    );
    try {
      final result = await _service.fetchParentProfileRequests(
        page: nextPage,
        limit: state.pageSize,
        studentId: studentId,
      );
      final seen = <String>{};
      final merged = [...state.requests, ...result.requests]
          .where((r) => seen.add(r.id))
          .toList();
      state = ParentProfileRequestsState(
        requests: merged,
        isLoading: false,
        isLoadingMore: false,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        pageSize: state.pageSize,
      );
    } catch (e) {
      state = ParentProfileRequestsState(
        requests: state.requests,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        page: state.page,
        total: state.total,
        totalPages: state.totalPages,
        pageSize: state.pageSize,
      );
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages) return;
    load(refresh: true, page: page);
  }

  void setPageSize(int size) {
    if (size == state.pageSize) return;
    state = ParentProfileRequestsState(
      requests: state.requests,
      pageSize: size,
      page: 1,
      total: state.total,
      totalPages: state.totalPages,
    );
    load(refresh: true, page: 1);
  }
}

final parentProfileRequestsProvider =
    StateNotifierProvider.family<ParentProfileRequestsNotifier, ParentProfileRequestsState, String?>(
        (ref, studentId) {
  return ParentProfileRequestsNotifier(
    ref.read(profileRequestServiceProvider),
    studentId,
  );
});
