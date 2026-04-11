// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_students_screen.dart
// PURPOSE: Read-only student list screen for the Staff/Clerk portal.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/staff_students_provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';

class StaffStudentsScreen extends ConsumerStatefulWidget {
  const StaffStudentsScreen({super.key});

  @override
  ConsumerState<StaffStudentsScreen> createState() =>
      _StaffStudentsScreenState();
}

class _StaffStudentsScreenState extends ConsumerState<StaffStudentsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffStudentsProvider.notifier).loadStudents();
      ref.read(staffStudentsProvider.notifier).loadClasses();
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(staffStudentsProvider.notifier).setSearch(_searchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _searchCtrl.text.isNotEmpty ||
      ref.read(staffStudentsProvider).filterClassId != null;

  void _clearFilters() {
    _searchCtrl.clear();
    ref.read(staffStudentsProvider.notifier).setClassFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffStudentsProvider);
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(staffStudentsProvider.notifier).loadStudents(
              page: state.currentPage,
            );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg,
            ),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AppStrings.students,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Search + filters
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by name or admission no...',
                          prefixIcon:
                              Icon(Icons.search, size: AppIconSize.md),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: AppRadius.brMd),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 160,
                      child:
                          SearchableDropdownFormField<String?>.valueItems(
                        value: state.filterClassId,
                        valueItems: [
                          const MapEntry(null, 'All Classes'),
                          for (final c in state.classes)
                            MapEntry<String?, String>(
                              c['id'] as String?,
                              c['name'] as String? ?? '',
                            ),
                        ],
                        decoration: InputDecoration(
                          labelText: AppStrings.classLabel,
                          border: OutlineInputBorder(
                              borderRadius: AppRadius.brMd),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          isDense: true,
                        ),
                        onChanged: (v) => ref
                            .read(staffStudentsProvider.notifier)
                            .setClassFilter(v),
                      ),
                    ),
                    const Spacer(),
                    if (_hasFilters)
                      TextButton.icon(
                        icon: const Icon(Icons.filter_alt_off,
                            size: 18),
                        label: const Text(AppStrings.clearFilters),
                        onPressed: _clearFilters,
                      ),
                  ],
                ),
              ),
            ),
          ),

          AppSpacing.vGapLg,

          // Content area
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
              ),
              child: _buildContent(state, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StaffStudentsState state, bool isWide) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.students.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (state.errorMessage != null && state.students.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: AppIconSize.xl4, color: scheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center),
              AppSpacing.vGapXl,
              FilledButton.icon(
                onPressed: () => ref
                    .read(staffStudentsProvider.notifier)
                    .loadStudents(),
                icon: Icon(Icons.refresh, size: AppIconSize.md),
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: AppIconSize.xl4, color: scheme.outline),
              AppSpacing.vGapLg,
              Text(
                AppStrings.noRecordsFound,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_hasFilters) ...[
                AppSpacing.vGapLg,
                TextButton.icon(
                  icon: Icon(Icons.filter_alt_off, size: AppIconSize.md),
                  label: const Text(AppStrings.clearFilters),
                  onPressed: _clearFilters,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final hasMore = state.total > 0 &&
        state.students.length < state.total &&
        state.currentPage < state.totalPages;
    return MobileInfiniteScrollList(
      itemCount: state.students.length,
      itemBuilder: (ctx, i) {
        final s = state.students[i];
        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            borderRadius: AppRadius.brLg,
            onTap: () => context.go('/staff/students/${s.id}'),
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.secondary400.withValues(alpha: 0.15),
                    child: Text(
                      s.firstName.isNotEmpty
                          ? s.firstName[0].toUpperCase()
                          : '?',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondary400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '${s.admissionNo}  \u2022  ${s.className ?? ''}${s.sectionName != null ? ' ${s.sectionName}' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: s.status),
                ],
              ),
            ),
          ),
        );
      },
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: () =>
          ref.read(staffStudentsProvider.notifier).loadMoreStudents(),
      loadingLabel: AppStrings.loadingLabel,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    final color = isActive ? AppColors.success500 : AppColors.warning500;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        status,
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
