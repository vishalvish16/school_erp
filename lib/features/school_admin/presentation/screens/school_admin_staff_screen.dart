// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_staff_screen.dart
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../models/school_admin/staff_model.dart';

import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import '../providers/school_admin_staff_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_toast.dart';

const List<String> _designations = [
  'TEACHER',
  'CLERK',
  'LIBRARIAN',
  'ACCOUNTANT',
  'PRINCIPAL',
  'VICE_PRINCIPAL',
  'COUNSELOR',
  'OTHER',
];

class SchoolAdminStaffScreen extends ConsumerStatefulWidget {
  const SchoolAdminStaffScreen({super.key});

  @override
  ConsumerState<SchoolAdminStaffScreen> createState() =>
      _SchoolAdminStaffScreenState();
}

class _SchoolAdminStaffScreenState
    extends ConsumerState<SchoolAdminStaffScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminStaffProvider.notifier).loadStaff();
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(schoolAdminStaffProvider.notifier).setSearch(_searchCtrl.text);
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

  void _clearFilters() {
    _searchCtrl.clear();
    final notifier = ref.read(schoolAdminStaffProvider.notifier);
    notifier.setSearch('');
    notifier.setDesignationFilter(null);
    notifier.setActiveFilter(null);
  }

  void _onPageSizeChanged(int? value) {
    if (value == null) return;
    ref.read(schoolAdminStaffProvider.notifier).setPageSize(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolAdminStaffProvider);
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(schoolAdminStaffProvider.notifier).loadStaff(refresh: true);
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
                        AppStrings.schoolStaff,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Manage teachers and staff profiles',
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
                        onPressed: () => _showAddDialog(context),
                        icon: const Icon(Icons.add, size: AppIconSize.md),
                        label: Text(AppStrings.addStaff),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Wide filter card — full width (no Center) ─────────────────
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
                                    onPressed: _searchCtrl.clear,
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
                          value: state.designationFilter,
                          valueItems: [
                            const MapEntry(null, 'All Roles'),
                            for (final d in _designations)
                              MapEntry<String?, String>(d, d),
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.designation,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            isDense: true,
                          ),
                          onChanged: (v) => ref
                              .read(schoolAdminStaffProvider.notifier)
                              .setDesignationFilter(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: SearchableDropdownFormField<String?>.valueItems(
                          value: state.isActiveFilter == null
                              ? null
                              : state.isActiveFilter == true
                                  ? 'active'
                                  : 'inactive',
                          valueItems: const [
                            MapEntry(null, 'All'),
                            MapEntry('active', 'Active'),
                            MapEntry('inactive', 'Inactive'),
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.status,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final bool? filter = v == 'active'
                                ? true
                                : v == 'inactive'
                                    ? false
                                    : null;
                            ref
                                .read(schoolAdminStaffProvider.notifier)
                                .setActiveFilter(filter);
                          },
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
              title: AppStrings.schoolStaff,
              primaryLabel: AppStrings.addStaff,
              onPrimary: () => _showAddDialog(context),
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
                          ref.read(schoolAdminStaffProvider.notifier).setSearch(v);
                        }
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      ref.read(schoolAdminStaffProvider.notifier).setSearch('');
                    },
                  ),
                  AppSpacing.vGapMd,
                  ListScreenMobileFilterRow(
                    children: [
                      SearchableDropdownFormField<String?>.valueItems(
                        value: state.designationFilter,
                        valueItems: [
                          const MapEntry(null, 'All Roles'),
                          for (final d in _designations)
                            MapEntry<String?, String>(d, d),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) => ref
                            .read(schoolAdminStaffProvider.notifier)
                            .setDesignationFilter(v),
                      ),
                      SearchableDropdownFormField<String?>.valueItems(
                        value: state.isActiveFilter == null
                            ? null
                            : state.isActiveFilter == true
                                ? 'active'
                                : 'inactive',
                        valueItems: const [
                          MapEntry(null, 'All'),
                          MapEntry('active', 'Active'),
                          MapEntry('inactive', 'Inactive'),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) {
                          final bool? filter = v == 'active'
                              ? true
                              : v == 'inactive'
                                  ? false
                                  : null;
                          ref
                              .read(schoolAdminStaffProvider.notifier)
                              .setActiveFilter(filter);
                        },
                      ),
                      ListScreenMobileMoreFiltersButton(
                        onPressed: _clearFilters,
                        showActiveDot: _searchCtrl.text.isNotEmpty ||
                            state.designationFilter != null ||
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

  Widget _buildContent(StaffState state, bool isWide) {
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
              onPressed: () =>
                  ref.read(schoolAdminStaffProvider.notifier).loadStaff(),
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (state.staff.isEmpty) {
      final hasFilters = _searchCtrl.text.isNotEmpty ||
          state.designationFilter != null ||
          state.isActiveFilter != null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined,
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

  static const _columnWidths = [100.0, 200.0, 120.0, 180.0, 90.0, 60.0];
  static const _tableContentWidth =
      100.0 + 200.0 + 120.0 + 180.0 + 90.0 + 60.0 + 32;

  Widget _buildStaffList(StaffState state, bool isWide) {
    if (isWide) {
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
                      'Emp.No',
                      'Name',
                      'Designation',
                      'Email',
                      'Status',
                      'Actions',
                    ],
                    columnWidths: _columnWidths,
                    showSrNo: false,
                    itemCount: state.staff.length,
                    rowBuilder: (i) => _buildDataRow(state.staff[i]),
                  ),
                ),
                _buildPaginationRow(),
              ],
            ),
          ),
        ),
      );
    }

    final hasMore = state.total > 0 &&
        state.staff.length < state.total &&
        state.currentPage < state.totalPages;
    return MobileInfiniteScrollList(
      itemCount: state.staff.length,
      itemBuilder: (ctx, i) => _buildMobileCard(state.staff[i]),
      onLoadMore: () => ref
          .read(schoolAdminStaffProvider.notifier)
          .loadMoreStaff(),
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      loadingLabel: 'Loading more staff…',
    );
  }

  DataRow _buildDataRow(StaffModel s) {
    return DataRow(cells: [
      DataCell(Text(s.employeeNo,
          style: const TextStyle(fontFamily: 'monospace'))),
      DataCell(
        InkWell(
          onTap: () => context.go('/school-admin/staff/${s.id}'),
          child: Text(
            s.fullName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      DataCell(Text(s.designation)),
      DataCell(Text(s.email,
          overflow: TextOverflow.ellipsis, maxLines: 1)),
      DataCell(_ActiveBadge(isActive: s.isActive)),
      DataCell(
        HoverPopupMenu<String>(
          icon: const Icon(Icons.more_vert, size: AppIconSize.md),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            if (v == 'view') context.go('/school-admin/staff/${s.id}');
            if (v == 'edit') _showEditDialog(context, s);
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

  Widget _buildMobileCard(StaffModel s) {
    final initials =
        '${s.firstName.isNotEmpty ? s.firstName[0] : ''}${s.lastName.isNotEmpty ? s.lastName[0] : ''}'
            .toUpperCase();
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/school-admin/staff/${s.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Text(initials.isEmpty ? '?' : initials)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.designation,
                          style: smallMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  HoverPopupMenu<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') _showEditDialog(context, s);
                      if (v == 'delete') _confirmDelete(context, s);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.edit_outlined, size: 20),
                          title: Text(AppStrings.edit),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.error500),
                          title: Text(
                            AppStrings.delete,
                            style: const TextStyle(color: AppColors.error500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    child: Text(
                      s.email,
                      style: smallMuted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final state = ref.watch(schoolAdminStaffProvider);
    return ListPaginationBar(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalEntries: state.total,
      pageSize: state.pageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: _onPageSizeChanged,
      onGoToPage: (page) =>
          ref.read(schoolAdminStaffProvider.notifier).goToPage(page),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => _StaffFormDialog(
        schoolAdminService: ref.read(schoolAdminServiceProvider),
        onSave: (data) async {
          final ok =
              await ref.read(schoolAdminStaffProvider.notifier).createStaff(data);
          if (ok && ctx.mounted) {
            Navigator.of(ctx).pop();
            if (context.mounted) {
              AppToast.showSuccess(context, AppStrings.staffMemberAdded);
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, StaffModel staff) async {
    await showDialog(
      context: context,
      builder: (ctx) => _StaffFormDialog(
        schoolAdminService: ref.read(schoolAdminServiceProvider),
        staff: staff,
        onSave: (data) async {
          final ok = await ref
              .read(schoolAdminStaffProvider.notifier)
              .updateStaff(staff.id, data);
          if (ok && ctx.mounted) {
            Navigator.of(ctx).pop();
            if (context.mounted) {
              AppToast.showSuccess(context, AppStrings.staffMemberUpdated);
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, StaffModel staff) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteStaffQuestion,
      message: 'Remove ${staff.fullName} (${staff.employeeNo})?',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(schoolAdminStaffProvider.notifier).deleteStaff(staff.id);
    if (context.mounted) {
      AppToast.showSuccess(context, AppStrings.staffMemberDeleted);
    }
  }
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
        isActive ? AppStrings.active : 'Inactive',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog({
    required this.schoolAdminService,
    this.staff,
    required this.onSave,
  });
  final dynamic schoolAdminService;
  final StaffModel? staff;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl =
      TextEditingController(text: widget.staff?.firstName ?? '');
  late final _lastNameCtrl =
      TextEditingController(text: widget.staff?.lastName ?? '');
  late final _empNoCtrl =
      TextEditingController(text: widget.staff?.employeeNo ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.staff?.email ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.staff?.phone ?? '');
  late final _qualCtrl =
      TextEditingController(text: widget.staff?.qualification ?? '');
  late final _passwordCtrl = TextEditingController();

  String _gender = 'MALE';
  String _designation = 'TEACHER';
  bool _isActive = true;
  bool _createLogin = false;
  bool _isSaving = false;
  bool _empNoManuallyEdited = false;
  bool? _empNoAvailable;
  bool _empNoChecking = false;
  Timer? _suggestDebounce;
  Timer? _checkDebounce;
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  bool _firstNameHadFocus = false;
  bool _lastNameHadFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _gender = widget.staff!.gender;
      _designation = widget.staff!.designation;
      _isActive = widget.staff!.isActive;
    } else {
      _fetchSuggestedEmployeeNo();
    }
    if (widget.staff != null && widget.staff!.employeeNo.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 600), _checkEmployeeNoAvailability);
    }
    _firstNameCtrl.addListener(_onNameChanged);
    _lastNameCtrl.addListener(_onNameChanged);
    _empNoCtrl.addListener(_onEmpNoChanged);
    _firstNameFocus.addListener(_onFirstNameFocusChanged);
    _lastNameFocus.addListener(_onLastNameFocusChanged);
  }

  void _onFirstNameFocusChanged() {
    final hasFocus = _firstNameFocus.hasFocus;
    if (_firstNameHadFocus && !hasFocus) _refetchSuggestedOnBlur();
    _firstNameHadFocus = hasFocus;
  }

  void _onLastNameFocusChanged() {
    final hasFocus = _lastNameFocus.hasFocus;
    if (_lastNameHadFocus && !hasFocus) _refetchSuggestedOnBlur();
    _lastNameHadFocus = hasFocus;
  }

  void _refetchSuggestedOnBlur() {
    if (widget.staff != null || _empNoManuallyEdited) return;
    _fetchSuggestedEmployeeNo();
  }

  void _onNameChanged() {
    if (widget.staff != null || _empNoManuallyEdited) return;
    _suggestDebounce?.cancel();
    _suggestDebounce = Timer(const Duration(milliseconds: 250), () {
      _fetchSuggestedEmployeeNo();
    });
  }

  void _onEmpNoChanged() {
    _empNoManuallyEdited = true; // User edited (listener removed during programmatic updates)
    _empNoAvailable = null;
    final v = _empNoCtrl.text.trim();
    if (v.isEmpty) {
      _checkDebounce?.cancel();
      return;
    }
    _checkDebounce?.cancel();
    _checkDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkEmployeeNoAvailability();
    });
  }

  Future<void> _fetchSuggestedEmployeeNo() async {
    if (widget.staff != null) return;
    try {
      final service = widget.schoolAdminService as SchoolAdminService;
      final suggested = await service.getSuggestedEmployeeNo(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      if (mounted && !_empNoManuallyEdited) {
        // Temporarily remove listener so programmatic update doesn't set _empNoManuallyEdited
        _empNoCtrl.removeListener(_onEmpNoChanged);
        _empNoCtrl.text = suggested;
        _empNoCtrl.selection = TextSelection.collapsed(offset: suggested.length);
        _empNoCtrl.addListener(_onEmpNoChanged);
        _checkEmployeeNoAvailability();
        setState(() {}); // Ensure UI reflects the new value
      }
    } catch (_) {}
  }

  Future<void> _checkEmployeeNoAvailability() async {
    final v = _empNoCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() => _empNoChecking = true);
    try {
      final service = widget.schoolAdminService as SchoolAdminService;
      final result = await service.checkEmployeeNoAvailability(
        v,
        excludeStaffId: widget.staff?.id,
      );
      if (mounted) {
        setState(() {
          _empNoAvailable = result['available'] == true;
          _empNoChecking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _empNoChecking = false);
    }
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _checkDebounce?.cancel();
    _firstNameCtrl.removeListener(_onNameChanged);
    _lastNameCtrl.removeListener(_onNameChanged);
    _empNoCtrl.removeListener(_onEmpNoChanged);
    _firstNameFocus.removeListener(_onFirstNameFocusChanged);
    _lastNameFocus.removeListener(_onLastNameFocusChanged);
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _empNoCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _qualCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Staff' : 'Add Staff'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: _field('First Name', _firstNameCtrl, focusNode: _firstNameFocus)),
                  AppSpacing.hGapMd,
                  Expanded(child: _field('Last Name', _lastNameCtrl, focusNode: _lastNameFocus)),
                ]),
                AppSpacing.vGapMd,
                _employeeNoField(),
                AppSpacing.vGapMd,
                _field('Email', _emailCtrl),
                AppSpacing.vGapMd,
                _field('Phone / Mobile', _phoneCtrl, required: true, isPhone: true),
                AppSpacing.vGapMd,
                _field('Qualification', _qualCtrl, required: false),
                AppSpacing.vGapMd,
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                      labelText: 'Gender *', border: OutlineInputBorder()),
                  items: ['MALE', 'FEMALE', 'OTHER']
                      .map((g) =>
                          DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                AppSpacing.vGapMd,
                DropdownButtonFormField<String>(
                  initialValue: _designation,
                  decoration: const InputDecoration(
                      labelText: 'Designation *', border: OutlineInputBorder()),
                  items: _designations
                      .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _designation = v!),
                ),
                AppSpacing.vGapMd,
                  SwitchListTile(
                    title: Text(AppStrings.active),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!isEdit) ...[
                  AppSpacing.vGapMd,
                  SwitchListTile(
                    title: Text(AppStrings.createLoginAccount),
                    subtitle: const Text(
                      'Staff can log in with email and password',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _createLogin,
                    onChanged: (v) => setState(() => _createLogin = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_createLogin) ...[
                    AppSpacing.vGapMd,
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (min 8 characters) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: _createLogin
                          ? (v) => (v == null || v.trim().length < 8)
                              ? 'Min 8 characters required'
                              : null
                          : null,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _employeeNoField() {
    final isEdit = widget.staff != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _empNoCtrl,
          decoration: InputDecoration(
            labelText: 'Employee No. *',
            hintText: 'Auto-filled; editable',
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isEdit && !_empNoManuallyEdited)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Regenerate from name',
                    onPressed: () => _fetchSuggestedEmployeeNo(),
                  ),
                if (_empNoChecking)
                  const Padding(
                    padding: AppSpacing.paddingMd,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_empNoAvailable == true)
                  const Icon(Icons.check_circle, color: AppColors.success500, size: 20)
                else if (_empNoAvailable == false)
                  const Icon(Icons.cancel, color: AppColors.error500, size: 20),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        if (_empNoAvailable != null && _empNoCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _empNoAvailable!
                  ? 'Available'
                  : 'Not available (already in use)',
              style: TextStyle(
                fontSize: 12,
                color: _empNoAvailable! ? AppColors.success500 : AppColors.error500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = true, FocusNode? focusNode, bool isPhone = false}) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      keyboardType: isPhone ? TextInputType.phone : null,
      decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder()),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (isPhone && v.replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter valid 10-digit mobile number';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_empNoCtrl.text.trim().isNotEmpty && _empNoAvailable == false) {
      AppToast.showError(context, AppStrings.empNoInUse);
      return;
    }
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final data = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'employeeNo': _empNoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'gender': _gender,
      'designation': _designation,
      'joinDate':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'isActive': _isActive,
      'phone': _phoneCtrl.text.trim(),
      if (_qualCtrl.text.isNotEmpty) 'qualification': _qualCtrl.text.trim(),
      if (widget.staff == null && _createLogin) 'createLogin': true,
      if (widget.staff == null && _createLogin && _passwordCtrl.text.isNotEmpty)
        'password': _passwordCtrl.text,
    };
    await widget.onSave(data);
    if (mounted) setState(() => _isSaving = false);
  }
}
