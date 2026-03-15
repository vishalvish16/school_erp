// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_attendance_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/attendance_model.dart';
import '../providers/school_admin_attendance_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../providers/school_admin_students_provider.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class SchoolAdminAttendanceScreen extends ConsumerStatefulWidget {
  const SchoolAdminAttendanceScreen({super.key});

  @override
  ConsumerState<SchoolAdminAttendanceScreen> createState() =>
      _SchoolAdminAttendanceScreenState();
}

class _SchoolAdminAttendanceScreenState
    extends ConsumerState<SchoolAdminAttendanceScreen> {
  // local attendance entries — mutable per student
  final Map<String, AttendanceEntry> _entries = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(schoolAdminAttendanceProvider);
    final classesState = ref.watch(schoolAdminClassesProvider);
    final studentsState = ref.watch(schoolAdminStudentsProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    // Sync entries whenever students change
    if (studentsState.students.isNotEmpty && _entries.isEmpty) {
      for (final s in studentsState.students) {
        _entries[s.id] = AttendanceEntry(
          studentId: s.id,
          studentName: s.fullName,
          rollNo: s.rollNo,
        );
      }
    }

    // Overlay existing attendance records
    for (final rec in attendanceState.records) {
      if (_entries.containsKey(rec.studentId)) {
        _entries[rec.studentId]!.status = rec.status;
        _entries[rec.studentId]!.remarks = rec.remarks;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mark Attendance',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.go('/school-admin/attendance/report'),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Monthly Report'),
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Selectors: class, section, date
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _ClassSelector(classes: classesState.classes),
                if (attendanceState.selectedClassId != null)
                  _SectionSelector(
                    classId: attendanceState.selectedClassId!,
                    classes: classesState.classes,
                  ),
                _DateSelector(selectedDate: attendanceState.selectedDate),
              ],
            ),
            AppSpacing.vGapLg,

            if (attendanceState.errorMessage != null)
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
                child: Text(attendanceState.errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13)),
              ),

            // Attendance grid
            if (attendanceState.selectedSectionId == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'Select a class and section to mark attendance',
                    style: TextStyle(color: AppColors.neutral400),
                  ),
                ),
              )
            else if (attendanceState.isLoading || studentsState.isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (studentsState.students.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No students in this section',
                      style: TextStyle(color: AppColors.neutral400)),
                ),
              )
            else ...[
              // Quick select row
              _QuickMarkRow(
                onMarkAll: (status) {
                  setState(() {
                    for (final e in _entries.values) {
                      e.status = status;
                    }
                  });
                },
              ),
              AppSpacing.vGapSm,
              Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: studentsState.students.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final student = studentsState.students[i];
                      final entry = _entries[student.id] ??
                          AttendanceEntry(
                            studentId: student.id,
                            studentName: student.fullName,
                            rollNo: student.rollNo,
                          );
                      return _AttendanceRow(
                        entry: entry,
                        onStatusChange: (status) {
                          setState(() {
                            _entries[student.id] = entry..status = status;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              AppSpacing.vGapMd,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: attendanceState.isSaving ? null : _saveAttendance,
                  icon: attendanceState.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(attendanceState.isSaving
                      ? 'Saving...'
                      : 'Save Attendance'),
                  style: FilledButton.styleFrom(backgroundColor: _accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final records = _entries.values
        .map((e) => {
              'studentId': e.studentId,
              'status': e.status,
              if (e.remarks != null && e.remarks!.isNotEmpty)
                'remarks': e.remarks,
            })
        .toList();
    final ok = await ref
        .read(schoolAdminAttendanceProvider.notifier)
        .saveAttendance(records);
    if (ok && mounted) {
      AppSnackbar.success(context, AppStrings.attendanceSaved);
    }
  }
}

// ── Selectors ─────────────────────────────────────────────────────────────────

class _ClassSelector extends ConsumerWidget {
  const _ClassSelector({required this.classes});
  final List classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminAttendanceProvider);
    return DropdownButton<String?>(
      value: state.selectedClassId,
      hint: const Text('Select Class'),
      underline: const SizedBox.shrink(),
      items: [
        for (final c in classes)
          DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
      ],
      onChanged: (v) {
        if (v == null) return;
        ref.read(schoolAdminAttendanceProvider.notifier).setClass(v);
        ref
            .read(schoolAdminStudentsProvider.notifier)
            .setClassFilter(v);
      },
    );
  }
}

class _SectionSelector extends ConsumerWidget {
  const _SectionSelector({required this.classId, required this.classes});
  final String classId;
  final List classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(schoolAdminAttendanceProvider);
    final cls = classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => null,
    );
    if (cls == null) return const SizedBox.shrink();
    final sections = cls.sections as List;
    return DropdownButton<String?>(
      value: attendanceState.selectedSectionId,
      hint: const Text('Select Section'),
      underline: const SizedBox.shrink(),
      items: [
        for (final s in sections)
          DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
      ],
      onChanged: (v) {
        if (v == null) return;
        ref.read(schoolAdminAttendanceProvider.notifier).setSection(v);
        ref
            .read(schoolAdminStudentsProvider.notifier)
            .setSectionFilter(v);
      },
    );
  }
}

class _DateSelector extends ConsumerWidget {
  const _DateSelector({required this.selectedDate});
  final String selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final parts = selectedDate.split('-');
        final initial = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          ref
              .read(schoolAdminAttendanceProvider.notifier)
              .setDate(formatted);
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(selectedDate),
    );
  }
}

// ── Quick Mark ────────────────────────────────────────────────────────────────

class _QuickMarkRow extends StatelessWidget {
  const _QuickMarkRow({required this.onMarkAll});
  final void Function(String) onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Mark all as:',
            style: Theme.of(context).textTheme.bodySmall),
        AppSpacing.hGapSm,
        _quickBtn('Present', 'PRESENT', AppColors.success500),
        AppSpacing.hGapXs,
        _quickBtn('Absent', 'ABSENT', AppColors.error500),
        AppSpacing.hGapXs,
        _quickBtn('Late', 'LATE', AppColors.warning500),
      ],
    );
  }

  Widget _quickBtn(String label, String status, Color color) {
    return OutlinedButton(
      onPressed: () => onMarkAll(status),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ── Attendance Row ────────────────────────────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.entry,
    required this.onStatusChange,
  });

  final AttendanceEntry entry;
  final void Function(String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _statusColor(entry.status).withValues(alpha: 0.15),
        child: Text(
          entry.rollNo?.toString() ?? '#',
          style: TextStyle(
              fontSize: 11,
              color: _statusColor(entry.status),
              fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(entry.studentName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'PRESENT',
            label: Text('P', style: TextStyle(fontSize: 11)),
          ),
          ButtonSegment(
            value: 'ABSENT',
            label: Text('A', style: TextStyle(fontSize: 11)),
          ),
          ButtonSegment(
            value: 'LATE',
            label: Text('L', style: TextStyle(fontSize: 11)),
          ),
        ],
        selected: {entry.status},
        onSelectionChanged: (set) => onStatusChange(set.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor:
              _statusColor(entry.status).withValues(alpha: 0.15),
          selectedForegroundColor: _statusColor(entry.status),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'PRESENT' => AppColors.success500,
        'ABSENT' => AppColors.error500,
        'LATE' => AppColors.warning500,
        _ => AppColors.neutral400,
      };
}
