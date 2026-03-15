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

final _dashboardProvider =
    FutureProvider.autoDispose<GroupAdminDashboardStats>((ref) {
  return ref.read(groupAdminServiceProvider).getDashboardStats();
});

class GroupAdminDashboardScreen extends ConsumerWidget {
  const GroupAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(_dashboardProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_dashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncStats.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
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
              _buildStatsGrid(context, stats, isWide),
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
      BuildContext context, GroupAdminDashboardStats stats, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.school,
        value: '${stats.totalSchools}',
        label: 'Total Schools',
        subtitle: '${stats.activeSchools} active',
        color: AppColors.secondary500,
        onTap: () => context.go('/group-admin/schools'),
      ),
      _StatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: 'Total Students',
        color: AppColors.success500,
      ),
      _StatCard(
        icon: Icons.schedule,
        value: '${stats.expiringSoon}',
        label: 'Expiring Soon',
        color: stats.expiringSoon > 0 ? Colors.amber : AppColors.neutral400,
      ),
      _StatCard(
        icon: Icons.person,
        value: '${stats.totalTeachers}',
        label: 'Staff & Teachers',
        color: Colors.purple,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
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

  Widget _buildSubscriptionBreakdown(
      BuildContext context, GroupAdminDashboardStats stats) {
    if (stats.subscriptionBreakdown.isEmpty) return const SizedBox.shrink();

    final planColors = {
      'PREMIUM': AppColors.secondary500,
      'STANDARD': Colors.teal,
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
              spacing: 8,
              runSpacing: 8,
              children: stats.subscriptionBreakdown.entries.map((entry) {
                final color =
                    planColors[entry.key.toUpperCase()] ?? AppColors.neutral400;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
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
          Colors.amber.withValues(alpha: 0.10),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.amber),
        title: Text(
          '${stats.expiringSoon} school subscription(s) expiring soon',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
        color: Colors.indigo,
        onTap: () => context.go('/group-admin/analytics'),
      ),
      _QuickAccessCard(
        icon: Icons.bar_chart,
        label: 'Reports',
        subtitle: 'Attendance, Finance & more',
        color: Colors.teal,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? subtitle;
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
              style:
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success500,
                    fontSize: 11,
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
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
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
                size: 14,
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
                size: 48, color: Theme.of(context).colorScheme.error),
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
