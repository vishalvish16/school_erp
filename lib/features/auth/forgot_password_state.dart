// =============================================================================
// FILE: lib/features/auth/forgot_password_state.dart
// PURPOSE: Immutable state for the Forgot Password flow
// =============================================================================

class ForgotPasswordState {
  const ForgotPasswordState({
    this.email = '',
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final String email;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  bool get isFailure => errorMessage != null;

  ForgotPasswordState copyWith({
    String? email,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage, // We reset error if not provided
    );
  }

  ForgotPasswordState setLoading() => copyWith(isLoading: true, errorMessage: null, isSuccess: false);
  ForgotPasswordState setSuccess() => copyWith(isLoading: false, isSuccess: true, errorMessage: null);
  ForgotPasswordState setError(String message) => copyWith(isLoading: false, errorMessage: message, isSuccess: false);
}
