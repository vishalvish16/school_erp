// =============================================================================
// FILE: lib/features/parent/presentation/providers/parent_notifications_provider.dart
// PURPOSE: Notifications provider for the Parent portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/parent_service.dart';
import '../../../../models/parent/parent_notification_model.dart';

class ParentNotificationsState {
  final List<ParentNotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const ParentNotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  ParentNotificationsState copyWith({
    List<ParentNotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) =>
      ParentNotificationsState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

class ParentNotificationsNotifier extends StateNotifier<ParentNotificationsState> {
  final ParentService _service;

  ParentNotificationsNotifier(this._service) : super(const ParentNotificationsState());

  Future<void> loadNotifications({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getNotifications(page: page);
      final data = response['data'] as List<dynamic>? ?? [];
      final notifications = data
          .map((e) => ParentNotificationModel.fromJson(
                e is Map<String, dynamic> ? e : {},
              ))
          .toList();
      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      );
      await loadUnreadCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _service.getUnreadNotificationCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markNotificationRead(id);
      final updated = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      final unread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadNotifications(page: page);
  }
}

final parentNotificationsProvider =
    StateNotifierProvider<ParentNotificationsNotifier, ParentNotificationsState>((ref) {
  return ParentNotificationsNotifier(ref.read(parentServiceProvider));
});
