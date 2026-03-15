// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_attendance_screen.dart
// PURPOSE: Daily bulk attendance marking for non-teaching staff.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../providers/school_admin_non_teaching_attendance_provider.dart';
import '../../../../models/school_admin/non_teaching_attendance_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

const List<String> _statusOptions = [
  'PRESENT',
  'ABSENT',
  'HALF_DAY',
  'ON_LEAVE',
  'LATE',
  'HOLIDAY',
];

const List<String> _categories = [
  'FINANCE',
  'LIBRARY',
  'LABORATORY',
  'ADMIN_SUPPORT',
  'GENERAL',
];

class SchoolAdminNonTeachingAttendanceScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingAttendanceScreen({super.key});

  @override
  ConsumerState<SchoolAdminNonTeachingAttendanceScreen> createState() =>
      _State();
}

class _State
    extends ConsumerState<SchoolAdminNonTeachingAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(nonTeachingAttendanceProvider.notifier)
          .loadForDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nonTeachingAttendanceProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final summary = state.summary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Non-Teaching Attendance',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapLg,

            // Date selector
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        final prev = state.selectedDate
                            .subtract(const Duration(days: 1));
                        ref
                            .read(nonTeachingAttendanceProvider.notifier)
                            .changeDate(prev);
                      },
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      _formatDate(state.selectedDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    AppSpacing.hGapSm,
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final next = state.selectedDate
                            .add(const Duration(days: 1));
                        if (!next.isAfter(DateTime.now())) {
                          ref
                              .read(nonTeachingAttendanceProvider
                                  .notifier)
                              .changeDate(next);
                        }
                      },
                    ),
                    const Spacer(),
                    _CategoryFilterChips(),
                  ],
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // Summary row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in summary.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SummaryBox(
                        label: NonTeachingAttendanceModel.labelForStatus(
                            entry.key),
                        count: entry.value,
                        color: NonTeachingAttendanceModel.colorForStatus(
                            entry.key),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.vGapMd,

            // Error
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),

            // Staff list
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.staffWithAttendance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.how_to_reg_outlined,
                                  size: 56,
                                  color: AppColors.neutral400),
                              AppSpacing.vGapMd,
                              const Text(
                                  'No staff found for selected filters'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount:
                              state.staffWithAttendance.length,
                          itemBuilder: (ctx, i) {
                            final staff =
                                state.staffWithAttendance[i];
                            return _AttendanceRow(
                              staff: staff,
                              isWide: isWide,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : _saveAll,
        backgroundColor: _accent,
        icon: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(state.isSaving ? 'Saving...' : 'Save All'),
      ),
    );
  }

  Future<void> _saveAll() async {
    final ok = await ref
        .read(nonTeachingAttendanceProvider.notifier)
        .saveAll();
    if (mounted) {
      if (ok) {
        AppSnackbar.success(context, 'Attendance saved');
      } else {
        AppSnackbar.error(context, 'Failed to save');
      }
    }
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dayName = days[d.weekday - 1];
    return '$dayName, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Category filter chips ─────────────────────────────────────────────────────

class _CategoryFilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nonTeachingAttendanceProvider);
    return DropdownButton<String?>(
      value: state.categoryFilter,
      hint: const Text('Category'),
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(
            value: null, child: Text('All')),
        for (final c in _categories)
          DropdownMenuItem<String?>(
              value: c, child: Text(_catLabel(c))),
      ],
      onChanged: (v) => ref
          .read(nonTeachingAttendanceProvider.notifier)
          .setCategoryFilter(v),
    );
  }

  String _catLabel(String c) {
    switch (c) {
      case 'FINANCE': return 'Finance';
      case 'LIBRARY': return 'Library';
      case 'LABORATORY': return 'Lab';
      case 'ADMIN_SUPPORT': return 'Admin';
      default: return 'General';
    }
  }
}

// ── Summary box ───────────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ── Attendance row per staff ───────────────────────────────────────────────────

class _AttendanceRow extends ConsumerStatefulWidget {
  const _AttendanceRow({required this.staff, required this.isWide});
  final Map<String, dynamic> staff;
  final bool isWide;

  @override
  ConsumerState<_AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends ConsumerState<_AttendanceRow> {
  late String _status;
  final _checkInCtrl = TextEditingController();
  final _checkOutCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final staffId = widget.staff['id'] as String? ?? '';
    final existing = ref
        .read(nonTeachingAttendanceProvider)
        .localEdits[staffId];
    _status = existing?['status'] as String? ??
        widget.staff['attendanceStatus'] as String? ??
        'ABSENT';
    _checkInCtrl.text =
        existing?['check_in_time'] as String? ?? '';
    _checkOutCtrl.text =
        existing?['check_out_time'] as String? ?? '';
    _remarksCtrl.text =
        existing?['remarks'] as String? ?? '';
  }

  @override
  void dispose() {
    _checkInCtrl.dispose();
    _checkOutCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _updateRecord() {
    final staffId = widget.staff['id'] as String? ?? '';
    ref.read(nonTeachingAttendanceProvider.notifier).updateLocalRecord(
          staffId,
          _status,
          checkIn: _checkInCtrl.text.trim().isEmpty
              ? null
              : _checkInCtrl.text.trim(),
          checkOut: _checkOutCtrl.text.trim().isEmpty
              ? null
              : _checkOutCtrl.text.trim(),
          remarks: _remarksCtrl.text.trim().isEmpty
              ? null
              : _remarksCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (widget.staff['firstName'] ??
            widget.staff['first_name'] ?? '') as String;
    final lastName = (widget.staff['lastName'] ??
            widget.staff['last_name'] ?? '') as String;
    final fullName = '$firstName $lastName'.trim();
    final roleMap = widget.staff['role'] as Map<String, dynamic>?;
    final roleName = (roleMap?['displayName'] ??
        roleMap?['display_name'] ?? '') as String;
    final empNo = (widget.staff['employeeNo'] ??
        widget.staff['employee_no'] ?? '') as String;

    final statusColor =
        NonTeachingAttendanceModel.colorForStatus(_status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      statusColor.withValues(alpha: 0.15),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                        .toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                AppSpacing.hGapMd,
                // Name + role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName.isEmpty ? empNo : fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      if (roleName.isNotEmpty)
                        Text(roleName,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.neutral400)),
                    ],
                  ),
                ),
                // Status dropdown
                DropdownButton<String>(
                  value: _status,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  selectedItemBuilder: (ctx) => _statusOptions
                      .map((s) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: NonTeachingAttendanceModel
                                  .colorForStatus(s)
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  AppRadius.brLg,
                            ),
                            child: Text(
                              NonTeachingAttendanceModel
                                  .labelForStatus(s),
                              style: TextStyle(
                                color: NonTeachingAttendanceModel
                                    .colorForStatus(s),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                NonTeachingAttendanceModel
                                    .labelForStatus(s)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _status = v);
                      _updateRecord();
                    }
                  },
                ),
                // Expand toggle
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            // Expanded extras
            if (_expanded) ...[
              AppSpacing.vGapSm,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checkInCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Check-in Time',
                        hintText: 'HH:MM',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateRecord(),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: TextField(
                      controller: _checkOutCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Check-out Time',
                        hintText: 'HH:MM',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateRecord(),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _remarksCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateRecord(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withValues(alpha: 0.4),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(message,
          style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13)),
    );
  }
}
