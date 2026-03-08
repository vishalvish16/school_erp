// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_infra_screen.dart
// PURPOSE: Super Admin infrastructure status — auto-refresh 30s
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/super_admin_service.dart';

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Infrastructure Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceCard('API Server', _status['api'] ?? 'unknown'),
                      _buildServiceCard('Database', _status['database'] ?? 'unknown'),
                      _buildServiceCard('GPS WebSocket', _status['gps_ws'] ?? 'unknown'),
                      _buildServiceCard('SMS Gateway', _status['sms'] ?? 'unknown'),
                      _buildServiceCard('S3 Storage', _status['s3'] ?? 'unknown'),
                      _buildServiceCard('FCM Push', _status['fcm'] ?? 'unknown'),
                      if (_status.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Icon(Icons.health_and_safety_outlined, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 16),
                                Text('No infrastructure data available'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, dynamic status) {
    final s = status.toString().toLowerCase();
    final isOk = s == 'ok' || s == 'healthy' || s == 'online';
    final isDown = s == 'down' || s == 'error' || s == 'offline' || s == 'failed';
    final color = isOk ? Colors.green : (isDown ? Colors.red : Colors.orange);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        title: Text(name),
        trailing: Chip(label: Text(s)),
      ),
    );
  }
}
