// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Staff/Clerk portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/staff/staff_dashboard_model.dart';
import '../providers/staff_dashboard_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(staffDashboardProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final padding = isWide ? AppSpacing.xl : AppSpacing.lg;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncStats.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl5),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(staffDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.staffDashboardTitle,
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
              _buildStatsRow(context, stats, isWide),
              AppSpacing.vGapXl,

              // Quick actions
              _buildQuickActions(context, isWide),
              AppSpacing.vGapXl,

              // Recent payments
              if (stats.recentPayments.isNotEmpty) ...[
                _buildRecentPayments(context, stats.recentPayments),
                AppSpacing.vGapLg,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, StaffDashboardModel stats, bool isWide) {
    final cards = [
      MetricStatCard(
        icon: Icons.today,
        value: '\u20B9${_fmt(stats.feeCollectedToday)}',
        label: AppStrings.collectedToday,
        subtitle: AppStrings.paymentsCount(stats.totalPaymentsToday),
        color: AppColors.secondary400,
        onTap: () => context.go('/staff/fees'),
      ),
      MetricStatCard(
        icon: Icons.calendar_month,
        value: '\u20B9${_fmt(stats.feeCollectedThisMonth)}',
        label: AppStrings.thisMonth,
        subtitle: AppStrings.paymentsCount(stats.totalPaymentsThisMonth),
        color: AppColors.success500,
        onTap: () => context.go('/staff/fees'),
      ),
      MetricStatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: AppStrings.totalStudents,
        color: AppColors.primary500,
        onTap: () => context.go('/staff/students'),
      ),
      MetricStatCard(
        icon: Icons.campaign,
        value: '${stats.activeNoticesCount}',
        label: AppStrings.activeNotices,
        color: AppColors.warning500,
        onTap: () => context.go('/staff/notices'),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) SizedBox(width: AppSpacing.md),
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
        itemCount: cards.length,
        itemBuilder: (_, i) => SizedBox(
          width: 148,
          child: MetricStatCard(
            compact: true,
            icon: [Icons.today, Icons.calendar_month, Icons.people, Icons.campaign][i],
            value: [
              '\u20B9${_fmt(stats.feeCollectedToday)}',
              '\u20B9${_fmt(stats.feeCollectedThisMonth)}',
              '${stats.totalStudents}',
              '${stats.activeNoticesCount}',
            ][i],
            label: [
              AppStrings.collectedToday,
              AppStrings.thisMonth,
              AppStrings.totalStudents,
              AppStrings.activeNotices,
            ][i],
            color: [
              AppColors.secondary400,
              AppColors.success500,
              AppColors.primary500,
              AppColors.warning500,
            ][i],
            onTap: [
              () => context.go('/staff/fees'),
              () => context.go('/staff/fees'),
              () => context.go('/staff/students'),
              () => context.go('/staff/notices'),
            ][i],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      _QuickAction(
        icon: Icons.add_card,
        label: AppStrings.collectFee,
        color: AppColors.secondary400,
        onTap: () => context.go('/staff/fees'),
      ),
      _QuickAction(
        icon: Icons.person_search,
        label: AppStrings.findStudent,
        color: AppColors.primary500,
        onTap: () => context.go('/staff/students'),
      ),
      _QuickAction(
        icon: Icons.campaign,
        label: AppStrings.viewNotices,
        color: AppColors.warning500,
        onTap: () => context.go('/staff/notices'),
      ),
      _QuickAction(
        icon: Icons.notifications,
        label: AppStrings.notifications,
        color: AppColors.info500,
        onTap: () => context.go('/staff/notifications'),
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
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                Expanded(child: actions[i]),
                if (i < actions.length - 1) SizedBox(width: AppSpacing.md),
              ],
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    actions[0],
                    AppSpacing.vGapMd,
                    actions[2],
                  ],
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  children: [
                    actions[1],
                    AppSpacing.vGapMd,
                    actions[3],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentPayments(
      BuildContext context, List<StaffRecentPayment> payments) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppStrings.recentPayments,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/staff/fees'),
              child: const Text(AppStrings.viewAll),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length.clamp(0, 6),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = payments[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary400.withValues(alpha: 0.15),
                  child: Icon(Icons.receipt, size: AppIconSize.sm, color: AppColors.secondary400),
                ),
                title: Text(
                  p.studentName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${p.feeHead}  \u2022  ${p.receiptNo}  \u2022  ${p.paymentMode}',
                  style: textTheme.bodySmall,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\u20B9${_fmt(p.amount)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success500,
                      ),
                    ),
                    Text(
                      _formatDate(p.paymentDate),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmt(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
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

// ── Quick Action ──────────────────────────────────────────────────────────────

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
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl4, color: scheme.error),
            AppSpacing.vGapLg,
            Text(AppStrings.couldNotLoadDashboard,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
            AppSpacing.vGapSm,
            Text(error,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
            AppSpacing.vGapXl,
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: AppIconSize.md),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
