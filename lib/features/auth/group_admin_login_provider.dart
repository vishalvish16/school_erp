// =============================================================================
// FILE: lib/features/auth/group_admin_login_provider.dart
// PURPOSE: Riverpod StateNotifier to manage Group Admin Login flow.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_guard_provider.dart';
import '../../core/services/group_admin_service.dart';

// ── State ──────────────────────────────────────────────────────────────────

@immutable
class GroupAdminLoginState {
  const GroupAdminLoginState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.requiresOtp = false,
    this.otpSessionId,
    this.maskedPhone,
    this.maskedEmail,
    this.otpSentTo,
    this.devOtp,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool requiresOtp;
  final String? otpSessionId;
  final String? maskedPhone;
  final String? maskedEmail;
  final String? otpSentTo;
  final String? devOtp;

  bool get isFailure => errorMessage != null;

  GroupAdminLoginState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    bool? requiresOtp,
    String? otpSessionId,
    String? maskedPhone,
    String? maskedEmail,
    String? otpSentTo,
    String? devOtp,
  }) {
    return GroupAdminLoginState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requiresOtp: requiresOtp ?? this.requiresOtp,
      otpSessionId: otpSessionId ?? this.otpSessionId,
      maskedPhone: maskedPhone ?? this.maskedPhone,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      otpSentTo: otpSentTo ?? this.otpSentTo,
      devOtp: devOtp ?? this.devOtp,
    );
  }

  GroupAdminLoginState setLoading() => copyWith(
        isLoading: true,
        isSuccess: false,
        clearError: true,
      );

  GroupAdminLoginState setError(String message) => GroupAdminLoginState(
        isLoading: false,
        isSuccess: false,
        errorMessage: message,
        requiresOtp: requiresOtp,
        otpSessionId: otpSessionId,
        maskedPhone: maskedPhone,
        maskedEmail: maskedEmail,
        otpSentTo: otpSentTo,
        devOtp: devOtp,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class GroupAdminLoginNotifier extends StateNotifier<GroupAdminLoginState> {
  GroupAdminLoginNotifier(this._service, this._ref)
      : super(const GroupAdminLoginState());

  final GroupAdminService _service;
  final Ref _ref;

  Future<void> login(
    String email,
    String password,
    String groupId, {
    String? deviceFingerprint,
    Map<String, dynamic>? deviceMeta,
  }) async {
    if (state.isLoading) return;
    state = state.setLoading();

    try {
      final response = await _service.login({
        'identifier': email,
        'password': password,
        'group_id': groupId,
        'device_fingerprint': deviceFingerprint ?? 'web_browser',
        'device_meta': deviceMeta ?? {},
      });

      if (!mounted) return;

      if (response['requires_otp'] == true) {
        state = state.copyWith(
          isLoading: false,
          requiresOtp: true,
          otpSessionId: response['otp_session_id']?.toString(),
          maskedPhone: response['masked_phone']?.toString(),
          maskedEmail: response['masked_email']?.toString(),
          otpSentTo: response['otp_sent_to']?.toString(),
          devOtp: response['dev_otp']?.toString(),
        );
        return;
      }

      final token = response['access_token'] as String?;
      if (token != null) {
        await _ref.read(authGuardProvider.notifier).establishSession(
              token,
              portalTypeOverride:
                  response['portal_type']?.toString() ?? 'group_admin',
            );
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            clearError: true,
          );
        }
      } else {
        final errMsg = response['message'] ?? response['error'] ?? 'Invalid response from server';
        state = state.setError(errMsg.toString());
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final responseData = e.response?.data;
      String message = 'Login failed. Please try again.';
      if (responseData is Map) {
        final errors = responseData['errors'];
        if (errors is List && errors.isNotEmpty && errors.first is Map) {
          message = (errors.first as Map)['message']?.toString() ?? message;
        } else {
          message = responseData['error']?.toString() ??
              responseData['message']?.toString() ??
              message;
        }
      }
      state = state.setError(message);
    } catch (e) {
      if (!mounted) return;
      state = state.setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const GroupAdminLoginState();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final groupAdminLoginProvider =
    StateNotifierProvider<GroupAdminLoginNotifier, GroupAdminLoginState>((ref) {
  return GroupAdminLoginNotifier(ref.read(groupAdminServiceProvider), ref);
});
