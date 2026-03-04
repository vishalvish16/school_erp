// =============================================================================
// FILE: lib/features/auth/login_state.dart
// PURPOSE: Immutable state class for Super Admin Login
// =============================================================================

import 'package:flutter/foundation.dart';

@immutable
class LoginState {
  const LoginState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.rememberMe = false,
    this.email = '',
    this.password = '',
    this.isBiometricSupported = false,
    this.isBiometricEnabled = false,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool rememberMe;
  final String email;
  final String password;
  final bool isBiometricSupported;
  final bool isBiometricEnabled;

  /// Helper to check if state is failure
  bool get isFailure => errorMessage != null;

  LoginState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool? rememberMe,
    bool? isBiometricSupported,
    bool? isBiometricEnabled,
    String? email,
    String? password,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage, // Reset error if not explicitly passed
      rememberMe: rememberMe ?? this.rememberMe,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  /// Special copyWith that allows nulling out error message explicitly
  LoginState setError(String message) {
    return copyWith(errorMessage: message, isLoading: false, isSuccess: false);
  }

  LoginState setSuccess() {
    return copyWith(isSuccess: true, isLoading: false, errorMessage: null);
  }

  LoginState setLoading() {
    return copyWith(isLoading: true, isSuccess: false, errorMessage: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isSuccess == other.isSuccess &&
          errorMessage == other.errorMessage &&
          rememberMe == other.rememberMe &&
          isBiometricSupported == other.isBiometricSupported &&
          isBiometricEnabled == other.isBiometricEnabled &&
          email == other.email &&
          password == other.password;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isSuccess.hashCode ^
      errorMessage.hashCode ^
      rememberMe.hashCode ^
      isBiometricSupported.hashCode ^
      isBiometricEnabled.hashCode ^
      email.hashCode ^
      password.hashCode;
}
