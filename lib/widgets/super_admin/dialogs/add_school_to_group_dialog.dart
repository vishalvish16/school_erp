// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/add_school_to_group_dialog.dart
// PURPOSE: Add school to group
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../models/super_admin/super_admin_models.dart';

class AddSchoolToGroupDialog extends StatefulWidget {
  const AddSchoolToGroupDialog({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.availableSchools,
    required this.onAdd,
  });

  final String groupId;
  final String groupName;
  final List<SuperAdminSchoolModel> availableSchools;
  final Future<void> Function(String schoolId) onAdd;

  @override
  State<AddSchoolToGroupDialog> createState() => _AddSchoolToGroupDialogState();
}

class _AddSchoolToGroupDialogState extends State<AddSchoolToGroupDialog> {
  String? _selectedSchoolId;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a school')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onAdd(_selectedSchoolId!);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School added to group')),
        );
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
            'Add School to ${widget.groupName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          if (widget.availableSchools.isEmpty)
            const Text('No standalone schools available to add.')
          else
            ...widget.availableSchools.map((s) => RadioListTile<String>(
                  title: Text(s.name),
                  subtitle: Text('${s.city ?? ''} • ${s.code}'),
                  value: s.id,
                  groupValue: _selectedSchoolId,
                  onChanged: (v) => setState(() => _selectedSchoolId = v),
                )),
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
                onPressed: _submitting || widget.availableSchools.isEmpty ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
