// FILE: lib/core/theme/app_input_styles.dart
// PURPOSE: TextField / InputDecoration factories
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppInputStyles {
  AppInputStyles._();

  // ── Base InputDecorationTheme (used in ThemeData) ───────────────────────────
  static InputDecorationTheme inputDecorationTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    // Dark: glass navy fill + white-glass border (clearly visible on #07111F bg)
    // Light: white fill + blue-tinted border (matching brand login style)
    final fillColor = isDark
        ? AppColors.brandNavy700        // #122040 — slightly lighter than card
        : AppColors.lightSurface;       // white
    final borderColor = isDark
        ? AppColors.glassWhite18        // rgba(255,255,255,0.18) — visible glass border
        : AppColors.lightBorder;        // #C7D8F5 — blue border
    final focusColor = AppColors.brandBlue; // #2563EB — brand blue focus for both modes

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
        borderSide: BorderSide(color: focusColor, width: 2),
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
          color: isDark
              ? AppColors.glassWhite05
              : AppColors.lightBorder.withAlpha(100),
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
          return AppTextStyles.caption(color: focusColor);
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
        if (states.contains(WidgetState.focused)) return focusColor;
        return isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return AppColors.error600;
        if (states.contains(WidgetState.focused)) return focusColor;
        return isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
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
      hintText: hint ?? AppStrings.searchHint,
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
