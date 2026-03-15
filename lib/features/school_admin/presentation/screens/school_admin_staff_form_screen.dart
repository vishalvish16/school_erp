// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_staff_form_screen.dart
// PURPOSE: 4-tab create/edit form for staff — Personal, Employment, Contact, Login.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/school_admin/staff_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

// Simple provider to load staff for edit mode
final _editStaffProvider =
    FutureProvider.autoDispose.family<StaffModel?, String?>((ref, id) async {
  if (id == null || id.isEmpty) return null;
  return ref.read(schoolAdminServiceProvider).getStaffById(id);
});

class SchoolAdminStaffFormScreen extends ConsumerWidget {
  const SchoolAdminStaffFormScreen({super.key, this.staffId});

  /// null = create mode, non-null = edit mode
  final String? staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (staffId == null) {
      return _StaffForm(staffId: null, existing: null);
    }
    final async = ref.watch(_editStaffProvider(staffId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Staff')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Staff')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapMd,
              Text(_StaffFormState._extractUserMessage(err)),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref.invalidate(_editStaffProvider(staffId)),
                style: FilledButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (staff) => _StaffForm(staffId: staffId, existing: staff),
    );
  }
}

// ── The actual tabbed form ────────────────────────────────────────────────────

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({required this.staffId, required this.existing});
  final String? staffId;
  final StaffModel? existing;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Tab form keys
  final _k1 = GlobalKey<FormState>();
  final _k2 = GlobalKey<FormState>();
  final _k3 = GlobalKey<FormState>();
  final _k4 = GlobalKey<FormState>();

  // ── Tab 1: Personal
  late final _firstNameCtrl =
      TextEditingController(text: widget.existing?.firstName ?? '');
  late final _lastNameCtrl =
      TextEditingController(text: widget.existing?.lastName ?? '');
  late String _gender = widget.existing?.gender ?? 'MALE';
  DateTime? _dateOfBirth;
  late String? _bloodGroup = widget.existing?.bloodGroup;

  // ── Tab 2: Employment
  late final _empNoCtrl =
      TextEditingController(text: widget.existing?.employeeNo ?? '');
  late final _designationCtrl =
      TextEditingController(text: widget.existing?.designation ?? '');
  late final _departmentCtrl =
      TextEditingController(text: widget.existing?.department ?? '');
  late String _employeeType = widget.existing?.employeeType ?? 'PERMANENT';
  DateTime? _joinDate;
  late final _salaryGradeCtrl =
      TextEditingController(text: widget.existing?.salaryGrade ?? '');
  late final _experienceCtrl = TextEditingController(
      text: widget.existing?.experienceYears?.toString() ?? '');

  // ── Tab 3: Contact
  late final _phoneCtrl =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.existing?.email ?? '');
  late final _addressCtrl =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _cityCtrl =
      TextEditingController(text: widget.existing?.city ?? '');
  late final _stateCtrl =
      TextEditingController(text: widget.existing?.state ?? '');
  late final _emergencyNameCtrl =
      TextEditingController(text: widget.existing?.emergencyContactName ?? '');
  late final _emergencyPhoneCtrl = TextEditingController(
      text: widget.existing?.emergencyContactPhone ?? '');

  // ── Tab 4: Login (staff logs in with email from Contact tab)
  final _passwordCtrl = TextEditingController();
  String _role = 'TEACHER';
  bool _obscurePassword = true;

  bool _submitting = false;

  bool get _isEdit => widget.staffId != null;

  static const _genders = ['MALE', 'FEMALE', 'OTHER'];
  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];
  static const _employeeTypes = [
    'PERMANENT',
    'CONTRACT',
    'PART_TIME',
    'VISITING',
  ];
  static const _roles = ['TEACHER', 'STAFF'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _dateOfBirth = widget.existing?.dateOfBirth;
    _joinDate = widget.existing?.joinDate;
  }

  @override
  void dispose() {
    _tab.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _empNoCtrl.dispose();
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    _salaryGradeCtrl.dispose();
    _experienceCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(_isEdit ? 'Edit Staff' : 'Add Staff',
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tab,
              labelColor: _accent,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: _accent,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Employment'),
                Tab(text: 'Contact'),
                Tab(text: 'Login'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _PersonalTab(
                formKey: _k1,
                firstNameCtrl: _firstNameCtrl,
                lastNameCtrl: _lastNameCtrl,
                gender: _gender,
                onGenderChanged: (v) => setState(() => _gender = v),
                dateOfBirth: _dateOfBirth,
                onDateOfBirthChanged: (v) =>
                    setState(() => _dateOfBirth = v),
                bloodGroup: _bloodGroup,
                onBloodGroupChanged: (v) =>
                    setState(() => _bloodGroup = v),
                bloodGroups: _bloodGroups,
                genders: _genders,
              ),
              _EmploymentTab(
                formKey: _k2,
                empNoCtrl: _empNoCtrl,
                designationCtrl: _designationCtrl,
                departmentCtrl: _departmentCtrl,
                employeeType: _employeeType,
                onEmployeeTypeChanged: (v) =>
                    setState(() => _employeeType = v),
                joinDate: _joinDate,
                onJoinDateChanged: (v) => setState(() => _joinDate = v),
                salaryGradeCtrl: _salaryGradeCtrl,
                experienceCtrl: _experienceCtrl,
                employeeTypes: _employeeTypes,
              ),
              _ContactTab(
                formKey: _k3,
                phoneCtrl: _phoneCtrl,
                emailCtrl: _emailCtrl,
                addressCtrl: _addressCtrl,
                cityCtrl: _cityCtrl,
                stateCtrl: _stateCtrl,
                emergencyNameCtrl: _emergencyNameCtrl,
                emergencyPhoneCtrl: _emergencyPhoneCtrl,
              ),
              _LoginTab(
                formKey: _k4,
                emailForLogin: _emailCtrl.text.trim(),
                passwordCtrl: _passwordCtrl,
                role: _role,
                onRoleChanged: (v) => setState(() => _role = v),
                obscurePassword: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                isEdit: _isEdit,
                roles: _roles,
              ),
            ],
          ),
          bottomNavigationBar: _BottomActions(
            tab: _tab,
            isLastTab: _tab.index == 3,
            isFirstTab: _tab.index == 0,
            onNext: _advanceTab,
            onBack: _retreatTab,
            onSubmit: _submit,
            submitting: _submitting,
            isEdit: _isEdit,
          ),
        ),
        if (_submitting)
          const ColoredBox(
            color: AppColors.neutral300,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _advanceTab() async {
    final currentKey = [_k1, _k2, _k3, _k4][_tab.index];
    if (!(currentKey.currentState?.validate() ?? false)) {
      // Form validator shows inline errors for required fields
      return;
    }
    if (_isEdit) {
      setState(() => _submitting = true);
      try {
        final body = _buildBodyForTab(_tab.index);
        if (body.isNotEmpty) {
          await ref.read(schoolAdminServiceProvider).updateStaff(widget.staffId!, body);
        }
        if (_tab.index < 3 && mounted) {
          _tab.animateTo(_tab.index + 1);
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, _extractUserMessage(e));
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } else {
      if (_tab.index < 3) {
        _tab.animateTo(_tab.index + 1);
        setState(() {});
      }
    }
  }

  static String _tabName(int index) {
    const names = ['Personal', 'Employment', 'Contact', 'Login'];
    return names[index];
  }

  /// Build partial body for a single tab (edit mode only).
  Map<String, dynamic> _buildBodyForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'gender': _gender,
          if (_dateOfBirth != null)
            'dateOfBirth': _dateOfBirth!.toIso8601String().split('T').first,
          if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
        };
      case 1:
        return {
          'employeeNo': _empNoCtrl.text.trim(),
          'designation': _designationCtrl.text.trim(),
          if (_departmentCtrl.text.trim().isNotEmpty)
            'department': _departmentCtrl.text.trim(),
          'employeeType': _employeeType,
          if (_joinDate != null)
            'joinDate': _joinDate!.toIso8601String().split('T').first,
          if (_salaryGradeCtrl.text.trim().isNotEmpty)
            'salaryGrade': _salaryGradeCtrl.text.trim(),
          if (_experienceCtrl.text.trim().isNotEmpty)
            'experienceYears': int.tryParse(_experienceCtrl.text.trim()),
        };
      case 2:
        return {
          if (_phoneCtrl.text.trim().isNotEmpty)
            'phone': _phoneCtrl.text.trim(),
          if (_emailCtrl.text.trim().isNotEmpty)
            'email': _emailCtrl.text.trim(),
          if (_addressCtrl.text.trim().isNotEmpty)
            'address': _addressCtrl.text.trim(),
          if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
          if (_stateCtrl.text.trim().isNotEmpty)
            'state': _stateCtrl.text.trim(),
          if (_emergencyNameCtrl.text.trim().isNotEmpty)
            'emergencyContactName': _emergencyNameCtrl.text.trim(),
          if (_emergencyPhoneCtrl.text.trim().isNotEmpty)
            'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        };
      case 3:
        // Login tab: username/role/password are handled on final submit only
        // (backend uses createStaffLogin / resetStaffPassword, not updateStaff)
        return {};
      default:
        return {};
    }
  }

  void _retreatTab() {
    if (_tab.index > 0) {
      _tab.animateTo(_tab.index - 1);
      setState(() {});
    }
  }

  /// Validate tab data directly (TabBarView may dispose off-screen tabs, so
  /// Form.validate() can be null for non-visible tabs).
  bool _isTabValid(int tabIndex) {
    switch (tabIndex) {
      case 0: // Personal
        return _firstNameCtrl.text.trim().isNotEmpty &&
            _lastNameCtrl.text.trim().isNotEmpty;
      case 1: // Employment
        return _empNoCtrl.text.trim().isNotEmpty &&
            _designationCtrl.text.trim().isNotEmpty &&
            _joinDate != null;
      case 2: // Contact
        return _phoneCtrl.text.trim().length >= 10;
      case 3: // Login
        if (_isEdit) return _passwordCtrl.text.isEmpty || _passwordCtrl.text.length >= 8;
        return _passwordCtrl.text.isEmpty || _passwordCtrl.text.length >= 8;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    // Validate all tabs using data (not Form state — off-screen tabs may be disposed)
    int firstInvalid = -1;
    for (var i = 0; i < 4; i++) {
      if (!_isTabValid(i)) {
        firstInvalid = i;
        break;
      }
    }
    if (firstInvalid >= 0) {
      _tab.animateTo(firstInvalid);
      setState(() {});
      AppSnackbar.warning(context, 'Please complete the ${_tabName(firstInvalid)} tab');
      return;
    }

    setState(() => _submitting = true);
    try {
      final svc = ref.read(schoolAdminServiceProvider);
      final body = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender,
        if (_dateOfBirth != null)
          'dateOfBirth': _dateOfBirth!.toIso8601String().split('T').first,
        if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
        'employeeNo': _empNoCtrl.text.trim(),
        'designation': _designationCtrl.text.trim(),
        if (_departmentCtrl.text.trim().isNotEmpty)
          'department': _departmentCtrl.text.trim(),
        'employeeType': _employeeType,
        if (_joinDate != null)
          'joinDate': _joinDate!.toIso8601String().split('T').first,
        if (_salaryGradeCtrl.text.trim().isNotEmpty)
          'salaryGrade': _salaryGradeCtrl.text.trim(),
        if (_experienceCtrl.text.trim().isNotEmpty)
          'experienceYears':
              int.tryParse(_experienceCtrl.text.trim()),
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone': _phoneCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
        if (_stateCtrl.text.trim().isNotEmpty)
          'state': _stateCtrl.text.trim(),
        if (_emergencyNameCtrl.text.trim().isNotEmpty)
          'emergencyContactName': _emergencyNameCtrl.text.trim(),
        if (_emergencyPhoneCtrl.text.trim().isNotEmpty)
          'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
      };

      // Login tab — create: use createLogin + password (email required); edit: handled separately
      if (!_isEdit) {
        if (_passwordCtrl.text.trim().length >= 8) {
          if (body['email'] == null || (body['email'] as String).trim().isEmpty) {
            setState(() => _submitting = false);
            _tab.animateTo(2); // Contact tab
            setState(() {});
            AppSnackbar.warning(context, 'Email is required when creating login credentials');
            return;
          }
          body['createLogin'] = true;
          body['password'] = _passwordCtrl.text.trim();
        }
      }

      if (_isEdit) {
        await svc.updateStaff(widget.staffId!, body);
        // Handle login credentials: create new login or reset password
        final hasLogin = widget.existing?.userId != null &&
            (widget.existing!.userId ?? '').isNotEmpty;
        final newPassword = _passwordCtrl.text.trim();
        if (newPassword.length >= 8) {
          if (hasLogin) {
            await svc.resetStaffPassword(widget.staffId!, newPassword);
          } else {
            await svc.createStaffLogin(widget.staffId!, newPassword);
          }
        }
      } else {
        await svc.createStaff(body);
      }

      // Clear sensitive credentials from memory immediately after submission
      _passwordCtrl.clear();

      if (mounted) {
        AppSnackbar.success(context, _isEdit ? 'Staff updated successfully' : 'Staff added successfully');
        context.go('/school-admin/staff');
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractUserMessage(e);
        AppSnackbar.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Returns a safe, user-facing error message without leaking server internals.
  static String _extractUserMessage(Object e) {
    final raw = e.toString();
    // DioException wraps a server response — extract only the 'message' field if present
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (msgMatch != null) return msgMatch.group(1)!;
    // Strip Dart exception class prefixes
    final cleaned = raw
        .replaceAll('Exception: ', '')
        .replaceAll('DioException [bad response]: ', '');
    // Do not expose anything that looks like a file path or stack frame
    if (cleaned.contains('/') || cleaned.contains('\\') || cleaned.length > 200) {
      return 'An error occurred. Please try again.';
    }
    return cleaned;
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomActions extends StatefulWidget {
  const _BottomActions({
    required this.tab,
    required this.isLastTab,
    required this.isFirstTab,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
    required this.submitting,
    required this.isEdit,
  });

  final TabController tab;
  final bool isLastTab;
  final bool isFirstTab;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool submitting;
  final bool isEdit;

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions> {
  @override
  void initState() {
    super.initState();
    widget.tab.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.tab.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.tab.index == 3;
    final isFirst = widget.tab.index == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: widget.submitting ? null : widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
            ),
          const Spacer(),
          if (!isLast)
            FilledButton.icon(
              onPressed: widget.submitting ? null : widget.onNext,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
              style: FilledButton.styleFrom(backgroundColor: _accent),
            )
          else
            FilledButton.icon(
              onPressed: widget.submitting ? null : widget.onSubmit,
              icon: const Icon(Icons.check, size: 16),
              label: Text(widget.isEdit ? 'Update' : 'Save Staff'),
              style: FilledButton.styleFrom(backgroundColor: _accent),
            ),
        ],
      ),
    );
  }
}

// ── Tab 1: Personal ───────────────────────────────────────────────────────────

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.onDateOfBirthChanged,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
    required this.bloodGroups,
    required this.genders,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final String gender;
  final void Function(String) onGenderChanged;
  final DateTime? dateOfBirth;
  final void Function(DateTime?) onDateOfBirthChanged;
  final String? bloodGroup;
  final void Function(String?) onBloodGroupChanged;
  final List<String> bloodGroups;
  final List<String> genders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Basic Information'),
            AppSpacing.vGapMd,
            Row(
              children: [
                Expanded(
                  child: _FormField(
                      label: 'First Name',
                      ctrl: firstNameCtrl,
                      required: true),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: _FormField(
                      label: 'Last Name',
                      ctrl: lastNameCtrl,
                      required: true),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => onGenderChanged(v!),
            ),
            AppSpacing.vGapMd,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateOfBirth ?? DateTime(1990),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                onDateOfBirthChanged(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(
                  dateOfBirth != null
                      ? _fmtDate(dateOfBirth!)
                      : 'Select date',
                  style: TextStyle(
                    color: dateOfBirth != null
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            AppSpacing.vGapMd,
            DropdownButtonFormField<String?>(
              value: bloodGroup,
              decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Not specified')),
                ...bloodGroups.map(
                    (b) => DropdownMenuItem<String?>(
                        value: b, child: Text(b))),
              ],
              onChanged: onBloodGroupChanged,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Tab 2: Employment ─────────────────────────────────────────────────────────

class _EmploymentTab extends StatelessWidget {
  const _EmploymentTab({
    required this.formKey,
    required this.empNoCtrl,
    required this.designationCtrl,
    required this.departmentCtrl,
    required this.employeeType,
    required this.onEmployeeTypeChanged,
    required this.joinDate,
    required this.onJoinDateChanged,
    required this.salaryGradeCtrl,
    required this.experienceCtrl,
    required this.employeeTypes,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController empNoCtrl;
  final TextEditingController designationCtrl;
  final TextEditingController departmentCtrl;
  final String employeeType;
  final void Function(String) onEmployeeTypeChanged;
  final DateTime? joinDate;
  final void Function(DateTime?) onJoinDateChanged;
  final TextEditingController salaryGradeCtrl;
  final TextEditingController experienceCtrl;
  final List<String> employeeTypes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Employment Details'),
            AppSpacing.vGapMd,
            _FormField(label: 'Employee No.', ctrl: empNoCtrl, required: true),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Designation', ctrl: designationCtrl, required: true),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Department', ctrl: departmentCtrl, required: false),
            AppSpacing.vGapMd,
            DropdownButtonFormField<String>(
              value: employeeType,
              decoration: const InputDecoration(
                  labelText: 'Employee Type *',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: employeeTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => onEmployeeTypeChanged(v!),
            ),
            AppSpacing.vGapMd,
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: joinDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                onJoinDateChanged(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Join Date *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(
                  joinDate != null ? _fmtDate(joinDate!) : 'Select date',
                  style: TextStyle(
                    color: joinDate != null
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Salary Grade', ctrl: salaryGradeCtrl, required: false),
            AppSpacing.vGapMd,
            _FormField(
              label: 'Years of Experience',
              ctrl: experienceCtrl,
              required: false,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Tab 3: Contact ────────────────────────────────────────────────────────────

class _ContactTab extends StatelessWidget {
  const _ContactTab({
    required this.formKey,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Contact Information'),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Phone',
                ctrl: phoneCtrl,
                required: true,
                keyboardType: TextInputType.phone),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Email',
                ctrl: emailCtrl,
                required: false,
                keyboardType: TextInputType.emailAddress),
            AppSpacing.vGapMd,
            _FormField(label: 'Address', ctrl: addressCtrl, required: false),
            AppSpacing.vGapMd,
            Row(
              children: [
                Expanded(
                    child: _FormField(
                        label: 'City', ctrl: cityCtrl, required: false)),
                AppSpacing.hGapMd,
                Expanded(
                    child: _FormField(
                        label: 'State', ctrl: stateCtrl, required: false)),
              ],
            ),
            AppSpacing.vGapLg,
            _SectionLabel('Emergency Contact'),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Name', ctrl: emergencyNameCtrl, required: false),
            AppSpacing.vGapMd,
            _FormField(
                label: 'Phone',
                ctrl: emergencyPhoneCtrl,
                required: false,
                keyboardType: TextInputType.phone),
          ],
        ),
      ),
    );
  }
}

// ── Tab 4: Login ──────────────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.formKey,
    required this.emailForLogin,
    required this.passwordCtrl,
    required this.role,
    required this.onRoleChanged,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isEdit,
    required this.roles,
  });

  final GlobalKey<FormState> formKey;
  final String emailForLogin;
  final TextEditingController passwordCtrl;
  final String role;
  final void Function(String) onRoleChanged;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isEdit;
  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Portal Login Credentials'),
            AppSpacing.vGapXs,
            Text(
              isEdit
                  ? 'Leave password blank to keep existing credentials.'
                  : 'Staff logs in with their email (from Contact tab). Set password below, or leave blank to skip.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (emailForLogin.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Text(
                'Login email: $emailForLogin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            AppSpacing.vGapLg,
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: isEdit
                    ? 'New Password (leave blank to keep current)'
                    : 'Password',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            AppSpacing.vGapMd,
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => onRoleChanged(v!),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _accent,
          ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.ctrl,
    required this.required,
    this.keyboardType,
  });

  final String label;
  final TextEditingController ctrl;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
