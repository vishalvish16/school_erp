// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_dashboard_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/dashboard_stats_model.dart';
import '../providers/school_admin_dashboard_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

const Color _accent = AppColors.success500;

Widget _schoolAdminMetricCard(
  BuildContext context,
  DashboardStatsModel stats,
  int index, {
  required bool compact,
}) {
  switch (index) {
    case 0:
      return MetricStatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: AppStrings.totalStudents,
        color: AppColors.secondary500,
        onTap: () => context.go('/school-admin/students'),
        compact: compact,
      );
    case 1:
      return MetricStatCard(
        icon: Icons.person_search,
        value: '${stats.totalStaff}',
        label: AppStrings.totalStaff,
        color: AppColors.primary500,
        onTap: () => context.go('/school-admin/staff'),
        compact: compact,
      );
    case 2:
      return MetricStatCard(
        icon: Icons.class_,
        value: '${stats.totalClasses}',
        label: AppStrings.classes,
        subtitle: AppStrings.sectionsCount(stats.totalSections),
        subtitleColor: AppColors.neutral400,
        color: AppColors.info500,
        onTap: () => context.go('/school-admin/classes'),
        compact: compact,
      );
    case 3:
      return MetricStatCard(
        icon: Icons.campaign,
        value: '${stats.noticesCount}',
        label: AppStrings.activeNotices,
        color: AppColors.warning500,
        onTap: () => context.go('/school-admin/notices'),
        compact: compact,
      );
    default:
      return const SizedBox.shrink();
  }
}

class SchoolAdminDashboardScreen extends ConsumerWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(schoolAdminDashboardProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final padding = isWide ? AppSpacing.xl : AppSpacing.lg;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(schoolAdminDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncStats.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(schoolAdminDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                AppStrings.schoolDashboard,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXs,
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,

              // Stat cards grid
              _buildStatsGrid(context, stats),
              AppSpacing.vGapXl,

              // Attendance highlight
              _buildAttendanceCard(context, stats),
              AppSpacing.vGapLg,

              // Quick actions
              _buildQuickActions(context, isWide),
              AppSpacing.vGapXl,

              // Recent activity
              if (stats.recentActivity.isNotEmpty) ...[
                _buildRecentActivity(context, stats.recentActivity),
                AppSpacing.vGapLg,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStatsModel stats) {
    final useRow = MediaQuery.sizeOf(context).width >= 600;
    if (useRow) {
      // IntrinsicHeight forces all cards to match the tallest one (e.g. card
      // with subtitle won't make siblings shorter than it).
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: _schoolAdminMetricCard(context, stats, i, compact: false),
              ),
              if (i < 3) const SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (ctx, i) => SizedBox(
          width: 148,
          child: _schoolAdminMetricCard(context, stats, i, compact: true),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
      BuildContext context, DashboardStatsModel stats) {
    final pct = stats.todayAttendancePercent;
    final color = pct >= 75 ? _accent : pct >= 50 ? AppColors.warning500 : AppColors.error500;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.brLg,
              ),
              child: Icon(Icons.fact_check, color: color, size: AppIconSize.xl),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.todaysAttendance,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    '${pct.toStringAsFixed(1)}${AppStrings.percentStudentsPresent}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.brXs,
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            TextButton(
              onPressed: () => context.go('/school-admin/attendance'),
              child: Text(AppStrings.mark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      _QuickAction(
        icon: Icons.person_add,
        label: AppStrings.addStudent,
        color: AppColors.secondary500,
        onTap: () => context.go('/school-admin/students'),
      ),
      _QuickAction(
        icon: Icons.payments,
        label: AppStrings.collectFee,
        color: _accent,
        onTap: () => context.go('/school-admin/fees/collection'),
      ),
      _QuickAction(
        icon: Icons.fact_check,
        label: AppStrings.attendance,
        color: AppColors.info500,
        onTap: () => context.go('/school-admin/attendance'),
      ),
      _QuickAction(
        icon: Icons.campaign,
        label: AppStrings.newNotice,
        color: AppColors.warning500,
        onTap: () => context.go('/school-admin/notices'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.vGapMd,
        if (isWide)
          Row(
            children: actions
                .map((a) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: a,
                      ),
                    ))
                .toList(),
          )
        else
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [actions[0], AppSpacing.vGapMd, actions[2]],
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  children: [actions[1], AppSpacing.vGapMd, actions[3]],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<RecentActivityItem> activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentActivity,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.vGapMd,
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activity.length.clamp(0, 8),
            separatorBuilder: (context2, i2) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = activity[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  child: const Icon(Icons.circle_notifications,
                      size: AppIconSize.sm, color: _accent),
                ),
                title: Text(item.message,
                    style: Theme.of(context).textTheme.bodySmall),
                subtitle: Text(
                  _timeAgo(item.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Quick Action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, color: color, size: AppIconSize.md),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

// ── Error Card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text('Could not load dashboard',
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapSm,
            Text(error,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
