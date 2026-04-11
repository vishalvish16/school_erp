// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_fee_collection_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/school_admin_fees_provider.dart';
import '../providers/school_admin_students_provider.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/constants/app_strings.dart';

const Color _accent = AppColors.success500;

class SchoolAdminFeeCollectionScreen extends ConsumerStatefulWidget {
  const SchoolAdminFeeCollectionScreen({super.key});

  @override
  ConsumerState<SchoolAdminFeeCollectionScreen> createState() =>
      _SchoolAdminFeeCollectionScreenState();
}

class _SchoolAdminFeeCollectionScreenState
    extends ConsumerState<SchoolAdminFeeCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feeHeadCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: AppStrings.academicYearDefault);
  final _remarksCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String? _selectedStudentId;
  String? _selectedStudentName;
  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;
  bool _showStudentSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminStudentsProvider.notifier).loadStudents();
    });
  }

  @override
  void dispose() {
    _feeHeadCtrl.dispose();
    _amountCtrl.dispose();
    _receiptCtrl.dispose();
    _yearCtrl.dispose();
    _remarksCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(schoolAdminStudentsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/school-admin/fees'),
        ),
        title: Text(AppStrings.collectFee),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student selector
                  Text(
                    AppStrings.selectStudent,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.vGapSm,
                  if (_selectedStudentId == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchStudentHint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: AppRadius.brMd),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            ref
                                .read(schoolAdminStudentsProvider.notifier)
                                .setSearch(v);
                            setState(() => _showStudentSearch = v.isNotEmpty);
                          },
                        ),
                        if (_showStudentSearch && studentsState.students.isNotEmpty)
                          Card(
                            margin: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: studentsState.students.length
                                    .clamp(0, 6),
                                itemBuilder: (ctx, i) {
                                  final s = studentsState.students[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(s.fullName),
                                    subtitle: Text(s.admissionNo),
                                    onTap: () {
                                      setState(() {
                                        _selectedStudentId = s.id;
                                        _selectedStudentName =
                                            '${s.fullName} (${s.admissionNo})';
                                        _showStudentSearch = false;
                                        _searchCtrl.clear();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: AppRadius.brMd,
                        border: Border.all(
                            color: _accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: _accent, size: 20),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              _selectedStudentName ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _selectedStudentId = null;
                              _selectedStudentName = null;
                            }),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  AppSpacing.vGapLg,

                  // Fee Head
                  TextFormField(
                    controller: _feeHeadCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.feeHead,
                      hintText: AppStrings.feeHeadFieldHint,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  AppSpacing.vGapMd,

                  // Amount
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.amountLabel,
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.vGapMd,

                  // Academic Year
                  TextFormField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.academicYear,
                      hintText: AppStrings.academicYearDefault,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  AppSpacing.vGapMd,

                  // Receipt No
                  TextFormField(
                    controller: _receiptCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.receiptNo,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  AppSpacing.vGapMd,

                  // Payment Mode
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: AppStrings.paymentMode,
                      border: OutlineInputBorder(),
                    ),
                    items: ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE']
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMode = v!),
                  ),
                  AppSpacing.vGapMd,

                  // Payment Date
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _paymentDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        'Payment Date: ${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}'),
                  ),
                  AppSpacing.vGapMd,

                  // Remarks
                  TextFormField(
                    controller: _remarksCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.remarksOptional,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  AppSpacing.vGapXl,

                  FilledButton.icon(
                    onPressed:
                        _isSaving || _selectedStudentId == null
                            ? null
                            : _submit,
                    icon: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary),
                          )
                        : const Icon(Icons.payment),
                    label: Text(
                        _isSaving ? 'Processing...' : 'Collect Payment'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedStudentId == null) {
      AppToast.showWarning(context, AppStrings.pleaseSelectStudent);
      return;
    }
    setState(() => _isSaving = true);
    final data = {
      'studentId': _selectedStudentId,
      'feeHead': _feeHeadCtrl.text.trim(),
      'amount': double.parse(_amountCtrl.text.trim()),
      'academicYear': _yearCtrl.text.trim(),
      'receiptNo': _receiptCtrl.text.trim(),
      'paymentMode': _paymentMode,
      'paymentDate':
          '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
      if (_remarksCtrl.text.isNotEmpty) 'remarks': _remarksCtrl.text.trim(),
    };
    final ok =
        await ref.read(schoolAdminFeesProvider.notifier).collectFee(data);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        AppToast.showSuccess(context, AppStrings.paymentRecordedSuccess);
        _formKey.currentState?.reset();
        _feeHeadCtrl.clear();
        _amountCtrl.clear();
        _receiptCtrl.clear();
        _remarksCtrl.clear();
        setState(() {
          _selectedStudentId = null;
          _selectedStudentName = null;
          _paymentMode = 'CASH';
          _paymentDate = DateTime.now();
        });
      }
    }
  }
}
