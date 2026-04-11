// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_apply_leave_screen.dart
// PURPOSE: Staff portal — apply for a new leave request.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

const Color _accent = AppColors.secondary400;

const List<String> _leaveTypes = [
  'CASUAL',
  'SICK',
  'EARNED',
  'MATERNITY',
  'PATERNITY',
  'UNPAID',
  'COMPENSATORY',
];

String _leaveTypeLabel(String t) {
  switch (t) {
    case 'CASUAL': return 'Casual Leave';
    case 'SICK': return 'Sick Leave';
    case 'EARNED': return 'Earned Leave';
    case 'MATERNITY': return 'Maternity Leave';
    case 'PATERNITY': return 'Paternity Leave';
    case 'UNPAID': return 'Unpaid Leave';
    case 'COMPENSATORY': return 'Compensatory Leave';
    default: return t;
  }
}

class StaffApplyLeaveScreen extends ConsumerStatefulWidget {
  const StaffApplyLeaveScreen({super.key});

  @override
  ConsumerState<StaffApplyLeaveScreen> createState() =>
      _StaffApplyLeaveScreenState();
}

class _StaffApplyLeaveScreenState
    extends ConsumerState<StaffApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String _leaveType = 'CASUAL';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _submitting = false;
  Map<String, dynamic> _summary = {};
  bool _loadingSummary = false;

  int get _totalDays {
    if (_fromDate == null || _toDate == null) return 0;
    if (_toDate!.isBefore(_fromDate!)) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final result = await ref
          .read(schoolAdminServiceProvider)
          .getMyNonTeachingLeaveSummary();
      if (mounted) setState(() => _summary = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final first = isFrom ? DateTime.now() : (_fromDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromDate == null || _toDate == null) {
      AppSnackbar.warning(context, 'Please select from and to dates');
      return;
    }
    if (_totalDays < 1) {
      AppSnackbar.warning(context, 'To date must be on or after from date');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(schoolAdminServiceProvider).applyMyLeave({
        'leave_type': _leaveType,
        'from_date': _fromDate!.toIso8601String().split('T').first,
        'to_date': _toDate!.toIso8601String().split('T').first,
        'reason': _reasonCtrl.text.trim(),
      });
      if (mounted) {
        AppSnackbar.success(context, AppStrings.leaveApplicationSubmitted);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff/my-leaves'),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(AppStrings.applyForLeave),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave balance summary
                  if (_loadingSummary)
                    const LinearProgressIndicator()
                  else if (_summary.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Leave Balance',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            AppSpacing.vGapSm,
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final e in _summary.entries)
                                  if (e.value is Map)
                                    _BalanceChip(
                                      type: _leaveTypeLabel(e.key),
                                      remaining: (e.value as Map)[
                                              'remaining'] ??
                                          0,
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Leave type
                  DropdownButtonFormField<String>(
                    initialValue: _leaveType,
                    decoration: const InputDecoration(
                      labelText: AppStrings.leaveTypeRequired,
                      border: OutlineInputBorder(),
                    ),
                    items: _leaveTypes
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_leaveTypeLabel(t))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _leaveType = v!),
                  ),
                  AppSpacing.vGapLg,

                  // Date pickers
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'From Date *',
                          value: _fromDate,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: _DatePickerField(
                          label: 'To Date *',
                          value: _toDate,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,

                  // Total days display
                  if (_fromDate != null && _toDate != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: _accent),
                          const SizedBox(width: 6),
                          Text(
                            '$_totalDays day${_totalDays != 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  AppSpacing.vGapLg,

                  // Reason
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: AppStrings.reasonRequired,
                      hintText:
                          'Please describe the reason for your leave...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Please provide a reason (min 5 characters)';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.vGapXl,

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14)),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text(AppStrings.submitApplication,
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon:
              const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
              : 'Select',
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.type, required this.remaining});
  final String type;
  final dynamic remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        '$type: $remaining',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
