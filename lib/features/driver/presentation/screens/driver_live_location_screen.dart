// =============================================================================
// FILE: lib/features/driver/presentation/screens/driver_live_location_screen.dart
// PURPOSE: Driver screen to start/end trip and stream live GPS location.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/driver_location_provider.dart';

const Color _accentColor = AppColors.driverAccent;

class DriverLiveLocationScreen extends ConsumerStatefulWidget {
  const DriverLiveLocationScreen({super.key});

  @override
  ConsumerState<DriverLiveLocationScreen> createState() =>
      _DriverLiveLocationScreenState();
}

class _DriverLiveLocationScreenState
    extends ConsumerState<DriverLiveLocationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDuration.xslow,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleStartTrip() async {
    final ok = await ref.read(driverLocationProvider.notifier).startTrip();
    if (!mounted) return;
    if (ok) {
      AppFeedback.showSuccess(context, AppStrings.driverTripStarted);
    } else {
      final error = ref.read(driverLocationProvider).error;
      AppFeedback.showError(
        context,
        error ?? AppStrings.driverTripStartFailed,
      );
    }
  }

  Future<void> _handleEndTrip() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.driverEndTripConfirmTitle,
      message: AppStrings.driverEndTripConfirmMessage,
      confirmLabel: AppStrings.driverEndTrip,
    );
    if (!confirmed || !mounted) return;

    final ok = await ref.read(driverLocationProvider.notifier).endTrip();
    if (!mounted) return;
    if (ok) {
      AppFeedback.showSuccess(context, AppStrings.driverTripEnded);
    } else {
      final error = ref.read(driverLocationProvider).error;
      AppFeedback.showError(
        context,
        error ?? AppStrings.driverTripEndFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverLocationProvider);
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/driver/dashboard'),
              ),
              AppSpacing.hGapSm,
            ],
          ),
          Text(
            AppStrings.driverLiveLocationTitle,
            style: AppTextStyles.h4(color: scheme.onSurface),
          ),
          AppSpacing.vGapXs,
          Text(
            AppStrings.driverLiveLocationSubtitle,
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
          ),
          AppSpacing.vGapXl,

          // ── Error banner ──────────────────────────────────────────────
          if (state.error != null) ...[
            AppFeedback.errorBanner(
              state.error!,
              onRetry: state.tripActive ? null : _handleStartTrip,
            ),
            AppSpacing.vGapLg,
          ],

          // ── Trip Status Card ──────────────────────────────────────────
          _TripStatusCard(
            tripActive: state.tripActive,
            isStreaming: state.isStreaming,
            isStarting: state.isStarting,
            isStopping: state.isStopping,
            lat: state.lat,
            lng: state.lng,
            pulseController: _pulseController,
            onStartTrip: _handleStartTrip,
            onEndTrip: _handleEndTrip,
          ),
          AppSpacing.vGapXl,

          // ── Coordinates Card (visible when trip is active) ────────────
          if (state.tripActive) ...[
            _CoordinatesCard(
              lat: state.lat,
              lng: state.lng,
              isStreaming: state.isStreaming,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Trip Status Card ─────────────────────────────────────────────────────────

class _TripStatusCard extends StatelessWidget {
  const _TripStatusCard({
    required this.tripActive,
    required this.isStreaming,
    required this.isStarting,
    required this.isStopping,
    required this.lat,
    required this.lng,
    required this.pulseController,
    required this.onStartTrip,
    required this.onEndTrip,
  });

  final bool tripActive;
  final bool isStreaming;
  final bool isStarting;
  final bool isStopping;
  final double? lat;
  final double? lng;
  final AnimationController pulseController;
  final VoidCallback onStartTrip;
  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            // ── Live badge (when active) ──────────────────────────────
            if (tripActive) ...[
              FadeTransition(
                opacity: Tween<double>(begin: 0.4, end: 1.0)
                    .animate(pulseController),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success600,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        AppStrings.driverTripActive,
                        style: AppTextStyles.caption(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapLg,
              Text(
                AppStrings.driverLocationStreaming,
                style: AppTextStyles.body(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXl,
            ],

            // ── Inactive state ────────────────────────────────────────
            if (!tripActive) ...[
              Icon(
                Icons.directions_car_rounded,
                size: AppIconSize.xl4,
                color: _accentColor,
              ),
              AppSpacing.vGapLg,
              Text(
                AppStrings.driverTripNotActive,
                style: AppTextStyles.h5(color: scheme.onSurface),
              ),
              AppSpacing.vGapSm,
              Text(
                AppStrings.driverStartTripDescription,
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXl,
            ],

            // ── Action button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: tripActive
                  ? FilledButton.icon(
                      onPressed: isStopping ? null : onEndTrip,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error600,
                        foregroundColor: Colors.white,
                        padding: AppSpacing.paddingVLg,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      icon: isStopping
                          ? SizedBox(
                              width: AppIconSize.md,
                              height: AppIconSize.md,
                              child: const CircularProgressIndicator(
                                strokeWidth: AppBorderWidth.medium,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.stop_rounded,
                              size: AppIconSize.lg),
                      label: Text(
                        AppStrings.driverEndTrip,
                        style: AppTextStyles.buttonLabel(color: Colors.white),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: isStarting ? null : onStartTrip,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success600,
                        foregroundColor: Colors.white,
                        padding: AppSpacing.paddingVLg,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      icon: isStarting
                          ? SizedBox(
                              width: AppIconSize.md,
                              height: AppIconSize.md,
                              child: const CircularProgressIndicator(
                                strokeWidth: AppBorderWidth.medium,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded,
                              size: AppIconSize.lg),
                      label: Text(
                        AppStrings.driverStartTrip,
                        style: AppTextStyles.buttonLabel(color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coordinates Card ─────────────────────────────────────────────────────────

class _CoordinatesCard extends StatelessWidget {
  const _CoordinatesCard({
    required this.lat,
    required this.lng,
    required this.isStreaming,
  });

  final double? lat;
  final double? lng;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  size: AppIconSize.md,
                  color: _accentColor,
                ),
                AppSpacing.hGapSm,
                Text(
                  AppStrings.driverCurrentLocation,
                  style: AppTextStyles.h6(color: scheme.onSurface),
                ),
                const Spacer(),
                if (isStreaming)
                  Container(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: const BoxDecoration(
                      color: AppColors.success500,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            AppSpacing.vGapLg,
            _CoordRow(
              label: AppStrings.driverLatitude,
              value: lat?.toStringAsFixed(6) ?? AppStrings.dash,
            ),
            AppSpacing.vGapSm,
            _CoordRow(
              label: AppStrings.driverLongitude,
              value: lng?.toStringAsFixed(6) ?? AppStrings.dash,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.xl5,
          child: Text(
            label,
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMd(color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}
