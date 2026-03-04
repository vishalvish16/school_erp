// =============================================================================
// FILE: lib/features/auth/login_provider.dart
// PURPOSE: Riverpod StateNotifier to manage Super Admin Login flow
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_state.dart';
import 'login_repository.dart';
import 'auth_guard_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../settings/settings_provider.dart';

/// StateNotifierProvider for the Super Admin Login flow
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final repository = ref.watch(loginRepositoryProvider);
  return LoginNotifier(repository, ref);
});

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._repository, this._ref) : super(const LoginState()) {
    _initBiometrics();
    // React to settings changes
    _ref.listen(settingsProvider, (previous, next) {
      state = state.copyWith(
        isBiometricEnabled: next.isBiometricEnabled,
        isBiometricSupported: next.isBiometricSupported,
      );
    });
  }

  final LoginRepository _repository;
  final Ref _ref;

  Future<void> _initBiometrics() async {
    if (kIsWeb) {
      state = state.copyWith(
        isBiometricSupported: false,
        isBiometricEnabled: false,
      );
      return;
    }
    try {
      final biometricService = _ref.read(biometricServiceProvider);
      final isSupported = await biometricService.isBiometricAvailable();

      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('biometric_login_enabled') ?? false;

      state = state.copyWith(
        isBiometricSupported: isSupported,
        isBiometricEnabled: isEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        isBiometricSupported: false,
        isBiometricEnabled: false,
      );
    }
  }

  /// Update the email field in the state
  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      errorMessage: null, // Clear error when user starts typing
    );
  }

  /// Update the password field in the state
  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      errorMessage: null, // Clear error when user starts typing
    );
  }

  /// Toggle the remember me state
  void toggleRememberMe(bool? value) {
    state = state.copyWith(rememberMe: value ?? false);
  }

  /// Manually set an error message in the state
  void setError(String? message) {
    if (message == null) {
      state = state.copyWith(errorMessage: null);
    } else {
      state = state.setError(message);
    }
  }

  /// Resets the login state to initial values
  void reset() {
    state = const LoginState();
    _initBiometrics();
  }

  /// Performs biometric authentication and login
  Future<void> loginWithBiometrics() async {
    if (state.isLoading || kIsWeb) return;

    final biometricService = _ref.read(biometricServiceProvider);
    final secureStorage = _ref.read(secureStorageServiceProvider);

    final isAuthenticated = await biometricService.authenticate(
      reason: 'Please authenticate to access the Command Center',
    );

    if (isAuthenticated) {
      final savedEmail = await secureStorage.read('biometric_email');
      final savedPassword = await secureStorage.read('biometric_password');

      if (savedEmail != null && savedPassword != null) {
        state = state.copyWith(
          email: savedEmail,
          password: savedPassword,
          isLoading: true,
        );
        // Explicitly call the internal login logic to bypass state reset
        await _performLoginLogic();
      } else {
        state = state.setError(
          'Biometric login is not configured. Please log in manually first.',
        );
      }
    }
  }

  /// Internal login logic shared between normal and biometric login
  Future<void> _performLoginLogic() async {
    try {
      final token = await _repository.login(state.email, state.password);

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (state.rememberMe) {
          await prefs.setString('saved_login_email', state.email);
        } else {
          await prefs.remove('saved_login_email');
        }

        // Securely store credentials for future biometric use (Mobile only)
        if (!kIsWeb) {
          final secureStorage = _ref.read(secureStorageServiceProvider);
          await secureStorage.write('biometric_email', state.email);
          await secureStorage.write('biometric_password', state.password);
        }

        await _ref.read(authGuardProvider.notifier).establishSession(token);
        state = state.setSuccess();
      }
    } catch (e) {
      if (mounted) {
        state = state.setError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// Performs the login operation using current state values or provided ones
  Future<void> login([String? email, String? password]) async {
    if (state.isLoading) return;

    if (email != null && password != null) {
      state = state.copyWith(email: email, password: password);
    }

    state = state.setLoading();
    await _performLoginLogic();
  }

  /// Logs out the user and clears the session
  Future<void> logout() async {
    await _ref.read(authGuardProvider.notifier).clearSession();
    reset();
  }
}
