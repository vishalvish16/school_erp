// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_security_screen.dart
// PURPOSE: Super Admin security events, 2FA, trusted devices
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

class SuperAdminSecurityScreen extends ConsumerStatefulWidget {
  const SuperAdminSecurityScreen({super.key});

  @override
  ConsumerState<SuperAdminSecurityScreen> createState() =>
      _SuperAdminSecurityScreenState();
}

class _SuperAdminSecurityScreenState extends ConsumerState<SuperAdminSecurityScreen> {
  bool _loading = true;
  String? _error;
  bool _mfaEnabled = false;
  List<SuperAdminAuditLogModel> _events = [];
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(superAdminServiceProvider);
      final results = await Future.wait([
        service.get2faStatus(),
        service.getSecurityEvents(),
        service.getTrustedDevices(),
      ]);
      if (mounted) {
        final status = results[0] as Map<String, dynamic>;
        setState(() {
          _mfaEnabled = status['mfa_enabled'] == true;
          _events = results[1] as List<SuperAdminAuditLogModel>;
          _devices = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _events = [];
          _devices = [];
        });
      }
    }
  }

  Future<void> _showEnable2faDialog() async {
    final service = ref.read(superAdminServiceProvider);
    Map<String, dynamic>? setupData;
    try {
      setupData = await service.setup2fa();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
      return;
    }
    if (!mounted) return;

    final otpauthUri = setupData['otpauth_uri'] as String? ?? '';
    final manualKey = setupData['manual_entry_key'] as String? ?? '';

    final codeController = TextEditingController();
    final codeFocus = FocusNode();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 12),
            Text('Enable Two-Factor Authentication'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.):',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: otpauthUri,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or enter this key manually:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: manualKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(manualKey, style: const TextStyle(fontFamily: 'monospace'))),
                      const Icon(Icons.copy, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Enter the 6-digit code from your app:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                focusNode: codeFocus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  if (v.length == 6) {
                    codeFocus.unfocus();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter 6-digit code')),
                );
                return;
              }
              try {
                await service.enable2fa(code);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('2FA enabled successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Verify & Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeDevice(Map<String, dynamic> d) async {
    final deviceId = d['device_id'] ?? d['deviceId'] ?? d['id']?.toString();
    if (deviceId == null || deviceId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device ID not found')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Device?'),
        content: Text(
          'Revoke ${d['device_name'] ?? d['device_id'] ?? 'this device'}? You will need to verify again on next login.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).revokeDevice(deviceId.toString());
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device revoked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _showBlockIpDialog() async {
    final ipController = TextEditingController();
    final reasonController = TextEditingController();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Block IP Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address *',
                  hintText: 'e.g. 192.168.1.1',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Suspicious activity',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final ip = ipController.text.trim();
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter IP address')),
                  );
                  return;
                }
                try {
                  await ref.read(superAdminServiceProvider).blockIp(ip, reasonController.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IP blocked'), backgroundColor: Colors.orange),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDisable2faDialog() async {
    final passwordController = TextEditingController();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to disable 2FA:'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) return;
              try {
                await ref.read(superAdminServiceProvider).disable2fa(password);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('2FA disabled'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
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
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(
                                _mfaEnabled ? Icons.check_circle : Icons.security,
                                color: _mfaEnabled ? Colors.green : Theme.of(context).colorScheme.primary,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mfaEnabled ? '2FA is enabled' : '2FA is disabled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _mfaEnabled
                                          ? 'Your account is protected with an authenticator app.'
                                          : 'Add an extra layer of security by requiring a code from your phone.',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: _mfaEnabled ? _showDisable2faDialog : _showEnable2faDialog,
                                child: Text(_mfaEnabled ? 'Disable' : 'Enable'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Block IP',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.block),
                          title: const Text('Block an IP address'),
                          subtitle: const Text('Prevent access from a specific IP'),
                          trailing: FilledButton(
                            onPressed: _showBlockIpDialog,
                            child: const Text('Block IP'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Security Events',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_events.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 16),
                                Text('No recent security events'),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._events.take(10).map((e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: e.status == 'failed' || e.status == 'blocked'
                              ? Colors.red.withValues(alpha: 0.05)
                              : null,
                          child: ListTile(
                            leading: Icon(
                              e.status == 'failed' ? Icons.warning_amber : Icons.info_outline,
                              color: e.status == 'failed' ? Colors.red : null,
                            ),
                            title: Text(e.action),
                            subtitle: Text(
                              '${e.actorName ?? "—"} • ${e.actorIp ?? ""} • ${DateFormat.yMMMd().add_Hm().format(e.createdAt)}',
                            ),
                          ),
                        )),
                      const SizedBox(height: 24),
                      Text(
                        'Trusted Devices',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_devices.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No trusted devices'),
                          ),
                        )
                      else
                        ..._devices.map((d) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.devices),
                            title: Text(d['device_name'] ?? d['device_id'] ?? 'Unknown'),
                            subtitle: Text(d['last_used']?.toString() ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _revokeDevice(d),
                              tooltip: 'Revoke device',
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
