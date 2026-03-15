// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_reset_password_screen.dart
// PURPOSE: Group Admin reset password — token from query param, new + confirm fields.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_auth_constants.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

class GroupAdminResetPasswordScreen extends ConsumerStatefulWidget {
  const GroupAdminResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<GroupAdminResetPasswordScreen> createState() =>
      _GroupAdminResetPasswordScreenState();
}

class _GroupAdminResetPasswordScreenState
    extends ConsumerState<GroupAdminResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _success = false;
  String? _error;

  static final List<({String label, bool Function(String) check})>
      _passwordRules = [
    (label: AuthStrings.passwordRuleMinLength, check: (s) => s.length >= 8),
    (
      label: AuthStrings.passwordRuleUppercase,
      check: (s) => s.contains(RegExp(r'[A-Z]')),
    ),
    (
      label: AuthStrings.passwordRuleLowercase,
      check: (s) => s.contains(RegExp(r'[a-z]')),
    ),
    (
      label: AuthStrings.passwordRuleNumber,
      check: (s) => s.contains(RegExp(r'[0-9]')),
    ),
    (
      label: AuthStrings.passwordRuleSpecial,
      check: (s) =>
          s.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]')),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _newController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token.isEmpty) {
      setState(() => _error = 'Invalid or missing reset token.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(groupAdminServiceProvider).resetPassword(
            widget.token,
            _newController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.resetPassword),
        leading: BackButton(
          onPressed: () => context.go('/login/group'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: _success
                    ? _buildSuccess(context)
                    : _buildForm(context, scheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success500),
        AppSpacing.vGapLg,
        Text(
          'Password updated!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapSm,
        Text(
          'Your password has been reset successfully. You can now sign in with your new password.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXl,
        FilledButton.icon(
          onPressed: () => context.go('/login/group'),
          icon: const Icon(Icons.login, size: 18),
          label: const Text(AppStrings.goToLogin),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset_outlined, size: 48, color: scheme.primary),
          AppSpacing.vGapLg,
          Text(
            'Set New Password',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapSm,
          Text(
            'Enter and confirm your new password below.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (widget.token.isEmpty) ...[
            AppSpacing.vGapLg,
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: scheme.error, size: 18),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'Invalid reset link. Please request a new one.',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.vGapXl,
          TextFormField(
            controller: _newController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: AppStrings.newPassword,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Password is required';
              }
              for (final r in _passwordRules) {
                if (!r.check(v)) return '${r.label} required';
              }
              return null;
            },
          ),
          // Password rules indicator
          if (_newController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _passwordRules.map((r) {
                  final ok = r.check(_newController.text);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          ok ? Icons.check_circle : Icons.cancel,
                          size: 13,
                          color: ok ? AppColors.success500 : scheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: ok ? AppColors.success500 : scheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          AppSpacing.vGapLg,
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: AppStrings.confirmNewPassword,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please confirm your password';
              if (v != _newController.text) return AuthStrings.keysDoNotMatch;
              return null;
            },
          ),
          if (_error != null) ...[
            AppSpacing.vGapMd,
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 18),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.vGapXl,
          FilledButton(
            onPressed: (_loading || widget.token.isEmpty) ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.resetPassword),
          ),
          AppSpacing.vGapMd,
          TextButton(
            onPressed: () => context.go('/login/group'),
            child: const Text(AppStrings.backToLogin),
          ),
        ],
      ),
    );
  }
}
