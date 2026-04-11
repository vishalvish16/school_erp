// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_leaves_screen.dart
// PURPOSE: School-wide leave management — 3 tabs: Pending, All Requests, Summary.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/staff_leave_model.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../widgets/common/hover_popup_menu.dart';

import '../../../../core/constants/app_strings.dart';

const Color _accent = AppColors.success500;

// ── Providers ─────────────────────────────────────────────────────────────────

final _pendingLeavesProvider =
    FutureProvider.autoDispose<List<StaffLeaveModel>>((ref) async {
  final raw = await ref
      .read(schoolAdminServiceProvider)
      .getLeaves(status: 'PENDING', limit: 50);
  final data = raw['data'];
  final list = data is Map
      ? (data['data'] as List? ?? data['leaves'] as List? ?? [])
      : data is List
          ? data
          : [];
  return list
      .map((e) =>
          StaffLeaveModel.fromJson(e is Map<String, dynamic> ? e : {}))
      .toList();
});

final _allLeavesProvider = FutureProvider.autoDispose
    .family<List<StaffLeaveModel>, _LeavesFilter>((ref, filter) async {
  final raw = await ref.read(schoolAdminServiceProvider).getLeaves(
        status: filter.status,
        leaveType: filter.leaveType,
        limit: 100,
      );
  final data = raw['data'];
  final list = data is Map
      ? (data['data'] as List? ?? data['leaves'] as List? ?? [])
      : data is List
          ? data
          : [];
  return list
      .map((e) =>
          StaffLeaveModel.fromJson(e is Map<String, dynamic> ? e : {}))
      .toList();
});

final _leaveSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(schoolAdminServiceProvider).getLeaveSummary();
});

class _LeavesFilter {
  final String? status;
  final String? leaveType;
  const _LeavesFilter({this.status, this.leaveType});

  @override
  bool operator ==(Object other) =>
      other is _LeavesFilter &&
      other.status == status &&
      other.leaveType == leaveType;

  @override
  int get hashCode => Object.hash(status, leaveType);
}

// ── Safe error message helper ─────────────────────────────────────────────────

String _safeErrorMessage(Object e) {
  final raw = e.toString();
  final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
  if (msgMatch != null) return msgMatch.group(1)!;
  final cleaned = raw
      .replaceAll('Exception: ', '')
      .replaceAll('DioException [bad response]: ', '');
  if (cleaned.contains('/') || cleaned.contains('\\') || cleaned.length > 200) {
    return 'An error occurred. Please try again.';
  }
  return cleaned;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SchoolAdminLeavesScreen extends ConsumerStatefulWidget {
  const SchoolAdminLeavesScreen({super.key});

  @override
  ConsumerState<SchoolAdminLeavesScreen> createState() =>
      _SchoolAdminLeavesScreenState();
}

class _SchoolAdminLeavesScreenState
    extends ConsumerState<SchoolAdminLeavesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(_pendingLeavesProvider);
    ref.invalidate(_leaveSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/school-admin/staff'),
                  ),
                  Text(
                    'Leave Requests',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.refresh,
                  ),
                ],
              ),
            ),

            // ── Tab bar ──
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'All Requests'),
                Tab(text: 'Summary'),
              ],
            ),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PendingTab(),
                  _AllRequestsTab(),
                  _SummaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Pending ────────────────────────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_pendingLeavesProvider);
    final cs = Theme.of(context).colorScheme;

    return async.when(
      loading: () => AppLoaderScreen(),
      error: (err, _) => Center(
        child: Card(
          margin: AppSpacing.paddingXl,
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                AppSpacing.vGapMd,
                Text(_safeErrorMessage(err), textAlign: TextAlign.center),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () => ref.invalidate(_pendingLeavesProvider),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (leaves) => leaves.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: cs.outline),
                  AppSpacing.vGapLg,
                  Text(AppStrings.noPendingLeaves,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.paddingLg,
              itemCount: leaves.length,
              itemBuilder: (ctx, i) => _PendingLeaveCard(
                leave: leaves[i],
                onReviewed: () => ref.invalidate(_pendingLeavesProvider),
              ),
            ),
    );
  }
}

