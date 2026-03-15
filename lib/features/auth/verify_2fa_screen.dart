// =============================================================================
// FILE: lib/features/auth/verify_2fa_screen.dart
// PURPOSE: 2FA (TOTP) verification for Super Admin login
// =============================================================================

import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/local_storage_service.dart';
import 'auth_guard_provider.dart';
import 'auto_lock_provider.dart';
import 'auth_screen_layout.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class Verify2faScreen extends ConsumerStatefulWidget {
  const Verify2faScreen({
    super.key,
    required this.tempToken,
    this.portalType,
  });

  final String tempToken;
  final String? portalType;

  @override
  ConsumerState<Verify2faScreen> createState() => _Verify2faScreenState();
}

class _Verify2faScreenState extends ConsumerState<Verify2faScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _trustDevice = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _attempts = 0;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _totpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_totpCode.length != 6) return;
    if (_attempts >= 5) {
      setState(() => _errorMessage = AppStrings.tooManyAttemptsLoginAgain);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final result = await auth.verify2fa(
        tempToken: widget.tempToken,
        totpCode: _totpCode,
        trustDevice: _trustDevice,
      );

      if (!mounted) return;

      final token = result['session_token'] as String?;
      if (token != null) {
        final portal = result['portal_type']?.toString() ?? widget.portalType;
        if (!kIsWeb && portal != null) {
          await LocalStorageService().setPortalType(portal);
        }
        await ref.read(authGuardProvider.notifier).establishSession(
              token,
              portalTypeOverride: result['portal_type']?.toString() ?? widget.portalType,
            );
        ref.read(autoLockProvider.notifier).resetTimer();
        if (mounted) {
          final effectivePortal = portal ?? ref.read(authGuardProvider).portalType;
          final isSuperAdmin = effectivePortal == 'super_admin';
          context.go(isSuperAdmin ? '/super-admin/dashboard' : '/dashboard');
        }
        return;
      }

      if (result['requires_device_otp'] == true) {
        final sessionId = result['otp_session_id']?.toString();
        final masked = result['masked_phone']?.toString() ?? '';
        final portal = result['portal_type'] ?? widget.portalType;
        if (sessionId != null && sessionId.isNotEmpty) {
          final q = 'otp_session_id=$sessionId&masked_phone=${Uri.encodeComponent(masked)}${portal != null ? '&portal_type=$portal' : ''}';
          context.go('/device-verification?$q');
        } else {
          setState(() => _errorMessage = AppStrings.verificationFailed);
        }
      } else {
        setState(() => _errorMessage = AppStrings.verificationFailed);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attempts++;
          _isLoading = false;
          _errorMessage = _attempts >= 5
              ? AppStrings.tooManyAttemptsLoginAgain
              : (e.toString().replaceAll('Exception: ', ''));
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AuthSizes.breakpointMobile;

    return AuthScreenLayout(
      loading: _isLoading,
      child: _buildCard(isMobile),
    );
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
            border: Border.all(color: AuthColors.overlayLight(0.5), width: AuthSizes.glassBorderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, size: 48, color: AuthColors.primary),
              AppSpacing.vGapLg,
              Text(
                AppStrings.twoFactorAuth,
                style: AuthTextStyles.screenTitle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              AppSpacing.vGapSm,
              Text(
                AppStrings.enter6DigitCode,
                style: AuthTextStyles.screenSubtitle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
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
                              if (_totpCode.length == 6) {
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
              if (_errorMessage != null) ...[
                AppSpacing.vGapMd,
                Text(
                  _errorMessage!,
                  style: AuthTextStyles.screenSubtitle.copyWith(color: AppColors.error500),
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
                        Text(AppStrings.rememberDevice30Days, style: AuthTextStyles.rememberMe),
                        Text(
                          AppStrings.skipDeviceVerificationNextTime,
                          style: AuthTextStyles.screenSubtitle.copyWith(fontSize: 12),
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
                  onPressed: _isLoading || _totpCode.length != 6 ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AuthSizes.buttonRadius),
                    ),
                  ),
                  child: const Text(AppStrings.verifyAndContinue),
                ),
              ),
              AppSpacing.vGapLg,
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  AppStrings.backToLogin,
                  style: AuthTextStyles.forgotPassword.copyWith(color: AuthColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
