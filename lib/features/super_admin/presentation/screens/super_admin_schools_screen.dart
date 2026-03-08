// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart
// PURPOSE: Super Admin schools list — search, filters, row actions, pagination
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';

// Indian states for filter
const _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal', 'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry',
];

class SuperAdminSchoolsScreen extends ConsumerStatefulWidget {
  const SuperAdminSchoolsScreen({super.key});

  @override
  ConsumerState<SuperAdminSchoolsScreen> createState() =>
      _SuperAdminSchoolsScreenState();
}

class _SuperAdminSchoolsScreenState extends ConsumerState<SuperAdminSchoolsScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminSchoolModel> _schools = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _statusFilter = 'all';
  String? _planFilter;
  String? _stateFilter;
  List<SuperAdminPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlans();
        _load();
      }
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _page = 1);
        _load();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final p = await ref.read(superAdminServiceProvider).getPlans();
      if (mounted) setState(() => _plans = p);
    } catch (_) {}
  }

  Future<void> _load({bool append = false}) async {
    if (!mounted) return;
    if (!append) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final service = ref.read(superAdminServiceProvider);
      final result = await service.getSchools(
        page: _page,
        limit: 20,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _statusFilter == 'all' ? null : _statusFilter,
        planId: GoRouterState.of(context).uri.queryParameters['plan_id'] ?? _planFilter,
        state: _stateFilter,
        groupId: GoRouterState.of(context).uri.queryParameters['group_id'],
      );
      if (mounted) {
        setState(() {
          if (append) {
            _schools.addAll(result.data);
          } else {
            _schools = result.data;
          }
          _totalPages = result.totalPages > 0 ? result.totalPages : ((result.total / 20).ceil()).clamp(1, 999);
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _loadingMore = false;
          if (!append) _schools = [];
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _page++);
    await _load(append: true);
  }

  void _openSchoolDetail(SuperAdminSchoolModel s) {
    showAdaptiveModal(
      context,
      SchoolDetailDialog(
        schoolId: s.id,
        onUpdated: () => _load(),
      ),
    );
  }

  Future<void> _openAssignPlan(SuperAdminSchoolModel s) async {
    final plans = _plans.map((e) => {
      'id': e.id,
      'name': e.name,
      'price_per_student': e.pricePerStudent,
      'priceMonthly': e.pricePerStudent,
    }).toList();
    if (!mounted) return;
    showAdaptiveModal(
      context,
      AssignPlanDialog(
        schoolName: s.name,
        currentPlanName: s.plan?.name,
        plans: plans,
        onAssign: (planId, effectiveDate, reason) async {
          await ref.read(superAdminServiceProvider).assignPlan(s.id, {
            'plan_id': planId,
            'effective_date': effectiveDate?.toIso8601String(),
            'reason': reason,
          });
          if (mounted) _load();
        },
      ),
    );
  }

  void _copyLoginUrl(SuperAdminSchoolModel s) {
    final sub = s.subdomain ?? s.code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final url = 'https://$sub.vidyron.in';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login URL copied: $url')),
    );
  }

  void _openRenew(SuperAdminSchoolModel s) {
    final monthlyAmount = (s.plan?.pricePerStudent ?? 0) * s.studentCount;
    showAdaptiveModal(
      context,
      RenewSubscriptionDialog(
        schoolName: s.name,
        planName: s.plan?.name ?? '—',
        currentEndDate: s.subscriptionEnd,
        monthlyAmount: monthlyAmount > 0 ? monthlyAmount : 1000,
        onRenew: (durationMonths, paymentRef) async {
          await ref.read(superAdminServiceProvider).renewSubscription(s.id, {
            'duration_months': durationMonths,
            'payment_ref': paymentRef,
          });
          if (mounted) _load();
        },
      ),
    );
  }

  void _openResolve(SuperAdminSchoolModel s) {
    showAdaptiveModal(
      context,
      ResolveOverdueDialog(
        schoolName: s.name,
        overdueDays: s.overdueDays,
        onResolve: (action, paymentRef) async {
          await ref.read(superAdminServiceProvider).resolveOverdue(
            s.id,
            {'action': action, 'payment_ref': paymentRef},
          );
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _unsuspend(SuperAdminSchoolModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsuspend School?'),
        content: Text(
          'Reactivate ${s.name}? Staff and students will regain access.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unsuspend')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolStatus(s.id, 'active');
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School reactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportSchools() async {
    try {
      await ref.read(superAdminServiceProvider).exportSchools(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _statusFilter == 'all' ? null : _statusFilter,
        planId: _planFilter,
        state: _stateFilter,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schools exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openAddSchool() async {
    final plans = _plans.map((e) => {
      'id': e.id,
      'name': e.name,
      'price_per_student': e.pricePerStudent,
      'priceMonthly': e.pricePerStudent,
    }).toList();
    if (!mounted) return;
    showAdaptiveModal(
      context,
      AddSchoolDialog(
        plans: plans,
        groups: [],
        onCreate: (body) async {
          await ref.read(superAdminServiceProvider).createSchool(body);
          if (mounted) {
            _load();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('School created')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _page = 1);
        await _load();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schools',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _loading ? null : _exportSchools,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _openAddSchool,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add School'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schools...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _page = 1);
                          _load();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                setState(() => _page = 1);
                _load();
              },
            ),
            const SizedBox(height: 16),

            // Filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _statusFilter == 'all',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'all';
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                  _FilterChip(
                    label: 'Active',
                    selected: _statusFilter == 'active',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'active';
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                  _FilterChip(
                    label: 'Trial',
                    selected: _statusFilter == 'trial',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'trial';
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                  _FilterChip(
                    label: 'Suspended',
                    selected: _statusFilter == 'suspended',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'suspended';
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                  _FilterChip(
                    label: 'Expiring',
                    selected: _statusFilter == 'expiring',
                    onTap: () {
                      setState(() {
                        _statusFilter = 'expiring';
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Plan & State dropdowns
            if (isWide)
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _planFilter,
                      decoration: const InputDecoration(
                        labelText: 'Plan',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All plans')),
                        ..._plans.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _planFilter = v;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _stateFilter,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All states')),
                        ..._indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _stateFilter = v;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            if (_loading && _schools.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: ShimmerListLoadingWidget(itemCount: 8),
              )
            else if (_error != null && _schools.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => _load(), child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_schools.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? "No results for '${_searchController.text}'"
                            : 'No schools found',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _statusFilter = 'all';
                            _planFilter = null;
                            _stateFilter = null;
                            _page = 1;
                          });
                          _load();
                        },
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildSchoolList(isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolList(bool isWide) {
    return Column(
      children: [
        if (isWide)
          _buildTable()
        else
          ..._schools.map((s) => _buildMobileCard(s)),
        if (_page < _totalPages)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingMore
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: FilledButton(
                      onPressed: _loadMore,
                      child: const Text('Load more'),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('School')),
          DataColumn(label: Text('Code')),
          DataColumn(label: Text('Plan')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _schools.map((s) => DataRow(
          cells: [
            DataCell(
              Text(s.name),
              onTap: () => _openSchoolDetail(s),
            ),
            DataCell(Text(s.code)),
            DataCell(Text(s.plan?.name ?? '—')),
            DataCell(
              Chip(
                label: Text(s.status),
                backgroundColor: _statusColor(s.status),
              ),
            ),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: () => _openSchoolDetail(s),
                  tooltip: 'Manage',
                ),
                IconButton(
                  icon: const Icon(Icons.layers, size: 20),
                  onPressed: () => _openAssignPlan(s),
                  tooltip: 'Assign Plan',
                ),
                IconButton(
                  icon: const Icon(Icons.link, size: 20),
                  onPressed: () => _copyLoginUrl(s),
                  tooltip: 'Copy URL',
                ),
                if (s.status == 'expiring' || s.status == 'trial')
                  TextButton(
                    onPressed: () => _openRenew(s),
                    child: const Text('Renew'),
                  ),
                if (s.status == 'suspended' || s.overdueDays > 0)
                  TextButton(
                    onPressed: () => _openResolve(s),
                    child: const Text('Resolve'),
                  ),
                if (s.status == 'suspended')
                  TextButton(
                    onPressed: () => _unsuspend(s),
                    child: const Text('Unsuspend'),
                  ),
              ],
            )),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMobileCard(SuperAdminSchoolModel s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openSchoolDetail(s),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${s.city ?? ''} • ${s.code}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(s.status),
                    backgroundColor: _statusColor(s.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () => _openSchoolDetail(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.layers, size: 20),
                    onPressed: () => _openAssignPlan(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link, size: 20),
                    onPressed: () => _copyLoginUrl(s),
                  ),
                  if (s.status == 'expiring' || s.status == 'trial')
                    FilledButton.tonal(
                      onPressed: () => _openRenew(s),
                      child: const Text('Renew'),
                    ),
                  if (s.status == 'suspended' || s.overdueDays > 0)
                    FilledButton.tonal(
                      onPressed: () => _openResolve(s),
                      child: const Text('Resolve'),
                    ),
                  if (s.status == 'suspended')
                    TextButton(
                      onPressed: () => _unsuspend(s),
                      child: const Text('Unsuspend'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _statusColor(String? s) {
    if (s == null) return null;
    switch (s.toLowerCase()) {
      case 'active':
        return Colors.green.withValues(alpha: 0.2);
      case 'trial':
        return Colors.blue.withValues(alpha: 0.2);
      case 'suspended':
        return Colors.red.withValues(alpha: 0.2);
      case 'expiring':
        return Colors.orange.withValues(alpha: 0.2);
      default:
        return null;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
