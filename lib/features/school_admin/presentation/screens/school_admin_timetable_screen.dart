// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_timetable_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../providers/school_admin_timetable_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class SchoolAdminTimetableScreen extends ConsumerStatefulWidget {
  const SchoolAdminTimetableScreen({super.key});

  @override
  ConsumerState<SchoolAdminTimetableScreen> createState() =>
      _SchoolAdminTimetableScreenState();
}

class _SchoolAdminTimetableScreenState
    extends ConsumerState<SchoolAdminTimetableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(schoolAdminClassesProvider);
    final timetableState = ref.watch(schoolAdminTimetableProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timetable',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapLg,

            // Class + Section selectors
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _ClassDropdown(classes: classesState.classes),
                if (timetableState.selectedClassId != null)
                  _SectionDropdown(
                    classId: timetableState.selectedClassId!,
                    classes: classesState.classes,
                  ),
              ],
            ),
            AppSpacing.vGapLg,

            if (timetableState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.4),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(timetableState.errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13)),
              ),

            if (timetableState.selectedClassId == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'Select a class to view its timetable',
                    style: TextStyle(color: AppColors.neutral400),
                  ),
                ),
              )
            else if (timetableState.isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: _TimetableGrid(
                  entries: timetableState.entries,
                  classId: timetableState.selectedClassId!,
                  sectionId: timetableState.selectedSectionId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClassDropdown extends ConsumerWidget {
  const _ClassDropdown({required this.classes});
  final List<SchoolClassModel> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminTimetableProvider);
    return DropdownButton<String?>(
      value: state.selectedClassId,
      hint: Text(AppStrings.selectClass),
      underline: const SizedBox.shrink(),
      items: classes
          .map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        ref.read(schoolAdminTimetableProvider.notifier).loadTimetable(classId: v);
      },
    );
  }
}

class _SectionDropdown extends ConsumerWidget {
  const _SectionDropdown({
    required this.classId,
    required this.classes,
  });
  final String classId;
  final List<SchoolClassModel> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminTimetableProvider);
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls == null || cls.sections.isEmpty) return const SizedBox.shrink();

    return DropdownButton<String?>(
      value: state.selectedSectionId,
      hint: Text(AppStrings.allSections),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<String?>(
            value: null, child: Text(AppStrings.allSections)),
        for (final s in cls.sections)
          DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
      ],
      onChanged: (v) {
        ref
            .read(schoolAdminTimetableProvider.notifier)
            .loadTimetable(classId: classId, sectionId: v);
      },
    );
  }
}

class _TimetableGrid extends ConsumerWidget {
  const _TimetableGrid({
    required this.entries,
    required this.classId,
    required this.sectionId,
  });

  final List<dynamic> entries;
  final String classId;
  final String? sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group entries by day
    final Map<int, List<Map<String, dynamic>>> byDay = {};
    for (int d = 1; d <= 6; d++) {
      byDay[d] = [];
    }
    for (final e in entries) {
      if (e is Map<String, dynamic>) {
        final day = (e['day_of_week'] as num?)?.toInt() ?? 1;
        if (day >= 1 && day <= 6) byDay[day]!.add(e);
      }
    }
    // Sort each day by period_no
    for (final list in byDay.values) {
      list.sort((a, b) => ((a['period_no'] as num?)?.toInt() ?? 0)
          .compareTo((b['period_no'] as num?)?.toInt() ?? 0));
    }

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            AppSpacing.vGapLg,
            Text(AppStrings.noTimetableEntries,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: [
            DataColumn(label: Text(AppStrings.period)),
            DataColumn(label: Text(AppStrings.time)),
            for (final day in _days)
              DataColumn(label: Text(day)),
          ],
          rows: _buildRows(byDay, context),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(
      Map<int, List<Map<String, dynamic>>> byDay, BuildContext context) {
    // Find max periods
    int maxPeriods = 0;
    for (final list in byDay.values) {
      if (list.length > maxPeriods) maxPeriods = list.length;
    }
    if (maxPeriods == 0) return [];

    return List.generate(maxPeriods, (periodIdx) {
      final periodNo = periodIdx + 1;
      String startTime = '';
      String endTime = '';

      // Find time from any day that has this period
      for (int d = 1; d <= 6; d++) {
        final dayEntries = byDay[d]!;
        if (periodIdx < dayEntries.length) {
          startTime = dayEntries[periodIdx]['start_time'] as String? ?? '';
          endTime = dayEntries[periodIdx]['end_time'] as String? ?? '';
          break;
        }
      }

      return DataRow(cells: [
        DataCell(Text(
          'P$periodNo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(
          startTime.isNotEmpty ? '$startTime–$endTime' : '-',
          style: const TextStyle(fontSize: 12, color: AppColors.neutral400),
        )),
        for (int d = 1; d <= 6; d++)
          DataCell(_PeriodCell(
            entry: periodIdx < byDay[d]!.length ? byDay[d]![periodIdx] : null,
          )),
      ]);
    });
  }
}

class _PeriodCell extends StatelessWidget {
  const _PeriodCell({required this.entry});
  final Map<String, dynamic>? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const Text('-', style: TextStyle(color: AppColors.neutral400));
    }
    final subject = entry!['subject'] as String? ?? '-';
    final room = entry!['room'] as String?;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: _accent),
          overflow: TextOverflow.ellipsis,
        ),
        if (room != null)
          Text(room,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral400)),
      ],
    );
  }
}
