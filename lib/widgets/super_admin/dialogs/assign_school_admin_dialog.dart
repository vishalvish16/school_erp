// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/assign_school_admin_dialog.dart
// PURPOSE: Assign primary admin to a school (when none exists)
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../design_system/tokens/app_spacing.dart';

class AssignSchoolAdminDialog extends ConsumerStatefulWidget {
  const AssignSchoolAdminDialog({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.onAssigned,
  });

  final String schoolId;
  final String schoolName;
  final VoidCallback onAssigned;

  @override
  ConsumerState<AssignSchoolAdminDialog> createState() =>
      _AssignSchoolAdminDialogState();
}

class _AssignSchoolAdminDialogState extends ConsumerState<AssignSchoolAdminDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    return List.generate(12, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      AppSnackbar.warning(context, 'Admin name is required');
      return;
    }
    if (email.isEmpty) {
      AppSnackbar.warning(context, AppStrings.adminEmailIsRequired);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      AppSnackbar.warning(context, AppStrings.invalidEmailFormat);
      return;
    }
    if (mobile.length != 10) {
      AppSnackbar.warning(context, AppStrings.mobileMust10Digits);
      return;
    }
    if (password.length < 8) {
      AppSnackbar.warning(context, AppStrings.passwordMin8);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(superAdminServiceProvider).assignSchoolAdmin(
            widget.schoolId,
            {
              'admin_name': name,
              'admin_email': email,
              'admin_mobile': mobile,
              'temp_password': password,
            },
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onAssigned();
        AppSnackbar.success(context, AppStrings.adminAssignedSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text(AppStrings.assignSchoolAdmin),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assign a primary admin for ${widget.schoolName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.adminNameRequired,
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: AppStrings.adminEmailRequired,
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Admin Mobile * (10 digits)',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: AppStrings.tempPasswordRequired,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () =>
                          setState(() => _passwordController.text = _generatePassword()),
                      tooltip: 'Generate password',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.assignAdmin),
        ),
      ],
    );
  }
}
