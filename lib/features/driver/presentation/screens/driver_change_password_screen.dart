// =============================================================================
// FILE: lib/features/driver/presentation/screens/driver_change_password_screen.dart
// PURPOSE: Change password screen for the Driver portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_auth_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/driver_service.dart';
import '../../../../design_system/design_system.dart';

const Color _accentColor = AppColors.driverAccent;

class DriverChangePasswordScreen extends ConsumerStatefulWidget {
  const DriverChangePasswordScreen({super.key});

  @override
  ConsumerState<DriverChangePasswordScreen> createState() =>
      _DriverChangePasswordScreenState();
}

class _DriverChangePasswordScreenState
    extends ConsumerState<DriverChangePasswordScreen> {
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
      check: (s) => s.contains(
          RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]')),
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
        color: scheme.surfaceContainerHighest.withValues(alpha: AppOpacity.medium),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: AppIconSize.sm, color: scheme.primary),
              AppSpacing.hGapSm,
              Text(
                AppStrings.tooltipRequirements,
                style: AppTextStyles.caption(color: scheme.onSurface),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          ..._passwordRules.map((r) {
            final satisfied = r.check(password);
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    satisfied ? Icons.check_circle : Icons.cancel,
                    size: AppIconSize.sm,
                    color: satisfied ? AppColors.success500 : scheme.error,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      r.label,
                      style: AppTextStyles.bodySm(
                        color: satisfied ? AppColors.success500 : scheme.error,
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.driverChangePasswordTitle,
                  style: AppTextStyles.h4(color: scheme.onSurface),
                ),
                AppSpacing.vGapSm,
                Text(
                  'Update your account password. Use a strong password with uppercase, lowercase, numbers, and special characters.',
                  style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
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
                                onPressed: () =>
                                    setState(() => _showCurrent = !_showCurrent),
                                icon: Icon(
                                  _showCurrent
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? AppStrings.driverEnterCurrentPassword
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
                                icon: Icon(
                                  _showNew
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return AppStrings.driverEnterNewPassword;
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
                                icon: Icon(
                                  _showConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return AppStrings.driverConfirmNewPassword;
                              }
                              if (v != _newCtrl.text) {
                                return AppStrings.driverPasswordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          AppSpacing.vGapXl,
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? SizedBox(
                                    width: AppIconSize.sm,
                                    height: AppIconSize.sm,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset, size: AppIconSize.sm),
                            label: Text(
                              _isSaving
                                  ? AppStrings.driverUpdatingPassword
                                  : AppStrings.driverUpdatePassword,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              padding: AppSpacing.paddingVLg,
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
      await ref.read(driverServiceProvider).changePassword(
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
        AppSnackbar.error(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }
}
