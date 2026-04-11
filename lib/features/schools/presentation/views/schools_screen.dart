import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import '../../../../shared/widgets/reusable_data_table.dart';
import '../../../../utils/download_file.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';

import '../../../subscription/provider/plan_provider.dart';
import '../../domain/models/school_model.dart';
import '../../domain/models/pagination_model.dart';
import '../viewmodels/schools_viewmodel.dart';
import 'add_edit_school_screen.dart';
import 'platform_school_detail_page.dart';

class SchoolsScreen extends ConsumerStatefulWidget {
  const SchoolsScreen({super.key});

  @override
  ConsumerState<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends ConsumerState<SchoolsScreen> {
  final TextEditingController _searchController = TextEditingController();

  int? _sortColumnIndex;
  bool _sortAscending = true;

  Set<String> _selectedIds = {};

  int _page = 1;
  int _pageSize = 15;
  int _totalPages = 1;
  int _total = 0;
  bool _mobileLoadingMore = false;
  static const _pageSizeOptions = [10, 15, 25, 50];

  static const _sortFieldMap = {
    0: 'schoolCode',
    1: 'name',
    2: 'planId',
    3: 'isActive',
    6: 'subscriptionEnd',
  };
  static const _sortableColumns = [0, 1, 2, 3, 4, 5, 6];

  int? _sortColumnIndexFromSortBy(String sortBy) {
    for (final e in _sortFieldMap.entries) {
      if (e.value == sortBy) return e.key;
    }
    return null;
  }

  List<SchoolModel> _filterSchools(
    List<SchoolModel> schools,
    String searchQuery,
    String planIdFilter,
  ) {
    var result = schools;
    if (searchQuery.trim().isNotEmpty) {
      final lower = searchQuery.trim().toLowerCase();
      result = result
          .where((s) =>
              s.name.toLowerCase().contains(lower) ||
              s.schoolCode.toLowerCase().contains(lower) ||
              (s.city ?? '').toLowerCase().contains(lower))
          .toList();
    }
    if (planIdFilter.isNotEmpty && planIdFilter != 'ALL') {
      result =
          result
              .where((s) => s.planId?.toString() == planIdFilter)
              .toList();
    }
    return result;
  }

  List<SchoolModel> _sortSchools(
    List<SchoolModel> schools,
    int? columnIndex,
    bool ascending,
  ) {
    if (columnIndex == null || schools.isEmpty) return schools;
    final list = List<SchoolModel>.from(schools);
    list.sort((a, b) {
      int cmp;
      switch (columnIndex) {
        case 0:
          cmp = a.schoolCode.compareTo(b.schoolCode);
          break;
        case 1:
          cmp = a.name.compareTo(b.name);
          break;
        case 2:
          final pa = (a.planName ?? '').toLowerCase();
          final pb = (b.planName ?? '').toLowerCase();
          cmp = pa.compareTo(pb);
          break;
        case 3:
          cmp = a.status.compareTo(b.status);
          break;
        case 4:
          cmp = (a.maxStudents ?? 0).compareTo(b.maxStudents ?? 0);
          break;
        case 5:
          cmp = (a.maxTeachers ?? 0).compareTo(b.maxTeachers ?? 0);
          break;
        case 6:
          final da = a.subscriptionEnd?.millisecondsSinceEpoch ?? 0;
          final db = b.subscriptionEnd?.millisecondsSinceEpoch ?? 0;
          cmp = da.compareTo(db);
          break;
        default:
          return 0;
      }
      return ascending ? cmp : -cmp;
    });
    return list;
  }

  static const _columnWidths = [
    90.0,
    200.0,
    100.0,
    100.0,
    100.0,
    100.0,
    110.0,
    140.0,
  ];

  static const double _tableContentWidth =
      90 + 200 + 100 + 100 + 100 + 100 + 110 + 140 + 32;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(planProvider).fetchPlans());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _page = page);
    final vm = ref.read(schoolsViewModelProvider.notifier);
    vm.fetchSchools(page: page);
  }

  void _onPageSizeChanged(int? value) {
    if (value == null || value == _pageSize) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    final vm = ref.read(schoolsViewModelProvider.notifier);
    vm.fetchSchools(page: 1);
  }

  void _clearFilters() {
    _searchController.clear();
    final vm = ref.read(schoolsViewModelProvider.notifier);
    vm.setPlanIdFilter(null);
    vm.setStatusFilter('ALL');
    vm.onSearchChanged('');
    setState(() => _page = 1);
  }

  Future<void> _showSuspendOrActivateDialog(
    BuildContext context,
    String schoolId,
    String name,
    bool isSuspended,
  ) async {
    final confirm = await AppDialogs.confirm(
      context,
      title: isSuspended
          ? AppStrings.activateSchoolTitle
          : AppStrings.suspendSchoolTitle,
      message: isSuspended
          ? AppStrings.activateSchoolConfirm(name)
          : AppStrings.suspendSchoolConfirm(name),
      confirmLabel: isSuspended ? AppStrings.activate : AppStrings.suspend,
      isDestructive: !isSuspended,
    );

    if (confirm) {
      if (isSuspended) {
        ref.read(schoolsViewModelProvider.notifier).activateSchool(schoolId);
      } else {
        ref.read(schoolsViewModelProvider.notifier).suspendSchool(schoolId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolsViewModelProvider);
    final vm = ref.read(schoolsViewModelProvider.notifier);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final hPad = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: () => vm.fetchSchools(isRefresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppStrings.schoolsManagement,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditSchoolScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(AppStrings.addSchool),
                    ),
                  ],
                ),
              ),

              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _buildFilterRow(context, vm),
                ),
              ),

              AppSpacing.vGapLg,

              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, hPad),
                    child: _buildContent(state, vm, isWide),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, SchoolsViewModel vm) {
    final planState = ref.watch(planProvider);
    final plans = planState.plans;

    return Card(
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
                controller: _searchController,
                onChanged: (v) {
                  vm.onSearchChanged(v);
                  setState(() => _page = 1);
                },
                onSubmitted: (_) {
                  vm.applySearchNow(_searchController.text);
                  setState(() => _page = 1);
                },
                decoration: InputDecoration(
                  hintText: AppStrings.searchByNameOrCode,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            vm.applySearchNow('');
                            setState(() => _page = 1);
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
              width: 140,
              child: SearchableDropdownFormField<String>.valueItems(
                value: plans.any(
                        (p) => p.planId.toString() == vm.currentPlanIdFilter)
                    ? vm.currentPlanIdFilter
                    : 'ALL',
                valueItems: [
                  MapEntry('ALL', AppStrings.allPlans),
                  ...plans.map(
                      (p) => MapEntry(p.planId.toString(), p.planName)),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onChanged: (v) {
                  vm.setPlanIdFilter(v == 'ALL' ? null : v);
                  setState(() => _page = 1);
                },
              ),
            ),
            SizedBox(
              width: 140,
              child: SearchableDropdownFormField<String>.valueItems(
                value: vm.currentStatus,
                valueItems: const [
                  MapEntry('ALL', AppStrings.allStatus),
                  MapEntry('ACTIVE', AppStrings.statusActive),
                  MapEntry('SUSPENDED', AppStrings.statusSuspended),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onChanged: (v) {
                  if (v != null) {
                    vm.setStatusFilter(v);
                    setState(() => _page = 1);
                  }
                },
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Clear filters'),
              onPressed: _clearFilters,
            ),
            TextButton.icon(
              onPressed: () => _exportSchools(vm),
              icon: const Icon(Icons.download, size: 18),
              label: const Text(AppStrings.export),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<PaginationModel<SchoolModel>> state,
    SchoolsViewModel vm,
    bool isWide,
  ) {
    return state.when(
      loading: () => AppLoaderScreen(),
      error: (e, _) => Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(
                AppStrings.errorWithMessage(e.toString()),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => vm.fetchSchools(isRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        _total = data.total;
        _totalPages =
            data.totalPages > 0 ? data.totalPages : 1;

        if (data.data.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  AppSpacing.vGapLg,
                  Text(
                    _searchController.text.isNotEmpty
                        ? "No results for '${_searchController.text}'"
                        : AppStrings.noSchoolsFound,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vGapSm,
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          );
        }

        final sortCol =
            _sortColumnIndex ?? _sortColumnIndexFromSortBy(vm.currentSortBy);
        final sortAsc = _sortColumnIndex != null
            ? _sortAscending
            : vm.currentSortOrder == 'asc';

        final filteredSchools = _filterSchools(
          data.data,
          vm.currentSearch,
          vm.currentPlanIdFilter,
        );
        final sortedSchools =
            _sortSchools(filteredSchools, sortCol, sortAsc);

        if (isWide) {
          return _buildDesktopTable(sortedSchools, sortCol, sortAsc, vm);
        }
        return _buildMobileList(sortedSchools, vm);
      },
    );
  }

  Widget _buildDesktopTable(
    List<SchoolModel> schools,
    int? sortCol,
    bool sortAsc,
    SchoolsViewModel vm,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _tableContentWidth),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListTableView(
                  columns: const [
                    AppStrings.tableCode,
                    AppStrings.tableSchoolName,
                    AppStrings.tablePlan,
                    AppStrings.tableStatus,
                    AppStrings.tableStudents,
                    AppStrings.tableTeachers,
                    AppStrings.tableExpDate,
                    AppStrings.tableActions,
                  ],
                  columnWidths: _columnWidths,
                  sortableColumns: _sortableColumns,
                  sortColumnIndex: sortCol,
                  sortAscending: sortAsc,
                  onSort: (col, asc) {
                    setState(() {
                      _sortColumnIndex = col;
                      _sortAscending = asc;
                    });
                    final sortBy = _sortFieldMap[col] ?? 'createdAt';
                    vm.setSort(sortBy, asc ? 'asc' : 'desc');
                  },
                  showSrNo: false,
                  selectedIds: _selectedIds,
                  onSelectionChanged: (ids) =>
                      setState(() => _selectedIds = ids),
                  rowIds:
                      schools.map((s) => s.id).toList(),
                  rows: schools.map((school) {
                    return DataRow(
                      cells: [
                        DataCell(SizedBox(
                          width: _columnWidths[0],
                          child: Text(school.schoolCode),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[1],
                          child: Text(
                            school.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[2],
                          child: Text(
                            school.planName ?? AppStrings.notAvailable,
                            style: TextStyle(
                              color: school.planName != null
                                  ? Colors.indigo
                                  : AppColors.neutral400,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[3],
                          child: StatusBadge(status: school.status),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[4],
                          child: Text(
                            school.maxStudents.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[5],
                          child: Text(
                            school.maxTeachers.toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[6],
                          child: Text(
                            school.subscriptionEnd != null
                                ? DateFormat('MMM dd, yyyy')
                                    .format(school.subscriptionEnd!)
                                : AppStrings.notAvailable,
                          ),
                        )),
                        DataCell(SizedBox(
                          width: _columnWidths[7],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: AppStrings.tooltipViewDetails,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_red_eye,
                                    color: AppColors.success500,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlatformSchoolDetailPage(
                                          schoolId: school.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Tooltip(
                                message: AppStrings.tooltipEditSchool,
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.secondary500),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddEditSchoolScreen(
                                                school: school),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Tooltip(
                                message: school.status.toUpperCase() ==
                                        'SUSPENDED'
                                    ? AppStrings.tooltipActivateSchool
                                    : AppStrings.tooltipSuspendSchool,
                                child: IconButton(
                                  icon: Icon(
                                    school.status.toUpperCase() ==
                                            'SUSPENDED'
                                        ? Icons.play_circle
                                        : Icons.block,
                                    color:
                                        school.status.toUpperCase() ==
                                                'SUSPENDED'
                                            ? AppColors.success500
                                            : AppColors.error500,
                                  ),
                                  onPressed: () =>
                                      _showSuspendOrActivateDialog(
                                    context,
                                    school.id,
                                    school.name,
                                    school.status.toUpperCase() ==
                                        'SUSPENDED',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
              _buildPaginationRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<SchoolModel> schools, SchoolsViewModel vm) {
    return MobileInfiniteScrollList(
      itemCount: schools.length,
      itemBuilder: (_, i) => _buildMobileCard(schools[i]),
      hasMore: vm.hasMorePages,
      isLoadingMore: _mobileLoadingMore,
      onLoadMore: () async {
        if (_mobileLoadingMore || !vm.hasMorePages) return;
        setState(() => _mobileLoadingMore = true);
        try {
          await vm.loadMore();
        } finally {
          if (mounted) setState(() => _mobileLoadingMore = false);
        }
      },
      loadingLabel: 'Loading more schools…',
    );
  }

  String _formatSchoolStatusLabel(String raw) {
    if (raw.isEmpty) {
      return '—';
    }
    return raw.length > 1
        ? raw[0].toUpperCase() + raw.substring(1).toLowerCase()
        : raw.toUpperCase();
  }

  void _onMobileSchoolMenu(SchoolModel school, String value) {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditSchoolScreen(school: school),
          ),
        );
        break;
      case 'suspend':
        _showSuspendOrActivateDialog(
          context,
          school.id,
          school.name,
          false,
        );
        break;
      case 'activate':
        _showSuspendOrActivateDialog(
          context,
          school.id,
          school.name,
          true,
        );
        break;
    }
  }

  Widget _buildMobileCard(SchoolModel school) {
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    final statusLabel = _formatSchoolStatusLabel(school.status);
    final cityLine = (school.city ?? '').trim();
    final isSuspended = school.status.toUpperCase() == 'SUSPENDED';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PlatformSchoolDetailPage(schoolId: school.id),
            ),
          );
        },
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      school.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  HoverPopupMenu<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    padding: EdgeInsets.zero,
                    onSelected: (v) => _onMobileSchoolMenu(school, v),
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.edit_outlined, size: 20),
                          title: Text(AppStrings.edit),
                        ),
                      ),
                      if (isSuspended)
                        PopupMenuItem<String>(
                          value: 'activate',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.play_circle_outlined,
                                size: 20),
                            title: Text(AppStrings.activate),
                          ),
                        )
                      else
                        PopupMenuItem<String>(
                          value: 'suspend',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.block, color: AppColors.error500),
                            title: Text(
                              AppStrings.suspend,
                              style: const TextStyle(color: AppColors.error500),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  school.schoolCode,
                  if ((school.state ?? '').trim().isNotEmpty)
                    school.state!.trim(),
                ].join(' · '),
                style: smallMuted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cityLine.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cityLine,
                                  style: smallMuted,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          'ID: ${school.schoolCode}',
                          style: smallMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Students: ${school.studentCount} · Faculty: ${school.teacherCount}',
                          style: smallMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              school.planName ?? '—',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: cs.outlineVariant),
                            backgroundColor: cs.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                          Chip(
                            label: Text(statusLabel),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _statusColor(school.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expiry: ${school.subscriptionEnd != null ? DateFormat('MMM dd, yyyy').format(school.subscriptionEnd!) : '—'}',
                        style: smallMuted,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    return ListPaginationBar(
      currentPage: _page,
      totalPages: _totalPages,
      totalEntries: _total,
      pageSize: _pageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: _onPageSizeChanged,
      onGoToPage: _goToPage,
    );
  }

  Future<void> _exportSchools(SchoolsViewModel vm) async {
    final state = ref.read(schoolsViewModelProvider);
    if (!state.hasValue) return;
    final data = state.value!;
    final schools = data.data;
    final toExport = _selectedIds.isEmpty
        ? schools
        : schools.where((s) => _selectedIds.contains(s.id)).toList();
    if (toExport.isEmpty) {
      if (mounted) {
        AppSnackbar.info(context, AppStrings.noRecordsFound);
      }
      return;
    }
    try {
      final csv = _schoolsToCsv(toExport);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final msg = await downloadFile(
          csv, 'schools_$timestamp.csv', 'text/csv');
      if (mounted) {
        AppSnackbar.success(context, msg);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, '${AppStrings.exportFailed}: $e');
      }
    }
  }

  String _schoolsToCsv(List<SchoolModel> schools) {
    const header =
        'Code,School Name,Plan,Status,Students,Teachers,Exp. Date';
    final rows = schools.map((s) {
      final exp = s.subscriptionEnd != null
          ? DateFormat('yyyy-MM-dd').format(s.subscriptionEnd!)
          : '';
      return '"${s.schoolCode}","${s.name.replaceAll('"', '""')}","${(s.planName ?? '').replaceAll('"', '""')}","${s.status}",${s.maxStudents ?? 0},${s.maxTeachers ?? 0},"$exp"';
    });
    return '$header\n${rows.join('\n')}';
  }

  Color? _statusColor(String? s) {
    if (s == null) return null;
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success500.withValues(alpha: 0.2);
      case 'SUSPENDED':
        return AppColors.error500.withValues(alpha: 0.2);
      case 'TRIAL':
        return AppColors.secondary500.withValues(alpha: 0.2);
      default:
        return null;
    }
  }
}
