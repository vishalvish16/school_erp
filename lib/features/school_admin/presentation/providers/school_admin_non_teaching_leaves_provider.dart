// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_non_teaching_leaves_provider.dart
// PURPOSE: StateNotifier for Non-Teaching Staff leave management (admin side).
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/non_teaching_leave_model.dart';

class NonTeachingLeavesState {
  final List<NonTeachingLeaveModel> leaves;
  final bool isLoading;
  final String? errorMessage;
  final String statusFilter; // ALL | PENDING | APPROVED | REJECTED | CANCELLED
  final int page;
  final int totalPages;
  final int total;
  final bool isSubmitting;

  const NonTeachingLeavesState({
    this.leaves = const [],
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter = 'ALL',
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.isSubmitting = false,
  });

  NonTeachingLeavesState copyWith({
    List<NonTeachingLeaveModel>? leaves,
    bool? isLoading,
    String? errorMessage,
    String? statusFilter,
    int? page,
    int? totalPages,
    int? total,
    bool? isSubmitting,
    bool clearError = false,
  }) =>
      NonTeachingLeavesState(
        leaves: leaves ?? this.leaves,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        statusFilter: statusFilter ?? this.statusFilter,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class NonTeachingLeavesNotifier
    extends StateNotifier<NonTeachingLeavesState> {
  final SchoolAdminService _service;

  NonTeachingLeavesNotifier(this._service)
      : super(const NonTeachingLeavesState());

  Future<void> loadLeaves({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pg = refresh ? 1 : state.page;
      final response = await _service.getNonTeachingLeaves(
        page: pg,
        status: state.statusFilter == 'ALL' ? null : state.statusFilter,
      );
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      final inner = response['data'];
      if (inner is Map) {
        rawList = (inner['data'] as List?) ?? [];
        pagination = (inner['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (inner is List) {
        rawList = inner;
      }
      final leaves = rawList
          .map((e) =>
              NonTeachingLeaveModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        leaves: leaves,
        isLoading: false,
        page: (pagination['page'] as num?)?.toInt() ?? pg,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? leaves.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, page: 1);
    loadLeaves(refresh: true);
  }

  Future<bool> reviewLeave(
    String leaveId,
    String status, {
    String? adminRemark,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.reviewNonTeachingLeave(leaveId, {
        'status': status,
        if (adminRemark != null && adminRemark.isNotEmpty)
          'admin_remark': adminRemark,
      });
      state = state.copyWith(isSubmitting: false);
      await loadLeaves(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> cancelLeave(String leaveId) async {
    try {
      await _service.cancelNonTeachingLeave(leaveId);
      await loadLeaves(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final nonTeachingLeavesProvider = StateNotifierProvider<
    NonTeachingLeavesNotifier, NonTeachingLeavesState>((ref) {
  return NonTeachingLeavesNotifier(ref.read(schoolAdminServiceProvider));
});
