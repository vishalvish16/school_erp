// =============================================================================
// FILE: lib/features/student/presentation/screens/student_timetable_screen.dart
// PURPOSE: Timetable screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class StudentTimetableScreen extends ConsumerWidget {
  const StudentTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTimetable = ref.watch(studentTimetableProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentTimetableProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.studentTimetableTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXl,
            asyncTimetable.when(
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
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(err.toString().replaceAll('Exception: ', '')),
                      AppSpacing.vGapLg,
                      FilledButton(
                        onPressed: () => ref.invalidate(studentTimetableProvider),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (tt) {
                if (tt.slots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          AppStrings.noTimetableSlots,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildTimetableGrid(context, tt.slots),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid(BuildContext context, List slots) {
    final byDay = <int, List>{};
    for (final s in slots) {
      final d = s.dayOfWeek;
      if (d >= 1 && d <= 6) {
        byDay.putIfAbsent(d, () => []).add(s);
      }
    }
      for (final list in byDay.values) {
        list.sort((a, b) => (a.periodNo as int).compareTo(b.periodNo as int));
      }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        _accent.withValues(alpha: 0.1),
      ),
      columns: [
        const DataColumn(label: Text('Period')),
        ...List.generate(6, (i) => DataColumn(label: Text(_dayNames[i]))),
      ],
      rows: _buildRows(byDay),
    );
  }

  List<DataRow> _buildRows(Map<int, List> byDay) {
    int maxPeriods = 0;
    for (final list in byDay.values) {
      for (final s in list) {
        final p = s.periodNo as int;
        if (p > maxPeriods) maxPeriods = p;
      }
    }
    if (maxPeriods == 0) return [];

    return List.generate(maxPeriods, (periodIndex) {
      final periodNo = periodIndex + 1;
      final cells = <DataCell>[
        DataCell(Text('$periodNo')),
      ];
      for (int day = 1; day <= 6; day++) {
        final list = byDay[day] ?? [];
        dynamic slot;
        for (final s in list) {
          if (s.periodNo == periodNo) { slot = s; break; }
        }
        if (slot != null) {
          cells.add(DataCell(
            Tooltip(
              message: '${slot.startTime} - ${slot.endTime}${slot.room != null ? '\n${slot.room}' : ''}',
              child: Text(
                slot.subject,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ));
        } else {
          cells.add(const DataCell(Text('—')));
        }
      }
      return DataRow(cells: cells);
    });
  }
}
