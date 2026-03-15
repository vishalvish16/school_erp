// =============================================================================
// FILE: lib/features/student/presentation/screens/student_attendance_screen.dart
// PURPOSE: Attendance screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  String _selectedMonth = _currentMonthKey();

  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final asyncAttendance = ref.watch(studentAttendanceProvider(_selectedMonth));
    final asyncSummary = ref.watch(studentAttendanceSummaryProvider(_selectedMonth));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentAttendanceProvider(_selectedMonth));
        ref.invalidate(studentAttendanceSummaryProvider(_selectedMonth));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.studentAttendanceTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _MonthDropdown(
                  value: _selectedMonth,
                  onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                ),
              ],
            ),
            AppSpacing.vGapXl,
            asyncSummary.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (summary) => _buildSummaryCards(context, summary),
            ),
            AppSpacing.vGapXl,
            asyncAttendance.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, s) => Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(err.toString().replaceAll('Exception: ', '')),
                      AppSpacing.vGapLg,
                      FilledButton(
                        onPressed: () => ref.invalidate(studentAttendanceProvider(_selectedMonth)),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (att) => att.records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fact_check_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                          AppSpacing.vGapLg,
                          Text(
                            AppStrings.noAttendanceRecords,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : _buildRecordsGrid(context, att.records),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, dynamic summary) {
    final cards = [
      _SummaryChip(label: AppStrings.present, value: '${summary.present}', color: AppColors.success500),
      _SummaryChip(label: AppStrings.absent, value: '${summary.absent}', color: AppColors.error500),
      _SummaryChip(label: AppStrings.late, value: '${summary.late}', color: AppColors.warning500),
      _SummaryChip(label: AppStrings.halfDay, value: '${summary.halfDay}', color: AppColors.neutral500),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: cards.map((c) => c).toList(),
    );
  }

  Widget _buildRecordsGrid(BuildContext context, List records) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: records.map<Widget>((r) {
        final status = r.status.toString().toUpperCase();
        Color color = _accent;
        if (status == 'PRESENT') {
          color = AppColors.success500;
        } else if (status == 'ABSENT') {
          color = AppColors.error500;
        } else if (status == 'LATE') {
          color = AppColors.warning500;
        } else if (status == 'HALF_DAY') {
          color = AppColors.neutral500;
        }
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: AppRadius.brMd,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                r.date.toString().split('-').last,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                status == 'PRESENT' ? 'P' : status == 'ABSENT' ? 'A' : status == 'LATE' ? 'L' : 'H',
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          AppSpacing.hGapSm,
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({required this.value, required this.onChanged});

  final String value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return DropdownButton<String>(
      value: value,
      items: months.map((m) {
        final parts = m.split('-');
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final label = '${monthNames[monthNum - 1]} ${parts[0]}';
        return DropdownMenuItem(value: m, child: Text(label));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
