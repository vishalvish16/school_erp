// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_staff_detail_screen.dart
// PURPOSE: Full 6-tab staff detail — Overview, Qualifications, Documents,
//          Subjects, Timetable, Leaves — for the School Admin portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/school_admin/staff_model.dart';
import '../../../../models/school_admin/staff_qualification_model.dart';
import '../../../../models/school_admin/staff_document_model.dart';
import '../../../../models/school_admin/staff_subject_assignment_model.dart';
import '../../../../models/school_admin/staff_timetable_model.dart';
import '../../../../models/school_admin/staff_leave_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

// ── Per-staff providers ───────────────────────────────────────────────────────

final _staffDetailProv =
    FutureProvider.autoDispose.family<StaffModel, String>((ref, id) {
  return ref.read(schoolAdminServiceProvider).getStaffById(id);
});

final _staffQualsProv =
    FutureProvider.autoDispose.family<List<StaffQualificationModel>, String>(
        (ref, id) {
  return ref.read(schoolAdminServiceProvider).getStaffQualifications(id);
});

final _staffDocsProv =
    FutureProvider.autoDispose.family<List<StaffDocumentModel>, String>(
        (ref, id) {
  return ref.read(schoolAdminServiceProvider).getStaffDocuments(id);
});

final _staffSubjectsProv =
    FutureProvider.autoDispose.family<List<StaffSubjectAssignmentModel>, String>(
        (ref, id) {
  return ref.read(schoolAdminServiceProvider).getSubjectAssignments(id);
});

final _staffTimetableProv =
    FutureProvider.autoDispose.family<StaffTimetableModel, String>((ref, id) {
  return ref.read(schoolAdminServiceProvider).getStaffTimetable(id);
});

final _staffLeavesProv =
    FutureProvider.autoDispose.family<List<StaffLeaveModel>, String>((ref, id) {
  return ref.read(schoolAdminServiceProvider).getStaffLeaves(id);
});

// ── Main screen ───────────────────────────────────────────────────────────────

class SchoolAdminStaffDetailScreen extends ConsumerStatefulWidget {
  const SchoolAdminStaffDetailScreen({super.key, required this.staffId});

  final String staffId;

  @override
  ConsumerState<SchoolAdminStaffDetailScreen> createState() =>
      _SchoolAdminStaffDetailScreenState();
}

