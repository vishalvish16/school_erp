// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/assign_plan_dialog.dart
// PURPOSE: Assign plan to school
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../design_system/tokens/app_spacing.dart';

class AssignPlanDialog extends StatefulWidget {
  const AssignPlanDialog({
    super.key,
    required this.schoolName,
    required this.currentPlanName,
    this.currentPlanId,
    required this.plans,
    required this.onAssign,
  });

  final String schoolName;
  final String? currentPlanName;
  /// School's current plan ID (may be 'BASIC'/'STANDARD'/'PREMIUM' from enum).
  /// Used to pre-select the matching plan in the list (by id or name).
  final String? currentPlanId;
  final List<Map<String, dynamic>> plans;
  final Future<void> Function(String planId, DateTime? effectiveDate, String? reason) onAssign;

  @override
  State<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends State<AssignPlanDialog> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = _resolveSelectedPlanId();
  }

  /// Pre-select the school's current plan by matching id or name.
  String? _resolveSelectedPlanId() {
    final currentId = widget.currentPlanId;
    final currentName = widget.currentPlanName?.toLowerCase();
    if (currentId == null && currentName == null) return null;
    for (final p in widget.plans) {
      final id = p['id']?.toString() ?? '';
      final name = (p['name'] ?? '').toString().toLowerCase();
      if (currentId != null && id == currentId) return id;
      if (currentName != null && name == currentName) return id;
    }
    return currentId;
  }
  DateTime _effectiveDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPlanId == null) {
      AppSnackbar.warning(context, AppStrings.selectPlanPrompt);
      return;
    }
    try {
      await widget.onAssign(_selectedPlanId!, _effectiveDate, _reasonController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, AppStrings.planAssigned);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
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
          Text('Assign Plan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.vGapSm,
          Text(widget.schoolName, style: Theme.of(context).textTheme.bodyLarge),
          if (widget.currentPlanName != null)
            Text('Current: ${widget.currentPlanName}', style: Theme.of(context).textTheme.bodySmall),
          AppSpacing.vGapXl,
          ...widget.plans.map((p) {
            final id = p['id']?.toString() ?? '';
            final name = p['name'] ?? '';
            final price = (p['price_per_student'] ?? p['priceMonthly'] ?? 0) is num
                ? (p['price_per_student'] ?? p['priceMonthly'] ?? 0).toDouble()
                : 0.0;
            final selected = _selectedPlanId == id;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: selected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
              child: InkWell(
                onTap: () => setState(() => _selectedPlanId = id),
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      AppSpacing.hGapMd,
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${price.toStringAsFixed(0)}/mo'),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            );
          }),
          AppSpacing.vGapLg,
          ListTile(
            title: const Text(AppStrings.effectiveDate),
            subtitle: Text(DateFormat.yMMMd().format(_effectiveDate)),
            trailing: TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _effectiveDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _effectiveDate = d);
              },
              child: const Text(AppStrings.change),
            ),
          ),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            maxLines: 2,
          ),
          AppSpacing.vGapXl,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              AppSpacing.hGapSm,
              FilledButton(onPressed: _submit, child: const Text(AppStrings.assignPlan)),
            ],
          ),
        ],
      ),
    );
  }
}
