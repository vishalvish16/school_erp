// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_students_screen.dart
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/school_admin/student_model.dart';
import '../../../../models/school_admin/school_class_model.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../../../../widgets/common/shimmer_loading_widget.dart';
import '../../../../widgets/common/searchable_dropdown_form_field.dart';
import '../../../../shared/widgets/list_table_view.dart';
import '../providers/school_admin_students_provider.dart';
import '../providers/school_admin_classes_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

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
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 768;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(schoolAdminStudentsProvider.notifier).loadStudents(refresh: true);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                      'Students',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          _showAddDialog(context, classesState.classes),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(AppStrings.addStudent),
                    ),
                  ],
                ),
              ),

              // Search + Filters
              Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
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
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: AppStrings.searchByNameAdmNo,
                                prefixIcon:
                                    const Icon(Icons.search, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
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
                            child: SearchableDropdownFormField<String?>
                                .valueItems(
                              value: state.classFilter,
                              valueItems: [
                                const MapEntry(null, 'All Classes'),
                                ...classesState.classes.map((c) =>
                                    MapEntry<String?, String>(c.id, c.name)),
                              ],
                              decoration: InputDecoration(
                                labelText: AppStrings.classLabel,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                ref
                                    .read(
                                        schoolAdminStudentsProvider.notifier)
                                    .setClassFilter(v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: SearchableDropdownFormField<String?>
                                .valueItems(
                              value: state.statusFilter,
                              valueItems: const [
                                MapEntry(null, 'All Status'),
                                MapEntry('ACTIVE', 'Active'),
                                MapEntry('INACTIVE', 'Inactive'),
                                MapEntry('TRANSFERRED', 'Transferred'),
                              ],
                              decoration: InputDecoration(
                                labelText: AppStrings.status,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                ref
                                    .read(
                                        schoolAdminStudentsProvider.notifier)
                                    .setStatusFilter(v);
                              },
                            ),
                          ),
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

              AppSpacing.vGapLg,

              // Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isNarrow ? 16 : 24,
                      0,
                      isNarrow ? 16 : 24,
                      isNarrow ? 16 : 24,
                    ),
                    child: _buildContent(state, classesState, isWide),
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
    StudentsState state,
    dynamic classesState,
    bool isWide,
  ) {
    if (state.isLoading && state.students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: ShimmerListLoadingWidget(itemCount: 8),
      );
    }

    if (state.errorMessage != null && state.students.isEmpty) {
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
              Text(state.errorMessage!, textAlign: TextAlign.center),
              AppSpacing.vGapLg,
              FilledButton(
                onPressed: () => ref
                    .read(schoolAdminStudentsProvider.notifier)
                    .loadStudents(refresh: true),
                child: Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.students.isEmpty) {
      final hasFilters = _searchCtrl.text.isNotEmpty ||
          state.classFilter != null ||
          state.statusFilter != null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              AppSpacing.vGapLg,
              Text(
                _searchCtrl.text.isNotEmpty
                    ? "No results for '${_searchCtrl.text}'"
                    : 'No students found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (hasFilters) ...[
                AppSpacing.vGapSm,
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(AppStrings.clearFilters),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildStudentList(state, classesState, isWide);
  }

  static const _columnWidths = [100.0, 200.0, 140.0, 100.0, 140.0, 60.0];

  Widget _buildStudentList(
    StudentsState state,
    dynamic classesState,
    bool isWide,
  ) {
    if (isWide) {
      return Card(
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
      );
    }

    // Mobile cards
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children:
                state.students.map((s) => _buildMobileCard(s, classesState)).toList(),
          ),
        ),
        if (state.students.isNotEmpty) Card(child: _buildPaginationRow()),
      ],
    );
  }

  DataRow _buildDataRow(StudentModel s, dynamic classesState) {
    final cs = Theme.of(context).colorScheme;
    return DataRow(cells: [
      DataCell(Text(s.admissionNo,
          style: const TextStyle(fontFamily: 'monospace'))),
      DataCell(
        InkWell(
          onTap: () => context.go('/school-admin/students/${s.id}'),
          child: Text(
            s.fullName,
            style: TextStyle(
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
        PopupMenuButton<String>(
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'view',
                child: ListTile(
                    dense: true,
                    leading: Icon(Icons.visibility),
                    title: Text(AppStrings.view))),
            PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.edit),
                    title: Text(AppStrings.edit))),
            PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.delete, color: AppColors.error500),
                    title: Text(AppStrings.delete,
                        style: const TextStyle(color: AppColors.error500)))),
          ],
          onSelected: (v) {
            if (v == 'view') {
              context.go('/school-admin/students/${s.id}');
            }
            if (v == 'edit') {
              _showEditDialog(context, s, classesState.classes);
            }
            if (v == 'delete') _confirmDelete(context, s);
          },
          child: const Icon(Icons.more_vert, size: 18),
        ),
      ),
    ]);
  }

  Widget _buildMobileCard(StudentModel s, dynamic classesState) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/school-admin/students/${s.id}'),
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      s.fullName.isNotEmpty
                          ? s.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${s.admissionNo} · ${s.className ?? '-'} ${s.sectionName ?? ''}'.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: s.status),
                ],
              ),
              AppSpacing.vGapSm,
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () =>
                        _showEditDialog(context, s, classesState.classes),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: AppColors.error500),
                    onPressed: () => _confirmDelete(context, s),
                    tooltip: 'Delete',
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
    final state = ref.watch(schoolAdminStudentsProvider);
    final cs = Theme.of(context).colorScheme;
    final page = state.currentPage;
    final totalPages = state.totalPages;
    final total = state.total;
    final pageSize = state.pageSize;
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = (page * pageSize).clamp(0, total);

    Widget pageButton(String label, {required int page, bool active = false}) {
      final enabled =
          page != state.currentPage && page >= 1 && page <= totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? () => _goToPage(page) : null,
            child: Container(
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
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
      int rangeStart = (page - (maxVisible ~/ 2)).clamp(1, totalPages);
      int rangeEnd = (rangeStart + maxVisible - 1).clamp(1, totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart = (rangeEnd - maxVisible + 1).clamp(1, totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(pageButton('$i', page: i, active: i == page));
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
          Text('Showing $start to $end of $total entries',
              style: mutedStyle),
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
                    value: pageSize,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: textStyle.copyWith(color: cs.onSurface),
                    items: _pageSizeOptions
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n')))
                        .toList(),
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
              pageButton('Previous', page: page - 1),
              ...pageNumbers(),
              pageButton('Next', page: page + 1),
              pageButton('Last', page: totalPages),
            ],
          ),
        ],
      ),
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
              AppSnackbar.success(context, AppStrings.studentAddedSuccess);
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
              AppSnackbar.success(context, AppStrings.studentUpdated);
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
      AppSnackbar.success(context, AppStrings.studentDeleted);
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
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
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
          style: FilledButton.styleFrom(backgroundColor: _accent),
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
      value: selected,
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
      value: selected,
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
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
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
