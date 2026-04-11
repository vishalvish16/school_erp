// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_student_detail_screen.dart
// PURPOSE: Full tabbed student report — Profile, Attendance, Fees, Progress,
//          Notices — plus Send Notice FAB. Reusable by Staff portal via basePath.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/student_model.dart';
import '../../../../models/school_admin/student_report_model.dart';
import '../../../../models/school_admin/student_notice_model.dart';
import '../../../../models/school_admin/parent_link_model.dart';
import '../../../../models/school_admin/parent_search_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/app_feedback.dart';

// =============================================================================
// SCREEN
// =============================================================================

class SchoolAdminStudentDetailScreen extends ConsumerStatefulWidget {
  const SchoolAdminStudentDetailScreen({
    super.key,
    required this.studentId,
    this.basePath = '/api/school/students',
    this.backPath = '/school-admin/students',
  });

  final String studentId;
  final String basePath;
  final String backPath;

  @override
  ConsumerState<SchoolAdminStudentDetailScreen> createState() =>
      _SchoolAdminStudentDetailScreenState();
}

class _SchoolAdminStudentDetailScreenState
    extends ConsumerState<SchoolAdminStudentDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // ── Report state ──────────────────────────────────────────────────────────
  StudentReportModel? _report;
  bool _reportLoading = true;
  String? _reportError;

  // ── Attendance state ──────────────────────────────────────────────────────
  DateTime _currentMonth = DateTime.now();
  Map<String, dynamic>? _attendanceData;
  bool _attendanceLoading = false;
  String? _attendanceError;

  // ── Fees state ────────────────────────────────────────────────────────────
  Map<String, dynamic>? _feesData;
  List<Map<String, dynamic>> _payments = [];
  bool _feesLoading = false;
  String? _feesError;

  // ── Notices state ─────────────────────────────────────────────────────────
  List<StudentNoticeModel> _notices = [];
  bool _noticesLoading = false;
  String? _noticesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        if (_attendanceData == null && !_attendanceLoading) _loadAttendance();
      case 2:
        if (_feesData == null && !_feesLoading) _loadFees();
      case 4:
        if (_notices.isEmpty && !_noticesLoading) _loadNotices();
    }
  }

  SchoolAdminService get _svc => ref.read(schoolAdminServiceProvider);

  // ── Loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadReport() async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      final r = await _svc.getStudentReport(
        widget.studentId,
        basePath: widget.basePath,
      );
      if (mounted) setState(() { _report = r; _reportLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportError = e.toString().replaceAll('Exception: ', '');
          _reportLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
    });
    try {
      final month =
          '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
      final data = await _svc.getStudentAttendance(
        widget.studentId,
        month: month,
        basePath: widget.basePath,
      );
      if (mounted) {
        setState(() { _attendanceData = data; _attendanceLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attendanceError = e.toString().replaceAll('Exception: ', '');
          _attendanceLoading = false;
        });
      }
    }
  }

  Future<void> _loadFees() async {
    setState(() {
      _feesLoading = true;
      _feesError = null;
    });
    try {
      final data = await _svc.getStudentFeesReport(
        widget.studentId,
        basePath: widget.basePath,
      );
      if (mounted) {
        final rawPayments = data['payments'] as List? ?? [];
        setState(() {
          _feesData = data;
          _payments = rawPayments
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _feesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feesError = e.toString().replaceAll('Exception: ', '');
          _feesLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotices() async {
    setState(() {
      _noticesLoading = true;
      _noticesError = null;
    });
    try {
      final data = await _svc.getStudentNotices(
        widget.studentId,
        basePath: widget.basePath,
      );
      if (mounted) {
        final raw = data['notices'] as List? ?? [];
        setState(() {
          _notices = raw
              .map((e) => StudentNoticeModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _noticesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _noticesError = e.toString().replaceAll('Exception: ', '');
          _noticesLoading = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(widget.backPath),
        ),
        title: Text(
          AppStrings.studentReportTitle,
          style: AppTextStyles.h5(color: scheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: _refreshAll,
            icon: Icon(Icons.refresh, size: AppIconSize.lg),
            tooltip: AppStrings.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTextStyles.caption(),
          unselectedLabelStyle: AppTextStyles.caption(),
          tabs: const [
            Tab(icon: Icon(Icons.person, size: AppIconSize.md), text: AppStrings.tabProfile),
            Tab(icon: Icon(Icons.fact_check, size: AppIconSize.md), text: AppStrings.tabAttendance),
            Tab(icon: Icon(Icons.payments, size: AppIconSize.md), text: AppStrings.tabFees),
            Tab(icon: Icon(Icons.bar_chart, size: AppIconSize.md), text: AppStrings.tabProgress),
            Tab(icon: Icon(Icons.campaign, size: AppIconSize.md), text: AppStrings.tabNotices),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendNoticeSheet(context),
        icon: Icon(Icons.message, size: AppIconSize.md),
        label: Text(AppStrings.sendNotice),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(scheme),
          _buildAttendanceTab(scheme),
          _buildFeesTab(scheme),
          _buildProgressTab(scheme),
          _buildNoticesTab(scheme),
        ],
      ),
    );
  }

  void _refreshAll() {
    _loadReport();
    if (_tabController.index == 1) _loadAttendance();
    if (_tabController.index == 2) _loadFees();
    if (_tabController.index == 4) _loadNotices();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab(ColorScheme scheme) {
    if (_reportLoading) {
      return AppLoaderScreen();
    }
    if (_reportError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xl3, color: scheme.error),
            AppSpacing.vGapLg,
            Text(_reportError!, style: AppTextStyles.body(color: scheme.onSurfaceVariant)),
            AppSpacing.vGapLg,
            FilledButton(
              onPressed: _loadReport,
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    final report = _report;
    if (report == null) return const SizedBox.shrink();

    final student = report.student;
    final stats = report.stats;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Student header card ─────────────────────────────────────
              _StudentHeaderCard(student: student),
              AppSpacing.vGapLg,

              // ── Stats summary ───────────────────────────────────────────
              _StatsSummary(stats: stats),
              AppSpacing.vGapLg,

              // ── Personal Info ───────────────────────────────────────────
              _InfoCard(
                title: AppStrings.personalInformation,
                icon: Icons.person,
                fields: {
                  AppStrings.gender: student.gender,
                  AppStrings.dateOfBirth: _formatDate(student.dateOfBirth),
                  AppStrings.bloodGroup: student.bloodGroup ?? AppStrings.dash,
                  AppStrings.phone: student.phone ?? AppStrings.dash,
                  AppStrings.email: student.email ?? AppStrings.dash,
                  AppStrings.address: student.address ?? AppStrings.dash,
                },
              ),
              AppSpacing.vGapMd,

              // ── Academic Info ───────────────────────────────────────────
              _InfoCard(
                title: AppStrings.academicInformation,
                icon: Icons.school,
                fields: {
                  AppStrings.admissionNo: student.admissionNo,
                  AppStrings.admissionDate: _formatDate(student.admissionDate),
                  AppStrings.className: student.className ?? AppStrings.dash,
                  AppStrings.section: student.sectionName ?? AppStrings.dash,
                  AppStrings.rollNo: student.rollNo?.toString() ?? AppStrings.dash,
                  AppStrings.status: student.status,
                },
              ),
              AppSpacing.vGapMd,

              // ── Parent Info ─────────────────────────────────────────────
              _InfoCard(
                title: AppStrings.parentGuardian,
                icon: Icons.family_restroom,
                fields: {
                  AppStrings.nameLabel: student.parentName ?? AppStrings.dash,
                  AppStrings.phone: student.parentPhone ?? AppStrings.dash,
                  AppStrings.email: student.parentEmail ?? AppStrings.dash,
                  AppStrings.relationLabel: student.parentRelation ?? AppStrings.dash,
                },
              ),
              AppSpacing.vGapMd,

              // ── Portal login card ───────────────────────────────────────
              _PortalLoginCard(
                student: student,
                onRefresh: _loadReport,
              ),
              AppSpacing.vGapMd,

              // ── Parents section ─────────────────────────────────────────
              _ParentsSection(studentId: widget.studentId),
              AppSpacing.vGapXl,
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAttendanceTab(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Month picker ────────────────────────────────────────────
              _MonthPicker(
                currentMonth: _currentMonth,
                onPrevious: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                  _loadAttendance();
                },
                onNext: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                  _loadAttendance();
                },
              ),
              AppSpacing.vGapLg,

              if (_attendanceLoading)
                AppLoaderScreen()
              else if (_attendanceError != null)
                AppFeedback.errorBanner(
                  _attendanceError!,
                  onRetry: _loadAttendance,
                )
              else if (_attendanceData != null) ...[
                // ── Summary chips ───────────────────────────────────────
                _AttendanceSummaryChips(
                  summary: _attendanceData!['summary'] as Map<String, dynamic>? ?? {},
                ),
                AppSpacing.vGapLg,

                // ── Calendar grid ───────────────────────────────────────
                _AttendanceCalendar(
                  month: _currentMonth,
                  records: (_attendanceData!['records'] as List? ?? [])
                      .cast<Map<String, dynamic>>(),
                ),
              ] else
                Center(
                  child: Text(
                    AppStrings.noAttendanceRecords,
                    style: AppTextStyles.body(color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — FEES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFeesTab(ColorScheme scheme) {
    if (_feesLoading) {
      return AppLoaderScreen();
    }
    if (_feesError != null) {
      return Center(
        child: AppFeedback.errorBanner(_feesError!, onRetry: _loadFees),
      );
    }

    final summary = _feesData?['summary'] as Map<String, dynamic>? ?? {};
    final totalPaid = (summary['totalPaid'] as num?)?.toDouble() ?? 0.0;
    final paymentsCount = (summary['paymentsCount'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary card ──────────────────────────────────────────
              Card(
                shape: AppRadius.cardShape,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: _FeeSummaryItem(
                          label: AppStrings.totalFeesPaid,
                          value: '${AppStrings.rupeesSymbol}${totalPaid.toStringAsFixed(0)}',
                          color: AppColors.success600,
                        ),
                      ),
                      Expanded(
                        child: _FeeSummaryItem(
                          label: AppStrings.reportPaymentsCount,
                          value: paymentsCount.toString(),
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGapLg,

              // ── Payment list ──────────────────────────────────────────
              Text(
                AppStrings.paymentHistory,
                style: AppTextStyles.h6(color: scheme.onSurface),
              ),
              AppSpacing.vGapMd,

              if (_payments.isEmpty)
                Center(
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Text(
                      AppStrings.noPaymentsRecorded,
                      style: AppTextStyles.body(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ..._payments.map((p) => _PaymentTile(payment: p)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — PROGRESS (placeholder)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressTab(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: AppIconSize.xl4,
              color: scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled),
            ),
            AppSpacing.vGapLg,
            Text(
              AppStrings.progressPlaceholder,
              style: AppTextStyles.body(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5 — NOTICES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNoticesTab(ColorScheme scheme) {
    if (_noticesLoading) {
      return AppLoaderScreen();
    }
    if (_noticesError != null) {
      return Center(
        child: AppFeedback.errorBanner(_noticesError!, onRetry: _loadNotices),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_notices.isEmpty)
                Center(
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Column(
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: AppIconSize.xl3,
                          color: scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled),
                        ),
                        AppSpacing.vGapMd,
                        Text(
                          AppStrings.noNoticesSent,
                          style: AppTextStyles.body(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._notices.map((n) => _NoticeTile(notice: n)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Send Notice Sheet ─────────────────────────────────────────────────────

  void _showSendNoticeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppRadius.bottomSheetShape,
      builder: (_) => _SendNoticeSheet(
        studentId: widget.studentId,
        basePath: widget.basePath,
        onSent: () {
          _loadNotices();
          _loadReport();
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// =============================================================================
// STUDENT HEADER CARD
// =============================================================================

class _StudentHeaderCard extends StatelessWidget {
  const _StudentHeaderCard({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: AppSpacing.xl2,
              backgroundColor: AppColors.success500.withValues(alpha: AppOpacity.focus),
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? Text(
                      '${student.firstName.isNotEmpty ? student.firstName[0] : ''}${student.lastName.isNotEmpty ? student.lastName[0] : ''}',
                      style: AppTextStyles.h3(color: AppColors.success500),
                    )
                  : null,
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: AppTextStyles.h5(color: scheme.onSurface),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    student.admissionNo,
                    style: AppTextStyles.code(color: scheme.onSurfaceVariant),
                  ),
                  AppSpacing.vGapSm,
                  Row(
                    children: [
                      if (student.className != null) ...[
                        AppFeedback.statusChip(
                          '${student.className} ${student.sectionName ?? ''}'.trim(),
                        ),
                        AppSpacing.hGapSm,
                      ],
                      AppFeedback.statusChip(student.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STATS SUMMARY
// =============================================================================

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});
  final StudentReportStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _StatCard(
          icon: Icons.fact_check,
          label: AppStrings.attendancePercentage,
          value: '${stats.attendanceThisMonth.percentage.toStringAsFixed(1)}%',
          color: AppColors.primary600,
        ),
        _StatCard(
          icon: Icons.payments,
          label: AppStrings.totalFeesPaid,
          value: '${AppStrings.rupeesSymbol}${stats.totalFeesPaid.toStringAsFixed(0)}',
          color: AppColors.success600,
        ),
        _StatCard(
          icon: Icons.money_off,
          label: AppStrings.totalFeesDue,
          value: '${AppStrings.rupeesSymbol}${stats.totalFeesDue.toStringAsFixed(0)}',
          color: stats.totalFeesDue > 0 ? AppColors.error600 : scheme.onSurfaceVariant,
        ),
        _StatCard(
          icon: Icons.campaign,
          label: AppStrings.noticesSent,
          value: stats.noticesSentCount.toString(),
          color: AppColors.secondary600,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: AppBreakpoints.cardMinWidth,
      child: Card(
        shape: AppRadius.cardShape,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: AppOpacity.focus),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, size: AppIconSize.lg, color: color),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.h5(color: scheme.onSurface),
                    ),
                    Text(
                      label,
                      style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INFO CARD (reused for personal, academic, parent info)
// =============================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.fields,
  });
  final String title;
  final IconData icon;
  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.md, color: AppColors.success500),
                AppSpacing.hGapSm,
                Text(title, style: AppTextStyles.h6(color: scheme.onSurface)),
              ],
            ),
            AppSpacing.vGapMd,
            AppDivider.hairline,
            AppSpacing.vGapMd,
            ...fields.entries.map(
              (e) => Padding(
                padding: AppSpacing.paddingVSm,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppBreakpoints.sidebarCollapsed * 2,
                      child: Text(
                        e.key,
                        style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodyMd(color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MONTH PICKER
// =============================================================================

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: Icon(Icons.chevron_left, size: AppIconSize.lg),
              tooltip: AppStrings.back,
            ),
            AppSpacing.hGapMd,
            Text(
              '${_months[currentMonth.month - 1]} ${currentMonth.year}',
              style: AppTextStyles.h6(color: scheme.onSurface),
            ),
            AppSpacing.hGapMd,
            IconButton(
              onPressed: onNext,
              icon: Icon(Icons.chevron_right, size: AppIconSize.lg),
              tooltip: AppStrings.next,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ATTENDANCE SUMMARY CHIPS
// =============================================================================

class _AttendanceSummaryChips extends StatelessWidget {
  const _AttendanceSummaryChips({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final present = (summary['present'] as num?)?.toInt() ?? 0;
    final absent = (summary['absent'] as num?)?.toInt() ?? 0;
    final late = (summary['late'] as num?)?.toInt() ?? 0;
    final percentage = (summary['percentage'] as num?)?.toDouble() ?? 0.0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _AttendanceChip(
          label: AppStrings.present,
          value: present.toString(),
          color: AppColors.success600,
        ),
        _AttendanceChip(
          label: AppStrings.absent,
          value: absent.toString(),
          color: AppColors.error600,
        ),
        _AttendanceChip(
          label: AppStrings.late,
          value: late.toString(),
          color: AppColors.warning600,
        ),
        _AttendanceChip(
          label: AppStrings.attendancePercentage,
          value: '${percentage.toStringAsFixed(1)}%',
          color: AppColors.primary600,
        ),
      ],
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.focus),
        borderRadius: AppRadius.brFull,
        border: Border.all(
          color: color.withValues(alpha: AppOpacity.overlay),
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySm(color: color),
          ),
          Text(
            value,
            style: AppTextStyles.caption(color: color),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ATTENDANCE CALENDAR GRID
// =============================================================================

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar({required this.month, required this.records});
  final DateTime month;
  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon

    // Build a lookup: day number -> status
    final Map<int, String> statusMap = {};
    for (final r in records) {
      final dateStr = r['date']?.toString() ?? '';
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        statusMap[parsed.day] = r['status']?.toString() ?? '';
      }
    }

    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            // Weekday headers
            Row(
              children: weekDays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            AppSpacing.vGapSm,

            // Calendar cells
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
              ),
              itemCount: (firstWeekday - 1) + daysInMonth,
              itemBuilder: (_, index) {
                // Empty cells for days before the first
                if (index < firstWeekday - 1) {
                  return const SizedBox.shrink();
                }
                final day = index - (firstWeekday - 1) + 1;
                final status = statusMap[day];

                Color dotColor;
                if (status == null || status.isEmpty) {
                  dotColor = scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled);
                } else {
                  switch (status.toUpperCase()) {
                    case 'PRESENT':
                      dotColor = AppColors.success500;
                    case 'ABSENT':
                      dotColor = AppColors.error500;
                    case 'LATE':
                      dotColor = AppColors.warning500;
                    default:
                      dotColor = scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled);
                  }
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: AppTextStyles.bodySm(color: scheme.onSurface),
                    ),
                    Container(
                      width: AppSpacing.sm,
                      height: AppSpacing.sm,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FEE SUMMARY ITEM
// =============================================================================

class _FeeSummaryItem extends StatelessWidget {
  const _FeeSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
        AppSpacing.vGapXs,
        Text(value, style: AppTextStyles.h4(color: color)),
      ],
    );
  }
}

// =============================================================================
// PAYMENT TILE
// =============================================================================

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final receiptNo = payment['receiptNo']?.toString() ?? AppStrings.dash;
    final feeHead = payment['feeHead']?.toString() ?? AppStrings.dash;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final mode = payment['paymentMode']?.toString() ?? AppStrings.dash;
    final dateStr = payment['paymentDate']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr);

    return Card(
      shape: AppRadius.cardShape,
      child: ListTile(
        contentPadding: AppSpacing.paddingHLg,
        leading: CircleAvatar(
          radius: AppSpacing.lg,
          backgroundColor: AppColors.success500.withValues(alpha: AppOpacity.focus),
          child: Icon(Icons.receipt, size: AppIconSize.sm, color: AppColors.success500),
        ),
        title: Text(feeHead, style: AppTextStyles.bodyMd(color: scheme.onSurface)),
        subtitle: Text(
          '$receiptNo  ${AppStrings.dash}  $mode',
          style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppStrings.rupeesSymbol}${amount.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMd(color: AppColors.success600),
            ),
            if (date != null)
              Text(
                _fmtDate(date),
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// =============================================================================
// NOTICE TILE
// =============================================================================

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});
  final StudentNoticeModel notice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUrgent = notice.priority.toUpperCase() == 'URGENT';

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    notice.subject,
                    style: AppTextStyles.h6(color: scheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacing.hGapSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isUrgent ? AppColors.error600 : AppColors.neutral400)
                        .withValues(alpha: AppOpacity.focus),
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    isUrgent ? AppStrings.priorityUrgent : AppStrings.priorityNormal,
                    style: AppTextStyles.overline(
                      color: isUrgent ? AppColors.error600 : AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              notice.message,
              style: AppTextStyles.body(color: scheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.vGapMd,
            Row(
              children: [
                if (notice.targetStudent) ...[
                  _TargetChip(label: AppStrings.targetStudent),
                  AppSpacing.hGapSm,
                ],
                if (notice.targetParent)
                  _TargetChip(label: AppStrings.targetParent),
                const Spacer(),
                if (notice.sentByName != null)
                  Text(
                    '${AppStrings.sentBy} ${notice.sentByName}',
                    style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                  ),
                AppSpacing.hGapMd,
                Text(
                  _fmtDate(notice.createdAt),
                  style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.overline(color: scheme.onPrimaryContainer),
      ),
    );
  }
}

// =============================================================================
// SEND NOTICE BOTTOM SHEET
// =============================================================================

class _SendNoticeSheet extends ConsumerStatefulWidget {
  const _SendNoticeSheet({
    required this.studentId,
    required this.basePath,
    required this.onSent,
  });
  final String studentId;
  final String basePath;
  final VoidCallback onSent;

  @override
  ConsumerState<_SendNoticeSheet> createState() => _SendNoticeSheetState();
}

class _SendNoticeSheetState extends ConsumerState<_SendNoticeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _targetStudent = true;
  bool _targetParent = false;
  String _priority = 'NORMAL';
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.showWarning(context, AppStrings.validationError);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(schoolAdminServiceProvider).sendStudentNotice(
            widget.studentId,
            subject: _subjectCtrl.text.trim(),
            message: _messageCtrl.text.trim(),
            priority: _priority,
            targetStudent: _targetStudent,
            targetParent: _targetParent,
            basePath: widget.basePath,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(context, AppStrings.noticeSentSuccess);
        widget.onSent();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.dialogPadding,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: AppSpacing.xl3,
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: AppOpacity.disabled),
                      borderRadius: AppRadius.brFull,
                    ),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Title ───────────────────────────────────────────────
                Text(
                  AppStrings.sendNoticeToStudent,
                  style: AppTextStyles.h5(color: scheme.onSurface),
                ),
                AppSpacing.vGapLg,

                // ── Send To ─────────────────────────────────────────────
                Text(
                  AppStrings.sendTo,
                  style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                ),
                CheckboxListTile(
                  value: _targetStudent,
                  onChanged: (v) => setState(() => _targetStudent = v ?? true),
                  title: Text(AppStrings.targetStudent, style: AppTextStyles.body(color: scheme.onSurface)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                CheckboxListTile(
                  value: _targetParent,
                  onChanged: (v) => setState(() => _targetParent = v ?? false),
                  title: Text(AppStrings.targetParent, style: AppTextStyles.body(color: scheme.onSurface)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                AppSpacing.vGapMd,

                // ── Subject ─────────────────────────────────────────────
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.noticeSubject,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.noticeSubjectRequired : null,
                ),
                AppSpacing.vGapMd,

                // ── Message ─────────────────────────────────────────────
                TextFormField(
                  controller: _messageCtrl,
                  decoration: InputDecoration(
                    labelText: AppStrings.noticeMessage,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.noticeMessageRequired : null,
                ),
                AppSpacing.vGapMd,

                // ── Priority ────────────────────────────────────────────
                Text(
                  AppStrings.noticePriority,
                  style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                ),
                AppSpacing.vGapSm,
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'NORMAL',
                      label: Text(AppStrings.priorityNormal),
                    ),
                    ButtonSegment(
                      value: 'URGENT',
                      label: Text(AppStrings.priorityUrgent),
                    ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) =>
                      setState(() => _priority = s.first),
                ),
                AppSpacing.vGapXl,

                // ── Submit button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? SizedBox(
                            width: AppIconSize.md,
                            height: AppIconSize.md,
                            child: CircularProgressIndicator(
                              strokeWidth: AppBorderWidth.medium,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Icon(Icons.send, size: AppIconSize.md),
                    label: Text(AppStrings.sendNotice),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success600,
                      padding: AppSpacing.paddingVLg,
                    ),
                  ),
                ),
                AppSpacing.vGapMd,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PORTAL LOGIN CARD (preserved from original)
// =============================================================================

class _PortalLoginCard extends ConsumerWidget {
  const _PortalLoginCard({required this.student, required this.onRefresh});
  final StudentModel student;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hasLogin = student.hasLogin;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: AppIconSize.md, color: AppColors.success500),
                AppSpacing.hGapSm,
                Text(
                  AppStrings.portalLogin,
                  style: AppTextStyles.h6(color: scheme.onSurface),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: hasLogin
                        ? AppColors.success500.withValues(alpha: AppOpacity.focus)
                        : AppColors.neutral300.withValues(alpha: AppOpacity.medium),
                    borderRadius: AppRadius.brLg,
                    border: Border.all(
                      color: hasLogin
                          ? AppColors.success500.withValues(alpha: AppOpacity.overlay)
                          : AppColors.neutral400.withValues(alpha: AppOpacity.overlay),
                      width: AppBorderWidth.thin,
                    ),
                  ),
                  child: Text(
                    hasLogin ? AppStrings.active : AppStrings.noLogin,
                    style: AppTextStyles.overline(
                      color: hasLogin ? AppColors.success500 : AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            AppDivider.hairline,
            AppSpacing.vGapMd,
            Text(
              hasLogin
                  ? AppStrings.portalLoginActiveDesc
                  : AppStrings.portalLoginInactiveDesc,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
            ),
            AppSpacing.vGapMd,
            Row(
              children: [
                if (!hasLogin)
                  FilledButton.icon(
                    onPressed: () =>
                        _showPasswordDialog(context, ref, isCreate: true),
                    icon: Icon(Icons.add, size: AppIconSize.md),
                    label: Text(AppStrings.createLogin),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success500,
                    ),
                  ),
                if (hasLogin)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showPasswordDialog(context, ref, isCreate: false),
                    icon: Icon(Icons.lock_reset, size: AppIconSize.md),
                    label: Text(AppStrings.resetPassword),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isCreate,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _PasswordDialog(
        title: isCreate ? AppStrings.createStudentLogin : AppStrings.resetStudentPassword,
        confirmLabel: isCreate ? AppStrings.create : AppStrings.resetPassword,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      final svc = ref.read(schoolAdminServiceProvider);
      if (isCreate) {
        await svc.createStudentLogin(student.id, result);
        if (context.mounted) {
          AppFeedback.showSuccess(context, AppStrings.loginCreatedSuccess);
        }
      } else {
        await svc.resetStudentPassword(student.id, result);
        if (context.mounted) {
          AppFeedback.showSuccess(context, AppStrings.passwordResetSuccess);
        }
      }
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

// =============================================================================
// PASSWORD DIALOG (preserved from original)
// =============================================================================

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title, required this.confirmLabel});
  final String title;
  final String confirmLabel;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: AppRadius.dialogShape,
      title: Text(widget.title, style: AppTextStyles.h5(color: scheme.onSurface)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.dialogMinWidth),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: AppStrings.newPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      size: AppIconSize.md,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 6) {
                    return AppStrings.passwordMinLength;
                  }
                  return null;
                },
              ),
              AppSpacing.vGapMd,
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: AppStrings.confirmPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      size: AppIconSize.md,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_passwordCtrl.text);
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

// =============================================================================
// PARENTS SECTION (preserved from original)
// =============================================================================

class _ParentsSection extends ConsumerStatefulWidget {
  const _ParentsSection({required this.studentId});
  final String studentId;

  @override
  ConsumerState<_ParentsSection> createState() => _ParentsSectionState();
}

class _ParentsSectionState extends ConsumerState<_ParentsSection> {
  List<ParentLinkModel> _parents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = ref.read(schoolAdminServiceProvider);
      final result = await svc.getStudentParents(widget.studentId);
      if (mounted) setState(() { _parents = result; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: AppRadius.cardShape,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom,
                    color: AppColors.success500, size: AppIconSize.md),
                AppSpacing.hGapSm,
                Text(
                  AppStrings.parentsGuardiansTitle,
                  style: AppTextStyles.h6(color: scheme.onSurface),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAddParentDialog(context),
                  icon: Icon(Icons.add, size: AppIconSize.sm),
                  label: Text(AppStrings.addParent),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success500,
                    padding: AppSpacing.paddingHMd,
                    textStyle: AppTextStyles.bodySm(),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            AppDivider.hairline,
            AppSpacing.vGapMd,
            if (_loading)
              AppLoaderScreen(),
            if (_error != null)
              Text(_error!,
                  style: AppTextStyles.bodySm(color: scheme.error)),
            if (!_loading && _error == null && _parents.isEmpty)
              Text(AppStrings.noParentsLinked,
                  style: AppTextStyles.bodySm(
                      color: scheme.onSurfaceVariant)),
            ..._parents.map((p) => _ParentTile(
                  link: p,
                  onSetPrimary: () => _setPrimary(p),
                  onRemove: () => _confirmRemove(p),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _setPrimary(ParentLinkModel link) async {
    try {
      await ref.read(schoolAdminServiceProvider).updateParentLink(
            widget.studentId,
            link.parentId,
            {'isPrimary': true},
          );
      _load();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _confirmRemove(ParentLinkModel link) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: AppStrings.removeParentTitle,
      message: AppStrings.removeParentConfirm(link.fullName),
      confirmLabel: AppStrings.remove,
      isDanger: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(schoolAdminServiceProvider).unlinkParentFromStudent(
            widget.studentId,
            link.parentId,
          );
      _load();
      if (mounted) {
        AppFeedback.showSuccess(context, AppStrings.parentRemovedSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _showAddParentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => _AddParentDialog(
        studentId: widget.studentId,
        onAdded: _load,
      ),
    );
  }
}

// =============================================================================
// PARENT TILE
// =============================================================================

class _ParentTile extends StatelessWidget {
  const _ParentTile({
    required this.link,
    required this.onSetPrimary,
    required this.onRemove,
  });
  final ParentLinkModel link;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.success500.withValues(alpha: AppOpacity.focus),
        child: Text(
          link.fullName.isNotEmpty ? link.fullName[0].toUpperCase() : 'P',
          style: AppTextStyles.bodyMd(color: AppColors.success500),
        ),
      ),
      title: Row(
        children: [
          Text(link.fullName,
              style: AppTextStyles.bodyMd(color: scheme.onSurface)),
          if (link.isPrimary) ...[
            AppSpacing.hGapSm,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success500.withValues(alpha: AppOpacity.focus),
                borderRadius: AppRadius.brXs,
              ),
              child: Text(AppStrings.primaryLabel,
                  style: AppTextStyles.overline(color: AppColors.success700)),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(link.displayRelation,
              style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
          Text(link.phone, style: AppTextStyles.bodySm(color: scheme.onSurface)),
          if (link.email != null)
            Text(link.email!,
                style: AppTextStyles.bodySm(color: scheme.onSurface)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'primary') onSetPrimary();
          if (v == 'remove') onRemove();
        },
        itemBuilder: (_) => [
          if (!link.isPrimary)
            PopupMenuItem(
              value: 'primary',
              child: Text(AppStrings.setAsPrimary),
            ),
          PopupMenuItem(
            value: 'remove',
            child: Text(AppStrings.remove,
                style: AppTextStyles.body(color: AppColors.error600)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ADD PARENT DIALOG (preserved from original)
// =============================================================================

class _AddParentDialog extends ConsumerStatefulWidget {
  const _AddParentDialog({required this.studentId, required this.onAdded});
  final String studentId;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddParentDialog> createState() => _AddParentDialogState();
}

class _AddParentDialogState extends ConsumerState<_AddParentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _linkRelation = 'Father';
  bool _saving = false;
  bool _searched = false;
  ParentSearchModel? _foundParent;
  bool _createNew = false;

  static const _relations = [
    'Father', 'Mother', 'Guardian', 'Grandfather',
    'Grandmother', 'Uncle', 'Aunt', 'Other',
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchByPhone() async {
    if (_phoneCtrl.text.length < 10) return;
    setState(() {
      _searched = false;
      _foundParent = null;
      _createNew = false;
    });
    try {
      final results = await ref
          .read(schoolAdminServiceProvider)
          .searchParents(_phoneCtrl.text.trim());
      if (mounted) {
        setState(() {
          _searched = true;
          _foundParent = results.isNotEmpty ? results.first : null;
          _createNew = results.isEmpty;
          if (_foundParent != null) {
            _firstCtrl.text = _foundParent!.firstName;
            _lastCtrl.text = _foundParent!.lastName;
            _emailCtrl.text = _foundParent!.email ?? '';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searched = true;
          _createNew = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'linkRelation': _linkRelation,
      };
      if (_foundParent != null) {
        body['parentId'] = _foundParent!.id;
      } else {
        body['phone'] = _phoneCtrl.text.trim();
        body['firstName'] = _firstCtrl.text.trim();
        body['lastName'] = _lastCtrl.text.trim();
        if (_emailCtrl.text.trim().isNotEmpty) {
          body['email'] = _emailCtrl.text.trim();
        }
      }
      await ref
          .read(schoolAdminServiceProvider)
          .linkParentToStudent(widget.studentId, body);
      if (mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, AppStrings.parentLinkedSuccess);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: AppRadius.dialogShape,
      title: Text(AppStrings.addParentGuardian, style: AppTextStyles.h5(color: scheme.onSurface)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.dialogMinWidth),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Phone search ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: AppStrings.phoneNumberLabel,
                          border: const OutlineInputBorder(),
                          hintText: AppStrings.searchExistingParentHint,
                        ),
                        validator: (v) => (v == null || v.length < 10)
                            ? AppStrings.validPhoneRequired
                            : null,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    OutlinedButton(
                      onPressed: _searchByPhone,
                      child: Text(AppStrings.searchAction),
                    ),
                  ],
                ),

                // ── Found existing parent ─────────────────────────────
                if (_searched && _foundParent != null) ...[
                  AppSpacing.vGapMd,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.success500.withValues(alpha: AppOpacity.shadow),
                      borderRadius: AppRadius.brMd,
                      border: Border.all(
                        color: AppColors.success500.withValues(alpha: AppOpacity.overlay),
                        width: AppBorderWidth.thin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success500, size: AppIconSize.md),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text(
                            AppStrings.parentFoundDetail(
                              _foundParent!.fullName,
                              _foundParent!.childrenCount,
                            ),
                            style: AppTextStyles.bodySm(
                                color: AppColors.success700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Create new parent fields ──────────────────────────
                if (_searched && _createNew) ...[
                  AppSpacing.vGapMd,
                  Text(AppStrings.noParentFoundCreateNew,
                      style: AppTextStyles.bodySm(
                          color: scheme.onSurfaceVariant)),
                  AppSpacing.vGapMd,
                  TextFormField(
                    controller: _firstCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.firstNameRequired,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.validFieldRequired
                        : null,
                  ),
                  AppSpacing.vGapMd,
                  TextFormField(
                    controller: _lastCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.lastNameRequired,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.validFieldRequired
                        : null,
                  ),
                  AppSpacing.vGapMd,
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.emailOptional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],

                // ── Relation dropdown ─────────────────────────────────
                if (_searched) ...[
                  AppSpacing.vGapMd,
                  DropdownButtonFormField<String>(
                    initialValue: _linkRelation,
                    decoration: InputDecoration(
                      labelText: AppStrings.relationToStudent,
                      border: const OutlineInputBorder(),
                    ),
                    items: _relations
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _linkRelation = v ?? 'Father'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        if (_searched && (_foundParent != null || _createNew))
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: AppColors.success500),
            child: _saving
                ? SizedBox(
                    width: AppIconSize.md,
                    height: AppIconSize.md,
                    child: CircularProgressIndicator(
                      strokeWidth: AppBorderWidth.medium,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(AppStrings.linkParent),
          ),
      ],
    );
  }
}
