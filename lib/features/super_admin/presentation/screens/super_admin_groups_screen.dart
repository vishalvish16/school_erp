// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_groups_screen.dart
// PURPOSE: Super Admin school groups — expand/collapse, Create, Manage, etc.
// =============================================================================

import 'package:flutter/material.dart';
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
    );
  }

  void _openSchoolDetail(String schoolId) {
    showAdaptiveModal(
      context,
      SchoolDetailDialog(
        schoolId: schoolId,
        onUpdated: _load,
      ),
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
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).updateGroup(group.id, body);
          if (mounted) _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'School Groups',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _openAddStandaloneSchool,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Standalone School'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _openCreateGroup,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Create Group'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              ...[
                ..._groups.map((g) => _buildGroupCard(g)),
                if (_standaloneSchools.isNotEmpty) _buildStandaloneNotice(),
              ],
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    child: Text(g.name.isNotEmpty ? g.name[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${g.schoolCount} schools • ${g.studentCount} students • ₹${g.mrr.toStringAsFixed(0)}/mo'),
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
                  ...g.schools.map((s) => ListTile(
                    leading: CircleAvatar(
                      child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(s.name),
                    subtitle: Text('${s.city ?? ''} • ${s.code}'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _openSchoolDetail(s.id),
                      child: const Text('Manage'),
                    ),
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _openAddSchoolToGroup(g),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add School'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/super-admin/schools'),
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Group Report'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openEditGroup(g),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Group Settings'),
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

  Widget _buildStandaloneNotice() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
