// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart
// PURPOSE: Super Admin dashboard — stats, recent schools, plan distribution
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  SuperAdminDashboardStatsModel? _stats;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _openAddSchool() async {
    final service = ref.read(superAdminServiceProvider);
    List<Map<String, dynamic>> plans = [];
    try {
      final p = await service.getPlans();
      plans = p.map((e) => {
        'id': e.id,
        'name': e.name,
        'price_per_student': e.pricePerStudent,
        'priceMonthly': e.pricePerStudent,
      }).toList();
    } catch (_) {}
    if (!mounted) return;
    showAdaptiveModal(
      context,
      AddSchoolDialog(
        plans: plans,
        groups: [],
        onCreate: (body) async {
          await service.createSchool(body);
          if (mounted) _load();
        },
      ),
    );
  }

  void _openResolveOverdue(SuperAdminSchoolModel school) {
    showAdaptiveModal(
      context,
      ResolveOverdueDialog(
        schoolName: school.name,
        overdueDays: school.overdueDays,
        onResolve: (action, paymentRef) async {
          await ref.read(superAdminServiceProvider).resolveOverdue(
            school.id,
            {'action': action, 'payment_ref': paymentRef},
          );
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _exportReport() async {
    try {
      await ref.read(superAdminServiceProvider).exportDashboardReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final stats = await service.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _stats = SuperAdminDashboardStatsModel();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Overview',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                ...[
                  if (!isWide) const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _exportReport(),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export Report'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openAddSchool(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add School'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              _buildErrorCard()
            else
              ...[
                // Stats row
                _buildStatsRow(isWide),
                const SizedBox(height: 24),

                // 2-column: Recent schools + Plan distribution
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildRecentSchools(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildPlanDistribution(),
                      ),
                    ],
                  )
                else
                  ...[
                    _buildNeedsAttention(),
                    const SizedBox(height: 16),
                    _buildRecentSchools(),
                    const SizedBox(height: 16),
                    _buildPlanDistribution(),
                  ],
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isWide) {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final cards = [
      _StatCard(
        icon: Icons.school,
        value: '${s.totalSchools}',
        label: 'Total Schools',
        color: Colors.blue,
        onTap: () => context.go('/super-admin/schools'),
      ),
      _StatCard(
        icon: Icons.people,
        value: '${s.totalStudents}',
        label: 'Students',
        color: Colors.green,
        onTap: () => context.go('/super-admin/schools'),
      ),
      _StatCard(
        icon: Icons.payments,
        value: '₹${s.mrr.toStringAsFixed(0)}',
        label: 'MRR',
        color: Colors.orange,
        onTap: () => context.go('/super-admin/billing'),
      ),
      _StatCard(
        icon: Icons.group,
        value: '${s.totalGroups}',
        label: 'Groups',
        color: Colors.purple,
        onTap: () => context.go('/super-admin/groups'),
      ),
    ];
    if (isWide) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: c,
        ))).toList(),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards.map((c) => c).toList(),
    );
  }

  Widget _buildNeedsAttention() {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final hasExpiring = s.expiringSchools.isNotEmpty;
    final hasOverdue = s.overdueSchools.isNotEmpty;
    if (!hasExpiring && !hasOverdue) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasExpiring)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('${s.expiringSchools.length} schools expiring in 7 days'),
                trailing: TextButton(
                  onPressed: () => context.go('/super-admin/billing'),
                  child: const Text('Renew'),
                ),
              ),
            if (hasOverdue)
              ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text('${s.overdueSchools.length} schools overdue'),
                trailing: TextButton(
                  onPressed: () => _openResolveOverdue(s.overdueSchools.first),
                  child: const Text('Resolve'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSchools() {
    final list = _stats?.recentSchools ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Added',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (list.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/super-admin/schools'),
                    child: const Text('View All →'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No schools yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...list.take(5).map((school) => ListTile(
                leading: CircleAvatar(
                  child: Text(school.name.isNotEmpty ? school.name[0].toUpperCase() : '?'),
                ),
                title: Text(school.name),
                subtitle: Text('${school.city ?? ''} • ${school.code}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAdaptiveModal(
                  context,
                  SchoolDetailDialog(
                    schoolId: school.id,
                    onUpdated: _load,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDistribution() {
    final list = _stats?.planDistribution ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No plans',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...list.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => context.go('/super-admin/schools?plan_id=${p.planId}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(p.planIcon ?? '📦', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.planName),
                            LinearProgressIndicator(
                              value: p.percentage / 100,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.schoolCount}'),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: child,
            )
          : child,
    );
  }
}
