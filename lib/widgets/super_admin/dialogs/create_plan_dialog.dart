// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/create_plan_dialog.dart
// PURPOSE: Create or edit plan
// =============================================================================

import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../common/searchable_dropdown_form_field.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../design_system/tokens/app_spacing.dart';

class CreateEditPlanDialog extends StatefulWidget {
  const CreateEditPlanDialog({
    super.key,
    this.plan,
    required this.onSave,
  });

  final SuperAdminPlanModel? plan;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<CreateEditPlanDialog> createState() => _CreateEditPlanDialogState();
}

class _CreateEditPlanDialogState extends State<CreateEditPlanDialog> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _emojiController = TextEditingController();
  String _status = 'active';
  String _supportLevel = 'standard';
  final Map<String, bool> _features = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    if (p != null) {
      _nameController.text = p.name;
      _slugController.text = p.slug;
      _priceController.text = p.pricePerStudent.toStringAsFixed(0);
      _descController.text = p.description ?? '';
      _maxStudentsController.text = p.maxStudents?.toString() ?? '';
      _emojiController.text = p.iconEmoji ?? '📦';
      _status = p.status ?? 'active';
      _supportLevel = p.supportLevel ?? 'standard';
      _features.addAll(p.features);
    } else {
      _emojiController.text = '📦';
    }
    _nameController.addListener(_syncSlug);
  }

  void _syncSlug() {
    if (widget.plan != null) return;
    final slug = _nameController.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (_slugController.text.isEmpty || _slugController.text == _slugFromName(_slugController.text)) {
      _slugController.text = slug;
    }
  }

  String _slugFromName(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  @override
  void dispose() {
    _nameController.removeListener(_syncSlug);
    _nameController.dispose();
    _slugController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxStudentsController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool asDraft = false}) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text);
    if (name.isEmpty) {
      AppSnackbar.warning(context, 'Name is required');
      return;
    }
    if (price == null || price < 0) {
      AppSnackbar.warning(context, 'Valid price is required');
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSave({
        'name': name,
        'slug': _slugController.text.trim().isEmpty ? _slugFromName(name) : _slugController.text.trim(),
        'price_per_student': price,
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'max_students': _maxStudentsController.text.trim().isEmpty ? null : int.tryParse(_maxStudentsController.text),
        'support_level': _supportLevel,
        'status': asDraft ? 'draft' : _status,
        'icon_emoji': _emojiController.text.trim().isEmpty ? '📦' : _emojiController.text.trim(),
        'features': _features,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, widget.plan == null ? 'Plan created' : 'Plan updated');
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
    final price = double.tryParse(_priceController.text) ?? 0;
    final exampleTotal = price * 500;

    return SingleChildScrollView(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.plan == null ? 'Create Plan' : 'Edit Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.vGapXl,
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plan Name'),
            ),
            AppSpacing.vGapMd,
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            AppSpacing.vGapMd,
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per student (₹)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            AppSpacing.vGapMd,
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            AppSpacing.vGapMd,
            TextFormField(
              controller: _maxStudentsController,
              decoration: const InputDecoration(labelText: 'Max students (optional)'),
              keyboardType: TextInputType.number,
            ),
            AppSpacing.vGapMd,
            SearchableDropdownFormField<String>.valueItems(
              value: _supportLevel,
              valueItems: const [
                MapEntry('standard', 'STANDARD'),
                MapEntry('priority', 'PRIORITY'),
                MapEntry('dedicated', 'DEDICATED'),
              ],
              decoration: const InputDecoration(labelText: 'Support Level'),
              onChanged: (v) => setState(() => _supportLevel = v ?? 'standard'),
            ),
            AppSpacing.vGapMd,
            SearchableDropdownFormField<String>.valueItems(
              value: _status,
              valueItems: const [
                MapEntry('active', 'ACTIVE'),
                MapEntry('draft', 'DRAFT'),
                MapEntry('inactive', 'INACTIVE'),
              ],
              decoration: const InputDecoration(labelText: 'Status'),
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            AppSpacing.vGapMd,
            TextFormField(
              controller: _emojiController,
              decoration: const InputDecoration(labelText: 'Icon emoji'),
            ),
            AppSpacing.vGapLg,
            Text(
              'Example: 500 students × ₹${price.toStringAsFixed(0)} = ₹${exampleTotal.toStringAsFixed(0)}/month',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            AppSpacing.vGapXl,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.plan == null)
                  TextButton(
                    onPressed: _submitting ? null : () => _submit(asDraft: true),
                    child: const Text('Save as Draft'),
                  ),
                AppSpacing.hGapSm,
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                AppSpacing.hGapSm,
                FilledButton(
                  onPressed: _submitting ? null : () => _submit(),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.plan == null ? 'Create Plan' : 'Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
