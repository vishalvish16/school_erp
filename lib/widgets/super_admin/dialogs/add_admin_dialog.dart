// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/add_admin_dialog.dart
// PURPOSE: Add or edit super admin user
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../models/super_admin/super_admin_user_model.dart';

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
  late String _role;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _role = e?.role ?? 'tech_admin';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final body = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
      };
      if (widget._isEdit && widget.existing != null && widget.onUpdate != null) {
        await widget.onUpdate!(widget.existing!.id, body);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin updated')),
          );
        }
      } else if (widget.onAdd != null) {
        await widget.onAdd!(body);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin invited')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email *'),
            keyboardType: TextInputType.emailAddress,
            readOnly: widget._isEdit,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'owner', child: Text('Owner')),
              DropdownMenuItem(value: 'tech_admin', child: Text('Tech Admin')),
              DropdownMenuItem(value: 'support', child: Text('Support')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'tech_admin'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
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
