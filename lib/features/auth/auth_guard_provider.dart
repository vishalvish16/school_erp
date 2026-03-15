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
    this.portalType,
    this.designation,
    this.isInitializing = true,
  });

  final bool isAuthenticated;
  final String? accessToken;
  final String? userEmail;
  final String? portalType;
  final String? designation;
  final bool isInitializing;

  bool get isSuperAdmin => portalType == 'super_admin';

  static const _teachingDesignations = {
    'TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD',
  };

  bool get isTeacher =>
      portalType == 'teacher' ||
      (designation != null &&
          _teachingDesignations.contains(designation!.toUpperCase()));

  AuthGuardState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? userEmail,
    String? portalType,
    String? designation,
    bool? isInitializing,
    bool clearPortalType = false,
    bool clearUserEmail = false,
    bool clearAccessToken = false,
    bool clearDesignation = false,
  }) {
    return AuthGuardState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      portalType: clearPortalType ? null : (portalType ?? this.portalType),
      designation: clearDesignation ? null : (designation ?? this.designation),
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
        final storedDesignation = prefs.getString('staff_designation');
        state = state.copyWith(
          isAuthenticated: true,
          accessToken: token,
          userEmail: _extractEmail(token),
          portalType: _extractPortalType(token),
          designation: storedDesignation,
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
      final payload = _decodePayload(token);
      return payload?['email'];
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payloadStr = parts[1];
      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }
      return json.decode(utf8.decode(base64Url.decode(payloadStr)));
    } catch (e) {
      return null;
    }
  }

  String? _extractPortalType(String token) {
    final payload = _decodePayload(token);
    return payload?['portal_type']?.toString();
  }

  /// Exposes current authentication status synchronously
  bool isAuthenticated() {
    return state.isAuthenticated;
  }

  /// Establishes a new authenticated session (called after login success)
  /// [portalTypeOverride] — use API response portal_type when token may not have it
  /// [designation] — staff designation for teacher portal detection
  Future<void> establishSession(
    String token, {
    String? portalTypeOverride,
    String? designation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    if (designation != null) {
      await prefs.setString('staff_designation', designation);
    }

    final portalType = portalTypeOverride ?? _extractPortalType(token);
    state = state.copyWith(
      isAuthenticated: true,
      accessToken: token,
      userEmail: _extractEmail(token),
      portalType: portalType,
      designation: designation,
      isInitializing: false,
    );
  }

  /// Destroys the current session and purges sensitive local data
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('staff_designation');

    state = const AuthGuardState(
      isAuthenticated: false,
      accessToken: null,
      userEmail: null,
      portalType: null,
      designation: null,
      isInitializing: false,
    );
  }
}
