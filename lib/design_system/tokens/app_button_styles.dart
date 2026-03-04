// =============================================================================
// FILE: lib/core/theme/app_button_styles.dart
// PURPOSE: Reusable ButtonStyle factories for all button variants
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Button size presets
enum AppButtonSize { sm, md, lg }

extension AppButtonSizeX on AppButtonSize {
  double get height => switch (this) {
    AppButtonSize.sm => 36,
    AppButtonSize.md => 44,
    AppButtonSize.lg => 52,
  };

  EdgeInsetsGeometry get padding => switch (this) {
    AppButtonSize.sm => const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    AppButtonSize.md => const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm + 2,
    ),
    AppButtonSize.lg => const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
  };

  TextStyle get textStyle => switch (this) {
    AppButtonSize.sm => AppTextStyles.caption(),
    AppButtonSize.md => AppTextStyles.buttonLabel(),
    AppButtonSize.lg => AppTextStyles.bodyMd(),
  };
}

abstract final class AppButtonStyles {
  AppButtonStyles._();

  // ── PRIMARY — filled Indigo ──────────────────────────────────────────────────
  static ButtonStyle primary({AppButtonSize size = AppButtonSize.md}) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        minimumSize: Size(64, size.height),
        padding: size.padding,
        elevation: AppElevation.xs,
        shadowColor: AppColors.primary600.withAlpha(77),
        textStyle: size.textStyle,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        animationDuration: const Duration(milliseconds: 200),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered))
            return Colors.white.withAlpha(25);
          if (states.contains(WidgetState.pressed))
            return Colors.white.withAlpha(40);
          return null;
        }),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppElevation.sm;
          if (states.contains(WidgetState.pressed)) return 0;
          return AppElevation.xs;
        }),
      );

  // ── SECONDARY — filled Blue ──────────────────────────────────────────────────
  static ButtonStyle secondary({AppButtonSize size = AppButtonSize.md}) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        minimumSize: Size(64, size.height),
        padding: size.padding,
        elevation: AppElevation.xs,
        shadowColor: AppColors.secondary600.withAlpha(77),
        textStyle: size.textStyle,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered))
            return Colors.white.withAlpha(25);
          if (states.contains(WidgetState.pressed))
            return Colors.white.withAlpha(40);
          return null;
        }),
      );

  // ── OUTLINE — bordered, transparent ─────────────────────────────────────────
  static ButtonStyle outline({
    AppButtonSize size = AppButtonSize.md,
    Color? color,
  }) {
    final fgColor = color ?? AppColors.primary600;
    return OutlinedButton.styleFrom(
      foregroundColor: fgColor,
      disabledForegroundColor: AppColors.neutral400,
      minimumSize: Size(64, size.height),
      padding: size.padding,
      textStyle: size.textStyle,
      side: BorderSide(color: fgColor, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return fgColor.withAlpha(15);
        if (states.contains(WidgetState.pressed)) return fgColor.withAlpha(25);
        return null;
      }),
    );
  }

  // ── GHOST — text only ────────────────────────────────────────────────────────
  static ButtonStyle ghost({
    AppButtonSize size = AppButtonSize.md,
    Color? color,
  }) {
    final fgColor = color ?? AppColors.primary600;
    return TextButton.styleFrom(
      foregroundColor: fgColor,
      disabledForegroundColor: AppColors.neutral400,
      minimumSize: Size(64, size.height),
      padding: size.padding,
      textStyle: size.textStyle,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return fgColor.withAlpha(12);
        if (states.contains(WidgetState.pressed)) return fgColor.withAlpha(20);
        return null;
      }),
    );
  }

  // ── DANGER — filled error/red ────────────────────────────────────────────────
  static ButtonStyle danger({AppButtonSize size = AppButtonSize.md}) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.error600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        minimumSize: Size(64, size.height),
        padding: size.padding,
        elevation: AppElevation.xs,
        shadowColor: AppColors.error600.withAlpha(77),
        textStyle: size.textStyle,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered))
            return Colors.white.withAlpha(25);
          if (states.contains(WidgetState.pressed))
            return Colors.white.withAlpha(40);
          return null;
        }),
      );

  // ── DANGER OUTLINE ───────────────────────────────────────────────────────────
  static ButtonStyle dangerOutline({AppButtonSize size = AppButtonSize.md}) =>
      outline(size: size, color: AppColors.error600);

  // ── SUCCESS ──────────────────────────────────────────────────────────────────
  static ButtonStyle success({AppButtonSize size = AppButtonSize.md}) =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.success600,
        foregroundColor: Colors.white,
        minimumSize: Size(64, size.height),
        padding: size.padding,
        elevation: AppElevation.xs,
        shadowColor: AppColors.success600.withAlpha(77),
        textStyle: size.textStyle,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      );

  // ── ICON BUTTON (circular) ───────────────────────────────────────────────────
  static ButtonStyle iconButton({
    Color? backgroundColor,
    Color? foregroundColor,
    double size = 40,
  }) => IconButton.styleFrom(
    backgroundColor: backgroundColor ?? Colors.transparent,
    foregroundColor: foregroundColor ?? AppColors.neutral600,
    minimumSize: Size(size, size),
    fixedSize: Size(size, size),
    shape: const CircleBorder(),
    padding: EdgeInsets.zero,
  );

  // ── FAB style ────────────────────────────────────────────────────────────────
  static ButtonStyle fab() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary600,
    foregroundColor: Colors.white,
    minimumSize: const Size(56, 56),
    padding: AppSpacing.paddingSm,
    elevation: AppElevation.md,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
  );
}
