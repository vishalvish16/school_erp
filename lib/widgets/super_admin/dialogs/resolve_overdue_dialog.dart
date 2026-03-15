// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/resolve_overdue_dialog.dart
// PURPOSE: Resolve overdue school billing
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

class ResolveOverdueDialog extends StatefulWidget {
  const ResolveOverdueDialog({
    super.key,
    required this.schoolName,
    required this.overdueDays,
    required this.onResolve,
  });

  final String schoolName;
  final int overdueDays;
  final Future<void> Function(String action, String? paymentRef) onResolve;

  @override
  State<ResolveOverdueDialog> createState() => _ResolveOverdueDialogState();
}

class _ResolveOverdueDialogState extends State<ResolveOverdueDialog> {
  String _action = 'paid';
  final _paymentRefController = TextEditingController();
  final _terminateConfirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _paymentRefController.dispose();
    _terminateConfirmController.dispose();
    super.dispose();
  }

  bool get _canConfirmTerminate =>
      _terminateConfirmController.text.trim() == widget.schoolName;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onResolve(_action, _paymentRefController.text.trim().isEmpty ? null : _paymentRefController.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(context, AppStrings.overdueResolved);
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
          Text(AppStrings.resolveOverdue, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.vGapSm,
          Text(widget.schoolName, style: Theme.of(context).textTheme.bodyLarge),
          Text('${widget.overdueDays} days overdue', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error500)),
          AppSpacing.vGapXl,
          RadioListTile<String>(
            title: const Text(AppStrings.markAsPaid),
            subtitle: const Text(AppStrings.markAsPaidSubtitle),
            value: 'paid',
            groupValue: _action,
            onChanged: (v) => setState(() => _action = v!),
          ),
          RadioListTile<String>(
            title: const Text(AppStrings.gracePeriod),
            subtitle: const Text(AppStrings.gracePeriodSubtitle),
            value: 'grace_period',
            groupValue: _action,
            onChanged: (v) => setState(() => _action = v!),
          ),
          RadioListTile<String>(
            title: const Text('Terminate'),
            subtitle: const Text('Deactivate school'),
            value: 'terminate',
            groupValue: _action,
            onChanged: (v) => setState(() => _action = v!),
          ),
          if (_action == 'paid') ...[
            AppSpacing.vGapLg,
            TextField(
              controller: _paymentRefController,
              decoration: const InputDecoration(labelText: AppStrings.paymentReference),
            ),
          ],
          if (_action == 'terminate') ...[
            AppSpacing.vGapLg,
            Text(
              'Type the school name exactly to confirm:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.vGapSm,
            TextField(
              controller: _terminateConfirmController,
              decoration: InputDecoration(
                labelText: AppStrings.schoolName,
                hintText: widget.schoolName,
                errorText: _terminateConfirmController.text.isNotEmpty &&
                        _terminateConfirmController.text.trim() != widget.schoolName
                    ? 'Must match exactly'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          AppSpacing.vGapXl,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
              AppSpacing.hGapSm,
              FilledButton(
                onPressed: _submitting
                    ? null
                    : (_action == 'terminate' && !_canConfirmTerminate)
                        ? null
                        : _submit,
                style: _action == 'terminate'
                    ? FilledButton.styleFrom(backgroundColor: AppColors.error500)
                    : null,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(AppStrings.confirmResolution),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
