// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_attendance_screen.dart
// PURPOSE: Daily bulk attendance marking for non-teaching staff.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../providers/school_admin_non_teaching_attendance_provider.dart';
import '../../../../models/school_admin/non_teaching_attendance_model.dart';
import '../../../../shared/widgets/app_toast.dart';

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
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final scheme = Theme.of(context).colorScheme;
    final summary = state.summary;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        context.go('/school-admin/non-teaching-staff'),
                    tooltip: 'Back',
                  ),
                  AppSpacing.hGapSm,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Non-Teaching Attendance',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Mark daily attendance for support staff',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Date navigator
                  _DateNavigator(state: state),
                  AppSpacing.hGapMd,
                  // Category filter
                  _CategoryFilterDropdown(),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context
                            .go('/school-admin/non-teaching-staff'),
                      ),
                      Expanded(
                        child: Text(
                          'Non-Teaching Attendance',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  _DateNavigator(state: state),
                  AppSpacing.vGapSm,
                  _CategoryFilterDropdown(),
                ],
              ),
            AppSpacing.vGapMd,

            // ── Summary chips ─────────────────────────────────────────────
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summary.entries.length,
                separatorBuilder: (_, _) => AppSpacing.hGapSm,
                itemBuilder: (ctx, i) {
                  final entry = summary.entries.elementAt(i);
                  return _SummaryBox(
                    label: NonTeachingAttendanceModel.labelForStatus(
                        entry.key),
                    count: entry.value,
                    color: NonTeachingAttendanceModel.colorForStatus(
                        entry.key),
                  );
                },
              ),
            ),
            AppSpacing.vGapMd,

            // ── Error ─────────────────────────────────────────────────────
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),

            // ── Staff list ────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? AppLoaderScreen()
                  : state.staffWithAttendance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.how_to_reg_outlined,
                                  size: AppIconSize.xl4,
                                  color: scheme.onSurfaceVariant),
                              AppSpacing.vGapMd,
                              Text(
                                'No staff found for selected filters',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.staffWithAttendance.length,
                          itemBuilder: (ctx, i) {
                            final staff = state.staffWithAttendance[i];
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
        icon: state.isSaving
            ? SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: CircularProgressIndicator(
                    strokeWidth: AppBorderWidth.medium,
                    color: Theme.of(context).colorScheme.onPrimary))
            : const Icon(Icons.save, size: AppIconSize.md),
        label: Text(state.isSaving ? 'Saving...' : 'Save All'),
      ),
    );
  }

  Future<void> _saveAll() async {
    final ok =
        await ref.read(nonTeachingAttendanceProvider.notifier).saveAll();
    if (mounted) {
      if (ok) {
        AppToast.showSuccess(context, 'Attendance saved');
      } else {
        AppToast.showError(context, 'Failed to save');
      }
    }
  }
}

// ── Date Navigator ────────────────────────────────────────────────────────────

class _DateNavigator extends ConsumerWidget {
  const _DateNavigator({required this.state});
  final NonTeachingAttendanceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: AppIconSize.md),
            onPressed: () {
              final prev =
                  state.selectedDate.subtract(const Duration(days: 1));
              ref
                  .read(nonTeachingAttendanceProvider.notifier)
                  .changeDate(prev);
            },
          ),
          Text(
            _formatDate(state.selectedDate),
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: AppIconSize.md),
            onPressed: () {
              final next =
                  state.selectedDate.add(const Duration(days: 1));
              if (!next.isAfter(DateTime.now())) {
                ref
                    .read(nonTeachingAttendanceProvider.notifier)
                    .changeDate(next);
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dayName = days[d.weekday - 1];
    return '$dayName, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Category filter dropdown ──────────────────────────────────────────────────

class _CategoryFilterDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nonTeachingAttendanceProvider);
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
          value: state.categoryFilter,
          hint: const Text('Category', style: TextStyle(fontSize: 13)),
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
                value: null,
                child: Text('All', style: TextStyle(fontSize: 13))),
            for (final c in _categories)
              DropdownMenuItem<String?>(
                  value: c,
                  child: Text(_catLabel(c),
                      style: const TextStyle(fontSize: 13))),
          ],
          onChanged: (v) => ref
              .read(nonTeachingAttendanceProvider.notifier)
              .setCategoryFilter(v),
        ),
      ),
    );
  }

  String _catLabel(String c) {
    switch (c) {
      case 'FINANCE':
        return 'Finance';
      case 'LIBRARY':
        return 'Library';
      case 'LABORATORY':
        return 'Lab';
      case 'ADMIN_SUPPORT':
        return 'Admin';
      default:
        return 'General';
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
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
    _remarksCtrl.text = existing?['remarks'] as String? ?? '';
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
    ref
        .read(nonTeachingAttendanceProvider.notifier)
        .updateLocalRecord(
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
    final scheme = Theme.of(context).colorScheme;
    final firstName = (widget.staff['firstName'] ??
        widget.staff['first_name'] ??
        '') as String;
    final lastName = (widget.staff['lastName'] ??
        widget.staff['last_name'] ??
        '') as String;
    final fullName = '$firstName $lastName'.trim();
    final roleMap = widget.staff['role'] as Map<String, dynamic>?;
    final roleName = (roleMap?['displayName'] ??
        roleMap?['display_name'] ??
        '') as String;
    final empNo = (widget.staff['employeeNo'] ??
        widget.staff['employee_no'] ??
        '') as String;

    final statusColor =
        NonTeachingAttendanceModel.colorForStatus(_status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                      Text(
                        fullName.isEmpty ? empNo : fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      if (roleName.isNotEmpty)
                        Text(
                          roleName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                // Status dropdown — styled pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brLg,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _status,
                      isDense: true,
                      selectedItemBuilder: (ctx) => _statusOptions
                          .map((s) => Text(
                                NonTeachingAttendanceModel
                                    .labelForStatus(s),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
                  ),
                ),
                // Expand toggle
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: AppIconSize.md,
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
                      decoration: InputDecoration(
                        labelText: 'Check-in Time',
                        hintText: 'HH:MM',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: AppRadius.brMd),
                      ),
                      onChanged: (_) => _updateRecord(),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: TextField(
                      controller: _checkOutCtrl,
                      decoration: InputDecoration(
                        labelText: 'Check-out Time',
                        hintText: 'HH:MM',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: AppRadius.brMd),
                      ),
                      onChanged: (_) => _updateRecord(),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _remarksCtrl,
                      decoration: InputDecoration(
                        labelText: 'Remarks',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: AppRadius.brMd),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.error, fontSize: 13),
      ),
    );
  }
}
