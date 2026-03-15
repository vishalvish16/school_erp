// =============================================================================
// FILE: lib/shared/widgets/app_feedback.dart
// PURPOSE: Single source of truth for ALL user feedback in the system.
//          Toast messages, snackbars, confirmation dialogs, success dialogs,
//          warning dialogs, error dialogs — ALL go through this class only.
//
// RULE: No screen, widget, or provider may call ScaffoldMessenger, showDialog,
//       showSnackBar, or any overlay directly. Use AppFeedback everywhere.
//
// DESIGN TOKENS: Every size, color, spacing, duration, and opacity value
//                comes from the design system — zero hardcoded raw values.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_text_styles.dart';
import '../../core/constants/app_strings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOAST TYPE ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum AppToastType { success, error, warning, info }

// ─────────────────────────────────────────────────────────────────────────────
// APP FEEDBACK — SINGLE CLASS FOR ALL FEEDBACK UI
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppFeedback {
  AppFeedback._();

  // ───────────────────────────────────────────────────────────────────────────
  // TOAST / SNACKBAR
  // ───────────────────────────────────────────────────────────────────────────

  /// Show a success toast (green). Use after successful create/update/delete.
  static void showSuccess(BuildContext context, String message) =>
      _showToast(context, message: message, type: AppToastType.success);

  /// Show an error toast (red). Use when an API call fails.
  static void showError(BuildContext context, String message) =>
      _showToast(context, message: message, type: AppToastType.error);

  /// Show a warning toast (amber). Use for non-fatal cautions.
  static void showWarning(BuildContext context, String message) =>
      _showToast(context, message: message, type: AppToastType.warning);

  /// Show an info toast (cyan). Use for neutral informational messages.
  static void showInfo(BuildContext context, String message) =>
      _showToast(context, message: message, type: AppToastType.info);

  static void _showToast(
    BuildContext context, {
    required String message,
    required AppToastType type,
    Duration duration = AppDuration.toast,       // ← token, not Duration(seconds: 3)
  }) {
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final Color border;
    final IconData icon;

    switch (type) {
      case AppToastType.success:
        bg     = isDark ? AppColors.success700 : AppColors.success50;
        fg     = isDark ? AppColors.success50  : AppColors.success700;
        border = isDark ? AppColors.success500 : AppColors.success300;
        icon   = Icons.check_circle_rounded;
      case AppToastType.error:
        bg     = isDark ? AppColors.error700 : AppColors.error50;
        fg     = isDark ? AppColors.error50  : AppColors.error700;
        border = isDark ? AppColors.error500 : AppColors.error300;
        icon   = Icons.error_rounded;
      case AppToastType.warning:
        bg     = isDark ? AppColors.warning700 : AppColors.warning50;
        fg     = isDark ? AppColors.warning50  : AppColors.warning700;
        border = isDark ? AppColors.warning500 : AppColors.warning300;
        icon   = Icons.warning_amber_rounded;
      case AppToastType.info:
        bg     = isDark ? AppColors.info600    : AppColors.secondary50;
        fg     = isDark ? Colors.white          : AppColors.secondary700;
        border = isDark ? AppColors.info500    : AppColors.secondary300;
        icon   = Icons.info_rounded;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: AppElevation.none,            // ← token, not 0
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: AppSpacing.xl2,
            left:   AppSpacing.xl,
            right:  AppSpacing.xl,
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical:   AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color:        bg,
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: border,
                width: AppBorderWidth.thin,        // ← token, not 1
              ),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: AppOpacity.shadow), // ← token, not 0.08
                  blurRadius: AppElevation.md,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: fg, size: AppIconSize.md),          // ← token, not 18
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodyMd(color: fg),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacing.hGapSm,
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  child: Icon(
                    Icons.close_rounded,
                    color: fg.withValues(alpha: AppOpacity.high),     // ← token, not 0.7
                    size:  AppIconSize.sm,                             // ← token, not 16
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CONFIRMATION DIALOG
  // ───────────────────────────────────────────────────────────────────────────

  /// Show a standard confirm/cancel dialog. Returns true if confirmed.
  ///
  /// ```dart
  /// final confirmed = await AppFeedback.confirm(
  ///   context,
  ///   title: AppStrings.deleteConfirmTitle,
  ///   message: AppStrings.deleteStudentConfirm(student.fullName),
  ///   confirmLabel: AppStrings.delete,
  ///   isDanger: true,
  /// );
  /// if (confirmed == true) { ... }
  /// ```
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDanger = false,
    IconData? icon,
  }) {
    final scheme       = Theme.of(context).colorScheme;
    final confirmColor = isDanger ? AppColors.error600 : scheme.primary;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:          AppRadius.dialogShape,
        backgroundColor: scheme.surface,
        contentPadding: AppSpacing.dialogPadding,
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg,
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDanger ? AppColors.error600 : scheme.primary,
                size:  AppIconSize.lg,                                 // ← token, not 22
              ),
              AppSpacing.hGapMd,
            ],
            Expanded(
              child: Text(title, style: AppTextStyles.h5(color: scheme.onSurface)),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.body(color: scheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelLabel ?? AppStrings.cancel,
              style: AppTextStyles.buttonLabel(color: scheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape:   RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical:   AppSpacing.sm,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel ?? AppStrings.confirm,
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE CONFIRMATION (convenience shorthand)
  // ───────────────────────────────────────────────────────────────────────────

  /// Shorthand for a red "Delete" confirmation dialog.
  static Future<bool?> confirmDelete(
    BuildContext context, {
    required String entityName,
    String? customMessage,
  }) =>
      confirm(
        context,
        title:         AppStrings.deleteConfirmTitle,
        message:       customMessage ?? AppStrings.deleteConfirmMessage(entityName),
        confirmLabel:  AppStrings.delete,
        isDanger:      true,
        icon:          Icons.delete_outline_rounded,
      );

  // ───────────────────────────────────────────────────────────────────────────
  // LOADING DIALOG (blocking spinner with message)
  // ───────────────────────────────────────────────────────────────────────────

  /// Show a blocking loading dialog. Must call [hideLoading] when done.
  ///
  /// ```dart
  /// AppFeedback.showLoading(context, message: AppStrings.savingLabel);
  /// await doWork();
  /// AppFeedback.hideLoading(context);
  /// ```
  static void showLoading(BuildContext context, {String? message}) {
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
          child: Padding(
            padding: AppSpacing.dialogPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color:       scheme.primary,
                  strokeWidth: AppBorderWidth.thick,   // ← token, not 2.5
                ),
                AppSpacing.hGapXl,
                Text(
                  message ?? AppStrings.loadingLabel,
                  style: AppTextStyles.body(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Close the loading dialog opened by [showLoading].
  static void hideLoading(BuildContext context) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INFORMATIONAL DIALOG (OK button only)
  // ───────────────────────────────────────────────────────────────────────────

  /// Show a simple info/alert dialog with only an OK button.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String? okLabel,
    AppToastType type = AppToastType.info,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final IconData icon;
    final Color iconColor;
    switch (type) {
      case AppToastType.success:
        icon = Icons.check_circle_rounded; iconColor = AppColors.success600;
      case AppToastType.error:
        icon = Icons.error_rounded;        iconColor = AppColors.error600;
      case AppToastType.warning:
        icon = Icons.warning_amber_rounded; iconColor = AppColors.warning600;
      case AppToastType.info:
        icon = Icons.info_rounded;         iconColor = scheme.primary;
    }

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:          AppRadius.dialogShape,
        backgroundColor: scheme.surface,
        contentPadding: AppSpacing.dialogPadding,
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg,
        ),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: AppIconSize.lg),        // ← token, not 22
            AppSpacing.hGapMd,
            Expanded(
              child: Text(title, style: AppTextStyles.h5(color: scheme.onSurface)),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.body(color: scheme.onSurfaceVariant),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: Colors.white,
              shape:   RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical:   AppSpacing.sm,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              okLabel ?? AppStrings.ok,
              style: AppTextStyles.buttonLabel(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INLINE ERROR BANNER (embedded in screen body, not a dialog)
  // ───────────────────────────────────────────────────────────────────────────

  /// Embed in screen body for API load failures.
  static Widget errorBanner(String message, {VoidCallback? onRetry}) =>
      _InlineErrorBanner(message: message, onRetry: onRetry);

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS CHIP (color-coded badge for tables/lists)
  // ───────────────────────────────────────────────────────────────────────────

  /// Color-mapped status badge.
  /// `AppFeedback.statusChip('ACTIVE')` → green chip
  static Widget statusChip(String status) => _StatusChip(status: status);
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.error700 : AppColors.error50;
    final fg     = isDark ? AppColors.error50  : AppColors.error700;
    final border = isDark ? AppColors.error500 : AppColors.error300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical:   AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: border,
          width: AppBorderWidth.thin,                                  // ← token, not 1
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: fg, size: AppIconSize.md), // ← token, not 18
          AppSpacing.hGapMd,
          Expanded(
            child: Text(message, style: AppTextStyles.bodySm(color: fg)),
          ),
          if (onRetry != null) ...[
            AppSpacing.hGapMd,
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(AppStrings.retry, style: AppTextStyles.caption(color: fg)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = isDark ? AppColors.success700 : AppColors.success50;
        fg = isDark ? AppColors.success50  : AppColors.success700;
        label = AppStrings.statusActive;
      case 'INACTIVE':
      case 'SUSPENDED':
        bg = isDark ? AppColors.error700 : AppColors.error50;
        fg = isDark ? AppColors.error50  : AppColors.error700;
        label = AppStrings.statusSuspended;
      case 'PENDING':
        bg = isDark ? AppColors.warning700 : AppColors.warning50;
        fg = isDark ? AppColors.warning50  : AppColors.warning700;
        label = AppStrings.statusPending;
      case 'DRAFT':
        bg = isDark ? AppColors.neutral700 : AppColors.neutral100;
        fg = isDark ? AppColors.neutral200 : AppColors.neutral600;
        label = AppStrings.statusDraft;
      default:
        bg = isDark ? AppColors.neutral700 : AppColors.neutral100;
        fg = isDark ? AppColors.neutral200 : AppColors.neutral600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical:   AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brFull),
      child: Text(label, style: AppTextStyles.overline(color: fg)),
    );
  }
}
