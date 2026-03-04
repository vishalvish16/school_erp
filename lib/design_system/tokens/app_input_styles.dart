// FILE: lib/core/theme/app_input_styles.dart
// PURPOSE: TextField / InputDecoration factories
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppInputStyles {
  AppInputStyles._();

  // ── Base InputDecorationTheme (used in ThemeData) ───────────────────────────
  static InputDecorationTheme inputDecorationTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.darkSurfaceVar : AppColors.neutral100;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // ── Border states ───────────────────────────────────────────────────────
      border: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(
          color: isDark ? AppColors.primary400 : AppColors.primary600,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: const BorderSide(color: AppColors.error600, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: const BorderSide(color: AppColors.error600, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(
          color: borderColor.withAlpha(128),
          width: 1,
        ),
      ),
      // ── Text styles ────────────────────────────────────────────────────────
      hintStyle: AppTextStyles.body(
        color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
      ),
      labelStyle: AppTextStyles.bodyMd(
        color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
      ),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.error)) {
          return AppTextStyles.caption(color: AppColors.error600);
        }
        if (states.contains(WidgetState.focused)) {
          return AppTextStyles.caption(
            color: isDark ? AppColors.primary400 : AppColors.primary600,
          );
        }
        return AppTextStyles.caption(
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
        );
      }),
      helperStyle: AppTextStyles.caption(
        color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
      ),
      errorStyle: AppTextStyles.caption(color: AppColors.error600),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return isDark ? AppColors.primary400 : AppColors.primary600;
        }
        return isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return AppColors.error600;
        if (states.contains(WidgetState.focused)) {
          return isDark ? AppColors.primary400 : AppColors.primary600;
        }
        return isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
      }),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: true,
    );
  }

  // ── Individual decoration factory ───────────────────────────────────────────
  /// Build a custom InputDecoration for one-off field customisations.
  static InputDecoration decoration({
    required BuildContext context,
    String? label,
    String? hint,
    String? helper,
    Widget? prefix,
    Widget? suffix,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isRequired = false,
  }) {
    final labelText = isRequired && label != null ? '$label *' : label;
    return InputDecoration(
      labelText: labelText,
      hintText: hint,
      helperText: helper,
      prefix: prefix,
      suffix: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  // ── Search field decoration ──────────────────────────────────────────────────
  static InputDecoration search(BuildContext context, {String? hint}) {
    return InputDecoration(
      hintText: hint ?? 'Search…',
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      border: OutlineInputBorder(
        borderRadius: AppRadius.brFull,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brFull,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.brFull,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      isDense: true,
    );
  }
}