class _PendingLeaveCard extends ConsumerStatefulWidget {
  const _PendingLeaveCard({required this.leave, required this.onReviewed});
  final StaffLeaveModel leave;
  final VoidCallback onReviewed;

  @override
  ConsumerState<_PendingLeaveCard> createState() =>
      _PendingLeaveCardState();
}

class _PendingLeaveCardState extends ConsumerState<_PendingLeaveCard> {
  bool _loading = false;

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.leave;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.staffName ?? 'Unknown Staff',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    HoverPopupMenu<String>(
                      icon: const Icon(Icons.more_vert, size: 22),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'approve',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle_outline,
                                color: AppColors.success500),
                            title: Text(AppStrings.approve),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reject',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.cancel_outlined,
                                color: AppColors.error500),
                            title: Text(AppStrings.reject,
                                style: const TextStyle(
                                    color: AppColors.error500)),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.visibility_outlined),
                            title: const Text('View Details'),
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'approve') _review('APPROVED');
                        if (v == 'reject') _showRejectDialog();
                      },
                    ),
                ],
              ),
              AppSpacing.vGapXs,
              Text(
                '${l.leaveType} · ${_fmtDate(l.fromDate)} - ${_fmtDate(l.toDate)} (${l.totalDays} day${l.totalDays == 1 ? '' : 's'})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  _LeaveStatusChip(status: l.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _review(String status, {String? remark}) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(schoolAdminServiceProvider)
          .reviewLeave(widget.leave.id, status, adminRemark: remark);
      widget.onReviewed();
      if (mounted) {
        AppToast.showSuccess(context, status == 'APPROVED' ? 'Leave approved' : 'Leave rejected');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, _safeErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRejectDialog() async {
    final remarkCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reject Leave Request',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapMd,
              TextFormField(
                controller: remarkCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.reasonForRejection,
                  hintText: AppStrings.optionalRemarkStaff,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              AppSpacing.vGapMd,
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _review('REJECTED', remark: remarkCtrl.text.trim());
                },
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error500),
                child: Text(AppStrings.confirmRejection),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 2: All Requests ───────────────────────────────────────────────────────

class _AllRequestsTab extends ConsumerStatefulWidget {
  const _AllRequestsTab();

  @override
  ConsumerState<_AllRequestsTab> createState() => _AllRequestsTabState();
}

class _AllRequestsTabState extends ConsumerState<_AllRequestsTab> {
  String? _statusFilter;
  String? _leaveTypeFilter;

  static const _statuses = [
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED',
  ];

  static const _leaveTypes = [
    'CASUAL',
    'SICK',
    'EARNED',
    'MATERNITY',
    'PATERNITY',
    'UNPAID',
    'OTHER',
  ];

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  bool get _hasFilters => _statusFilter != null || _leaveTypeFilter != null;

  @override
  Widget build(BuildContext context) {
    final filter = _LeavesFilter(
        status: _statusFilter, leaveType: _leaveTypeFilter);
    final async = ref.watch(_allLeavesProvider(filter));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Filter bar
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding:
              EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(AppStrings.statusColon,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                _FilterChip(
                  label: AppStrings.all,
                  selected: _statusFilter == null,
                  onTap: () =>
                      setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 6),
                ..._statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        label: s,
                        selected: _statusFilter == s,
                        color: _statusColor(s),
                        onTap: () => setState(() => _statusFilter = s),
                      ),
                    )),
              ],
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding:
              EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(AppStrings.typeColon,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                _FilterChip(
                  label: AppStrings.all,
                  selected: _leaveTypeFilter == null,
                  onTap: () =>
                      setState(() => _leaveTypeFilter = null),
                ),
                const SizedBox(width: 6),
                ..._leaveTypes.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        label: t,
                        selected: _leaveTypeFilter == t,
                        onTap: () =>
                            setState(() => _leaveTypeFilter = t),
                      ),
                    )),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => AppLoaderScreen(),
            error: (err, _) => Center(
              child: Card(
                margin: AppSpacing.paddingXl,
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      AppSpacing.vGapMd,
                      Text(_safeErrorMessage(err),
                          textAlign: TextAlign.center),
                      AppSpacing.vGapLg,
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(_allLeavesProvider(filter)),
                        child: Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (leaves) => leaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 64, color: cs.outline),
                        AppSpacing.vGapLg,
                        Text(AppStrings.noLeaveRequestsFound,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (_hasFilters) ...[
                          AppSpacing.vGapSm,
                          TextButton(
                            onPressed: () => setState(() {
                              _statusFilter = null;
                              _leaveTypeFilter = null;
                            }),
                            child: Text(AppStrings.clearFilters),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.paddingLg,
                    itemCount: leaves.length,
                    itemBuilder: (ctx, i) {
                      final l = leaves[i];
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(l.status)
                                .withValues(alpha: 0.15),
                            child: Icon(Icons.event,
                                color: _statusColor(l.status),
                                size: 20),
                          ),
                          title: Text(
                            l.staffName ?? 'Unknown Staff',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${l.leaveType} • ${_fmtDate(l.fromDate)} — ${_fmtDate(l.toDate)}'),
                              Text('${l.totalDays} day(s)',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.neutral400)),
                            ],
                          ),
                          trailing: _LeaveStatusChip(
                              status: l.status),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success500;
      case 'REJECTED':
        return AppColors.error500;
      case 'CANCELLED':
        return AppColors.neutral400;
      default:
        return AppColors.warning500;
    }
  }
}

