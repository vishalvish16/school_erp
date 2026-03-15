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

const Color _accent = AppColors.secondary400;

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(staffDashboardProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffDashboardProvider),
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
            onRetry: () => ref.invalidate(staffDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Dashboard',
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

  Widget _buildStatsGrid(
      BuildContext context, StaffDashboardModel stats, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.today,
        value: '₹${_fmt(stats.feeCollectedToday)}',
        label: 'Collected Today',
        subtitle: '${stats.totalPaymentsToday} payments',
        color: _accent,
        onTap: () => context.go('/staff/fees'),
      ),
      _StatCard(
        icon: Icons.calendar_month,
        value: '₹${_fmt(stats.feeCollectedThisMonth)}',
        label: 'This Month',
        subtitle: '${stats.totalPaymentsThisMonth} payments',
        color: AppColors.success500,
        onTap: () => context.go('/staff/fees'),
      ),
      _StatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: 'Total Students',
        color: Colors.purple,
        onTap: () => context.go('/staff/students'),
      ),
      _StatCard(
        icon: Icons.campaign,
        value: '${stats.activeNoticesCount}',
        label: 'Active Notices',
        color: AppColors.warning500,
        onTap: () => context.go('/staff/notices'),
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

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final actions = [
      _QuickAction(
        icon: Icons.add_card,
        label: 'Collect Fee',
        color: _accent,
        onTap: () => context.go('/staff/fees'),
      ),
      _QuickAction(
        icon: Icons.person_search,
        label: 'Find Student',
        color: Colors.purple,
        onTap: () => context.go('/staff/students'),
      ),
      _QuickAction(
        icon: Icons.campaign,
        label: 'View Notices',
        color: AppColors.warning500,
        onTap: () => context.go('/staff/notices'),
      ),
      _QuickAction(
        icon: Icons.notifications,
        label: 'Notifications',
        color: Colors.teal,
        onTap: () => context.go('/staff/notifications'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Payments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
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
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  child: const Icon(Icons.receipt, size: 16, color: _accent),
                ),
                title: Text(
                  p.studentName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${p.feeHead}  •  ${p.receiptNo}  •  ${p.paymentMode}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmt(p.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.success500,
                      ),
                    ),
                    Text(
                      _formatDate(p.paymentDate),
                      style: Theme.of(context).textTheme.bodySmall,
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

// ── Stat Card ─────────────────────────────────────────────────────────────────

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

// ── Error Card ────────────────────────────────────────────────────────────────

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
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
