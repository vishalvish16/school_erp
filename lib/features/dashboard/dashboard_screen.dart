// =============================================================================
// FILE: lib/features/dashboard/dashboard_screen.dart
// PURPOSE: Stable Super Admin Dashboard (No Nested Scroll Issues)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../design_system/design_system.dart';
import '../../core/constants/app_strings.dart';
import 'dashboard_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int getCrossAxisCount() {
      if (ResponsiveWrapper.isDesktop(context)) return 4;
      if (ResponsiveWrapper.isTablet(context)) return 2;
      return 1;
    }

    final horizontalPadding =
        ResponsiveWrapper.isMobile(context) ? 16.0 : 32.0;

    return CustomScrollView(
      slivers: [
        /// ───────────────── HEADER ─────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 24, horizontalPadding, 0),
            child: _HeaderSection(),
          ),
        ),

        const SliverToBoxAdapter(child: AppSpacing.vGapXl2),

        /// ───────────────── KPI GRID ─────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: ref.watch(dashboardDataProvider).when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(child: Text('${AppStrings.errorPrefix}$error')),
            ),
            data: (data) => SliverGrid(
              delegate: SliverChildListDelegate([
                _KpiCard(
                  title: AppStrings.totalSchoolsCard,
                  value: data.metrics.totalSchools.toString(),
                  icon: Icons.business_rounded,
                  color: AppColors.secondary500,
                ),
                _KpiCard(
                  title: AppStrings.activeSchoolsCard,
                  value: data.metrics.activeSchools.toString(),
                  icon: Icons.school_rounded,
                  color: AppColors.success500,
                ),
                _KpiCard(
                  title: AppStrings.monthlyRevenueCard,
                  value: NumberFormat.currency(locale: 'en_US', symbol: '\$').format(data.metrics.monthlyRevenue),
                  icon: Icons.payments_rounded,
                  color: AppColors.warning500,
                ),
                _KpiCard(
                  title: AppStrings.expiringSoonCard,
                  value: data.metrics.expiringSoon.toString(),
                  icon: Icons.warning_rounded,
                  color: AppColors.error500,
                ),
              ]),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getCrossAxisCount(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: ResponsiveWrapper.isMobile(context) ? 2.5 : 1.5,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: AppSpacing.vGapXl3),

        /// ───────────────── ACTIVITY TITLE ─────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              AppStrings.recentTenantActivity,
              style: AppTextStyles.h5(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: AppSpacing.vGapLg),

        /// ───────────────── ACTIVITY LIST ─────────────────
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: ref.watch(dashboardDataProvider).when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (error, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (data) => SliverList.separated(
              itemCount: data.recentActivities.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final activity = data.recentActivities[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      activity.id,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${activity.schoolName} - ${activity.branchName}',
                    style: AppTextStyles.body().copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    activity.action,
                    style: AppTextStyles.caption(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    DateFormat('MMM d, h:mm a').format(activity.timestamp),
                    style: AppTextStyles.caption(),
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: AppSpacing.vGapXl3),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.dashboardTitle,
                style: AppTextStyles.h3(),
              ),
              AppSpacing.vGapXs,
              Text(
                AppStrings.dashboardSubtitle,
                style: AppTextStyles.body(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!ResponsiveWrapper.isMobile(context)) ...[
          AppSpacing.hGapLg,
          IntrinsicWidth(
            child: AppPrimaryButton(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              child: const Text(AppStrings.exportReport),
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.more_horiz_rounded,
                  color: scheme.onSurfaceVariant),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h3(
                        color: scheme.onSurface)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXs,
              Text(
                title,
                style: AppTextStyles.body(
                        color: scheme.onSurfaceVariant)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}