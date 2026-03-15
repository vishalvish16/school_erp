// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_attendance_report_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/attendance_model.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.monthlyAttendanceReport),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(_attendanceReportProvider(params)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Wrap(
              spacing: 12,
              runSpacing: 8,
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
                    onChanged: (v) => setState(() => _sectionId = v),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(err.toString().replaceAll('Exception: ', '')),
                ),
                data: (report) => Column(
                  children: [
                    _SummaryRow(summary: report.summary),
                    AppSpacing.vGapLg,
                    Expanded(child: _CalendarGrid(calendar: report.calendar)),
                  ],
                ),
              ),
            ),
          ],
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
    return DropdownButton<String?>(
      value: value,
      hint: Text(AppStrings.allClasses),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<String?>(
            value: null, child: Text(AppStrings.allClasses)),
        for (final c in classes)
          DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
      ],
      onChanged: onChanged,
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
    final cls = classes.where((c) => c.id == classId).firstOrNull;
    if (cls == null) return const SizedBox.shrink();
    return DropdownButton<String?>(
      value: value,
      hint: Text(AppStrings.allSections),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<String?>(
            value: null, child: Text(AppStrings.allSections)),
        for (final s in cls.sections)
          DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
      ],
      onChanged: onChanged,
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
        final initial = DateTime(int.parse(parts[0]), int.parse(parts[1]));
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
      icon: const Icon(Icons.calendar_month, size: 16),
      label: Text(month),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final AttendanceReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
            label: AppStrings.totalDays,
            value: '${summary.totalDays}',
            color: AppColors.neutral400),
        AppSpacing.hGapMd,
        _SummaryCard(
            label: AppStrings.presentDays,
            value: '${summary.presentDays}',
            color: AppColors.success500),
        AppSpacing.hGapMd,
        _SummaryCard(
            label: AppStrings.absentDays,
            value: '${summary.absentDays}',
            color: AppColors.error500),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.calendar});
  final List<AttendanceDayReport> calendar;

  @override
  Widget build(BuildContext context) {
    if (calendar.isEmpty) {
      return const Center(
        child: Text(AppStrings.noAttendanceData,
            style: TextStyle(color: AppColors.neutral400)),
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
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 44,
                  columns: [
                    DataColumn(label: Text(AppStrings.dateColumn)),
                    DataColumn(label: Text(AppStrings.present), numeric: true),
                    DataColumn(label: Text(AppStrings.absent), numeric: true),
                    DataColumn(label: Text(AppStrings.late), numeric: true),
                  ],
                  rows: calendar.map((day) {
                    final total = day.present + day.absent + day.late;
                    final pct = total > 0
                        ? (day.present / total * 100).toStringAsFixed(0)
                        : '0';
                    return DataRow(cells: [
                      DataCell(Text(_fmt(day.date))),
                      DataCell(Text(
                        '${day.present} ($pct%)',
                        style: const TextStyle(color: AppColors.success500),
                      )),
                      DataCell(Text(
                        '${day.absent}',
                        style: const TextStyle(color: AppColors.error500),
                      )),
                      DataCell(Text(
                        '${day.late}',
                        style: const TextStyle(color: AppColors.warning500),
                      )),
                    ]);
                  }).toList(),
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
