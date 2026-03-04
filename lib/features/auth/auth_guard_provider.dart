// =============================================================================
// FILE: lib/features/auth/auth_guard_provider.dart
// PURPOSE: Core authentication guard to manage tokens, expiry, and session logic.
// =============================================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to access the AuthGuardNotifier
final authGuardProvider =
    StateNotifierProvider<AuthGuardNotifier, AuthGuardState>((ref) {
      return AuthGuardNotifier();
    });

/// Immutable state representing the current session
class AuthGuardState {
  const AuthGuardState({
    this.isAuthenticated = false,
    this.accessToken,
    this.userEmail,
    this.isInitializing = true,
  });

  final bool isAuthenticated;
  final String? accessToken;
  final String? userEmail;
  final bool isInitializing;

  AuthGuardState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? userEmail,
    bool? isInitializing,
  }) {
    return AuthGuardState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      userEmail: userEmail ?? this.userEmail,
      isInitializing: isInitializing ?? false,
    );
  }
}

/// Headless provider responsible for token lifecycle and session validation
class AuthGuardNotifier extends StateNotifier<AuthGuardState> {
  AuthGuardNotifier() : super(const AuthGuardState()) {
    _initSession();
  }

  /// Initialization called on app startup to verify existing sessions
  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool wasLocked =
        prefs.getBool('is_session_locked_persistently') ?? false;
    final String? token = prefs.getString('access_token');

    if (wasLocked) {
      // If the app was killed while locked, force a fresh login
      await clearSession();
      await prefs.remove('is_session_locked_persistently');
      return;
    }

    if (token != null && token.isNotEmpty) {
      if (_isTokenValid(token)) {
        // Valid Session
        state = state.copyWith(
          isAuthenticated: true,
          accessToken: token,
          userEmail: _extractEmail(token),
          isInitializing: false,
        );
      } else {
        // Expired Session - clear token
        await clearSession();
      }
    } else {
      // No Session
      state = state.copyWith(
        isAuthenticated: false,
        accessToken: null,
        isInitializing: false,
      );
    }
  }

  /// Validates the token format and checks the expiration claim
  /// Prepared for JWT decoding later.
  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Pad base64 for decoding
      String payloadStr = parts[1];
      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }

      final payload = json.decode(utf8.decode(base64Url.decode(payloadStr)));
      final expiry = payload['exp'] * 1000;
      return DateTime.now().millisecondsSinceEpoch < expiry;
    } catch (e) {
      return false;
    }
  }

  String? _extractEmail(String token) {
    try {
      final parts = token.split('.');
      String payloadStr = parts[1];
      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }
      final payload = json.decode(utf8.decode(base64Url.decode(payloadStr)));
      return payload['email'];
    } catch (e) {
      return null;
    }
  }

  /// Exposes current authentication status synchronously
  bool isAuthenticated() {
    return state.isAuthenticated;
  }

  /// Establishes a new authenticated session (called after login success)
  Future<void> establishSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    state = state.copyWith(
      isAuthenticated: true,
      accessToken: token,
      userEmail: _extractEmail(token),
      isInitializing: false,
    );
  }

  /// Destroys the current session and purges sensitive local data
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    state = state.copyWith(
      isAuthenticated: false,
      accessToken: null,
      isInitializing: false,
    );
  }
}
