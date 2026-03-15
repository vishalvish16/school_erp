// =============================================================================
// FILE: lib/features/student/presentation/screens/student_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(studentDashboardProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentDashboardProvider),
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
            onRetry: () => ref.invalidate(studentDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.studentDashboardTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXs,
              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,

              // Stats cards
              _buildStatsGrid(context, stats, isWide),
              AppSpacing.vGapXl,

              // Today timetable
              if (stats.todayTimetable.isNotEmpty) ...[
                _buildSectionTitle(context, AppStrings.todayTimetable),
                AppSpacing.vGapMd,
                _buildTodayTimetable(context, stats.todayTimetable),
                AppSpacing.vGapXl,
              ],

              // Recent notices
              if (stats.recentNotices.isNotEmpty) ...[
                Row(
                  children: [
                    _buildSectionTitle(context, AppStrings.recentNotices),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/student/notices'),
                      child: const Text(AppStrings.viewAll),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,
                _buildRecentNotices(context, stats.recentNotices),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, dynamic stats, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.fact_check,
        value: stats.todayAttendance?.status ?? '—',
        label: 'Today',
        color: _accent,
      ),
      _StatCard(
        icon: Icons.calendar_month,
        value: '${stats.presentDaysThisMonth}',
        label: AppStrings.presentDaysThisMonth,
        color: AppColors.success500,
      ),
      _StatCard(
        icon: Icons.payments,
        value: '₹${_fmt(stats.totalFeePaidThisYear)}',
        label: AppStrings.totalFeePaidThisYear,
        color: AppColors.secondary500,
      ),
      _StatCard(
        icon: Icons.schedule,
        value: '${stats.upcomingDues.length}',
        label: AppStrings.upcomingDues,
        color: AppColors.warning500,
        onTap: () => context.go('/student/fees'),
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

  Widget _buildTodayTimetable(BuildContext context, List slots) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: slots.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final s = slots[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: _accent.withValues(alpha: 0.15),
              child: Text(
                '${s.periodNo}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ),
            title: Text(s.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${s.startTime} - ${s.endTime}${s.room != null ? ' • ${s.room}' : ''}'),
          );
        },
      ),
    );
  }

  Widget _buildRecentNotices(BuildContext context, List notices) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notices.length.clamp(0, 5),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final n = notices[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.campaign_outlined, color: _accent, size: 20),
            title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/student/notices/${n.id}'),
          );
        },
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return Card(
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: AppRadius.brLg, child: content)
          : content,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            const Text(AppStrings.couldNotLoadStudentDashboard,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            AppSpacing.vGapSm,
            Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
