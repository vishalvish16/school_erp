import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/teacher/teacher_dashboard_model.dart';
import '../providers/teacher_dashboard_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDash = ref.watch(teacherDashboardProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teacherDashboardProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncDash.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(teacherDashboardProvider),
          ),
          data: (dash) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(teacher: dash.teacher),
              AppSpacing.vGapXl,
              _buildStatsGrid(context, dash.stats, isWide),
              AppSpacing.vGapXl,
              if (dash.todaySchedule.isNotEmpty) ...[
                _TodayScheduleSection(schedule: dash.todaySchedule),
                AppSpacing.vGapXl,
              ],
              if (dash.pendingActions.isNotEmpty) ...[
                _PendingActionsSection(actions: dash.pendingActions),
                AppSpacing.vGapXl,
              ],
              if (dash.classTeacherOf != null)
                _ClassTeacherCard(info: dash.classTeacherOf!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, TeacherStats stats, bool isWide) {
    final cards = [
      _StatCard(
        icon: Icons.class_outlined,
        value: '${stats.totalSections}',
        label: 'My Sections',
        color: _accent,
      ),
      _StatCard(
        icon: Icons.people,
        value: '${stats.totalStudents}',
        label: 'Total Students',
        color: AppColors.secondary500,
      ),
      _StatCard(
        icon: Icons.pending_actions,
        value: '${stats.attendancePendingToday}',
        label: 'Pending Attendance',
        color: AppColors.warning500,
        onTap: () => context.go('/teacher/attendance'),
      ),
      _StatCard(
        icon: Icons.assignment,
        value: '${stats.homeworkActive}',
        label: 'Active Homework',
        subtitle: '${stats.homeworkDueThisWeek} due this week',
        color: Colors.purple,
        onTap: () => context.go('/teacher/homework'),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: cards[0]),
          AppSpacing.hGapMd,
          Expanded(child: cards[1]),
        ]),
        AppSpacing.vGapMd,
        Row(children: [
          Expanded(child: cards[2]),
          AppSpacing.hGapMd,
          Expanded(child: cards[3]),
        ]),
      ],
    );
  }
}

// ── Welcome Header ───────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.teacher});
  final TeacherInfo teacher;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _accent.withValues(alpha: 0.15),
              backgroundImage: teacher.photoUrl != null &&
                      teacher.photoUrl!.isNotEmpty
                  ? NetworkImage(teacher.photoUrl!)
                  : null,
              child: teacher.photoUrl == null || teacher.photoUrl!.isEmpty
                  ? Text(
                      _initials(teacher.name),
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${teacher.name}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.vGapXs,
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: AppRadius.brXs,
                        ),
                        child: Text(
                          teacher.designation,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        teacher.employeeNo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'TC';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'TC';
  }
}

// ── Today's Schedule ─────────────────────────────────────────────────────────

class _TodayScheduleSection extends StatelessWidget {
  const _TodayScheduleSection({required this.schedule});
  final List<SchedulePeriod> schedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.vGapMd,
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: schedule.length,
            separatorBuilder: (_, _) => AppSpacing.hGapMd,
            itemBuilder: (context, i) {
              final p = schedule[i];
              return SizedBox(
                width: 160,
                child: Card(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: AppRadius.brXs,
                              ),
                              child: Text(
                                'P${p.periodNo}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _accent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${p.startTime}–${p.endTime}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.neutral400),
                            ),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          p.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          '${p.className} - ${p.sectionName}${p.room != null ? '  •  ${p.room}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Pending Actions ──────────────────────────────────────────────────────────

class _PendingActionsSection extends StatelessWidget {
  const _PendingActionsSection({required this.actions});
  final List<PendingAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Actions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        AppSpacing.vGapMd,
        ...actions.map((a) => Card(
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warning500.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning500, size: 20),
                ),
                title: Text(a.label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    if (a.type == 'ATTENDANCE_PENDING') {
                      context.go('/teacher/attendance');
                    }
                  },
                  child: const Text(AppStrings.takeAction),
                ),
              ),
            )),
      ],
    );
  }
}

// ── Class Teacher Card ───────────────────────────────────────────────────────

class _ClassTeacherCard extends StatelessWidget {
  const _ClassTeacherCard({required this.info});
  final ClassTeacherInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary500.withValues(alpha: 0.12),
                borderRadius: AppRadius.brLg,
              ),
              child: const Icon(Icons.school, color: AppColors.secondary500, size: 24),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Teacher',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral400,
                    ),
                  ),
                  Text(
                    '${info.className} - ${info.sectionName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${info.studentCount} students',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.go('/teacher/attendance'),
              child: const Text(AppStrings.attendance),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          AppSpacing.vGapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brLg,
              child: content,
            )
          : content,
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppSpacing.vGapLg,
            Text(AppStrings.couldNotLoadDashboard,
                style: Theme.of(context).textTheme.titleMedium),
            AppSpacing.vGapSm,
            Text(error,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