class _SchoolAdminStaffDetailScreenState
    extends ConsumerState<SchoolAdminStaffDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Qualifications'),
    Tab(text: 'Documents'),
    Tab(text: 'Subjects'),
    Tab(text: 'Timetable'),
    Tab(text: 'Leaves'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncStaff = ref.watch(_staffDetailProv(widget.staffId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: asyncStaff.maybeWhen(
          data: (s) => Text(s.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          orElse: () => const Text('Staff Profile'),
        ),
        actions: [
          asyncStaff.maybeWhen(
            data: (s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => context
                      .go('/school-admin/staff/${widget.staffId}/edit'),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                AppSpacing.hGapXs,
                _StatusToggleButton(
                  staff: s,
                  onToggled: () =>
                      ref.invalidate(_staffDetailProv(widget.staffId)),
                ),
                AppSpacing.hGapSm,
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(_staffDetailProv(widget.staffId));
              ref.invalidate(_staffQualsProv(widget.staffId));
              ref.invalidate(_staffDocsProv(widget.staffId));
              ref.invalidate(_staffSubjectsProv(widget.staffId));
              ref.invalidate(_staffTimetableProv(widget.staffId));
              ref.invalidate(_staffLeavesProv(widget.staffId));
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: _accent,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: _accent,
          tabs: _tabs,
        ),
      ),
      body: asyncStaff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorRetry(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(_staffDetailProv(widget.staffId)),
        ),
        data: (staff) => TabBarView(
          controller: _tab,
          children: [
            _OverviewTab(staff: staff),
            _QualificationsTab(staffId: widget.staffId),
            _DocumentsTab(staffId: widget.staffId),
            _SubjectsTab(staffId: widget.staffId),
            _TimetableTab(staffId: widget.staffId),
            _LeavesTab(staffId: widget.staffId),
          ],
        ),
      ),
    );
  }
}

// ── Status toggle action ──────────────────────────────────────────────────────

class _StatusToggleButton extends ConsumerStatefulWidget {
  const _StatusToggleButton({required this.staff, required this.onToggled});
  final StaffModel staff;
  final VoidCallback onToggled;

  @override
  ConsumerState<_StatusToggleButton> createState() =>
      _StatusToggleButtonState();
}

class _StatusToggleButtonState extends ConsumerState<_StatusToggleButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(
        widget.staff.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
        size: 16,
      ),
      label: Text(widget.staff.isActive ? 'Deactivate' : 'Activate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.staff.isActive ? AppColors.warning500 : _accent,
        side: BorderSide(
            color: widget.staff.isActive ? AppColors.warning500 : _accent),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  Future<void> _toggle() async {
    String? reason;
    if (widget.staff.isActive) {
      final ctrl = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deactivate ${widget.staff.fullName}? They will lose portal access.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              AppSpacing.vGapMd,
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.warning500),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (reason == null) return; // cancelled
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .updateStaffStatus(widget.staff.id, !widget.staff.isActive,
              reason: reason);
      widget.onToggled();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Tab 1 — Overview ─────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.staff});
  final StaffModel staff;

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCard(staff: staff),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoGrid(context),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(staff: staff),
                  AppSpacing.vGapLg,
                  _infoGrid(context),
                ],
              ),
      ),
    );
  }

  Widget _infoGrid(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: 'Personal Information',
          icon: Icons.person,
          fields: {
            'Gender': staff.gender.isNotEmpty ? staff.gender : '-',
            'Date of Birth':
                staff.dateOfBirth != null ? _fmt(staff.dateOfBirth!) : '-',
            'Blood Group': staff.bloodGroup ?? '-',
            'Phone': staff.phone ?? '-',
            'Email': staff.email,
          },
        ),
        AppSpacing.vGapMd,
        _InfoCard(
          title: 'Employment Details',
          icon: Icons.work,
          fields: {
            'Employee No.': staff.employeeNo,
            'Designation': staff.designation,
            'Department': staff.department ?? '-',
            'Employee Type': staff.employeeType,
            'Join Date': _fmt(staff.joinDate),
            'Salary Grade': staff.salaryGrade ?? '-',
            'Experience': staff.experienceYears != null
                ? '${staff.experienceYears} years'
                : '-',
            'Status': staff.isActive ? 'Active' : 'Inactive',
          },
        ),
        AppSpacing.vGapMd,
        _InfoCard(
          title: 'Contact & Location',
          icon: Icons.location_on,
          fields: {
            'Address': staff.address ?? '-',
            'City': staff.city ?? '-',
            'State': staff.state ?? '-',
          },
        ),
        AppSpacing.vGapMd,
        _InfoCard(
          title: 'Emergency Contact',
          icon: Icons.emergency,
          fields: {
            'Name': staff.emergencyContactName ?? '-',
            'Phone': staff.emergencyContactPhone ?? '-',
          },
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.staff});
  final StaffModel staff;

  @override
  Widget build(BuildContext context) {
    final initials = staff.firstName.isNotEmpty && staff.lastName.isNotEmpty
        ? '${staff.firstName[0]}${staff.lastName[0]}'
        : staff.firstName.isNotEmpty
            ? staff.firstName[0]
            : '?';

    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: SizedBox(
          width: 200,
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: _accent.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
              AppSpacing.vGapMd,
              Text(
                staff.fullName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXs,
              Text(
                staff.employeeNo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapSm,
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: AppRadius.brLg,
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  staff.designation,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: (staff.isActive ? AppColors.success500 : AppColors.neutral400)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadius.brLg,
                ),
                child: Text(
                  staff.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: staff.isActive ? AppColors.success500 : AppColors.neutral400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 2 — Qualifications ────────────────────────────────────────────────────

class _QualificationsTab extends ConsumerWidget {
  const _QualificationsTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffQualsProv(staffId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(_staffQualsProv(staffId)),
      ),
      data: (quals) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_staffQualsProv(staffId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          children: [
            Row(
              children: [
                Text('Qualifications (${quals.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAddQualDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            if (quals.isEmpty)
              const _EmptyPlaceholder(
                icon: Icons.school_outlined,
                message: 'No qualifications added yet',
              )
            else
              ...quals.map((q) => _QualCard(
                    qual: q,
                    staffId: staffId,
                    onChanged: () => ref.invalidate(_staffQualsProv(staffId)),
                  )),
          ],
        ),
      ),
    );
  }

  void _showAddQualDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _QualFormDialog(
        staffId: staffId,
        onSaved: () => ref.invalidate(_staffQualsProv(staffId)),
      ),
    );
  }
}

class _QualCard extends ConsumerStatefulWidget {
  const _QualCard(
      {required this.qual, required this.staffId, required this.onChanged});
  final StaffQualificationModel qual;
  final String staffId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_QualCard> createState() => _QualCardState();
}

class _QualCardState extends ConsumerState<_QualCard> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.qual;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: q.isHighest
              ? Colors.amber.withValues(alpha: 0.2)
              : _accent.withValues(alpha: 0.1),
          child: Icon(
            q.isHighest ? Icons.star : Icons.school,
            color: q.isHighest ? Colors.amber : _accent,
            size: 20,
          ),
        ),
        title: Text(q.degree,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.institution),
            if (q.boardOrUniversity != null)
              Text(q.boardOrUniversity!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12)),
            Row(
              children: [
                if (q.yearOfPassing != null)
                  Text('${q.yearOfPassing}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                if (q.gradeOrPercentage != null) ...[
                  const Text(' • ', style: TextStyle(color: AppColors.neutral400)),
                  Text(q.gradeOrPercentage!,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                ],
              ],
            ),
          ],
        ),
        trailing: _deleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit),
                          title: Text('Edit'))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.delete, color: AppColors.error500),
                          title: Text('Delete',
                              style: TextStyle(color: AppColors.error500)))),
                ],
                onSelected: (v) {
                  if (v == 'edit') {
                    showDialog(
                      context: context,
                      builder: (ctx) => _QualFormDialog(
                        staffId: widget.staffId,
                        existing: q,
                        onSaved: widget.onChanged,
                      ),
                    );
                  } else if (v == 'delete') {
                    _delete();
                  }
                },
                child: const Icon(Icons.more_vert, size: 18),
              ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Delete Qualification?',
      message: 'Remove "${widget.qual.degree}" from ${widget.qual.institution}?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .deleteQualification(widget.staffId, widget.qual.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

