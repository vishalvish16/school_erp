// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_change_password_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_auth_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class SchoolAdminChangePasswordScreen extends ConsumerStatefulWidget {
  const SchoolAdminChangePasswordScreen({super.key});

  @override
  ConsumerState<SchoolAdminChangePasswordScreen> createState() =>
      _SchoolAdminChangePasswordScreenState();
}

class _SchoolAdminChangePasswordScreenState
    extends ConsumerState<SchoolAdminChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;

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
    _newCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Widget _buildPasswordRulesBox(String password) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                AppStrings.tooltipRequirements,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          ..._passwordRules.map((r) {
            final satisfied = r.check(password);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    satisfied ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: satisfied ? AppColors.success500 : scheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: satisfied ? AppColors.success500 : scheme.error,
                        fontWeight:
                            satisfied ? FontWeight.w600 : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.changePassword,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppSpacing.vGapSm,
                Text(
                  'Update your account password. Use a strong password with uppercase, lowercase, numbers, and special characters.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                AppSpacing.vGapXl,
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _currentCtrl,
                            obscureText: !_showCurrent,
                            decoration: InputDecoration(
                              labelText: AppStrings.currentPassword,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _showCurrent = !_showCurrent),
                                icon: Icon(_showCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Enter current password'
                                    : null,
                          ),
                          AppSpacing.vGapLg,
                          TextFormField(
                            controller: _newCtrl,
                            obscureText: !_showNew,
                            decoration: InputDecoration(
                              labelText: AppStrings.newPassword,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _showNew = !_showNew),
                                icon: Icon(_showNew
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter new password';
                              }
                              for (final r in _passwordRules) {
                                if (!r.check(v)) return '${r.label} required';
                              }
                              return null;
                            },
                          ),
                          _buildPasswordRulesBox(_newCtrl.text),
                          AppSpacing.vGapLg,
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: !_showConfirm,
                            decoration: InputDecoration(
                              labelText: AppStrings.confirmNewPassword,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _showConfirm = !_showConfirm),
                                icon: Icon(_showConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirm your new password';
                              }
                              if (v != _newCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.vGapXl,
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.lock_reset),
                            label: Text(_isSaving
                                ? 'Updating...'
                                : 'Update Password'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(schoolAdminServiceProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        AppSnackbar.success(context, AppStrings.passwordUpdatedSuccess);
        _formKey.currentState?.reset();
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }
}
