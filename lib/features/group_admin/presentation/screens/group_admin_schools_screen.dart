// =============================================================================
// FILE: lib/features/group_admin/presentation/screens/group_admin_schools_screen.dart
// PURPOSE: Group Admin schools list — search, sort, status dots, plan chips.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/group_admin_service.dart';
import '../../../../models/group_admin/group_admin_models.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';

import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';

// ── State ──────────────────────────────────────────────────────────────────

class _SchoolsState {
  const _SchoolsState({
    this.schools = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.sortBy = 'name',
    this.sortOrder = 'asc',
  });

  final List<GroupAdminSchoolModel> schools;
  final bool isLoading;
  final String? error;
  final String search;
  final String sortBy;
  final String sortOrder;

  _SchoolsState copyWith({
    List<GroupAdminSchoolModel>? schools,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) {
    return _SchoolsState(
      schools: schools ?? this.schools,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class _SchoolsNotifier extends StateNotifier<_SchoolsState> {
  _SchoolsNotifier(this._service) : super(const _SchoolsState());

  final GroupAdminService _service;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final schools = await _service.getSchools(
        search: state.search.isEmpty ? null : state.search,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );
      state = state.copyWith(schools: schools, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        schools: [],
      );
    }
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    load();
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    load();
  }

  void setSortOrder(String order) {
    state = state.copyWith(sortOrder: order);
    load();
  }
}

final _schoolsProvider =
    StateNotifierProvider.autoDispose<_SchoolsNotifier, _SchoolsState>((ref) {
  return _SchoolsNotifier(ref.read(groupAdminServiceProvider));
});

// ── Screen ─────────────────────────────────────────────────────────────────

class GroupAdminSchoolsScreen extends ConsumerStatefulWidget {
  const GroupAdminSchoolsScreen({super.key});

  @override
  ConsumerState<GroupAdminSchoolsScreen> createState() =>
      _GroupAdminSchoolsScreenState();
}

class _GroupAdminSchoolsScreenState
    extends ConsumerState<GroupAdminSchoolsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_schoolsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    final s = ref.read(_schoolsProvider);
    return s.search.isNotEmpty || s.sortBy != 'name' || s.sortOrder != 'asc';
  }

  void _clearFilters() {
    _searchController.clear();
    final notifier = ref.read(_schoolsProvider.notifier);
    notifier.setSearch('');
    notifier.setSortBy('name');
    notifier.setSortOrder('asc');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_schoolsProvider);
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? AppSpacing.lg : AppSpacing.xl;

    return RefreshIndicator(
      onRefresh: () => ref.read(_schoolsProvider.notifier).load(),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Schools',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapMd,

            // ── Search + Filters ──
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Card(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: AppStrings.searchSchools,
                              prefixIcon:
                                  Icon(Icons.search, size: AppIconSize.md),
                              border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              suffixIcon: state.search.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear,
                                          size: AppIconSize.sm),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                                _schoolsProvider.notifier)
                                            .setSearch('');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: ref
                                .read(_schoolsProvider.notifier)
                                .setSearch,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String>.valueItems(
                            value: state.sortBy,
                            valueItems: const [
                              MapEntry('name', 'Name'),
                              MapEntry('status', 'Status'),
                              MapEntry('subscriptionPlan', 'Plan'),
                              MapEntry('subscriptionEnd', 'Expiry'),
                            ],
                            hintText: AppStrings.sortBy,
                            decoration: InputDecoration(
                              labelText: AppStrings.sortBy,
                              border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(_schoolsProvider.notifier)
                                    .setSortBy(v);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: Icon(
                            state.sortOrder == 'asc'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: AppIconSize.md,
                          ),
                          tooltip: state.sortOrder == 'asc'
                              ? 'Ascending'
                              : 'Descending',
                          onPressed: () {
                            ref
                                .read(_schoolsProvider.notifier)
                                .setSortOrder(
                                  state.sortOrder == 'asc'
                                      ? 'desc'
                                      : 'asc',
                                );
                          },
                        ),
                        const Spacer(),
                        if (_hasActiveFilters)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.filter_alt_off,
                                size: AppIconSize.sm),
                            label: const Text(AppStrings.clearFilters),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.vGapSm,

            // ── Content ──
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildContent(context, state, cs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, _SchoolsState state, ColorScheme cs) {
    if (state.error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: AppSpacing.paddingXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: AppIconSize.xl3, color: cs.error),
                AppSpacing.vGapMd,
                Text(
                  state.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vGapLg,
                FilledButton(
                  onPressed: () =>
                      ref.read(_schoolsProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.isLoading) {
      return AppLoaderScreen();
    }

    if (state.schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: AppIconSize.xl4, color: cs.outline),
            AppSpacing.vGapLg,
            Text(
              state.search.isNotEmpty
                  ? 'No schools match "${state.search}"'
                  : 'No schools found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_hasActiveFilters) ...[
              AppSpacing.vGapMd,
              TextButton(
                onPressed: _clearFilters,
                child: const Text(AppStrings.clearFilters),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.schools.length,
      itemBuilder: (context, index) =>
          _SchoolTile(school: state.schools[index]),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  const _SchoolTile({required this.school});

  final GroupAdminSchoolModel school;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(school.status);
    final planColor = _planColor(school.subscriptionPlan);
    final daysRemaining = school.subscriptionEnd?.difference(DateTime.now()).inDays;
    final isExpiringSoon =
        daysRemaining != null && daysRemaining < 30 && daysRemaining >= 0;
    final isExpired = daysRemaining != null && daysRemaining < 0;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ),
        title: Text(
          school.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${school.code}${school.city != null ? ' · ${school.city}' : ''}',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: planColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.brXs,
                border: Border.all(color: planColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                school.subscriptionPlan,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: planColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppSpacing.vGapXs,
            if (school.subscriptionEnd != null) ...[
              Text(
                isExpired
                    ? 'Expired'
                    : isExpiringSoon
                        ? '$daysRemaining d left'
                        : _formatDate(school.subscriptionEnd!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isExpired
                      ? AppColors.error500
                      : isExpiringSoon
                          ? AppColors.warning500
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        onTap: () => context.go('/group-admin/schools/${school.id}'),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success500;
      case 'SUSPENDED':
        return AppColors.warning500;
      default:
        return AppColors.error500;
    }
  }

  Color _planColor(String plan) {
    switch (plan.toUpperCase()) {
      case 'PREMIUM':
        return AppColors.secondary500;
      case 'STANDARD':
        return AppColors.success500;
      default:
        return AppColors.neutral400;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
