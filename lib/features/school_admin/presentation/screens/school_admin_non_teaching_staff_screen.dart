// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_non_teaching_staff_screen.dart
// PURPOSE: Non-Teaching Staff list screen — web table / mobile card layout.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/non_teaching_staff_model.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../providers/school_admin_non_teaching_staff_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
  int _pageSize = 15;
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
    if (value == null || value == _pageSize) return;
    setState(() => _pageSize = value);
    ref.read(nonTeachingStaffProvider.notifier).goToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nonTeachingStaffProvider);
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(nonTeachingStaffProvider.notifier).goToPage(1);
        await ref.read(nonTeachingStaffProvider.notifier).loadStaff();
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
                      'Non-Teaching Staff',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/school-admin/non-teaching-staff/new'),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Staff'),
                    ),
                  ],
                ),
              ),

              // Search + Filters
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
                                hintText: 'Search by name or employee no...',
                                prefixIcon:
                                    const Icon(Icons.search, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          ref
                                              .read(nonTeachingStaffProvider
                                                  .notifier)
                                              .setSearch('');
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: 10),
                              ),
                              onSubmitted: (_) {
                                ref
                                    .read(
                                        nonTeachingStaffProvider.notifier)
                                    .setSearch(_searchCtrl.text);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: SearchableDropdownFormField<String?>
                                .valueItems(
                              value: state.categoryFilter,
                              valueItems: [
                                const MapEntry(null, 'All Categories'),
                                for (final c in _categories)
                                  MapEntry<String?, String>(
                                      c, _categoryLabel(c)),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                ref
                                    .read(
                                        nonTeachingStaffProvider.notifier)
                                    .setCategoryFilter(v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: SearchableDropdownFormField<bool?>
                                .valueItems(
                              value: state.isActiveFilter,
                              valueItems: const [
                                MapEntry(null, 'All'),
                                MapEntry(true, 'Active'),
                                MapEntry(false, 'Inactive'),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                ref
                                    .read(
                                        nonTeachingStaffProvider.notifier)
                                    .setActiveFilter(v);
                              },
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.filter_alt_off,
                                size: 18),
                            label: const Text('Clear filters'),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(nonTeachingStaffProvider.notifier)
                                  .setSearch('');
                              ref
                                  .read(nonTeachingStaffProvider.notifier)
                                  .setCategoryFilter(null);
                              ref
                                  .read(nonTeachingStaffProvider.notifier)
                                  .setActiveFilter(null);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              AppSpacing.vGapLg,

              // Content
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

  Widget _buildContent(dynamic state, bool isWide) {
    if (state.isLoading && state.staff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }
    if (state.errorMessage != null && state.staff.isEmpty) {
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
                onPressed: () =>
                    ref.read(nonTeachingStaffProvider.notifier).loadStaff(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.staff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchCtrl.text.isNotEmpty
                    ? "No results for '${_searchCtrl.text}'"
                    : 'No staff found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  ref
                      .read(nonTeachingStaffProvider.notifier)
                      .setSearch('');
                  ref
                      .read(nonTeachingStaffProvider.notifier)
                      .setCategoryFilter(null);
                  ref
                      .read(nonTeachingStaffProvider.notifier)
                      .setActiveFilter(null);
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
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

  Widget _buildStaffList(dynamic state, bool isWide) {
    final staff = state.staff as List<NonTeachingStaffModel>;
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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: staff.length,
            itemBuilder: (ctx, i) => _buildMobileCard(staff[i]),
          ),
        ),
        if (staff.isNotEmpty)
          Card(child: _buildPaginationRow()),
      ],
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
      DataCell(PopupMenuButton<String>(
        itemBuilder: (ctx) => [
          const PopupMenuItem(
              value: 'view',
              child: ListTile(
                  dense: true,
                  leading: Icon(Icons.visibility),
                  title: Text('View'))),
          const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit),
                  title: Text('Edit'))),
          PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                  dense: true,
                  leading: Icon(s.isActive
                      ? Icons.block
                      : Icons.check_circle),
                  title: Text(
                      s.isActive ? 'Deactivate' : 'Activate'))),
          const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                  dense: true,
                  leading:
                      Icon(Icons.delete, color: AppColors.error500),
                  title: Text('Delete',
                      style: TextStyle(color: AppColors.error500)))),
        ],
        onSelected: (v) {
          if (v == 'view') {
            context.go('/school-admin/non-teaching-staff/${s.id}');
          }
          if (v == 'edit') {
            context.go('/school-admin/non-teaching-staff/${s.id}/edit');
          }
          if (v == 'toggle') _confirmToggle(context, s);
          if (v == 'delete') _confirmDelete(context, s);
        },
        child: const Icon(Icons.more_vert, size: 18),
      )),
    ]);
  }

  Widget _buildMobileCard(NonTeachingStaffModel s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/school-admin/non-teaching-staff/${s.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        s.role?.categoryColor.withValues(alpha: 0.2) ??
                            AppColors.neutral200,
                    child: Text(
                      s.initials,
                      style: TextStyle(
                        color: s.role?.categoryColor ?? AppColors.neutral400,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        Text(s.employeeNo,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  _ActiveBadge(isActive: s.isActive),
                ],
              ),
              if (s.role != null) ...[
                AppSpacing.vGapSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _CategoryChip(
                        label: s.role!.displayName,
                        color: s.role!.categoryColor),
                    _TypeChip(
                        label: s.employeeTypeLabel,
                        color: s.employeeTypeColor),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    final state = ref.watch(nonTeachingStaffProvider);
    final cs = Theme.of(context).colorScheme;
    final total = state.total;
    final page = state.currentPage;
    final totalPages = state.totalPages;
    final start = total == 0 ? 0 : ((page - 1) * _pageSize) + 1;
    final end = (page * _pageSize).clamp(0, total);

    Widget pageButton(String label,
        {required int targetPage, bool active = false}) {
      final enabled =
          targetPage != page && targetPage >= 1 && targetPage <= totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? () => _goToPage(targetPage) : null,
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
      int rangeStart = (page - (maxVisible ~/ 2)).clamp(1, totalPages);
      int rangeEnd =
          (rangeStart + maxVisible - 1).clamp(1, totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart =
            (rangeEnd - maxVisible + 1).clamp(1, totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(
            pageButton('$i', targetPage: i, active: i == page));
      }
      return pages;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle =
        textStyle.copyWith(color: cs.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Showing $start to $end of $total entries',
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
                padding:
                    AppSpacing.paddingHSm,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: AppColors.neutral400),
                  borderRadius: AppRadius.brXs,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _pageSize,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 18),
                    style: textStyle.copyWith(
                        color: cs.onSurface),
                    items: _pageSizeOptions
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n')))
                        .toList(),
                    onChanged: _onPageSizeChanged,
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
              pageButton('First', targetPage: 1),
              pageButton('Previous', targetPage: page - 1),
              ...pageNumbers(),
              pageButton('Next', targetPage: page + 1),
              pageButton('Last', targetPage: totalPages),
            ],
          ),
        ],
      ),
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
      AppSnackbar.success(context, '${staff.fullName} ${action.toLowerCase()}d');
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
      AppSnackbar.success(context, 'Staff member deleted');
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
