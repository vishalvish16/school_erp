// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_security_screen.dart
// PURPOSE: Super Admin security events, 2FA, trusted devices
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
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
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            const Icon(Icons.security, color: AppColors.success500),
            Text(
              AppStrings.enable2fa,
              style: Theme.of(ctx).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
        content: SizedBox(
          width: (MediaQuery.of(ctx).size.width - 48).clamp(280.0, 400.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.):',
                style: TextStyle(fontSize: 14),
              ),
              AppSpacing.vGapLg,
              Center(
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: QrImageView(
                    data: otpauthUri,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              ),
              AppSpacing.vGapLg,
              const Text('Or enter this key manually:', style: TextStyle(fontSize: 14)),
              AppSpacing.vGapSm,
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: manualKey));
                  AppSnackbar.info(context, AppStrings.copiedToClipboard);
                },
                child: Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(manualKey, style: const TextStyle(fontFamily: 'monospace'))),
                      const Icon(Icons.copy, size: 20),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapXl,
              const Text('Enter the 6-digit code from your app:', style: TextStyle(fontSize: 14)),
              AppSpacing.vGapSm,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                AppSnackbar.warning(context, AppStrings.enter6DigitCodeSnack);
                return;
              }
              try {
                await service.enable2fa(code);
                if (ctx.mounted) Navigator.of(ctx).pop();
                _load();
                if (mounted) {
                  AppSnackbar.success(context, AppStrings.twoFaEnabled);
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
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
      AppSnackbar.error(context, AppStrings.deviceIdNotFound);
      return;
    }
    final ok = await AppDialogs.confirm(
      context,
      title: AppStrings.revokeDeviceQuestion,
      message: 'Revoke ${d['device_name'] ?? d['device_id'] ?? 'this device'}? You will need to verify again on next login.',
      confirmLabel: AppStrings.revoke,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).revokeDevice(deviceId.toString());
      if (mounted) {
        _load();
        AppSnackbar.success(context, AppStrings.deviceRevoked);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _buildSecurityStats() {
    final failedCount = _events.where((e) => e.status == 'failed' || e.status == 'blocked').length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _SecurityStatCard(icon: Icons.check_circle, value: '0', label: AppStrings.activeThreats, color: AppColors.success500),
          _SecurityStatCard(icon: Icons.warning, value: '$failedCount', label: AppStrings.failedLogins24h, color: AppColors.warning500),
          _SecurityStatCard(icon: Icons.devices, value: '${_devices.length}', label: AppStrings.trustedDevices, color: AppColors.secondary500),
          _SecurityStatCard(icon: Icons.security, value: _mfaEnabled ? 'ON' : 'OFF', label: AppStrings.twoFaStatus, color: _mfaEnabled ? AppColors.success500 : AppColors.neutral400),
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

  Future<void> _showBlockIpDialog({String? prefillIp}) async {
    final ipController = TextEditingController(text: prefillIp ?? '');
    final reasonController = TextEditingController();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(AppStrings.blockIpAddress),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: AppStrings.ipAddressRequired,
                  hintText: AppStrings.ipAddressHint,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              AppSpacing.vGapLg,
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: AppStrings.reason,
                  hintText: AppStrings.reasonHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () async {
                final ip = ipController.text.trim();
                if (ip.isEmpty) {
                  AppSnackbar.warning(context, AppStrings.enterIpAddress);
                  return;
                }
                try {
                  await ref.read(superAdminServiceProvider).blockIp(ip, reasonController.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                  if (mounted) {
                    AppSnackbar.warning(context, AppStrings.ipBlocked);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
                  }
                }
              },
              child: const Text(AppStrings.block),
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
        title: const Text(AppStrings.disable2fa),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to disable 2FA:'),
            AppSpacing.vGapLg,
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AppStrings.password,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
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
                  AppSnackbar.warning(context, AppStrings.twoFaDisabled);
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
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
              AppStrings.security,
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
                      _buildSecurityStats(),
                      AppSpacing.vGapXl,
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 500;
                          final content = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                                  color: AppColors.neutral600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                          final btn = FilledButton(
                            onPressed: _mfaEnabled ? _showDisable2faDialog : _showEnable2faDialog,
                            child: Text(_mfaEnabled ? 'Disable' : 'Enable'),
                          );
                          return Card(
                            child: Padding(
                              padding: AppSpacing.paddingXl,
                              child: narrow
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _mfaEnabled ? Icons.check_circle : Icons.security,
                                              color: _mfaEnabled ? AppColors.success500 : Theme.of(context).colorScheme.primary,
                                              size: 40,
                                            ),
                                            AppSpacing.hGapLg,
                                            Expanded(child: content),
                                          ],
                                        ),
                                        AppSpacing.vGapLg,
                                        btn,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          _mfaEnabled ? Icons.check_circle : Icons.security,
                                          color: _mfaEnabled ? AppColors.success500 : Theme.of(context).colorScheme.primary,
                                          size: 40,
                                        ),
                                        AppSpacing.hGapLg,
                                        Expanded(child: content),
                                        btn,
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      AppSpacing.vGapXl,
                      Text(
                        AppStrings.blockIp,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      Card(
                        child: ListTile(
                          leading: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.block),
                          ),
                          title: const Text(AppStrings.blockAnIp),
                          subtitle: const Text(AppStrings.preventAccessIp),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _showBlockIpDialog,
                            tooltip: AppStrings.blockIp,
                          ),
                        ),
                      ),
                      AppSpacing.vGapXl,
                      Text(
                        AppStrings.recentSecurityEvents,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      if (_events.isEmpty)
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingXl,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                                AppSpacing.hGapLg,
                                Text(AppStrings.noRecentSecurityEvents),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._events.take(10).map((e) {
                          final isFailed = e.status == 'failed' || e.status == 'blocked';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isFailed ? AppColors.error500.withValues(alpha: 0.05) : null,
                            child: ListTile(
                              leading: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  isFailed ? Icons.warning_amber : Icons.info_outline,
                                  color: isFailed ? AppColors.error500 : null,
                                ),
                              ),
                              title: Text(e.action),
                              subtitle: Text(
                                '${e.actorName ?? "—"} • ${e.actorIp ?? ""} • ${DateFormat.yMMMd().add_Hm().format(e.createdAt)}',
                              ),
                              trailing: isFailed && e.actorIp != null && e.actorIp!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.block),
                                      onPressed: () {
                                        _showBlockIpDialog(prefillIp: e.actorIp);
                                      },
                                      tooltip: AppStrings.blockIp,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      AppSpacing.vGapXl,
                      Text(
                        AppStrings.trustedDevices,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapMd,
                      if (_devices.isEmpty)
                        Card(
                          child: Padding(
                            padding: AppSpacing.paddingXl,
                            child: Text(AppStrings.noTrustedDevices),
                          ),
                        )
                      else
                        ..._devices.map((d) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.devices),
                            ),
                            title: Text(d['device_name'] ?? d['device_id'] ?? AppStrings.unknown),
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
        ],
      ),
    ),
    );
  }
}

class _SecurityStatCard extends StatelessWidget {
  const _SecurityStatCard({required this.icon, required this.value, required this.label, required this.color});
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
