// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart
// PURPOSE: Super Admin schools list — search, filters, row actions, pagination
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/location_data.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../widgets/super_admin/dialogs/add_school_dialog.dart';
import '../../../../widgets/super_admin/dialogs/assign_plan_dialog.dart';
import '../../../../widgets/super_admin/dialogs/renew_subscription_dialog.dart';
import '../../../../widgets/super_admin/dialogs/resolve_overdue_dialog.dart';
import '../../../../widgets/super_admin/dialogs/school_detail_dialog.dart';
import '../../../../widgets/super_admin/super_admin_dialogs.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';

class SuperAdminSchoolsScreen extends ConsumerStatefulWidget {
  const SuperAdminSchoolsScreen({super.key});

  @override
  ConsumerState<SuperAdminSchoolsScreen> createState() =>
      _SuperAdminSchoolsScreenState();
}

class _SuperAdminSchoolsScreenState extends ConsumerState<SuperAdminSchoolsScreen> {
  bool _loading = true;
  bool _loadingMore = false;
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
          cmp = a.teacherCount.compareTo(b.teacherCount);
          break;
        case 5:
          cmp = (a.plan?.name ?? '').compareTo(b.plan?.name ?? '');
          break;
        case 6:
          cmp = a.status.compareTo(b.status);
          break;
        case 7:
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

