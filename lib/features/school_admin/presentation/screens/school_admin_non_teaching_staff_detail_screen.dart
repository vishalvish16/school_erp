// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_staff_detail_screen.dart
// PURPOSE: 5-tab detail view: Overview, Qualifications, Documents, Attendance, Leaves.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../models/school_admin/non_teaching_staff_model.dart';
import '../../../../models/school_admin/non_teaching_qualification_model.dart';
import '../../../../models/school_admin/non_teaching_leave_model.dart';
import '../providers/school_admin_non_teaching_roles_provider.dart';

const Color _accent = AppColors.success500;

// ── Per-staff FutureProviders ─────────────────────────────────────────────────

final _ntStaffDetailProv =
    FutureProvider.autoDispose.family<NonTeachingStaffModel, String>(
        (ref, id) =>
            ref.read(schoolAdminServiceProvider).getNonTeachingStaffById(id));

// ── Main screen ───────────────────────────────────────────────────────────────

class SchoolAdminNonTeachingStaffDetailScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingStaffDetailScreen(
      {super.key, required this.staffId});

  final String staffId;

  @override
  ConsumerState<SchoolAdminNonTeachingStaffDetailScreen> createState() =>
      _State();
}

class _State extends ConsumerState<SchoolAdminNonTeachingStaffDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Qualifications'),
    Tab(text: 'Documents'),
    Tab(text: 'Attendance'),
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
    final asyncStaff = ref.watch(_ntStaffDetailProv(widget.staffId));

    final scheme = Theme.of(context).colorScheme;
    return asyncStaff.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.go('/school-admin/non-teaching-staff'),
          ),
          title: const Text('Non-Teaching Staff'),
        ),
        body: const AppLoaderScreen(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.go('/school-admin/non-teaching-staff'),
          ),
          title: const Text('Non-Teaching Staff'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: AppIconSize.xl4, color: scheme.error),
              AppSpacing.vGapLg,
              Text(AppStrings.genericError,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
              AppSpacing.vGapSm,
              Text(e.toString().replaceAll('Exception: ', ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center),
              AppSpacing.vGapXl,
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(_ntStaffDetailProv(widget.staffId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (staff) => _buildScaffold(context, staff),
    );
  }

  Widget _buildScaffold(BuildContext context, NonTeachingStaffModel staff) {
    final categoryColor = staff.role?.categoryColor ?? _accent;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/school-admin/non-teaching-staff'),
        ),
        title: Text(staff.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.go(
                '/school-admin/non-teaching-staff/${staff.id}/edit'),
          ),
          PopupMenuButton<String>(
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  dense: true,
                  leading: Icon(staff.isActive
                      ? Icons.block_outlined
                      : Icons.check_circle_outline),
                  title: Text(staff.isActive ? 'Deactivate' : 'Activate'),
                ),
              ),
              if (!staff.hasLogin)
                const PopupMenuItem(
                  value: 'create_login',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.login),
                    title: Text('Create Login'),
                  ),
                ),
              if (staff.hasLogin)
                const PopupMenuItem(
                  value: 'reset_password',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.lock_reset),
                    title: Text('Reset Password'),
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline,
                      color: scheme.error),
                  title: Text('Delete',
                      style: TextStyle(color: scheme.error)),
                ),
              ),
            ],
            onSelected: (v) => _handleAction(context, staff, v),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: _tabs,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          isScrollable: true,
        ),
      ),
      body: Column(
        children: [
          // Header card
          _StaffHeader(staff: staff, categoryColor: categoryColor),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(staff: staff),
                _QualificationsTab(staffId: staff.id),
                _DocumentsTab(staffId: staff.id),
                _AttendanceTab(staffId: staff.id),
                _LeavesTab(staffId: staff.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, NonTeachingStaffModel staff, String action) async {
    final svc = ref.read(schoolAdminServiceProvider);
    switch (action) {
      case 'toggle':
        final confirmed = await _confirm(
          context,
          title: staff.isActive ? 'Deactivate Staff?' : 'Activate Staff?',
          content:
              '${staff.isActive ? 'Deactivate' : 'Activate'} ${staff.fullName}?',
        );
        if (confirmed && context.mounted) {
          try {
            await svc.updateNonTeachingStaffStatus(staff.id, !staff.isActive);
            ref.invalidate(_ntStaffDetailProv(staff.id));
            if (context.mounted) {
              AppToast.showSuccess(context, 'Status updated');
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
            }
          }
        }
      case 'create_login':
        _showPasswordDialog(context, staff.id, isCreate: true);
      case 'reset_password':
        _showPasswordDialog(context, staff.id, isCreate: false);
      case 'delete':
        final confirmed = await _confirm(
          context,
          title: 'Delete Staff?',
          content: 'Remove ${staff.fullName}? This cannot be undone.',
          destructive: true,
        );
        if (confirmed && context.mounted) {
          try {
            await svc.deleteNonTeachingStaff(staff.id);
            if (context.mounted) {
              context.go('/school-admin/non-teaching-staff');
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
            }
          }
        }
    }
  }

  Future<bool> _confirm(BuildContext context,
      {required String title,
      required String content,
      bool destructive = false}) async {
    return AppDialogs.confirm(
      context,
      title: title,
      message: content,
      isDestructive: destructive,
    );
  }

  void _showPasswordDialog(BuildContext context, String staffId,
      {required bool isCreate}) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isCreate ? 'Create Login' : 'Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password (min 8 chars) *',
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'Minimum 8 characters'
                      : null,
                ),
                AppSpacing.vGapMd,
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Confirm Password *',
                      border: OutlineInputBorder()),
                  validator: (v) => v != passCtrl.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        final svc = ref.read(schoolAdminServiceProvider);
                        if (isCreate) {
                          await svc.createNonTeachingStaffLogin(
                              staffId, passCtrl.text);
                        } else {
                          await svc.resetNonTeachingStaffPassword(
                              staffId, passCtrl.text);
                        }
                        // Clear sensitive password data from memory immediately
                        passCtrl.clear();
                        confirmCtrl.clear();
                        ref.invalidate(_ntStaffDetailProv(staffId));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          AppToast.showSuccess(context, isCreate ? 'Login created' : 'Password reset');
                        }
                      } catch (e) {
                        setS(() => saving = false);
                        if (ctx.mounted) {
                          AppToast.showError(ctx, e.toString().replaceAll('Exception: ', ''));
                        }
                      }
                    },
              child: saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(ctx).colorScheme.onPrimary))
                  : Text(isCreate ? 'Create' : 'Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff Header ──────────────────────────────────────────────────────────────

class _StaffHeader extends StatelessWidget {
  const _StaffHeader(
      {required this.staff, required this.categoryColor});
  final NonTeachingStaffModel staff;
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: scheme.surface,
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: categoryColor.withValues(alpha: 0.2),
            child: Text(
              staff.initials,
              style: textTheme.titleMedium?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(staff.employeeNo,
                    style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: scheme.onSurfaceVariant)),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    if (staff.role != null)
                      _Chip(
                          label: staff.role!.displayName,
                          color: categoryColor),
                    AppSpacing.hGapSm,
                    _Chip(
                      label: staff.isActive ? 'Active' : 'Inactive',
                      color: staff.isActive ? AppColors.success500 : AppColors.neutral400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.staff});
  final NonTeachingStaffModel staff;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(children: [
                  _infoCard('Personal', _personalRows()),
                  AppSpacing.vGapMd,
                  _infoCard('Contact', _contactRows()),
                ])),
                AppSpacing.hGapLg,
                Expanded(
                    child: Column(children: [
                  _infoCard('Employment', _employmentRows()),
                  AppSpacing.vGapMd,
                  _infoCard('Emergency Contact', _emergencyRows()),
                  AppSpacing.vGapMd,
                  _infoCard('Login Status', _loginRows()),
                ])),
              ],
            )
          : Column(children: [
              _infoCard('Personal', _personalRows()),
              AppSpacing.vGapMd,
              _infoCard('Employment', _employmentRows()),
              AppSpacing.vGapMd,
              _infoCard('Contact', _contactRows()),
              AppSpacing.vGapMd,
              _infoCard('Emergency Contact', _emergencyRows()),
              AppSpacing.vGapMd,
              _infoCard('Login Status', _loginRows()),
            ]),
    );
  }

  List<_InfoRow> _personalRows() => [
        _InfoRow('Gender', staff.gender),
        _InfoRow(
            'Date of Birth',
            staff.dateOfBirth != null
                ? _fmtDate(staff.dateOfBirth!)
                : '—'),
        _InfoRow('Blood Group', staff.bloodGroup ?? '—'),
        _InfoRow('Qualification', staff.qualification ?? '—'),
      ];

  List<_InfoRow> _contactRows() => [
        _InfoRow('Email', staff.email),
        _InfoRow('Phone', staff.phone ?? '—'),
        _InfoRow('Address', staff.address ?? '—'),
        _InfoRow('City', staff.city ?? '—'),
        _InfoRow('State', staff.state ?? '—'),
      ];

  List<_InfoRow> _employmentRows() => [
        _InfoRow('Employee No.', staff.employeeNo),
        _InfoRow('Role', staff.role?.displayName ?? '—'),
        _InfoRow('Category', staff.role?.categoryLabel ?? '—'),
        _InfoRow('Department', staff.department ?? '—'),
        _InfoRow('Designation', staff.designation ?? '—'),
        _InfoRow('Employee Type', staff.employeeTypeLabel),
        _InfoRow('Salary Grade', staff.salaryGrade ?? '—'),
        _InfoRow(
            'Join Date',
            staff.joinDate != null ? _fmtDate(staff.joinDate!) : '—'),
      ];

  List<_InfoRow> _emergencyRows() => [
        _InfoRow('Contact Name', staff.emergencyContactName ?? '—'),
        _InfoRow('Contact Phone', staff.emergencyContactPhone ?? '—'),
      ];

  List<_InfoRow> _loginRows() => [
        _InfoRow('Has Login', staff.hasLogin ? 'Yes' : 'No'),
        _InfoRow('Status', staff.isActive ? 'Active' : 'Inactive'),
      ];

  Widget _infoCard(String title, List<_InfoRow> rows) {
    return Builder(builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final scheme = Theme.of(context).colorScheme;
      return Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
              AppSpacing.vGapSm,
              const Divider(),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(r.label,
                            style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text(r.value,
                            style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}

// ── Qualifications Tab ────────────────────────────────────────────────────────

class _QualificationsTab extends ConsumerWidget {
  const _QualificationsTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nonTeachingQualificationsProvider(staffId));
    return async.when(
      loading: () =>
          AppLoaderScreen(),
      error: (e, _) => _retryView(
          e.toString().replaceAll('Exception: ', ''),
          () => ref.invalidate(nonTeachingQualificationsProvider(staffId))),
      data: (quals) => quals.isEmpty
          ? _emptyTab(Icons.school_outlined, 'No qualifications added')
          : ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: quals.length,
              itemBuilder: (ctx, i) {
                final q = quals[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Icon(Icons.school, size: AppIconSize.md)),
                    title: Text(q.degree,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${q.institution}${q.yearOfPassing != null ? ' · ${q.yearOfPassing}' : ''}${q.gradeOrPercentage != null ? ' · ${q.gradeOrPercentage}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit_outlined, size: AppIconSize.md),
                          onPressed: () => _showQualDialog(
                              context, ref, staffId,
                              existing: q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: AppIconSize.md, color: AppColors.error500),
                          onPressed: () =>
                              _deleteQual(context, ref, staffId, q.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showQualDialog(BuildContext context, WidgetRef ref, String staffId,
      {NonTeachingQualificationModel? existing}) {
    final degreeCtrl =
        TextEditingController(text: existing?.degree ?? '');
    final instCtrl =
        TextEditingController(text: existing?.institution ?? '');
    final yearCtrl = TextEditingController(
        text: existing?.yearOfPassing?.toString() ?? '');
    final gradeCtrl =
        TextEditingController(text: existing?.gradeOrPercentage ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
              existing == null ? 'Add Qualification' : 'Edit Qualification'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: degreeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Degree *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: instCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Institution *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Passing Year',
                          border: OutlineInputBorder()),
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: gradeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Grade / Percentage',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        final svc = ref.read(schoolAdminServiceProvider);
                        final body = {
                          'degree': degreeCtrl.text.trim(),
                          'institution': instCtrl.text.trim(),
                          if (yearCtrl.text.isNotEmpty)
                            'year_of_passing':
                                int.tryParse(yearCtrl.text.trim()),
                          if (gradeCtrl.text.isNotEmpty)
                            'grade_or_percentage': gradeCtrl.text.trim(),
                        };
                        if (existing == null) {
                          await svc.addNonTeachingQualification(
                              staffId, body);
                        } else {
                          await svc.updateNonTeachingQualification(
                              staffId, existing.id, body);
                        }
                        ref.invalidate(
                            nonTeachingQualificationsProvider(staffId));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        setS(() => saving = false);
                        if (ctx.mounted) {
                          AppToast.showError(ctx, e.toString().replaceAll('Exception: ', ''));
                        }
                      }
                    },
              child: saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(ctx).colorScheme.onPrimary))
                  : Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteQual(BuildContext context, WidgetRef ref,
      String staffId, String qualId) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete Qualification?',
      message: 'This qualification will be removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .deleteNonTeachingQualification(staffId, qualId);
      ref.invalidate(nonTeachingQualificationsProvider(staffId));
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }
}

// ── Documents Tab ─────────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nonTeachingDocumentsProvider(staffId));
    return async.when(
      loading: () =>
          AppLoaderScreen(),
      error: (e, _) => _retryView(
          e.toString().replaceAll('Exception: ', ''),
          () => ref.invalidate(nonTeachingDocumentsProvider(staffId))),
      data: (docs) => docs.isEmpty
          ? _emptyTab(Icons.folder_outlined, 'No documents uploaded')
          : ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final d = docs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Icon(d.documentIcon, size: 18)),
                    title: Text(d.documentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(d.documentTypeLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!d.isVerified)
                          TextButton(
                            onPressed: () =>
                                _verify(context, ref, staffId, d.id),
                            child: const Text('Verify',
                                style: TextStyle(color: _accent)),
                          )
                        else
                          const Chip(
                            label: Text('Verified',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.success500)),
                            backgroundColor: AppColors.success50,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error500),
                          onPressed: () =>
                              _delete(context, ref, staffId, d.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref, String staffId,
      String docId) async {
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .verifyNonTeachingDocument(staffId, docId);
      ref.invalidate(nonTeachingDocumentsProvider(staffId));
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String staffId,
      String docId) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete Document?',
      message: 'This document will be removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .deleteNonTeachingDocument(staffId, docId);
      ref.invalidate(nonTeachingDocumentsProvider(staffId));
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }
}

// ── Attendance Tab ────────────────────────────────────────────────────────────

class _AttendanceTab extends ConsumerStatefulWidget {
  const _AttendanceTab({required this.staffId});
  final String staffId;

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> _report = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final monthStr =
          '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
      final report = await ref
          .read(schoolAdminServiceProvider)
          .getNonTeachingAttendanceReport(
            month: monthStr,
            staffId: widget.staffId,
          );
      if (mounted) setState(() => _report = report);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(
        () => _month = DateTime(_month.year, _month.month - 1));
    _loadReport();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(
        () => _month = DateTime(_month.year, _month.month + 1));
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return Column(
      children: [
        // Month selector
        Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left)),
              Text(
                '${months[_month.month - 1]} ${_month.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        if (_loading)
          const Expanded(
              child: AppLoaderScreen())
        else if (_error != null)
          Expanded(
              child: _retryView(_error!, _loadReport))
        else
          Expanded(
            child: _report.isEmpty
                ? _emptyTab(
                    Icons.event_note_outlined, 'No attendance data')
                : _AttendanceReportView(report: _report),
          ),
      ],
    );
  }
}

