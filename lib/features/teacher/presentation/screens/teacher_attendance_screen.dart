import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/teacher/attendance_model.dart';
import '../providers/teacher_attendance_provider.dart';
import '../../../../design_system/design_system.dart';


const Color _accent = AppColors.success500;

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherSectionsProvider);
    });
  }

  Future<void> _pickDate() async {
    final notifier = ref.read(teacherAttendanceProvider.notifier);
    final current = ref.read(teacherAttendanceProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) notifier.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(teacherSectionsProvider);
    final attState = ref.watch(teacherAttendanceProvider);
    final notifier = ref.read(teacherAttendanceProvider.notifier);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Student Attendance',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/teacher/attendance/report'),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Reports'),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Section picker + Date picker
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: sectionsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    data: (sections) => DropdownButtonFormField<String>(
                      initialValue: attState.selectedSection?.sectionId,
                      decoration: const InputDecoration(
                        labelText: AppStrings.selectSection,
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
                        final section = sections
                            .firstWhere((s) => s.sectionId == val);
                        notifier.selectSection(section);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        suffixIcon:
                            Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(_formatDate(attState.selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Messages
            if (attState.errorMessage != null)
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(attState.errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),

            if (attState.successMessage != null)
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(attState.successMessage!,
                    style: const TextStyle(color: _accent)),
              ),

            if (attState.selectedSection == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fact_check_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      AppSpacing.vGapLg,
                      Text(AppStrings.selectSectionToMark,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )
            else if (attState.isLoading)
              Expanded(
                  child: AppLoaderScreen())
            else ...[
              // Summary bar
              _SummaryBar(summary: notifier.liveSummary),
              AppSpacing.vGapSm,

              // Mark all present + locked indicator
              Row(
                children: [
                  if (attState.attendance?.isLocked == true)
                    Chip(
                      avatar: const Icon(Icons.lock, size: 16),
                      label: const Text(AppStrings.locked),
                      backgroundColor: AppColors.error500.withValues(alpha: 0.1),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: notifier.markAllPresent,
                      child: const Text(AppStrings.markAllPresent),
                    ),
                  const Spacer(),
                  Text(
                    '${attState.editableRecords.length} students',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              AppSpacing.vGapSm,

              // Student list
              Expanded(
                child: attState.editableRecords.isEmpty
                    ? Center(
                        child: Text(AppStrings.noStudentsFound,
                            style: Theme.of(context).textTheme.bodyLarge))
                    : ListView.builder(
                        itemCount: attState.editableRecords.length,
                        itemBuilder: (context, i) {
                          final record = attState.editableRecords[i];
                          return _StudentAttendanceRow(
                            record: record,
                            isLocked:
                                attState.attendance?.isLocked ?? false,
                            onStatusChanged: (status) =>
                                notifier.updateStudentStatus(
                                    record.studentId, status),
                            onRemarksChanged: (remarks) =>
                                notifier.updateStudentRemarks(
                                    record.studentId, remarks),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: attState.selectedSection != null &&
              attState.editableRecords.isNotEmpty &&
              !(attState.attendance?.isLocked ?? false)
          ? SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: FilledButton(
                  onPressed: attState.isSaving
                      ? null
                      : () async {
                          await notifier.saveAttendance();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: attState.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(AppStrings.saveAttendance,
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            )
          : null,
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

// ── Summary Bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.summary});
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryChip('Total', '${summary.total}', AppColors.neutral400),
            _SummaryChip('Present', '${summary.present}', _accent),
            _SummaryChip('Absent', '${summary.absent}', AppColors.error500),
            _SummaryChip('Late', '${summary.late}', AppColors.warning500),
            _SummaryChip('Half Day', '${summary.halfDay}', AppColors.secondary500),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.brLg,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ),
        AppSpacing.vGapXs,
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral400)),
      ],
    );
  }
}

// ── Student Attendance Row ───────────────────────────────────────────────────

class _StudentAttendanceRow extends StatefulWidget {
  const _StudentAttendanceRow({
    required this.record,
    required this.isLocked,
    required this.onStatusChanged,
    required this.onRemarksChanged,
  });

  final StudentAttendanceRecord record;
  final bool isLocked;
  final void Function(String) onStatusChanged;
  final void Function(String) onRemarksChanged;

  @override
  State<_StudentAttendanceRow> createState() => _StudentAttendanceRowState();
}

class _StudentAttendanceRowState extends State<_StudentAttendanceRow> {
  bool _showRemarks = false;
  late TextEditingController _remarksCtrl;

  @override
  void initState() {
    super.initState();
    _remarksCtrl = TextEditingController(text: widget.record.remarks ?? '');
    _showRemarks = widget.record.remarks?.isNotEmpty == true;
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    widget.record.rollNo?.toString() ?? '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      Text(
                        widget.record.admissionNo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'PRESENT', label: Text('P')),
                    ButtonSegment(value: 'ABSENT', label: Text('A')),
                    ButtonSegment(value: 'LATE', label: Text('L')),
                    ButtonSegment(value: 'HALF_DAY', label: Text('H')),
                  ],
                  selected: {widget.record.status},
                  onSelectionChanged: widget.isLocked
                      ? null
                      : (vals) {
                          if (vals.isNotEmpty) {
                            widget.onStatusChanged(vals.first);
                          }
                        },
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                AppSpacing.hGapXs,
                IconButton(
                  icon: Icon(
                    _showRemarks ? Icons.notes : Icons.note_add_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _showRemarks = !_showRemarks),
                  tooltip: 'Remarks',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (_showRemarks)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 32),
                child: TextField(
                  controller: _remarksCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Remarks (optional)',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: widget.onRemarksChanged,
                  enabled: !widget.isLocked,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