  Future<void> _load({bool append = false}) async {
    if (!mounted) return;
    if (append) {
      if (_loadingMore || _loading) return;
      if (_schools.isNotEmpty && _schools.length >= _total && _total > 0) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final service = ref.read(superAdminServiceProvider);
      final planIdFromUrl = GoRouterState.of(context).uri.queryParameters['plan_id'];
      final requestPage = append
          ? (_schools.length ~/ _pageSize) + 1
          : _page;
      final result = await service.getSchools(
        page: requestPage,
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
          if (append) {
            final merged = [..._schools, ...result.data];
            final seen = <String>{};
            _schools = merged.where((s) => seen.add(s.id)).toList();
            _loadingMore = false;
          } else {
            _schools = result.data;
            _loading = false;
          }
          _total = result.total;
          _totalPages = result.totalPages > 0 ? result.totalPages : ((result.total / _pageSize).ceil()).clamp(1, 999);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (append) {
            _loadingMore = false;
          } else {
            _error = e.toString().replaceAll('Exception: ', '');
            _loading = false;
            _schools = [];
          }
        });
      }
    }
  }

  bool get _hasMoreSchools =>
      _schools.isNotEmpty && _total > 0 && _schools.length < _total;

  Future<void> _loadMoreSchools() => _load(append: true);

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

  bool get _hasLocationFilters =>
      _countryFilter != null || _stateFilter != null || _cityFilter != null;

  Future<void> _showMobileFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.filters,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                AppSpacing.vGapMd,
                SearchableDropdownFormField<String?>.valueItems(
                  value: _countryFilter,
                  valueItems: [
                    const MapEntry(null, 'All countries'),
                    ...LocationData.countries.map((c) => MapEntry<String?, String>(c, c)),
                  ],
                  hintText: AppStrings.country,
                  decoration: const InputDecoration(
                    labelText: AppStrings.country,
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
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
                AppSpacing.vGapSm,
                SearchableDropdownFormField<String?>.valueItems(
                  value: _countryFilter != null ? _stateFilter : null,
                  valueItems: [
                    const MapEntry(null, 'All states'),
                    ...(_countryFilter != null
                            ? LocationData.statesFor(_countryFilter!)
                            : <String>[])
                        .map((s) => MapEntry<String?, String>(s, s)),
                  ],
                  hintText: AppStrings.state,
                  decoration: const InputDecoration(
                    labelText: AppStrings.state,
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
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
                AppSpacing.vGapSm,
                SearchableDropdownFormField<String?>.valueItems(
                  value: (_countryFilter != null && _stateFilter != null) ? _cityFilter : null,
                  valueItems: [
                    const MapEntry(null, 'All cities'),
                    ...(_countryFilter != null && _stateFilter != null
                            ? LocationData.citiesFor(_countryFilter!, _stateFilter!)
                            : <String>[])
                        .map((c) => MapEntry<String?, String>(c, c)),
                  ],
                  hintText: AppStrings.city,
                  decoration: const InputDecoration(
                    labelText: AppStrings.city,
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  enabled: _countryFilter != null && _stateFilter != null,
                  onChanged: _countryFilter != null && _stateFilter != null
                      ? (v) {
                          setState(() {
                            _cityFilter = v;
                            _page = 1;
                          });
                          _load();
                        }
                      : null,
                ),
                AppSpacing.vGapLg,
                OutlinedButton.icon(
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
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text(AppStrings.clearFilters),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileSearchFilters(BuildContext context) {
    return ListScreenMobileFilterStrip(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListScreenMobilePillSearchField(
            controller: _searchController,
            hintText: AppStrings.searchSchools,
            onChanged: (_) => setState(() {}),
            onSubmitted: () {
              setState(() => _page = 1);
              _load();
            },
            onClear: () {
              _searchController.clear();
              setState(() => _page = 1);
              _load();
            },
          ),
          AppSpacing.vGapMd,
          ListScreenMobileFilterRow(
            children: [
              SearchableDropdownFormField<String>.valueItems(
                value: _statusFilter,
                valueItems: const [
                  MapEntry('all', 'All'),
                  MapEntry('active', 'Active'),
                  MapEntry('trial', 'Trial'),
                  MapEntry('suspended', 'Suspended'),
                  MapEntry('expiring', 'Expiring'),
                ],
                hintText: AppStrings.status,
                decoration: listScreenMobileFilterFieldDecoration(context),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _statusFilter = v;
                      _page = 1;
                    });
                    _load();
                  }
                },
              ),
              SearchableDropdownFormField<String?>.valueItems(
                value: _planFilter,
                valueItems: [
                  const MapEntry(null, 'All plans'),
                  ..._plans.map((p) => MapEntry<String?, String>(p.id, p.name)),
                ],
                hintText: AppStrings.plan,
                decoration: listScreenMobileFilterFieldDecoration(context),
                onChanged: (v) {
                  setState(() {
                    _planFilter = v;
                    _page = 1;
                  });
                  _load();
                },
              ),
              ListScreenMobileMoreFiltersButton(
                showActiveDot: _hasLocationFilters,
                onPressed: _showMobileFiltersSheet,
              ),
            ],
          ),
        ],
      ),
    );
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
    final isWide =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

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
              // Header: title + actions
              if (isNarrow)
                ListScreenMobileHeader(
                  title: 'Schools',
                  onExport: _exportSchools,
                  exportEnabled: !_loading,
                  primaryLabel: AppStrings.addSchool,
                  onPrimary: _openAddSchool,
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                            icon: const Icon(Icons.download, size: AppIconSize.md),
                            label: const Text(AppStrings.export),
                          ),
                          AppSpacing.hGapSm,
                          FilledButton.icon(
                            onPressed: _openAddSchool,
                            icon: const Icon(Icons.add, size: AppIconSize.md),
                            label: const Text(AppStrings.addSchool),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Search + filters
              if (isNarrow)
                _buildMobileSearchFilters(context)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              prefixIcon: const Icon(Icons.search, size: AppIconSize.md),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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

              if (isNarrow) AppSpacing.vGapSm else AppSpacing.vGapLg,

              // Table / list area
              Expanded(
                child: isNarrow
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildContent(isWide),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null && _schools.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: AppIconSize.xl3, color: Theme.of(context).colorScheme.error),
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
          padding: EdgeInsets.all(AppSpacing.xl4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: AppIconSize.xl4, color: Theme.of(context).colorScheme.outline),
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
    72.0,  // Students
    72.0,  // Faculty (staff)
    110.0, // Plan
    110.0, // Status
    110.0, // Expiry
    180.0, // Subdomain
    60.0,  // Actions (3-dot menu)
  ];

  static const _tableContentWidth =
      90.0 + 260 + 160 + 72 + 72 + 110 + 110 + 110 + 180 + 60 + 32;

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
                      'Faculty',
                      'Plan',
                      'Status',
                      'Expiry',
                      'Subdomain',
                      'Actions',
                    ],
                    columnWidths: _columnWidths,
                    sortableColumns: const [0, 1, 2, 3, 4, 5, 6, 7],
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
    return MobileInfiniteScrollList(
      itemCount: _schools.length,
      itemBuilder: (context, i) => _buildMobileCard(_schools[i]),
      hasMore: _hasMoreSchools,
      isLoadingMore: _loadingMore,
      onLoadMore: _loadMoreSchools,
      loadingLabel: 'Loading more schools…',
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

  DataRow _buildDataRow(SuperAdminSchoolModel s) {
    return DataRow(
      cells: [
        DataCell(Text(s.code, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
        DataCell(Text('${s.studentCount}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
        DataCell(Text('${s.teacherCount}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
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
              ? Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)
              : (s.status == 'expiring' || s.status == 'trial'
                  ? Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary)
                  : Theme.of(context).textTheme.bodySmall),
        )),
        DataCell(Text(
          s.subdomain != null && s.subdomain!.isNotEmpty
              ? '${s.subdomain}.vidyron.in'
              : '—',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.tertiary,
          ),
          overflow: TextOverflow.ellipsis,
        )),
        DataCell(HoverPopupMenu<String>(
          icon: const Icon(Icons.more_vert, size: AppIconSize.md),
          padding: EdgeInsets.zero,
          onSelected: (v) => _onSchoolRowMenuSelected(s, v),
          itemBuilder: (ctx) => _schoolRowMenuItems(s, omitManage: false),
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

  void _onSchoolRowMenuSelected(SuperAdminSchoolModel s, String v) {
    switch (v) {
      case 'manage':
        _openSchoolDetail(s);
        break;
      case 'assign':
        _openAssignPlan(s);
        break;
      case 'copy':
        _copyLoginUrl(s);
        break;
      case 'renew':
        _openRenew(s);
        break;
      case 'resolve':
        _openResolve(s);
        break;
      case 'unsuspend':
        _unsuspend(s);
        break;
    }
  }

  /// Desktop table: include Manage. Mobile card: omit Manage (card tap opens detail).
  List<PopupMenuEntry<String>> _schoolRowMenuItems(
    SuperAdminSchoolModel s, {
    required bool omitManage,
  }) {
    final items = <PopupMenuEntry<String>>[];
    if (!omitManage) {
      items.add(
        const PopupMenuItem<String>(
          value: 'manage',
          child: ListTile(
            leading: Icon(Icons.settings, size: AppIconSize.md),
            title: Text(AppStrings.manage),
            dense: true,
          ),
        ),
      );
    }
    items.addAll([
      const PopupMenuItem<String>(
        value: 'assign',
        child: ListTile(
          leading: Icon(Icons.layers, size: AppIconSize.md),
          title: Text(AppStrings.assignPlan),
          dense: true,
        ),
      ),
      const PopupMenuItem<String>(
        value: 'copy',
        child: ListTile(
          leading: Icon(Icons.link, size: AppIconSize.md),
          title: Text(AppStrings.copyUrl),
          dense: true,
        ),
      ),
    ]);
    if (s.status == 'expiring' || s.status == 'trial') {
      items.add(
        const PopupMenuItem<String>(
          value: 'renew',
          child: ListTile(
            leading: Icon(Icons.refresh, size: AppIconSize.md),
            title: Text(AppStrings.renew),
            dense: true,
          ),
        ),
      );
    }
    if (s.status == 'suspended' || s.overdueDays > 0) {
      items.add(
        const PopupMenuItem<String>(
          value: 'resolve',
          child: ListTile(
            leading: Icon(Icons.check_circle, size: AppIconSize.md),
            title: Text(AppStrings.resolve),
            dense: true,
          ),
        ),
      );
    }
    if (s.status == 'suspended') {
      items.add(
        const PopupMenuItem<String>(
          value: 'unsuspend',
          child: ListTile(
            leading: Icon(Icons.lock_open, size: AppIconSize.md),
            title: Text(AppStrings.unsuspend),
            dense: true,
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildMobileCard(SuperAdminSchoolModel s) {
    final typeLabel = s.schoolType.isNotEmpty
        ? (s.schoolType.length > 1
            ? s.schoolType[0].toUpperCase() + s.schoolType.substring(1)
            : s.schoolType.toUpperCase())
        : '—';
    final statusLabel = s.status.isNotEmpty
        ? (s.status.length > 1
            ? s.status[0].toUpperCase() + s.status.substring(1)
            : s.status.toUpperCase())
        : '—';
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _openSchoolDetail(s),
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
                      s.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  HoverPopupMenu<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    padding: EdgeInsets.zero,
                    onSelected: (v) => _onSchoolRowMenuSelected(s, v),
                    itemBuilder: (ctx) => _schoolRowMenuItems(s, omitManage: true),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '${s.board} · $typeLabel',
                style: smallMuted,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.city != null && s.city!.trim().isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  s.city!,
                                  style: smallMuted,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          'ID: ${s.code}',
                          style: smallMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Students: ${s.studentCount} · Faculty: ${s.teacherCount}',
                          style: smallMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
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
                              s.plan?.name ?? '—',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: cs.outlineVariant),
                            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          Chip(
                            label: Text(statusLabel),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _statusColor(s.status),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Expiry: ${_formatExpiry(s)}',
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
