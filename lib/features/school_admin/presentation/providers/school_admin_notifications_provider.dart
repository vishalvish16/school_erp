// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_notifications_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';

class NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? unreadCount,
    bool clearError = false,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final SchoolAdminService _service;

  NotificationsNotifier(this._service) : super(const NotificationsState());

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = refresh ? 1 : state.currentPage;
      final response = await _service.getNotifications(page: page);
      final dataWrapper = response['data'];
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination = (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final items = rawList
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
      state = state.copyWith(
        notifications: items,
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

  Future<void> loadUnreadCount() async {
    final count = await _service.getUnreadCount();
    state = state.copyWith(unreadCount: count);
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markNotificationRead(id);
      final updated = state.notifications.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
      final newUnread = (state.unreadCount - 1).clamp(0, state.unreadCount);
      state = state.copyWith(
        notifications: updated,
        unreadCount: newUnread,
      );
    } catch (_) {}
  }
}

final schoolAdminNotificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.read(schoolAdminServiceProvider));
});
