// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_dashboard_screen.dart
// PURPOSE: Group Admin dashboard — group stats, subscription breakdown, schools summary.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../models/group_admin/group_admin_models.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

final _dashboardProvider =
    FutureProvider.autoDispose<GroupAdminDashboardStats>((ref) {
  return ref.read(groupAdminServiceProvider).getDashboardStats();
});

Widget _groupMetricCard(
  BuildContext context,
  GroupAdminDashboardStats stats,
  int index, {
  required bool compact,
}) {
  switch (index) {
    case 0:
      return MetricStatCard(
        icon: Icons.school,
        value: '${stats.totalSchools}',
        label: 'Total Schools',
        color: AppColors.secondary500,
        subtitle: '${stats.activeSchools} active',
        onTap: () => context.go('/group-admin/schools'),
        compact: compact,
      );
    case 1:
      return MetricStatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: 'Total Students',
        color: AppColors.success500,
        compact: compact,
      );
    case 2:
      return MetricStatCard(
        icon: Icons.schedule,
        value: '${stats.expiringSoon}',
        label: 'Expiring Soon',
        color: stats.expiringSoon > 0 ? AppColors.warning500 : AppColors.neutral400,
        compact: compact,
      );
    case 3:
      return MetricStatCard(
        icon: Icons.person,
        value: '${stats.totalTeachers}',
        label: 'Staff & Teachers',
        color: AppColors.primary500,
        compact: compact,
      );
    default:
      return const SizedBox.shrink();
  }
}

class GroupAdminDashboardScreen extends ConsumerWidget {
  const GroupAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(_dashboardProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isNarrow ? AppSpacing.lg : AppSpacing.xl;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_dashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncStats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl4),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(_dashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '${stats.groupName} — Dashboard',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
              ),
              AppSpacing.vGapXs,
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,

              // Stat cards
              _buildStatsGrid(context, stats),
              AppSpacing.vGapXl,

              // Subscription breakdown
              _buildSubscriptionBreakdown(context, stats),
              AppSpacing.vGapLg,

              // Expiring soon warning
              if (stats.expiringSoon > 0) ...[
                _buildExpiringSoonCard(context, stats),
                AppSpacing.vGapXl,
              ],

              // Quick Access
              _buildQuickAccess(context, isWide),
              AppSpacing.vGapLg,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, GroupAdminDashboardStats stats) {
    final useRow = MediaQuery.sizeOf(context).width >= 600;
    if (useRow) {
      return Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: _groupMetricCard(context, stats, i, compact: false),
            ),
            if (i < 3) const SizedBox(width: AppSpacing.md),
          ],
        ],
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) => SizedBox(
          width: 148,
          child: _groupMetricCard(context, stats, i, compact: true),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBreakdown(
      BuildContext context, GroupAdminDashboardStats stats) {
    if (stats.subscriptionBreakdown.isEmpty) return const SizedBox.shrink();

    final planColors = {
      'PREMIUM': AppColors.secondary500,
      'STANDARD': AppColors.success500,
      'BASIC': AppColors.neutral400,
    };

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Breakdown',
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
            AppSpacing.vGapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: stats.subscriptionBreakdown.entries.map((entry) {
                final color =
                    planColors[entry.key.toUpperCase()] ?? AppColors.neutral400;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(entry.key),
                  backgroundColor: color.withValues(alpha: 0.10),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringSoonCard(
      BuildContext context, GroupAdminDashboardStats stats) {
    return Card(
      color:
          AppColors.warning500.withValues(alpha: 0.10),
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: AppColors.warning500, size: AppIconSize.lg),
        title: Text(
          '${stats.expiringSoon} school subscription(s) expiring soon',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle:
            const Text('Review these schools to avoid service disruption.'),
        trailing: TextButton(
          onPressed: () => context.go('/group-admin/schools'),
          child: const Text(AppStrings.viewSchools),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, bool isWide) {
    final cards = [
      _QuickAccessCard(
        icon: Icons.analytics,
        label: 'School Analytics',
        subtitle: 'Compare all campuses',
        color: AppColors.primary500,
        onTap: () => context.go('/group-admin/analytics'),
      ),
      _QuickAccessCard(
        icon: Icons.bar_chart,
        label: 'Reports',
        subtitle: 'Attendance, Finance & more',
        color: AppColors.success500,
        onTap: () => context.go('/group-admin/reports'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.vGapMd,
        if (isWide)
          Row(
            children: [
              Expanded(child: cards[0]),
              AppSpacing.hGapMd,
              Expanded(child: cards[1]),
            ],
          )
        else
          Column(
            children: [
              cards[0],
              AppSpacing.vGapMd,
              cards[1],
            ],
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brLg,
                ),
                child: Icon(icon, color: color, size: AppIconSize.lg),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppIconSize.sm,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.vGapSm,
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
