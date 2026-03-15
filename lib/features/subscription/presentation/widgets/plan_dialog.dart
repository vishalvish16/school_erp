// =============================================================================
// FILE: lib/features/subscription/presentation/widgets/plan_dialog.dart
// PURPOSE: Reusable Dialog for Adding and Editing Platform Plans
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../data/models/plan_model.dart';
import '../../provider/plan_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
      AppSnackbar.success(context,
            widget.plan != null
                ? 'Plan updated successfully'
                : 'Plan created successfully');
    } else {
      AppSnackbar.error(context, provider.error ?? 'Failed to save plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(planProvider).isLoading;

    return AlertDialog(
      title: Text(
        widget.plan != null ? 'Edit Subscription Plan' : 'Create New Plan',
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl2),
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
                AppSpacing.vGapLg,
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
                    AppSpacing.hGapLg,
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
                AppSpacing.vGapLg,
                _buildTextField(
                  controller: _branchesController,
                  label: 'Max Branches',
                  icon: Icons.account_tree_outlined,
                  isNumber: true,
                ),
                AppSpacing.vGapXl,
                const Divider(),
                AppSpacing.vGapLg,
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
                    AppSpacing.hGapLg,
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
                AppSpacing.vGapLg,
                SwitchListTile(
                  title: const Text('Is Active'),
                  subtitle: const Text(
                    'Inactive plans are hidden from new subscriptions',
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeThumbColor: Colors.indigo,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl2, vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.brLg,
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
        border: OutlineInputBorder(borderRadius: AppRadius.brLg),
        filled: true,
        fillColor: AppColors.neutral50,
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
