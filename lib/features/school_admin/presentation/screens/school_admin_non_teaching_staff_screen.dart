// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_staff_screen.dart
// PURPOSE: Non-Teaching Staff list screen — web table / mobile card layout.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/non_teaching_staff_model.dart';
import '../../../../design_system/design_system.dart';

import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import '../providers/school_admin_non_teaching_staff_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_toast.dart';

const List<String> _categories = [
  'FINANCE',
  'LIBRARY',
  'LABORATORY',
  'ADMIN_SUPPORT',
  'GENERAL',
];

class SchoolAdminNonTeachingStaffScreen extends ConsumerStatefulWidget {
  const SchoolAdminNonTeachingStaffScreen({super.key});

  @override
  ConsumerState<SchoolAdminNonTeachingStaffScreen> createState() =>
      _SchoolAdminNonTeachingStaffScreenState();
}

class _SchoolAdminNonTeachingStaffScreenState
    extends ConsumerState<SchoolAdminNonTeachingStaffScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nonTeachingStaffProvider.notifier).loadStaff();
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(nonTeachingStaffProvider.notifier).setSearch(_searchCtrl.text);
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

  void _goToPage(int page) {
    final state = ref.read(nonTeachingStaffProvider);
    if (page < 1 || page > state.totalPages) return;
    ref.read(nonTeachingStaffProvider.notifier).goToPage(page);
  }

  void _onPageSizeChanged(int? value) {
    if (value == null) return;
    ref.read(nonTeachingStaffProvider.notifier).setPageSize(value);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    ref.read(nonTeachingStaffProvider.notifier).setSearch('');
    ref.read(nonTeachingStaffProvider.notifier).setCategoryFilter(null);
    ref.read(nonTeachingStaffProvider.notifier).setActiveFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nonTeachingStaffProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(nonTeachingStaffProvider.notifier).goToPage(1);
        await ref.read(nonTeachingStaffProvider.notifier).loadStaff();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWide) ...[
            // ── Wide header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.nonTeachingStaff,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Manage support and administrative staff',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, size: AppIconSize.md),
                        label: Text(AppStrings.export),
                      ),
                      AppSpacing.hGapSm,
                      FilledButton.icon(
                        onPressed: () =>
                            context.go('/school-admin/non-teaching-staff/new'),
                        icon: const Icon(Icons.add, size: AppIconSize.md),
                        label: Text(AppStrings.addStaff),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Wide filter card ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            hintText: AppStrings.searchByNameEmpNo,
                            prefixIcon: const Icon(Icons.search, size: AppIconSize.md),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      ref
                                          .read(nonTeachingStaffProvider.notifier)
                                          .setSearch('');
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: SearchableDropdownFormField<String?>.valueItems(
                          value: state.categoryFilter,
                          valueItems: [
                            const MapEntry(null, 'All Categories'),
                            for (final c in _categories)
                              MapEntry<String?, String>(c, _categoryLabel(c)),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            isDense: true,
                          ),
                          onChanged: (v) => ref
                              .read(nonTeachingStaffProvider.notifier)
                              .setCategoryFilter(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: SearchableDropdownFormField<bool?>.valueItems(
                          value: state.isActiveFilter,
                          valueItems: const [
                            MapEntry(null, 'All'),
                            MapEntry(true, 'Active'),
                            MapEntry(false, 'Inactive'),
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.status,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            isDense: true,
                          ),
                          onChanged: (v) => ref
                              .read(nonTeachingStaffProvider.notifier)
                              .setActiveFilter(v),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.filter_alt_off, size: 18),
                        label: Text(AppStrings.clearFilters),
                        onPressed: _clearFilters,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppSpacing.vGapLg,
          ] else ...[
            // ── Narrow header ──────────────────────────────────────────────
            ListScreenMobileHeader(
              title: AppStrings.nonTeachingStaff,
              primaryLabel: AppStrings.addStaff,
              onPrimary: () => context.go('/school-admin/non-teaching-staff/new'),
              onExport: () {},
            ),
            // ── Narrow filter strip ────────────────────────────────────────
            ListScreenMobileFilterStrip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListScreenMobilePillSearchField(
                    controller: _searchCtrl,
                    hintText: AppStrings.searchByNameEmpNo,
                    onChanged: (v) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                        if (mounted) {
                          ref.read(nonTeachingStaffProvider.notifier).setSearch(v);
                        }
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      ref.read(nonTeachingStaffProvider.notifier).setSearch('');
                    },
                  ),
                  AppSpacing.vGapMd,
                  ListScreenMobileFilterRow(
                    children: [
                      SearchableDropdownFormField<String?>.valueItems(
                        value: state.categoryFilter,
                        valueItems: [
                          const MapEntry(null, 'All Categories'),
                          for (final c in _categories)
                            MapEntry<String?, String>(c, _categoryLabel(c)),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) => ref
                            .read(nonTeachingStaffProvider.notifier)
                            .setCategoryFilter(v),
                      ),
                      SearchableDropdownFormField<bool?>.valueItems(
                        value: state.isActiveFilter,
                        valueItems: const [
                          MapEntry(null, 'All'),
                          MapEntry(true, 'Active'),
                          MapEntry(false, 'Inactive'),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) => ref
                            .read(nonTeachingStaffProvider.notifier)
                            .setActiveFilter(v),
                      ),
                      ListScreenMobileMoreFiltersButton(
                        onPressed: _clearFilters,
                        showActiveDot: _searchCtrl.text.isNotEmpty ||
                            state.categoryFilter != null ||
                            state.isActiveFilter != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                0,
                isWide ? 24 : 16,
                isWide ? 24 : 16,
              ),
              child: _buildContent(state, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NonTeachingStaffState state, bool isWide) {
    if (state.isLoading && state.staff.isEmpty) {
      return AppLoaderScreen();
    }
    if (state.errorMessage != null && state.staff.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl4, color: scheme.error),
            AppSpacing.vGapLg,
            Text(AppStrings.genericError,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
            AppSpacing.vGapSm,
            Text(state.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center),
            AppSpacing.vGapXl,
            FilledButton.icon(
              onPressed: () => ref.read(nonTeachingStaffProvider.notifier).loadStaff(),
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (state.staff.isEmpty) {
      final hasFilters = _searchCtrl.text.isNotEmpty ||
          state.categoryFilter != null ||
          state.isActiveFilter != null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined,
                size: AppIconSize.xl4,
                color: Theme.of(context).colorScheme.outline),
            AppSpacing.vGapLg,
            Text(
              'No staff found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              AppSpacing.vGapSm,
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off, size: AppIconSize.md),
                label: Text(AppStrings.clearFilters),
              ),
            ],
          ],
        ),
      );
    }
    return _buildStaffList(state, isWide);
  }

  static const _columnWidths = [
    100.0, // Emp.No
    200.0, // Name
    120.0, // Role
    120.0, // Department
    90.0,  // Type
    90.0,  // Status
    60.0,  // Actions
  ];

  Widget _buildStaffList(NonTeachingStaffState state, bool isWide) {
    final staff = state.staff;
    if (isWide) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListTableView(
                columns: const [
                  'Emp.No',
                  'Name',
                  'Role',
                  'Department',
                  'Type',
                  'Status',
                  'Actions',
                ],
                columnWidths: _columnWidths,
                showSrNo: false,
                itemCount: staff.length,
                rowBuilder: (i) => _buildDataRow(staff[i]),
              ),
            ),
            _buildPaginationRow(),
          ],
        ),
      );
    }
    final hasMore = state.total > 0 &&
        staff.length < state.total &&
        state.currentPage < state.totalPages;
    return MobileInfiniteScrollList(
      itemCount: staff.length,
      itemBuilder: (ctx, i) => _buildMobileCard(staff[i]),
      onLoadMore: () =>
          ref.read(nonTeachingStaffProvider.notifier).loadMoreStaff(),
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      loadingLabel: 'Loading more staff…',
    );
  }

  DataRow _buildDataRow(NonTeachingStaffModel s) {
    return DataRow(cells: [
      DataCell(Text(s.employeeNo,
          style: const TextStyle(fontFamily: 'monospace'))),
      DataCell(
        InkWell(
          onTap: () => context.go('/school-admin/non-teaching-staff/${s.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (s.email.isNotEmpty)
                Text(s.email,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
      DataCell(
        s.role != null
            ? _CategoryChip(
                label: s.role!.displayName,
                color: s.role!.categoryColor,
              )
            : const Text('—'),
      ),
      DataCell(Text(s.department ?? '—')),
      DataCell(_TypeChip(
          label: s.employeeTypeLabel, color: s.employeeTypeColor)),
      DataCell(_ActiveBadge(isActive: s.isActive)),
      DataCell(
        HoverPopupMenu<String>(
          icon: const Icon(Icons.more_vert, size: AppIconSize.md),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            if (v == 'view') context.go('/school-admin/non-teaching-staff/${s.id}');
            if (v == 'edit') context.go('/school-admin/non-teaching-staff/${s.id}/edit');
            if (v == 'toggle') _confirmToggle(context, s);
            if (v == 'delete') _confirmDelete(context, s);
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<String>(
              value: 'view',
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.visibility_outlined, size: AppIconSize.md),
                title: Text(AppStrings.view),
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.edit_outlined, size: AppIconSize.md),
                title: Text(AppStrings.edit),
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              child: ListTile(
                dense: true,
                leading: Icon(
                  s.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                  size: AppIconSize.md,
                ),
                title: Text(s.isActive ? 'Deactivate' : 'Activate'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.delete_outline,
                    size: AppIconSize.md, color: AppColors.error500),
                title: Text(AppStrings.delete,
                    style: const TextStyle(color: AppColors.error500)),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildMobileCard(NonTeachingStaffModel s) {
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.go('/school-admin/non-teaching-staff/${s.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      s.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  HoverPopupMenu<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') {
                        context.go('/school-admin/non-teaching-staff/${s.id}/edit');
                      }
                      if (v == 'toggle') _confirmToggle(context, s);
                      if (v == 'delete') _confirmDelete(context, s);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.edit_outlined, size: AppIconSize.md),
                          title: Text(AppStrings.edit),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            s.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                            size: AppIconSize.md,
                          ),
                          title: Text(s.isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.delete_outline,
                              size: AppIconSize.md, color: AppColors.error500),
                          title: Text(AppStrings.delete,
                              style: const TextStyle(color: AppColors.error500)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(s.employeeNo, style: smallMuted),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        if (s.role != null)
                          _CategoryChip(
                              label: s.role!.displayName,
                              color: s.role!.categoryColor),
                        _TypeChip(
                            label: s.employeeTypeLabel,
                            color: s.employeeTypeColor),
                      ],
                    ),
                  ),
                  AppSpacing.hGapSm,
                  _ActiveBadge(isActive: s.isActive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    final state = ref.watch(nonTeachingStaffProvider);
    return ListPaginationBar(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalEntries: state.total,
      pageSize: state.pageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: _onPageSizeChanged,
      onGoToPage: _goToPage,
    );
  }

  Future<void> _confirmToggle(
      BuildContext context, NonTeachingStaffModel staff) async {
    final action = staff.isActive ? 'Deactivate' : 'Activate';
    final confirmed = await AppDialogs.confirm(
      context,
      title: '$action Staff?',
      message: '$action ${staff.fullName} (${staff.employeeNo})?',
      confirmLabel: action,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(nonTeachingStaffProvider.notifier)
        .toggleStatus(staff.id, !staff.isActive);
    if (context.mounted) {
      AppToast.showSuccess(context, '${staff.fullName} ${action.toLowerCase()}d');
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, NonTeachingStaffModel staff) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Delete Staff?',
      message: 'Remove ${staff.fullName} (${staff.employeeNo})? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(nonTeachingStaffProvider.notifier)
        .deleteStaff(staff.id);
    if (context.mounted) {
      AppToast.showSuccess(context, 'Staff member deleted');
    }
  }
}

// ── Shared Widgets (UNCHANGED) ───────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => _CategoryChip(label: label, color: color);
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success500 : AppColors.neutral400;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _categoryLabel(String cat) {
  switch (cat) {
    case 'FINANCE':
      return 'Finance';
    case 'LIBRARY':
      return 'Library';
    case 'LABORATORY':
      return 'Laboratory';
    case 'ADMIN_SUPPORT':
      return 'Admin Support';
    default:
      return 'General';
  }
}
