import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../models/teacher/attendance_model.dart';
import '../providers/teacher_attendance_provider.dart';
import '../../../../design_system/design_system.dart';

const Color _accent = AppColors.success500;

final _attendanceReportProvider = FutureProvider.autoDispose
    .family<AttendanceReportModel, _ReportParams>((ref, params) {
  return ref.read(teacherServiceProvider).getAttendanceReport(
        params.sectionId,
        fromDate: params.fromDate,
        toDate: params.toDate,
      );
});

class _ReportParams {
  final String sectionId;
  final String? fromDate;
  final String? toDate;

  const _ReportParams({
    required this.sectionId,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ReportParams &&
          sectionId == other.sectionId &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(sectionId, fromDate, toDate);
}

class TeacherAttendanceReportScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceReportScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceReportScreen> createState() =>
      _TeacherAttendanceReportScreenState();
}

class _TeacherAttendanceReportScreenState
    extends ConsumerState<TeacherAttendanceReportScreen> {
  TeacherSectionModel? _selectedSection;
  DateTimeRange? _dateRange;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(teacherSectionsProvider);
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
                  onPressed: () => context.go('/teacher/attendance'),
                  icon: const Icon(Icons.arrow_back),
                ),
                AppSpacing.hGapSm,
                Text(
                  'Attendance Report',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Filters
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: sectionsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (sections) => DropdownButtonFormField<String>(
                      initialValue: _selectedSection?.sectionId,
                      decoration: const InputDecoration(
                        labelText: 'Select Section',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                      ),
                      items: sections
                          .map((s) => DropdownMenuItem(
                                value: s.sectionId,
                                child: Text(s.displayName),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedSection = sections
                              .firstWhere((s) => s.sectionId == val);
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: InkWell(
                    onTap: _pickDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        suffixIcon: Icon(Icons.date_range, size: 18),
                      ),
                      child: Text(_dateRange != null
                          ? '${_displayDate(_dateRange!.start)} – ${_displayDate(_dateRange!.end)}'
                          : 'Select date range'),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Report content
            Expanded(
              child: _selectedSection == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline),
                          AppSpacing.vGapLg,
                          Text('Select a section to view report',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : _ReportContent(
                      params: _ReportParams(
                        sectionId: _selectedSection!.sectionId,
                        fromDate: _dateRange != null
                            ? _fmtDate(_dateRange!.start)
                            : null,
                        toDate: _dateRange != null
                            ? _fmtDate(_dateRange!.end)
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportContent extends ConsumerWidget {
  const _ReportContent({required this.params});
  final _ReportParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReport = ref.watch(_attendanceReportProvider(params));

    return asyncReport.when(
      loading: () => AppLoaderScreen(),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapMd,
            Text(err.toString().replaceAll('Exception: ', '')),
            AppSpacing.vGapMd,
            FilledButton(
              onPressed: () =>
                  ref.invalidate(_attendanceReportProvider(params)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (report) => Column(
        children: [
          // Summary
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${report.summary.totalWorkingDays}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Working Days',
                            style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${report.summary.averageAttendancePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: report.summary.averageAttendancePct >= 90
                                ? _accent
                                : report.summary.averageAttendancePct >= 75
                                    ? AppColors.warning500
                                    : AppColors.error500,
                          ),
                        ),
                        const Text('Average Attendance',
                            style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vGapMd,

          // Student table
          Expanded(
            child: Card(
              child: report.students.isEmpty
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowHeight: 40,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 40,
                          columns: const [
                            DataColumn(label: Text('Roll')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('P'), numeric: true),
                            DataColumn(label: Text('A'), numeric: true),
                            DataColumn(label: Text('L'), numeric: true),
                            DataColumn(label: Text('H'), numeric: true),
                            DataColumn(label: Text('%'), numeric: true),
                          ],
                          rows: report.students
                              .map((s) => DataRow(cells: [
                                    DataCell(
                                        Text(s.rollNo?.toString() ?? '—')),
                                    DataCell(Text(s.name)),
                                    DataCell(Text('${s.present}')),
                                    DataCell(Text(
                                      '${s.absent}',
                                      style: TextStyle(
                                        color: s.absent > 0
                                            ? AppColors.error500
                                            : null,
                                      ),
                                    )),
                                    DataCell(Text('${s.late}')),
                                    DataCell(Text('${s.halfDay}')),
                                    DataCell(Text(
                                      s.attendancePct.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: s.attendancePct >= 90
                                            ? _accent
                                            : s.attendancePct >= 75
                                                ? AppColors.warning500
                                                : AppColors.error500,
                                      ),
                                    )),
                                  ]))
                              .toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
