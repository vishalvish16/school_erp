import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/teacher/teacher_profile_model.dart';
import '../providers/teacher_profile_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(teacherProfileProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teacherProfileProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncProfile.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
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
                  onPressed: () => ref.invalidate(teacherProfileProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
          data: (profile) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(profile: profile),
                  AppSpacing.vGapXl,
                  _DetailsSection(profile: profile),
                  AppSpacing.vGapLg,
                  if (profile.classTeacherOf != null) ...[
                    _ClassTeacherSection(info: profile.classTeacherOf!),
                    AppSpacing.vGapLg,
                  ],
                  _SubjectAssignmentsSection(
                      assignments: profile.subjectAssignments),
                  AppSpacing.vGapLg,
                  if (profile.school != null)
                    _SchoolInfoSection(school: profile.school!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final TeacherProfileModel profile;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'TC';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _accent.withValues(alpha: 0.15),
              backgroundImage: profile.photoUrl != null &&
                      profile.photoUrl!.isNotEmpty
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                  ? Text(
                      _initials(profile.fullName),
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
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
                          profile.designation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ),
                      if (profile.department != null) ...[
                        AppSpacing.hGapSm,
                        Text(profile.department!,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    'Employee No: ${profile.employeeNo}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.profile});
  final TeacherProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.contactAndDetails,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.vGapLg,
            if (profile.email != null)
              _DetailRow(Icons.email_outlined, 'Email', profile.email!),
            if (profile.phone != null) ...[
              AppSpacing.vGapMd,
              _DetailRow(Icons.phone_outlined, 'Phone', profile.phone!),
            ],
            if (profile.joinDate != null) ...[
              AppSpacing.vGapMd,
              _DetailRow(
                  Icons.calendar_today_outlined, 'Joined', profile.joinDate!),
            ],
            if (profile.subjects.isNotEmpty) ...[
              AppSpacing.vGapMd,
              _DetailRow(Icons.subject, 'Subjects',
                  profile.subjects.join(', ')),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutral600),
        AppSpacing.hGapMd,
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral400)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _ClassTeacherSection extends StatelessWidget {
  const _ClassTeacherSection({required this.info});
  final TeacherClassInfo info;

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
              child:
                  const Icon(Icons.school, color: AppColors.secondary500, size: 24),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Teacher Of',
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
          ],
        ),
      ),
    );
  }
}

class _SubjectAssignmentsSection extends StatelessWidget {
  const _SubjectAssignmentsSection({required this.assignments});
  final List<SubjectAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.subjectAssignments,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.vGapMd,
            if (assignments.isEmpty)
              const Text(AppStrings.noAssignments,
                  style: TextStyle(color: AppColors.neutral400))
            else
              ...assignments.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            '${a.subject} — ${a.className} ${a.sectionName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SchoolInfoSection extends StatelessWidget {
  const _SchoolInfoSection({required this.school});
  final TeacherSchoolInfo school;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            Icon(Icons.apartment,
                size: 24, color: AppColors.neutral600),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.school,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.neutral400)),
                  Text(school.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
