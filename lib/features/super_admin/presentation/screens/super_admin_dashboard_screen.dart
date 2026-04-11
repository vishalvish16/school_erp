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
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;
    final isNarrow = width < 600;
    final scheme = Theme.of(context).colorScheme;
    final padding = isNarrow ? AppSpacing.lg : AppSpacing.xl;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — title left, actions right
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.platformOverview,
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
                TextButton.icon(
                  onPressed: () => _exportReport(),
                  icon: Icon(Icons.download_rounded, size: AppIconSize.md),
                  label: Text(isNarrow ? AppStrings.export : AppStrings.exportReport),
                ),
              ],
            ),
            AppSpacing.vGapXl,

            if (_loading)
              Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl4),
                child: const CircularProgressIndicator(),
              ))
            else if (_error != null)
              _buildErrorCard()
            else
              ...[
                // Stats row (metric cards — same pattern as Billing; narrow = horizontal scroll)
                _buildStatsRow(),
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
            Icon(Icons.error_outline, size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(
              AppStrings.couldNotLoadDashboard,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.vGapSm,
            Text(
              _error ?? AppStrings.unknownError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapLg,
            FilledButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh, size: AppIconSize.md),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _stats ?? SuperAdminDashboardStatsModel();
    final useRow = MediaQuery.sizeOf(context).width >= 600;
    final items = <(IconData, String, String, Color, VoidCallback)>[
      (
        Icons.school_rounded,
        '${s.totalSchools}',
        'Total Schools',
        AppColors.primary500,
        () => context.go('/super-admin/schools'),
      ),
      (
        Icons.people_rounded,
        '${s.totalStudents}',
        'Total Students',
        AppColors.secondary500,
        () => context.go('/super-admin/schools'),
      ),
      (
        Icons.currency_rupee_rounded,
        '₹${s.mrr.toStringAsFixed(0)}',
        'Monthly Revenue',
        AppColors.warning500,
        () => context.go('/super-admin/billing'),
      ),
      (
        Icons.account_tree_rounded,
        '${s.totalGroups}',
        'School Groups',
        AppColors.primary400,
        () => context.go('/super-admin/groups'),
      ),
    ];
    if (useRow) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: MetricStatCard(
                icon: items[i].$1,
                value: items[i].$2,
                label: items[i].$3,
                color: items[i].$4,
                onTap: items[i].$5,
                compact: false,
              ),
            ),
            if (i < items.length - 1) SizedBox(width: AppSpacing.md),
          ],
        ],
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final e = items[i];
          return SizedBox(
            width: 148,
            child: MetricStatCard(
              icon: e.$1,
              value: e.$2,
              label: e.$3,
              color: e.$4,
              onTap: e.$5,
              compact: true,
            ),
          );
        },
      ),
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
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                trailing: Icon(Icons.chevron_right, size: AppIconSize.md),
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
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () => context.go('/super-admin/schools?plan_id=${p.planId}'),
                  borderRadius: AppRadius.brMd,
                  child: Row(
                    children: [
                      Text(p.planIcon ?? '📦', style: TextStyle(fontSize: AppIconSize.md)),
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
