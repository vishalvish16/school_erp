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

import '../../../../widgets/super_admin/dialogs/create_plan_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

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
      maxWidth: kDialogMaxWidthLarge,
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
      maxWidth: kDialogMaxWidthLarge,
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
    final isNarrow = MediaQuery.sizeOf(context).width < AppBreakpoints.formMaxWidth;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section A: Page Header ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg,
              ),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.subscriptionPlans,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        AppStrings.subscriptionPlansSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _openCreatePlan,
                    icon: const Icon(Icons.add, size: AppIconSize.md),
                    label: const Text(AppStrings.createPlan),
                  ),
                ],
              ),
            ),

            // ── Content states ──────────────────────────────────────────────
            if (_loading)
              const Expanded(child: AppLoaderScreen())
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: AppIconSize.xl4, color: scheme.error),
                        AppSpacing.vGapLg,
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.vGapXl,
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: AppIconSize.md),
                          label: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_plans.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_outlined,
                            size: AppIconSize.xl4, color: scheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          AppStrings.noPlansFound,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? AppSpacing.lg : AppSpacing.xl,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // ── Section B: Stats Row ────────────────────────────────
                    _buildSummaryStats(),
                    AppSpacing.vGapXl,

                    // ── Plan Cards Grid ─────────────────────────────────────
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final isWide = innerConstraints.maxWidth >= 400;
                        return Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.lg,
                          children: _plans
                              .map((p) => SizedBox(
                                    width: isWide
                                        ? 320
                                        : innerConstraints.maxWidth,
                                    child: _buildPlanCard(p),
                                  ))
                              .toList(),
                        );
                      },
                    ),

                    // ── Change Log Section ──────────────────────────────────
                    if (_changeLog.isNotEmpty) ...[
                      AppSpacing.vGapXl2,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.planChange,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go('/super-admin/audit-logs'),
                            child: const Text(AppStrings.viewAll),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _changeLog.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (_, i) {
                            final log = _changeLog[i];
                            return _buildChangeLogTile(log);
                          },
                        ),
                      ),
                    ],
                    AppSpacing.vGapXl2,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildSummaryStats() {
    final totalSchools = _plans.fold<int>(0, (sum, p) => sum + p.schoolCount);
    final totalMrr = _plans.fold<double>(0, (sum, p) {
      final mrr = p.mrr > 0 ? p.mrr : (p.pricePerStudent * p.schoolCount * 200);
      return sum + mrr;
    });
    final useRow = MediaQuery.sizeOf(context).width >= AppBreakpoints.formMaxWidth;
    final items = <(IconData, String, String, Color)>[
      (
        Icons.category_outlined,
        '${_plans.length}',
        'Total Plans',
        AppColors.secondary500,
      ),
      (
        Icons.school_outlined,
        '$totalSchools',
        'Total Schools',
        AppColors.success500,
      ),
      (
        Icons.trending_up,
        '\u20B9${totalMrr.toStringAsFixed(0)}',
        'Est. MRR',
        AppColors.warning500,
      ),
    ];
    if (useRow) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: MetricStatCard(
                icon: items[i].$1,
                value: items[i].$2,
                label: items[i].$3,
                color: items[i].$4,
                compact: false,
              ),
            ),
            if (i < items.length - 1) SizedBox(width: AppSpacing.md),
          ],
        ],
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final e = items[i];
          return SizedBox(
            width: 148,
            child: MetricStatCard(
              icon: e.$1,
              value: e.$2,
              label: e.$3,
              color: e.$4,
              compact: true,
            ),
          );
        },
      ),
    );
  }

  // ── Plan Card ─────────────────────────────────────────────────────────────

  String _formatSupportLevel(String? level) {
    if (level == null || level.isEmpty) return AppStrings.standard;
    return level[0].toUpperCase() + level.substring(1).toLowerCase();
  }

  Widget _buildPlanCard(SuperAdminPlanModel p) {
    final isActive = (p.status ?? 'active') == 'active';
    final estMrr = p.mrr > 0 ? p.mrr : (p.pricePerStudent * p.schoolCount * 200);
    final enabledFeatures =
        p.features.entries.where((e) => e.value).map((e) => e.key).toList();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Emoji + Name + Status + Menu
            Row(
              children: [
                Text(p.iconEmoji ?? '\u{1F4E6}',
                    style: textTheme.headlineMedium),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      _buildStatusChip(isActive),
                    ],
                  ),
                ),
                HoverPopupMenu<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openEditPlan(p);
                    else if (v == 'deactivate') _deactivatePlan(p);
                    else if (v == 'activate') _activatePlan(p);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text(AppStrings.edit)),
                    if (isActive)
                      const PopupMenuItem(
                          value: 'deactivate',
                          child: Text(AppStrings.deactivate)),
                    if (!isActive)
                      const PopupMenuItem(
                          value: 'activate',
                          child: Text(AppStrings.activate)),
                  ],
                ),
              ],
            ),

            AppSpacing.vGapLg,

            // Price
            Text(
              '\u20B9${p.pricePerStudent.toStringAsFixed(0)}/student/month',
              style: textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Description
            if (p.description != null && p.description!.isNotEmpty) ...[
              AppSpacing.vGapSm,
              Text(
                p.description!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            AppSpacing.vGapMd,

            // Info chips
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _buildInfoChip(Icons.school, '${p.schoolCount} schools'),
                if (p.maxStudents != null)
                  _buildInfoChip(
                      Icons.people, 'Max ${p.maxStudents} students'),
                _buildInfoChip(Icons.support_agent,
                    _formatSupportLevel(p.supportLevel)),
                _buildInfoChip(Icons.currency_rupee,
                    'MRR \u20B9${estMrr.toStringAsFixed(0)}'),
              ],
            ),

            // Feature chips
            if (enabledFeatures.isNotEmpty) ...[
              AppSpacing.vGapMd,
              Text(
                'Features',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapXs,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: enabledFeatures.take(5).map((f) {
                  final label = f
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) => w.isEmpty
                          ? ''
                          : w[0].toUpperCase() +
                              w.substring(1).toLowerCase())
                      .join(' ');
                  return Chip(
                    label: Text(label),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Status Chip ───────────────────────────────────────────────────────────

  Widget _buildStatusChip(bool isActive) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = isActive ? AppColors.success500 : scheme.onSurfaceVariant;
    final bgColor = isActive
        ? AppColors.success500.withValues(alpha: 0.20)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        isActive
            ? AppStrings.activate.toUpperCase()
            : AppStrings.deactivate.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Info Chip ─────────────────────────────────────────────────────────────

  Widget _buildInfoChip(IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
        AppSpacing.hGapXs,
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  // ── Change Log Tile ───────────────────────────────────────────────────────

  Widget _buildChangeLogTile(SuperAdminAuditLogModel log) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final action = log.action.isEmpty ? AppStrings.planChange : log.action;

    // Determine action badge color
    final (Color badgeColor, Color badgeTextColor) = switch (action.toLowerCase()) {
      final a when a.contains('create') => (
          AppColors.success500.withValues(alpha: 0.20),
          AppColors.success500,
        ),
      final a when a.contains('delete') || a.contains('deactivat') => (
          AppColors.error500.withValues(alpha: 0.20),
          AppColors.error500,
        ),
      _ => (
          AppColors.secondary500.withValues(alpha: 0.20),
          AppColors.secondary500,
        ),
    };

    return ListTile(
      leading: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: AppRadius.brMd,
        ),
        child: Text(
          action.replaceAll('_', ' ').toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: badgeTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
      title: Text(
        log.createdAt.toIso8601String().substring(0, 10),
        style: textTheme.bodyMedium,
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: AppIconSize.md,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
