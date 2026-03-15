// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_profile_provider.dart
// PURPOSE: Profile provider for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_profile_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StaffProfileState {
  final StaffProfileModel? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const StaffProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  StaffProfileState copyWith({
    StaffProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      StaffProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StaffProfileNotifier extends StateNotifier<StaffProfileState> {
  final StaffService _service;

  StaffProfileNotifier(this._service) : super(const StaffProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _service.updateUserProfile(data);
      state = state.copyWith(profile: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final staffProfileProvider =
    StateNotifierProvider<StaffProfileNotifier, StaffProfileState>((ref) {
  return StaffProfileNotifier(ref.read(staffServiceProvider));
});
