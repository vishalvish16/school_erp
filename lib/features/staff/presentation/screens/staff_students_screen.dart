// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_students_screen.dart
// PURPOSE: Read-only student list screen for the Staff/Clerk portal.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/staff_students_provider.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.secondary400;
const _pageSizeOptions = [10, 15, 25, 50];

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
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(staffStudentsProvider.notifier).loadStudents(
              page: state.currentPage,
            );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  isNarrow ? 16 : 24,
                  16,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'My Students',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Search + filters
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 16 : 24),
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search by name or admission no...',
                                prefixIcon:
                                    const Icon(Icons.search, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: 10),
                              ),
                            ),
                          ),
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
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) => ref
                                  .read(staffStudentsProvider.notifier)
                                  .setClassFilter(v),
                            ),
                          ),
                          if (_hasFilters)
                            TextButton.icon(
                              icon: const Icon(Icons.filter_alt_off,
                                  size: 18),
                              label: const Text('Clear filters'),
                              onPressed: _clearFilters,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              AppSpacing.vGapLg,

              // Content area
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24,
                      0,
                      isNarrow ? 16 : 24,
                      isNarrow ? 16 : 24,
                    ),
                    child: _buildContent(state, isWide),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(StaffStudentsState state, bool isWide) {
    if (state.isLoading && state.students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }

    if (state.errorMessage != null && state.students.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(staffStudentsProvider.notifier)
                    .loadStudents(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchCtrl.text.isNotEmpty
                    ? "No results for '${_searchCtrl.text}'"
                    : 'No students found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_hasFilters) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Mobile card list
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: state.students.length,
            itemBuilder: (ctx, i) {
              final s = state.students[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: AppRadius.brLg,
                  onTap: () => context.go('/staff/students/${s.id}'),
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  _accent.withValues(alpha: 0.15),
                              child: Text(
                                s.firstName.isNotEmpty
                                    ? s.firstName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            AppSpacing.hGapMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.admissionNo}  •  ${s.className ?? ''}${s.sectionName != null ? ' ${s.sectionName}' : ''}',
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            _StatusChip(status: s.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (state.students.isNotEmpty)
          Card(child: _buildPaginationRow(state)),
      ],
    );
  }

  Widget _buildPaginationRow(StaffStudentsState state) {
    final cs = Theme.of(context).colorScheme;
    final pageSize = state.pageSize;
    final start = state.total == 0 ? 0 : ((state.currentPage - 1) * pageSize) + 1;
    final end = (state.currentPage * pageSize).clamp(0, state.total);

    Widget pageButton(String label,
        {required int page, bool active = false}) {
      final enabled =
          page != state.currentPage && page >= 1 && page <= state.totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled
                ? () => ref
                    .read(staffStudentsProvider.notifier)
                    .goToPage(page)
                : null,
            child: Container(
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              padding: AppSpacing.paddingHSm,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? cs.onPrimary
                      : enabled
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> pageNumbers() {
      final pages = <Widget>[];
      const maxVisible = 5;
      int rangeStart =
          (state.currentPage - (maxVisible ~/ 2)).clamp(1, state.totalPages);
      int rangeEnd =
          (rangeStart + maxVisible - 1).clamp(1, state.totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart =
            (rangeEnd - maxVisible + 1).clamp(1, state.totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(pageButton('$i', page: i, active: i == state.currentPage));
      }
      return pages;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle =
        textStyle.copyWith(color: cs.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Showing $start to $end of ${state.total} entries',
              style: mutedStyle),
          AppSpacing.hGapXl,
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Show', style: mutedStyle),
              const SizedBox(width: 6),
              Container(
                height: 28,
                padding: AppSpacing.paddingHSm,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral400),
                  borderRadius: AppRadius.brXs,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    icon:
                        const Icon(Icons.arrow_drop_down, size: 18),
                    style: textStyle.copyWith(color: cs.onSurface),
                    items: _pageSizeOptions
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(staffStudentsProvider.notifier)
                            .setPageSize(v);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('entries', style: mutedStyle),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton('First', page: 1),
              pageButton('Previous', page: state.currentPage - 1),
              ...pageNumbers(),
              pageButton('Next', page: state.currentPage + 1),
              pageButton('Last', page: state.totalPages),
            ],
          ),
        ],
      ),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
