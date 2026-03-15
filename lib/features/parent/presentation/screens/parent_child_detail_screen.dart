// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_child_detail_screen.dart
// PURPOSE: Child detail screen with quick links to attendance and fees.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/child_detail_model.dart';
import '../../data/parent_child_detail_provider.dart';

const Color _accent = AppColors.success500;

class ParentChildDetailScreen extends ConsumerWidget {
  const ParentChildDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(parentChildDetailProvider(studentId));
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: asyncChild.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(parentChildDetailProvider(studentId)),
          ),
          data: (child) {
            if (child == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.error),
                    AppSpacing.vGapMd,
                    const Text(AppStrings.notFoundError),
                    AppSpacing.vGapMd,
                    TextButton(
                      onPressed: () => context.go('/parent/children'),
                      child: const Text(AppStrings.back),
                    ),
                  ],
                ),
              );
            }
            return _buildContent(context, child);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ChildDetailModel child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/parent/children'),
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.back,
              ),
              AppSpacing.hGapSm,
              Text(
                AppStrings.childDetails,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.vGapXl,

          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _accent.withValues(alpha: 0.15),
                    backgroundImage: child.photoUrl != null
                        ? NetworkImage(child.photoUrl!)
                        : null,
                    child: child.photoUrl == null
                        ? Text(
                            child.fullName.isNotEmpty
                                ? child.fullName
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 24,
                                color: _accent,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(child.classSection),
                        Text(child.admissionNo),
                        if (child.dateOfBirth != null)
                          Text(
                            'DOB: ${_formatDate(child.dateOfBirth!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vGapXl,

          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () =>
                        context.go('/parent/children/$studentId/attendance'),
                    borderRadius: AppRadius.brLg,
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.15),
                              borderRadius: AppRadius.brMd,
                            ),
                            child: Icon(Icons.event_available, color: _accent),
                          ),
                          AppSpacing.hGapLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.childAttendance,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  AppStrings.viewAttendance,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () =>
                        context.go('/parent/children/$studentId/fees'),
                    borderRadius: AppRadius.brLg,
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.15),
                              borderRadius: AppRadius.brMd,
                            ),
                            child: Icon(Icons.receipt_long, color: _accent),
                          ),
                          AppSpacing.hGapLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.childFees,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  AppStrings.viewFees,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppSpacing.vGapMd,
          Text(error, textAlign: TextAlign.center),
          AppSpacing.vGapMd,
          FilledButton(
              onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
