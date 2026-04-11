// =============================================================================
// FILE: lib/features/student/presentation/screens/student_transport_screen.dart
// PURPOSE: Real-time map showing live driver locations via Socket.IO + REST.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/student_service.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../../../models/student/live_driver_model.dart';

const Color _accentColor = AppColors.info500;

class StudentTransportScreen extends ConsumerStatefulWidget {
  const StudentTransportScreen({super.key});

  @override
  ConsumerState<StudentTransportScreen> createState() =>
      _StudentTransportScreenState();
}

class _StudentTransportScreenState
    extends ConsumerState<StudentTransportScreen> {
  List<LiveDriverModel> _drivers = [];
  bool _isLoading = true;
  String? _error;
  io.Socket? _socket;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialDrivers();
      _connectSocket();
    });
  }

  @override
  void dispose() {
    _disconnectSocket();
    _mapController.dispose();
    super.dispose();
  }

  // ── REST: initial fetch ────────────────────────────────────────────────────

  Future<void> _fetchInitialDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(studentServiceProvider);
      final drivers = await service.getLiveDrivers();
      if (mounted) {
        setState(() {
          _drivers = drivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ── Socket.IO: real-time updates ───────────────────────────────────────────

  void _connectSocket() {
    final accessToken = ref.read(authGuardProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    final socketUrl = ApiConfig.socketUrl;

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('driver:location', (data) {
      if (!mounted || data is! Map<String, dynamic>) return;
      final updated = LiveDriverModel.fromJson(data);
      setState(() {
        final index =
            _drivers.indexWhere((d) => d.driverId == updated.driverId);
        if (index >= 0) {
          _drivers[index] = updated;
        } else {
          _drivers.add(updated);
        }
      });
    });

    _socket!.on('driver:offline', (data) {
      if (!mounted || data is! Map<String, dynamic>) return;
      final driverId = data['driver_id'] as String? ??
          data['driverId'] as String? ??
          '';
      if (driverId.isNotEmpty) {
        setState(() {
          _drivers.removeWhere((d) => d.driverId == driverId);
        });
      }
    });
  }

  void _disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Map helpers ────────────────────────────────────────────────────────────

  LatLng get _defaultCenter {
    if (_drivers.isNotEmpty) {
      return LatLng(_drivers.first.lat, _drivers.first.lng);
    }
    // Default to India center if no drivers
    return const LatLng(20.5937, 78.9629);
  }

  List<Marker> _buildMarkers() {
    return _drivers.map((driver) {
      return Marker(
        point: LatLng(driver.lat, driver.lng),
        width: AppSpacing.xl4,
        height: AppSpacing.xl4,
        child: _DriverMarker(driver: driver),
      );
    }).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.studentTransportTitle,
                style: AppTextStyles.h4(color: scheme.onSurface),
              ),
              AppSpacing.vGapXs,
              Text(
                AppStrings.studentTransportSubtitle,
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,

        // ── Active drivers count ────────────────────────────────────────
        if (!_isLoading && _error == null && _drivers.isNotEmpty)
          Padding(
            padding: AppSpacing.paddingHXl,
            child: Row(
              children: [
                Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: const BoxDecoration(
                    color: AppColors.success500,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.hGapSm,
                Text(
                  '${_drivers.length} ${AppStrings.studentActiveDrivers}',
                  style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        AppSpacing.vGapMd,

        // ── Content ─────────────────────────────────────────────────────
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: AppIconSize.xl3,
                color: scheme.error,
              ),
              AppSpacing.vGapLg,
              Text(
                AppStrings.studentConnectionError,
                style: AppTextStyles.h6(color: scheme.onSurface),
              ),
              AppSpacing.vGapSm,
              Text(
                _error!,
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: _fetchInitialDrivers,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: AppIconSize.xl4,
              color: scheme.outline,
            ),
            AppSpacing.vGapLg,
            Text(
              AppStrings.studentNoActiveDrivers,
              style: AppTextStyles.h6(color: scheme.onSurface),
            ),
            AppSpacing.vGapSm,
            Text(
              AppStrings.studentNoActiveDriversHint,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.vidyron.app',
        ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }
}

// ── Driver Map Marker Widget ─────────────────────────────────────────────────

class _DriverMarker extends StatelessWidget {
  const _DriverMarker({required this.driver});

  final LiveDriverModel driver;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: driver.vehicleNo != null
          ? '${driver.driverName} (${driver.vehicleNo})'
          : driver.driverName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: AppRadius.brSm,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: AppOpacity.shadow),
                  blurRadius: AppElevation.md,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              size: AppIconSize.lg,
              color: Colors.white,
            ),
          ),
          if (driver.vehicleNo != null)
            Container(
              margin: EdgeInsets.only(top: AppSpacing.xs),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral800,
                borderRadius: AppRadius.brXs,
              ),
              child: Text(
                driver.vehicleNo!,
                style: AppTextStyles.caption(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
