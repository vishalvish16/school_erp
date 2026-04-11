// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_timetable_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../providers/school_admin_timetable_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';

const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class SchoolAdminTimetableScreen extends ConsumerStatefulWidget {
  const SchoolAdminTimetableScreen({super.key});

  @override
  ConsumerState<SchoolAdminTimetableScreen> createState() =>
      _SchoolAdminTimetableScreenState();
}

class _SchoolAdminTimetableScreenState
    extends ConsumerState<SchoolAdminTimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(schoolAdminClassesProvider);
    final timetableState = ref.watch(schoolAdminTimetableProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
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
                    AppSpacing.vGapXs,
                    Text(
                      'Weekly class schedule by period',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,

          // ── Selectors ────────────────────────────────────────────────────
          Row(
            children: [
              _ClassDropdown(classes: classesState.classes),
              if (timetableState.selectedClassId != null) ...[
                AppSpacing.hGapSm,
                _SectionDropdown(
                  classId: timetableState.selectedClassId!,
                  classes: classesState.classes,
                ),
              ],
            ],
          ),
          AppSpacing.vGapLg,

          // ── Error banner ─────────────────────────────────────────────────
          if (timetableState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                timetableState.errorMessage!,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),

          // ── Content ───────────────────────────────────────────────────────
          if (timetableState.selectedClassId == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: AppIconSize.xl4,
                        color: scheme.onSurfaceVariant),
                    AppSpacing.vGapMd,
                    Text(
                      'Select a class to view its timetable',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (timetableState.isLoading)
            const Expanded(child: AppLoaderScreen())
          else
            Expanded(
              child: isWide
                  ? _TimetableWideGrid(
                      entries: timetableState.entries,
                      classId: timetableState.selectedClassId!,
                      sectionId: timetableState.selectedSectionId,
                    )
                  : _TimetableNarrowTabView(
                      entries: timetableState.entries,
                      tabController: _tabController,
                    ),
            ),
        ],
      ),
    );
  }
}

// ── Class / Section dropdowns ─────────────────────────────────────────────────

class _ClassDropdown extends ConsumerWidget {
  const _ClassDropdown({required this.classes});
  final List<SchoolClassModel> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminTimetableProvider);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: AppRadius.brMd,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: state.selectedClassId,
          hint: Text(AppStrings.selectClass,
              style: const TextStyle(fontSize: 13)),
          isDense: true,
          items: classes
              .map((c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child:
                        Text(c.name, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            ref
                .read(schoolAdminTimetableProvider.notifier)
                .loadTimetable(classId: v);
          },
        ),
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls == null || cls.sections.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: AppRadius.brMd,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: state.selectedSectionId,
          hint: Text(AppStrings.allSections,
              style: const TextStyle(fontSize: 13)),
          isDense: true,
          items: [
            DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.allSections,
                    style: const TextStyle(fontSize: 13))),
            for (final s in cls.sections)
              DropdownMenuItem<String?>(
                  value: s.id,
                  child:
                      Text(s.name, style: const TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            ref
                .read(schoolAdminTimetableProvider.notifier)
                .loadTimetable(classId: classId, sectionId: v);
          },
        ),
      ),
    );
  }
}

// ── Wide grid (≥768px): horizontal + vertical scroll, DataTable ───────────────

class _TimetableWideGrid extends ConsumerWidget {
  const _TimetableWideGrid({
    required this.entries,
    required this.classId,
    required this.sectionId,
  });

