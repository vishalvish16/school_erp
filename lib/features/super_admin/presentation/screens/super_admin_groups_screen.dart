// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_groups_screen.dart
// PURPOSE: Super Admin school groups — expand/collapse, Create, Manage, etc.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/add_school_to_group_dialog.dart';
import '../../../../widgets/super_admin/dialogs/create_group_dialog.dart';
import '../../../../widgets/super_admin/dialogs/edit_group_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';

class SuperAdminGroupsScreen extends ConsumerStatefulWidget {
  const SuperAdminGroupsScreen({super.key});

  @override
  ConsumerState<SuperAdminGroupsScreen> createState() =>
      _SuperAdminGroupsScreenState();
}

class _SuperAdminGroupsScreenState extends ConsumerState<SuperAdminGroupsScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminSchoolGroupModel> _groups = [];
  final Set<String> _expandedIds = {};
  List<SuperAdminSchoolModel> _standaloneSchools = [];
  List<SuperAdminPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final p = await ref.read(superAdminServiceProvider).getPlans();
      if (mounted) setState(() => _plans = p);
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final groups = await service.getGroups();
      final schoolsResult = await service.getSchools(limit: 500);
      final standalone = schoolsResult.data.where((s) => s.groupId == null || s.groupId!.isEmpty).toList();
      if (mounted) {
        setState(() {
          _groups = groups;
          _standaloneSchools = standalone;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _groups = [];
        });
      }
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _openCreateGroup() {
    showAdaptiveModal(
      context,
      CreateGroupDialog(
        onCreate: (body) async {
          await ref.read(superAdminServiceProvider).createGroup(body);
          if (mounted) _load();
        },
      ),
    );
  }

  void _openAddStandaloneSchool() {
    final plans = _plans.map((e) => {
      'id': e.id,
      'name': e.name,
      'price_per_student': e.pricePerStudent,
      'priceMonthly': e.pricePerStudent,
    }).toList();
    showAdaptiveModal(
      context,
      AddSchoolDialog(
        plans: plans,
        groups: _groups.map((g) => {'id': g.id, 'name': g.name}).toList(),
        onCreate: (body) async {
          await ref.read(superAdminServiceProvider).createSchool(body);
          if (mounted) _load();
        },
      ),
      maxWidth: kDialogMaxWidthLarge,
    );
  }

  void _openSchoolDetail(String schoolId) {
    showAdaptiveModal(
      context,
      SchoolDetailDialog(
        schoolId: schoolId,
        onUpdated: _load,
      ),
      maxWidth: kDialogMaxWidthLarge,
    );
  }

  void _openAddSchoolToGroup(SuperAdminSchoolGroupModel group) {
    showAdaptiveModal(
      context,
      AddSchoolToGroupDialog(
        groupId: group.id,
        groupName: group.name,
        availableSchools: _standaloneSchools,
        onAdd: (schoolId) async {
          await ref.read(superAdminServiceProvider).addSchoolToGroup(group.id, schoolId);
          if (mounted) _load();
        },
      ),
    );
  }

  void _openEditGroup(SuperAdminSchoolGroupModel group) {
    showAdaptiveModal(
      context,
      EditGroupDialog(
        groupId: group.id,
        initialName: group.name,
        initialSlug: group.slug,
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).updateGroup(group.id, body);
          if (mounted) _load();
        },
      ),
    );
  }

  static String _adminDisplayName(Map<String, dynamic>? admin) {
    if (admin == null) return '';
    final first = admin['first_name'] ?? admin['firstName'] ?? '';
    final last = admin['last_name'] ?? admin['lastName'] ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : (admin['email'] ?? admin['name'] ?? '').toString();
  }

  Widget _buildAssignedAdminSection(SuperAdminSchoolGroupModel g) {
    final admin = g.groupAdmin;
    final hasAdmin = admin != null;
    final isLocked = hasAdmin && (admin['is_locked'] == true);
    final displayName = _adminDisplayName(admin);
    final email = admin?['email']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: hasAdmin
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasAdmin ? Icons.person : Icons.person_off_outlined,
                size: 32,
                color: hasAdmin
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Admin',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAdmin
                          ? (displayName.isNotEmpty ? '$displayName ($email)' : email)
                          : 'No admin assigned',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: hasAdmin ? FontWeight.w500 : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (hasAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        size: 16,
                        color: isLocked
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      AppSpacing.hGapXs,
                      Text(
                        isLocked ? 'Locked' : 'Unlocked',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasAdmin) ...[
            AppSpacing.vGapMd,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isLocked)
                  FilledButton.icon(
                    onPressed: () => _unlockGroupAdmin(g),
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text('Unlock'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _lockGroupAdmin(g),
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text('Lock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => _openManageGroupAdmin(g),
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Reset Password'),
                ),
              ],
            ),
          ] else
            FilledButton.tonalIcon(
              onPressed: () => _openManageGroupAdmin(g),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Assign Admin'),
            ),
        ],
      ),
    );
  }

  Future<void> _lockGroupAdmin(SuperAdminSchoolGroupModel g) async {
    try {
      await ref.read(superAdminServiceProvider).lockGroupAdmin(g.id);
      if (mounted) {
        _load();
        AppSnackbar.warning(context, 'Group admin account locked. They cannot log in for 30 minutes.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _unlockGroupAdmin(SuperAdminSchoolGroupModel g) async {
    try {
      await ref.read(superAdminServiceProvider).unlockGroupAdmin(g.id);
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Account unlocked. Admin can log in now.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _openManageGroupAdmin(SuperAdminSchoolGroupModel group) {
    final hasAdmin = group.groupAdmin != null;
    final adminEmail = group.groupAdmin?['email'] as String? ?? '';
    final adminName = _adminDisplayName(group.groupAdmin);
    final emailCtrl = TextEditingController(text: hasAdmin ? adminEmail : '');
    final nameCtrl = TextEditingController(text: hasAdmin ? adminName : '');
    final mobileCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(hasAdmin ? 'Manage Group Admin — ${group.name}' : 'Assign Group Admin — ${group.name}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAdmin) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(adminName.isNotEmpty ? adminName[0].toUpperCase() : adminEmail[0].toUpperCase())),
                      title: Text(adminName.isNotEmpty ? adminName : adminEmail),
                      subtitle: Text(adminEmail),
                    ),
                    const Divider(),
                    Text('Reset Password', style: Theme.of(ctx).textTheme.labelLarge),
                    AppSpacing.vGapSm,
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    AppSpacing.vGapSm,
                    TextFormField(
                      controller: confirmCtrl,
                      decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (v) {
                        if (passwordCtrl.text.isNotEmpty &&
                            (v == null || v.trim() != passwordCtrl.text.trim())) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: mobileCtrl,
                      decoration: const InputDecoration(labelText: 'Mobile (optional)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Temporary Password', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                    ),
                  ],
                  if (error != null) ...[
                    AppSpacing.vGapSm,
                    Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            if (hasAdmin)
              Tooltip(
                message: 'Use if account is locked due to too many failed login attempts',
                child: TextButton(
                  onPressed: loading ? null : () async {
                    setS(() { loading = true; error = null; });
                    try {
                      await ref.read(superAdminServiceProvider).unlockGroupAdmin(group.id);
                      if (mounted) {
                        AppSnackbar.success(context, 'Account unlocked. Admin can log in now.');
                      }
                    } catch (e) {
                      setS(() { loading = false; error = e.toString().replaceAll('Exception: ', ''); });
                    }
                    setS(() => loading = false);
                  },
                  child: const Text('Unlock Account'),
                ),
              ),
            if (hasAdmin)
              TextButton(
                onPressed: loading ? null : () async {
                  setS(() { loading = true; error = null; });
                  try {
                    await ref.read(superAdminServiceProvider).deactivateGroupAdmin(group.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      _load();
                      AppSnackbar.success(context, 'Group admin deactivated');
                    }
                  } catch (e) {
                    setS(() { loading = false; error = e.toString().replaceAll('Exception: ', ''); });
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                child: const Text('Deactivate Admin'),
              ),
            FilledButton(
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() { loading = true; error = null; });
                try {
                  final service = ref.read(superAdminServiceProvider);
                  if (hasAdmin) {
                    if (passwordCtrl.text.isNotEmpty) {
                      if (passwordCtrl.text.length < 8) {
                        setS(() { loading = false; error = 'Password must be at least 8 characters'; });
                        return;
                      }
                      await service.resetGroupAdminPassword(group.id, passwordCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) AppSnackbar.success(context, 'Password reset successfully');
                    } else {
                      Navigator.pop(ctx);
                    }
                  } else {
                    await service.assignGroupAdmin(group.id, {
                      'admin_email': emailCtrl.text.trim(),
                      'first_name': nameCtrl.text.trim().split(' ').first,
                      'last_name': nameCtrl.text.trim().split(' ').skip(1).join(' '),
                      'phone': mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                      'password': passwordCtrl.text,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      _load();
                      AppSnackbar.success(context, 'Group admin assigned successfully');
                    }
                  }
                } catch (e) {
                  setS(() { loading = false; error = e.toString().replaceAll('Exception: ', ''); });
                }
              },
              child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(hasAdmin ? 'Save' : 'Assign Admin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGroup(SuperAdminSchoolGroupModel g) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Delete Group?',
      message: g.schoolCount > 0
          ? '${g.name} has ${g.schoolCount} school(s). Deleting will unlink all schools from this group. This cannot be undone.'
          : 'Are you sure you want to delete "${g.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).deleteGroup(g.id);
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Group deleted');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _toggleGroupStatus(SuperAdminSchoolGroupModel g) async {
    final isActive = (g.status).toLowerCase() == 'active';
    final newStatus = isActive ? 'inactive' : 'active';
    final action = isActive ? 'Deactivate' : 'Activate';
    final ok = await AppDialogs.confirm(
      context,
      title: '$action Group?',
      message: isActive
          ? 'Deactivating "${g.name}" will hide it from group admin access. Schools will remain linked.'
          : 'Activating "${g.name}" will restore group admin access.',
      confirmLabel: action,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateGroup(g.id, {'status': newStatus});
      if (mounted) {
        _load();
        AppSnackbar.success(context, 'Group ${isActive ? 'deactivated' : 'activated'}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'School Groups',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _openAddStandaloneSchool,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(isNarrow ? 'Add School' : 'Add Standalone School'),
                      ),
                      FilledButton.icon(
                        onPressed: _openCreateGroup,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Create Group'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                child: AppLoaderScreen(),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(padding),
                    child: Padding(
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                          AppSpacing.vGapLg,
                          Text(_error!, textAlign: TextAlign.center),
                          AppSpacing.vGapLg,
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (_groups.isEmpty && _standaloneSchools.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_work_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      AppSpacing.vGapLg,
                      Text('No school groups', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ..._groups.map((g) => _buildGroupCard(g)),
                    if (_standaloneSchools.isNotEmpty) _buildStandaloneNotice(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(SuperAdminSchoolGroupModel g) {
    final expanded = _expandedIds.contains(g.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(g.id),
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                  AppSpacing.hGapMd,
                  CircleAvatar(
                    child: Text(g.name.isNotEmpty ? g.name[0].toUpperCase() : '?'),
                  ),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            AppSpacing.hGapSm,
                            _buildStatusChip(g.status),
                          ],
                        ),
                        Text('${g.schoolCount} schools • ${g.studentCount} students • ₹${g.mrr.toStringAsFixed(0)}/mo'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildCopyChip(
                              label: 'Slug',
                              value: g.slug ?? '—',
                              tooltip: g.slug != null
                                  ? 'Group slug for login (e.g. {slug}.vidyron.in). Tap to copy.'
                                  : 'No slug set. Add in Group Settings.',
                            ),
                            _buildCopyChip(
                              label: 'ID',
                              value: g.id,
                              tooltip: 'Group UUID. Use for group-admin login when slug is not set.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  _buildAssignedAdminSection(g),
                  if (g.schools.isNotEmpty) ...[
                    AppSpacing.vGapSm,
                    Text(
                      'Schools',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    AppSpacing.vGapXs,
                  ],
                  ...g.schools.map((s) => ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircleAvatar(
                        child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                      ),
                    ),
                    title: Text(s.name),
                    subtitle: Text('${s.city ?? ''} • ${s.code}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _openSchoolDetail(s.id),
                      tooltip: 'Manage',
                    ),
                  )),
                  AppSpacing.vGapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _openAddSchoolToGroup(g),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add School'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/super-admin/schools'),
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Group Report'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openManageGroupAdmin(g),
                        icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                        label: Text(g.groupAdmin != null ? 'Manage Admin' : 'Assign Admin'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openEditGroup(g),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Group Settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _toggleGroupStatus(g),
                        icon: Icon(
                          (g.status).toLowerCase() == 'active' ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 18,
                        ),
                        label: Text((g.status).toLowerCase() == 'active' ? 'Deactivate' : 'Activate'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _deleteGroup(g),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
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

  Widget _buildStatusChip(String status) {
    final isActive = (status).toLowerCase() == 'active';
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 11)),
      backgroundColor: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCopyChip({
    required String label,
    required String value,
    String? tooltip,
  }) {
    final canCopy = value.isNotEmpty && value != '—';
    return Tooltip(
      message: tooltip ?? (canCopy ? 'Copy $label' : ''),
      child: InkWell(
        onTap: canCopy
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                if (mounted) {
                  AppSnackbar.info(context, '$label copied: $value');
                }
              }
            : null,
        borderRadius: AppRadius.brXl,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.brXl,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value.length > 20 ? '${value.substring(0, 8)}…' : value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
              if (canCopy) ...[
                AppSpacing.hGapXs,
                Icon(Icons.copy, size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandaloneNotice() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Standalone Schools (${_standaloneSchools.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/super-admin/schools?group_id=none'),
                  child: const Text('View All →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
