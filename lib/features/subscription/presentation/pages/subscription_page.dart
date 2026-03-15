// =============================================================================
// FILE: lib/features/subscription/presentation/pages/subscription_page.dart
// PURPOSE: Main Page for viewing and managing Platform Plans
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/reusable_data_table.dart' show StatusBadge;
import '../../provider/plan_provider.dart';
import '../../data/models/plan_model.dart';
import '../widgets/plan_dialog.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<PlanModel> _sortPlans(
    List<PlanModel> plans,
    int? columnIndex,
    bool ascending,
  ) {
    if (columnIndex == null || plans.isEmpty) return plans;
    final sorted = List<PlanModel>.from(plans);
    sorted.sort((a, b) {
      int cmp;
      switch (columnIndex) {
        case 0:
          cmp = a.planName.compareTo(b.planName);
          break;
        case 1:
          cmp = a.priceMonthly.compareTo(b.priceMonthly);
          break;
        case 2:
          cmp = a.priceYearly.compareTo(b.priceYearly);
          break;
        case 3:
          cmp = a.maxStudents.compareTo(b.maxStudents);
          break;
        case 4:
          cmp = a.maxTeachers.compareTo(b.maxTeachers);
          break;
        case 5:
          cmp = a.maxBranches.compareTo(b.maxBranches);
          break;
        case 6:
          cmp = a.activeSchoolCount.compareTo(b.activeSchoolCount);
          break;
        case 7:
          cmp = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          break;
        default:
          return 0;
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    ref.read(planProvider).fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;

    final filteredPlans = state.plans.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.planName.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(planProvider).fetchPlans(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: title + create button
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
                      AppStrings.subscriptionPlans,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const PlanDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(AppStrings.createPlan),
                    ),
                  ],
                ),
              ),

              // Search + filters
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24,
                  ),
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
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: AppStrings.searchPlans,
                                prefixIcon:
                                    const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 18),
                                        onPressed: _clearFilters,
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.filter_alt_off, size: 18),
                            label: const Text('Clear filters'),
                            onPressed: _clearFilters,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Plan cards grid
              if (!state.isLoading &&
                  state.error == null &&
                  filteredPlans.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24,
                    vertical: AppSpacing.lg,
                  ),
                  child: _buildCardsGrid(filteredPlans),
                ),

              AppSpacing.vGapLg,

              // Table area
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24,
                      0,
                      isNarrow ? 16 : 24,
                      isNarrow ? 16 : 24,
                    ),
                    child: _buildContent(filteredPlans, state, isWide),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<PlanModel> filteredPlans,
    dynamic state,
    bool isWide,
  ) {
    if (state.isLoading && state.plans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }

    if (state.error != null) {
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
              Text(state.error!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref.read(planProvider).fetchPlans(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchQuery.isNotEmpty
                    ? "No results for '$_searchQuery'"
                    : AppStrings.noPlansFound,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
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

    final sorted = _sortPlans(filteredPlans, _sortColumnIndex, _sortAscending);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListTableView(
              columns: const [
                AppStrings.planName,
                AppStrings.monthly,
                AppStrings.yearly,
                AppStrings.students,
                AppStrings.teachers,
                AppStrings.branches,
                AppStrings.activeSchools,
                AppStrings.tableStatus,
                AppStrings.tableActions,
              ],
              columnWidths: const [140, 90, 90, 80, 80, 80, 80, 80, 80],
              showSrNo: false,
              sortableColumns: const [0, 1, 2, 3, 4, 5, 6, 7],
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              onSort: (col, asc) => setState(() {
                _sortColumnIndex = col;
                _sortAscending = asc;
              }),
              isLoading: state.isLoading,
              rows: sorted.map((plan) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        plan.planName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                        Text('₹${plan.priceMonthly.toStringAsFixed(0)}')),
                    DataCell(
                        Text('₹${plan.priceYearly.toStringAsFixed(0)}')),
                    DataCell(Text(plan.maxStudents.toString())),
                    DataCell(Text(plan.maxTeachers.toString())),
                    DataCell(Text(plan.maxBranches.toString())),
                    DataCell(Text(plan.activeSchoolCount.toString())),
                    DataCell(
                      StatusBadge(
                          status: plan.isActive ? 'ACTIVE' : 'INACTIVE'),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: AppStrings.tooltipEditPlan,
                            child: IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      PlanDialog(plan: plan),
                                );
                              },
                            ),
                          ),
                          Tooltip(
                            message: AppStrings.tooltipDeletePlan,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.error500,
                              ),
                              onPressed: () =>
                                  _showDeleteDialog(context, plan),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid(List<PlanModel> plans) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 320,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) => _PlanCard(plan: plans[index]),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, PlanModel plan) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deletePlanTitle,
      message: AppStrings.deletePlanConfirm(plan.planName),
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await ref
        .read(planProvider)
        .deletePlan(plan.planId);
    if (!mounted) return;
    if (success) {
      AppSnackbar.success(context, AppStrings.planDeletedSuccess);
    } else {
      final error = ref.read(planProvider).error;
      AppSnackbar.error(context, error ?? AppStrings.failedToDeletePlan);
    }
  }
}

class _PlanCard extends ConsumerWidget {
  final PlanModel plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brXl2,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.neutral200),
      ),
      padding: AppSpacing.paddingXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.planName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge(status: plan.isActive ? 'ACTIVE' : 'INACTIVE'),
            ],
          ),
          AppSpacing.vGapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${plan.priceMonthly.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(AppStrings.perMonth, style: TextStyle(color: AppColors.neutral400)),
              AppSpacing.hGapSm,
              Text(
                '₹${plan.priceYearly.toStringAsFixed(0)} /yr',
                style: TextStyle(fontSize: 12, color: AppColors.neutral600),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildLimitRow(Icons.people_outline, '${plan.maxStudents} Students'),
          AppSpacing.vGapSm,
          _buildLimitRow(Icons.school_outlined, '${plan.maxTeachers} Teachers'),
          AppSpacing.vGapSm,
          _buildLimitRow(
            Icons.account_tree_outlined,
            '${plan.maxBranches} Branches',
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: AppColors.neutral400),
              AppSpacing.hGapSm,
              Text(
                '${plan.activeSchoolCount} Active Schools',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.vGapLg,
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Edit plan',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => PlanDialog(plan: plan),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(AppStrings.edit),
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              IconButton.filledTonal(
                onPressed: () =>
                    ref.read(planProvider).toggleStatus(plan.planId),
                icon: Icon(
                  plan.isActive ? Icons.toggle_on : Icons.toggle_off,
                  color: plan.isActive ? AppColors.success500 : AppColors.neutral400,
                ),
                tooltip: plan.isActive ? AppStrings.tooltipDeactivate : AppStrings.tooltipActivate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutral600),
        AppSpacing.hGapMd,
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
