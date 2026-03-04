import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/reusable_data_table.dart';
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

  /// Local sort state for instant client-side sorting on click
  int? _sortColumnIndex;
  bool _sortAscending = true;

  /// Column index -> backend sortBy field
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

  /// Filters schools by search (name or code) and plan for instant client-side filtering.
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
              s.schoolCode.toLowerCase().contains(lower))
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

  /// Sorts schools list by column index for instant client-side sorting.
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
    90.0,  // Code
    200.0, // School Name
    100.0, // Plan
    100.0, // Status (fixed so ACTIVE/SUSPENDED don't resize)
    100.0, // Students
    100.0, // Teachers
    110.0, // Exp. Date
    140.0, // Actions
  ];

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

  Future<void> _showSuspendOrActivateDialog(
    BuildContext context,
    String schoolId,
    String name,
    bool isSuspended,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSuspended
            ? AppStrings.activateSchoolTitle
            : AppStrings.suspendSchoolTitle),
        content: Text(isSuspended
            ? AppStrings.activateSchoolConfirm(name)
            : AppStrings.suspendSchoolConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isSuspended ? AppStrings.activate : AppStrings.suspend,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () => vm.fetchSchools(isRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          AppStrings.schoolsManagement,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Tooltip(
                          message: AppStrings.tooltipAddNewSchool,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditSchoolScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.addSchool),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// FILTER CARD
                    _buildFilterCard(context, vm),

                    const SizedBox(height: 24),

                    /// TABLE CARD
                    _buildContentCard(state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, vm) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final planState = ref.watch(planProvider);
    final plans = planState.plans;

    final filterWidgets = [
      Expanded(
        flex: 2,
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            vm.onSearchChanged(v);
            setState(() {}); // Instant filter display
          },
          onSubmitted: (_) => vm.applySearchNow(_searchController.text),
          decoration: InputDecoration(
            hintText: AppStrings.searchByNameOrCode,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                vm.applySearchNow(_searchController.text);
                setState(() {});
              },
              tooltip: AppStrings.tooltipRefresh,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: plans.any((p) => p.planId.toString() == vm.currentPlanIdFilter)
              ? vm.currentPlanIdFilter
              : 'ALL',
          onChanged: (v) {
            vm.setPlanIdFilter(v == 'ALL' ? null : v);
            setState(() {}); // Instant filter display
          },
          items: [
            const DropdownMenuItem(value: 'ALL', child: Text(AppStrings.allPlans)),
            ...plans.map((p) => DropdownMenuItem(
                  value: p.planId.toString(),
                  child: Text(p.planName, overflow: TextOverflow.ellipsis),
                )),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: vm.currentStatus,
          onChanged: (v) {
            if (v != null) vm.setStatusFilter(v);
          },
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text(AppStrings.allStatus)),
            DropdownMenuItem(value: 'ACTIVE', child: Text(AppStrings.statusActive)),
            DropdownMenuItem(
              value: 'SUSPENDED',
              child: Text(AppStrings.statusSuspended),
            ),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      vm.onSearchChanged(v);
                      setState(() {});
                    },
                    onSubmitted: (_) => vm.applySearchNow(_searchController.text),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchByNameOrCode,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          vm.applySearchNow(_searchController.text);
                          setState(() {});
                        },
                        tooltip: AppStrings.tooltipRefresh,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: plans.any((p) => p.planId.toString() == vm.currentPlanIdFilter)
                        ? vm.currentPlanIdFilter
                        : 'ALL',
                    onChanged: (v) {
                      vm.setPlanIdFilter(v == 'ALL' ? null : v);
                      setState(() {});
                    },
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text(AppStrings.allPlans)),
                      ...plans.map((p) => DropdownMenuItem(
                            value: p.planId.toString(),
                            child: Text(p.planName, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: vm.currentStatus,
                    onChanged: (v) {
                      if (v != null) vm.setStatusFilter(v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text(AppStrings.allStatus)),
                      DropdownMenuItem(value: 'ACTIVE', child: Text(AppStrings.statusActive)),
                      DropdownMenuItem(
                        value: 'SUSPENDED',
                        child: Text(AppStrings.statusSuspended),
                      ),
                    ],
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
              )
            : Row(children: filterWidgets),
      ),
    );
  }

  Widget _buildContentCard(AsyncValue<PaginationModel<SchoolModel>> state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(AppStrings.errorWithMessage(e.toString()))),
          data: (data) {
            if (data.data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppStrings.noSchoolsFound),
                ),
              );
            }

            final vm = ref.read(schoolsViewModelProvider.notifier);
            final sortCol =
                _sortColumnIndex ?? _sortColumnIndexFromSortBy(vm.currentSortBy);
            final sortAsc =
                _sortColumnIndex != null
                    ? _sortAscending
                    : vm.currentSortOrder == 'asc';

            /// Filter by search (name/code) and plan for instant client-side filtering
            final filteredSchools = _filterSchools(
              data.data,
              vm.currentSearch,
              vm.currentPlanIdFilter,
            );
            /// Sort data locally for instant ascending/descending on column click
            final sortedSchools = _sortSchools(filteredSchools, sortCol, sortAsc);

            return SizedBox(
              width: double.infinity,
              child: ReusableDataTable(
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
                rows: sortedSchools.map((school) {
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
                                : Colors.grey,
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
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(school.subscriptionEnd!)
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
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlatformSchoolDetailPage(
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
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddEditSchoolScreen(school: school),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Tooltip(
                              message: school.status.toUpperCase() == 'SUSPENDED'
                                  ? AppStrings.tooltipActivateSchool
                                  : AppStrings.tooltipSuspendSchool,
                              child: IconButton(
                                icon: Icon(
                                  school.status.toUpperCase() == 'SUSPENDED'
                                      ? Icons.play_circle
                                      : Icons.block,
                                  color: school.status.toUpperCase() == 'SUSPENDED'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () => _showSuspendOrActivateDialog(
                                  context,
                                  school.id,
                                  school.name,
                                  school.status.toUpperCase() == 'SUSPENDED',
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
            );
          },
        ),
      ),
    );
  }
}
