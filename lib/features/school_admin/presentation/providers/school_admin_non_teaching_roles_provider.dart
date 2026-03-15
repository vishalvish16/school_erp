// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_non_teaching_roles_provider.dart
// PURPOSE: StateNotifier for Non-Teaching Staff Roles management.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/non_teaching_staff_role_model.dart';

class NonTeachingRolesState {
  final List<NonTeachingStaffRoleModel> roles;
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitting;

  const NonTeachingRolesState({
    this.roles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSubmitting = false,
  });

  NonTeachingRolesState copyWith({
    List<NonTeachingStaffRoleModel>? roles,
    bool? isLoading,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
  }) =>
      NonTeachingRolesState(
        roles: roles ?? this.roles,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  List<NonTeachingStaffRoleModel> get systemRoles =>
      roles.where((r) => r.isSystem).toList();

  List<NonTeachingStaffRoleModel> get customRoles =>
      roles.where((r) => !r.isSystem).toList();
}

class NonTeachingRolesNotifier
    extends StateNotifier<NonTeachingRolesState> {
  final SchoolAdminService _service;

  NonTeachingRolesNotifier(this._service)
      : super(const NonTeachingRolesState());

  Future<void> loadRoles({bool includeInactive = true}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final roles =
          await _service.getNonTeachingRoles(includeInactive: includeInactive);
      state = state.copyWith(roles: roles, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: _safeMsg(e));
    }
  }

  Future<bool> createRole(Map<String, dynamic> body) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.createNonTeachingRole(body);
      await loadRoles(includeInactive: true);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isSubmitting: false, errorMessage: _safeMsg(e));
      return false;
    }
  }

  Future<bool> updateRole(String roleId, Map<String, dynamic> body) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.updateNonTeachingRole(roleId, body);
      await loadRoles(includeInactive: true);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isSubmitting: false, errorMessage: _safeMsg(e));
      return false;
    }
  }

  Future<bool> toggleRole(String roleId) async {
    try {
      await _service.toggleNonTeachingRole(roleId);
      await loadRoles(includeInactive: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _safeMsg(e));
      return false;
    }
  }

  Future<bool> deleteRole(String roleId) async {
    try {
      await _service.deleteNonTeachingRole(roleId);
      await loadRoles(includeInactive: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _safeMsg(e));
      return false;
    }
  }

  String _safeMsg(dynamic e) =>
      e.toString().replaceAll('Exception: ', '');
}

final nonTeachingRolesProvider = StateNotifierProvider<
    NonTeachingRolesNotifier, NonTeachingRolesState>((ref) {
  return NonTeachingRolesNotifier(ref.read(schoolAdminServiceProvider));
});

// FutureProvider family for detail sub-tabs
final nonTeachingQualificationsProvider =
    FutureProvider.autoDispose.family((ref, String staffId) {
  return ref.read(schoolAdminServiceProvider).getNonTeachingQualifications(staffId);
});

final nonTeachingDocumentsProvider =
    FutureProvider.autoDispose.family((ref, String staffId) {
  return ref.read(schoolAdminServiceProvider).getNonTeachingDocuments(staffId);
});

final nonTeachingStaffLeavesProvider =
    FutureProvider.autoDispose.family((ref, String staffId) {
  return ref.read(schoolAdminServiceProvider).getNonTeachingStaffLeaves(staffId);
});
