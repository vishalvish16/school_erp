// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_admins_screen.dart
// PURPOSE: Super Admin users — Add, Edit, Remove
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../features/auth/auth_guard_provider.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/add_admin_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

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

  Future<void> _removeAdmin(SuperAdminUserModel a) async {
    final currentEmail = ref.read(authGuardProvider).userEmail;
    if (a.email == currentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot remove yourself')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin?'),
        content: Text(
          'Remove ${a.name} as Tech Admin?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).removeSuperAdmin(a.id);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
                  'Admin Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _openAddAdmin,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Admin'),
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
            else if (_admins.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No admin users', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else
              ..._admins.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(a.name),
                  subtitle: Text(
                    '${a.email} • ${a.role}${a.lastLoginAt != null ? " • Last: ${DateFormat.yMMMd().format(a.lastLoginAt!)}" : ""}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a.totpEnabled)
                        Icon(Icons.security, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(a.isActive ? 'Active' : 'Inactive'),
                        backgroundColor: a.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
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
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove, size: 20),
                        onPressed: () => _removeAdmin(a),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
