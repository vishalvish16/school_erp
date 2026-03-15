// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_staff_form_screen.dart
// PURPOSE: Create / Edit form for Non-Teaching Staff.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/school_admin/non_teaching_staff_model.dart';
import '../providers/school_admin_non_teaching_staff_provider.dart';
import '../providers/school_admin_non_teaching_roles_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

const List<String> _genders = ['MALE', 'FEMALE', 'OTHER'];
const List<String> _employeeTypes = [
  'PERMANENT',
  'CONTRACT',
  'PART_TIME',
  'DAILY_WAGE',
];
const List<String> _bloodGroups = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
];

class SchoolAdminNonTeachingStaffFormScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingStaffFormScreen({super.key, this.staffId});

  final String? staffId;

  @override
  ConsumerState<SchoolAdminNonTeachingStaffFormScreen> createState() =>
      _SchoolAdminNonTeachingStaffFormScreenState();
}

class _SchoolAdminNonTeachingStaffFormScreenState
    extends ConsumerState<SchoolAdminNonTeachingStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final _firstNameCtrl = TextEditingController();
  late final _lastNameCtrl = TextEditingController();
  late final _empNoCtrl = TextEditingController();
  late final _emailCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _deptCtrl = TextEditingController();
  late final _designationCtrl = TextEditingController();
  late final _qualCtrl = TextEditingController();
  late final _salaryGradeCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();
  late final _cityCtrl = TextEditingController();
  late final _stateCtrl = TextEditingController();
  late final _emergencyNameCtrl = TextEditingController();
  late final _emergencyPhoneCtrl = TextEditingController();

  // State
  String _gender = 'MALE';
  String _employeeType = 'PERMANENT';
  String? _bloodGroup;
  DateTime? _dateOfBirth;
  DateTime? _joinDate;
  String? _selectedRoleId;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoadingDetail = false;
  bool _isSuggestingEmpNo = false;

  bool get _isEdit => widget.staffId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load roles
      ref.read(nonTeachingRolesProvider.notifier).loadRoles();
      if (_isEdit) {
        await _loadExistingData();
      } else {
        _suggestEmployeeNo();
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _empNoCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _designationCtrl.dispose();
    _qualCtrl.dispose();
    _salaryGradeCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoadingDetail = true);
    try {
      final svc = ref.read(schoolAdminServiceProvider);
      final staff = await svc.getNonTeachingStaffById(widget.staffId!);
      _populateForm(staff);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to load staff: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  void _populateForm(NonTeachingStaffModel staff) {
    _firstNameCtrl.text = staff.firstName;
    _lastNameCtrl.text = staff.lastName;
    _empNoCtrl.text = staff.employeeNo;
    _emailCtrl.text = staff.email;
    _phoneCtrl.text = staff.phone ?? '';
    _deptCtrl.text = staff.department ?? '';
    _designationCtrl.text = staff.designation ?? '';
    _qualCtrl.text = staff.qualification ?? '';
    _salaryGradeCtrl.text = staff.salaryGrade ?? '';
    _addressCtrl.text = staff.address ?? '';
    _cityCtrl.text = staff.city ?? '';
    _stateCtrl.text = staff.state ?? '';
    _emergencyNameCtrl.text = staff.emergencyContactName ?? '';
    _emergencyPhoneCtrl.text = staff.emergencyContactPhone ?? '';
    setState(() {
      _gender = staff.gender.isNotEmpty ? staff.gender : 'MALE';
      _employeeType = staff.employeeType;
      _bloodGroup = staff.bloodGroup;
      _dateOfBirth = staff.dateOfBirth;
      _joinDate = staff.joinDate;
      _selectedRoleId = staff.role?.id;
      _isActive = staff.isActive;
    });
  }

  Future<void> _suggestEmployeeNo() async {
    setState(() => _isSuggestingEmpNo = true);
    try {
      final svc = ref.read(schoolAdminServiceProvider);
      final suggested = await svc.suggestNonTeachingEmployeeNo();
      if (mounted && suggested.isNotEmpty) {
        _empNoCtrl.text = suggested;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSuggestingEmpNo = false);
    }
  }

  Future<void> _pickDate(bool isDob) async {
    final initial = isDob
        ? (_dateOfBirth ?? DateTime(1990))
        : (_joinDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isDob ? DateTime(1940) : DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDob) {
          _dateOfBirth = picked;
        } else {
          _joinDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRoleId == null) {
      AppSnackbar.warning(context, 'Please select a role');
      return;
    }
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      'role_id': _selectedRoleId,
      'employee_no': _empNoCtrl.text.trim(),
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'gender': _gender,
      'email': _emailCtrl.text.trim(),
      'employee_type': _employeeType,
      'is_active': _isActive,
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_deptCtrl.text.trim().isNotEmpty) 'department': _deptCtrl.text.trim(),
      if (_designationCtrl.text.trim().isNotEmpty)
        'designation': _designationCtrl.text.trim(),
      if (_qualCtrl.text.trim().isNotEmpty) 'qualification': _qualCtrl.text.trim(),
      if (_salaryGradeCtrl.text.trim().isNotEmpty)
        'salary_grade': _salaryGradeCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
      if (_stateCtrl.text.trim().isNotEmpty) 'state': _stateCtrl.text.trim(),
      if (_bloodGroup != null) 'blood_group': _bloodGroup,
      if (_dateOfBirth != null)
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
      if (_joinDate != null)
        'join_date': _joinDate!.toIso8601String().split('T').first,
      if (_emergencyNameCtrl.text.trim().isNotEmpty)
        'emergency_contact_name': _emergencyNameCtrl.text.trim(),
      if (_emergencyPhoneCtrl.text.trim().isNotEmpty)
        'emergency_contact_phone': _emergencyPhoneCtrl.text.trim(),
    };

    bool ok;
    if (_isEdit) {
      ok = await ref
          .read(nonTeachingStaffProvider.notifier)
          .updateStaff(widget.staffId!, data);
    } else {
      ok = await ref
          .read(nonTeachingStaffProvider.notifier)
          .createStaff(data);
    }

    if (mounted) setState(() => _isSaving = false);

    if (ok && mounted) {
      AppSnackbar.success(context, _isEdit ? 'Staff updated' : 'Staff member added');
      context.go('/school-admin/non-teaching-staff');
    } else if (mounted) {
      final err = ref.read(nonTeachingStaffProvider).errorMessage;
      AppSnackbar.error(context, err ?? 'An error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesState = ref.watch(nonTeachingRolesProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(_isEdit ? 'Edit Staff' : 'Add Non-Teaching Staff'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/school-admin/non-teaching-staff'),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: AppSpacing.paddingLg,
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Update' : 'Save',
                  style: const TextStyle(color: _accent)),
            ),
        ],
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          'Role',
                          [
                            DropdownButtonFormField<String>(
                              value: _selectedRoleId,
                              decoration: const InputDecoration(
                                labelText: 'Role *',
                                border: OutlineInputBorder(),
                              ),
                              items: rolesState.roles
                                  .where((r) => r.isActive)
                                  .map((r) => DropdownMenuItem(
                                        value: r.id,
                                        child: Row(
                                          children: [
                                            Icon(r.categoryIcon,
                                                size: 16,
                                                color: r.categoryColor),
                                            AppSpacing.hGapSm,
                                            Text(r.displayName),
                                            AppSpacing.hGapSm,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: r.categoryColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    AppRadius.brXs,
                                              ),
                                              child: Text(
                                                r.categoryLabel,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: r.categoryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedRoleId = v),
                              validator: (v) =>
                                  v == null ? 'Please select a role' : null,
                            ),
                          ],
                        ),
                        AppSpacing.vGapLg,

                        _sectionCard(
                          'Personal Information',
                          [
                            _twoCol(
                              isWide,
                              _textField('First Name *', _firstNameCtrl,
                                  required: true),
                              _textField('Last Name *', _lastNameCtrl,
                                  required: true),
                            ),
                            AppSpacing.vGapMd,
                            DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                  labelText: 'Gender *',
                                  border: OutlineInputBorder()),
                              items: _genders
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _gender = v!),
                            ),
                            AppSpacing.vGapMd,
                            _twoCol(
                              isWide,
                              _datePicker(
                                  'Date of Birth',
                                  _dateOfBirth,
                                  () => _pickDate(true)),
                              DropdownButtonFormField<String?>(
                                value: _bloodGroup,
                                decoration: const InputDecoration(
                                    labelText: 'Blood Group',
                                    border: OutlineInputBorder()),
                                items: [
                                  const DropdownMenuItem<String?>(
                                      value: null, child: Text('Select')),
                                  ..._bloodGroups.map((b) =>
                                      DropdownMenuItem(
                                          value: b, child: Text(b))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _bloodGroup = v),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vGapLg,

                        _sectionCard(
                          'Contact Information',
                          [
                            _textField('Email *', _emailCtrl,
                                required: true,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            }),
                            AppSpacing.vGapMd,
                            _textField('Phone', _phoneCtrl,
                                keyboardType: TextInputType.phone),
                            AppSpacing.vGapMd,
                            _textField('Address', _addressCtrl,
                                maxLines: 2),
                            AppSpacing.vGapMd,
                            _twoCol(
                              isWide,
                              _textField('City', _cityCtrl),
                              _textField('State', _stateCtrl),
                            ),
                          ],
                        ),
                        AppSpacing.vGapLg,

                        _sectionCard(
                          'Employment Details',
                          [
                            _empNoField(),
                            AppSpacing.vGapMd,
                            _twoCol(
                              isWide,
                              _textField('Department', _deptCtrl),
                              _textField('Designation', _designationCtrl),
                            ),
                            AppSpacing.vGapMd,
                            _twoCol(
                              isWide,
                              _datePicker('Join Date', _joinDate,
                                  () => _pickDate(false)),
                              DropdownButtonFormField<String>(
                                value: _employeeType,
                                decoration: const InputDecoration(
                                    labelText: 'Employee Type *',
                                    border: OutlineInputBorder()),
                                items: _employeeTypes
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(_empTypeLabel(t))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _employeeType = v!),
                              ),
                            ),
                            AppSpacing.vGapMd,
                            _twoCol(
                              isWide,
                              _textField('Qualification', _qualCtrl),
                              _textField('Salary Grade', _salaryGradeCtrl),
                            ),
                            AppSpacing.vGapMd,
                            SwitchListTile(
                              title: const Text('Active'),
                              subtitle:
                                  const Text('Staff can access the system'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        AppSpacing.vGapLg,

                        _sectionCard(
                          'Emergency Contact',
                          [
                            _twoCol(
                              isWide,
                              _textField(
                                  'Contact Name', _emergencyNameCtrl),
                              _textField('Contact Phone', _emergencyPhoneCtrl,
                                  keyboardType: TextInputType.phone),
                            ),
                          ],
                        ),
                        AppSpacing.vGapXl,

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _submit,
                            style: FilledButton.styleFrom(
                                backgroundColor: _accent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Text(_isEdit ? 'Update Staff' : 'Add Staff',
                                    style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        AppSpacing.vGapXl,
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            AppSpacing.vGapMd,
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _twoCol(bool isWide, Widget left, Widget right) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: left),
          AppSpacing.hGapMd,
          Expanded(child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        AppSpacing.vGapMd,
        right,
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }

  Widget _empNoField() {
    return TextFormField(
      controller: _empNoCtrl,
      decoration: InputDecoration(
        labelText: 'Employee No. *',
        hintText: 'Auto-suggested; editable',
        border: const OutlineInputBorder(),
        suffixIcon: _isSuggestingEmpNo
            ? const Padding(
                padding: AppSpacing.paddingMd,
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Suggest employee number',
                onPressed: _suggestEmployeeNo,
              ),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : 'Select date',
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _empTypeLabel(String t) {
    switch (t) {
      case 'PERMANENT':
        return 'Permanent';
      case 'CONTRACT':
        return 'Contract';
      case 'PART_TIME':
        return 'Part-Time';
      case 'DAILY_WAGE':
        return 'Daily Wage';
      default:
        return t;
    }
  }
}