class _QualFormDialog extends ConsumerStatefulWidget {
  const _QualFormDialog(
      {required this.staffId, this.existing, required this.onSaved});
  final String staffId;
  final StaffQualificationModel? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_QualFormDialog> createState() => _QualFormDialogState();
}

class _QualFormDialogState extends ConsumerState<_QualFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _degreeCtrl =
      TextEditingController(text: widget.existing?.degree ?? '');
  late final _institutionCtrl =
      TextEditingController(text: widget.existing?.institution ?? '');
  late final _boardCtrl =
      TextEditingController(text: widget.existing?.boardOrUniversity ?? '');
  late final _yearCtrl = TextEditingController(
      text: widget.existing?.yearOfPassing?.toString() ?? '');
  late final _gradeCtrl =
      TextEditingController(text: widget.existing?.gradeOrPercentage ?? '');
  late bool _isHighest = widget.existing?.isHighest ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _degreeCtrl.dispose();
    _institutionCtrl.dispose();
    _boardCtrl.dispose();
    _yearCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Qualification' : 'Add Qualification'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf('Degree / Certificate', _degreeCtrl),
                const SizedBox(height: 10),
                _tf('Institution', _institutionCtrl),
                const SizedBox(height: 10),
                _tf('Board / University', _boardCtrl, required: false),
                const SizedBox(height: 10),
                _tf('Year of Passing', _yearCtrl,
                    required: false, isNumber: true),
                const SizedBox(height: 10),
                _tf('Grade / Percentage', _gradeCtrl, required: false),
                const SizedBox(height: 6),
                CheckboxListTile(
                  title: const Text('Highest Qualification'),
                  value: _isHighest,
                  onChanged: (v) => setState(() => _isHighest = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  activeColor: _accent,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _accent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _tf(String label, TextEditingController ctrl,
      {bool required = true, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : null,
      decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final body = {
      'degree': _degreeCtrl.text.trim(),
      'institution': _institutionCtrl.text.trim(),
      if (_boardCtrl.text.trim().isNotEmpty)
        'board_or_university': _boardCtrl.text.trim(),
      if (_yearCtrl.text.trim().isNotEmpty)
        'year_of_passing': int.tryParse(_yearCtrl.text.trim()),
      if (_gradeCtrl.text.trim().isNotEmpty)
        'grade_or_percentage': _gradeCtrl.text.trim(),
      'is_highest': _isHighest,
    };
    try {
      final svc = ref.read(schoolAdminServiceProvider);
      if (widget.existing != null) {
        await svc.updateQualification(
            widget.staffId, widget.existing!.id, body);
      } else {
        await svc.addQualification(widget.staffId, body);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Tab 3 — Documents ─────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffDocsProv(staffId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(_staffDocsProv(staffId)),
      ),
      data: (docs) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_staffDocsProv(staffId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          children: [
            Row(
              children: [
                Text('Documents (${docs.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            if (docs.isEmpty)
              const _EmptyPlaceholder(
                icon: Icons.folder_open_outlined,
                message: 'No documents uploaded yet',
              )
            else
              ...docs.map((d) => _DocCard(
                    doc: d,
                    staffId: staffId,
                    onChanged: () => ref.invalidate(_staffDocsProv(staffId)),
                  )),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _DocFormDialog(
        staffId: staffId,
        onSaved: () => ref.invalidate(_staffDocsProv(staffId)),
      ),
    );
  }
}

class _DocCard extends ConsumerStatefulWidget {
  const _DocCard(
      {required this.doc, required this.staffId, required this.onChanged});
  final StaffDocumentModel doc;
  final String staffId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends ConsumerState<_DocCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accent.withValues(alpha: 0.1),
          child: Icon(_docIcon(d.documentType), color: _accent, size: 20),
        ),
        title: Text(d.documentName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.typeLabel),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: d.verified
                        ? AppColors.success500.withValues(alpha: 0.1)
                        : AppColors.warning500.withValues(alpha: 0.1),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Text(
                    d.verified ? 'Verified' : 'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: d.verified ? AppColors.success500 : AppColors.warning500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (d.fileSizeKb != null) ...[
                  const SizedBox(width: 6),
                  Text('${d.fileSizeKb} KB',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.neutral400)),
                ],
              ],
            ),
          ],
        ),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  if (!d.verified)
                    const PopupMenuItem(
                        value: 'verify',
                        child: ListTile(
                            dense: true,
                            leading: Icon(Icons.verified, color: AppColors.success500),
                            title: Text('Mark Verified'))),
                  const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          dense: true,
                          leading:
                              Icon(Icons.delete, color: AppColors.error500),
                          title: Text('Delete',
                              style: TextStyle(color: AppColors.error500)))),
                ],
                onSelected: (v) {
                  if (v == 'verify') _verify();
                  if (v == 'delete') _delete();
                },
                child: const Icon(Icons.more_vert, size: 18),
              ),
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'AADHAAR':
      case 'PAN':
        return Icons.credit_card;
      case 'DEGREE_CERTIFICATE':
        return Icons.school;
      case 'EXPERIENCE_LETTER':
      case 'APPOINTMENT_LETTER':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .verifyDocument(widget.staffId, widget.doc.id);
      widget.onChanged();
      if (mounted) {
        AppSnackbar.success(context, 'Document marked as verified');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Delete Document?',
      message: 'Remove "${widget.doc.documentName}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .deleteDocument(widget.staffId, widget.doc.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DocFormDialog extends ConsumerStatefulWidget {
  const _DocFormDialog({required this.staffId, required this.onSaved});
  final String staffId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_DocFormDialog> createState() => _DocFormDialogState();
}

