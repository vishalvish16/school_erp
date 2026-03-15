import 'package:flutter/material.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../subscription/provider/plan_provider.dart';
import '../viewmodels/school_detail_viewmodel.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class AssignPlanDialog extends ConsumerStatefulWidget {
  final String schoolId;
  final int? currentPlanId;
  final String? currentPlanName;

  const AssignPlanDialog({
    super.key,
    required this.schoolId,
    this.currentPlanId,
    this.currentPlanName,
  });

  @override
  ConsumerState<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends ConsumerState<AssignPlanDialog> {
  int? _selectedPlanId;
  String _billingCycle = 'MONTHLY';
  final TextEditingController _durationController = TextEditingController();
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(planProvider).fetchPlans());
  }

  int? _resolveSelectedPlanId(List<dynamic> plans) {
    final currentId = widget.currentPlanId;
    final currentName = widget.currentPlanName?.toLowerCase();
    if (currentId == null && (currentName == null || currentName.isEmpty)) return null;
    for (final p in plans) {
      final planId = p.planId is int ? p.planId : int.tryParse(p.planId.toString());
      final planName = (p.planName ?? '').toString().toLowerCase();
      if (currentId != null && planId == currentId) return planId;
      if (currentName != null && planName == currentName) return planId;
    }
    return currentId;
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

    if (!_initialized && planState.plans.isNotEmpty && (widget.currentPlanId != null || (widget.currentPlanName?.isNotEmpty ?? false))) {
      _initialized = true;
      final resolved = _resolveSelectedPlanId(planState.plans);
      if (resolved != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedPlanId = resolved);
        });
      }
    }

    return AlertDialog(
      title: const Text(AppStrings.assignSubscriptionPlan),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.choosePlan,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSm,
            SearchableDropdownFormField<int>.valueItems(
              value: _selectedPlanId,
              valueItems: planState.plans.map((plan) => MapEntry(
                plan.planId,
                '${plan.planName} (₹${plan.priceMonthly.toStringAsFixed(0)}/mo)',
              )).toList(),
              hintText: AppStrings.selectPlan,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (val) => setState(() => _selectedPlanId = val),
            ),
            AppSpacing.vGapXl,
            const Text(
              AppStrings.billingCycle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(AppStrings.monthlyBilling),
                    value: 'MONTHLY',
                    groupValue: _billingCycle,
                    onChanged: (val) => setState(() => _billingCycle = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(AppStrings.yearlyBilling),
                    value: 'YEARLY',
                    groupValue: _billingCycle,
                    onChanged: (val) => setState(() => _billingCycle = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,
            const Text(
              AppStrings.customDuration,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapSm,
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: AppStrings.enterMonthsHint,
                suffixText: AppStrings.months,
                border: OutlineInputBorder(),
              ),
            ),
            if (planState.error != null) ...[
              AppSpacing.vGapLg,
              Text(
                planState.error!,
                style: const TextStyle(color: AppColors.error500, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
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
              : const Text(AppStrings.assign),
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
        AppSnackbar.success(context, AppStrings.planAssignedSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppStrings.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