// ── Tab 3: Summary ────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_leaveSummaryProvider);
    final cs = Theme.of(context).colorScheme;

    return async.when(
      loading: () => AppLoaderScreen(),
      error: (err, _) => Center(
        child: Card(
          margin: AppSpacing.paddingXl,
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                AppSpacing.vGapMd,
                Text(_safeErrorMessage(err), textAlign: TextAlign.center),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () => ref.invalidate(_leaveSummaryProvider),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_leaveSummaryProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.leaveOverview,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.vGapMd,
              GridView.count(
                crossAxisCount:
                    MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    label: AppStrings.total,
                    value: '${summary['total'] ?? 0}',
                    color: AppColors.info500,
                    icon: Icons.summarize,
                  ),
                  _StatCard(
                    label: AppStrings.pending,
                    value: '${summary['pending'] ?? 0}',
                    color: AppColors.warning500,
                    icon: Icons.hourglass_empty,
                  ),
                  _StatCard(
                    label: AppStrings.approved,
                    value: '${summary['approved'] ?? 0}',
                    color: AppColors.success500,
                    icon: Icons.check_circle,
                  ),
                  _StatCard(
                    label: AppStrings.rejected,
                    value: '${summary['rejected'] ?? 0}',
                    color: AppColors.error500,
                    icon: Icons.cancel,
                  ),
                  _StatCard(
                    label: AppStrings.cancelled,
                    value: '${summary['cancelled'] ?? 0}',
                    color: AppColors.neutral400,
                    icon: Icons.event_busy,
                  ),
                ],
              ),
              if (summary['byType'] is Map) ...[
                const SizedBox(height: 20),
                Text(AppStrings.byLeaveType,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AppSpacing.vGapMd,
                ...(summary['byType'] as Map).entries.map((e) {
                  final type = e.key.toString();
                  final count = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.label_outline,
                          color: _accent, size: 18),
                      title: Text(type),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: AppRadius.brLg,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.neutral400)),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _LeaveStatusChip extends StatelessWidget {
  const _LeaveStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = AppColors.success500;
      case 'REJECTED':
        color = AppColors.error500;
      case 'CANCELLED':
        color = AppColors.neutral400;
      default:
        color = AppColors.warning500;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadius.brXl,
          border: Border.all(
            color: selected
                ? effectiveColor
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? effectiveColor
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
