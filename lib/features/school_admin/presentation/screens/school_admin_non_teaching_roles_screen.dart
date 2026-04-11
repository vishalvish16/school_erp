// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_roles_screen.dart
// PURPOSE: Manage non-teaching staff roles — system roles (read-only) + custom roles.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../providers/school_admin_non_teaching_roles_provider.dart';
import '../../../../models/school_admin/non_teaching_staff_role_model.dart';


const Color _accent = AppColors.success500;

const List<String> _categories = [
  'FINANCE',
  'LIBRARY',
  'LABORATORY',
  'ADMIN_SUPPORT',
  'GENERAL',
];

String _categoryLabel(String c) {
  switch (c) {
    case 'FINANCE': return 'Finance';
    case 'LIBRARY': return 'Library';
    case 'LABORATORY': return 'Laboratory';
    case 'ADMIN_SUPPORT': return 'Admin Support';
    default: return 'General';
  }
}

class SchoolAdminNonTeachingRolesScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingRolesScreen({super.key});

  @override
  ConsumerState<SchoolAdminNonTeachingRolesScreen> createState() =>
      _SchoolAdminNonTeachingRolesScreenState();
}

class _SchoolAdminNonTeachingRolesScreenState
    extends ConsumerState<SchoolAdminNonTeachingRolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nonTeachingRolesProvider.notifier).loadRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nonTeachingRolesProvider);
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(nonTeachingRolesProvider.notifier).loadRoles();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  8,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/school-admin/non-teaching-staff'),
                    ),
                    Text(
                      'Roles & Categories',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showRoleDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Custom Role'),
                      style: FilledButton.styleFrom(backgroundColor: _accent),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                child: Text(
                  'System roles are built-in and cannot be modified. Custom roles are school-specific.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              AppSpacing.vGapLg,

              // Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24,
                      0,
                      isNarrow ? 16 : 24,
                      isNarrow ? 16 : 24,
                    ),
                    child: _buildContent(state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(NonTeachingRolesState state) {
    if (state.isLoading) {
      return AppLoaderScreen();
    }

    if (state.errorMessage != null &&
        state.systemRoles.isEmpty &&
        state.customRoles.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () =>
                    ref.read(nonTeachingRolesProvider.notifier).loadRoles(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.systemRoles.isEmpty && state.customRoles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_accounts_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                'No roles found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (state.errorMessage != null)
          _ErrorBanner(message: state.errorMessage!),

        if (state.systemRoles.isNotEmpty) ...[
          _SectionHeader(
            title: 'System Roles',
            subtitle: 'Built-in roles — read only, cannot be deleted',
            icon: Icons.lock_outline,
          ),
          AppSpacing.vGapSm,
          for (final role in state.systemRoles)
            _RoleCard(
              role: role,
              isSystem: true,
            ),
          AppSpacing.vGapXl,
        ],

        _SectionHeader(
          title: 'Custom School Roles',
          subtitle: 'Roles specific to your school',
          icon: Icons.manage_accounts_outlined,
        ),
        AppSpacing.vGapSm,
        if (state.customRoles.isEmpty)
          _EmptyCustomRoles(onAdd: () => _showRoleDialog(context))
        else
          for (final role in state.customRoles)
            _RoleCard(
              role: role,
              isSystem: false,
              onEdit: () => _showRoleDialog(context, existing: role),
              onToggle: () => _toggleRole(context, role),
              onDelete: () => _deleteRole(context, role),
            ),
      ],
    );
  }

  void _showRoleDialog(BuildContext context,
      {NonTeachingStaffRoleModel? existing}) {
    final codeCtrl =
        TextEditingController(text: existing?.code ?? '');
    final nameCtrl =
        TextEditingController(text: existing?.displayName ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    String category = existing?.category ?? 'GENERAL';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add Custom Role' : 'Edit Role'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role Code *',
                        hintText: 'e.g. SENIOR_CLERK',
                        border: OutlineInputBorder(),
                        helperText: 'Unique identifier — uppercase, no spaces',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) {
                        final upper = v.toUpperCase().replaceAll(' ', '_');
                        if (upper != v) {
                          codeCtrl.value = codeCtrl.value.copyWith(
                            text: upper,
                            selection: TextSelection.collapsed(
                                offset: upper.length),
                          );
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.contains(' ')) return 'No spaces allowed';
                        return null;
                      },
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Display Name *',
                        hintText: 'e.g. Senior Clerk',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    AppSpacing.vGapMd,
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(_categoryLabel(c)),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => category = v!),
                    ),
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: saving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setS(() => saving = true);
                      final body = {
                        'code': codeCtrl.text.trim(),
                        'display_name': nameCtrl.text.trim(),
                        'category': category,
                        if (descCtrl.text.trim().isNotEmpty)
                          'description': descCtrl.text.trim(),
                      };
                      bool ok;
                      if (existing == null) {
                        ok = await ref
                            .read(nonTeachingRolesProvider.notifier)
                            .createRole(body);
                      } else {
                        ok = await ref
                            .read(nonTeachingRolesProvider.notifier)
                            .updateRole(existing.id, body);
                      }
                      if (ctx.mounted) {
                        if (ok) {
                          Navigator.of(ctx).pop();
                        } else {
                          setS(() => saving = false);
                          final err = ref
                              .read(nonTeachingRolesProvider)
                              .errorMessage;
                          AppToast.showError(ctx, err ?? 'An error occurred');
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(existing == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRole(
      BuildContext context, NonTeachingStaffRoleModel role) async {
    final action = role.isActive ? 'Deactivate' : 'Activate';
    final confirmed = await AppDialogs.confirm(
      context,
      title: '$action Role?',
      message: '$action "${role.displayName}"?${role.isActive ? ' Staff with this role will not be selectable.' : ''}',
      confirmLabel: action,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(nonTeachingRolesProvider.notifier).toggleRole(role.id);
  }

  Future<void> _deleteRole(
      BuildContext context, NonTeachingStaffRoleModel role) async {
    if (role.staffCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
              '"${role.displayName}" has ${role.staffCount} staff assigned. Reassign them to another role first.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete Role?',
      message: 'Delete "${role.displayName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(nonTeachingRolesProvider.notifier).deleteRole(role.id);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accent),
        AppSpacing.hGapSm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.neutral400)),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSystem,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });
  final NonTeachingStaffRoleModel role;
  final bool isSystem;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = role.categoryColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(role.categoryIcon, size: 18, color: color),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(role.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      AppSpacing.hGapSm,
                      if (!role.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: AppRadius.brXs,
                          ),
                          child: const Text('Inactive',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.neutral400)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(role.code,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.neutral400)),
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: AppRadius.brXs,
                        ),
                        child: Text(role.categoryLabel,
                            style: TextStyle(
                                fontSize: 10, color: color)),
                      ),
                    ],
                  ),
                  if (role.description != null) ...[
                    const SizedBox(height: 2),
                    Text(role.description!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.neutral400)),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: AppRadius.brLg,
              ),
              child: Text(
                '${role.staffCount}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            if (!isSystem) ...[
              AppSpacing.hGapSm,
              Switch(
                value: role.isActive,
                onChanged: (_) => onToggle?.call(),
                activeThumbColor: _accent,
              ),
              HoverPopupMenu<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    enabled: role.staffCount == 0,
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      enabled: role.staffCount == 0,
                      leading: Icon(
                        Icons.delete_outline,
                        color: role.staffCount > 0
                            ? AppColors.neutral400
                            : AppColors.error500,
                      ),
                      title: Text(
                        role.staffCount > 0
                            ? 'Reassign staff first'
                            : 'Delete',
                        style: TextStyle(
                          color: role.staffCount > 0
                              ? AppColors.neutral400
                              : AppColors.error500,
                        ),
                      ),
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete' && role.staffCount == 0) onDelete?.call();
                },
              ),
            ] else ...[
              AppSpacing.hGapSm,
              const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.neutral400),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCustomRoles extends StatelessWidget {
  const _EmptyCustomRoles({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingXl,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            AppSpacing.vGapMd,
            Text('No custom roles yet',
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapMd,
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Custom Role'),
              style: FilledButton.styleFrom(backgroundColor: _accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withValues(alpha: 0.4),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(message,
          style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13)),
    );
  }
}
