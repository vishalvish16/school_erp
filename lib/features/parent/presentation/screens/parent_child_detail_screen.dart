// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_detail_screen.dart
// PURPOSE: Full tabbed child detail screen for Parent Portal.
//          7 tabs: Overview, Attendance, Fees, Timetable, Notices, Documents, Bus
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/parent_service.dart';
import '../../../../models/parent/parent_models.dart';
import '../../data/parent_child_detail_provider.dart';
import '../../data/parent_child_attendance_provider.dart';
import '../../data/parent_child_fees_provider.dart';

class ParentChildDetailScreen extends ConsumerWidget {
  const ParentChildDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(parentChildDetailProvider(studentId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: asyncChild.when(
        loading: () => AppLoaderScreen(),
        error: (err, _) => _ErrorView(
          error: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(parentChildDetailProvider(studentId)),
        ),
        data: (child) {
          if (child == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off,
                      size: AppIconSize.xl3, color: scheme.error),
                  AppSpacing.vGapMd,
                  Text(AppStrings.notFoundError,
                      style: AppTextStyles.body(color: scheme.onSurface)),
                  AppSpacing.vGapMd,
                  TextButton(
                    onPressed: () => context.go('/parent/children'),
                    child: Text(AppStrings.back),
                  ),
                ],
              ),
            );
          }
          return _ChildDetailBody(child: child, studentId: studentId);
        },
      ),
    );
  }
}

// =============================================================================
// MAIN BODY — Header + TabBar + TabBarView
// =============================================================================

class _ChildDetailBody extends ConsumerWidget {
  const _ChildDetailBody({required this.child, required this.studentId});

  final ChildDetailModel child;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return DefaultTabController(
      length: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
            child: _ChildHeader(child: child, studentId: studentId),
          ),

