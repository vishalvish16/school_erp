// =============================================================================
// FILE: lib/features/driver/presentation/screens/driver_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Driver portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/driver_dashboard_provider.dart';

const Color _accentColor = AppColors.driverAccent;

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(driverDashboardProvider);
    final scheme = Theme.of(context).colorScheme;
    final padding = AppSpacing.pagePadding;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(driverDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: asyncStats.when(
          loading: () => Center(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(driverDashboardProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.driverDashboardTitle,
                style: AppTextStyles.h4(color: scheme.onSurface),
              ),
              AppSpacing.vGapXs,
              Text(
                _formatDate(DateTime.now()),
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
              AppSpacing.vGapXl,

              // School card
              _InfoCard(
                icon: Icons.school,
                title: stats.school.name,
                subtitle: null,
                leadingUrl: stats.school.logoUrl,
                color: _accentColor,
              ),
              AppSpacing.vGapMd,

              // Driver card
              _InfoCard(
                icon: Icons.person,
                title: stats.driver.fullName,
                subtitle: null,
                leadingUrl: stats.driver.photoUrl,
                color: _accentColor,
              ),
              AppSpacing.vGapMd,

              // Vehicle card
              _InfoCard(
                icon: Icons.directions_bus,
                title: stats.vehicle != null
                    ? '${stats.vehicle!.vehicleNo} (${stats.vehicle!.capacity} ${AppStrings.driverStudentCount})'
                    : AppStrings.noVehicleAssigned,
                subtitle: stats.vehicle != null
                    ? '${AppStrings.driverVehicle} • ${stats.vehicle!.capacity} ${AppStrings.driverStudentCount}'
                    : null,
                color: _accentColor,
              ),
              AppSpacing.vGapMd,

              // Route card
              _InfoCard(
                icon: Icons.route,
                title: stats.route != null
                    ? '${stats.route!.name} (${stats.route!.stopCount} stops)'
                    : AppStrings.noRouteAssigned,
                subtitle: stats.route != null
                    ? '${AppStrings.driverRoute} • ${stats.route!.stopCount} stops'
                    : null,
                color: _accentColor,
              ),
              AppSpacing.vGapMd,

              // Student count + Trip status
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      value: '${stats.studentCount}',
                      label: AppStrings.driverStudentCount,
                      color: _accentColor,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_shipping,
                      value: _tripStatusLabel(stats.tripStatus),
                      label: AppStrings.driverTripStatus,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _tripStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return AppStrings.tripStatusInProgress;
      case 'COMPLETED':
        return AppStrings.tripStatusCompleted;
      default:
        return AppStrings.tripStatusNotStarted;
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.leadingUrl,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? leadingUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            if (leadingUrl != null && leadingUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: Image.network(
                  leadingUrl!,
                  width: AppSpacing.xl4,
                  height: AppSpacing.xl4,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => _iconCircle(),
                ),
              )
            else
              _iconCircle(),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd(color: scheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    AppSpacing.vGapXs,
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle() {
    return Container(
      width: AppSpacing.xl4,
      height: AppSpacing.xl4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.focus),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(icon, color: color, size: AppIconSize.xl),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppIconSize.lg),
            AppSpacing.vGapSm,
            Text(
              value,
              style: AppTextStyles.h5(color: scheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: AppIconSize.xl3,
              color: scheme.error,
            ),
            AppSpacing.vGapLg,
            Text(
              AppStrings.couldNotLoadDashboard,
              style: AppTextStyles.h6(color: scheme.onSurface),
            ),
            AppSpacing.vGapSm,
            Text(
              error,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapLg,
            FilledButton(
              onPressed: onRetry,
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
