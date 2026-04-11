// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_bus_screen.dart
// PURPOSE: Live bus tracking screen for parent — shows bus location on map.
//          Auto-refreshes every 10s when trip is IN_PROGRESS.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/parent_service.dart';
import '../../../../models/parent/bus_location_model.dart';
import '../../../../design_system/design_system.dart';

class ParentChildBusScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentChildBusScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildBusScreen> createState() =>
      _ParentChildBusScreenState();
}

class _ParentChildBusScreenState extends ConsumerState<ParentChildBusScreen> {
  BusLocationModel? _data;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_data?.tripStatus == 'IN_PROGRESS') _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(parentServiceProvider);
      final data = await service.getChildBusLocation(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
        _error = null;
      });
      if (data.location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(data.location!.lat, data.location!.lng)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/parent/children/${widget.studentId}'),
        ),
        title: const Text('Track Bus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? AppLoaderScreen()
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapMd,
            Text(_error!, textAlign: TextAlign.center),
            AppSpacing.vGapMd,
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final data = _data!;

    if (!data.hasBus) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus_outlined, size: AppIconSize.xl4, color: scheme.outline),
              AppSpacing.vGapLg,
              Text(
                'No bus assigned for this student',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isActive = data.tripStatus == 'IN_PROGRESS';
    final loc = data.location;

    return Column(
      children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingMd,
          color: isActive ? AppColors.success500.withValues(alpha: 0.10) : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.success500 : AppColors.neutral400,
                ),
              ),
              AppSpacing.hGapSm,
              Text(
                isActive ? 'Bus is on the way' : 'Bus is not on a trip',
                style: AppTextStyles.bodyMd(
                  color: isActive ? AppColors.success700 : AppColors.neutral600,
                ),
              ),
              if (loc != null && isActive && (loc.speed ?? 0) > 0) ...[
                const Spacer(),
                Text(
                  '${((loc.speed ?? 0) * 3.6).toStringAsFixed(0)} km/h',
                  style: AppTextStyles.bodySm(color: AppColors.success700),
                ),
              ],
            ],
          ),
        ),

        // Map
        Expanded(
          child: loc != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(loc.lat, loc.lng),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: {
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: LatLng(loc.lat, loc.lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange),
                      infoWindow: InfoWindow(
                        title: data.vehicle?.vehicleNo ?? 'School Bus',
                        snippet: data.vehicle?.driverName,
                      ),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: AppIconSize.xl3, color: AppColors.neutral400),
                        AppSpacing.vGapSm,
                        Text(
                          'Location not available yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // Vehicle info card
        if (data.vehicle != null)
          Card(
            margin: AppSpacing.paddingMd,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_bus, color: AppColors.driverAccent),
                      AppSpacing.hGapSm,
                      Text(
                        data.vehicle!.vehicleNo,
                        style: AppTextStyles.h6(),
                      ),
                    ],
                  ),
                  if (data.vehicle!.driverName != null) ...[
                    const Divider(height: AppSpacing.xl),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: AppIconSize.sm, color: AppColors.neutral500),
                        AppSpacing.hGapSm,
                        Text(
                          data.vehicle!.driverName!,
                          style: AppTextStyles.bodyMd(),
                        ),
                        if (data.vehicle!.driverPhone != null) ...[
                          const Spacer(),
                          Icon(Icons.phone,
                              size: AppIconSize.sm, color: AppColors.success600),
                          AppSpacing.hGapXs,
                          Text(
                            data.vehicle!.driverPhone!,
                            style: AppTextStyles.bodySm(
                                color: AppColors.success600),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (loc?.updatedAt != null) ...[
                    AppSpacing.vGapSm,
                    Text(
                      'Last updated: ${_formatTime(loc!.updatedAt!)}',
                      style: AppTextStyles.bodySm(color: AppColors.neutral500),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
