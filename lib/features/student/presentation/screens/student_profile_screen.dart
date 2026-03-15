// =============================================================================
// FILE: lib/features/student/presentation/screens/student_profile_screen.dart
// PURPOSE: Profile screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(studentProfileProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentProfileProvider),
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
          error: (err, _) => Card(
            child: Padding(
              padding: AppSpacing.paddingXl,
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  AppSpacing.vGapLg,
                  Text(err.toString().replaceAll('Exception: ', '')),
                  AppSpacing.vGapLg,
                  FilledButton(
                    onPressed: () => ref.invalidate(studentProfileProvider),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.studentProfileTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapXl,
              _buildProfileCard(context, profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic profile) {
    final scheme = Theme.of(context).colorScheme;
    final classSection = [
      profile.class_?.name,
      profile.section?.name,
    ].where((x) => x != null && x.toString().isNotEmpty).join(' - ');
    return Card(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  backgroundImage: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _accent,
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
                        profile.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      AppSpacing.vGapXs,
                      _InfoRow(label: AppStrings.admissionNo, value: profile.admissionNo),
                      if (classSection.isNotEmpty)
                        _InfoRow(label: AppStrings.classSection, value: classSection),
                      if (profile.rollNo != null)
                        _InfoRow(label: AppStrings.rollNo, value: '${profile.rollNo}'),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXl,
            AppDivider.horizontal,
            AppSpacing.vGapLg,
            _InfoRow(label: AppStrings.dateOfBirth, value: profile.dateOfBirth ?? AppStrings.dash),
            AppSpacing.vGapSm,
            _InfoRow(label: AppStrings.bloodGroup, value: profile.bloodGroup ?? AppStrings.dash),
            AppSpacing.vGapSm,
            _InfoRow(label: AppStrings.gender, value: profile.gender),
            AppSpacing.vGapLg,
            Text(
              AppStrings.parentContact,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapSm,
            _InfoRow(label: AppStrings.parentName, value: profile.parentName ?? AppStrings.dash),
            _InfoRow(label: AppStrings.phone, value: profile.parentPhone ?? AppStrings.dash),
            _InfoRow(label: AppStrings.email, value: profile.parentEmail ?? AppStrings.dash),
            if (profile.parentRelation != null)
              _InfoRow(label: 'Relation', value: profile.parentRelation!),
            AppSpacing.vGapLg,
            Text(
              AppStrings.address,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.vGapSm,
            Text(profile.address ?? AppStrings.dash),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
