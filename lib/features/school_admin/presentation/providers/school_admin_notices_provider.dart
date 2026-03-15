// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_notices_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/school_notice_model.dart';

class NoticesState {
  final List<SchoolNoticeModel> notices;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final String searchQuery;

  const NoticesState({
    this.notices = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery = '',
  });

  NoticesState copyWith({
    List<SchoolNoticeModel>? notices,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    bool clearError = false,
  }) =>
      NoticesState(
        notices: notices ?? this.notices,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class NoticesNotifier extends StateNotifier<NoticesState> {
  final SchoolAdminService _service;

  NoticesNotifier(this._service) : super(const NoticesState());

  Future<void> loadNotices({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = refresh ? 1 : state.currentPage;
      final result = await _service.getNotices(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      final rawList = result['data'];
      final pagination =
          result['pagination'] as Map<String, dynamic>? ?? {};
      final notices = rawList is List
          ? rawList
              .map((e) => SchoolNoticeModel.fromJson(
                    e is Map<String, dynamic> ? e : {},
                  ))
              .toList()
          : <SchoolNoticeModel>[];
      state = state.copyWith(
        notices: notices,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
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
    loadNotices(refresh: true);
  }

  Future<bool> createNotice(Map<String, dynamic> data) async {
    try {
      await _service.createNotice(data);
      await loadNotices(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateNotice(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateNotice(id, data);
      await loadNotices(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteNotice(String id) async {
    try {
      await _service.deleteNotice(id);
      await loadNotices(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final schoolAdminNoticesProvider =
    StateNotifierProvider<NoticesNotifier, NoticesState>((ref) {
  return NoticesNotifier(ref.read(schoolAdminServiceProvider));
});