          // ── TabBar ────────────────────────────────────────────────────
          TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary500,
            labelColor: AppColors.primary500,
            unselectedLabelColor: scheme.onSurfaceVariant,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_outlined, size: AppIconSize.sm),
                text: AppStrings.tabOverview,
              ),
              Tab(
                icon: Icon(Icons.calendar_today_outlined, size: AppIconSize.sm),
                text: AppStrings.tabAttendance,
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined,
                    size: AppIconSize.sm),
                text: AppStrings.tabFees,
              ),
              Tab(
                icon: Icon(Icons.schedule_outlined, size: AppIconSize.sm),
                text: AppStrings.tabTimetable,
              ),
              Tab(
                icon: Icon(Icons.campaign_outlined, size: AppIconSize.sm),
                text: AppStrings.tabNotices,
              ),
              Tab(
                icon: Icon(Icons.folder_outlined, size: AppIconSize.sm),
                text: AppStrings.tabDocuments,
              ),
              Tab(
                icon: Icon(Icons.directions_bus_outlined, size: AppIconSize.sm),
                text: AppStrings.tabBus,
              ),
            ],
          ),

          // ── TabBarView ────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(child: child),
                _AttendanceTab(studentId: studentId),
                _FeesTab(studentId: studentId),
                _TimetableTab(studentId: studentId),
                _NoticesTab(studentId: studentId),
                _DocumentsTab(studentId: studentId),
                _BusTab(studentId: studentId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CHILD HEADER — Photo, name, class, admission no
// =============================================================================

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.child, required this.studentId});

  final ChildDetailModel child;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/parent/children'),
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.back,
        ),
        AppSpacing.hGapSm,
        CircleAvatar(
          radius: AppSpacing.xl,
          backgroundColor: AppColors.primary500.withValues(alpha: AppOpacity.focus),
          backgroundImage:
              child.photoUrl != null ? NetworkImage(child.photoUrl!) : null,
          child: child.photoUrl == null
              ? Text(
                  child.fullName.isNotEmpty
                      ? child.fullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.h5(color: AppColors.primary500),
                )
              : null,
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.fullName,
                  style: AppTextStyles.h5(color: scheme.onSurface)),
              Text(
                '${child.classSection}  |  ${child.admissionNo}',
                style:
                    AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        OutlinedButton.icon(
          onPressed: () => context.go('/parent/children/$studentId/update-profile'),
          icon: Icon(Icons.edit_outlined, size: AppIconSize.sm),
          label: Text(AppStrings.requestProfileUpdate),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary500,
            side: BorderSide(color: AppColors.primary500, width: AppBorderWidth.thin),
            shape: AppRadius.chipShape,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 1 — OVERVIEW
// =============================================================================

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({required this.child});
  final ChildDetailModel child;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  AttendanceSummaryModel? _summary;
  Map<String, dynamic>? _fees;
  List<AttendanceEntryModel>? _recentDays;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(parentServiceProvider);
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        service.getChildAttendanceSummary(widget.child.id, month: month),
        service.getChildFees(widget.child.id),
        service.getChildAttendance(widget.child.id, month: month, limit: 7),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as AttendanceSummaryModel;
        _fees = results[1] as Map<String, dynamic>;
        _recentDays = results[2] as List<AttendanceEntryModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(_error!,
                style: AppTextStyles.body(color: scheme.onSurface),
                textAlign: TextAlign.center),
            AppSpacing.vGapMd,
            FilledButton(
                onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    final summary = _summary;
    final feeStructure =
        _fees?['feeStructure'] as List<FeeStructureSummaryModel>? ?? [];
    final totalDue = feeStructure.fold<double>(
      0,
      (sum, s) => sum + (double.tryParse(s.amount) ?? 0),
    );

    return SingleChildScrollView(
      padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat cards ──────────────────────────────────────────
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _StatCard(
                    label: AppStrings.presentCount,
                    value: '${summary?.present ?? 0}',
                    color: AppColors.success600,
                    icon: Icons.check_circle_outline,
                  ),
                  _StatCard(
                    label: AppStrings.absentCount,
                    value: '${summary?.absent ?? 0}',
                    color: AppColors.error600,
                    icon: Icons.cancel_outlined,
                  ),
                  _StatCard(
                    label: AppStrings.attendancePercent,
                    value:
                        '${summary?.attendancePercent.toStringAsFixed(1) ?? '0'}%',
                    color: AppColors.info600,
                    icon: Icons.pie_chart_outline,
                  ),
                  _StatCard(
                    label: AppStrings.feeDue,
                    value: totalDue > 0 ? '₹${totalDue.toStringAsFixed(0)}' : '₹0',
                    color: AppColors.warning600,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
              AppSpacing.vGapXl,

              // ── Quick actions ───────────────────────────────────────
              Text(AppStrings.quickActions,
                  style: AppTextStyles.h6(color: scheme.onSurface)),
              AppSpacing.vGapMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _QuickActionChip(
                    label: AppStrings.viewTimetable,
                    icon: Icons.schedule_outlined,
                    onTap: () => DefaultTabController.of(context).animateTo(3),
                  ),
                  _QuickActionChip(
                    label: AppStrings.viewNotices,
                    icon: Icons.campaign_outlined,
                    onTap: () => DefaultTabController.of(context).animateTo(4),
                  ),
                  _QuickActionChip(
                    label: AppStrings.trackBus,
                    icon: Icons.directions_bus_outlined,
                    onTap: () => DefaultTabController.of(context).animateTo(6),
                  ),
                ],
              ),
              AppSpacing.vGapXl,

              // ── Recent attendance ───────────────────────────────────
              Text(AppStrings.recentAttendance,
                  style: AppTextStyles.h6(color: scheme.onSurface)),
              AppSpacing.vGapXs,
              Text(AppStrings.last7Days,
                  style: AppTextStyles.bodySm(
                      color: scheme.onSurfaceVariant)),
              AppSpacing.vGapMd,
              if (_recentDays != null && _recentDays!.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _recentDays!.map((e) {
                    return _AttendanceDayChip(entry: e);
                  }).toList(),
                )
              else
                Text(
                  AppStrings.noAttendanceData,
                  style: AppTextStyles.bodySm(
                      color: scheme.onSurfaceVariant),
                ),
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: Card(
        shape: AppRadius.cardShape,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppIconSize.lg, color: color),
              AppSpacing.vGapSm,
              Text(value,
                  style: AppTextStyles.h4(color: scheme.onSurface)),
              AppSpacing.vGapXs,
              Text(label,
                  style: AppTextStyles.bodySm(
                      color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: AppIconSize.sm, color: AppColors.primary500),
      label: Text(label, style: AppTextStyles.bodySm(color: AppColors.primary500)),
      onPressed: onTap,
      side: BorderSide(
        color: AppColors.primary500.withValues(alpha: AppOpacity.medium),
        width: AppBorderWidth.thin,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
    );
  }
}

class _AttendanceDayChip extends StatelessWidget {
  const _AttendanceDayChip({required this.entry});
  final AttendanceEntryModel entry;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[entry.date.weekday - 1];

    Color bg;
    Color fg;
    switch (entry.status.toUpperCase()) {
      case 'PRESENT':
        bg = AppColors.success100;
        fg = AppColors.success700;
      case 'ABSENT':
        bg = AppColors.error100;
        fg = AppColors.error700;
      case 'LATE':
        bg = AppColors.warning100;
        fg = AppColors.warning700;
      case 'HOLIDAY':
        bg = AppColors.neutral200;
        fg = AppColors.neutral600;
      default:
        bg = AppColors.neutral100;
        fg = AppColors.neutral500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brMd),
      child: Text(
        '$dayName ${entry.status[0]}',
        style: AppTextStyles.caption(color: fg),
      ),
    );
  }
}