class _DocFormDialogState extends ConsumerState<_DocFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _type = 'AADHAAR';
  bool _saving = false;

  static const _docTypes = [
    'AADHAAR',
    'PAN',
    'DEGREE_CERTIFICATE',
    'EXPERIENCE_LETTER',
    'APPOINTMENT_LETTER',
    'OTHER',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Document'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                    labelText: 'Document Type *',
                    border: OutlineInputBorder(),
                    isDense: true),
                items: _docTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Document Name *',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                    labelText: 'File URL *',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _accent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(schoolAdminServiceProvider).addDocument(widget.staffId, {
        'document_type': _type,
        'document_name': _nameCtrl.text.trim(),
        'file_url': _urlCtrl.text.trim(),
      });
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Tab 4 — Subject Assignments ───────────────────────────────────────────────

class _SubjectsTab extends ConsumerWidget {
  const _SubjectsTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffSubjectsProv(staffId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(_staffSubjectsProv(staffId)),
      ),
      data: (assignments) => RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(_staffSubjectsProv(staffId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          children: [
            Row(
              children: [
                Text('Subject Assignments (${assignments.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () =>
                      _showAssignDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Assign'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            if (assignments.isEmpty)
              const _EmptyPlaceholder(
                icon: Icons.book_outlined,
                message: 'No subject assignments yet',
              )
            else
              ...assignments.map((a) => _SubjectCard(
                    assignment: a,
                    staffId: staffId,
                    onChanged: () =>
                        ref.invalidate(_staffSubjectsProv(staffId)),
                  )),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AssignSubjectDialog(
        staffId: staffId,
        onSaved: () => ref.invalidate(_staffSubjectsProv(staffId)),
      ),
    );
  }
}

class _SubjectCard extends ConsumerStatefulWidget {
  const _SubjectCard(
      {required this.assignment,
      required this.staffId,
      required this.onChanged});
  final StaffSubjectAssignmentModel assignment;
  final String staffId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends ConsumerState<_SubjectCard> {
  bool _removing = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accent.withValues(alpha: 0.1),
          child: const Icon(Icons.menu_book, color: _accent, size: 20),
        ),
        title: Text(a.subject,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${a.classSectionLabel} • ${a.academicYear}'),
        trailing: _removing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : PopupMenuButton<String>(
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                          dense: true,
                          leading:
                              Icon(Icons.remove_circle, color: AppColors.error500),
                          title: Text('Remove',
                              style: TextStyle(color: AppColors.error500)))),
                ],
                onSelected: (v) {
                  if (v == 'remove') _remove();
                },
                child: const Icon(Icons.more_vert, size: 18),
              ),
      ),
    );
  }

  Future<void> _remove() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Remove Assignment?',
      message: 'Remove ${widget.assignment.subject} from ${widget.assignment.classSectionLabel}?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _removing = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .removeSubjectAssignment(widget.staffId, widget.assignment.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }
}

