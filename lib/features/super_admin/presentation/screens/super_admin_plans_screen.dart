// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_plans_screen.dart
// PURPOSE: Super Admin plans — Create, Edit, Deactivate, Activate, change log
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/super_admin/dialogs/create_plan_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../design_system/design_system.dart';

class SuperAdminPlansScreen extends ConsumerStatefulWidget {
  const SuperAdminPlansScreen({super.key});

  @override
  ConsumerState<SuperAdminPlansScreen> createState() =>
      _SuperAdminPlansScreenState();
}

class _SuperAdminPlansScreenState extends ConsumerState<SuperAdminPlansScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminPlanModel> _plans = [];
  List<SuperAdminAuditLogModel> _changeLog = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 500) {
        return 'Server error. Please try again later or contact support.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'You don\'t have permission to view plans.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Connection failed. Check your network and try again.';
      }
      final msg = e.response?.data?['message'] ?? e.message;
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final plans = await service.getPlans();
      List<SuperAdminAuditLogModel> log = [];
      try {
        final result = await service.getAuditLogs('plans', limit: 10);
        log = result.data;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _plans = plans;
          _changeLog = log;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatError(e);
          _loading = false;
          _plans = [];
        });
      }
    }
  }

  void _openCreatePlan() {
    showAdaptiveModal(
      context,
      CreateEditPlanDialog(
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).createPlan(body);
          if (mounted) _load();
        },
      ),
    );
  }

  void _openEditPlan(SuperAdminPlanModel p) {
    showAdaptiveModal(
      context,
      CreateEditPlanDialog(
        plan: p,
        onSave: (body) async {
          await ref.read(superAdminServiceProvider).updatePlan(p.id, body);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _deactivatePlan(SuperAdminPlanModel p) async {
    final count = p.schoolCount;
    if (count > 0) {
      final ok = await AppDialogs.confirm(
        context,
        title: AppStrings.deactivatePlanQuestion,
        message: '$count schools are on ${p.name}. Deactivating prevents new assignments but won\'t affect existing.',
        confirmLabel: AppStrings.deactivateAnyway,
      );
      if (!ok || !mounted) return;
    }
    try {
      await ref.read(superAdminServiceProvider).updatePlanStatus(p.id, 'inactive');
      if (mounted) {
        _load();
        AppSnackbar.success(context, AppStrings.planDeactivated);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _activatePlan(SuperAdminPlanModel p) async {
    try {
      await ref.read(superAdminServiceProvider).updatePlanStatus(p.id, 'active');
      if (mounted) {
        _load();
        AppSnackbar.success(context, AppStrings.planActivated);
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
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Plans & Pricing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  FilledButton.icon(
                    onPressed: _openCreatePlan,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(AppStrings.createPlan),
                  ),
                ],
              ),
            ),
            if (_loading)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: const ShimmerListLoadingWidget(itemCount: 8),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Card(
                    margin: EdgeInsets.all(padding),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else if (_plans.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(AppStrings.noPlansFound, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildSummaryStats(),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final isWide = innerConstraints.maxWidth >= 400;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _plans.map((p) => SizedBox(
                            width: isWide ? 320 : innerConstraints.maxWidth,
                            child: _buildPlanCard(p),
                          )).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_changeLog.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan Change Log',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/super-admin/audit-logs'),
                            child: const Text(AppStrings.viewAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _changeLog.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final log = _changeLog[i];
                            return ListTile(
                              title: Text(log.action.isEmpty ? AppStrings.planChange : log.action),
                              subtitle: Text(log.createdAt.toIso8601String().substring(0, 10)),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalSchools = _plans.fold<int>(0, (sum, p) => sum + p.schoolCount);
    final totalMrr = _plans.fold<double>(0, (sum, p) {
      final mrr = p.mrr > 0 ? p.mrr : (p.pricePerStudent * p.schoolCount * 200);
      return sum + mrr;
    });
    final isWide = MediaQuery.of(context).size.width >= 600;
    final chips = [
      _buildStatChip(icon: Icons.category_outlined, label: 'Total Plans', value: '${_plans.length}'),
      _buildStatChip(icon: Icons.school_outlined, label: 'Total Schools', value: '$totalSchools'),
      _buildStatChip(icon: Icons.trending_up, label: 'Est. MRR', value: '₹${totalMrr.toStringAsFixed(0)}'),
    ];
    if (isWide) {
      return Row(
        children: chips.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(right: e.key < chips.length - 1 ? 16 : 0),
            child: e.value,
          );
        }).toList(),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: chips,
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSupportLevel(String? level) {
    if (level == null || level.isEmpty) return AppStrings.standard;
    return level[0].toUpperCase() + level.substring(1).toLowerCase();
  }

  Widget _buildPlanCard(SuperAdminPlanModel p) {
    final isActive = (p.status ?? 'active') == 'active';
    final estMrr = p.mrr > 0 ? p.mrr : (p.pricePerStudent * p.schoolCount * 200);
    final enabledFeatures = p.features.entries.where((e) => e.value).map((e) => e.key).toList();
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.iconEmoji ?? '📦', style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: AppRadius.brLg,
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _openEditPlan(p);
                      } else if (v == 'deactivate') _deactivatePlan(p);
                      else if (v == 'activate') _activatePlan(p);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
                      if (isActive)
                        const PopupMenuItem(value: 'deactivate', child: Text(AppStrings.deactivate)),
                      if (!isActive)
                        const PopupMenuItem(value: 'activate', child: Text(AppStrings.activate)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '₹${p.pricePerStudent.toStringAsFixed(0)}/student/month',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (p.description != null && p.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  p.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.school, '${p.schoolCount} schools'),
                  if (p.maxStudents != null)
                    _buildInfoChip(Icons.people, 'Max ${p.maxStudents} students'),
                  _buildInfoChip(Icons.support_agent, _formatSupportLevel(p.supportLevel)),
                  _buildInfoChip(Icons.currency_rupee, 'MRR ₹${estMrr.toStringAsFixed(0)}'),
                ],
              ),
              if (enabledFeatures.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: enabledFeatures.take(5).map((f) {
                    final label = f.replaceAll('_', ' ').split(' ').map((w) =>
                        w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
                    return Chip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _openEditPlan(p),
                    tooltip: 'Edit',
                  ),
                  if (isActive)
                    IconButton(
                      icon: const Icon(Icons.pause, size: 20),
                      onPressed: () => _deactivatePlan(p),
                      tooltip: 'Deactivate',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      onPressed: () => _activatePlan(p),
                      tooltip: 'Activate',
                    ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
