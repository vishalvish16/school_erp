// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/create_group_dialog.dart
// PURPOSE: Create school group with slug (human-friendly, required for login)
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({
    super.key,
    required this.onCreate,
  });

  final Future<void> Function(Map<String, dynamic>) onCreate;

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _slugAvailable = false;
  bool _slugChecking = false;
  String? _slugError;
  Timer? _slugDebounce;

  static String _slugFromName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .substring(0, name.length.clamp(0, 50));
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_suggestSlug);
    _slugController.addListener(_checkSlugDebounced);
  }

  void _suggestSlug() {
    if (_slugController.text.isEmpty && _nameController.text.isNotEmpty) {
      final suggested = _slugFromName(_nameController.text);
      if (suggested.isNotEmpty) {
        _slugController.text = suggested;
        _checkSlugDebounced();
      }
    }
  }

  void _checkSlugDebounced() {
    _slugDebounce?.cancel();
    _slugDebounce = Timer(const Duration(milliseconds: 500), _checkSlug);
  }

  Future<void> _checkSlug() async {
    final value = _slugController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (value.isEmpty) {
      setState(() {
        _slugAvailable = false;
        _slugChecking = false;
        _slugError = null;
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
    setState(() {
      _slugChecking = true;
      _slugError = null;
    });
    try {
      final available = await ref.read(superAdminServiceProvider).checkGroupSlugAvailable(value);
      if (mounted) {
        setState(() {
          _slugAvailable = available;
          _slugChecking = false;
          _slugError = available ? null : 'Already taken';
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
    _nameController.removeListener(_suggestSlug);
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
      await widget.onCreate({
        'name': _nameController.text.trim(),
        'slug': slug,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, 'Group created');
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Group',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppSpacing.vGapSm,
              Text(
                'Slug is used for login (e.g. {slug}.vidyron.in). Choose something easy to remember.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. Delhi Public School',
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
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