// =============================================================================
// TAB 2 — ATTENDANCE
// =============================================================================

class _AttendanceTab extends ConsumerStatefulWidget {
  const _AttendanceTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  late String _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncAttendance = ref.watch(
      parentChildAttendanceProvider(
          (studentId: widget.studentId, month: _month)),
    );
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return SingleChildScrollView(
      padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month picker
              Row(
                children: [
                  Text(AppStrings.monthlyAttendance,
                      style: AppTextStyles.h6(color: scheme.onSurface)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _month,
                    items: _buildMonthItems(),
                    onChanged: (v) {
                      if (v != null) setState(() => _month = v);
                    },
                  ),
                ],
              ),
              AppSpacing.vGapLg,

              asyncAttendance.when(
                loading: () =>
                    AppLoaderScreen(),
                error: (err, _) => Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: AppIconSize.xl3, color: scheme.error),
                      AppSpacing.vGapMd,
                      Text(
                          err.toString().replaceAll('Exception: ', ''),
                          style:
                              AppTextStyles.body(color: scheme.onSurface)),
                      AppSpacing.vGapMd,
                      FilledButton(
                        onPressed: () => ref.invalidate(
                          parentChildAttendanceProvider(
                            (
                              studentId: widget.studentId,
                              month: _month,
                            ),
                          ),
                        ),
                        child: Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          AppSpacing.vGapXl,
                          Icon(Icons.event_busy,
                              size: AppIconSize.xl3, color: scheme.outline),
                          AppSpacing.vGapMd,
                          Text(AppStrings.noAttendanceData,
                              style: AppTextStyles.body(
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  // Stats summary
                  final presentCount =
                      list.where((e) => e.status == 'PRESENT').length;
                  final absentCount =
                      list.where((e) => e.status == 'ABSENT').length;
                  final lateCount =
                      list.where((e) => e.status == 'LATE').length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          _MiniStat(
                              label: AppStrings.present,
                              value: '$presentCount',
                              color: AppColors.success600),
                          _MiniStat(
                              label: AppStrings.absent,
                              value: '$absentCount',
                              color: AppColors.error600),
                          _MiniStat(
                              label: AppStrings.late,
                              value: '$lateCount',
                              color: AppColors.warning600),
                        ],
                      ),
                      AppSpacing.vGapXl,

                      // Calendar grid
                      Text(AppStrings.attendanceCalendar,
                          style:
                              AppTextStyles.h6(color: scheme.onSurface)),
                      AppSpacing.vGapMd,
                      _AttendanceCalendar(entries: list, month: _month),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildMonthItems() {
    final now = DateTime.now();
    final items = <DropdownMenuItem<String>>[];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i);
      final v = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      items.add(DropdownMenuItem(value: v, child: Text(_formatMonth(v))));
    }
    return items;
  }

