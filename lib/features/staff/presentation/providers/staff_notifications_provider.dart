// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_notifications_provider.dart
// PURPOSE: Notifications provider for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_notification_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StaffNotificationsState {
  final List<StaffNotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const StaffNotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  StaffNotificationsState copyWith({
    List<StaffNotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) =>
      StaffNotificationsState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StaffNotificationsNotifier
    extends StateNotifier<StaffNotificationsState> {
  final StaffService _service;

  StaffNotificationsNotifier(this._service)
      : super(const StaffNotificationsState());

  Future<void> loadNotifications({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.getNotifications(page: page);
      final dataWrapper = response['data'];
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination =
            (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final notifications = rawList
          .map((e) =>
              StaffNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final unread = notifications.where((n) => !n.isRead).length;
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unread,
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
    try {
      final count = await _service.getUnreadCount();
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

  Future<void> markAllRead() async {
    try {
      await _service.markAllNotificationsRead();
      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadNotifications(page: page);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final staffNotificationsProvider = StateNotifierProvider<
    StaffNotificationsNotifier, StaffNotificationsState>((ref) {
  return StaffNotificationsNotifier(ref.read(staffServiceProvider));
});
