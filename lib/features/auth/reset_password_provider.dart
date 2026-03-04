import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_auth_constants.dart';
import 'reset_password_state.dart';
import 'forgot_password_repository.dart';

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  ResetPasswordNotifier(this._repository) : super(const ResetPasswordState());

  final ForgotPasswordRepository _repository;

  static final List<({String label, bool Function(String) check})> _passwordRules = [
    (label: AuthStrings.passwordRuleMinLength, check: (s) => s.length >= 8),
    (label: AuthStrings.passwordRuleUppercase, check: (s) => s.contains(RegExp(r'[A-Z]'))),
    (label: AuthStrings.passwordRuleLowercase, check: (s) => s.contains(RegExp(r'[a-z]'))),
    (label: AuthStrings.passwordRuleNumber, check: (s) => s.contains(RegExp(r'[0-9]'))),
    (label: AuthStrings.passwordRuleSpecial, check: (s) => s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'))),
  ];

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

    for (final r in _passwordRules) {
      if (!r.check(state.newPassword)) {
        state = state.setError('${r.label} required');
        return;
      }
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
