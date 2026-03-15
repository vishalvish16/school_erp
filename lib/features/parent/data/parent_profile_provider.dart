// =============================================================================
// FILE: lib/features/parent/data/parent_profile_provider.dart
// PURPOSE: Profile provider for the Parent Portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent/parent_profile_model.dart';

class ParentProfileState {
  final ParentProfileModel? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ParentProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ParentProfileState copyWith({
    ParentProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ParentProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class ParentProfileNotifier extends StateNotifier<ParentProfileState> {
  final ParentService _service;

  ParentProfileNotifier(this._service) : super(const ParentProfileState());

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
      final updated = await _service.updateProfile(data);
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

final parentProfileProvider =
    StateNotifierProvider<ParentProfileNotifier, ParentProfileState>((ref) {
  return ParentProfileNotifier(ref.read(parentServiceProvider));
});
