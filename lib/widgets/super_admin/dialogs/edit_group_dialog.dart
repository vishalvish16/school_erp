// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/edit_group_dialog.dart
// PURPOSE: Edit school group — name and slug (human-friendly for login)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

class EditGroupDialog extends ConsumerStatefulWidget {
  const EditGroupDialog({
    super.key,
    required this.groupId,
    required this.initialName,
    this.initialSlug,
    required this.onSave,
  });

  final String groupId;
  final String initialName;
  final String? initialSlug;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  ConsumerState<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends ConsumerState<EditGroupDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _slugAvailable = false;
  bool _slugChecking = false;
  String? _slugError;
  Timer? _slugDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _slugController = TextEditingController(text: widget.initialSlug ?? '');
    if (widget.initialSlug != null && widget.initialSlug!.trim().isNotEmpty) {
      _slugAvailable = true;
    }
    _slugController.addListener(_checkSlugDebounced);
  }

  void _checkSlugDebounced() {
    _slugDebounce?.cancel();
    _slugDebounce = Timer(const Duration(milliseconds: 500), _checkSlug);
  }

  Future<void> _checkSlug() async {
    final value = _slugController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    final initialNormalized = (widget.initialSlug ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (value.isEmpty) {
      setState(() {
        _slugAvailable = false;
        _slugChecking = false;
        _slugError = 'Slug is required';
      });
      return;
    }
    if (value.length < 2) {
      setState(() {
        _slugAvailable = false;
        _slugChecking = false;
        _slugError = 'Slug must be at least 2 characters';
      });
      return;
    }
    const reserved = ['admin', 'api', 'www', 'app', 'docs', 'help', 'support', 'billing', 'status'];
    if (reserved.contains(value)) {
      setState(() {
        _slugAvailable = false;
        _slugChecking = false;
        _slugError = 'This slug is reserved';
      });
      return;
    }
    if (value == initialNormalized && initialNormalized.isNotEmpty) {
      setState(() {
        _slugAvailable = true;
        _slugChecking = false;
        _slugError = null;
      });
      return;
    }
    setState(() {
      _slugChecking = true;
      _slugError = null;
    });
    try {
      final available = await ref.read(superAdminServiceProvider).checkGroupSlugAvailable(
            value,
            excludeId: widget.groupId,
          );
      if (mounted) {
        setState(() {
          _slugAvailable = available;
          _slugChecking = false;
          _slugError = available ? null : 'Already taken by another group';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _slugAvailable = false;
          _slugChecking = false;
          _slugError = 'Could not check';
        });
      }
    }
  }

  @override
  void dispose() {
    _slugDebounce?.cancel();
    _slugController.removeListener(_checkSlugDebounced);
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final slug = _slugController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (!_slugAvailable || slug.isEmpty) {
      setState(() => _slugError = _slugError ?? 'Choose an available slug');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'slug': slug,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, 'Group updated');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingXl,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Group Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.vGapSm,
            Text(
              'Slug is used for login (e.g. {slug}.vidyron.in). Only available slugs can be saved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapXl,
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            AppSpacing.vGapLg,
            TextFormField(
              controller: _slugController,
              decoration: InputDecoration(
                labelText: 'Slug',
                hintText: 'e.g. dpsgroup',
                border: const OutlineInputBorder(),
                helperText: 'Lowercase letters, numbers, hyphens only',
                errorText: _slugError,
                suffixIcon: _slugChecking
                    ? const Padding(
                        padding: AppSpacing.paddingMd,
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_slugController.text.trim().isNotEmpty && !_slugChecking)
                        ? Icon(
                            _slugAvailable ? Icons.check_circle : Icons.cancel,
                            color: _slugAvailable ? AppColors.success500 : Theme.of(context).colorScheme.error,
                            size: 24,
                          )
                        : null,
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              validator: (v) {
                final s = (v ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
                if (s.isEmpty) return 'Slug is required';
                if (s.length < 2) return 'At least 2 characters';
                if (_slugError != null) return _slugError;
                return null;
              },
            ),
            AppSpacing.vGapXl,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                AppSpacing.hGapSm,
                FilledButton(
                  onPressed: (_submitting || !_slugAvailable) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
