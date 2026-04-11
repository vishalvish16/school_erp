// =============================================================================
// FILE: lib/features/auth/device_verification_screen.dart
// PURPOSE: OTP verification for new device — same visual style as login
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../design_system/design_system.dart';
import '../../core/services/local_storage_service.dart';
import 'auth_guard_provider.dart';
import 'auto_lock_provider.dart';
import 'auth_screen_layout.dart';

class DeviceVerificationScreen extends ConsumerStatefulWidget {
  const DeviceVerificationScreen({
    super.key,
    required this.otpSessionId,
    this.maskedPhone,
    this.maskedEmail,
    this.otpSentTo,
    this.portalType,
    this.devOtp,
  });

  final String otpSessionId;
  final String? maskedPhone;
  final String? maskedEmail;
  final String? otpSentTo;
  final String? portalType;
  final String? devOtp;

  @override
  ConsumerState<DeviceVerificationScreen> createState() =>
      _DeviceVerificationScreenState();
}

class _DeviceVerificationScreenState
    extends ConsumerState<DeviceVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _trustDevice = true;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _attempts = 0;
  Timer? _expiryTimer;
  int _expirySeconds = 120;
  late String _otpSessionId;
  String? _maskedPhone;
  String? _maskedEmail;
  String? _otpSentTo;

  @override
  void initState() {
    super.initState();
    _otpSessionId = widget.otpSessionId;
    _maskedPhone = widget.maskedPhone;
    _maskedEmail = widget.maskedEmail;
    _otpSentTo = widget.otpSentTo;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _expirySeconds > 0) {
        setState(() => _expirySeconds--);
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length != 6) return;
    if (_attempts >= 3) {
      setState(
        () =>
            _errorMessage = AppStrings.tooManyAttemptsGoBack,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final result = await auth.verifyDeviceOtp(
        otpSessionId: _otpSessionId,
        otpCode: _otpCode,
        trustDevice: _trustDevice,
        portalType: widget.portalType,
      );

      if (mounted) {
        final token = result['session_token'] as String?;
        if (token != null) {
          final portal = result['portal_type']?.toString() ?? widget.portalType;
          if (!kIsWeb && portal != null) {
            await LocalStorageService().setPortalType(portal);
          }
          await ref
              .read(authGuardProvider.notifier)
              .establishSession(
                token,
                portalTypeOverride:
                    result['portal_type']?.toString() ?? widget.portalType,
              );
          ref.read(autoLockProvider.notifier).resetTimer();
          if (mounted) {
            final effectivePortal =
                portal ?? ref.read(authGuardProvider).portalType;
            final isSuperAdmin = effectivePortal == 'super_admin';
            final isGroupAdmin = effectivePortal == 'group_admin';
            final path = isSuperAdmin
                ? '/super-admin/dashboard'
                : isGroupAdmin
                    ? '/group-admin/dashboard'
                    : '/dashboard';
            context.go(path);
          }
        } else {
          setState(() => _errorMessage = AppStrings.verificationFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attempts++;
          _isLoading = false;
          _errorMessage = _attempts >= 3
              ? AppStrings.tooManyAttemptsGoBack
              : (e.toString().replaceAll('Exception: ', ''));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _deliveryMessage {
    if (_otpSentTo == 'phone and email') {
      return 'New device detected. A 6-digit code was sent to your phone and email';
    }
    if (_maskedPhone != null && _maskedPhone!.isNotEmpty) {
      return 'New device detected. A 6-digit code was sent to $_maskedPhone';
    }
    if (_maskedEmail != null && _maskedEmail!.isNotEmpty) {
      return 'New device detected. A 6-digit code was sent to $_maskedEmail';
    }
    return 'New device detected. A 6-digit code was sent to your phone and email';
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final result = await auth.resendDeviceOtp(otpSessionId: _otpSessionId);
      if (mounted) {
        setState(() {
          _otpSessionId = result['otp_session_id']?.toString() ?? _otpSessionId;
          _expirySeconds = result['expires_in'] as int? ?? 120;
          _maskedPhone = result['masked_phone']?.toString();
          _maskedEmail = result['masked_email']?.toString();
          _otpSentTo = result['otp_sent_to']?.toString();
          _isResending = false;
          _errorMessage = null;
        });
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        AppSnackbar.success(context,
              result['otp_sent_to'] == 'phone and email'
                  ? AppStrings.newCodeSentPhoneEmail
                  : AppStrings.newCodeSent);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < AuthSizes.breakpointMobile;

    return AuthScreenLayout(loading: _isLoading, child: _buildCard(isMobile));
  }

  Widget _buildCard(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuthSizes.glassBlurStrong,
          sigmaY: AuthSizes.glassBlurStrong,
        ),
        child: Container(
          width: isMobile ? double.infinity : AuthSizes.cardWidthFixed,
          padding: const EdgeInsets.all(AuthSizes.cardPadding),
          decoration: BoxDecoration(
            color: AuthColors.overlayLight(0.25),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(
              color: AuthColors.overlayLight(0.5),
              width: AuthSizes.glassBorderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, size: 48, color: AuthColors.primary),
              AppSpacing.vGapLg,
              Text(
                AppStrings.verifyYourIdentity,
                style: AuthTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              Text(
                _deliveryMessage,
                style: AuthTextStyles.screenSubtitle,
                textAlign: TextAlign.center,
              ),
              if (widget.devOtp != null) ...[
                AppSpacing.vGapMd,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bug_report,
                        size: 16,
                        color: Colors.amber,
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        'DEV OTP: ${widget.devOtp}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              AppSpacing.vGapXl,
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const gap = 6.0;
                  const minFieldWidth = 36.0;
                  const maxFieldWidth = 48.0;
                  final fieldWidth = ((availableWidth - 5 * gap) / 6)
                      .clamp(minFieldWidth, maxFieldWidth)
                      .toDouble();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(6, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : gap / 2,
                          right: i == 5 ? 0 : gap / 2,
                        ),
                        child: SizedBox(
                          width: fieldWidth,
                          height: 52,
                          child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        enableSuggestions: false,
                        autocorrect: false,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) {
                          if (v.length == 1 && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_otpCode.length == 6) {
                            _verify();
                          }
                        },
                        style: TextStyle(
                          fontSize: (fieldWidth * 0.5).clamp(14, 22),
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral800,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.9),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AuthSizes.formFieldRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                  );
                },
              ),
              AppSpacing.vGapSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expirySeconds > 0
                        ? 'Expires in ${_expirySeconds ~/ 60}:${(_expirySeconds % 60).toString().padLeft(2, '0')}'
                        : AppStrings.codeExpired,
                    style: AuthTextStyles.screenSubtitle,
                  ),
                  AppSpacing.hGapLg,
                  TextButton(
                    onPressed: _isResending ? null : _resend,
                    child: Text(
                      _isResending
                          ? AppStrings.sending
                          : (_expirySeconds <= 0 ? AppStrings.resendCode : AppStrings.resend),
                      style: TextStyle(
                        color: AuthColors.primary,
                        fontWeight:
                            _expirySeconds <= 0 ? FontWeight.w600 : FontWeight.w500,
                        fontSize: _expirySeconds <= 0 ? 14 : 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                AppSpacing.vGapMd,
                Text(
                  _errorMessage!,
                  style: AuthTextStyles.screenSubtitle.copyWith(
                    color: AppColors.error500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              AppSpacing.vGapXl,
              Row(
                children: [
                  Switch(
                    value: _trustDevice,
                    onChanged: (v) => setState(() => _trustDevice = v),
                    activeTrackColor: AuthColors.primary,
                    activeThumbColor: Colors.white,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.rememberDevice30Days,
                          style: AuthTextStyles.rememberMe,
                        ),
                        Text(
                          AppStrings.skipStepNextTime,
                          style: AuthTextStyles.screenSubtitle.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXl,
              SizedBox(
                width: double.infinity,
                height: AuthSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading || _otpCode.length != 6
                      ? null
                      : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AuthSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text(AppStrings.verifyAndContinue),
                ),
              ),
              AppSpacing.vGapLg,
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  AppStrings.reportSuspiciousLogin,
                  style: AuthTextStyles.forgotPassword.copyWith(
                    color: AuthColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
