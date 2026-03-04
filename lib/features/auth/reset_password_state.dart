import 'package:flutter/foundation.dart';

@immutable
class ResetPasswordState {
  const ResetPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.token = '',
    this.newPassword = '',
    this.confirmPassword = '',
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String token;
  final String newPassword;
  final String confirmPassword;

  bool get isFailure => errorMessage != null;

  ResetPasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? token,
    String? newPassword,
    String? confirmPassword,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      token: token ?? this.token,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }

  ResetPasswordState setLoading() =>
      copyWith(isLoading: true, errorMessage: null);
  ResetPasswordState setSuccess() =>
      copyWith(isLoading: false, isSuccess: true, errorMessage: null);
  ResetPasswordState setError(String message) =>
      copyWith(isLoading: false, errorMessage: message);
}