class _AttendanceReportView extends StatelessWidget {
  const _AttendanceReportView({required this.report});
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final records = report['records'] as List? ?? [];
    return SingleChildScrollView(
      padding: AppSpacing.paddingHLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in summary.entries)
                _SummaryBox(
                    label: e.key,
                    count: (e.value as num?)?.toInt() ?? 0),
            ],
          ),
          AppSpacing.vGapLg,
          // Daily records
          for (final r in records)
            if (r is Map)
              _AttendanceRow(record: Map<String, dynamic>.from(r)),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          Text('$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? '';
    final date = record['date'] as String? ?? '';
    final checkIn = record['checkInTime'] ?? record['check_in_time'];
    final checkOut = record['checkOutTime'] ?? record['check_out_time'];
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppRadius.brSm,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Builder(builder: (context) {
        final tt = Theme.of(context).textTheme;
        final cs = Theme.of(context).colorScheme;
        return Row(
          children: [
            Expanded(child: Text(date, style: tt.bodySmall)),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppRadius.brLg,
              ),
              child: Text(_statusLabel(status),
                  style: tt.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600)),
            ),
            if (checkIn != null) ...[
              AppSpacing.hGapSm,
              Text('$checkIn',
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant)),
            ],
            if (checkOut != null) ...[
              AppSpacing.hGapXs,
              Text('–',
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant)),
              AppSpacing.hGapXs,
              Text('$checkOut',
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant)),
            ],
          ],
        );
      }),
    );
  }
}

