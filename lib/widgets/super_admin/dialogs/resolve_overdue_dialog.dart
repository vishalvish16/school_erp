// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/resolve_overdue_dialog.dart
// PURPOSE: Resolve overdue school billing
// =============================================================================

import 'package:flutter/material.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Overdue resolved')),
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
          Text('Resolve Overdue', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.schoolName, style: Theme.of(context).textTheme.bodyLarge),
          Text('${widget.overdueDays} days overdue', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
          const SizedBox(height: 24),
          RadioListTile<String>(
            title: const Text('Mark as Paid'),
            subtitle: const Text('Payment received, extend subscription'),
            value: 'paid',
            groupValue: _action,
            onChanged: (v) => setState(() => _action = v!),
          ),
          RadioListTile<String>(
            title: const Text('Grace Period'),
            subtitle: const Text('Give 7 days extension'),
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
            const SizedBox(height: 16),
            TextField(
              controller: _paymentRefController,
              decoration: const InputDecoration(labelText: 'Payment reference'),
            ),
          ],
          if (_action == 'terminate') ...[
            const SizedBox(height: 16),
            Text(
              'Type the school name exactly to confirm:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _terminateConfirmController,
              decoration: InputDecoration(
                labelText: 'School name',
                hintText: widget.schoolName,
                errorText: _terminateConfirmController.text.isNotEmpty &&
                        _terminateConfirmController.text.trim() != widget.schoolName
                    ? 'Must match exactly'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : (_action == 'terminate' && !_canConfirmTerminate)
                        ? null
                        : _submit,
                style: _action == 'terminate'
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm Resolution'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
