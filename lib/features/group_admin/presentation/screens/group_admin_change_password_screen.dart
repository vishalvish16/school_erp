// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_change_password_screen.dart
// PURPOSE: Change password for group admin — same structure as super admin version.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_auth_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/design_system.dart';

class GroupAdminChangePasswordScreen extends ConsumerStatefulWidget {
  const GroupAdminChangePasswordScreen({super.key});

  @override
  ConsumerState<GroupAdminChangePasswordScreen> createState() =>
      _GroupAdminChangePasswordScreenState();
}

class _GroupAdminChangePasswordScreenState
    extends ConsumerState<GroupAdminChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

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
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final current = _currentController.text.trim();
    final newPw = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPw != confirm) {
      AppSnackbar.error(context, AuthStrings.keysDoNotMatch);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(groupAdminServiceProvider).changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      if (mounted) {
        AppSnackbar.success(context, AuthStrings.passwordUpdated);
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/group-admin/profile'),
                        ),
                        AppSpacing.hGapSm,
                        Icon(Icons.lock_reset,
                            size: 32,
                            color:
                                Theme.of(context).colorScheme.primary),
                        AppSpacing.hGapMd,
                        Text(
                          AppStrings.changePassword,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      'Update your security key. Use a strong password with uppercase, lowercase, numbers, and special characters.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    AppSpacing.vGapXl,
                    TextFormField(
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: AppStrings.currentPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Current password is required';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.vGapLg,
                    TextFormField(
                      controller: _newController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: AuthStrings.newSecurityKey,
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
                          return AuthStrings.passwordRequired;
                        }
                        for (final r in _passwordRules) {
                          if (!r.check(v)) return '${r.label} required';
                        }
                        return null;
                      },
                    ),
                    _buildPasswordRulesBox(_newController.text),
                    AppSpacing.vGapLg,
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: AuthStrings.authorizeSecurityKey,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return AuthStrings.passwordRequired;
                        }
                        if (v != _newController.text) {
                          return AuthStrings.keysDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    AppSpacing.vGapXl,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  _currentController.clear();
                                  _newController.clear();
                                  _confirmController.clear();
                                },
                          child: const Text(AppStrings.clear),
                        ),
                        AppSpacing.hGapSm,
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text(AuthStrings.finalizeUpdate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
