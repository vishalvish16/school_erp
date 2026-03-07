import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/biometric_service.dart';
import 'auth_guard_provider.dart';
import 'auto_lock_provider.dart';
import 'login_provider.dart';

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
          _errorMessage = 'Invalid security key. Please try again.';
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
        setState(() => _errorMessage = 'Biometric authentication failed.');
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile/Lock Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Session Locked',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vidyron One Security active. Enter key.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569),
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
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ref.watch(authGuardProvider).userEmail ??
                                        'Super Admin',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Input (Matches LoginScreen style)
                          Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness == Brightness.dark ||
                                  MediaQuery.platformBrightnessOf(context) == Brightness.dark;
                              final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
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
                                    hintText: 'Security Key',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.key_rounded,
                                      color: Color(0xFF6366F1),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscured
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _isObscured = !_isObscured,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Gradient Button (Matches LoginScreen)
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
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
                                  borderRadius: BorderRadius.circular(12),
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
                                      'Unlock Session',
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
                                  ? 'Unlock with Face'
                                  : type == BiometricTypeUI.fingerprint
                                      ? 'Unlock with Fingerprint'
                                      : 'Unlock with Face or Fingerprint';
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleBiometricUnlock,
                                  icon: Icon(icon, color: const Color(0xFF6366F1)),
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        ref.read(loginProvider.notifier).logout();
                        ref.read(autoLockProvider.notifier).unlock();
                      },
                      child: Text(
                        'Switch Account / Logout',
                        style: TextStyle(
                          color: const Color(0xFF64748B).withOpacity(0.8),
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
