// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_notices_provider.dart
// PURPOSE: Read-only notices provider for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_notice_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StaffNoticesState {
  final List<StaffNoticeModel> notices;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const StaffNoticesState({
    this.notices = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  StaffNoticesState copyWith({
    List<StaffNoticeModel>? notices,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) =>
      StaffNoticesState(
        notices: notices ?? this.notices,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StaffNoticesNotifier extends StateNotifier<StaffNoticesState> {
  final StaffService _service;

  StaffNoticesNotifier(this._service) : super(const StaffNoticesState());

  Future<void> loadNotices({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getNotices(page: page);
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (response['data'] is List) {
        rawList = response['data'] as List;
      } else if (response['data'] is Map) {
        rawList =
            (response['data']['data'] as List?) ?? [];
        pagination = (response['data']['pagination'] as Map<String, dynamic>?) ??
            {};
      }
      final notices = rawList
          .map((e) =>
              StaffNoticeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort: pinned first, then by date descending
      notices.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

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

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadNotices(page: page);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final staffNoticesProvider =
    StateNotifierProvider<StaffNoticesNotifier, StaffNoticesState>((ref) {
  return StaffNoticesNotifier(ref.read(staffServiceProvider));
});
