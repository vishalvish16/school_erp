// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_attendance_screen.dart
// PURPOSE: Monthly attendance for one child.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/attendance_entry_model.dart';
import '../../data/parent_child_attendance_provider.dart';
import '../../data/parent_child_detail_provider.dart';

class ParentChildAttendanceScreen extends ConsumerStatefulWidget {
  const ParentChildAttendanceScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<ParentChildAttendanceScreen> createState() =>
      _ParentChildAttendanceScreenState();
}

class _ParentChildAttendanceScreenState
    extends ConsumerState<ParentChildAttendanceScreen> {
  String _month = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncChild = ref.watch(parentChildDetailProvider(widget.studentId));
    final asyncAttendance = ref.watch(
      parentChildAttendanceProvider((studentId: widget.studentId, month: _month)),
    );
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.all(isWide ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/parent/children/${widget.studentId}'),
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.back,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: asyncChild.when(
                  loading: () => Text(AppStrings.childAttendance,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  error: (_, __) => Text(AppStrings.childAttendance,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  data: (c) => Text(
                    c != null
                        ? '${AppStrings.childAttendance} — ${c.fullName}'
                        : AppStrings.childAttendance,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,

          Row(
            children: [
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                parentChildAttendanceProvider(
                  (studentId: widget.studentId, month: _month),
                ),
              ),
              child: asyncAttendance.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                error: (err, _) => _ErrorView(
                  error: err.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.invalidate(
                    parentChildAttendanceProvider(
                      (studentId: widget.studentId, month: _month),
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy,
                              size: AppIconSize.xl4, color: scheme.outline),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            AppStrings.noAttendanceThisMonth,
                            style: textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AttendanceTile(entry: list[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildMonthItems() {
    final now = DateTime.now();
    final items = <DropdownMenuItem<String>>[];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i);
      final v = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      items.add(DropdownMenuItem(
        value: v,
        child: Text(_formatMonth(v)),
      ));
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

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.entry});

  final AttendanceEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPresent = entry.status == 'PRESENT' || entry.status == 'LATE';
    final isHoliday = entry.status == 'HOLIDAY';

    final Color bgColor;
    final Color fgColor;
    final Color chipBg;
    if (isHoliday) {
      bgColor = AppColors.warning500.withValues(alpha: 0.20);
      fgColor = AppColors.warning600;
      chipBg = AppColors.warning100;
    } else if (isPresent) {
      bgColor = AppColors.success500.withValues(alpha: 0.20);
      fgColor = AppColors.success500;
      chipBg = AppColors.success100;
    } else {
      bgColor = AppColors.error500.withValues(alpha: 0.20);
      fgColor = AppColors.error600;
      chipBg = AppColors.error100;
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: bgColor,
          child: Icon(
            isHoliday ? Icons.beach_access : (isPresent ? Icons.check : Icons.close),
            color: fgColor,
            size: AppIconSize.md,
          ),
        ),
        title: Text(_formatDate(entry.date)),
        subtitle: entry.remarks != null && entry.remarks!.isNotEmpty
            ? Text(entry.remarks!)
            : null,
        trailing: Chip(
          label: Text(
            entry.status,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          backgroundColor: chipBg,
        ),
      ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl4, color: scheme.error),
            SizedBox(height: AppSpacing.lg),
            Text(error,
                style: textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: Icon(Icons.refresh, size: AppIconSize.md),
              label: const Text(AppStrings.retry),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
