import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/reusable_data_table.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSuspendDialog(
    BuildContext context,
    String schoolId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend School'),
        content: Text('Are you sure you want to suspend $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(schoolsViewModelProvider.notifier).suspendSchool(schoolId);
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
                          'Schools Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditSchoolScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add School'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: vm.onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search by school name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: vm.currentStatus,
                    onChanged: (v) {
                      if (v != null) vm.setStatusFilter(v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'SUSPENDED',
                        child: Text('Suspended'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: vm.onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by school name...',
                        prefixIcon: Icon(Icons.search),
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
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'SUSPENDED',
                          child: Text('Suspended'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContentCard(AsyncValue<PaginationModel<SchoolModel>> state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            if (data.data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No schools found'),
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              child: ReusableDataTable(
                columns: const [
                  'Code',
                  'School Name',
                  'Plan',
                  'Status',
                  'Students',
                  'Teachers',
                  'Exp. Date',
                  'Actions',
                ],
                rows: data.data.map((school) {
                  return DataRow(
                    cells: [
                      DataCell(Text(school.schoolCode)),
                      DataCell(
                        Text(
                          school.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          school.planName ?? 'N/A',
                          style: TextStyle(
                            color: school.planName != null
                                ? Colors.indigo
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(StatusBadge(status: school.status)),
                      DataCell(Text(school.maxStudents.toString())),
                      DataCell(Text(school.maxTeachers.toString())),
                      DataCell(
                        Text(
                          school.subscriptionEnd != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(school.subscriptionEnd!)
                              : 'N/A',
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
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
                            IconButton(
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
                            IconButton(
                              icon: const Icon(Icons.block, color: Colors.red),
                              onPressed: () => _showSuspendDialog(
                                context,
                                school.id,
                                school.name,
                              ),
                            ),
                          ],
                        ),
                      ),
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
