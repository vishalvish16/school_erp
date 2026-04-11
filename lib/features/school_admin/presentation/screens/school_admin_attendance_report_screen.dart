// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_attendance_report_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/attendance_model.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/metric_stat_card.dart';

final _attendanceReportProvider = FutureProvider.autoDispose
    .family<AttendanceReportModel, Map<String, String?>>((ref, params) {
  return ref.read(schoolAdminServiceProvider).getAttendanceReport(
        classId: params['classId'],
        sectionId: params['sectionId'],
        month: params['month'],
      );
});

class SchoolAdminAttendanceReportScreen extends ConsumerStatefulWidget {
  const SchoolAdminAttendanceReportScreen({super.key});

  @override
  ConsumerState<SchoolAdminAttendanceReportScreen> createState() =>
      _SchoolAdminAttendanceReportScreenState();
}

class _SchoolAdminAttendanceReportScreenState
    extends ConsumerState<SchoolAdminAttendanceReportScreen> {
  String? _classId;
  String? _sectionId;
  late String _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(schoolAdminClassesProvider);
    final params = {
      'classId': _classId,
      'sectionId': _sectionId,
      'month': _month,
    };
    final asyncReport = ref.watch(_attendanceReportProvider(params));
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/school-admin/attendance'),
        ),
        title: Text(AppStrings.monthlyAttendanceReport),
        backgroundColor: scheme.surface,
        actions: [
          TextButton.icon(
            onPressed: () =>
                ref.invalidate(_attendanceReportProvider(params)),
            icon: const Icon(Icons.refresh, size: AppIconSize.sm),
            label: const Text('Refresh'),
          ),
          TextButton.icon(
            onPressed: () {/* export logic — no-op placeholder */},
            icon: const Icon(Icons.download_rounded, size: AppIconSize.sm),
            label: const Text('Export'),
          ),
          AppSpacing.hGapSm,
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filters ────────────────────────────────────────────────────
            if (isWide)
              Row(
                children: [
                  _ClassDropdown(
                    classes: classesState.classes,
                    value: _classId,
                    onChanged: (v) => setState(() {
                      _classId = v;
                      _sectionId = null;
                    }),
                  ),
                  if (_classId != null) ...[
                    AppSpacing.hGapSm,
                    _SectionDropdown(
                      classes: classesState.classes,
                      classId: _classId!,
                      value: _sectionId,
                      onChanged: (v) =>
                          setState(() => _sectionId = v),
                    ),
                  ],
                  AppSpacing.hGapSm,
                  _MonthSelector(
                    month: _month,
                    onChanged: (m) => setState(() => _month = m),
                  ),
                ],
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ClassDropdown(
                    classes: classesState.classes,
                    value: _classId,
                    onChanged: (v) => setState(() {
                      _classId = v;
                      _sectionId = null;
                    }),
                  ),
                  if (_classId != null)
                    _SectionDropdown(
                      classes: classesState.classes,
                      classId: _classId!,
                      value: _sectionId,
                      onChanged: (v) =>
                          setState(() => _sectionId = v),
                    ),
                  _MonthSelector(
                    month: _month,
                    onChanged: (m) => setState(() => _month = m),
                  ),
                ],
              ),
            AppSpacing.vGapLg,

            Expanded(
              child: asyncReport.when(
                loading: () => AppLoaderScreen(),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: AppIconSize.xl4, color: scheme.error),
                      AppSpacing.vGapMd,
                      Text(
                        err.toString().replaceAll('Exception: ', ''),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (report) => Column(
                  children: [
                    // ── Summary MetricStatCards ────────────────────────────
                    _buildSummaryCards(report.summary, isWide),
                    AppSpacing.vGapLg,
                    Expanded(
                        child: _CalendarGrid(
                            calendar: report.calendar)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      AttendanceReportSummary summary, bool isWide) {
    final items = <(IconData, String, String, Color)>[
      (Icons.event_note_rounded, '${summary.totalDays}',
          AppStrings.totalDays, AppColors.neutral500),
      (Icons.check_circle_rounded,
          '${summary.presentDays}',
          AppStrings.presentDays,
          AppColors.success500),
      (Icons.cancel_rounded, '${summary.absentDays}',
          AppStrings.absentDays, AppColors.error500),
      (
        Icons.schedule_rounded,
        summary.totalDays > 0
            ? '${(summary.presentDays / summary.totalDays * 100).toStringAsFixed(0)}%'
            : '0%',
        'Attendance %',
        AppColors.primary500,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: MetricStatCard(
                icon: items[i].$1,
                value: items[i].$2,
                label: items[i].$3,
                color: items[i].$4,
                compact: false,
              ),
            ),
            if (i < items.length - 1) AppSpacing.hGapSm,
          ],
        ],
      );
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (ctx, i) => SizedBox(
          width: 148,
          child: MetricStatCard(
            icon: items[i].$1,
            value: items[i].$2,
            label: items[i].$3,
            color: items[i].$4,
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _ClassDropdown extends StatelessWidget {
  const _ClassDropdown({
    required this.classes,
    required this.value,
    required this.onChanged,
  });
  final List<SchoolClassModel> classes;
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
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
          value: value,
          hint: Text(AppStrings.allClasses,
              style: const TextStyle(fontSize: 13)),
          isDense: true,
          items: [
            DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.allClasses,
                    style: const TextStyle(fontSize: 13))),
            for (final c in classes)
              DropdownMenuItem<String?>(
                  value: c.id,
                  child:
                      Text(c.name, style: const TextStyle(fontSize: 13))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionDropdown extends StatelessWidget {
  const _SectionDropdown({
    required this.classes,
    required this.classId,
    required this.value,
    required this.onChanged,
  });
  final List<SchoolClassModel> classes;
  final String classId;
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls == null) return const SizedBox.shrink();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: AppRadius.brMd,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onChanged});
  final String month;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final parts = month.split('-');
        final initial =
            DateTime(int.parse(parts[0]), int.parse(parts[1]));
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (picked != null) {
          onChanged(
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}');
        }
      },
      icon: const Icon(Icons.calendar_month, size: AppIconSize.sm),
      label: Text(month, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.calendar});
  final List<AttendanceDayReport> calendar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (calendar.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: AppIconSize.xl4,
                color: scheme.onSurfaceVariant),
            AppSpacing.vGapMd,
            Text(
              AppStrings.noAttendanceData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dailyBreakdown,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapMd,
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    columns: [
                      DataColumn(label: Text(AppStrings.dateColumn)),
                      DataColumn(
                          label: Text(AppStrings.present),
                          numeric: true),
                      DataColumn(
                          label: Text(AppStrings.absent),
                          numeric: true),
                      DataColumn(
                          label: Text(AppStrings.late),
                          numeric: true),
                    ],
                    rows: calendar.map((day) {
                      final total =
                          day.present + day.absent + day.late;
                      final pct = total > 0
                          ? (day.present / total * 100)
                              .toStringAsFixed(0)
                          : '0';
                      return DataRow(cells: [
                        DataCell(Text(_fmt(day.date))),
                        DataCell(Text(
                          '${day.present} ($pct%)',
                          style: const TextStyle(
                              color: AppColors.success500),
                        )),
                        DataCell(Text(
                          '${day.absent}',
                          style: const TextStyle(
                              color: AppColors.error500),
                        )),
                        DataCell(Text(
                          '${day.late}',
                          style: const TextStyle(
                              color: AppColors.warning500),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
