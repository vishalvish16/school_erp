// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_student_detail_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/student_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

final _studentDetailProvider =
    FutureProvider.autoDispose.family<StudentModel, String>((ref, id) {
  return ref.read(schoolAdminServiceProvider).getStudentById(id);
});

class SchoolAdminStudentDetailScreen extends ConsumerWidget {
  const SchoolAdminStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudent = ref.watch(_studentDetailProvider(studentId));
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.studentProfile),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_studentDetailProvider(studentId)),
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
          ),
        ],
      ),
      body: asyncStudent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(err.toString().replaceAll('Exception: ', '')),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(_studentDetailProvider(studentId)),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
        data: (student) => SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(student: student),
                    AppSpacing.hGapLg,
                    Expanded(child: _DetailsColumn(student: student)),
                  ],
                )
              : Column(
                  children: [
                    _ProfileCard(student: student),
                    AppSpacing.vGapLg,
                    _DetailsColumn(student: student),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: SizedBox(
          width: 220,
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: _accent.withValues(alpha: 0.2),
                child: Text(
                  '${student.firstName[0]}${student.lastName[0]}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
              AppSpacing.vGapLg,
              Text(
                student.fullName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXs,
              Text(
                student.admissionNo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              AppSpacing.vGapSm,
              _StatusBadge(status: student.status),
              if (student.className != null) ...[
                AppSpacing.vGapSm,
                Chip(
                  label: Text(
                    '${student.className} ${student.sectionName ?? ''}'.trim(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _accent.withValues(alpha: 0.1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsColumn extends StatelessWidget {
  const _DetailsColumn({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          title: AppStrings.personalInformation,
          icon: Icons.person,
          fields: {
            'Gender': student.gender,
            'Date of Birth': _formatDate(student.dateOfBirth),
            'Blood Group': student.bloodGroup ?? '-',
            'Phone': student.phone ?? '-',
            'Email': student.email ?? '-',
            'Address': student.address ?? '-',
          },
        ),
        AppSpacing.vGapMd,
        _InfoCard(
          title: AppStrings.academicInformation,
          icon: Icons.school,
          fields: {
            'Admission No.': student.admissionNo,
            'Admission Date': _formatDate(student.admissionDate),
            'Class': student.className ?? '-',
            'Section': student.sectionName ?? '-',
            'Roll No.': student.rollNo?.toString() ?? '-',
            'Status': student.status,
          },
        ),
        AppSpacing.vGapMd,
        _InfoCard(
          title: AppStrings.parentGuardian,
          icon: Icons.family_restroom,
          fields: {
            'Name': student.parentName ?? '-',
            'Phone': student.parentPhone ?? '-',
            'Email': student.parentEmail ?? '-',
            'Relation': student.parentRelation ?? '-',
          },
        ),
      ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.fields,
  });
  final String title;
  final IconData icon;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: _accent),
                AppSpacing.hGapSm,
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            ...fields.entries.map(
              (e) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => AppColors.success500,
      'INACTIVE' => AppColors.neutral400,
      'TRANSFERRED' => AppColors.warning500,
      _ => AppColors.neutral400,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
