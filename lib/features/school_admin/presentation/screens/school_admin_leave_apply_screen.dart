// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_leave_apply_screen.dart
// PURPOSE: Apply a leave request for a specific staff member.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class SchoolAdminLeaveApplyScreen extends ConsumerStatefulWidget {
  const SchoolAdminLeaveApplyScreen({super.key, required this.staffId});

  final String staffId;

  @override
  ConsumerState<SchoolAdminLeaveApplyScreen> createState() =>
      _SchoolAdminLeaveApplyScreenState();
}

class _SchoolAdminLeaveApplyScreenState
    extends ConsumerState<SchoolAdminLeaveApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String _leaveType = 'CASUAL';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _submitting = false;

  static const _leaveTypes = [
    'CASUAL',
    'SICK',
    'EARNED',
    'MATERNITY',
    'PATERNITY',
    'UNPAID',
    'OTHER',
  ];

  int get _totalDays {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/school-admin/staff/${widget.staffId}'),
        ),
        title: Text(AppStrings.applyLeave,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    color: _accent.withValues(alpha: 0.05),
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: _accent, size: 18),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              'Submitting leave request on behalf of staff member.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Leave Type
                  DropdownButtonFormField<String>(
                    initialValue: _leaveType,
                    decoration: const InputDecoration(
                      labelText: AppStrings.leaveTypeRequired,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _leaveTypes
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _leaveType = v!),
                  ),
                  AppSpacing.vGapLg,

                  // From Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _fromDate = picked;
                          // Reset toDate if it's before fromDate
                          if (_toDate != null &&
                              _toDate!.isBefore(picked)) {
                            _toDate = picked;
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppStrings.fromDateRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        errorText: _fromDate == null &&
                                _formKey.currentState != null
                            ? 'Required'
                            : null,
                      ),
                      child: Text(
                        _fromDate != null
                            ? _fmtDate(_fromDate!)
                            : 'Select start date',
                        style: TextStyle(
                          color: _fromDate != null
                              ? null
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // To Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _toDate ?? _fromDate ?? DateTime.now(),
                        firstDate: _fromDate ?? DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _toDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppStrings.toDateRequired,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        errorText: _toDate == null &&
                                _formKey.currentState != null
                            ? 'Required'
                            : null,
                      ),
                      child: Text(
                        _toDate != null
                            ? _fmtDate(_toDate!)
                            : 'Select end date',
                        style: TextStyle(
                          color: _toDate != null
                              ? null
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // Total Days display
                  if (_fromDate != null && _toDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.08),
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available,
                              color: _accent, size: 18),
                          AppSpacing.hGapSm,
                          Text(
                            'Total: $_totalDays day${_totalDays == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _accent,
                            ),
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
                          'Provide a reason (minimum 10 characters)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.edit_note),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Reason is required';
                      }
                      if (v.trim().length < 10) {
                        return 'Reason must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.vGapXl,

                  // Submit button
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Submit Leave Request'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_submitting)
            ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.3),
              child: AppLoaderScreen(),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Validate form fields
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _fromDate == null || _toDate == null) {
      if (_fromDate == null || _toDate == null) {
        AppToast.showWarning(context, AppStrings.pleaseSelectDates);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(schoolAdminServiceProvider).applyLeave(
        widget.staffId,
        {
          'leaveType': _leaveType,
          'fromDate': _fromDate!.toIso8601String().split('T').first,
          'toDate': _toDate!.toIso8601String().split('T').first,
          'reason': _reasonCtrl.text.trim(),
        },
      );
      if (mounted) {
        AppToast.showSuccess(context, AppStrings.leaveSubmitted);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
