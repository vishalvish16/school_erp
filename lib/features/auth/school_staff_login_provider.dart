// =============================================================================
// FILE: lib/features/auth/school_staff_login_provider.dart
// PURPOSE: Riverpod StateNotifier for School Admin & Staff login (generic platform login).
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_guard_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../models/school_identity.dart';

// ── State ──────────────────────────────────────────────────────────────────

@immutable
class SchoolStaffLoginState {
  const SchoolStaffLoginState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.requiresOtp = false,
    this.requires2fa = false,
    this.otpSessionId,
    this.maskedPhone,
    this.maskedEmail,
    this.otpSentTo,
    this.devOtp,
    this.tempToken,
    this.portalType,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool requiresOtp;
  final bool requires2fa;
  final String? otpSessionId;
  final String? maskedPhone;
  final String? maskedEmail;
  final String? otpSentTo;
  final String? devOtp;
  final String? tempToken;
  final String? portalType;

  SchoolStaffLoginState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    bool? requiresOtp,
    bool? requires2fa,
    String? otpSessionId,
    String? maskedPhone,
    String? maskedEmail,
    String? otpSentTo,
    String? devOtp,
    String? tempToken,
    String? portalType,
  }) {
    return SchoolStaffLoginState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requiresOtp: requiresOtp ?? this.requiresOtp,
      requires2fa: requires2fa ?? this.requires2fa,
      otpSessionId: otpSessionId ?? this.otpSessionId,
      maskedPhone: maskedPhone ?? this.maskedPhone,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      otpSentTo: otpSentTo ?? this.otpSentTo,
      devOtp: devOtp ?? this.devOtp,
      tempToken: tempToken ?? this.tempToken,
      portalType: portalType ?? this.portalType,
    );
  }

  SchoolStaffLoginState setLoading() => copyWith(
        isLoading: true,
        isSuccess: false,
        clearError: true,
      );

  SchoolStaffLoginState setError(String message) => SchoolStaffLoginState(
        isLoading: false,
        isSuccess: false,
        errorMessage: message,
        requiresOtp: requiresOtp,
        requires2fa: requires2fa,
        otpSessionId: otpSessionId,
        maskedPhone: maskedPhone,
        maskedEmail: maskedEmail,
        otpSentTo: otpSentTo,
        devOtp: devOtp,
        tempToken: tempToken,
        portalType: portalType,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class SchoolStaffLoginNotifier extends StateNotifier<SchoolStaffLoginState> {
  SchoolStaffLoginNotifier(this._auth, this._ref)
      : super(const SchoolStaffLoginState());

  final AuthService _auth;
  final Ref _ref;

  Future<void> login(
    String email,
    String password, {
    required String? schoolId,
    String portalType = 'school_admin',
    bool trustDevice = false,
    SchoolIdentity? schoolIdentity,
  }) async {
    if (state.isLoading) return;
    state = state.setLoading();

    try {
      final response = await _auth.login(
        identifier: email,
        password: password,
        portalType: portalType,
        schoolId: schoolId,
        trustDevice: trustDevice,
      );

      if (response['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading: false,
          requires2fa: true,
          tempToken: response['temp_token']?.toString(),
          portalType: response['portal_type']?.toString(),
        );
        return;
      }

      if (response['requires_otp'] == true) {
        state = state.copyWith(
          isLoading: false,
          requiresOtp: true,
          otpSessionId: response['otp_session_id']?.toString(),
          maskedPhone: response['masked_phone']?.toString(),
          maskedEmail: response['masked_email']?.toString(),
          otpSentTo: response['otp_sent_to']?.toString(),
          devOtp: response['dev_otp']?.toString(),
          portalType: response['portal_type']?.toString(),
        );
        return;
      }

      final token = response['session_token'] as String? ??
          response['access_token'] as String?;
      if (token != null) {
        var portal = response['portal_type']?.toString() ?? portalType;
        final designation = response['designation']?.toString() ??
            response['staff']?['designation']?.toString();

        const teachingDesignations = {
          'TEACHER', 'PRINCIPAL', 'VICE_PRINCIPAL', 'HOD',
        };
        if (portal == 'staff' &&
            designation != null &&
            teachingDesignations.contains(designation.toUpperCase())) {
          portal = 'teacher';
        }

        await _ref.read(authGuardProvider.notifier).establishSession(
              token,
              portalTypeOverride: portal,
              designation: designation,
            );
        if (!kIsWeb) {
          await LocalStorageService().setPortalType(portal);
          if (schoolIdentity != null) {
            await LocalStorageService().saveSchool(schoolIdentity);
          }
        }
        state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            clearError: true,
          );
      } else {
        state = state.setError(
          response['message']?.toString() ?? 'Invalid response from server',
        );
      }
    } catch (e) {
      state = state.setError(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const SchoolStaffLoginState();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final schoolStaffLoginProvider =
    StateNotifierProvider<SchoolStaffLoginNotifier, SchoolStaffLoginState>(
        (ref) {
  return SchoolStaffLoginNotifier(ref.read(authServiceProvider), ref);
});
