// =============================================================================
// FILE: lib/features/subscription/presentation/pages/subscription_page.dart
// PURPOSE: Main Page for viewing and managing Platform Plans
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/plan_provider.dart';
import '../../data/models/plan_model.dart';
import '../widgets/plan_dialog.dart';
import '../../../../shared/widgets/reusable_data_table.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch plans on init
    Future.microtask(() => ref.read(planProvider).fetchPlans());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planProvider);

    // Filter plans based on search
    final filteredPlans = state.plans.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.planName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: state.isLoading && state.plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(planProvider).fetchPlans(),
              child: CustomScrollView(
                slivers: [
                  // --- Header ---
                  _buildHeader(context),

                  // --- Plans Grid ---
                  if (state.error != null)
                    SliverToBoxAdapter(child: _buildError(state.error!))
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      sliver: _buildCardsGrid(filteredPlans),
                    ),

                    // --- Table Section ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildDataTable(filteredPlans, state.isLoading),
                      ),
                    ),
                  ],

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 200,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription Plans',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Manage SaaS pricing and platform limits',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search plans...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => ref.read(planProvider).fetchPlans(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(context: context, builder: (context) => const PlanDialog());
      },
      icon: const Icon(Icons.add),
      label: const Text('Create Plan'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCardsGrid(List<PlanModel> plans) {
    if (plans.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text('No plans found')),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 320,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _PlanCard(plan: plans[index]),
        childCount: plans.length,
      ),
    );
  }

  Widget _buildDataTable(List<PlanModel> plans, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Detailed Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ReusableDataTable(
            isLoading: isLoading && plans.isEmpty,
            columns: const [
              'Plan Name',
              'Monthly',
              'Yearly',
              'Students',
              'Teachers',
              'Branches',
              'Active Schools',
              'Status',
              'Actions',
            ],
            rows: plans.map((plan) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      plan.planName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text('₹${plan.priceMonthly.toStringAsFixed(0)}')),
                  DataCell(Text('₹${plan.priceYearly.toStringAsFixed(0)}')),
                  DataCell(Text(plan.maxStudents.toString())),
                  DataCell(Text(plan.maxTeachers.toString())),
                  DataCell(Text(plan.maxBranches.toString())),
                  DataCell(Text(plan.activeSchoolCount.toString())),
                  DataCell(
                    StatusBadge(status: plan.isActive ? 'ACTIVE' : 'INACTIVE'),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => PlanDialog(plan: plan),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteDialog(context, plan),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          IconButton(
            onPressed: () => ref.read(planProvider).clearError(),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.planName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(planProvider)
                  .deletePlan(plan.planId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan deleted successfully')),
                );
              } else {
                final error = ref.read(planProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Failed to delete plan')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
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
              const Text(' /mo', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Text(
                '₹${plan.priceYearly.toStringAsFixed(0)} /yr',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildLimitRow(Icons.people_outline, '${plan.maxStudents} Students'),
          const SizedBox(height: 8),
          _buildLimitRow(Icons.school_outlined, '${plan.maxTeachers} Teachers'),
          const SizedBox(height: 8),
          _buildLimitRow(
            Icons.account_tree_outlined,
            '${plan.maxBranches} Branches',
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${plan.activeSchoolCount} Active Schools',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PlanDialog(plan: plan),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () =>
                    ref.read(planProvider).toggleStatus(plan.planId),
                icon: Icon(
                  plan.isActive ? Icons.toggle_on : Icons.toggle_off,
                  color: plan.isActive ? Colors.green : Colors.grey,
                ),
                tooltip: plan.isActive ? 'Deactivate' : 'Activate',
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
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
