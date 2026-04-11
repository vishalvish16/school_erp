// =============================================================================
// FILE: lib/features/parent/presentation/screens/parent_children_list_screen.dart
// PURPOSE: List of linked children for Parent Portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/parent/child_summary_model.dart';
import '../../data/parent_children_provider.dart';

class ParentChildrenListScreen extends ConsumerWidget {
  const ParentChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(parentChildrenProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(parentChildrenProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth),
            child: asyncChildren.when(
              loading: () => const Padding(
                padding: AppSpacing.paddingXl,
                child: AppLoaderScreen(),
              ),
              error: (err, _) => _ErrorCard(
                error: err.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(parentChildrenProvider),
              ),
              data: (children) {
                if (children.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myChildren,
                      style: AppTextStyles.h4(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      AppStrings.myChildrenSubtitle,
                      style: AppTextStyles.bodySm(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
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
        ),
      ),
    );
  }

  Widget _buildTable(
      BuildContext context, List<ChildSummaryModel> children) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: AppOpacity.shadow),
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: AppSpacing.xl4), // avatar col
                AppSpacing.hGapLg,
                Expanded(
                  child: Text(
                    AppStrings.parentColName,
                    style: AppTextStyles.tableHeader(
                        color: scheme.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    AppStrings.parentColClass,
                    style: AppTextStyles.tableHeader(
                        color: scheme.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Text(
                    AppStrings.parentColAdmNo,
                    style: AppTextStyles.tableHeader(
                        color: scheme.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: AppSpacing.xl5,
                  child: Center(
                    child: Text(
                      AppStrings.parentColAction,
                      style: AppTextStyles.tableHeader(
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ...children.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isEven = i % 2 == 0;
            return InkWell(
              onTap: () => context.go('/parent/children/${c.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : scheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant
                          .withValues(alpha: AppOpacity.medium),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppSpacing.lg + 2,
                      backgroundColor:
                          AppColors.primary500.withValues(alpha: AppOpacity.focus),
                      backgroundImage: c.photoUrl != null
                          ? NetworkImage(c.photoUrl!)
                          : null,
                      child: c.photoUrl == null
                          ? Text(
                              c.fullName.isNotEmpty
                                  ? c.fullName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.caption(color: AppColors.primary500),
                            )
                          : null,
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Text(
                        c.fullName,
                        style: AppTextStyles.bodyMd(
                            color: scheme.onSurface),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        c.classSection,
                        style: AppTextStyles.bodySm(
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: Text(
                        c.admissionNo,
                        style: AppTextStyles.code(
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                    SizedBox(
                      width: AppSpacing.xl5,
                      child: Center(
                        child: IconButton(
                          onPressed: () =>
                              context.go('/parent/children/${c.id}'),
                          icon: Icon(
                            Icons.open_in_new,
                            size: AppIconSize.sm,
                            color: AppColors.primary500,
                          ),
                          tooltip: AppStrings.viewChildTooltip(c.fullName),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              AppStrings.childrenLinkedFooter(children.length),
              style: AppTextStyles.bodySm(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(
      BuildContext context, List<ChildSummaryModel> children) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, i) => AppSpacing.vGapMd,
      itemBuilder: (_, i) {
        final c = children[i];
        return Card(
          shape: AppRadius.cardShape,
          child: InkWell(
            onTap: () => context.go('/parent/children/${c.id}'),
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSpacing.xl,
                    backgroundColor:
                        AppColors.primary500.withValues(alpha: AppOpacity.focus),
                    backgroundImage:
                        c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                    child: c.photoUrl == null
                        ? Text(
                            c.fullName.isNotEmpty
                                ? c.fullName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.h5(color: AppColors.primary500),
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
                          style: AppTextStyles.h6(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface),
                        ),
                        Text(
                          c.classSection,
                          style: AppTextStyles.bodySm(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                        Text(
                          c.admissionNo,
                          style: AppTextStyles.bodySm(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: AppIconSize.lg),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: AppIconSize.xl4,
            color: scheme.outline,
          ),
          AppSpacing.vGapLg,
          Text(
            AppStrings.noChildrenLinked,
            style: AppTextStyles.h5(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapSm,
          Text(
            AppStrings.noChildrenLinkedHint,
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.dialogPadding,
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapLg,
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: scheme.onSurface),
            ),
            AppSpacing.vGapLg,
            FilledButton.icon(
                icon: Icon(Icons.refresh, size: AppIconSize.md),
                label: const Text(AppStrings.retry),
                onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
