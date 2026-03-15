// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_attendance_screen.dart
// PURPOSE: Monthly attendance for one child.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/attendance_entry_model.dart';
import '../../data/parent_child_attendance_provider.dart';
import '../../data/parent_child_detail_provider.dart';

const Color _accent = AppColors.success500;

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
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
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
                    loading: () => const Text(AppStrings.childAttendance),
                    error: (_, __) => const Text(AppStrings.childAttendance),
                    data: (c) => Text(
                      c != null
                          ? '${AppStrings.childAttendance} — ${c.fullName}'
                          : AppStrings.childAttendance,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                                size: 48,
                                color: Theme.of(context).colorScheme.outline),
                            AppSpacing.vGapMd,
                            Text(
                              AppStrings.noAttendanceThisMonth,
                              style: Theme.of(context).textTheme.bodyMedium,
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
    final isPresent = entry.status == 'PRESENT' || entry.status == 'LATE';
    final isHoliday = entry.status == 'HOLIDAY';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isHoliday
              ? AppColors.warning500.withValues(alpha: 0.2)
              : (isPresent
                  ? _accent.withValues(alpha: 0.2)
                  : AppColors.error500.withValues(alpha: 0.2)),
          child: Icon(
            isHoliday ? Icons.beach_access : (isPresent ? Icons.check : Icons.close),
            color: isHoliday
                ? AppColors.warning600
                : (isPresent ? _accent : AppColors.error600),
            size: 20,
          ),
        ),
        title: Text(_formatDate(entry.date)),
        subtitle: entry.remarks != null && entry.remarks!.isNotEmpty
            ? Text(entry.remarks!)
            : null,
        trailing: Chip(
          label: Text(
            entry.status,
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: isHoliday
              ? AppColors.warning100
              : (isPresent ? AppColors.success100 : AppColors.error100),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
