// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_my_leaves_screen.dart
// PURPOSE: Staff portal — view own leave history and cancel pending leaves.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/school_admin/non_teaching_leave_model.dart';

import '../../../../core/constants/app_strings.dart';

const Color _accent = AppColors.secondary400;

class StaffMyLeavesScreen extends ConsumerStatefulWidget {
  const StaffMyLeavesScreen({super.key});

  @override
  ConsumerState<StaffMyLeavesScreen> createState() =>
      _StaffMyLeavesScreenState();
}

class _StaffMyLeavesScreenState extends ConsumerState<StaffMyLeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];

  List<NonTeachingLeaveModel> _leaves = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _loadLeaves();
    });
    _loadLeaves();
    _loadSummary();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _currentStatus => _statuses[_tab.index];

  Future<void> _loadLeaves() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _currentStatus == 'ALL' ? null : _currentStatus;
      final result = await ref
          .read(schoolAdminServiceProvider)
          .getMyNonTeachingLeaves(status: status);
      final list = result['data'] as List? ??
          result['leaves'] as List? ??
          [];
      if (mounted) {
        setState(() {
          _leaves = list
              .map((e) => NonTeachingLeaveModel.fromJson(
                  e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final result = await ref
          .read(schoolAdminServiceProvider)
          .getMyNonTeachingLeaveSummary();
      if (mounted) setState(() => _summary = result);
    } catch (_) {}
  }

  Future<void> _cancelLeave(NonTeachingLeaveModel leave) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.cancelLeaveQuestion,
      message: 'Are you sure you want to cancel this leave request?',
      confirmLabel: AppStrings.cancelLeave,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .cancelMyLeave(leave.id);
      await _loadLeaves();
      if (mounted) {
        AppSnackbar.success(context, 'Leave cancelled');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _loadLeaves,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Column(
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
                        Text(
                          'My Leaves',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final applied =
                                await context.push('/staff/apply-leave');
                            if (applied == true) _loadLeaves();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(AppStrings.applyLeave),
                          style: FilledButton.styleFrom(
                              backgroundColor: _accent),
                        ),
                      ],
                    ),
                  ),

                  // Summary row
                  if (_summary.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          isNarrow ? 16 : 24, 4, isNarrow ? 16 : 24, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final e in _summary.entries)
                              if (e.value is Map)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8),
                                  child: _BalanceSummaryCard(
                                    type: _leaveLbl(e.key),
                                    data: e.value as Map,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),

                  // Tab bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 8 : 16),
                    child: TabBar(
                      controller: _tab,
                      tabs: _statuses
                          .map((s) => Tab(text: _statusLbl(s)))
                          .toList(),
                      labelColor: _accent,
                      indicatorColor: _accent,
                      isScrollable: true,
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 16 : 24,
                        8,
                        isNarrow ? 16 : 24,
                        isNarrow ? 16 : 24,
                      ),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
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
              Text(_error!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: _loadLeaves,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _currentStatus != 'ALL'
                    ? 'No ${_statusLbl(_currentStatus).toLowerCase()} leaves found'
                    : 'No leave records found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_currentStatus != 'ALL') ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: () {
                    _tab.animateTo(0);
                  },
                  child: const Text(AppStrings.clearFilters),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _leaves.length,
      itemBuilder: (ctx, i) {
        final leave = _leaves[i];
        return _LeaveCard(
          leave: leave,
          onCancel:
              leave.isPending ? () => _cancelLeave(leave) : null,
        );
      },
    );
  }

  String _statusLbl(String s) {
    switch (s) {
      case 'ALL': return 'All';
      case 'PENDING': return 'Pending';
      case 'APPROVED': return 'Approved';
      case 'REJECTED': return 'Rejected';
      default: return s;
    }
  }

  String _leaveLbl(String t) {
    switch (t) {
      case 'CASUAL': return 'Casual';
      case 'SICK': return 'Sick';
      case 'EARNED': return 'Earned';
      case 'MATERNITY': return 'Maternity';
      case 'PATERNITY': return 'Paternity';
      case 'UNPAID': return 'Unpaid';
      case 'COMPENSATORY': return 'Comp.';
      default: return t;
    }
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({required this.type, required this.data});
  final String type;
  final Map data;

  @override
  Widget build(BuildContext context) {
    final taken = data['taken'] ?? 0;
    final total = data['total'] ?? 0;
    final remaining = data['remaining'] ?? 0;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.neutral400)),
          const SizedBox(height: 2),
          Text(
            '$remaining left',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: (remaining as num) > 0
                    ? _accent
                    : AppColors.error500),
          ),
          Text('$taken / $total used',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.neutral400)),
        ],
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave, this.onCancel});
  final NonTeachingLeaveModel leave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () {},
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(
                      label: leave.leaveTypeLabel,
                      color: leave.leaveTypeColor),
                  const Spacer(),
                  _Chip(
                      label: leave.statusLabel,
                      color: leave.statusColor),
                ],
              ),
              AppSpacing.vGapSm,
              Text(
                '${_fmt(leave.fromDate)} – ${_fmt(leave.toDate)}  ·  ${leave.totalDays} day${leave.totalDays != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(leave.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.neutral400)),
              if (leave.adminRemark != null) ...[
                AppSpacing.vGapXs,
                Text(
                  'Admin remark: ${leave.adminRemark}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral400,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning500),
                    child: const Text(AppStrings.cancelLeave),
                  ),
                ),
              ],
            ],
          ),
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
