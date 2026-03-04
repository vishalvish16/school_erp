import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reset_password_state.dart';
import 'forgot_password_repository.dart';

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  ResetPasswordNotifier(this._repository) : super(const ResetPasswordState());

  final ForgotPasswordRepository _repository;

  void setToken(String token) {
    state = state.copyWith(token: token);
  }

  void updatePassword(String password) {
    state = state.copyWith(newPassword: password, errorMessage: null);
  }

  void updateConfirmPassword(String password) {
    state = state.copyWith(confirmPassword: password, errorMessage: null);
  }

  Future<void> resetPassword() async {
    if (state.isLoading) return;

    if (state.newPassword != state.confirmPassword) {
      state = state.setError('Passwords do not match');
      return;
    }

    if (state.newPassword.length < 6) {
      state = state.setError('Password must be at least 6 characters');
      return;
    }

    state = state.setLoading();

    try {
      await _repository.resetPassword(state.token, state.newPassword);
      state = state.setSuccess();
    } catch (e) {
      state = state.setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void resetState() {
    state = const ResetPasswordState();
  }
}

final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordNotifier, ResetPasswordState>((ref) {
      final repo = ref.watch(forgotPasswordRepositoryProvider);
      return ResetPasswordNotifier(repo);
    });