  final List<dynamic> entries;
  final String classId;
  final String? sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = _groupByDay(entries);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined,
                size: AppIconSize.xl4,
                color: scheme.onSurfaceVariant),
            AppSpacing.vGapLg,
            Text(AppStrings.noTimetableEntries,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: _buildGrid(context, byDay),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, Map<int, List<Map<String, dynamic>>> byDay) {
    int maxPeriods = 0;
    for (final list in byDay.values) {
      if (list.length > maxPeriods) maxPeriods = list.length;
    }
    if (maxPeriods == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    const cellWidth = 140.0;
    const periodColWidth = 64.0;
    const timeColWidth = 100.0;
    const rowHeight = 64.0;

    return Table(
      defaultColumnWidth: const FixedColumnWidth(cellWidth),
      columnWidths: const {
        0: FixedColumnWidth(periodColWidth),
        1: FixedColumnWidth(timeColWidth),
      },
      border: TableBorder.all(
        color: AppColors.neutral200,
        borderRadius: AppRadius.brMd,
      ),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md)),
          ),
          children: [
            _headerCell('Period'),
            _headerCell('Time'),
            for (final day in _days) _headerCell(day),
          ],
        ),
        // Data rows
        for (int p = 0; p < maxPeriods; p++)
          TableRow(
            children: [
              // Period number
              SizedBox(
                height: rowHeight,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'P${p + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Time
              SizedBox(
                height: rowHeight,
                child: Center(
                  child: Text(
                    _timeLabel(byDay, p),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Day cells
              for (int d = 1; d <= 6; d++)
                _PeriodCell(
                  entry: p < byDay[d]!.length ? byDay[d]![p] : null,
                  height: rowHeight,
                ),
            ],
          ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _timeLabel(
      Map<int, List<Map<String, dynamic>>> byDay, int periodIdx) {
    for (int d = 1; d <= 6; d++) {
      final list = byDay[d]!;
      if (periodIdx < list.length) {
        final start = list[periodIdx]['start_time'] as String? ?? '';
        final end = list[periodIdx]['end_time'] as String? ?? '';
        if (start.isNotEmpty) return '$start\n$end';
      }
    }
    return '-';
  }

  Map<int, List<Map<String, dynamic>>> _groupByDay(List<dynamic> entries) {
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
    for (final list in byDay.values) {
      list.sort((a, b) => ((a['period_no'] as num?)?.toInt() ?? 0)
          .compareTo((b['period_no'] as num?)?.toInt() ?? 0));
    }
    return byDay;
  }
}

// ── Narrow tab view (<768px): TabBar per day ──────────────────────────────────

class _TimetableNarrowTabView extends StatelessWidget {
  const _TimetableNarrowTabView({
    required this.entries,
    required this.tabController,
  });

  final List<dynamic> entries;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byDay = _groupByDay(entries);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined,
                size: AppIconSize.xl4,
                color: scheme.onSurfaceVariant),
            AppSpacing.vGapLg,
            Text(AppStrings.noTimetableEntries,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: List.generate(_days.length, (dayIdx) {
              final dayEntries = byDay[dayIdx + 1] ?? [];
              if (dayEntries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_outlined,
                          size: AppIconSize.xl3,
                          color: scheme.onSurfaceVariant),
                      AppSpacing.vGapMd,
                      Text(
                        'No periods on ${_days[dayIdx]}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: AppSpacing.paddingMd,
                itemCount: dayEntries.length,
                itemBuilder: (ctx, i) {
                  final entry = dayEntries[i];
                  return _NarrowPeriodCard(
                    periodNo: i + 1,
                    entry: entry,
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Map<int, List<Map<String, dynamic>>> _groupByDay(List<dynamic> entries) {
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
    for (final list in byDay.values) {
      list.sort((a, b) => ((a['period_no'] as num?)?.toInt() ?? 0)
          .compareTo((b['period_no'] as num?)?.toInt() ?? 0));
    }
    return byDay;
  }
}

class _NarrowPeriodCard extends StatelessWidget {
  const _NarrowPeriodCard({required this.periodNo, required this.entry});
  final int periodNo;
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subject = entry['subject'] as String? ?? '';
    final teacher = entry['teacher'] as String? ?? '';
    final startTime = entry['start_time'] as String? ?? '';
    final endTime = entry['end_time'] as String? ?? '';
    final subjectColor = _subjectColor(subject);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            // Period number badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.brMd,
              ),
              child: Center(
                child: Text(
                  'P$periodNo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapMd,
            // Subject + teacher
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subject.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Free Period',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  if (teacher.isNotEmpty) ...[
                    AppSpacing.vGapXs,
                    Text(
                      teacher,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            // Time
            if (startTime.isNotEmpty)
              Text(
                '$startTime–$endTime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    const colors = [
      AppColors.primary500,
      AppColors.success500,
      AppColors.warning500,
      AppColors.secondary500,
      AppColors.error500,
      AppColors.info500,
    ];
    if (subject.isEmpty) return AppColors.neutral200;
    return colors[subject.hashCode.abs() % colors.length]
        .withValues(alpha: 0.15);
  }
}

// ── Period cell (wide table) ──────────────────────────────────────────────────

class _PeriodCell extends StatelessWidget {
  const _PeriodCell({required this.entry, required this.height});
  final Map<String, dynamic>? entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (entry == null) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('-',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    final subject = entry!['subject'] as String? ?? '-';
    final room = entry!['room'] as String?;
    final subjectColor = _subjectColor(subject);

    return SizedBox(
      height: height,
      child: Padding(
        padding: AppSpacing.paddingSm,
        child: Container(
          decoration: BoxDecoration(
            color: subjectColor,
            borderRadius: AppRadius.brSm,
          ),
          padding: AppSpacing.paddingSm,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (room != null)
                Text(
                  room,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    const colors = [
      AppColors.primary500,
      AppColors.success500,
      AppColors.warning500,
      AppColors.secondary500,
      AppColors.error500,
      AppColors.info500,
    ];
    if (subject == '-') return AppColors.neutral200;
    return colors[subject.hashCode.abs() % colors.length]
        .withValues(alpha: 0.15);
  }
}
