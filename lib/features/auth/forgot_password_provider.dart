// =============================================================================
// FILE: lib/features/auth/forgot_password_provider.dart
// PURPOSE: StateNotifier for managing Forgot Password logic
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'forgot_password_state.dart';
import 'forgot_password_repository.dart';

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier(this._repository) : super(const ForgotPasswordState());

  final ForgotPasswordRepository _repository;

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  Future<void> sendResetLink() async {
    if (state.isLoading) return;

    state = state.setLoading();

    try {
      await _repository.sendResetLink(state.email);
      state = state.setSuccess();
    } catch (e) {
      state = state.setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider = StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>((ref) {
  final repo = ref.watch(forgotPasswordRepositoryProvider);
  return ForgotPasswordNotifier(repo);
});
