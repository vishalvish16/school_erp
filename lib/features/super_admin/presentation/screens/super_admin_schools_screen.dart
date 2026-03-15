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
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/location_data.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

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
  int _total = 0;
  int _pageSize = 15;
  static const _pageSizeOptions = [10, 15, 25, 50];
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _statusFilter = 'all';
  String? _planFilter;
  String? _countryFilter;
  String? _stateFilter;
  String? _cityFilter;
  List<SuperAdminPlanModel> _plans = [];
  List<SuperAdminSchoolGroupModel> _groups = [];
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<SuperAdminSchoolModel> _sortSchools(
    List<SuperAdminSchoolModel> list,
    int? columnIndex,
    bool ascending,
  ) {
    if (columnIndex == null || list.isEmpty) return list;
    final sorted = List<SuperAdminSchoolModel>.from(list);
    sorted.sort((a, b) {
      int cmp;
      switch (columnIndex) {
        case 0:
          cmp = a.code.compareTo(b.code);
          break;
        case 1:
          cmp = a.name.compareTo(b.name);
          break;
        case 2:
          cmp = ((a.city ?? '') + (a.state ?? '')).compareTo((b.city ?? '') + (b.state ?? ''));
          break;
        case 3:
          cmp = a.studentCount.compareTo(b.studentCount);
          break;
        case 4:
          cmp = (a.plan?.name ?? '').compareTo(b.plan?.name ?? '');
          break;
        case 5:
          cmp = a.status.compareTo(b.status);
          break;
        case 6:
          cmp = (a.subscriptionEnd ?? DateTime(0)).compareTo(b.subscriptionEnd ?? DateTime(0));
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
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlans();
        _loadGroups();
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

  Future<void> _loadGroups() async {
    try {
      final g = await ref.read(superAdminServiceProvider).getGroups();
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      final planIdFromUrl = GoRouterState.of(context).uri.queryParameters['plan_id'];
      final result = await service.getSchools(
        page: _page,
        limit: _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _statusFilter == 'all' ? null : _statusFilter,
        planId: planIdFromUrl ?? _planFilter,
        country: _countryFilter,
        state: _stateFilter,
        city: _cityFilter,
        groupId: GoRouterState.of(context).uri.queryParameters['group_id'],
      );
      if (mounted) {
        setState(() {
          _schools = result.data;
          _total = result.total;
          _totalPages = result.totalPages > 0 ? result.totalPages : ((result.total / _pageSize).ceil()).clamp(1, 999);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _schools = [];
        });
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _page = page);
    _load();
  }

  void _onPageSizeChanged(int? value) {
    if (value == null || value == _pageSize) return;
    setState(() {
      _pageSize = value;
      _page = 1;
    });
    _load();
  }

  void _openSchoolDetail(SuperAdminSchoolModel s) {
    showAdaptiveModal(
      context,
      SchoolDetailDialog(
        schoolId: s.id,
        onUpdated: () => _load(),
      ),
      maxWidth: kDialogMaxWidthLarge,
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
        currentPlanId: s.plan?.id,
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
    AppSnackbar.info(context, 'Login URL copied: $url');
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
    final ok = await AppDialogs.confirm(
      context,
      title: AppStrings.unsuspendSchoolQuestion,
      message: 'Reactivate ${s.name}? Staff and students will regain access.',
      confirmLabel: AppStrings.unsuspend,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(superAdminServiceProvider).updateSchoolStatus(s.id, 'active');
      if (mounted) {
        _load();
        AppSnackbar.success(context, AppStrings.schoolReactivated);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    }
  }

  Future<void> _exportSchools() async {
    try {
      await ref.read(superAdminServiceProvider).exportSchools(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _statusFilter == 'all' ? null : _statusFilter,
        planId: _planFilter,
        country: _countryFilter,
        state: _stateFilter,
        city: _cityFilter,
      );
      if (mounted) {
        AppSnackbar.success(context, AppStrings.schoolsExported);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Export failed: ${e.toString()}');
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
        groups: _groups.map((g) => {'id': g.id, 'name': g.name}).toList(),
        onCreate: (body) async {
          await ref.read(superAdminServiceProvider).createSchool(body);
          if (mounted) {
            _load();
            AppSnackbar.success(context, AppStrings.schoolCreated);
          }
        },
      ),
      maxWidth: kDialogMaxWidthLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _page = 1);
        await _load();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FIXED Header: title + actions
              Padding(
                padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, isNarrow ? 16 : 24, isNarrow ? 16 : 24, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Schools',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _loading ? null : _exportSchools,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text(AppStrings.export),
                        ),
                        AppSpacing.hGapSm,
                        FilledButton.icon(
                          onPressed: _openAddSchool,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(AppStrings.addSchool),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // FIXED Search + filters — ALL ON ONE LINE (centered)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
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
                            decoration: InputDecoration(
                              hintText: AppStrings.searchSchools,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _page = 1);
                                        _load();
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                            ),
                            onSubmitted: (_) {
                              setState(() => _page = 1);
                              _load();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String>.valueItems(
                            value: _statusFilter,
                            valueItems: const [
                              MapEntry('all', 'All'),
                              MapEntry('active', 'Active'),
                              MapEntry('trial', 'Trial'),
                              MapEntry('suspended', 'Suspended'),
                              MapEntry('expiring', 'Expiring'),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.status,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() { _statusFilter = v; _page = 1; });
                                _load();
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String?>.valueItems(
                            value: _planFilter,
                            valueItems: [
                              const MapEntry(null, 'All plans'),
                              ..._plans.map((p) => MapEntry<String?, String>(p.id, p.name)),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.plan,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              setState(() { _planFilter = v; _page = 1; });
                              _load();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String?>.valueItems(
                            value: _countryFilter,
                            valueItems: [
                              const MapEntry(null, 'All countries'),
                              ...LocationData.countries.map((c) => MapEntry<String?, String>(c, c)),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.country,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              setState(() {
                                _countryFilter = v;
                                _stateFilter = null;
                                _cityFilter = null;
                                _page = 1;
                              });
                              _load();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String?>.valueItems(
                            value: _countryFilter != null ? _stateFilter : null,
                            valueItems: [
                              const MapEntry(null, 'All states'),
                              ...(_countryFilter != null
                                  ? LocationData.statesFor(_countryFilter!)
                                  : <String>[]).map((s) => MapEntry<String?, String>(s, s)),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.state,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              isDense: true,
                            ),
                            enabled: _countryFilter != null,
                            onChanged: _countryFilter != null
                                ? (v) {
                                    setState(() {
                                      _stateFilter = v;
                                      _cityFilter = null;
                                      _page = 1;
                                    });
                                    _load();
                                  }
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: SearchableDropdownFormField<String?>.valueItems(
                            value: (_countryFilter != null && _stateFilter != null) ? _cityFilter : null,
                            valueItems: [
                              const MapEntry(null, 'All cities'),
                              ...(_countryFilter != null && _stateFilter != null
                                  ? LocationData.citiesFor(_countryFilter!, _stateFilter!)
                                      .map((c) => MapEntry<String?, String>(c, c))
                                  : <MapEntry<String?, String>>[]),
                            ],
                            decoration: const InputDecoration(
                              labelText: AppStrings.city,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              isDense: true,
                            ),
                            enabled: _countryFilter != null && _stateFilter != null,
                            onChanged: _countryFilter != null && _stateFilter != null
                                ? (v) {
                                    setState(() { _cityFilter = v; _page = 1; });
                                    _load();
                                  }
                                : null,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.filter_alt_off, size: 18),
                          label: const Text(AppStrings.clearFilters),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _statusFilter = 'all';
                              _planFilter = null;
                              _countryFilter = null;
                              _stateFilter = null;
                              _cityFilter = null;
                              _page = 1;
                            });
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),

              AppSpacing.vGapLg,

              // Table area — fixed header, scrollable body (centered)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isNarrow ? 16 : 24, 0, isNarrow ? 16 : 24, isNarrow ? 16 : 24),
                    child: _buildContent(isWide),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(bool isWide) {
    if (_loading && _schools.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }
    if (_error != null && _schools.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapLg,
              Text(_error!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(onPressed: () => _load(), child: const Text(AppStrings.retry)),
            ],
          ),
        ),
      );
    }
    if (_schools.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchController.text.isNotEmpty
                    ? "No results for '${_searchController.text}'"
                    : 'No schools found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapSm,
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _statusFilter = 'all';
                    _planFilter = null;
                    _countryFilter = null;
                    _stateFilter = null;
                    _cityFilter = null;
                    _page = 1;
                  });
                  _load();
                },
                child: const Text(AppStrings.clearFilters),
              ),
            ],
          ),
        ),
      );
    }
    return _buildSchoolList(isWide);
  }

  static const _columnWidths = [
    90.0,  // Code (ID)
    260.0, // School (Title - wider to avoid truncation)
    160.0, // City
    85.0,  // Students
    110.0, // Plan
    110.0, // Status
    110.0, // Expiry
    180.0, // Subdomain
    60.0,  // Actions (3-dot menu)
  ];

  static const _tableContentWidth = 90.0 + 260 + 160 + 85 + 110 + 110 + 110 + 180 + 60 + 32;

  Widget _buildSchoolList(bool isWide) {
    if (isWide) {
      final sorted = _sortSchools(_schools, _sortColumnIndex, _sortAscending);
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
                      'Code',
                      'School',
                      'City',
                      'Students',
                      'Plan',
                      'Status',
                      'Expiry',
                      'Subdomain',
                      'Actions',
                    ],
                    columnWidths: _columnWidths,
                    sortableColumns: const [0, 1, 2, 3, 4, 5, 6],
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    onSort: (col, asc) => setState(() {
                      _sortColumnIndex = col;
                      _sortAscending = asc;
                    }),
                    showSrNo: false,
                    itemCount: sorted.length,
                    rowBuilder: (i) => _buildDataRow(sorted[i]),
                  ),
                ),
                _buildPaginationRow(),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: _schools.map((s) => _buildMobileCard(s)).toList(),
          ),
        ),
        if (_schools.isNotEmpty)
          Card(child: _buildPaginationRow()),
      ],
    );
  }

  Widget _buildPaginationRow() {
    final cs = Theme.of(context).colorScheme;
    final start = _total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;
    final end = (_page * _pageSize).clamp(0, _total);

    Widget pageButton(String label, {required int page, bool active = false}) {
      final enabled = page != _page && page >= 1 && page <= _totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? () => _goToPage(page) : null,
            child: Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              padding: AppSpacing.paddingHSm,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
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
      int rangeStart = (_page - (maxVisible ~/ 2)).clamp(1, _totalPages);
      int rangeEnd = (rangeStart + maxVisible - 1).clamp(1, _totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart = (rangeEnd - maxVisible + 1).clamp(1, _totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(pageButton('$i', page: i, active: i == _page));
      }
      return pages;
    }

    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle = textStyle.copyWith(color: cs.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Showing $start to $end of $_total entries', style: mutedStyle),
          AppSpacing.hGapXl,
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppStrings.show, style: mutedStyle),
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
                    value: _pageSize,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: textStyle.copyWith(color: cs.onSurface),
                    items: _pageSizeOptions.map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                    onChanged: _onPageSizeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(AppStrings.entries, style: mutedStyle),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton('First', page: 1),
              pageButton('Previous', page: _page - 1),
              ...pageNumbers(),
              pageButton('Next', page: _page + 1),
              pageButton('Last', page: _totalPages),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(SuperAdminSchoolModel s) {
    return DataRow(
      cells: [
        DataCell(Text(s.code, style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ))),
        DataCell(
          InkWell(
            onTap: () => _openSchoolDetail(s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      Text(
                        '${s.board} · ${s.schoolType.isNotEmpty ? (s.schoolType.length > 1 ? s.schoolType[0].toUpperCase() + s.schoolType.substring(1) : s.schoolType.toUpperCase()) : '—'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(s.city ?? '—', overflow: TextOverflow.ellipsis)),
        DataCell(Text('${s.studentCount}', style: const TextStyle(fontFamily: 'monospace'))),
        DataCell(Text(s.plan?.name ?? '—', overflow: TextOverflow.ellipsis)),
        DataCell(
          Chip(
            label: Text(s.status),
            backgroundColor: _statusColor(s.status),
          ),
        ),
        DataCell(Text(
          _formatExpiry(s),
          style: s.overdueDays > 0
              ? TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)
              : (s.status == 'expiring' || s.status == 'trial'
                  ? TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 12)
                  : null),
        )),
        DataCell(Text(
          s.subdomain != null && s.subdomain!.isNotEmpty
              ? '${s.subdomain}.vidyron.in'
              : '—',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          overflow: TextOverflow.ellipsis,
        )),
        DataCell(PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          padding: EdgeInsets.zero,
          tooltip: 'Actions',
          onSelected: (v) {
            switch (v) {
              case 'manage': _openSchoolDetail(s); break;
              case 'assign': _openAssignPlan(s); break;
              case 'copy': _copyLoginUrl(s); break;
              case 'renew': _openRenew(s); break;
              case 'resolve': _openResolve(s); break;
              case 'unsuspend': _unsuspend(s); break;
            }
          },
          itemBuilder: (ctx) {
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'manage', child: ListTile(leading: Icon(Icons.settings, size: 20), title: Text(AppStrings.manage), dense: true)),
              const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.layers, size: 20), title: Text(AppStrings.assignPlan), dense: true)),
              const PopupMenuItem(value: 'copy', child: ListTile(leading: Icon(Icons.link, size: 20), title: Text(AppStrings.copyUrl), dense: true)),
            ];
            if (s.status == 'expiring' || s.status == 'trial') {
              items.add(const PopupMenuItem(value: 'renew', child: ListTile(leading: Icon(Icons.refresh, size: 20), title: Text(AppStrings.renew), dense: true)));
            }
            if (s.status == 'suspended' || s.overdueDays > 0) {
              items.add(const PopupMenuItem(value: 'resolve', child: ListTile(leading: Icon(Icons.check_circle, size: 20), title: Text(AppStrings.resolve), dense: true)));
            }
            if (s.status == 'suspended') {
              items.add(const PopupMenuItem(value: 'unsuspend', child: ListTile(leading: Icon(Icons.lock_open, size: 20), title: Text(AppStrings.unsuspend), dense: true)));
            }
            return items;
          },
        )),
      ],
    );
  }

  String _formatExpiry(SuperAdminSchoolModel s) {
    if (s.subscriptionEnd == null) return '—';
    if (s.overdueDays > 0) return AppStrings.overdue;
    return '${s.subscriptionEnd!.day} ${_monthShort(s.subscriptionEnd!.month)} ${s.subscriptionEnd!.year}';
  }

  String _monthShort(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(m - 1).clamp(0, 11)];
  }

  Widget _buildMobileCard(SuperAdminSchoolModel s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openSchoolDetail(s),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                  ),
                  AppSpacing.hGapMd,
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
              AppSpacing.vGapMd,
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
                      child: const Text(AppStrings.renew),
                    ),
                  if (s.status == 'suspended' || s.overdueDays > 0)
                    FilledButton.tonal(
                      onPressed: () => _openResolve(s),
                      child: const Text(AppStrings.resolve),
                    ),
                  if (s.status == 'suspended')
                    TextButton(
                      onPressed: () => _unsuspend(s),
                      child: const Text(AppStrings.unsuspend),
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
        return AppColors.success500.withValues(alpha: 0.2);
      case 'trial':
        return AppColors.secondary500.withValues(alpha: 0.2);
      case 'suspended':
        return AppColors.error500.withValues(alpha: 0.2);
      case 'expiring':
        return AppColors.warning500.withValues(alpha: 0.2);
      default:
        return null;
    }
  }
}
