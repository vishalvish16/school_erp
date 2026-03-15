// =============================================================================
// FILE: lib/core/theme/app_colors.dart
// PURPOSE: Centralized color tokens for School ERP SaaS Admin Panel
// THEME: Material 3 · Indigo + Blue palette
// =============================================================================

import 'package:flutter/material.dart';

/// All raw color values for the School ERP design system.
/// Never use these directly in widgets — use AppTheme context extensions instead.
abstract final class AppColors {
  AppColors._();

  // ── Primary — Indigo ────────────────────────────────────────────────────────
  static const Color primary50  = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1); // brand base
  static const Color primary600 = Color(0xFF4F46E5); // default interactive
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);
  static const Color primary950 = Color(0xFF1E1B4B);

  // ── Secondary — Blue ────────────────────────────────────────────────────────
  static const Color secondary50  = Color(0xFFEFF6FF);
  static const Color secondary100 = Color(0xFFDBEAFE);
  static const Color secondary200 = Color(0xFFBFDBFE);
  static const Color secondary300 = Color(0xFF93C5FD);
  static const Color secondary400 = Color(0xFF60A5FA);
  static const Color secondary500 = Color(0xFF3B82F6); // brand base
  static const Color secondary600 = Color(0xFF2563EB); // default interactive
  static const Color secondary700 = Color(0xFF1D4ED8);
  static const Color secondary800 = Color(0xFF1E40AF);
  static const Color secondary900 = Color(0xFF1E3A8A);

  // ── Semantic — Success (Emerald) ────────────────────────────────────────────
  static const Color success50  = Color(0xFFECFDF5);
  static const Color success100 = Color(0xFFD1FAE5);
  static const Color success300 = Color(0xFF6EE7B7);
  static const Color success500 = Color(0xFF10B981);
  static const Color success600 = Color(0xFF059669);
  static const Color success700 = Color(0xFF047857);

  // ── Semantic — Warning (Amber) ──────────────────────────────────────────────
  static const Color warning50  = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);

  // ── Driver Portal — Orange accent (#FF9800, badge #E65100) ─────────────────
  static const Color driverAccent = Color(0xFFFF9800);
  static const Color driverBadge  = Color(0xFFE65100);

  // ── Semantic — Error (Rose) ─────────────────────────────────────────────────
  static const Color error50  = Color(0xFFFFF1F2);
  static const Color error100 = Color(0xFFFFE4E6);
  static const Color error300 = Color(0xFFFDA4AF);
  static const Color error500 = Color(0xFFF43F5E);
  static const Color error600 = Color(0xFFE11D48);
  static const Color error700 = Color(0xFFBE123C);

  // ── Semantic — Info ─────────────────────────────────────────────────────────
  static const Color info500 = Color(0xFF06B6D4);  // cyan-500
  static const Color info600 = Color(0xFF0891B2);
  static const Color info900 = Color(0xFF164E63);   // cyan-900 (badge bg)

  // ── Neutral — Slate ─────────────────────────────────────────────────────────
  static const Color neutral50  = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral950 = Color(0xFF020617);

  // ── Surface tokens ──────────────────────────────────────────────────────────
  // Light theme
  static const Color lightBackground   = Color(0xFFF8FAFC); // neutral-50
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceVar   = Color(0xFFF1F5F9); // neutral-100
  static const Color lightBorder       = Color(0xFFE2E8F0); // neutral-200
  static const Color lightBorderFocus  = Color(0xFF4F46E5); // primary-600
  static const Color lightText         = Color(0xFF0F172A); // neutral-900
  static const Color lightTextSub      = Color(0xFF475569); // neutral-600
  static const Color lightTextHint     = Color(0xFF94A3B8); // neutral-400

  // Dark theme
  static const Color darkBackground    = Color(0xFF0A0E1A); // deeper than neutral-950
  static const Color darkSurface       = Color(0xFF111827); // gray-900
  static const Color darkSurfaceVar    = Color(0xFF1C2537); // gray-800 variant
  static const Color darkBorder        = Color(0xFF1E293B); // neutral-800
  static const Color darkBorderFocus   = Color(0xFF818CF8); // primary-400
  static const Color darkText          = Color(0xFFF8FAFC); // neutral-50
  static const Color darkTextSub       = Color(0xFF94A3B8); // neutral-400
  static const Color darkTextHint      = Color(0xFF475569); // neutral-600

  // ── Overlay & scrim ─────────────────────────────────────────────────────────
  static const Color overlayLight = Color(0x1A000000); // 10% black
  static const Color overlayDark  = Color(0x40000000); // 25% black
  static const Color scrim        = Color(0x80000000); // 50% black

  // ── Gradient presets ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary700],
  );

  static const LinearGradient sidebarGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111827), Color(0xFF0A0E1A)],
  );

  static const LinearGradient sidebarGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
  );

  // ── ColorScheme factories ────────────────────────────────────────────────────

  static ColorScheme get lightScheme => ColorScheme(
    brightness: Brightness.light,
    primary: primary600,
    onPrimary: Colors.white,
    primaryContainer: primary100,
    onPrimaryContainer: primary900,
    secondary: secondary600,
    onSecondary: Colors.white,
    secondaryContainer: secondary100,
    onSecondaryContainer: secondary900,
    tertiary: success600,
    onTertiary: Colors.white,
    tertiaryContainer: success100,
    onTertiaryContainer: success700,
    error: error600,
    onError: Colors.white,
    errorContainer: error100,
    onErrorContainer: error700,
    surface: lightSurface,
    onSurface: lightText,
    surfaceContainerHighest: lightSurfaceVar,
    onSurfaceVariant: lightTextSub,
    outline: lightBorder,
    outlineVariant: neutral200,
    shadow: neutral900,
    scrim: scrim,
    inverseSurface: neutral900,
    onInverseSurface: neutral50,
    inversePrimary: primary300,
  );

  static ColorScheme get darkScheme => ColorScheme(
    brightness: Brightness.dark,
    primary: primary400,
    onPrimary: primary950,
    primaryContainer: primary800,
    onPrimaryContainer: primary100,
    secondary: secondary400,
    onSecondary: secondary900,
    secondaryContainer: secondary800,
    onSecondaryContainer: secondary100,
    tertiary: success300,
    onTertiary: success700,
    tertiaryContainer: success700,
    onTertiaryContainer: success50,
    error: error300,
    onError: error700,
    errorContainer: error700,
    onErrorContainer: error50,
    surface: darkSurface,
    onSurface: darkText,
    surfaceContainerHighest: darkSurfaceVar,
    onSurfaceVariant: darkTextSub,
    outline: darkBorder,
    outlineVariant: neutral700,
    shadow: Colors.black,
    scrim: scrim,
    inverseSurface: neutral100,
    onInverseSurface: neutral900,
    inversePrimary: primary600,
  );
}
