// =============================================================================
// FILE: lib/features/driver/presentation/screens/driver_dashboard_screen.dart
// PURPOSE: Dashboard screen for the Driver portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_config.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../location/driver_location_service.dart';
import '../providers/driver_dashboard_provider.dart';
import '../providers/driver_trip_provider.dart';

const Color _accentColor = AppColors.driverAccent;

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _tripActionLoading = false;

  Future<void> _onStartTrip() async {
    // 1. Check & request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to start a trip.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _tripActionLoading = true);
    try {
      // 2. Start trip on backend
      await ref.read(driverTripProvider.notifier).startTrip();

      // 3. Start background location service
      final token = ref.read(authGuardProvider).accessToken ?? '';
      await DriverLocationService.start(
        accessToken: token,
        baseUrl: ApiConfig.baseUrl,
      );

      // 4. Refresh dashboard
      ref.invalidate(driverDashboardProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tripActionLoading = false);
    }
  }

  Future<void> _onEndTrip() async {
    setState(() => _tripActionLoading = true);
    try {
      // 1. End trip on backend
      await ref.read(driverTripProvider.notifier).endTrip();

      // 2. Stop background service
      await DriverLocationService.stop();

      // 3. Refresh dashboard
      ref.invalidate(driverDashboardProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tripActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncStats = ref.watch(driverDashboardProvider);
    final tripState = ref.watch(driverTripProvider);
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
          data: (stats) {
            // Use local trip state if available (after start/end), else use dashboard
            final currentStatus =
                tripState.value?.status ?? stats.tripStatus;
            final isActive = currentStatus == 'IN_PROGRESS';

            return Column(
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

                // Student count + Trip status stats
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
                        value: _tripStatusLabel(currentStatus),
                        label: AppStrings.driverTripStatus,
                        color: isActive ? Colors.green : _accentColor,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapMd,

                // ── Trip Control Card ──────────────────────────────────────
                _TripControlCard(
                  tripStatus: currentStatus,
                  isLoading: _tripActionLoading || tripState.isLoading,
                  onStartTrip: _onStartTrip,
                  onEndTrip: _onEndTrip,
                ),
              ],
            );
          },
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

class _TripControlCard extends StatelessWidget {
  const _TripControlCard({
    required this.tripStatus,
    required this.isLoading,
    required this.onStartTrip,
    required this.onEndTrip,
  });

  final String tripStatus;
  final bool isLoading;
  final VoidCallback onStartTrip;
  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    final isActive = tripStatus == 'IN_PROGRESS';

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: isActive ? Colors.green : AppColors.driverAccent,
                  size: AppIconSize.md,
                ),
                AppSpacing.hGapSm,
                Text("Today's Trip", style: AppTextStyles.h6()),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tripStatus,
                        style: AppTextStyles.bodySm(
                          color: isActive ? Colors.green : AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : isActive
                      ? ElevatedButton.icon(
                          onPressed: onEndTrip,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: AppSpacing.paddingVMd,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onStartTrip,
                          icon: const Icon(Icons.play_circle_outlined),
                          label: const Text('Start Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: AppSpacing.paddingVMd,
                          ),
                        ),
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
