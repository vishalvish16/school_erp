// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_plans_screen.dart
// PURPOSE: Super Admin plans — Create, Edit, Deactivate, Activate, change log
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/create_plan_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

class SuperAdminPlansScreen extends ConsumerStatefulWidget {
  const SuperAdminPlansScreen({super.key});

  @override
  ConsumerState<SuperAdminPlansScreen> createState() =>
      _SuperAdminPlansScreenState();
}

class _SuperAdminPlansScreenState extends ConsumerState<SuperAdminPlansScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminPlanModel> _plans = [];
  List<SuperAdminAuditLogModel> _changeLog = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final plans = await service.getPlans();
      List<SuperAdminAuditLogModel> log = [];
      try {
        final result = await service.getAuditLogs('plans', limit: 10);
        log = result.data;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _plans = plans;
          _changeLog = log;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _plans = [];
        });
      }
    }
  }

  void _openCreatePlan() {
    showAdaptiveModal(
      context,
      CreateEditPlanDialog(
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).createPlan(body);
          if (mounted) _load();
        },
      ),
    );
  }

  void _openEditPlan(SuperAdminPlanModel p) {
    showAdaptiveModal(
      context,
      CreateEditPlanDialog(
        plan: p,
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).updatePlan(p.id, body);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _deactivatePlan(SuperAdminPlanModel p) async {
    final count = p.schoolCount;
    if (count > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate Plan?'),
          content: Text(
            '$count schools are on ${p.name}. Deactivating prevents new assignments but won\'t affect existing.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate Anyway')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      await ref.read(superAdminServiceProvider).updatePlanStatus(p.id, 'inactive');
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _activatePlan(SuperAdminPlanModel p) async {
    try {
      await ref.read(superAdminServiceProvider).updatePlanStatus(p.id, 'active');
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan activated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
                  'Plans & Pricing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _openCreatePlan,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create Plan'),
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _plans.map((p) => _buildPlanCard(p)).toList(),
                ),
                const SizedBox(height: 32),
                if (_changeLog.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Plan Change Log',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/super-admin/audit-logs'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _changeLog.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final log = _changeLog[i];
                        return ListTile(
                          title: Text(log.action.isEmpty ? 'Plan change' : log.action),
                          subtitle: Text(log.createdAt.toIso8601String().substring(0, 10)),
                        );
                      },
                    ),
                  ),
                ],
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SuperAdminPlanModel p) {
    final isActive = (p.status ?? 'active') == 'active';
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.iconEmoji ?? '📦', style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _openEditPlan(p);
                      else if (v == 'deactivate') _deactivatePlan(p);
                      else if (v == 'activate') _activatePlan(p);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (isActive)
                        const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                      if (!isActive)
                        const PopupMenuItem(value: 'activate', child: Text('Activate')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '₹${p.pricePerStudent.toStringAsFixed(0)}/student',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text('${p.schoolCount} schools', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _openEditPlan(p),
                    tooltip: 'Edit',
                  ),
                  if (isActive)
                    IconButton(
                      icon: const Icon(Icons.pause, size: 20),
                      onPressed: () => _deactivatePlan(p),
                      tooltip: 'Deactivate',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      onPressed: () => _activatePlan(p),
                      tooltip: 'Activate',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
