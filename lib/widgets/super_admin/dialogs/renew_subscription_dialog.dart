// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/renew_subscription_dialog.dart
// PURPOSE: Renew school subscription
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design_system/design_system.dart';
import '../../../design_system/tokens/app_spacing.dart';

class RenewSubscriptionDialog extends StatefulWidget {
  const RenewSubscriptionDialog({
    super.key,
    required this.schoolName,
    required this.planName,
    required this.currentEndDate,
    required this.monthlyAmount,
    required this.onRenew,
  });

  final String schoolName;
  final String planName;
  final DateTime? currentEndDate;
  final double monthlyAmount;
  final Future<void> Function(int durationMonths, String? paymentRef) onRenew;

  @override
  State<RenewSubscriptionDialog> createState() => _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends State<RenewSubscriptionDialog> {
  int _durationMonths = 12;
  final _paymentRefController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _paymentRefController.dispose();
    super.dispose();
  }

  DateTime get _newEndDate {
    final start = widget.currentEndDate?.isAfter(DateTime.now()) == true
        ? widget.currentEndDate!
        : DateTime.now();
    return DateTime(start.year, start.month + _durationMonths, start.day);
  }

  double get _totalAmount => widget.monthlyAmount * _durationMonths;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onRenew(_durationMonths, _paymentRefController.text.trim().isEmpty ? null : _paymentRefController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, 'Subscription renewed');
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
          Text('Renew Subscription', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.vGapSm,
          Text(widget.schoolName, style: Theme.of(context).textTheme.bodyLarge),
          Text('${widget.planName} • ₹${widget.monthlyAmount.toStringAsFixed(0)}/mo', style: Theme.of(context).textTheme.bodySmall),
          AppSpacing.vGapXl,
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3 mo')),
              ButtonSegment(value: 6, label: Text('6 mo')),
              ButtonSegment(value: 12, label: Text('12 mo')),
            ],
            selected: {_durationMonths},
            onSelectionChanged: (s) => setState(() => _durationMonths = s.first),
          ),
          AppSpacing.vGapLg,
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total: ₹${_totalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('New end date: ${DateFormat.yMMMd().format(_newEndDate)}'),
                ],
              ),
            ),
          ),
          TextField(
            controller: _paymentRefController,
            decoration: const InputDecoration(labelText: 'Payment reference (optional)'),
          ),
          AppSpacing.vGapXl,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
              AppSpacing.hGapSm,
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Renew'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
