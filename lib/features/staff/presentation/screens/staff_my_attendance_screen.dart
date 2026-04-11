// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_my_attendance_screen.dart
// PURPOSE: Staff portal — view own attendance for current/selected month.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/non_teaching_attendance_model.dart';
import '../../../../design_system/design_system.dart';


class StaffMyAttendanceScreen extends ConsumerStatefulWidget {
  const StaffMyAttendanceScreen({super.key});

  @override
  ConsumerState<StaffMyAttendanceScreen> createState() =>
      _StaffMyAttendanceScreenState();
}

class _StaffMyAttendanceScreenState
    extends ConsumerState<StaffMyAttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic> _data = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final monthStr =
          '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
      final result = await ref
          .read(schoolAdminServiceProvider)
          .getMyNonTeachingAttendance(month: monthStr);
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _loadAttendance();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final summary = _data['summary'] as Map<String, dynamic>? ?? {};
    final records = _data['records'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Attendance',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.vGapLg,

                    // Month selector
                    Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _prevMonth,
                              icon:
                                  const Icon(Icons.chevron_left),
                            ),
                            AppSpacing.hGapSm,
                            Text(
                              '${monthNames[_month.month - 1]} ${_month.year}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            AppSpacing.hGapSm,
                            IconButton(
                              onPressed: _nextMonth,
                              icon:
                                  const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.vGapLg,

                    // Summary
                    if (summary.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final e in summary.entries)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: _SummaryBox(
                                  label: NonTeachingAttendanceModel
                                      .labelForStatus(e.key),
                                  count:
                                      (e.value as num?)?.toInt() ??
                                          0,
                                  color: NonTeachingAttendanceModel
                                      .colorForStatus(e.key),
                                ),
                              ),
                          ],
                        ),
                      ),
                    AppSpacing.vGapLg,
                  ],
                ),
              ),
            ),

            if (_loading)
              SliverFillRemaining(
                child: AppLoaderScreen(),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 40, color: AppColors.error500),
                      AppSpacing.vGapSm,
                      Text(_error!,
                          textAlign: TextAlign.center),
                      AppSpacing.vGapMd,
                      FilledButton(
                        onPressed: _loadAttendance,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (records.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note_outlined,
                          size: 56, color: AppColors.neutral400),
                      AppSpacing.vGapMd,
                      Text('No attendance records this month',
                          style: TextStyle(color: AppColors.neutral500)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: AppSpacing.paddingHLg,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final r = records[i] as Map<String, dynamic>;
                      final status =
                          r['status'] as String? ?? '';
                      final date = r['date'] as String? ?? '';
                      final checkIn = r['checkInTime'] ??
                          r['check_in_time'];
                      final checkOut = r['checkOutTime'] ??
                          r['check_out_time'];
                      final remarks = r['remarks'] as String?;
                      final color =
                          NonTeachingAttendanceModel.colorForStatus(
                              status);
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 6),
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              color.withValues(alpha: 0.06),
                          borderRadius:
                              AppRadius.brMd,
                          border: Border(
                              left: BorderSide(
                                  color: color, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(date,
                                      style: Theme.of(ctx).textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w500)),
                                  if (checkIn != null)
                                    Text(
                                      'In: $checkIn${checkOut != null ? '  Out: $checkOut' : ''}',
                                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                                    ),
                                  if (remarks != null)
                                    Text(remarks,
                                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Container(
                              padding:
                                  EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                    alpha: 0.15),
                                borderRadius:
                                    AppRadius.brLg,
                              ),
                              child: Text(
                                NonTeachingAttendanceModel
                                    .labelForStatus(status),
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: records.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
                child: AppSpacing.vGapXl),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