// ── Leaves Tab ────────────────────────────────────────────────────────────────

class _LeavesTab extends ConsumerWidget {
  const _LeavesTab({required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nonTeachingStaffLeavesProvider(staffId));
    return async.when(
      loading: () =>
          AppLoaderScreen(),
      error: (e, _) => _retryView(
          e.toString().replaceAll('Exception: ', ''),
          () => ref.invalidate(nonTeachingStaffLeavesProvider(staffId))),
      data: (leaves) => leaves.isEmpty
          ? _emptyTab(Icons.event_busy_outlined, 'No leave records')
          : ListView.builder(
              padding: AppSpacing.paddingLg,
              itemCount: leaves.length,
              itemBuilder: (ctx, i) {
                final l = leaves[i];
                return _LeaveCard(leave: l);
              },
            ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave});
  final NonTeachingLeaveModel leave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(
                    label: leave.leaveTypeLabel,
                    color: leave.leaveTypeColor),
                const Spacer(),
                _Chip(
                    label: leave.statusLabel,
                    color: leave.statusColor),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              '${_fmt(leave.fromDate)} – ${_fmt(leave.toDate)} (${leave.totalDays} day${leave.totalDays != 1 ? 's' : ''})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.vGapXs,
            Text(leave.reason,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (leave.adminRemark != null) ...[
              AppSpacing.vGapXs,
              Text('Remark: ${leave.adminRemark}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _emptyTab(IconData icon, String message) {
  return Builder(builder: (context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.xl4, color: Theme.of(context).colorScheme.outline),
          AppSpacing.vGapMd,
          Text(message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  });
}

Widget _retryView(String message, VoidCallback onRetry) {
  return Builder(builder: (context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapSm,
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          AppSpacing.vGapMd,
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  });
}

Color _statusColor(String status) {
  switch (status) {
    case 'PRESENT':
      return AppColors.success500;
    case 'ABSENT':
      return AppColors.error500;
    case 'HALF_DAY':
      return AppColors.warning500;
    case 'ON_LEAVE':
      return AppColors.secondary400;
    case 'HOLIDAY':
      return AppColors.info500;
    case 'LATE':
      return AppColors.warning300;
    default:
      return AppColors.neutral400;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'PRESENT':
      return 'Present';
    case 'ABSENT':
      return 'Absent';
    case 'HALF_DAY':
      return 'Half Day';
    case 'ON_LEAVE':
      return 'On Leave';
    case 'HOLIDAY':
      return 'Holiday';
    case 'LATE':
      return 'Late';
    default:
      return status;
  }
}
