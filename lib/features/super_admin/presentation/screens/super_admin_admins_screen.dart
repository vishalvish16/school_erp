// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_admins_screen.dart
// PURPOSE: Super Admin users — Add, Edit, Remove
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/add_admin_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../design_system/design_system.dart';

class SuperAdminAdminsScreen extends ConsumerStatefulWidget {
  const SuperAdminAdminsScreen({super.key});

  @override
  ConsumerState<SuperAdminAdminsScreen> createState() =>
      _SuperAdminAdminsScreenState();
}

class _SuperAdminAdminsScreenState extends ConsumerState<SuperAdminAdminsScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminUserModel> _admins = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final list = await service.getSuperAdmins();
      if (mounted) {
        setState(() {
          _admins = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _admins = [];
        });
      }
    }
  }

  void _onAdminMenu(SuperAdminUserModel a, String value) {
    switch (value) {
      case 'reset':
        _resetPassword(a);
        break;
      case 'edit':
        showAdaptiveModal(
          context,
          AddAdminDialog(
            existing: a,
            onUpdate: (id, body) async {
              await ref.read(superAdminServiceProvider).updateSuperAdmin(id, body);
              if (mounted) _load();
            },
          ),
        );
        break;
      case 'remove':
        _removeAdmin(a);
        break;
    }
  }

  Widget _buildAdminCard(SuperAdminUserModel a) {
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.email,
                        style: smallMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                HoverPopupMenu<String>(
                  icon: const Icon(Icons.more_vert, size: 22),
                  padding: EdgeInsets.zero,
                  onSelected: (v) => _onAdminMenu(a, v),
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      value: 'reset',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.lock_reset, size: 20),
                        title: const Text(AppStrings.resetPassword),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.edit_outlined, size: 20),
                        title: const Text(AppStrings.edit),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.person_remove, size: 20, color: AppColors.error500),
                        title: Text(
                          AppStrings.remove,
                          style: const TextStyle(color: AppColors.error500),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            Row(
              children: [
                if (a.totpEnabled) ...[
                  Icon(Icons.security, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    a.totpEnabled ? '2FA enabled' : '2FA off',
                    style: smallMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    a.isActive ? AppStrings.statusActive : AppStrings.statusInactive,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: a.isActive
                      ? AppColors.success500.withValues(alpha: 0.2)
                      : AppColors.neutral400.withValues(alpha: 0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddAdmin() {
    showAdaptiveModal(
      context,
      AddAdminDialog(
        onAdd: (body) async {
          await ref.read(superAdminServiceProvider).addSuperAdmin(body);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _resetPassword(SuperAdminUserModel a) async {
    const defaultPassword = 'Password@123';
    final ok = await AppDialogs.confirm(
      context,
      title: AppStrings.resetPasswordQuestion,
      message: AppStrings.resetPasswordConfirm(a.name, defaultPassword),
      confirmLabel: 'Reset',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).resetSuperAdminPassword(a.id);
      if (mounted) {
        AppSnackbar.success(context, AppStrings.passwordResetToDefault);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _removeAdmin(SuperAdminUserModel a) async {
    final currentEmail = ref.read(authGuardProvider).userEmail;
    if (a.email == currentEmail) {
      AppSnackbar.warning(context, AppStrings.cannotRemoveSelf);
      return;
    }
    final ok = await AppDialogs.confirm(
      context,
      title: AppStrings.removeAdminQuestion,
      message: AppStrings.removeAdminConfirm(a.name),
      confirmLabel: AppStrings.remove,
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).removeSuperAdmin(a.id);
      if (mounted) {
        _load();
        AppSnackbar.success(context, AppStrings.adminRemoved);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AppStrings.adminUsers,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _openAddAdmin,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(AppStrings.addAdmin),
                ),
              ],
            ),
            AppSpacing.vGapXl,
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
            else if (_admins.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      AppSpacing.vGapLg,
                      Text(AppStrings.noAdminUsers, style: Theme.of(context).textTheme.titleMedium),
                      AppSpacing.vGapSm,
                      FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= AppBreakpoints.tablet;
                  final adminCards = _admins.map((a) => _buildAdminCard(a)).toList();
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: adminCards,
                              ),
                            ),
                            AppSpacing.hGapLg,
                            Expanded(
                              child: _buildAccessPermissionsCard(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ...adminCards,
                            const SizedBox(height: 20),
                            _buildAccessPermissionsCard(),
                          ],
                        );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessPermissionsCard() {
    final permissions = <Map<String, dynamic>>[
      {'role': 'Owner', 'badge': 'Full Access', 'desc': 'All screens · Can add/remove admins · Billing · Delete schools', 'color': AppColors.success500},
      {'role': 'Tech Admin', 'badge': 'Technical', 'desc': 'Feature flags · Hardware · Infra · Audit logs · No billing', 'color': Colors.purple},
      {'role': 'Ops Admin', 'badge': 'Operations', 'desc': 'Schools · Groups · Billing · Renewals · No system settings', 'color': AppColors.warning500},
      {'role': 'Support Admin', 'badge': 'Read Only', 'desc': 'View only · Can raise support tickets · No edit access', 'color': AppColors.neutral400},
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 20, color: Theme.of(context).colorScheme.primary),
                AppSpacing.hGapSm,
                Text(
                  'Access Permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              'Define what each admin role can access on this platform.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapLg,
            ...permissions.map((p) {
              final color = p['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p['role'] as String,
                          style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        ),
                        Chip(
                          label: Text(p['badge'] as String, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: color.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      p['desc'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
