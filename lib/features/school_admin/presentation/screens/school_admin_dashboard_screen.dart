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

const Color _accent = AppColors.success500;

class SchoolAdminDashboardScreen extends ConsumerWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(schoolAdminDashboardProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

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
              _buildStatsGrid(context, stats, isWide),
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

  Widget _buildStatsGrid(
      BuildContext context, DashboardStatsModel stats, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: AppStrings.totalStudents,
        color: AppColors.secondary500,
        onTap: () => context.go('/school-admin/students'),
      ),
      _StatCard(
        icon: Icons.person_search,
        value: '${stats.totalStaff}',
        label: AppStrings.totalStaff,
        color: Colors.purple,
        onTap: () => context.go('/school-admin/staff'),
      ),
      _StatCard(
        icon: Icons.class_,
        value: '${stats.totalClasses}',
        label: AppStrings.classes,
        subtitle: '${stats.totalSections} sections',
        color: Colors.teal,
        onTap: () => context.go('/school-admin/classes'),
      ),
      _StatCard(
        icon: Icons.campaign,
        value: '${stats.noticesCount}',
        label: AppStrings.activeNotices,
        color: AppColors.warning500,
        onTap: () => context.go('/school-admin/notices'),
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
        Row(children: [
          Expanded(child: cards[0]),
          AppSpacing.hGapMd,
          Expanded(child: cards[1]),
        ]),
        AppSpacing.vGapMd,
        Row(children: [
          Expanded(child: cards[2]),
          AppSpacing.hGapMd,
          Expanded(child: cards[3]),
        ]),
      ],
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
              child: Icon(Icons.fact_check, color: color, size: 28),
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
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 6),
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
        color: Colors.teal,
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
                        padding: const EdgeInsets.only(right: 12),
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
          'Recent Activity',
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
                      size: 14, color: _accent),
                ),
                title: Text(item.message,
                    style: const TextStyle(fontSize: 13)),
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

// ── Stat Card ────────────────────────────────────────────────────────────────

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
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          AppSpacing.vGapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brLg,
              child: content,
            )
          : content,
    );
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
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
