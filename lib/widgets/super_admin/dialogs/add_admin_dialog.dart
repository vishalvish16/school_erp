// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/add_admin_dialog.dart
// PURPOSE: Add or edit super admin user
// =============================================================================

import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../common/searchable_dropdown_form_field.dart';
import '../../../../models/super_admin/super_admin_user_model.dart';
import '../../../design_system/tokens/app_spacing.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({
    super.key,
    this.onAdd,
    this.onUpdate,
    this.existing,
  }) : assert(onAdd != null || (onUpdate != null && existing != null),
         'Provide onAdd for add, or onUpdate+existing for edit');

  final Future<void> Function(Map<String, dynamic>)? onAdd;
  final Future<void> Function(String id, Map<String, dynamic>)? onUpdate;
  final SuperAdminUserModel? existing;

  bool get _isEdit => existing != null;

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _tempPasswordController;
  late String _role;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _mobileController = TextEditingController(text: e?.mobile ?? '');
    _tempPasswordController = TextEditingController(text: 'Password@123');
    _role = e?.role ?? 'tech_admin';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      AppSnackbar.warning(context, 'Name and email are required');
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
      };
      if (!widget._isEdit) {
        final mobile = _mobileController.text.trim();
        if (mobile.isNotEmpty) body['mobile'] = mobile;
        final tempPw = _tempPasswordController.text.trim();
        if (tempPw.isNotEmpty) body['temp_password'] = tempPw;
      }
      if (widget._isEdit && widget.existing != null && widget.onUpdate != null) {
        await widget.onUpdate!(widget.existing!.id, body);
        if (mounted) {
          Navigator.of(context).pop(true);
          AppSnackbar.success(context, 'Admin updated');
        }
      } else if (widget.onAdd != null) {
        await widget.onAdd!(body);
        if (mounted) {
          Navigator.of(context).pop(true);
          AppSnackbar.success(context, 'Admin invited');
        }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget._isEdit ? 'Edit Admin' : 'Add Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.vGapXl,
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
          ),
          AppSpacing.vGapMd,
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email *'),
            keyboardType: TextInputType.emailAddress,
            readOnly: widget._isEdit,
          ),
          if (!widget._isEdit) ...[
            AppSpacing.vGapMd,
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile', hintText: 'e.g. +91 98765 43210'),
              keyboardType: TextInputType.phone,
            ),
            AppSpacing.vGapMd,
            TextField(
              controller: _tempPasswordController,
              decoration: const InputDecoration(
                labelText: 'Temp Password',
                hintText: 'Optional — user will set password on first login',
              ),
              obscureText: true,
            ),
          ],
          AppSpacing.vGapMd,
          SearchableDropdownFormField<String>.valueItems(
            value: _role,
            valueItems: const [
              MapEntry('owner', 'Owner'),
              MapEntry('tech_admin', 'Tech Admin'),
              MapEntry('ops_admin', 'Ops Admin'),
              MapEntry('support', 'Support'),
            ],
            decoration: const InputDecoration(labelText: 'Role'),
            onChanged: (v) => setState(() => _role = v ?? 'tech_admin'),
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
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget._isEdit ? 'Update' : 'Invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
