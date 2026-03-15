// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_alerts_screen.dart
// PURPOSE: Configure alert rules for cross-school metric monitoring.
//          Full CRUD — create, toggle active, edit threshold, delete.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _alertsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.read(groupAdminServiceProvider).getAlertRules();
});

// ── Constants ─────────────────────────────────────────────────────────────────

const _metrics = {
  'attendance_percentage': 'Attendance %',
  'fee_collection_rate': 'Fee Collection Rate %',
  'active_schools_ratio': 'Active Schools Ratio %',
};

const _conditions = {
  'less_than': 'Falls below',
  'greater_than': 'Rises above',
  'equals': 'Equals',
};

// ── Screen ────────────────────────────────────────────────────────────────────

class GroupAdminAlertsScreen extends ConsumerWidget {
  const GroupAdminAlertsScreen({super.key});

  static const Color _accent = AppColors.warning300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_alertsProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_alertsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert Rules',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Get notified when key metrics cross thresholds',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAlertDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.newAlert),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXl,

            // Info banner
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.secondary500.withValues(alpha: 0.08),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.secondary500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.secondary500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alert rules check metrics daily. You will be notified by email when a threshold is crossed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            asyncData.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapMd,
                      const Text(AppStrings.couldNotLoadAlerts),
                      AppSpacing.vGapMd,
                      FilledButton(
                        onPressed: () => ref.invalidate(_alertsProvider),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rules) {
                if (rules.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _showAlertDialog(context, ref),
                  );
                }
                return Column(
                  children: rules.map((r) {
                    final rule = r as Map<String, dynamic>;
                    return _AlertRuleCard(
                      rule: rule,
                      onEdit: () =>
                          _showAlertDialog(context, ref, rule: rule),
                      onToggle: () =>
                          _toggleActive(context, ref, rule),
                      onDelete: () =>
                          _confirmDelete(context, ref, rule['id'] as String),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDialog(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? rule}) {
    showDialog(
      context: context,
      builder: (ctx) => _AlertDialog(
        rule: rule,
        onSaved: () => ref.invalidate(_alertsProvider),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref,
      Map<String, dynamic> rule) async {
    try {
      final currentlyActive =
          rule['isActive'] == true || rule['is_active'] == true;
      await ref.read(groupAdminServiceProvider).updateAlertRule(
            rule['id'] as String,
            {'is_active': !currentlyActive},
          );
      ref.invalidate(_alertsProvider);
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete Alert Rule?',
      message: 'This alert rule will be permanently deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(groupAdminServiceProvider).deleteAlertRule(id);
      ref.invalidate(_alertsProvider);
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed: $e');
      }
    }
  }
}

// ── Alert Rule Card ────────────────────────────────────────────────────────────

class _AlertRuleCard extends StatelessWidget {
  const _AlertRuleCard({
    required this.rule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Map<String, dynamic> rule;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = rule['isActive'] == true || rule['is_active'] == true;
    final metric = rule['metric'] as String? ?? '';
    final condition = rule['condition'] as String? ?? '';
    final threshold = rule['threshold'];
    final notifyEmail =
        rule['notifyEmail'] == true || rule['notify_email'] == true;
    final notifySms =
        rule['notifySms'] == true || rule['notify_sms'] == true;
    final lastTriggered =
        rule['lastTriggered'] ?? rule['last_triggered'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success500 : AppColors.neutral400,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    rule['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.warning300,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(AppStrings.delete,
                          style: TextStyle(color: AppColors.error500)),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              '${_metrics[metric] ?? metric} ${_conditions[condition] ?? condition} $threshold%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (notifyEmail)
                  _Chip(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: AppColors.secondary500,
                  ),
                if (notifySms)
                  _Chip(
                    icon: Icons.sms_outlined,
                    label: 'SMS',
                    color: AppColors.success500,
                  ),
                if (lastTriggered != null)
                  _Chip(
                    icon: Icons.alarm_outlined,
                    label: 'Last: ${_formatDate(lastTriggered.toString())}',
                    color: AppColors.warning500,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${m[d.month - 1]} ${d.day}';
    } catch (_) {
      return '';
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brXs,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          AppSpacing.hGapXs,
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: AppSpacing.xl2),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning300.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  size: 36, color: AppColors.warning300),
            ),
            AppSpacing.vGapLg,
            Text(AppStrings.noAlertRules,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.vGapSm,
            Text(
              'Create alert rules to get notified when key metrics like attendance or fee collection drop below your targets.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.createFirstAlert),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning300,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert Dialog ───────────────────────────────────────────────────────────────

class _AlertDialog extends ConsumerStatefulWidget {
  const _AlertDialog({this.rule, required this.onSaved});

  final Map<String, dynamic>? rule;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AlertDialog> createState() => _AlertDialogState();
}

class _AlertDialogState extends ConsumerState<_AlertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _thresholdCtrl;
  String _metric = 'attendance_percentage';
  String _condition = 'less_than';
  bool _notifyEmail = true;
  bool _notifySms = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameCtrl = TextEditingController(text: r?['name'] ?? '');
    _thresholdCtrl = TextEditingController(
        text: r?['threshold']?.toString() ?? '75');
    if (r != null) {
      _metric = r['metric'] as String? ?? _metric;
      _condition = r['condition'] as String? ?? _condition;
      _notifyEmail = r['notifyEmail'] == true || r['notify_email'] == true;
      _notifySms = r['notifySms'] == true || r['notify_sms'] == true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final svc = ref.read(groupAdminServiceProvider);
    final body = {
      'name': _nameCtrl.text.trim(),
      'metric': _metric,
      'condition': _condition,
      'threshold': double.parse(_thresholdCtrl.text.trim()),
      'notify_email': _notifyEmail,
      'notify_sms': _notifySms,
    };

    try {
      if (widget.rule != null) {
        await svc.updateAlertRule(widget.rule!['id'] as String, body);
      } else {
        await svc.createAlertRule(body);
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rule != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Alert Rule' : 'New Alert Rule'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.ruleNameRequired,
                  border: OutlineInputBorder(),
                  hintText: AppStrings.ruleNameHint,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              AppSpacing.vGapLg,
              DropdownButtonFormField<String>(
                initialValue: _metric,
                decoration: const InputDecoration(
                  labelText: AppStrings.metric,
                  border: OutlineInputBorder(),
                ),
                items: _metrics.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _metric = v ?? _metric),
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _condition,
                      decoration: const InputDecoration(
                        labelText: AppStrings.condition,
                        border: OutlineInputBorder(),
                      ),
                      items: _conditions.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _condition = v ?? _condition),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: TextFormField(
                      controller: _thresholdCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.thresholdPercent,
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = double.tryParse(v);
                        if (n == null) return 'Invalid number';
                        if (n < 0 || n > 100) return '0–100 only';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              CheckboxListTile(
                value: _notifyEmail,
                onChanged: (v) =>
                    setState(() => _notifyEmail = v ?? true),
                title: const Text(AppStrings.notifyViaEmail),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _notifySms,
                onChanged: (v) =>
                    setState(() => _notifySms = v ?? false),
                title: const Text('Notify via SMS'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
