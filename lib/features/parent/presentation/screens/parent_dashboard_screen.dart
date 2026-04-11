// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/notice_summary_model.dart';
import '../../../../models/parent/parent_dashboard_model.dart';
import '../../../../shared/widgets/metric_stat_card.dart';
import '../../data/parent_dashboard_provider.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(parentDashboardProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(parentDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWide ? AppSpacing.xl : AppSpacing.lg),
        child: asyncDashboard.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl5),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(parentDashboardProvider),
          ),
          data: (dashboard) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.parentDashboardTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXs,
              Text(
                AppStrings.parentDashboardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,

              _buildStatsRow(context, dashboard, isWide, isNarrow),
              AppSpacing.vGapXl,

              if (dashboard.recentNotices.isNotEmpty) ...[
                _buildRecentNotices(context, dashboard.recentNotices),
                AppSpacing.vGapLg,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, ParentDashboardModel dashboard, bool isWide, bool isNarrow) {
    final items = [
      _StatData(Icons.family_restroom, '${dashboard.childrenCount}', AppStrings.childrenCount, AppColors.primary500),
      _StatData(Icons.event_available, '${dashboard.todaysPresent}', AppStrings.presentCount, AppColors.success500),
      _StatData(Icons.event_busy, '${dashboard.todaysAbsent}', AppStrings.absentCount, AppColors.warning500),
      _StatData(Icons.receipt_long, AppStrings.viewFeesPerChild, AppStrings.childFees, AppColors.info500),
    ];

    if (!isNarrow) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricStatCard(
                icon: items[i].icon,
                value: items[i].value,
                label: items[i].label,
                color: items[i].color,
                onTap: () => context.go('/parent/children'),
              ),
            ),
          ],
        ],
      );
    }

    // Narrow: horizontal scroll strip
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (_, i) => SizedBox(
          width: 148,
          child: MetricStatCard(
            compact: true,
            icon: items[i].icon,
            value: items[i].value,
            label: items[i].label,
            color: items[i].color,
            onTap: () => context.go('/parent/children'),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotices(BuildContext context, List<NoticeSummaryModel> notices) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.recentNotices,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/parent/notices'),
              child: const Text(AppStrings.viewAll),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notices.length.clamp(0, 5),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notices[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.campaign, size: AppIconSize.sm, color: scheme.primary),
                ),
                title: Text(
                  n.title,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  n.body.length > 80 ? '${n.body.substring(0, 80)}...' : n.body,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.go('/parent/notices/${n.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatData {
  const _StatData(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl4, color: scheme.error),
            SizedBox(height: AppSpacing.lg),
            Text(AppStrings.couldNotLoadDashboard,
                style: textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            SizedBox(height: AppSpacing.sm),
            Text(error,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: Icon(Icons.refresh, size: AppIconSize.md),
              label: const Text(AppStrings.retry),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
