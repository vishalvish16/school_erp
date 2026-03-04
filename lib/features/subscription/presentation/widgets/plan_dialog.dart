// =============================================================================
// FILE: lib/features/subscription/presentation/widgets/plan_dialog.dart
// PURPOSE: Reusable Dialog for Adding and Editing Platform Plans
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/plan_model.dart';
import '../../provider/plan_provider.dart';

class PlanDialog extends ConsumerStatefulWidget {
  final PlanModel? plan;

  const PlanDialog({super.key, this.plan});

  @override
  ConsumerState<PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends ConsumerState<PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _studentsController;
  late TextEditingController _teachersController;
  late TextEditingController _branchesController;
  late TextEditingController _monthlyController;
  late TextEditingController _yearlyController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController = TextEditingController(text: p?.planName ?? '');
    _studentsController = TextEditingController(
      text: p?.maxStudents.toString() ?? '',
    );
    _teachersController = TextEditingController(
      text: p?.maxTeachers.toString() ?? '',
    );
    _branchesController = TextEditingController(
      text: p?.maxBranches.toString() ?? '1',
    );
    _monthlyController = TextEditingController(
      text: p?.priceMonthly.toStringAsFixed(0) ?? '',
    );
    _yearlyController = TextEditingController(
      text: p?.priceYearly.toStringAsFixed(0) ?? '',
    );
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _branchesController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'maxStudents': int.parse(_studentsController.text),
      'maxTeachers': int.parse(_teachersController.text),
      'maxBranches': int.parse(_branchesController.text),
      'priceMonthly': double.parse(_monthlyController.text),
      'priceYearly': double.parse(_yearlyController.text),
      'isActive': _isActive,
    };

    final provider = ref.read(planProvider);
    bool success;

    if (widget.plan != null) {
      success = await provider.updatePlan(widget.plan!.planId, data);
    } else {
      success = await provider.createPlan(data);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.plan != null
                ? 'Plan updated successfully'
                : 'Plan created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Error message is already in provider.error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(planProvider).isLoading;

    return AlertDialog(
      title: Text(
        widget.plan != null ? 'Edit Subscription Plan' : 'Create New Plan',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Plan Name',
                  hint: 'e.g. Professional, Enterprise',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _studentsController,
                        label: 'Max Students',
                        icon: Icons.people_outline,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _teachersController,
                        label: 'Max Teachers',
                        icon: Icons.school_outlined,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _branchesController,
                  label: 'Max Branches',
                  icon: Icons.account_tree_outlined,
                  isNumber: true,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _monthlyController,
                        label: 'Price Monthly (₹)',
                        icon: Icons.calendar_month_outlined,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _yearlyController,
                        label: 'Price Yearly (₹)',
                        icon: Icons.event_repeat_outlined,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active'),
                  subtitle: const Text(
                    'Inactive plans are hidden from new subscriptions',
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: Colors.indigo,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.plan != null ? 'Update Plan' : 'Create Plan'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Field is required';
        if (isNumber && int.tryParse(val) == null) return 'Invalid number';
        if (isNumber && double.parse(val) <= 0 && label.contains('Price')) {
          return 'Price must be greater than 0';
        }
        return null;
      },
    );
  }
}
