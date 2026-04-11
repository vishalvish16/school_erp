// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_profile_request_detail_screen.dart
// PURPOSE: Detail screen showing old vs new values for a profile update request.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../models/school_admin/profile_update_request_model.dart';
import '../providers/profile_requests_provider.dart';

class SchoolAdminProfileRequestDetailScreen extends ConsumerStatefulWidget {
  const SchoolAdminProfileRequestDetailScreen({
    super.key,
    required this.requestId,
    this.basePath = '/school-admin',
  });

  final String requestId;
  final String basePath;

  @override
  ConsumerState<SchoolAdminProfileRequestDetailScreen> createState() =>
      _DetailScreenState();
}

class _DetailScreenState
    extends ConsumerState<SchoolAdminProfileRequestDetailScreen> {
  bool _isSubmitting = false;

  ProfileUpdateRequest? _findRequest() {
    final state = ref.read(profileRequestsProvider);
    try {
      return state.requests.firstWhere((r) => r.id == widget.requestId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleApprove(ProfileUpdateRequest request) async {
    final noteCtrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await AppFeedback.confirm(
      context,
      title: AppStrings.approveRequest,
      message: AppStrings.approveRequestConfirm,
      confirmLabel: AppStrings.approve,
      icon: Icons.check_circle_outline,
    );

    if (confirmed != true || !mounted) return;

    // Show optional note dialog
    String? note;
    if (mounted) {
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: AppRadius.dialogShape,
          backgroundColor: scheme.surface,
          title: Text(AppStrings.reviewNote,
              style: AppTextStyles.h6(color: scheme.onSurface)),
          content: TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              hintText: AppStrings.noteOptional,
              hintStyle: AppTextStyles.body(color: scheme.onSurfaceVariant),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
              child: Text(AppStrings.approve),
            ),
          ],
        ),
      );
    }

    if (note == null || !mounted) return;

    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(profileRequestsProvider.notifier)
        .approveRequest(request.id, note: note.isNotEmpty ? note : null);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        AppFeedback.showSuccess(context, AppStrings.requestApproved);
        context.go('${widget.basePath}/profile-requests');
      } else {
        AppFeedback.showError(
          context,
          ref.read(profileRequestsProvider).errorMessage ??
              AppStrings.genericError,
        );
      }
    }
    noteCtrl.dispose();
  }

  Future<void> _handleReject(ProfileUpdateRequest request) async {
    final noteCtrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;

    String? note;
    note = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          shape: AppRadius.dialogShape,
          backgroundColor: scheme.surface,
          title: Text(AppStrings.rejectRequest,
              style: AppTextStyles.h6(color: scheme.onSurface)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: AppStrings.reviewNote,
                hintStyle: AppTextStyles.body(color: scheme.onSurfaceVariant),
              ),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.noteRequired : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error600,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, noteCtrl.text.trim());
                }
              },
              child: Text(AppStrings.reject),
            ),
          ],
        );
      },
    );

    if (note == null || note.isEmpty || !mounted) {
      noteCtrl.dispose();
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await ref
        .read(profileRequestsProvider.notifier)
        .rejectRequest(request.id, note: note);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        AppFeedback.showSuccess(context, AppStrings.requestRejected);
        context.go('${widget.basePath}/profile-requests');
      } else {
        AppFeedback.showError(
          context,
          ref.read(profileRequestsProvider).errorMessage ??
              AppStrings.genericError,
        );
      }
    }
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch to rebuild when state updates
    ref.watch(profileRequestsProvider);
    final request = _findRequest();
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

    if (request == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: AppIconSize.xl3, color: scheme.onSurfaceVariant),
              AppSpacing.vGapMd,
              Text(AppStrings.notFoundError,
                  style: AppTextStyles.body(color: scheme.onSurface)),
              AppSpacing.vGapMd,
              TextButton(
                onPressed: () =>
                    context.go('${widget.basePath}/profile-requests'),
                child: Text(AppStrings.back),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth),
          child: SingleChildScrollView(
            padding: isWide ? AppSpacing.pagePadding : AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back + Title ──────────────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          context.go('${widget.basePath}/profile-requests'),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: AppStrings.back,
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(AppStrings.profileRequestDetail,
                          style: AppTextStyles.h5(color: scheme.onSurface)),
                    ),
                    _StatusBadge(status: request.status),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── Student Card ──────────────────────────────────────────
                _StudentCard(request: request, scheme: scheme),
                AppSpacing.vGapLg,

                // ── Changes Requested ─────────────────────────────────────
                Text(AppStrings.changesRequested,
                    style: AppTextStyles.h6(color: scheme.onSurface)),
                AppSpacing.vGapMd,
                ...request.requestedChanges.entries.map(
                  (entry) => _ChangeRow(
                    fieldName: _fieldLabel(entry.key),
                    oldValue: request.currentValues[entry.key]?.toString() ??
                        AppStrings.notAvailable,
                    newValue: entry.value?.toString() ?? AppStrings.notAvailable,
                    scheme: scheme,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Meta info ─────────────────────────────────────────────
                _MetaInfo(request: request, scheme: scheme),
                AppSpacing.vGapXl,

                // ── Actions (only if pending) ─────────────────────────────
                if (request.isPending)
                  _ActionButtons(
                    isSubmitting: _isSubmitting,
                    onApprove: () => _handleApprove(request),
                    onReject: () => _handleReject(request),
                  ),

                // ── Review note (if already reviewed) ─────────────────────
                if (!request.isPending && request.reviewNote != null) ...[
                  AppSpacing.vGapLg,
                  _ReviewNoteCard(request: request, scheme: scheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fieldLabel(String key) {
    const labels = {
      'firstName': AppStrings.firstName,
      'first_name': AppStrings.firstName,
      'lastName': AppStrings.lastName,
      'last_name': AppStrings.lastName,
      'dateOfBirth': AppStrings.dateOfBirth,
      'date_of_birth': AppStrings.dateOfBirth,
      'bloodGroup': AppStrings.bloodGroup,
      'blood_group': AppStrings.bloodGroup,
      'address': AppStrings.address,
      'parentName': AppStrings.parentName,
      'parent_name': AppStrings.parentName,
      'parentPhone': AppStrings.parentPhone,
      'parent_phone': AppStrings.parentPhone,
      'parentEmail': AppStrings.parentEmail,
      'parent_email': AppStrings.parentEmail,
      'gender': AppStrings.gender,
    };
    return labels[key] ?? key;
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'APPROVED':
        color = AppColors.success500;
        label = AppStrings.statusApproved;
      case 'REJECTED':
        color = AppColors.error500;
        label = AppStrings.statusRejected;
      default:
        color = AppColors.warning500;
        label = AppStrings.statusPending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.focus),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(label, style: AppTextStyles.caption(color: color)),
    );
  }
}

// ── Student Card ──────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.request, required this.scheme});
  final ProfileUpdateRequest request;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final photoUrl = request.student?['photoUrl'] as String?;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: AppOpacity.medium),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: scheme.outlineVariant,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.xl,
            backgroundColor: AppColors.primary100,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    request.studentName.isNotEmpty
                        ? request.studentName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.h5(color: AppColors.primary600),
                  )
                : null,
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.studentName,
                    style: AppTextStyles.bodyMd(color: scheme.onSurface)),
                AppSpacing.vGapXs,
                Text(
                  '${AppStrings.admissionNo}: ${request.studentAdmissionNo}',
                  style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Change Row ────────────────────────────────────────────────────────────────

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.scheme,
  });

  final String fieldName;
  final String oldValue;
  final String newValue;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingVSm,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: scheme.outlineVariant,
            width: AppBorderWidth.thin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fieldName,
                style: AppTextStyles.caption(color: scheme.onSurfaceVariant)),
            AppSpacing.vGapSm,
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.currentValue,
                          style: AppTextStyles.bodySm(
                              color: scheme.onSurfaceVariant)),
                      AppSpacing.vGapXs,
                      Text(oldValue,
                          style: AppTextStyles.body(
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Padding(
                  padding: AppSpacing.paddingHSm,
                  child: Icon(Icons.arrow_forward,
                      size: AppIconSize.md, color: AppColors.primary600),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.newValue,
                          style: AppTextStyles.bodySm(
                              color: AppColors.primary600)),
                      AppSpacing.vGapXs,
                      Text(newValue,
                          style: AppTextStyles.bodyMd(
                              color: AppColors.primary600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta Info ─────────────────────────────────────────────────────────────────

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({required this.request, required this.scheme});
  final ProfileUpdateRequest request;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(AppStrings.requestedBy, request.parentName),
        if (request.parentPhone.isNotEmpty)
          _infoRow(AppStrings.phone, request.parentPhone),
        _infoRow(AppStrings.requestedOn, fmt.format(request.createdAt)),
        if (request.reviewedAt != null)
          _infoRow(AppStrings.reviewedOn, fmt.format(request.reviewedAt!)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: AppSpacing.paddingVSm,
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.xl5 * 2,
            child: Text(label,
                style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child:
                Text(value, style: AppTextStyles.body(color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
  });

  final bool isSubmitting;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSubmitting ? null : onReject,
            icon: Icon(Icons.close, size: AppIconSize.md),
            label: Text(AppStrings.reject),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error600,
              side: BorderSide(color: AppColors.error600, width: AppBorderWidth.thin),
              shape: AppRadius.cardShape,
              padding: AppSpacing.paddingVMd,
            ),
          ),
        ),
        AppSpacing.hGapLg,
        Expanded(
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onApprove,
            icon: isSubmitting
                ? SizedBox(
                    width: AppIconSize.md,
                    height: AppIconSize.md,
                    child: CircularProgressIndicator(
                      strokeWidth: AppBorderWidth.medium,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.check, size: AppIconSize.md),
            label: Text(AppStrings.approve),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success600,
              shape: AppRadius.cardShape,
              padding: AppSpacing.paddingVMd,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Review Note Card ──────────────────────────────────────────────────────────

class _ReviewNoteCard extends StatelessWidget {
  const _ReviewNoteCard({required this.request, required this.scheme});
  final ProfileUpdateRequest request;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: (request.isApproved ? AppColors.success50 : AppColors.error50)
            .withValues(alpha: AppOpacity.medium),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: request.isApproved ? AppColors.success300 : AppColors.error300,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.reviewNote,
              style: AppTextStyles.caption(color: scheme.onSurfaceVariant)),
          AppSpacing.vGapXs,
          Text(request.reviewNote!,
              style: AppTextStyles.body(color: scheme.onSurface)),
        ],
      ),
    );
  }
}
