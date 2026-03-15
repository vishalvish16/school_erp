// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/notice_summary_model.dart';
import '../../../../models/parent/parent_dashboard_model.dart';
import '../../data/parent_dashboard_provider.dart';

const Color _accent = AppColors.success500;

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(parentDashboardProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(parentDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncDashboard.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapXl,

              _buildStatsGrid(context, dashboard, isWide),
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

  Widget _buildStatsGrid(
      BuildContext context, ParentDashboardModel dashboard, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.family_restroom,
        value: '${dashboard.childrenCount}',
        label: AppStrings.childrenCount,
        color: _accent,
        onTap: () => context.go('/parent/children'),
      ),
      _StatCard(
        icon: Icons.event_available,
        value: '${dashboard.todaysPresent}',
        label: AppStrings.presentCount,
        color: AppColors.success600,
        onTap: () => context.go('/parent/children'),
      ),
      _StatCard(
        icon: Icons.event_busy,
        value: '${dashboard.todaysAbsent}',
        label: AppStrings.absentCount,
        color: AppColors.warning500,
        onTap: () => context.go('/parent/children'),
      ),
      _StatCard(
        icon: Icons.receipt_long,
        value: AppStrings.viewFeesPerChild,
        label: AppStrings.childFees,
        color: AppColors.info500,
        onTap: () => context.go('/parent/children'),
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

  Widget _buildRecentNotices(BuildContext context, List<NoticeSummaryModel> notices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.recentNotices,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  child: Icon(Icons.campaign, size: 18, color: _accent),
                ),
                title: Text(
                  n.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  n.body.length > 80 ? '${n.body.substring(0, 80)}...' : n.body,
                  style: Theme.of(context).textTheme.bodySmall,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brLg,
              child: content,
            )
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
            Text(AppStrings.couldNotLoadDashboard,
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapSm,
            Text(error,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(
                onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
