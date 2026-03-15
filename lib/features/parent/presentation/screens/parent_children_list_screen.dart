// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_children_list_screen.dart
// PURPOSE: List of linked children for Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/child_summary_model.dart';
import '../../data/parent_children_provider.dart';

const Color _accent = AppColors.success500;

class ParentChildrenListScreen extends ConsumerWidget {
  const ParentChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(parentChildrenProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(parentChildrenProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: asyncChildren.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => _ErrorCard(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(parentChildrenProvider),
          ),
          data: (children) {
            if (children.isEmpty) {
              return _EmptyState();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.myChildren,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                AppSpacing.vGapXs,
                Text(
                  AppStrings.myChildrenSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                AppSpacing.vGapXl,
                isWide
                    ? _buildTable(context, children)
                    : _buildCardList(context, children),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<ChildSummaryModel> children) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text(AppStrings.dash)),
            DataColumn(label: Text(AppStrings.parentColName)),
            DataColumn(label: Text(AppStrings.parentColClass)),
            DataColumn(label: Text(AppStrings.parentColAdmNo)),
            DataColumn(label: Text(AppStrings.view)),
          ],
          rows: children
              .map(
                (c) => DataRow(
                  cells: [
                    DataCell(
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _accent.withValues(alpha: 0.15),
                        backgroundImage:
                            c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                        child: c.photoUrl == null
                            ? Text(
                                c.fullName.isNotEmpty
                                    ? c.fullName.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: _accent,
                                    fontWeight: FontWeight.w600),
                              )
                            : null,
                      ),
                    ),
                    DataCell(Text(c.fullName)),
                    DataCell(Text(c.classSection)),
                    DataCell(Text(c.admissionNo)),
                    DataCell(
                      TextButton(
                        onPressed: () => context.go('/parent/children/${c.id}'),
                        child: const Text(AppStrings.view),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context, List<ChildSummaryModel> children) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, __) => AppSpacing.vGapMd,
      itemBuilder: (_, i) {
        final c = children[i];
        return Card(
          child: InkWell(
            onTap: () => context.go('/parent/children/${c.id}'),
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _accent.withValues(alpha: 0.15),
                    backgroundImage:
                        c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                    child: c.photoUrl == null
                        ? Text(
                            c.fullName.isNotEmpty
                                ? c.fullName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 18),
                          )
                        : null,
                  ),
                  AppSpacing.hGapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          c.classSection,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          c.admissionNo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          AppSpacing.vGapLg,
          Text(
            AppStrings.noChildrenLinked,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapSm,
          Text(
            AppStrings.noChildrenLinkedHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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
            Text(error, textAlign: TextAlign.center),
            AppSpacing.vGapLg,
            FilledButton(
                onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      ),
    );
  }
}
