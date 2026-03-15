// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_forgot_password_screen.dart
// PURPOSE: Group Admin forgot password — email input → API call → success state.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/group_admin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

class GroupAdminForgotPasswordScreen extends ConsumerStatefulWidget {
  const GroupAdminForgotPasswordScreen({super.key});

  @override
  ConsumerState<GroupAdminForgotPasswordScreen> createState() =>
      _GroupAdminForgotPasswordScreenState();
}

class _GroupAdminForgotPasswordScreenState
    extends ConsumerState<GroupAdminForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(groupAdminServiceProvider)
          .forgotPassword(_emailController.text.trim());
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
        title: const Text(AppStrings.forgotPassword),
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
                child: _success ? _buildSuccess(context) : _buildForm(scheme),
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
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.success500),
        AppSpacing.vGapLg,
        Text(
          'Check your email',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapSm,
        Text(
          'Password reset instructions have been sent to ${_emailController.text.trim()}. Please check your inbox.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXl,
        OutlinedButton.icon(
          onPressed: () => context.go('/login/group'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 48, color: scheme.primary),
          AppSpacing.vGapLg,
          Text(
            'Reset Password',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapSm,
          Text(
            'Enter your email address and we will send you password reset instructions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapXl,
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: AppStrings.emailAddress,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!v.contains('@')) return 'Enter a valid email';
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
                  Icon(Icons.error_outline,
                      color: scheme.error, size: 18),
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
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.sendResetInstructions),
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
