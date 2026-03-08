// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_hardware_screen.dart
// PURPOSE: Super Admin hardware — search, filters, Register, Config, Ping, Alert
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/register_hardware_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

class SuperAdminHardwareScreen extends ConsumerStatefulWidget {
  const SuperAdminHardwareScreen({super.key});

  @override
  ConsumerState<SuperAdminHardwareScreen> createState() =>
      _SuperAdminHardwareScreenState();
}

class _SuperAdminHardwareScreenState extends ConsumerState<SuperAdminHardwareScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminHardwareDeviceModel> _devices = [];
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  String? _typeFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final result = await service.getHardware(
        page: 1,
        limit: 50,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        type: _typeFilter,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _devices = result.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _devices = [];
        });
      }
    }
  }

  void _openRegisterDevice() {
    showAdaptiveModal(
      context,
      RegisterHardwareDialog(
        onRegister: (body) async {
          await ref.read(superAdminServiceProvider).registerHardware(body);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _pingDevice(SuperAdminHardwareDeviceModel d) async {
    try {
      await ref.read(superAdminServiceProvider).pingDevice(d.id);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device responded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device not responding')),
        );
      }
    }
  }

  Future<void> _alertSchool(SuperAdminHardwareDeviceModel d) async {
    try {
      await ref.read(superAdminServiceProvider).alertSchool(d.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School admin notified')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'maintenance':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hardware Devices',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _openRegisterDevice,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Register Device'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search devices...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButtonFormField<String>(
                  value: _typeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'rfid', child: Text('RFID')),
                    const DropdownMenuItem(value: 'gps', child: Text('GPS')),
                    const DropdownMenuItem(value: 'tablet', child: Text('Tablet')),
                  ],
                  onChanged: (v) {
                    setState(() => _typeFilter = v);
                    _load();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    const DropdownMenuItem(value: 'online', child: Text('Online')),
                    const DropdownMenuItem(value: 'offline', child: Text('Offline')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
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
            else if (_devices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.devices_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No devices registered', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              ..._devices.map((d) {
                final isOnline = d.status.toLowerCase() == 'online';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor(d.status),
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [
                                BoxShadow(
                                  color: _statusColor(d.status).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    title: Text(d.deviceId),
                    subtitle: Text(
                      '${d.deviceType} • ${d.schoolName ?? "Unassigned"}${d.locationLabel != null ? " • ${d.locationLabel}" : ""}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, size: 20),
                          onPressed: () {
                            showAdaptiveModal(
                              context,
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Device: ${d.deviceId}', style: Theme.of(context).textTheme.titleMedium),
                                    Text('Type: ${d.deviceType}'),
                                    Text('Location: ${d.locationLabel ?? "-"}'),
                                    Text('Firmware: ${d.firmwareVersion ?? "-"}'),
                                  ],
                                ),
                              ),
                            );
                          },
                          tooltip: 'Config',
                        ),
                        IconButton(
                          icon: const Icon(Icons.wifi_tethering, size: 20),
                          onPressed: () => _pingDevice(d),
                          tooltip: 'Ping',
                        ),
                        if (!isOnline)
                          IconButton(
                            icon: const Icon(Icons.notifications, size: 20),
                            onPressed: () => _alertSchool(d),
                            tooltip: 'Alert School',
                          ),
                        if (d.lastPingAt != null)
                          Text(
                            '${DateFormat.Md().add_Hm().format(d.lastPingAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
