// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_students_screen.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/student_model.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';

import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../widgets/common/hover_popup_menu.dart';
import '../../../../shared/widgets/list_pagination_bar.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../../../../shared/widgets/list_screen_mobile_toolbar.dart';
import '../../../../shared/widgets/mobile_infinite_scroll.dart';
import '../providers/school_admin_students_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_toast.dart';

class SchoolAdminStudentsScreen extends ConsumerStatefulWidget {
  const SchoolAdminStudentsScreen({super.key});

  @override
  ConsumerState<SchoolAdminStudentsScreen> createState() =>
      _SchoolAdminStudentsScreenState();
}

class _SchoolAdminStudentsScreenState
    extends ConsumerState<SchoolAdminStudentsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  static const _pageSizeOptions = [10, 15, 25, 50];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolAdminStudentsProvider.notifier).loadStudents();
      ref.read(schoolAdminClassesProvider.notifier).loadClasses();
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(schoolAdminStudentsProvider.notifier).setSearch(_searchCtrl.text);
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
    final state = ref.read(schoolAdminStudentsProvider);
    if (page < 1 || page > state.totalPages) return;
    ref.read(schoolAdminStudentsProvider.notifier).goToPage(page);
  }

  void _onPageSizeChanged(int? value) {
    if (value == null) return;
    ref.read(schoolAdminStudentsProvider.notifier).setPageSize(value);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    final notifier = ref.read(schoolAdminStudentsProvider.notifier);
    notifier.setClassFilter(null);
    notifier.setStatusFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolAdminStudentsProvider);
    final classesState = ref.watch(schoolAdminClassesProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.tablet;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(schoolAdminStudentsProvider.notifier).loadStudents(refresh: true);
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
                        AppStrings.students,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Manage student enrollment and records',
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
                        onPressed: () => _showAddDialog(context, classesState.classes),
                        icon: const Icon(Icons.add, size: AppIconSize.md),
                        label: Text(AppStrings.addStudent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Wide filter card — same max-width as table ──────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _tableContentWidth + 48),
                child: Padding(
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
                                hintText: AppStrings.searchByNameAdmNo,
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
                              value: state.classFilter,
                              valueItems: [
                                const MapEntry(null, 'All Classes'),
                                ...classesState.classes.map((c) =>
                                    MapEntry<String?, String>(c.id, c.name)),
                              ],
                              decoration: InputDecoration(
                                labelText: AppStrings.classLabel,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) => ref
                                  .read(schoolAdminStudentsProvider.notifier)
                                  .setClassFilter(v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 140,
                            child: SearchableDropdownFormField<String?>.valueItems(
                              value: state.statusFilter,
                              valueItems: const [
                                MapEntry(null, 'All Status'),
                                MapEntry('ACTIVE', 'Active'),
                                MapEntry('INACTIVE', 'Inactive'),
                                MapEntry('TRANSFERRED', 'Transferred'),
                              ],
                              decoration: InputDecoration(
                                labelText: AppStrings.status,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) => ref
                                  .read(schoolAdminStudentsProvider.notifier)
                                  .setStatusFilter(v),
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
              ),
            ),
            AppSpacing.vGapLg,
          ] else ...[
            // ── Narrow header ──────────────────────────────────────────────
            ListScreenMobileHeader(
              title: AppStrings.students,
              primaryLabel: AppStrings.addStudent,
              onPrimary: () => _showAddDialog(context, classesState.classes),
              onExport: () {},
            ),
            // ── Narrow filter strip ────────────────────────────────────────
            ListScreenMobileFilterStrip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListScreenMobilePillSearchField(
                    controller: _searchCtrl,
                    hintText: AppStrings.searchByNameAdmNo,
                    onChanged: (v) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                        if (mounted) {
                          ref
                              .read(schoolAdminStudentsProvider.notifier)
                              .setSearch(v);
                        }
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      ref.read(schoolAdminStudentsProvider.notifier).setSearch('');
                    },
                  ),
                  AppSpacing.vGapMd,
                  ListScreenMobileFilterRow(
                    children: [
                      SearchableDropdownFormField<String?>.valueItems(
                        value: state.classFilter,
                        valueItems: [
                          const MapEntry(null, 'All Classes'),
                          ...classesState.classes.map((c) =>
                              MapEntry<String?, String>(c.id, c.name)),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) => ref
                            .read(schoolAdminStudentsProvider.notifier)
                            .setClassFilter(v),
                      ),
                      SearchableDropdownFormField<String?>.valueItems(
                        value: state.statusFilter,
                        valueItems: const [
                          MapEntry(null, 'All Status'),
                          MapEntry('ACTIVE', 'Active'),
                          MapEntry('INACTIVE', 'Inactive'),
                          MapEntry('TRANSFERRED', 'Transferred'),
                        ],
                        decoration: listScreenMobileFilterFieldDecoration(context),
                        onChanged: (v) => ref
                            .read(schoolAdminStudentsProvider.notifier)
                            .setStatusFilter(v),
                      ),
                      ListScreenMobileMoreFiltersButton(
                        onPressed: _clearFilters,
                        showActiveDot: _searchCtrl.text.isNotEmpty ||
                            state.classFilter != null ||
                            state.statusFilter != null,
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
              child: _buildContent(state, classesState, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    StudentsState state,
    dynamic classesState,
    bool isWide,
  ) {
    if (state.isLoading && state.students.isEmpty) {
      return AppLoaderScreen();
    }

    if (state.errorMessage != null && state.students.isEmpty) {
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
              onPressed: () => ref
                  .read(schoolAdminStudentsProvider.notifier)
                  .loadStudents(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (state.students.isEmpty) {
      final hasFilters = _searchCtrl.text.isNotEmpty ||
          state.classFilter != null ||
          state.statusFilter != null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: AppIconSize.xl4,
                color: Theme.of(context).colorScheme.outline),
            AppSpacing.vGapLg,
            Text(
              AppStrings.noStudentsFound,
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

    return _buildStudentList(state, classesState, isWide);
  }

  static const _columnWidths = [100.0, 200.0, 140.0, 100.0, 140.0, 60.0];
  static const _tableContentWidth =
      100.0 + 200.0 + 140.0 + 100.0 + 140.0 + 60.0 + 32;

  Widget _buildStudentList(
    StudentsState state,
    dynamic classesState,
    bool isWide,
  ) {
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
                  'Adm.No',
                  'Name',
                  'Class',
                  'Status',
                  'Parent',
                  'Actions',
                ],
                columnWidths: _columnWidths,
                showSrNo: false,
                itemCount: state.students.length,
                rowBuilder: (i) => _buildDataRow(state.students[i], classesState),
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
        state.students.length < state.total &&
        state.currentPage < state.totalPages;
    return MobileInfiniteScrollList(
      itemCount: state.students.length,
      itemBuilder: (context, i) =>
          _buildMobileCard(state.students[i], classesState),
      hasMore: hasMore,
      isLoadingMore: state.isLoadingMore,
      onLoadMore: () =>
          ref.read(schoolAdminStudentsProvider.notifier).loadMoreStudents(),
      loadingLabel: 'Loading more students…',
    );
  }

  DataRow _buildDataRow(StudentModel s, dynamic classesState) {
    final cs = Theme.of(context).colorScheme;
    return DataRow(cells: [
      DataCell(Text(s.admissionNo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'))),
      DataCell(
        InkWell(
          onTap: () => context.go('/school-admin/students/${s.id}'),
          child: Text(
            s.fullName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: cs.primary,
            ),
          ),
        ),
      ),
      DataCell(Text(
          '${s.className ?? '-'} ${s.sectionName ?? ''}'.trim())),
      DataCell(_StatusBadge(status: s.status)),
      DataCell(Text(s.parentName ?? '-',
          overflow: TextOverflow.ellipsis, maxLines: 1)),
      DataCell(
        HoverPopupMenu<String>(
          icon: const Icon(Icons.more_vert, size: AppIconSize.md),
          padding: EdgeInsets.zero,
          onSelected: (v) {
            if (v == 'view') context.go('/school-admin/students/${s.id}');
            if (v == 'edit') _showEditDialog(context, s, classesState.classes);
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

  Widget _buildMobileCard(StudentModel s, dynamic classesState) {
    final cs = Theme.of(context).colorScheme;
    final smallMuted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.go('/school-admin/students/${s.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      s.fullName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  HoverPopupMenu<String>(
                    icon: const Icon(Icons.more_vert, size: AppIconSize.lg),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'view') context.go('/school-admin/students/${s.id}');
                      if (v == 'edit') _showEditDialog(context, s, classesState.classes);
                      if (v == 'delete') _confirmDelete(context, s);
                    },
                    itemBuilder: (ctx) => [
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
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '${s.admissionNo} · ${s.className ?? '-'} ${s.sectionName ?? ''}'.trim(),
                style: smallMuted,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xs),
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
                      s.parentName ?? '-',
                      style: smallMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  _StatusBadge(status: s.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    final state = ref.watch(schoolAdminStudentsProvider);
    return ListPaginationBar(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalEntries: state.total,
      pageSize: state.pageSize,
      pageSizeOptions: _pageSizeOptions,
      onPageSizeChanged: _onPageSizeChanged,
      onGoToPage: _goToPage,
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, List<SchoolClassModel> classes) async {
    final academicYears = await ref
        .read(schoolAdminServiceProvider)
        .getAcademicYears();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _StudentFormDialog(
        classes: classes,
        academicYears: academicYears,
        service: ref.read(schoolAdminServiceProvider),
        onSave: (data) async {
          final ok = await ref
              .read(schoolAdminStudentsProvider.notifier)
              .createStudent(data);
          if (ok && ctx.mounted) {
            Navigator.of(ctx).pop();
            if (context.mounted) {
              AppToast.showSuccess(context, AppStrings.studentAddedSuccess);
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, StudentModel student,
      List<SchoolClassModel> classes) async {
    final academicYears = await ref
        .read(schoolAdminServiceProvider)
        .getAcademicYears();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _StudentFormDialog(
        student: student,
        classes: classes,
        academicYears: academicYears,
        service: ref.read(schoolAdminServiceProvider),
        onSave: (data) async {
          final ok = await ref
              .read(schoolAdminStudentsProvider.notifier)
              .updateStudent(student.id, data);
          if (ok && ctx.mounted) {
            Navigator.of(ctx).pop();
            if (context.mounted) {
              AppToast.showSuccess(context, AppStrings.studentUpdated);
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, StudentModel student) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.deleteStudentQuestion,
      message: 'Remove ${student.fullName} (${student.admissionNo})? This cannot be undone.',
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(schoolAdminStudentsProvider.notifier)
        .deleteStudent(student.id);
    if (context.mounted) {
      AppToast.showSuccess(context, AppStrings.studentDeleted);
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => AppColors.success500,
      'INACTIVE' => AppColors.neutral400,
      'TRANSFERRED' => AppColors.warning500,
      _ => AppColors.neutral400,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

// ── Student Form Dialog ────────────────────────────────────────────────────────

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({
    this.student,
    required this.classes,
    this.academicYears = const [],
    required this.service,
    required this.onSave,
  });

  final StudentModel? student;
  final List<SchoolClassModel> classes;
  final List<Map<String, dynamic>> academicYears;
  final SchoolAdminService service;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl = TextEditingController(
      text: widget.student?.firstName ?? '');
  late final _lastNameCtrl = TextEditingController(
      text: widget.student?.lastName ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.student?.phone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.student?.email ?? '');
  late final _parentNameCtrl =
      TextEditingController(text: widget.student?.parentName ?? '');
  late final _parentPhoneCtrl =
      TextEditingController(text: widget.student?.parentPhone ?? '');

  String _gender = 'MALE';
  String _status = 'ACTIVE';
  DateTime _dob = DateTime(2010);
  DateTime _admissionDate = DateTime.now();
  String? _classId;
  String? _sectionId;
  String? _academicYearId;
  bool _isSaving = false;
  List<SectionSummary>? _fetchedSections;
  bool _loadingSections = false;

  List<SectionSummary> get _sectionsForSelectedClass {
    if (_classId == null) return [];
    for (final c in widget.classes) {
      if (c.id == _classId) return c.sections;
    }
    return [];
  }

  List<SectionSummary> get _effectiveSections {
    final fromClass = _sectionsForSelectedClass;
    if (fromClass.isNotEmpty) return fromClass;
    return _fetchedSections ?? [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _gender = widget.student!.gender;
      _status = widget.student!.status;
      _dob = widget.student!.dateOfBirth;
      _admissionDate = widget.student!.admissionDate;
      _classId = widget.student!.classId;
      _sectionId = widget.student!.sectionId;
    }
    if (widget.academicYears.isNotEmpty && _academicYearId == null) {
      _academicYearId = widget.academicYears.first['id'] as String?;
    }
    if (_classId != null && _sectionsForSelectedClass.isEmpty) {
      _loadSectionsForClass(_classId!);
    }
  }

  Future<void> _onClassChanged(String? newClassId) async {
    setState(() {
      _classId = newClassId;
      _sectionId = null;
      _fetchedSections = null;
    });
    if (newClassId != null && _sectionsForSelectedClass.isEmpty) {
      await _loadSectionsForClass(newClassId);
    }
  }

  Future<void> _loadSectionsForClass(String classId) async {
    setState(() => _loadingSections = true);
    try {
      final sections = await widget.service.getSections(classId);
      if (mounted) {
        final summaries = sections
            .map((s) => SectionSummary(
                  id: s.id,
                  name: s.name,
                  studentCount: 0,
                  isActive: s.isActive,
                ))
            .toList();
        setState(() {
          _fetchedSections = summaries;
          _loadingSections = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fetchedSections = [];
          _loadingSections = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Student' : 'Add Student'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: _field('First Name', _firstNameCtrl)),
                  AppSpacing.hGapMd,
                  Expanded(child: _field('Last Name', _lastNameCtrl)),
                ]),
                if (isEdit) ...[
                  AppSpacing.vGapMd,
                  _readOnlyField('Admission No.', widget.student!.admissionNo),
                ],
                AppSpacing.vGapMd,
                _dateField(
                  label: AppStrings.dateOfBirth,
                  value: _dob,
                  onChanged: (v) => setState(() => _dob = v ?? _dob),
                ),
                AppSpacing.vGapMd,
                _dateField(
                  label: AppStrings.admissionDate,
                  value: _admissionDate,
                  onChanged: (v) => setState(() => _admissionDate = v ?? _admissionDate),
                ),
                AppSpacing.vGapMd,
                _dropdownField<String>(
                  label: AppStrings.gender,
                  selected: _gender,
                  items: const ['MALE', 'FEMALE', 'OTHER'],
                  itemLabel: (g) => g,
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                AppSpacing.vGapMd,
                _dropdownFieldNullable<String>(
                  label: 'Class',
                  selected: _classId,
                  items: widget.classes.map((c) => c.id).toList(),
                  itemLabel: (id) => widget.classes
                      .firstWhere((c) => c.id == id,
                          orElse: () => widget.classes.first)
                      .name,
                  noneLabel: 'No Class',
                  onChanged: (v) => _onClassChanged(v),
                ),
                AppSpacing.vGapMd,
                _classId == null
                    ? _disabledSectionField()
                    : _loadingSections
                        ? const Padding(
                            padding: AppSpacing.paddingVMd,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _dropdownFieldNullable<String>(
                            label: AppStrings.section,
                            selected: _effectiveSections.any((s) => s.id == _sectionId)
                                ? _sectionId
                                : null,
                            items: _effectiveSections.map((s) => s.id).toList(),
                            itemLabel: (id) => _effectiveSections
                                .firstWhere((s) => s.id == id,
                                    orElse: () => _effectiveSections.first)
                                .name,
                            noneLabel: 'No Section',
                            onChanged: (v) => setState(() => _sectionId = v),
                          ),
                if (widget.academicYears.isNotEmpty) ...[
                  AppSpacing.vGapMd,
                  _dropdownFieldNullable<String>(
                    label: AppStrings.academicYear,
                    selected: _academicYearId,
                    items: widget.academicYears
                        .map((ay) => ay['id'] as String?)
                        .whereType<String>()
                        .toList(),
                    itemLabel: (id) => widget.academicYears
                            .firstWhere(
                              (ay) => ay['id'] == id,
                              orElse: () => {'yearName': ''},
                            )['yearName']
                        ?.toString() ??
                        id,
                    noneLabel: 'No Academic Year',
                    onChanged: (v) => setState(() => _academicYearId = v),
                  ),
                ],
                AppSpacing.vGapMd,
                _field('Phone', _phoneCtrl, required: false),
                AppSpacing.vGapMd,
                _field('Email', _emailCtrl, required: false),
                AppSpacing.vGapMd,
                _field('Parent Name', _parentNameCtrl, required: false),
                AppSpacing.vGapMd,
                _field('Parent Phone', _parentPhoneCtrl, required: false),
                AppSpacing.vGapMd,
                _dropdownField<String>(
                  label: AppStrings.status,
                  selected: _status,
                  items: const ['ACTIVE', 'INACTIVE', 'TRANSFERRED'],
                  itemLabel: (s) => s,
                  onChanged: (v) => setState(() => _status = v!),
                ),
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

  Widget _readOnlyField(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _disabledSectionField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppStrings.section,
        hintText: AppStrings.selectClassFirst,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      child: Text(
        AppStrings.selectClassFirst,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = true}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T selected,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      initialValue: selected,
      items: items
          .map((i) => DropdownMenuItem<T>(value: i, child: Text(itemLabel(i))))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _dropdownFieldNullable<T>({
    required String label,
    required T? selected,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String noneLabel = 'None',
  }) {
    return DropdownButtonFormField<T?>(
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      initialValue: selected,
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(noneLabel)),
        ...items.map(
            (i) => DropdownMenuItem<T?>(value: i, child: Text(itemLabel(i)))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _dateField({
    required String label,
    required DateTime value,
    required void Function(DateTime?) onChanged,
  }) {
    final fmt = '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1990),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: AppIconSize.md),
        ),
        child: Text(fmt),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final data = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'gender': _gender,
      'dateOfBirth':
          '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}',
      'admissionDate':
          '${_admissionDate.year}-${_admissionDate.month.toString().padLeft(2, '0')}-${_admissionDate.day.toString().padLeft(2, '0')}',
      'status': _status,
      if (_classId != null) 'classId': _classId,
      if (_sectionId != null) 'sectionId': _sectionId,
      if (_academicYearId != null) 'academicYearId': _academicYearId,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_parentNameCtrl.text.isNotEmpty)
        'parentName': _parentNameCtrl.text.trim(),
      if (_parentPhoneCtrl.text.isNotEmpty)
        'parentPhone': _parentPhoneCtrl.text.trim(),
    };
    await widget.onSave(data);
    if (mounted) setState(() => _isSaving = false);
  }
}
