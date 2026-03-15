import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/biometric_service.dart';
import 'auth_guard_provider.dart';
import 'auto_lock_provider.dart';
import 'login_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  bool _isObscured = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authGuardProvider);
      final email = authState.userEmail ?? 'vishal.vish16@gmail.com';

      final loginNotifier = ref.read(loginProvider.notifier);
      await loginNotifier.login(email, _passwordController.text.trim());

      if (mounted) {
        ref.read(autoLockProvider.notifier).unlock();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.invalidSecurityKey;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricUnlock() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(loginProvider.notifier).loginWithBiometrics();
      if (mounted && ref.read(loginProvider).isSuccess) {
        ref.read(autoLockProvider.notifier).unlock();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AppStrings.biometricFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppSpacing.paddingHXl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile/Lock Icon
                    Container(
                      padding: AppSpacing.paddingXl,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary500.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: AppColors.neutral800,
                      ),
                    ),
                    AppSpacing.vGapXl,
                    const Text(
                      AppStrings.sessionLocked,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral800,
                        letterSpacing: -1,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    const Text(
                      AppStrings.vidyronSecurityActive,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Glassmorphic Form Card (Matches LoginScreen)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: AppRadius.brXl3,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Identifier
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: AppRadius.brLg,
                              border: Border.all(color: Colors.white),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary500,
                                  size: 20,
                                ),
                                AppSpacing.hGapMd,
                                Expanded(
                                  child: Text(
                                    ref.watch(authGuardProvider).userEmail ??
                                        AppStrings.roleSuperAdmin,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutral800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vGapLg,

                          // Password Input (Matches LoginScreen style)
                          Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness == Brightness.dark ||
                                  MediaQuery.platformBrightnessOf(context) == Brightness.dark;
                              final textColor = isDark ? AppColors.neutral50 : AppColors.neutral800;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: AppRadius.brLg,
                                  border: Border.all(color: Colors.white),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _isObscured,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppStrings.securityKey,
                                    hintStyle: const TextStyle(
                                      color: AppColors.neutral400,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.key_rounded,
                                      color: AppColors.primary500,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscured
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.neutral400,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _isObscured = !_isObscured,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.lg,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_errorMessage != null) ...[
                            AppSpacing.vGapMd,
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          AppSpacing.vGapXl2,

                          // Gradient Button (Matches LoginScreen)
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.brLg,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary500, AppColors.secondary500],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleUnlock,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.brLg,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      AppStrings.unlockSession,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          // Biometric Unlock (Mobile Only - Face or Fingerprint)
                          Builder(
                            builder: (context) {
                              final loginState = ref.watch(loginProvider);
                              if (kIsWeb || !loginState.isBiometricSupported) {
                                return const SizedBox.shrink();
                              }
                              final type = loginState.primaryBiometricType;
                              final icon = type == BiometricTypeUI.face
                                  ? Icons.face_rounded
                                  : Icons.fingerprint_rounded;
                              final label = type == BiometricTypeUI.face
                                  ? AppStrings.unlockWithFace
                                  : type == BiometricTypeUI.fingerprint
                                      ? AppStrings.unlockWithFingerprint
                                      : AppStrings.unlockWithFaceOrFingerprint;
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleBiometricUnlock,
                                  icon: Icon(icon, color: AppColors.primary500),
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.neutral800,
                                    ),
                                  ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.brLg,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          );
                            },
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.vGapXl2,
                    TextButton(
                      onPressed: () {
                        ref.read(loginProvider.notifier).logout();
                        ref.read(autoLockProvider.notifier).unlock();
                      },
                      child: Text(
                        AppStrings.switchAccountLogout,
                        style: TextStyle(
                          color: AppColors.neutral500.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
