// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_infra_screen.dart
// PURPOSE: Super Admin infrastructure status — auto-refresh 30s
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SuperAdminInfraScreen extends ConsumerStatefulWidget {
  const SuperAdminInfraScreen({super.key});

  @override
  ConsumerState<SuperAdminInfraScreen> createState() =>
      _SuperAdminInfraScreenState();
}

class _SuperAdminInfraScreenState extends ConsumerState<SuperAdminInfraScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _status = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(superAdminServiceProvider);
      final res = await service.getInfraStatus();
      final data = res['data'] ?? res;
      if (mounted) {
        setState(() {
          _status = data is Map<String, dynamic> ? data : {};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _status = {};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.infrastructureStatus,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AppSpacing.vGapXl,
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(_error!, textAlign: TextAlign.center),
                      AppSpacing.vGapLg,
                      FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                    ],
                  ),
                ),
              )
            else
              Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfraStats(),
                      AppSpacing.vGapXl,
                      Text(
                        AppStrings.services,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      _buildServiceCard(AppStrings.apiServer, _status['api'] ?? 'unknown'),
                      _buildServiceCard(AppStrings.database, _status['database'] ?? 'unknown'),
                      _buildServiceCard(AppStrings.gpsWebSocket, _status['gps_ws'] ?? 'unknown'),
                      _buildServiceCard(AppStrings.smsGateway, _status['sms'] ?? 'unknown'),
                      _buildServiceCard(AppStrings.s3Storage, _status['s3'] ?? 'unknown'),
                      _buildServiceCard(AppStrings.fcmPush, _status['fcm'] ?? 'unknown'),
                      AppSpacing.vGapXl,
                      Text(
                        AppStrings.thirtyDayUptime,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      ..._buildUptimeBars(),
                      if (_status.isEmpty)
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingXl,
                            child: Row(
                              children: [
                                Icon(Icons.health_and_safety_outlined, color: Theme.of(context).colorScheme.outline),
                                AppSpacing.hGapLg,
                                Text(AppStrings.noInfraData),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfraStats() {
    final uptime = _status['uptime_pct'] ?? 99.9;
    final responseMs = _status['response_ms'] ?? 45;
    final connections = _status['active_connections'] ?? 0;
    final storagePct = _status['storage_used_pct'] ?? 62;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _InfraStatCard(icon: Icons.schedule, value: '$uptime%', label: 'Uptime', color: AppColors.success500),
          _InfraStatCard(icon: Icons.speed, value: '${responseMs}ms', label: 'Response Time', color: AppColors.secondary500),
          _InfraStatCard(icon: Icons.link, value: '$connections', label: 'Active Connections', color: Colors.purple),
          _InfraStatCard(icon: Icons.storage, value: '$storagePct%', label: 'Storage Used', color: AppColors.warning500),
        ];
        if (isWide) {
          return Row(
            children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: cards,
        );
      },
    );
  }

  List<Widget> _buildUptimeBars() {
    final services = [
      (AppStrings.apiServer, 'api', _status['api'] ?? 'unknown'),
      (AppStrings.database, 'database', _status['database'] ?? 'unknown'),
      (AppStrings.gpsWebSocket, 'gps_ws', _status['gps_ws'] ?? 'unknown'),
      (AppStrings.smsGateway, 'sms', _status['sms'] ?? 'unknown'),
      (AppStrings.s3Storage, 's3', _status['s3'] ?? 'unknown'),
      (AppStrings.fcmPush, 'fcm', _status['fcm'] ?? 'unknown'),
    ];
    return services.map((s) {
      final uptimeMap = _status['uptime_30d'];
      final uptimeData = uptimeMap is Map ? uptimeMap[s.$2] : null;
      final bars = uptimeData is List ? uptimeData : List.filled(30, 1.0);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(s.$1, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Chip(label: Text(s.$3.toString())),
                ],
              ),
              AppSpacing.vGapMd,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(30, (i) {
                  final v = i < bars.length ? (bars[i] is num ? bars[i] as num : 1.0) : 1.0;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 20,
                      decoration: BoxDecoration(
                        color: (v >= 0.99 ? AppColors.success500 : (v >= 0.95 ? AppColors.warning500 : AppColors.error500))
                            .withValues(alpha: 0.3 + (v * 0.7)),
                        borderRadius: AppRadius.brXs,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildServiceCard(String name, dynamic status) {
    final s = status.toString().toLowerCase();
    final isOk = s == 'ok' || s == 'healthy' || s == 'online';
    final isDown = s == 'down' || s == 'error' || s == 'offline' || s == 'failed';
    final color = isOk ? AppColors.success500 : (isDown ? AppColors.error500 : AppColors.warning500);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
        ),
        title: Text(name),
        trailing: Chip(label: Text(s)),
      ),
    );
  }
}

class _InfraStatCard extends StatelessWidget {
  const _InfraStatCard({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.brMd),
              child: Icon(icon, size: 24, color: color),
            ),
            AppSpacing.vGapMd,
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.vGapXs,
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
