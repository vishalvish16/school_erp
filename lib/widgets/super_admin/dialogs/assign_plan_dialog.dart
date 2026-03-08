// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/assign_plan_dialog.dart
// PURPOSE: Assign plan to school
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignPlanDialog extends StatefulWidget {
  const AssignPlanDialog({
    super.key,
    required this.schoolName,
    required this.currentPlanName,
    required this.plans,
    required this.onAssign,
  });

  final String schoolName;
  final String? currentPlanName;
  final List<Map<String, dynamic>> plans;
  final Future<void> Function(String planId, DateTime? effectiveDate, String? reason) onAssign;

  @override
  State<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends State<AssignPlanDialog> {
  String? _selectedPlanId;
  DateTime _effectiveDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }
    try {
      await widget.onAssign(_selectedPlanId!, _effectiveDate, _reasonController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan assigned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
          Text('Assign Plan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.schoolName, style: Theme.of(context).textTheme.bodyLarge),
          if (widget.currentPlanName != null)
            Text('Current: ${widget.currentPlanName}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Effective date'),
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
              child: const Text('Change'),
            ),
          ),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Assign Plan')),
            ],
          ),
        ],
      ),
    );
  }
}
