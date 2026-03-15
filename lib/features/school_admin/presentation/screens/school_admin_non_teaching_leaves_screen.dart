// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_leaves_screen.dart
// PURPOSE: Admin view of non-teaching staff leaves with approve/reject actions.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../providers/school_admin_non_teaching_leaves_provider.dart';
import '../../../../models/school_admin/non_teaching_leave_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class SchoolAdminNonTeachingLeavesScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingLeavesScreen({super.key});

  @override
  ConsumerState<SchoolAdminNonTeachingLeavesScreen> createState() =>
      _State();
}

class _State
    extends ConsumerState<SchoolAdminNonTeachingLeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _statuses = [
    'ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        ref
            .read(nonTeachingLeavesProvider.notifier)
            .setStatusFilter(_statuses[_tab.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nonTeachingLeavesProvider.notifier).loadLeaves();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nonTeachingLeavesProvider);
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(nonTeachingLeavesProvider.notifier)
          .loadLeaves(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.all(isNarrow ? 16.0 : 24.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Non-Teaching Staff Leaves',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (state.total > 0)
                    Text('${state.total} records',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),

            // ── Tab bar ──
            TabBar(
              controller: _tab,
              tabs: _statuses
                  .map((s) => Tab(text: _statusLabel(s)))
                  .toList(),
              labelColor: _accent,
              indicatorColor: _accent,
              isScrollable: true,
              padding: AppSpacing.paddingHLg,
            ),

            // ── Content ──
            Expanded(
              child: state.isLoading
                  ? const ShimmerListLoadingWidget(itemCount: 8)
                  : state.errorMessage != null
                      ? Center(
                          child: Card(
                            margin: AppSpacing.paddingXl,
                            child: Padding(
                              padding: AppSpacing.paddingXl,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: cs.error),
                                  AppSpacing.vGapMd,
                                  Text(state.errorMessage!,
                                      textAlign: TextAlign.center),
                                  AppSpacing.vGapLg,
                                  FilledButton(
                                    onPressed: () => ref
                                        .read(nonTeachingLeavesProvider
                                            .notifier)
                                        .loadLeaves(refresh: true),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : state.leaves.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_busy_outlined,
                                      size: 64, color: cs.outline),
                                  AppSpacing.vGapLg,
                                  Text(
                                    state.statusFilter == 'ALL'
                                        ? 'No leave requests yet'
                                        : 'No ${_statusLabel(state.statusFilter).toLowerCase()} leaves',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  if (state.statusFilter != 'ALL') ...[
                                    AppSpacing.vGapSm,
                                    TextButton(
                                      onPressed: () {
                                        _tab.animateTo(0);
                                        ref
                                            .read(nonTeachingLeavesProvider
                                                .notifier)
                                            .setStatusFilter('ALL');
                                      },
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: AppSpacing.paddingLg,
                              itemCount: state.leaves.length,
                              itemBuilder: (ctx, i) => _LeaveCard(
                                leave: state.leaves[i],
                                onApprove: state.leaves[i].isPending
                                    ? () => _approve(
                                        context, state.leaves[i].id)
                                    : null,
                                onReject: state.leaves[i].isPending
                                    ? () => _reject(
                                        context, state.leaves[i].id)
                                    : null,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'ALL': return 'All';
      case 'PENDING': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      case 'CANCELLED': return 'Cancelled';
      default: return s;
    }
  }

  Future<void> _approve(BuildContext context, String leaveId) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Approve Leave?',
      message: 'This leave request will be approved.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref
        .read(nonTeachingLeavesProvider.notifier)
        .reviewLeave(leaveId, 'APPROVED');
    if (context.mounted) {
      if (ok) {
        AppSnackbar.success(context, 'Leave approved');
      } else {
        AppSnackbar.error(context, 'Failed to approve');
      }
    }
  }

  Future<void> _reject(BuildContext context, String leaveId) async {
    final remarkCtrl = TextEditingController();
    String? remark;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reject Leave',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              AppSpacing.vGapLg,
              TextField(
                controller: remarkCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => remark = v.trim(),
              ),
              AppSpacing.vGapLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error500),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(nonTeachingLeavesProvider.notifier)
        .reviewLeave(leaveId, 'REJECTED',
            adminRemark: remark);
    if (context.mounted) {
      if (ok) {
        AppSnackbar.warning(context, 'Leave rejected');
      } else {
        AppSnackbar.error(context, 'Failed to reject');
      }
    }
  }
}

// ── Leave card ────────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    this.onApprove,
    this.onReject,
  });
  final NonTeachingLeaveModel leave;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        leave.staffName ?? 'Staff',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      if (leave.employeeNo != null)
                        Text(leave.employeeNo!,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.neutral400)),
                      if (leave.roleName != null)
                        Text(leave.roleName!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.neutral400)),
                    ],
                  ),
                ),
                _Chip(
                  label: leave.statusLabel,
                  color: leave.statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _Chip(
                    label: leave.leaveTypeLabel,
                    color: leave.leaveTypeColor),
                AppSpacing.hGapSm,
                Text(
                  '${_fmt(leave.fromDate)} – ${_fmt(leave.toDate)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
                AppSpacing.hGapSm,
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Text(
                    '${leave.totalDays} day${leave.totalDays != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,

            Text(
              leave.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral400),
            ),

            if (leave.adminRemark != null) ...[
              const SizedBox(height: 6),
              Text(
                'Remark: ${leave.adminRemark}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral400,
                    fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error500,
                          side: const BorderSide(color: AppColors.error500)),
                      child: const Text('Reject'),
                    ),
                  AppSpacing.hGapSm,
                  if (onApprove != null)
                    FilledButton(
                      onPressed: onApprove,
                      style:
                          FilledButton.styleFrom(backgroundColor: _accent),
                      child: const Text('Approve'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}