  String _formatMonth(String yyyyMm) {
    final parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${months[m - 1]} ${parts[0]}';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.pressed),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: color.withValues(alpha: AppOpacity.medium),
          width: AppBorderWidth.thin,
        ),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h5(color: color)),
          Text(label,
              style: AppTextStyles.bodySm(color: color)),
        ],
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar({required this.entries, required this.month});

  final List<AttendanceEntryModel> entries;
  final String month;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final mon = int.tryParse(parts[1]) ?? DateTime.now().month;
    final daysInMonth = DateTime(year, mon + 1, 0).day;
    final firstWeekday = DateTime(year, mon, 1).weekday; // 1=Mon

    // Map date -> status
    final statusMap = <int, String>{};
    for (final e in entries) {
      if (e.date.month == mon && e.date.year == year) {
        statusMap[e.date.day] = e.status;
      }
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();

    return Column(
      children: [
        // Day headers
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: AppTextStyles.caption(
                              color: scheme.onSurfaceVariant)),
                    ),
                  ))
              .toList(),
        ),
        AppSpacing.vGapSm,
        // Calendar cells
        ...List.generate(6, (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: List.generate(7, (col) {
                final dayNum =
                    week * 7 + col + 1 - (firstWeekday - 1);
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox.shrink());
                }

                final isFuture = DateTime(year, mon, dayNum)
                    .isAfter(today);
                final status = statusMap[dayNum];
                final isWeekend = col >= 5;

                Color cellBg;
                Color cellFg;
                if (isFuture) {
                  cellBg = Colors.transparent;
                  cellFg = scheme.onSurfaceVariant
                      .withValues(alpha: AppOpacity.disabled);
                } else if (status != null) {
                  switch (status.toUpperCase()) {
                    case 'PRESENT':
                      cellBg = AppColors.success100;
                      cellFg = AppColors.success700;
                    case 'ABSENT':
                      cellBg = AppColors.error100;
                      cellFg = AppColors.error700;
                    case 'LATE':
                      cellBg = AppColors.warning100;
                      cellFg = AppColors.warning700;
                    case 'HOLIDAY':
                      cellBg = AppColors.neutral200;
                      cellFg = AppColors.neutral600;
                    default:
                      cellBg = AppColors.neutral100;
                      cellFg = AppColors.neutral500;
                  }
                } else if (isWeekend) {
                  cellBg = AppColors.neutral100;
                  cellFg = AppColors.neutral500;
                } else {
                  cellBg = Colors.transparent;
                  cellFg = scheme.onSurface;
                }

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.xs / 2),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: cellBg,
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: AppTextStyles.bodySm(color: cellFg),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
        AppSpacing.vGapMd,
        // Legend
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendDot(color: AppColors.success100, label: AppStrings.present),
            _LegendDot(color: AppColors.error100, label: AppStrings.absent),
            _LegendDot(color: AppColors.warning100, label: AppStrings.late),
            _LegendDot(color: AppColors.neutral200, label: AppStrings.holiday),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.brXs,
          ),
        ),
        AppSpacing.hGapXs,
        Text(label,
            style: AppTextStyles.bodySm(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// =============================================================================
// TAB 3 — FEES
// =============================================================================

class _FeesTab extends ConsumerWidget {
  const _FeesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncFees = ref.watch(
      parentChildFeesProvider((studentId: studentId, academicYear: null)),
    );
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return asyncFees.when(
      loading: () => AppLoaderScreen(),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(err.toString().replaceAll('Exception: ', ''),
                style: AppTextStyles.body(color: scheme.onSurface)),
            AppSpacing.vGapMd,
            FilledButton(
              onPressed: () => ref.invalidate(
                parentChildFeesProvider(
                    (studentId: studentId, academicYear: null)),
              ),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ),
      data: (data) {
        final payments =
            data['feePayments'] as List<FeePaymentSummaryModel>? ?? [];
        final structure =
            data['feeStructure'] as List<FeeStructureSummaryModel>? ?? [];

        return SingleChildScrollView(
          padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fee structure
                  Text(AppStrings.feeStructure,
                      style: AppTextStyles.h6(color: scheme.onSurface)),
                  AppSpacing.vGapMd,
                  if (structure.isEmpty)
                    Text(AppStrings.noFeeStructure,
                        style: AppTextStyles.body(
                            color: scheme.onSurfaceVariant))
                  else
                    Card(
                      shape: AppRadius.cardShape,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: structure.length,
                        separatorBuilder: (_, i) => AppDivider.hairline,
                        itemBuilder: (_, i) {
                          final s = structure[i];
                          return ListTile(
                            title: Text(s.feeHead,
                                style: AppTextStyles.bodyMd(
                                    color: scheme.onSurface)),
                            trailing: Text('₹${s.amount}',
                                style: AppTextStyles.h6(
                                    color: scheme.onSurface)),
                            subtitle: Text(s.frequency,
                                style: AppTextStyles.bodySm(
                                    color: scheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                  AppSpacing.vGapXl,

                  // Payment history
                  Text(AppStrings.feePayments,
                      style: AppTextStyles.h6(color: scheme.onSurface)),
                  AppSpacing.vGapMd,
                  if (payments.isEmpty)
                    Text(AppStrings.noFeePayments,
                        style: AppTextStyles.body(
                            color: scheme.onSurfaceVariant))
                  else
                    Card(
                      shape: AppRadius.cardShape,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (_, i) => AppDivider.hairline,
                        itemBuilder: (_, i) {
                          final p = payments[i];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: AppSpacing.lg + 2,
                              backgroundColor: AppColors.primary500.withValues(
                                  alpha: AppOpacity.focus),
                              child: Icon(Icons.receipt,
                                  size: AppIconSize.md, color: AppColors.primary500),
                            ),
                            title: Text(p.feeHead,
                                style: AppTextStyles.bodyMd(
                                    color: scheme.onSurface)),
                            subtitle: Text(
                              '${p.receiptNo} • ${p.paymentMode}',
                              style: AppTextStyles.bodySm(
                                  color: scheme.onSurfaceVariant),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${p.amount}',
                                    style: AppTextStyles.h6(
                                        color: AppColors.success600)),
                                Text(_formatDate(p.paymentDate),
                                    style: AppTextStyles.bodySm(
                                        color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// =============================================================================
// TAB 4 — TIMETABLE
// =============================================================================

class _TimetableTab extends ConsumerStatefulWidget {
  const _TimetableTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends ConsumerState<_TimetableTab>
    with SingleTickerProviderStateMixin {
  List<TimetableSlotModel>? _slots;
  bool _isLoading = true;
  String? _error;
  late TabController _dayTabCtrl;

  static const _dayNames = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
  ];
  static const _dayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (Mon=0, Sat=5), or Mon if Sunday
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final initialIndex = today >= 1 && today <= 6 ? today - 1 : 0;
    _dayTabCtrl = TabController(
      length: _dayNames.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _load();
  }

  @override
  void dispose() {
    _dayTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(parentServiceProvider);
      final slots = await service.getChildTimetable(widget.studentId);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(_error!,
                style: AppTextStyles.body(color: scheme.onSurface)),
            AppSpacing.vGapMd,
            FilledButton(
                onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    final allSlots = _slots ?? [];

    return Column(
      children: [
        TabBar(
          controller: _dayTabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.primary500,
          labelColor: AppColors.primary500,
          unselectedLabelColor: scheme.onSurfaceVariant,
          tabAlignment: TabAlignment.start,
          tabs: _dayShort
              .map((d) => Tab(text: d))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _dayTabCtrl,
            children: _dayNames.map((dayName) {
              final daySlots = allSlots
                  .where((s) => s.day.toUpperCase() == dayName)
                  .toList()
                ..sort((a, b) => a.period.compareTo(b.period));

              if (daySlots.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy,
                          size: AppIconSize.xl3, color: scheme.outline),
                      AppSpacing.vGapMd,
                      Text(AppStrings.noTimetableForDay,
                          style: AppTextStyles.body(
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: AppSpacing.paddingLg,
                itemCount: daySlots.length,
                separatorBuilder: (_, i) => AppSpacing.vGapSm,
                itemBuilder: (_, i) {
                  final slot = daySlots[i];
                  return Card(
                    shape: AppRadius.cardShape,
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Row(
                        children: [
                          // Period number
                          Container(
                            width: AppSpacing.xl3,
                            height: AppSpacing.xl3,
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withValues(
                                  alpha: AppOpacity.focus),
                              borderRadius: AppRadius.brMd,
                            ),
                            child: Center(
                              child: Text(
                                '${slot.period}',
                                style: AppTextStyles.h6(color: AppColors.primary500),
                              ),
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(slot.subject,
                                    style: AppTextStyles.bodyMd(
                                        color: scheme.onSurface)),
                                if (slot.startTime.isNotEmpty)
                                  Text(
                                    '${slot.startTime} - ${slot.endTime}',
                                    style: AppTextStyles.bodySm(
                                        color:
                                            scheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                          if (slot.room != null || slot.teacherName != null)
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                if (slot.room != null)
                                  Text(slot.room!,
                                      style: AppTextStyles.bodySm(
                                          color: scheme
                                              .onSurfaceVariant)),
                                if (slot.teacherName != null)
                                  Text(slot.teacherName!,
                                      style: AppTextStyles.bodySm(
                                          color: scheme
                                              .onSurfaceVariant)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 5 — NOTICES
// =============================================================================

class _NoticesTab extends ConsumerStatefulWidget {
  const _NoticesTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends ConsumerState<_NoticesTab> {
  List<NoticeSummaryModel>? _notices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(parentServiceProvider);
      final result = await service.getNotices(page: 1, limit: 20);
      final notices = result['notices'] as List<NoticeSummaryModel>? ?? [];
      if (!mounted) return;
      setState(() {
        _notices = notices;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(_error!,
                style: AppTextStyles.body(color: scheme.onSurface)),
            AppSpacing.vGapMd,
            FilledButton(
                onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    final notices = _notices ?? [];

    if (notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: AppIconSize.xl4, color: scheme.outline),
            AppSpacing.vGapLg,
            Text(AppStrings.noNotices,
                style: AppTextStyles.h6(color: scheme.onSurface)),
            AppSpacing.vGapSm,
            Text(AppStrings.noNoticesHint,
                style:
                    AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.paddingLg,
      itemCount: notices.length,
      separatorBuilder: (_, i) => AppSpacing.vGapSm,
      itemBuilder: (_, i) {
        final n = notices[i];
        return Card(
          shape: AppRadius.cardShape,
          child: InkWell(
            onTap: () => context.go('/parent/notices/${n.id}'),
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (n.isPinned) ...[
                        Icon(Icons.push_pin,
                            size: AppIconSize.sm,
                            color: AppColors.warning600),
                        AppSpacing.hGapXs,
                      ],
                      Expanded(
                        child: Text(n.title,
                            style: AppTextStyles.bodyMd(
                                color: scheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (n.publishedAt != null)
                        Text(_formatDate(n.publishedAt!),
                            style: AppTextStyles.bodySm(
                                color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  AppSpacing.vGapXs,
                  Text(n.body,
                      style: AppTextStyles.bodySm(
                          color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// =============================================================================
// TAB 6 — DOCUMENTS
// =============================================================================

class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  List<StudentDocumentModel>? _docs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(parentServiceProvider);
      final docs = await service.getChildDocuments(widget.studentId);
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(_error!,
                style: AppTextStyles.body(color: scheme.onSurface)),
            AppSpacing.vGapMd,
            FilledButton(
                onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    final docs = _docs ?? [];

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined,
                size: AppIconSize.xl4, color: scheme.outline),
            AppSpacing.vGapLg,
            Text(AppStrings.noDocumentsLinked,
                style: AppTextStyles.h6(color: scheme.onSurface)),
          ],
        ),
      );
    }

    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return GridView.builder(
      padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        return _DocumentCard(doc: doc);
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});
  final StudentDocumentModel doc;

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'CERTIFICATE':
      case 'AWARD':
        return Icons.emoji_events_outlined;
      case 'PHOTO':
      case 'IMAGE':
        return Icons.image_outlined;
      case 'ID_CARD':
        return Icons.badge_outlined;
      case 'REPORT_CARD':
        return Icons.assessment_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(doc.type),
                    size: AppIconSize.xl, color: AppColors.primary500),
                const Spacer(),
                if (doc.verified)
                  Icon(Icons.verified,
                      size: AppIconSize.sm, color: AppColors.success600),
              ],
            ),
            AppSpacing.vGapSm,
            Expanded(
              child: Text(
                doc.name,
                style: AppTextStyles.bodyMd(color: scheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpacing.vGapXs,
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2,
                    vertical: AppSpacing.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: AppOpacity.pressed),
                    borderRadius: AppRadius.brXs,
                  ),
                  child: Text(
                    doc.type,
                    style: AppTextStyles.overline(color: AppColors.primary500),
                  ),
                ),
                const Spacer(),
                if (doc.fileSizeKb != null)
                  Text(
                    '${(doc.fileSizeKb! / 1024).toStringAsFixed(1)} MB',
                    style: AppTextStyles.bodySm(
                        color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 7 — BUS
// =============================================================================

class _BusTab extends ConsumerStatefulWidget {
  const _BusTab({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_BusTab> createState() => _BusTabState();
}

class _BusTabState extends ConsumerState<_BusTab> {
  BusLocationModel? _data;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(AppDuration.toast, (_) {
      if (_data?.tripStatus == 'IN_PROGRESS') _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(parentServiceProvider);
      final data = await service.getChildBusLocation(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return AppLoaderScreen();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapMd,
            Text(_error!,
                style: AppTextStyles.body(color: scheme.onSurface),
                textAlign: TextAlign.center),
            AppSpacing.vGapMd,
            FilledButton(
                onPressed: _load, child: Text(AppStrings.retry)),
          ],
        ),
      );
    }

    final data = _data!;

    if (!data.hasBus) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_outlined,
                size: AppIconSize.xl4, color: scheme.outline),
            AppSpacing.vGapLg,
            Text(AppStrings.noBusAssigned,
                style: AppTextStyles.body(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final isActive = data.tripStatus == 'IN_PROGRESS';
    final loc = data.location;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success50
                      : AppColors.neutral100,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: isActive
                        ? AppColors.success300
                        : AppColors.neutral300,
                    width: AppBorderWidth.thin,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppSpacing.sm + 2,
                      height: AppSpacing.sm + 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.success600
                            : AppColors.neutral500,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      isActive
                          ? AppStrings.busOnTheWay
                          : AppStrings.busNotOnTrip,
                      style: AppTextStyles.bodyMd(
                        color: isActive
                            ? AppColors.success700
                            : AppColors.neutral600,
                      ),
                    ),
                    if (loc != null &&
                        isActive &&
                        (loc.speed ?? 0) > 0) ...[
                      const Spacer(),
                      Text(
                        '${((loc.speed ?? 0) * 3.6).toStringAsFixed(0)} km/h',
                        style: AppTextStyles.bodySm(
                            color: AppColors.success700),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.vGapLg,

              // Vehicle info
              if (data.vehicle != null)
                Card(
                  shape: AppRadius.cardShape,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_bus,
                                color: AppColors.warning600,
                                size: AppIconSize.lg),
                            AppSpacing.hGapSm,
                            Text(data.vehicle!.vehicleNo,
                                style: AppTextStyles.h6(
                                    color: scheme.onSurface)),
                          ],
                        ),
                        if (data.vehicle!.driverName != null) ...[
                          AppDivider.hairline,
                          AppSpacing.vGapSm,
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: AppIconSize.sm,
                                  color: scheme.onSurfaceVariant),
                              AppSpacing.hGapSm,
                              Text(data.vehicle!.driverName!,
                                  style: AppTextStyles.bodyMd(
                                      color: scheme.onSurface)),
                              if (data.vehicle!.driverPhone != null) ...[
                                const Spacer(),
                                Icon(Icons.phone,
                                    size: AppIconSize.sm,
                                    color: AppColors.success600),
                                AppSpacing.hGapXs,
                                Text(data.vehicle!.driverPhone!,
                                    style: AppTextStyles.bodySm(
                                        color: AppColors.success600)),
                              ],
                            ],
                          ),
                        ],
                        if (loc?.updatedAt != null) ...[
                          AppSpacing.vGapSm,
                          Text(
                            '${AppStrings.busLastUpdated}: ${_formatTime(loc!.updatedAt!)}',
                            style: AppTextStyles.bodySm(
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              if (loc == null) ...[
                AppSpacing.vGapXl,
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_off,
                          size: AppIconSize.xl3,
                          color: scheme.outline),
                      AppSpacing.vGapMd,
                      Text(AppStrings.busLocationNotAvailable,
                          style: AppTextStyles.body(
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// =============================================================================
// ERROR VIEW — reusable
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: AppIconSize.xl3, color: scheme.error),
          AppSpacing.vGapMd,
          Text(error,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: scheme.onSurface)),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
