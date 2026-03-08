// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/register_hardware_dialog.dart
// PURPOSE: Register hardware device
// =============================================================================

import 'package:flutter/material.dart';

class RegisterHardwareDialog extends StatefulWidget {
  const RegisterHardwareDialog({
    super.key,
    required this.onRegister,
  });

  final Future<void> Function(Map<String, dynamic>) onRegister;

  @override
  State<RegisterHardwareDialog> createState() => _RegisterHardwareDialogState();
}

class _RegisterHardwareDialogState extends State<RegisterHardwareDialog> {
  final _deviceIdController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _locationController = TextEditingController();
  String? _schoolId;
  bool _submitting = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceTypeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device ID is required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onRegister({
        'device_id': _deviceIdController.text.trim(),
        'device_type': _deviceTypeController.text.trim().isEmpty ? 'rfid' : _deviceTypeController.text.trim(),
        'location_label': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'school_id': _schoolId,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device registered')),
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
            'Register Device',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _deviceIdController,
            decoration: const InputDecoration(labelText: 'Device ID *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceTypeController,
            decoration: const InputDecoration(
              labelText: 'Device Type',
              hintText: 'rfid, gps, tablet, etc.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
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
                    : const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