class _AssignSubjectDialog extends ConsumerStatefulWidget {
  const _AssignSubjectDialog({required this.staffId, required this.onSaved});
  final String staffId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AssignSubjectDialog> createState() =>
      _AssignSubjectDialogState();
}

class _AssignSubjectDialogState extends ConsumerState<_AssignSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classIdCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _academicYearCtrl =
      TextEditingController(text: '2025-2026');
  bool _saving = false;

  @override
  void dispose() {
    _classIdCtrl.dispose();
    _subjectCtrl.dispose();
    _academicYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Subject'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _classIdCtrl,
                decoration: const InputDecoration(
                    labelText: 'Class ID *',
                    hintText: 'Enter class UUID',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _academicYearCtrl,
                decoration: const InputDecoration(
                    labelText: 'Academic Year *',
                    hintText: '2025-2026',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _accent),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .addSubjectAssignment(widget.staffId, {
        'subject': _subjectCtrl.text.trim(),
        'class_id': _classIdCtrl.text.trim(),
        'academic_year': _academicYearCtrl.text.trim(),
      });
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Tab 5 — Timetable ─────────────────────────────────────────────────────────

class _TimetableTab extends ConsumerWidget {
  const _TimetableTab({required this.staffId});
  final String staffId;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffTimetableProv(staffId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(_staffTimetableProv(staffId)),
      ),
      data: (timetable) {
        final periodNos = timetable.allPeriodNumbers;
        if (periodNos.isEmpty) {
          return const _EmptyPlaceholder(
            icon: Icons.table_chart_outlined,
            message: 'No timetable entries found',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(_staffTimetableProv(staffId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.paddingLg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 56,
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
                columns: [
                  const DataColumn(label: Text('Period')),
                  ...List.generate(7, (i) {
                    return DataColumn(
                      label: Text(_days[i],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    );
                  }),
                ],
                rows: periodNos.map((period) {
                  return DataRow(cells: [
                    DataCell(Text('P$period',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
                    ...List.generate(7, (i) {
                      final dayOfWeek = i + 1;
                      final entry =
                          timetable.periodAt(dayOfWeek, period);
                      if (entry == null) {
                        return const DataCell(Text('-',
                            style: TextStyle(color: AppColors.neutral400)));
                      }
                      return DataCell(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(entry.subject,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            Text(entry.classSectionLabel,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral400)),
                            Text(
                                '${entry.startTime} - ${entry.endTime}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.neutral400)),
                          ],
                        ),
                      );
                    }),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 6 — Leaves ────────────────────────────────────────────────────────────

class _LeavesTab extends ConsumerWidget {
  const _LeavesTab({required this.staffId});
  final String staffId;

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffLeavesProv(staffId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorRetry(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(_staffLeavesProv(staffId)),
      ),
      data: (leaves) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_staffLeavesProv(staffId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          children: [
            Row(
              children: [
                Text('Leave History (${leaves.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.go(
                      '/school-admin/staff/$staffId/leave/apply'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Apply Leave'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            if (leaves.isEmpty)
              const _EmptyPlaceholder(
                icon: Icons.event_busy_outlined,
                message: 'No leave records found',
              )
            else
              ...leaves.map((l) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _leaveStatusColor(l.status).withValues(alpha: 0.15),
                        child: Icon(Icons.event,
                            color: _leaveStatusColor(l.status), size: 20),
                      ),
                      title: Text(l.leaveType,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${_fmtDate(l.fromDate)} — ${_fmtDate(l.toDate)} (${l.totalDays}d)'),
                          Text(l.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.neutral400)),
                        ],
                      ),
                      trailing: _LeaveStatusChip(status: l.status),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Color _leaveStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success500;
      case 'REJECTED':
        return AppColors.error500;
      case 'CANCELLED':
        return AppColors.neutral400;
      default:
        return AppColors.warning500;
    }
  }
}

class _LeaveStatusChip extends StatelessWidget {
  const _LeaveStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = AppColors.success500;
      case 'REJECTED':
        color = AppColors.error500;
      case 'CANCELLED':
        color = AppColors.neutral400;
      default:
        color = AppColors.warning500;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.title, required this.icon, required this.fields});
  final String title;
  final IconData icon;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: _accent),
              AppSpacing.hGapSm,
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 16),
            ...fields.entries.map(
              (e) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(e.key,
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            AppSpacing.vGapMd,
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapMd,
            Text(message, textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
