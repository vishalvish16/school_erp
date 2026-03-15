// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart
// PURPOSE: Super Admin dashboard — stats, recent schools, plan distribution
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
    List<Map<String, dynamic>> groups = [];
    try {
      final p = await service.getPlans();
      plans = p.map((e) => {
        'id': e.id,
        'name': e.name,
        'price_per_student': e.pricePerStudent,
        'priceMonthly': e.pricePerStudent,
      }).toList();
      final g = await service.getGroups();
      groups = g.map((e) => {'id': e.id, 'name': e.name}).toList();
    } catch (_) {}
    if (!mounted) return;
    showAdaptiveModal(
      context,
      AddSchoolDialog(
        plans: plans,
        groups: groups,
        onCreate: (body) async {
          await service.createSchool(body);
          if (mounted) _load();
        },
      ),
      maxWidth: kDialogMaxWidthLarge,
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
        AppSnackbar.success(context, AppStrings.reportExported);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Export failed: ${e.toString()}');
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
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;
    final isNarrow = width < 600;
    final scheme = Theme.of(context).colorScheme;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                    AppSpacing.vGapXs,
                    Text(
                      _formatDate(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _exportReport(),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(isNarrow ? 'Export' : 'Export Report'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openAddSchool(),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(isNarrow ? 'Add School' : 'Add School'),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.vGapXl,

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
                AppSpacing.vGapXl,

                // Needs attention (both layouts)
                _buildNeedsAttention(),
                AppSpacing.vGapLg,
                // 2-column: Recent schools + Plan distribution (wide) | stacked (narrow)
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentSchools()),
                      AppSpacing.hGapXl,
                      Expanded(child: _buildPlanDistribution()),
                    ],
                  )
                else
                  ...[
                    _buildRecentSchools(),
                    AppSpacing.vGapLg,
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
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.vGapSm,
            Text(
              _error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapLg,
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
        color: AppColors.secondary500,
        onTap: () => context.go('/super-admin/schools'),
      ),
      _StatCard(
        icon: Icons.people,
        value: '${s.totalStudents}',
        label: 'Students',
        color: AppColors.success500,
        onTap: () => context.go('/super-admin/schools'),
      ),
      _StatCard(
        icon: Icons.payments,
        value: '₹${s.mrr.toStringAsFixed(0)}',
        label: 'MRR',
        color: AppColors.warning500,
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            AppSpacing.hGapMd,
            Expanded(child: cards[1]),
          ],
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(child: cards[2]),
            AppSpacing.hGapMd,
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildNeedsAttention() {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final hasExpiring = s.expiringSchools.isNotEmpty;
    final hasOverdue = s.overdueSchools.isNotEmpty;
    if (!hasExpiring && !hasOverdue) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning500),
                AppSpacing.hGapSm,
                Text(
                  AppStrings.needsAttention,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            if (hasExpiring)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const SizedBox(width: 40, height: 40, child: Icon(Icons.schedule)),
                title: Text(
                  '${s.expiringSchools.length} schools expiring in 7 days',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: TextButton(
                  onPressed: () => context.go('/super-admin/billing'),
                  child: const Text(AppStrings.renew),
                ),
              ),
            if (hasOverdue)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                ),
                title: Text(
                  '${s.overdueSchools.length} schools overdue',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: TextButton(
                  onPressed: () => _openResolveOverdue(s.overdueSchools.first),
                  child: const Text(AppStrings.resolve),
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
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.recentlyAdded,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (list.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/super-admin/schools'),
                    child: const Text(AppStrings.viewAll),
                  ),
              ],
            ),
            AppSpacing.vGapMd,
            if (list.isEmpty)
              Padding(
                padding: AppSpacing.paddingXl,
                child: Text(
                  AppStrings.noSchoolsYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...list.take(5).map((school) => ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.xs),
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircleAvatar(
                    child: Text(school.name.isNotEmpty ? school.name[0].toUpperCase() : '?'),
                  ),
                ),
                title: Text(
                  school.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                subtitle: Text(
                  '${school.city ?? ''} • ${school.code}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => showAdaptiveModal(
                  context,
                  SchoolDetailDialog(
                    schoolId: school.id,
                    onUpdated: _load,
                  ),
                  maxWidth: kDialogMaxWidthLarge,
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
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.planDistribution,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.vGapMd,
            if (list.isEmpty)
              Padding(
                padding: AppSpacing.paddingXl,
                child: Text(
                  AppStrings.noPlans,
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
                  borderRadius: AppRadius.brMd,
                  child: Row(
                    children: [
                      Text(p.planIcon ?? '📦', style: const TextStyle(fontSize: 20)),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.planName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            AppSpacing.vGapXs,
                            LinearProgressIndicator(
                              value: p.percentage / 100,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text('${p.schoolCount}', style: Theme.of(context).textTheme.titleSmall),
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
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          AppSpacing.vGapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brLg,
              child: child,
            )
          : child,
    );
  }
}
