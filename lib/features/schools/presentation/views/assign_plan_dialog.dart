import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../subscription/provider/plan_provider.dart';
import '../viewmodels/school_detail_viewmodel.dart';

class AssignPlanDialog extends ConsumerStatefulWidget {
  final String schoolId;

  const AssignPlanDialog({super.key, required this.schoolId});

  @override
  ConsumerState<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends ConsumerState<AssignPlanDialog> {
  int? _selectedPlanId;
  String _billingCycle = 'MONTHLY';
  final TextEditingController _durationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch plans if not already loaded
    Future.microtask(() => ref.read(planProvider).fetchPlans());
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Assign Subscription Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedPlanId,
              hint: const Text('Select Plan'),
              isExpanded: true,
              items: planState.plans.map((plan) {
                return DropdownMenuItem(
                  value: plan.planId,
                  child: Text(
                    '${plan.planName} (₹${plan.priceMonthly.toStringAsFixed(0)}/mo)',
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPlanId = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text(
              'Billing Cycle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Monthly'),
                    value: 'MONTHLY',
                    groupValue: _billingCycle,
                    onChanged: (val) => setState(() => _billingCycle = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Yearly'),
                    value: 'YEARLY',
                    groupValue: _billingCycle,
                    onChanged: (val) => setState(() => _billingCycle = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Custom Duration (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter months (e.g. 6)',
                suffixText: 'Months',
                border: OutlineInputBorder(),
              ),
            ),
            if (planState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                planState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedPlanId == null
              ? null
              : _handleAssign,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _handleAssign() async {
    setState(() => _isSubmitting = true);
    try {
      final duration = int.tryParse(_durationController.text);

      await ref
          .read(schoolDetailViewModelProvider(widget.schoolId).notifier)
          .assignPlan(
            planId: _selectedPlanId!.toString(),
            billingCycle: _billingCycle,
            durationMonths: duration,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
